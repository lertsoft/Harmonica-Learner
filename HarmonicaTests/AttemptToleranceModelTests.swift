import XCTest
@testable import Harmonica

final class AttemptToleranceModelTests: XCTestCase {
    func testToleranceStartsAtStartCents() {
        let model = AttemptToleranceModel(startCents: 30, targetCents: 15, attemptsToTarget: 20)

        XCTAssertEqual(model.tolerance(forAttempt: 0), 30, accuracy: 0.0001)
    }

    func testToleranceLinearlyApproachesTarget() {
        let model = AttemptToleranceModel(startCents: 30, targetCents: 10, attemptsToTarget: 4)

        XCTAssertEqual(model.tolerance(forAttempt: 1), 25, accuracy: 0.0001)
        XCTAssertEqual(model.tolerance(forAttempt: 2), 20, accuracy: 0.0001)
        XCTAssertEqual(model.tolerance(forAttempt: 3), 15, accuracy: 0.0001)
    }

    func testToleranceClampsBelowZeroAttempt() {
        let model = AttemptToleranceModel(startCents: 30, targetCents: 15, attemptsToTarget: 20)

        XCTAssertEqual(model.tolerance(forAttempt: -50), 30, accuracy: 0.0001)
    }

    func testToleranceClampsAboveTargetAttemptCount() {
        let model = AttemptToleranceModel(startCents: 30, targetCents: 15, attemptsToTarget: 20)

        XCTAssertEqual(model.tolerance(forAttempt: 500), 15, accuracy: 0.0001)
    }

    func testToleranceFallsBackToTargetWhenAttemptsToTargetIsNonPositive() {
        let zeroModel = AttemptToleranceModel(startCents: 30, targetCents: 15, attemptsToTarget: 0)
        let negativeModel = AttemptToleranceModel(startCents: 30, targetCents: 15, attemptsToTarget: -2)

        XCTAssertEqual(zeroModel.tolerance(forAttempt: 4), 15, accuracy: 0.0001)
        XCTAssertEqual(negativeModel.tolerance(forAttempt: 4), 15, accuracy: 0.0001)
    }
}
