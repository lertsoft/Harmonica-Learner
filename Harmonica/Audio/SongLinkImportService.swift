import Foundation

enum SongLinkProvider: String, Codable, Equatable {
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

        let notes = Self.playableEvents(from: payload.notes, layout: layout)
        guard !notes.isEmpty else { throw SongLinkImportError.noPlayableNotes }
        return .transcription(
            LinkedSongTranscription(
                title: payload.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "Linked Song"
                    : payload.title,
                bpm: min(300, max(30, payload.bpm ?? 90)),
                key: key,
                notes: notes
            )
        )
    }

    static func playableEvents(
        from events: [HarmonicaNoteEvent],
        layout: HarmonicaLayout
    ) -> [HarmonicaNoteEvent] {
        events.prefix(512).compactMap { event in
            guard let hole = layout.hole(for: event.note) else { return nil }
            return HarmonicaNoteEvent(
                note: event.note,
                duration: min(4, max(0.1, event.duration)),
                hole: "\(hole.index)\(hole.airflow == .blow ? "B" : "D")"
            )
        }
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
