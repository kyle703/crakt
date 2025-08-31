import Foundation
import Combine

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

    // How often to update the stopwatch (in seconds)
    private let updateInterval: TimeInterval = 0.1

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
        }

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

    /// Stops the stopwatch if running.
    func stop() {
        guard isRunning else { return }
        isRunning = false
        updateTimes() // ensure times are up-to-date at stop
        lastStopDate = Date()

        timer?.invalidate()
        timer = nil
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

    // MARK: - Private Helpers

    private func updateTimes() {
        guard isRunning,
              let startTime = startTime,
              let lapStartTime = lapStartTime else { return }

        let now = Date()
        totalTime = now.timeIntervalSince(startTime)
        currentLapTime = now.timeIntervalSince(lapStartTime)
    }
}
