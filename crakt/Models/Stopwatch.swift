//
//  Stopwatch.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import Combine
import SwiftUI

class Stopwatch: ObservableObject {
    private var startTime: Date?
    private var totalElapsedTime: TimeInterval = 0
    private var timer: Timer?

    @Published var elapsedDisplay: String = "00:00.0"

    var isRunning: Bool {
        return timer != nil
    }

    func start() {
        guard timer == nil else { return }
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateElapsedDisplay()
        }
        
        RunLoop.main.add(timer!, forMode: .common)
    }

    func pause() {
        if let start = startTime {
            totalElapsedTime += Date().timeIntervalSince(start)
            startTime = Date()
        }
        timer?.invalidate()
        timer = nil
    }

    func continueRunning() {
        guard timer == nil else { return }
        startTime = Date().addingTimeInterval(-totalElapsedTime)
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateElapsedDisplay()
        }
    }

    func updateElapsedDisplay() {
        let elapsed = self.elapsed()
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        let tenthOfSecond = Int((elapsed * 10).truncatingRemainder(dividingBy: 10))
        elapsedDisplay = String(format: "%02d:%02d.%d", minutes, seconds, tenthOfSecond)
    }

    func elapsed() -> TimeInterval {
        guard let start = startTime else { return totalElapsedTime }
        return totalElapsedTime + Date().timeIntervalSince(start)
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        startTime = nil
        totalElapsedTime = 0
        elapsedDisplay = "00:00.0"
    }

    deinit {
        timer?.invalidate()
    }
}
