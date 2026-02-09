import XCTest
@testable import Harmonica

final class NoteEvaluationTests: XCTestCase {
    private let model = AttemptToleranceModel(startCents: 30, targetCents: 10, attemptsToTarget: 2)

    func testEvaluateReturnsIdleWhenPitchMissing() {
        let evaluator = NoteEvaluation(toleranceModel: model)

        XCTAssertEqual(evaluator.evaluate(detected: nil, targetNote: "A4", attempt: 0), .idle)
    }

    func testEvaluateReturnsMissForWrongNote() {
        let evaluator = NoteEvaluation(toleranceModel: model)
        let detected = NotePitch(noteName: "C", octave: 5, centsOffset: 0)

        XCTAssertEqual(evaluator.evaluate(detected: detected, targetNote: "A4", attempt: 0), .miss)
    }

    func testEvaluateReturnsHitWhenWithinTolerance() {
        let evaluator = NoteEvaluation(toleranceModel: model)
        let detected = NotePitch(noteName: "A", octave: 4, centsOffset: 8)

        XCTAssertEqual(evaluator.evaluate(detected: detected, targetNote: "A4", attempt: 2), .hit)
    }

    func testEvaluateReturnsMissWhenOutsideTolerance() {
        let evaluator = NoteEvaluation(toleranceModel: model)
        let detected = NotePitch(noteName: "A", octave: 4, centsOffset: 20)

        XCTAssertEqual(evaluator.evaluate(detected: detected, targetNote: "A4", attempt: 2), .miss)
    }

    func testAttemptCountChangesToleranceOutcome() {
        let evaluator = NoteEvaluation(toleranceModel: model)
        let detected = NotePitch(noteName: "A", octave: 4, centsOffset: 20)

        XCTAssertEqual(evaluator.evaluate(detected: detected, targetNote: "A4", attempt: 0), .hit)
        XCTAssertEqual(evaluator.evaluate(detected: detected, targetNote: "A4", attempt: 2), .miss)
    }
}
