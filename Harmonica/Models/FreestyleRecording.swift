import Foundation

enum RecordingSource: String, Codable, Hashable {
    case freestyle
    case importedSong
}

struct FreestyleRecording: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let createdAt: Date
    let key: String
    let layoutRawValue: String
    let audioFileName: String?
    let notes: [HarmonicaNoteEvent]
    let duration: TimeInterval
    let source: RecordingSource

    init(
        id: UUID,
        title: String,
        createdAt: Date,
        key: String,
        layoutRawValue: String,
        audioFileName: String?,
        notes: [HarmonicaNoteEvent],
        duration: TimeInterval,
        source: RecordingSource = .freestyle
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.key = key
        self.layoutRawValue = layoutRawValue
        self.audioFileName = audioFileName
        self.notes = notes
        self.duration = duration
        self.source = source
    }

    var hasAudioPlayback: Bool {
        guard let audioFileName else { return false }
        return !audioFileName.isEmpty
    }

    var asSong: HarmonicaSong {
        HarmonicaSong(
            songTitle: title,
            bpm: 90,
            key: key,
            notes: notes,
            stableID: "recording:\(id.uuidString)"
        )
    }

    static func makeTitle(for date: Date, id: UUID) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, yyyy HH:mm:ss"
        let suffix = id.uuidString.prefix(4)
        return "Freestyle • \(formatter.string(from: date)) • \(suffix)"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case createdAt
        case key
        case layoutRawValue
        case audioFileName
        case notes
        case duration
        case source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        key = try container.decode(String.self, forKey: .key)
        layoutRawValue = try container.decode(String.self, forKey: .layoutRawValue)
        audioFileName = try container.decodeIfPresent(String.self, forKey: .audioFileName)
        notes = try container.decode([HarmonicaNoteEvent].self, forKey: .notes)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        source = try container.decodeIfPresent(RecordingSource.self, forKey: .source) ?? .freestyle
    }
}
