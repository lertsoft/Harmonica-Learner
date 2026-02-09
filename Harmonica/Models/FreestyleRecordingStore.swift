import Foundation

enum FreestyleRecordingStoreError: LocalizedError {
    case unableToCreateStorage

    var errorDescription: String? {
        switch self {
        case .unableToCreateStorage:
            return "Unable to create local freestyle recording storage."
        }
    }
}

final class FreestyleRecordingStore {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let documentsDirectoryOverride: URL?

    init(fileManager: FileManager = .default, documentsDirectoryURL: URL? = nil) {
        self.fileManager = fileManager
        self.documentsDirectoryOverride = documentsDirectoryURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func loadAll() -> [FreestyleRecording] {
        do {
            try ensureStorageDirectories()
            guard fileManager.fileExists(atPath: indexURL.path) else { return [] }
            let data = try Data(contentsOf: indexURL)
            let decoded = try decoder.decode([FreestyleRecording].self, from: data)
            var normalized: [FreestyleRecording] = []
            normalized.reserveCapacity(decoded.count)

            for recording in decoded {
                if let audioURL = audioURL(for: recording), fileManager.fileExists(atPath: audioURL.path) {
                    normalized.append(recording)
                    continue
                }

                let withoutAudio = FreestyleRecording(
                    id: recording.id,
                    title: recording.title,
                    createdAt: recording.createdAt,
                    key: recording.key,
                    layoutRawValue: recording.layoutRawValue,
                    audioFileName: nil,
                    notes: recording.notes,
                    duration: recording.duration
                )

                if !withoutAudio.notes.isEmpty {
                    normalized.append(withoutAudio)
                }
            }

            if normalized != decoded {
                try writeIndex(normalized)
            }

            return normalized.sorted { $0.createdAt > $1.createdAt }
        } catch {
            return []
        }
    }

    func save(_ recording: FreestyleRecording) throws {
        try ensureStorageDirectories()
        var all = loadAll().filter { $0.id != recording.id }
        all.append(recording)
        try writeIndex(all.sorted { $0.createdAt > $1.createdAt })
    }

    func delete(id: UUID) throws {
        try ensureStorageDirectories()
        var all = loadAll()
        guard let index = all.firstIndex(where: { $0.id == id }) else { return }
        let recording = all.remove(at: index)
        if let url = audioURL(for: recording), fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
        try writeIndex(all)
    }

    @discardableResult
    func removeAudio(id: UUID) throws -> FreestyleRecording? {
        try ensureStorageDirectories()
        var all = loadAll()
        guard let index = all.firstIndex(where: { $0.id == id }) else { return nil }

        let existing = all[index]
        if let url = audioURL(for: existing), fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }

        let updated = FreestyleRecording(
            id: existing.id,
            title: existing.title,
            createdAt: existing.createdAt,
            key: existing.key,
            layoutRawValue: existing.layoutRawValue,
            audioFileName: nil,
            notes: existing.notes,
            duration: existing.duration
        )
        all[index] = updated
        try writeIndex(all.sorted { $0.createdAt > $1.createdAt })
        return updated
    }

    func audioURL(for recording: FreestyleRecording) -> URL? {
        guard let audioFileName = recording.audioFileName, !audioFileName.isEmpty else { return nil }
        return audioDirectoryURL.appendingPathComponent(audioFileName)
    }

    func audioURL(forFileName fileName: String) -> URL {
        audioDirectoryURL.appendingPathComponent(fileName)
    }

    private var documentsDirectoryURL: URL {
        if let documentsDirectoryOverride {
            return documentsDirectoryOverride
        }
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var indexURL: URL {
        documentsDirectoryURL.appendingPathComponent("freestyle_recordings_index.json")
    }

    private var audioDirectoryURL: URL {
        documentsDirectoryURL.appendingPathComponent("FreestyleAudio", isDirectory: true)
    }

    private func ensureStorageDirectories() throws {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: audioDirectoryURL.path, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else {
                throw FreestyleRecordingStoreError.unableToCreateStorage
            }
            return
        }
        try fileManager.createDirectory(at: audioDirectoryURL, withIntermediateDirectories: true)
    }

    private func writeIndex(_ recordings: [FreestyleRecording]) throws {
        let data = try encoder.encode(recordings)
        try data.write(to: indexURL, options: .atomic)
    }
}
