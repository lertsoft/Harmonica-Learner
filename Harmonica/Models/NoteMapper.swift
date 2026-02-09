import Foundation

struct NotePitch: Equatable {
    let noteName: String
    let octave: Int
    let centsOffset: Double

    var fullName: String {
        "\(noteName)\(octave)"
    }
}

struct NoteMapper {
    private static let noteNames = [
        "C", "C#", "D", "D#", "E", "F",
        "F#", "G", "G#", "A", "A#", "B"
    ]

    static func pitch(for frequency: Double) -> NotePitch? {
        guard frequency > 0 else { return nil }
        let midi = Int(round(12 * log2(frequency / 440.0) + 69))
        let name = noteNames[midi.mod(12)]
        let octave = midi / 12 - 1
        let reference = Self.frequency(forMidi: midi)
        let cents = 1200 * log2(frequency / reference)
        return NotePitch(noteName: name, octave: octave, centsOffset: cents)
    }

    private static func frequency(forMidi midi: Int) -> Double {
        440.0 * pow(2.0, (Double(midi) - 69) / 12.0)
    }
}

private extension Int {
    func mod(_ n: Int) -> Int {
        let r = self % n
        return r >= 0 ? r : r + n
    }
}
