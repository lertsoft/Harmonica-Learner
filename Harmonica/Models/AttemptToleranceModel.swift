import Combine
import Foundation

struct AttemptToleranceModel {
    let startCents: Double
    let targetCents: Double
    let attemptsToTarget: Int

    func tolerance(forAttempt attempt: Int) -> Double {
        guard attemptsToTarget > 0 else { return targetCents }
        let clamped = min(max(attempt, 0), attemptsToTarget)
        let progress = Double(clamped) / Double(attemptsToTarget)
        return startCents - (startCents - targetCents) * progress
    }
}
