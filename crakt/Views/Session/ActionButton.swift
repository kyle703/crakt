//
//  ActionButton.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI

struct ActionButton: View {
    let icon: String
    let label: String?
    var size: CGFloat = 60  // Standard mobile size
    let color: Color
    let action: () -> Void
    var disabled: Bool = false
    var width: CGFloat = 100  // Full-width but mobile-appropriate
    var height: CGFloat = 60   // Meets 60pt requirement without being excessive
    var hapticType: HapticType = .attempt

    enum HapticType {
        case success
        case attempt
        case error
    }

    var body: some View {
        Button(action: {
            if !disabled {
                // Play haptic feedback
                playHapticFeedback()

                withAnimation(.easeInOut(duration: 0.3)) {
                    action()
                }
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))  // Appropriate mobile icon size
                    .foregroundColor(disabled ? .gray : color)
                    .frame(height: 24)  // Appropriate mobile icon height

                if let label {
                    Text(label)
                        .foregroundColor(disabled ? .gray : color)
                        .font(.system(size: 12, weight: .semibold))  // Standard mobile text size
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(minWidth: width, maxWidth: .infinity, minHeight: height, maxHeight: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(disabled ? 0.7 : 1.0))
                    .shadow(color: Color.black.opacity(disabled ? 0.05 : 0.15), radius: 2, x: 0, y: 1)
                    .shadow(color: Color.black.opacity(disabled ? 0.1 : 0.3), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(disabled ? .gray : color, lineWidth: disabled ? 1 : 3)
            )
        .contentShape(Rectangle())  // Ensure entire area is tappable
        .accessibilityLabel(label ?? icon)
        .accessibilityHint("Tap to \(label?.lowercased() ?? "perform action")")
        .accessibilityAddTraits(.isButton)
    }
        .buttonStyle(PlainButtonStyle())
        .disabled(disabled)
    }

    private func playHapticFeedback() {
        switch hapticType {
        case .success:
            HapticManager.shared.playSuccess()
        case .attempt:
            HapticManager.shared.playAttempt()
        case .error:
            HapticManager.shared.playError()
        }
    }
}

struct ActionButton_Previews: PreviewProvider {
    static var previews: some View {
        ActionButton(icon: "xmark", label: ClimbStatus.fall.description, color: .red, action: {}).frame(width: 100, height: 100)
    }
}
