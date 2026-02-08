//
//  RouteFeedbackPopover.swift
//  crakt
//
//  Lightweight floating popover asking if user wants to review route
//  Auto-dismisses after 5 seconds with circular countdown
//

import SwiftUI

struct RouteFeedbackPopover: View {
    let route: Route
    let attempt: RouteAttempt?
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    @State private var countdown: Double = 5.0
    @State private var autoDismissTask: Task<Void, Never>?
    
    private let totalDuration: Double = 5.0
    
    private var progress: Double {
        countdown / totalDuration
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Circular countdown timer
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                // Progress circle (counts down)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)
                
                // Countdown number
                Text("\(Int(ceil(countdown)))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            // Route info and question
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if route.gradeSystem == .circuit, let mapping = route.circuitMapping {
                        Circle()
                            .fill(mapping.swiftUIColor)
                            .frame(width: 12, height: 12)
                        Text(mapping.gradeRangeDescription)
                            .font(.subheadline.weight(.semibold))
                    } else {
                        Circle()
                            .fill(route.gradeColor)
                            .frame(width: 12, height: 12)
                        Text(route.gradeDescription ?? "Route")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                
                Text("Add route feedback?")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                // Dismiss button
                Button(action: {
                    cancelAutoDismiss()
                    onDismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Circle())
                }
                
                // Accept button
                Button(action: {
                    cancelAutoDismiss()
                    onAccept()
                }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .onAppear {
            startAutoDismissTimer()
        }
        .onDisappear {
            cancelAutoDismiss()
        }
    }
    
    // MARK: - Auto-Dismiss Timer
    
    private func startAutoDismissTimer() {
        countdown = totalDuration
        
        autoDismissTask = Task {
            while countdown > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                await MainActor.run {
                    countdown = max(0, countdown - 0.1)
                }
            }
            if !Task.isCancelled && countdown <= 0 {
                await MainActor.run {
                    onDismiss()
                }
            }
        }
    }
    
    private func cancelAutoDismiss() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
    }
}

// MARK: - Popover Overlay (tap outside to dismiss, overlays on header bar)

struct RouteFeedbackPopoverOverlay: View {
    let route: Route
    let attempt: RouteAttempt?
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Tap-outside dismiss area (invisible)
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onDismiss()
                    }
                
                // Popover positioned to overlay header bar (second row with timer, tags, attempts)
                // This positions below the top grade badge row but over the session timer bar
                VStack {
                    Spacer()
                        .frame(height: geometry.safeAreaInsets.top + 55) // Just below top bar with grade badge
                    
                    RouteFeedbackPopover(
                        route: route,
                        attempt: attempt,
                        onAccept: onAccept,
                        onDismiss: onDismiss
                    )
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("Popover") {
    ZStack {
        Color.gray.opacity(0.2)
            .edgesIgnoringSafeArea(.all)
        
        VStack {
            // Fake header bar
            HStack {
                Text("V4")
                    .font(.title2.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                
                Spacer()
                
                Text("00:05:32")
                    .font(.system(.body, design: .monospaced))
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding()
            
            Spacer()
        }
        
        RouteFeedbackPopoverOverlay(
            route: Route(gradeSystem: .vscale, grade: "V4"),
            attempt: RouteAttempt(status: .send),
            onAccept: { print("Accepted") },
            onDismiss: { print("Dismissed") }
        )
    }
}
