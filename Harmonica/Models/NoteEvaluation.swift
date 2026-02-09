import Foundation

enum NoteMatchState: String {
    case idle
    case hit
    case miss
}

struct NoteEvaluation {
    let toleranceModel: AttemptToleranceModel

    func evaluate(detected: NotePitch?, targetNote: String, attempt: Int) -> NoteMatchState {
        guard let detected else { return .idle }
        guard detected.fullName == targetNote else { return .miss }
        let tolerance = toleranceModel.tolerance(forAttempt: attempt)
        return abs(detected.centsOffset) <= tolerance ? .hit : .miss
    }
}
