//
//  HapticManager.swift
//  crakt
//
//  Created by Kyle Thompson on 1/20/25.
//

import CoreHaptics
import SwiftUI

/// Manager class for CoreHaptics feedback in climbing app
class HapticManager {
    static let shared = HapticManager()

    private var hapticEngine: CHHapticEngine?

    private init() {
        createHapticEngine()
    }

    private func createHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Haptic engine not supported on this device")
            return
        }

        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine creation failed: \(error.localizedDescription)")
        }
    }

    /// Play success haptic feedback (for send/completion)
    func playSuccess() {
        playHapticPattern(intensity: 1.0, sharpness: 1.0, duration: 0.3)
    }

    /// Play attempt haptic feedback (for fall/flash)
    func playAttempt() {
        playHapticPattern(intensity: 0.7, sharpness: 0.5, duration: 0.2)
    }

    /// Play custom haptic pattern
    func playHapticPattern(intensity: Float, sharpness: Float, duration: Double) {
        guard let hapticEngine = hapticEngine else {
            // Fallback to simple vibration for older devices
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            return
        }

        do {
            let intensityParameter = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
            let sharpnessParameter = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)

            let event = CHHapticEvent(eventType: .hapticContinuous,
                                    parameters: [intensityParameter, sharpnessParameter],
                                    relativeTime: 0,
                                    duration: duration)

            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error.localizedDescription)")
            // Fallback to simple feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
}
