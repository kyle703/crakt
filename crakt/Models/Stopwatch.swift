import Foundation
import Combine
import UIKit

extension TimeInterval {
    var formatted: String {
        // Break down the total interval into integer hours, minutes, seconds, plus a tenths digit
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        // Extract the tenths of a second (0–9)
        let tenths = Int((self * 10).truncatingRemainder(dividingBy: 10))
        
        if hours > 0 {
            // Format: H:MM:SS.t (e.g. 1:07:05.2)
            return String(format: "%d:%02d:%02d.%d", hours, minutes, seconds, tenths)
        } else {
            // Format: MM:SS.t (e.g. 07:05.2)
            return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
        }
    }
}


final class Stopwatch: ObservableObject {
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var totalTime: TimeInterval = 0
    @Published private(set) var currentLapTime: TimeInterval = 0
    @Published private(set) var laps: [TimeInterval] = []

    // Internal state
    private var timer: Timer?
    private var startTime: Date?
    private var lapStartTime: Date?
    private var lastStopDate: Date?
    private var lastBackgroundDate: Date?

    // How often to update the stopwatch (in seconds)
    private let updateInterval: TimeInterval = 0.1

    // Background task identifier
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    // MARK: - Public API

    /// Starts the stopwatch if not already running.
    func start() {
        guard !isRunning else { return }
        isRunning = true

        let now = Date()
        if startTime == nil {
            // First start
            startTime = now
            lapStartTime = now
        } else if let lastStopDate = lastStopDate {
            // Resuming after a stop
            let pauseDuration = now.timeIntervalSince(lastStopDate)
            startTime = startTime?.addingTimeInterval(pauseDuration)
            lapStartTime = lapStartTime?.addingTimeInterval(pauseDuration)
        } else if let lastBackgroundDate = lastBackgroundDate {
            // Resuming after background
            let backgroundDuration = now.timeIntervalSince(lastBackgroundDate)
            startTime = startTime?.addingTimeInterval(backgroundDuration)
            lapStartTime = lapStartTime?.addingTimeInterval(backgroundDuration)
        }

        startMainTimer()
    }

    /// Stops the stopwatch if running.
    func stop() {
        guard isRunning else { return }
        isRunning = false
        updateTimes() // ensure times are up-to-date at stop
        lastStopDate = Date()

        // Stop all timers
        timer?.invalidate()
        timer = nil

        // End background task if active
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }

        // Reset background state
        resetBackgroundState()
    }

    /// Resets the stopwatch completely.
    func reset() {
        stop()
        totalTime = 0
        currentLapTime = 0
        laps.removeAll()
        startTime = nil
        lapStartTime = nil
        lastStopDate = nil
        resetBackgroundState()
    }

    /// Records a lap and resets the current lap counter.
    func lap() {
        guard isRunning else { return }
        updateTimes() // capture the most recent currentLapTime

        // Store the current lap time and reset
        laps.append(currentLapTime)
        lapStartTime = Date()
        currentLapTime = 0
    }

    /// Called when app enters background
    func enterBackground() {
        guard isRunning else { return }

        lastBackgroundDate = Date()

        // End background task if active
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }

        // Request background task to continue timer
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }

        // Start background timer that updates every minute
        startBackgroundTimer()
    }

    /// Called when app enters foreground
    func enterForeground() {
        guard isRunning, let lastBackgroundDate = lastBackgroundDate else { return }

        let backgroundDuration = Date().timeIntervalSince(lastBackgroundDate)

        // Adjust start times to account for background duration
        if let startTime = startTime {
            self.startTime = startTime.addingTimeInterval(backgroundDuration)
        }
        if let lapStartTime = lapStartTime {
            self.lapStartTime = lapStartTime.addingTimeInterval(backgroundDuration)
        }

        // End background task
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }

        // Stop background timer and resume main timer
        stopBackgroundTimer()
        startMainTimer()
    }

    /// Reset background state
    func resetBackgroundState() {
        lastBackgroundDate = nil
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    // MARK: - Private Helpers

    private func startBackgroundTimer() {
        // Background timer updates every minute to save battery
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateTimesInBackground()
        }
    }

    private func stopBackgroundTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func startMainTimer() {
        timer = Timer.scheduledTimer(
            withTimeInterval: updateInterval,
            repeats: true
        ) { [weak self] _ in
            self?.updateTimes()
        }

        // Add timer to the main run loop
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func updateTimes() {
        guard isRunning,
              let startTime = startTime,
              let lapStartTime = lapStartTime else { return }

        let now = Date()
        totalTime = now.timeIntervalSince(startTime)
        currentLapTime = now.timeIntervalSince(lapStartTime)
    }

    private func updateTimesInBackground() {
        guard isRunning,
              let startTime = startTime,
              let lapStartTime = lapStartTime else { return }

        let now = Date()
        totalTime = now.timeIntervalSince(startTime)
        currentLapTime = now.timeIntervalSince(lapStartTime)

        // Notify observers of time change
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
}
