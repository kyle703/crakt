//
//  RouteReviewView.swift
//  crakt
//
//  Consolidated view for route feedback
//

import SwiftUI
import SwiftData

// Category colors for consistent theming
private enum CategoryColor {
    static let difficulty = Color.blue
    static let wall = Color.cyan
    static let holds = Color.orange
    static let movement = Color.purple
    static let experience = Color.green
}

struct RouteReviewView: View {
    let route: Route
    let attempt: RouteAttempt?
    let isAutoPresented: Bool
    let onSave: (DifficultyRating?, [WallAngle], [HoldType], [MovementStyle], [ClimbExperience]) -> Void
    @Environment(\.dismiss) private var dismiss

    // Selection state
    @State private var selectedRating: DifficultyRating?
    @State private var selectedAngles: [WallAngle] = []
    @State private var selectedHolds: [HoldType] = []
    @State private var selectedMovement: [MovementStyle] = []
    @State private var selectedExperience: [ClimbExperience] = []
    
    // Track original values to restore on cancel
    @State private var originalRating: DifficultyRating?
    @State private var originalAngles: [WallAngle] = []
    @State private var originalHolds: [HoldType] = []
    @State private var originalMovement: [MovementStyle] = []
    @State private var originalExperience: [ClimbExperience] = []
    @State private var wasCancelled = false
    
    // Auto-dismiss timer state
    @State private var autoDismissTask: Task<Void, Never>?
    @State private var autoDismissEnabled: Bool = true
    @State private var countdownSeconds: Int = 0
    @State private var showCountdown: Bool = false
    private let autoDismissDelay: TimeInterval = 10.0
    private let countdownThreshold: Int = 5

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    headerView
                    
                    // Difficulty Rating
                    difficultySection
                    
                    // Wall Angle (multi-select)
                    angleSection
                    
                    // Hold Types
                    holdTypesSection
                    
                    // Movement Style
                    movementSection
                    
                    // Experience
                    experienceSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .contentShape(Rectangle())
            .onTapGesture { cancelAutoDismiss() }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in cancelAutoDismiss() }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        wasCancelled = true
                        restoreOriginalValues()
                        cancelAutoDismissTimer()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadOriginalValues()
                if isAutoPresented {
                    startAutoDismissTimer()
                } else {
                    autoDismissEnabled = false
                }
            }
            .onDisappear {
                cancelAutoDismissTimer()
                if !wasCancelled {
                    onSave(selectedRating, selectedAngles, selectedHolds, selectedMovement, selectedExperience)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Route Review")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    // Show grade info
                    gradeInfoView
                }
                
                Spacer()
                
                // Show circuit color swatch if applicable
                if route.gradeSystem == .circuit, let mapping = route.circuitMapping {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(mapping.swiftUIColor)
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            
            if showCountdown && autoDismissEnabled && isAutoPresented {
                HStack(spacing: 6) {
                    Text("Auto-saving in \(countdownSeconds)s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Keep open") {
                        cancelAutoDismiss()
                    }
                    .font(.caption.bold())
                    .foregroundColor(.blue)
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.2), value: showCountdown)
    }
    
    @ViewBuilder
    private var gradeInfoView: some View {
        if route.gradeSystem == .circuit {
            // Circuit grade display
            if let mapping = route.circuitMapping {
                HStack(spacing: 6) {
                    Circle()
                        .fill(mapping.swiftUIColor)
                        .frame(width: 12, height: 12)
                    Text(mapping.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("(\(mapping.gradeRangeDescription))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Circuit grade")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } else {
            // Standard grade display
            if let gradeDesc = route.gradeDescription {
                HStack(spacing: 6) {
                    Circle()
                        .fill(route.gradeColor)
                        .frame(width: 12, height: 12)
                    Text(gradeDesc)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(route.gradeSystem.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Difficulty Section
    
    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How did it feel?")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(DifficultyRating.allCases, id: \.self) { rating in
                    CategoryTagButton(
                        label: rating.rawValue,
                        icon: rating.iconName,
                        isSelected: selectedRating == rating,
                        color: CategoryColor.difficulty
                    ) {
                        cancelAutoDismiss()
                        selectedRating = selectedRating == rating ? nil : rating
                    }
                }
            }
        }
    }
    
    // MARK: - Wall Angle Section
    
    private var angleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wall")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(WallAngle.allCases, id: \.self) { angle in
                    CategoryTagButton(
                        label: angle.description,
                        icon: angle.iconName,
                        isSelected: selectedAngles.contains(angle),
                        color: CategoryColor.wall
                    ) {
                        cancelAutoDismiss()
                        toggle(&selectedAngles, angle)
                    }
                }
            }
        }
    }
    
    // MARK: - Hold Types Section
    
    private var holdTypesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Holds")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(HoldType.allCases, id: \.self) { hold in
                    CategoryTagButton(
                        label: hold.description,
                        icon: hold.iconName,
                        isSelected: selectedHolds.contains(hold),
                        color: CategoryColor.holds
                    ) {
                        cancelAutoDismiss()
                        toggle(&selectedHolds, hold)
                    }
                }
            }
        }
    }
    
    // MARK: - Movement Section
    
    private var movementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Movement")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(MovementStyle.allCases, id: \.self) { style in
                    CategoryTagButton(
                        label: style.description,
                        icon: style.iconName,
                        isSelected: selectedMovement.contains(style),
                        color: CategoryColor.movement
                    ) {
                        cancelAutoDismiss()
                        toggle(&selectedMovement, style)
                    }
                }
            }
        }
    }
    
    // MARK: - Experience Section
    
    private var experienceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Experience")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(ClimbExperience.allCases, id: \.self) { exp in
                    CategoryTagButton(
                        label: exp.description,
                        icon: exp.iconName,
                        isSelected: selectedExperience.contains(exp),
                        color: CategoryColor.experience
                    ) {
                        cancelAutoDismiss()
                        toggle(&selectedExperience, exp)
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func toggle<T: Equatable>(_ array: inout [T], _ item: T) {
        if let idx = array.firstIndex(of: item) {
            array.remove(at: idx)
        } else {
            array.append(item)
        }
    }
    
    private func loadOriginalValues() {
        originalRating = attempt?.difficultyRating
        originalAngles = route.wallAngles
        originalHolds = route.holdTypes
        originalMovement = route.movementStyles
        originalExperience = route.experiences
        
        selectedRating = originalRating
        selectedAngles = originalAngles
        selectedHolds = originalHolds
        selectedMovement = originalMovement
        selectedExperience = originalExperience
    }
    
    private func restoreOriginalValues() {
        selectedRating = originalRating
        selectedAngles = originalAngles
        selectedHolds = originalHolds
        selectedMovement = originalMovement
        selectedExperience = originalExperience
    }
    
    // MARK: - Auto-Dismiss Timer
    
    private func startAutoDismissTimer() {
        guard isAutoPresented && autoDismissEnabled else { return }
        countdownSeconds = Int(autoDismissDelay)
        
        autoDismissTask = Task {
            for remaining in stride(from: Int(autoDismissDelay), through: 1, by: -1) {
                if Task.isCancelled { return }
                await MainActor.run {
                    countdownSeconds = remaining
                    if remaining <= countdownThreshold {
                        withAnimation { showCountdown = true }
                    }
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            if !Task.isCancelled {
                await MainActor.run { dismiss() }
            }
        }
    }
    
    private func cancelAutoDismiss() {
        guard autoDismissEnabled else { return }
        autoDismissEnabled = false
        cancelAutoDismissTimer()
        withAnimation { showCountdown = false }
    }
    
    private func cancelAutoDismissTimer() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
    }
}

// MARK: - Category Tag Button Component

struct CategoryTagButton: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? color : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.15) : Color(.systemGray6))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }
        
        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

#Preview("Manual Open") {
    RouteReviewView(
        route: Route(gradeSystem: .vscale, grade: "V4"),
        attempt: RouteAttempt(status: .send),
        isAutoPresented: false,
        onSave: { _, _, _, _, _ in }
    )
}

#Preview("Auto Presented") {
    RouteReviewView(
        route: Route(gradeSystem: .vscale, grade: "V4"),
        attempt: RouteAttempt(status: .send),
        isAutoPresented: true,
        onSave: { _, _, _, _, _ in }
    )
}
