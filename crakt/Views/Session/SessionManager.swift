//
//  SessionManager.swift
//  crakt
//
//  Created by Kyle Thompson on 1/20/25.
//

import SwiftUI
import Combine

/// Manager class for session-level functionality including auto-lock prevention
class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published var isSessionActive: Bool = false {
        didSet {
            updateIdleTimer()
        }
    }

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Listen for app lifecycle events to manage idle timer
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.updateIdleTimer()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                // Disable idle timer when app goes to background
                UIApplication.shared.isIdleTimerDisabled = false
            }
            .store(in: &cancellables)
    }

    /// Start a climbing session (enables auto-lock prevention)
    func startSession() {
        isSessionActive = true
    }

    /// End a climbing session (disables auto-lock prevention)
    func endSession() {
        isSessionActive = false
    }

    /// Update idle timer based on session state
    private func updateIdleTimer() {
        // Only disable idle timer if session is active and app is in foreground
        let shouldDisableIdleTimer = isSessionActive && UIApplication.shared.applicationState == .active
        UIApplication.shared.isIdleTimerDisabled = shouldDisableIdleTimer

        print("Idle timer disabled: \(shouldDisableIdleTimer)")
    }
}
