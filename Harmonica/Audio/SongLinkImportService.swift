import Foundation

nonisolated enum SongLinkProvider: String, Codable, Equatable {
    case spotify
    case youtube
    case appleMusic
    case directAudio
    case web

    var displayName: String {
        switch self {
        case .spotify: return "Spotify"
        case .youtube: return "YouTube"
        case .appleMusic: return "Apple Music"
        case .directAudio: return "audio"
        case .web: return "web"
        }
    }
}

struct SongLinkDescriptor: Equatable {
    let url: URL
    let provider: SongLinkProvider

    static func parse(_ text: String) throws -> SongLinkDescriptor {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["https", "http"].contains(scheme),
              let host = url.host?.lowercased() else {
            throw SongLinkImportError.invalidLink
        }

        let provider: SongLinkProvider
        if host == "open.spotify.com" || host == "spotify.link" || host.hasSuffix(".spotify.com") {
            provider = .spotify
        } else if host == "youtu.be" || host == "youtube.com" || host.hasSuffix(".youtube.com") {
            provider = .youtube
        } else if host == "music.apple.com" || host.hasSuffix(".music.apple.com") {
            provider = .appleMusic
        } else if Self.audioExtensions.contains(url.pathExtension.lowercased()) {
            provider = .directAudio
        } else {
            provider = .web
        }

        return SongLinkDescriptor(url: url, provider: provider)
    }

    private static let audioExtensions: Set<String> = [
        "aac", "aif", "aiff", "caf", "flac", "m4a", "mp3", "wav"
    ]
}

struct LinkedSongTranscription {
    let title: String
    let bpm: Int
    let key: String
    let notes: [HarmonicaNoteEvent]
    let arrangement: HarmonicaArrangementSummary
}

enum SongLinkImportResult {
    case downloadedAudio(URL)
    case transcription(LinkedSongTranscription)
}

enum SongLinkImportError: LocalizedError, Equatable {
    case invalidLink
    case unsupportedWebLink
    case licensedServiceRequired(SongLinkProvider)
    case downloadFailed
    case fileTooLarge
    case invalidServiceResponse
    case noPlayableNotes

    var errorDescription: String? {
        switch self {
        case .invalidLink:
            return "Paste a complete http or https song link."
        case .unsupportedWebLink:
            return "That page does not expose an audio file. Use a direct audio-file link or import the file from Files."
        case .licensedServiceRequired(let provider):
            return "The app recognized this as a \(provider.displayName) link, but \(provider.displayName) does not permit the app to extract its audio. Configure a licensed transcription service or import an audio file you can use."
        case .downloadFailed:
            return "The linked audio file could not be downloaded."
        case .fileTooLarge:
            return "The linked audio file is larger than the 200 MB import limit."
        case .invalidServiceResponse:
            return "The transcription service returned an invalid response."
        case .noPlayableNotes:
            return "The transcription did not contain notes playable on the selected harmonica."
        }
    }
}

/// Resolves direct audio links locally or delegates protected-service links to an optional,
/// licensed backend that returns note events rather than copyrighted source audio.
struct SongLinkImportService {
    private let session: URLSession
    private let transcriptionEndpoint: URL?

    init(
        session: URLSession = .shared,
        transcriptionEndpoint: URL? = SongLinkImportService.configuredEndpoint
    ) {
        self.session = session
        self.transcriptionEndpoint = transcriptionEndpoint
    }

    func resolve(
        _ descriptor: SongLinkDescriptor,
        layout: HarmonicaLayout,
        key: String
    ) async throws -> SongLinkImportResult {
        if descriptor.provider == .directAudio {
            return .downloadedAudio(try await downloadAudio(from: descriptor.url))
        }

        guard descriptor.provider != .web else {
            throw SongLinkImportError.unsupportedWebLink
        }
        guard let transcriptionEndpoint else {
            throw SongLinkImportError.licensedServiceRequired(descriptor.provider)
        }

        var request = URLRequest(url: transcriptionEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = Self.configuredAPIToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(
            TranscriptionRequest(
                sourceURL: descriptor.url,
                provider: descriptor.provider,
                harmonicaKey: key,
                layout: layout.rawValue
            )
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode),
              let payload = try? JSONDecoder().decode(TranscriptionResponse.self, from: data) else {
            throw SongLinkImportError.invalidServiceResponse
        }

        let arrangement = Self.arrange(events: payload.notes, layout: layout)
        let notes = arrangement.notes
        guard !notes.isEmpty else { throw SongLinkImportError.noPlayableNotes }
        return .transcription(
            LinkedSongTranscription(
                title: payload.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "Linked Song"
                    : payload.title,
                bpm: min(300, max(30, payload.bpm ?? 90)),
                key: key,
                notes: notes,
                arrangement: arrangement.summary
            )
        )
    }

    static func playableEvents(
        from events: [HarmonicaNoteEvent],
        layout: HarmonicaLayout
    ) -> [HarmonicaNoteEvent] {
        arrange(events: events, layout: layout).notes
    }

    /// Legacy events are sequential. Timed responses may contain simultaneous notes;
    /// sourceNotes carries a chord group without requiring a new provider contract.
    static func arrange(events: [HarmonicaNoteEvent], layout: HarmonicaLayout) -> HarmonicaArrangement {
        struct TimedPitch {
            let start: Double
            let end: Double
            let frequencies: [Double]
        }
        var cursor = 0.0
        var timed: [TimedPitch] = []
        for event in events {
            guard event.duration.isFinite, event.duration > 0 else { continue }
            let start = event.startTime ?? cursor
            guard start.isFinite, start >= 0 else { continue }
            let end = start + event.duration
            guard end.isFinite else { continue }
            cursor = max(cursor, end)
            let source = event.sourceNotes?.isEmpty == false ? event.sourceNotes! : [event.note]
            let frequencies = source.compactMap { NoteMapper.frequency(for: $0) }
            timed.append(TimedPitch(start: start, end: end, frequencies: frequencies))
        }
        // Sweep time boundaries to retain overlaps and gaps in O(n log n), not O(n²).
        struct Boundary {
            let time: Double
            let index: Int
            let starts: Bool
        }
        let boundaries = timed.enumerated().flatMap { index, item in
            [Boundary(time: item.start, index: index, starts: true), Boundary(time: item.end, index: index, starts: false)]
        }.sorted { $0.time < $1.time }
        var active: Set<Int> = []
        var observations: [PitchObservation] = []
        var time = 0.0
        var index = 0
        while index < boundaries.count {
            let nextTime = boundaries[index].time
            if nextTime > time {
                observations.append(PitchObservation(
                    frequencies: active.sorted().flatMap { timed[$0].frequencies }, duration: nextTime - time,
                    startsNewNote: active.contains { abs(timed[$0].start - time) < 0.000001 }
                ))
            }
            while index < boundaries.count, boundaries[index].time == nextTime {
                let boundary = boundaries[index]
                if boundary.starts { active.insert(boundary.index) } else { active.remove(boundary.index) }
                index += 1
            }
            time = nextTime
        }
        return HarmonicaArrangement.make(from: observations, layout: layout, minimumRunDuration: 0)
    }

    private func downloadAudio(from url: URL) async throws -> URL {
        let (temporaryURL, response) = try await session.download(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            try? FileManager.default.removeItem(at: temporaryURL)
            throw SongLinkImportError.downloadFailed
        }

        let size = (try? temporaryURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        guard size <= 200 * 1_024 * 1_024 else {
            try? FileManager.default.removeItem(at: temporaryURL)
            throw SongLinkImportError.fileTooLarge
        }

        let fileExtension = url.pathExtension.isEmpty ? "m4a" : url.pathExtension.lowercased()
        let namedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("linked-song-\(UUID().uuidString).\(fileExtension)")
        do {
            try FileManager.default.moveItem(at: temporaryURL, to: namedURL)
            return namedURL
        } catch {
            try? FileManager.default.removeItem(at: temporaryURL)
            throw SongLinkImportError.downloadFailed
        }
    }

    private static var configuredEndpoint: URL? {
        guard let value = Bundle.main.object(
            forInfoDictionaryKey: "HarmonicaTranscriptionAPIURL"
        ) as? String else { return nil }
        return URL(string: value)
    }

    private static var configuredAPIToken: String? {
        guard let value = Bundle.main.object(
            forInfoDictionaryKey: "HarmonicaTranscriptionAPIToken"
        ) as? String,
              !value.isEmpty else { return nil }
        return value
    }
}

private struct TranscriptionRequest: Encodable {
    let sourceURL: URL
    let provider: SongLinkProvider
    let harmonicaKey: String
    let layout: String
}

private struct TranscriptionResponse: Decodable {
    let title: String
    let bpm: Int?
    let notes: [HarmonicaNoteEvent]
}
