import Foundation

struct FreestyleRecording: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let createdAt: Date
    let key: String
    let layoutRawValue: String
    let audioFileName: String?
    let notes: [HarmonicaNoteEvent]
    let duration: TimeInterval

    var hasAudioPlayback: Bool {
        guard let audioFileName else { return false }
        return !audioFileName.isEmpty
    }

    var asSong: HarmonicaSong {
        HarmonicaSong(
            songTitle: title,
            bpm: 90,
            key: key,
            notes: notes
        )
    }

    static func makeTitle(for date: Date, id: UUID) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, yyyy HH:mm:ss"
        let suffix = id.uuidString.prefix(4)
        return "Freestyle • \(formatter.string(from: date)) • \(suffix)"
    }
}
