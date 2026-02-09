import Foundation

struct HarmonicaSong: Codable, Identifiable, Hashable {
    let songTitle: String
    let bpm: Int
    let key: String
    let notes: [HarmonicaNoteEvent]

    var id: String { songTitle }
}

struct HarmonicaNoteEvent: Codable, Hashable {
    let note: String
    let duration: Double
    let hole: String
}
