import Foundation

enum Airflow: String, Codable, CaseIterable {
    case blow
    case draw
}

struct HarmonicaHole: Codable, Hashable, Identifiable {
    let index: Int
    let airflow: Airflow

    var id: String {
        "\(index)-\(airflow.rawValue)"
    }

    var displayName: String {
        "\(index) \(airflow == .blow ? "Blow" : "Draw")"
    }

    static func fromCode(_ code: String) -> HarmonicaHole? {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return nil }
        let numberPart = trimmed.dropLast()
        let actionPart = trimmed.suffix(1)
        guard let index = Int(numberPart) else { return nil }
        switch actionPart.uppercased() {
        case "B":
            return HarmonicaHole(index: index, airflow: .blow)
        case "D":
            return HarmonicaHole(index: index, airflow: .draw)
        default:
            return nil
        }
    }
}
