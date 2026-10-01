import Foundation

nonisolated enum HarmonicaLayout: String, CaseIterable, Identifiable {
    case diatonicC = "Diatonic C"
    case leeOskarC = "Lee Oskar C"

    var id: String { rawValue }

    private static let standardNoteToHole: [String: HarmonicaHole] = {
        let pairs: [(String, HarmonicaHole)] = [
            ("C4", HarmonicaHole(index: 1, airflow: .blow)),
            ("D4", HarmonicaHole(index: 1, airflow: .draw)),
            ("E4", HarmonicaHole(index: 2, airflow: .blow)),
            ("G4", HarmonicaHole(index: 2, airflow: .draw)),
            ("B4", HarmonicaHole(index: 3, airflow: .draw)),
            ("C5", HarmonicaHole(index: 4, airflow: .blow)),
            ("D5", HarmonicaHole(index: 4, airflow: .draw)),
            ("E5", HarmonicaHole(index: 5, airflow: .blow)),
            ("F5", HarmonicaHole(index: 5, airflow: .draw)),
            ("G5", HarmonicaHole(index: 6, airflow: .blow)),
            ("A5", HarmonicaHole(index: 6, airflow: .draw)),
            ("C6", HarmonicaHole(index: 7, airflow: .blow)),
            ("B5", HarmonicaHole(index: 7, airflow: .draw)),
            ("E6", HarmonicaHole(index: 8, airflow: .blow)),
            ("D6", HarmonicaHole(index: 8, airflow: .draw)),
            ("G6", HarmonicaHole(index: 9, airflow: .blow)),
            ("F6", HarmonicaHole(index: 9, airflow: .draw)),
            ("C7", HarmonicaHole(index: 10, airflow: .blow)),
            ("A6", HarmonicaHole(index: 10, airflow: .draw))
        ]

        var map: [String: HarmonicaHole] = [:]
        for (note, hole) in pairs {
            map[note] = hole
        }
        return map
    }()

    private static let standardPlayableNotes: [(name: String, midi: Int)] =
        standardNoteToHole.keys.sorted().compactMap { note in
            NoteMapper.midiNumber(for: note).map { (note, $0) }
        }

    var noteToHole: [String: HarmonicaHole] {
        // Both supported C layouts currently share the same natural-note map.
        // Keep this switch so another layout can supply a cached table later.
        switch self {
        case .diatonicC, .leeOskarC:
            return Self.standardNoteToHole
        }
    }

    func hole(for noteName: String) -> HarmonicaHole? {
        noteToHole[noteName]
    }

    func nearestPlayableNote(to frequency: Double) -> String? {
        guard frequency.isFinite, frequency > 0,
              let detected = NoteMapper.pitch(for: frequency),
              let midi = NoteMapper.midiNumber(for: detected.fullName) else { return nil }
        return playableNote(forMIDI: midi)
    }

    /// Preserve pitch class by moving octaves first. Only approximate a semitone when
    /// that pitch class is unavailable without bends or overblows on this layout.
    func playableNote(forMIDI midi: Int) -> String? {
        let candidates = Self.standardPlayableNotes
        let sameClass = candidates.filter { ($0.midi - midi).isMultiple(of: 12) }
        return (sameClass.isEmpty ? candidates : sameClass).min { left, right in
            let leftDistance = abs(left.midi - midi)
            let rightDistance = abs(right.midi - midi)
            return leftDistance == rightDistance ? left.midi < right.midi : leftDistance < rightDistance
        }?.name
    }
}
