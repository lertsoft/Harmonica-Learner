import Foundation

struct HarmonicaSong: Codable, Identifiable, Hashable {
    let stableID: String
    let songTitle: String
    let bpm: Int
    let key: String
    let notes: [HarmonicaNoteEvent]

    var id: String { stableID }

    init(
        songTitle: String,
        bpm: Int,
        key: String,
        notes: [HarmonicaNoteEvent],
        stableID: String? = nil
    ) {
        self.songTitle = songTitle
        self.bpm = bpm
        self.key = key
        self.notes = notes
        self.stableID = stableID ?? "bundled:\(songTitle)"
    }

    private enum CodingKeys: String, CodingKey {
        case stableID
        case songTitle
        case bpm
        case key
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        songTitle = try container.decode(String.self, forKey: .songTitle)
        bpm = try container.decode(Int.self, forKey: .bpm)
        key = try container.decode(String.self, forKey: .key)
        notes = try container.decode([HarmonicaNoteEvent].self, forKey: .notes)
        stableID = try container.decodeIfPresent(String.self, forKey: .stableID)
            ?? "bundled:\(songTitle)"
    }
}

struct HarmonicaNoteEvent: Codable, Hashable {
    let note: String
    let duration: Double
    let hole: String
}
