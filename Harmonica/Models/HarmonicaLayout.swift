import Foundation

enum HarmonicaLayout: String, CaseIterable, Identifiable {
    case diatonicC = "Diatonic C"
    case leeOskarC = "Lee Oskar C"

    var id: String { rawValue }

    var noteToHole: [String: HarmonicaHole] {
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
    }

    func hole(for noteName: String) -> HarmonicaHole? {
        noteToHole[noteName]
    }
}
