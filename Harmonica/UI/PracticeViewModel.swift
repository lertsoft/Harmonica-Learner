import Combine
import Foundation
import SwiftUI

final class PracticeViewModel: ObservableObject {
    @Published var songs: [HarmonicaSong] = []
    @Published var selectedSong: HarmonicaSong?
    @Published var attemptCount: Int = 0
    @Published var currentNoteIndex: Int = 0
    @Published var matchState: NoteMatchState = .idle
    @Published var detectedPitch: NotePitch?
    @Published var sensitivity: Double = 0.035
    @Published var selectedLayout: HarmonicaLayout = .diatonicC
    @Published var selectedKey: String = "C"

    @Published var isFreestyleMode: Bool = false
    @Published private(set) var isFreestyleRecording: Bool = false
    @Published private(set) var isFreestylePlayingAudio: Bool = false
    @Published private(set) var isReferenceNotePlaying: Bool = false
    @Published private(set) var freestyleElapsed: TimeInterval = 0
    @Published private(set) var isImportingSong: Bool = false

    @Published private(set) var bundledSongs: [HarmonicaSong] = []
    @Published private(set) var freestyleRecordings: [FreestyleRecording] = []
    @Published private(set) var recordingBySongId: [String: FreestyleRecording] = [:]
    @Published var noticeMessage: String?

    lazy var audioService = AudioEngineService()
    lazy var notePlaybackService = NotePlaybackService()
    let toleranceModel = AttemptToleranceModel(startCents: 30, targetCents: 15, attemptsToTarget: 20)

    private let evaluator: NoteEvaluation
    private let recordingStore: FreestyleRecordingStore

    private var hitStreak: Int = 0
    // PitchTap publishes at most every 50 ms, so six stable samples represent a 300 ms hold.
    private let sustainedHitSampleCount = 6
    private var cancellables = Set<AnyCancellable>()
    private let shouldBindAudioService: Bool

    private var freestyleTimer: AnyCancellable?
    private var freestyleStartDate: Date?
    private var freestyleCurrentNote: NotePitch?
    private var freestyleCurrentHole: HarmonicaHole?
    private var freestyleCurrentNoteStart: Date?
    private var freestyleInvalidSince: Date?
    private var freestyleCapturedEvents: [HarmonicaNoteEvent] = []
    private var freestylePendingRecordingID: UUID?
    private var freestylePendingAudioFileName: String?
    private var freestyleCaptureLayout: HarmonicaLayout?
    private var freestyleCaptureKey: String?

    init(
        recordingStore: FreestyleRecordingStore = FreestyleRecordingStore(),
        enableAudioBindings: Bool? = nil
    ) {
        let runningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
        self.shouldBindAudioService = enableAudioBindings ?? !runningTests
        self.recordingStore = recordingStore
        self.evaluator = NoteEvaluation(toleranceModel: toleranceModel)

        bundledSongs = SongLibrary.loadBundledSongs()
        freestyleRecordings = recordingStore.loadAll()
        rebuildMergedSongs(keepCurrentSelection: false)

        if shouldBindAudioService {
            bindAudioService()
        }
    }

    deinit {
        freestyleTimer?.cancel()
        freestyleTimer = nil
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    var currentSongNotes: [HarmonicaNoteEvent] {
        selectedSong?.notes ?? []
    }

    var currentTargetNote: String? {
        guard currentNoteIndex < currentSongNotes.count else { return nil }
        return currentSongNotes[currentNoteIndex].note
    }

    var currentTargetHole: HarmonicaHole? {
        guard let target = currentTargetNote else { return nil }
        return selectedLayout.hole(for: target)
    }

    var selectedRecording: FreestyleRecording? {
        guard let selectedSong else { return nil }
        return recordingBySongId[selectedSong.id]
    }

    var selectedSongIsFreestyle: Bool {
        selectedRecording != nil
    }

    var selectedFreestyleHasAudio: Bool {
        selectedRecording?.hasAudioPlayback == true
    }

    var selectedFreestyleHasPlayableNotes: Bool {
        guard let recording = selectedRecording else { return true }
        return !recording.notes.isEmpty
    }

    var selectedRecordingIsImportedSong: Bool {
        selectedRecording?.source == .importedSong
    }

    var currentTargetEvent: HarmonicaNoteEvent? {
        guard currentNoteIndex >= 0, currentNoteIndex < currentSongNotes.count else { return nil }
        return currentSongNotes[currentNoteIndex]
    }

    func reloadFreestyleRecordings() {
        freestyleRecordings = recordingStore.loadAll()
        rebuildMergedSongs(keepCurrentSelection: true)
    }

    func enterFreestyleMode() {
        isFreestyleMode = true
        matchState = .idle
        currentNoteIndex = 0
        hitStreak = 0
    }

    func exitFreestyleMode() {
        isFreestyleMode = false
        if isFreestylePlayingAudio {
            stopSelectedFreestyleAudio()
        }
    }

    func startNewAttempt() {
        attemptCount += 1
        currentNoteIndex = 0
        matchState = .idle
        hitStreak = 0
    }

    func handleFrequency(_ frequency: Double, amplitude: Double) {
        let hasFrequencySignal = frequency > 20 && frequency < 5_000
        let hasAmplitudeSignal = amplitude >= sensitivity

        guard hasFrequencySignal && hasAmplitudeSignal else {
            if isFreestyleRecording {
                processFreestyleCapture(pitch: nil, timestamp: Date())
            }
            matchState = .idle
            detectedPitch = nil
            hitStreak = 0
            return
        }

        detectedPitch = NoteMapper.pitch(for: frequency)

        if isFreestyleRecording {
            processFreestyleCapture(pitch: detectedPitch, timestamp: Date())
        }

        guard let detectedPitch else {
            matchState = .idle
            hitStreak = 0
            return
        }


        guard !isReferenceNotePlaying, !isFreestylePlayingAudio else {
            matchState = .idle
            hitStreak = 0
            return
        }

        if isFreestyleMode {
            matchState = .idle
            hitStreak = 0
            return
        }

        guard let targetNote = currentTargetNote else { return }
        matchState = evaluator.evaluate(detected: detectedPitch, targetNote: targetNote, attempt: attemptCount)

        if matchState == .hit {
            hitStreak += 1
            if hitStreak >= sustainedHitSampleCount {
                advanceNote()
                hitStreak = 0
            }
        } else {
            hitStreak = 0
        }
    }

    func handleSelectedSongChange(from oldSong: HarmonicaSong?, to newSong: HarmonicaSong?) {
        guard oldSong?.id != newSong?.id else { return }
        if shouldBindAudioService {
            notePlaybackService.stop()
        }
        if isFreestylePlayingAudio {
            stopSelectedFreestyleAudio()
        }
        currentNoteIndex = 0
        hitStreak = 0
        matchState = .idle

        if isFreestyleRecording {
            do {
                try stopFreestyleRecordingAndSave(selectSavedSong: false)
                scheduleNotice("Freestyle recording saved before switching songs.")
            } catch {
                scheduleNotice("Could not save current freestyle recording.")
            }
        }

        if let newSong, let recording = recordingBySongId[newSong.id] {
            selectedKey = recording.key
            if let recordedLayout = HarmonicaLayout(rawValue: recording.layoutRawValue) {
                selectedLayout = recordedLayout
            }
            if recording.notes.isEmpty {
                scheduleNotice("This saved recording has no captured notes.")
            }
        }
    }

    func startFreestyleRecording() throws {
        guard !isFreestyleRecording else { return }

        let recordingID = UUID()
        let audioFileName = "\(recordingID.uuidString).m4a"
        let audioURL = recordingStore.audioURL(forFileName: audioFileName)

        try audioService.startFreestyleRecording(to: audioURL)

        freestylePendingRecordingID = recordingID
        freestylePendingAudioFileName = audioFileName
        freestyleCaptureLayout = selectedLayout
        freestyleCaptureKey = selectedKey
        freestyleCapturedEvents = []
        freestyleCurrentNote = nil
        freestyleCurrentHole = nil
        freestyleCurrentNoteStart = nil
        freestyleInvalidSince = nil
        freestyleStartDate = Date()
        freestyleElapsed = 0

        freestyleTimer?.cancel()
        freestyleTimer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                guard let self, let start = self.freestyleStartDate else { return }
                self.freestyleElapsed = now.timeIntervalSince(start)
            }
    }

    @discardableResult
    func stopFreestyleRecordingAndSave(selectSavedSong: Bool = true) throws -> FreestyleRecording? {
        guard isFreestyleRecording else { return nil }

        try audioService.stopFreestyleRecording()
        finalizeFreestyleCurrentEvent(at: Date())

        freestyleTimer?.cancel()
        freestyleTimer = nil

        let recordingDuration = audioService.lastFreestyleRecordingDuration
        freestyleElapsed = recordingDuration

        guard let recordingID = freestylePendingRecordingID,
              let audioFileName = freestylePendingAudioFileName else {
            return nil
        }

        let captured = freestyleCapturedEvents
        let hasEnoughAudio = recordingDuration >= 1.0

        if captured.isEmpty && !hasEnoughAudio {
            let audioURL = recordingStore.audioURL(forFileName: audioFileName)
            try? FileManager.default.removeItem(at: audioURL)
            scheduleNotice("Recording too short to save.")
            resetFreestyleCaptureState()
            return nil
        }

        let createdAt = freestyleStartDate ?? Date()
        let title = FreestyleRecording.makeTitle(for: createdAt, id: recordingID)

        let recording = FreestyleRecording(
            id: recordingID,
            title: title,
            createdAt: createdAt,
            key: freestyleCaptureKey ?? selectedKey,
            layoutRawValue: (freestyleCaptureLayout ?? selectedLayout).rawValue,
            audioFileName: audioFileName,
            notes: captured,
            duration: max(recordingDuration, 0),
            source: .freestyle
        )

        try recordingStore.save(recording)
        freestyleRecordings = recordingStore.loadAll()
        rebuildMergedSongs(keepCurrentSelection: false)

        if selectSavedSong, let justSaved = songs.first(where: { $0.id == recording.asSong.id }) {
            selectedSong = justSaved
            currentNoteIndex = 0
        }

        if captured.isEmpty {
            scheduleNotice("Audio saved. No valid harmonica notes were captured.")
        }

        resetFreestyleCaptureState()
        return recording
    }

    func playSelectedFreestyleAudio() throws {
        guard let recording = selectedRecording else { return }
        guard let audioURL = recordingStore.audioURL(for: recording) else {
            scheduleNotice("This freestyle session is notes-only.")
            return
        }
        notePlaybackService.stop()
        try audioService.playFreestyleAudio(from: audioURL)
    }

    func stopSelectedFreestyleAudio() {
        audioService.stopFreestyleAudio()
    }

    func playCurrentReferenceNote() throws {
        guard let event = currentTargetEvent else { return }
        if isFreestylePlayingAudio {
            stopSelectedFreestyleAudio()
        }
        try notePlaybackService.play(noteName: event.note, duration: event.duration)
    }

    func stopCurrentReferenceNote() {
        notePlaybackService.stop()
    }

    func renameSelectedRecording(to title: String) throws {
        guard let recording = selectedRecording else { return }
        guard let renamed = try recordingStore.rename(id: recording.id, to: title) else {
            scheduleNotice("Enter a name before saving.")
            return
        }

        freestyleRecordings = recordingStore.loadAll()
        rebuildMergedSongs(keepCurrentSelection: false)
        selectedSong = songs.first(where: { $0.id == renamed.asSong.id })
        scheduleNotice("Renamed to “\(renamed.title)”.")
    }

    func deleteSelectedRecording() throws {
        guard let recording = selectedRecording else { return }
        if isFreestylePlayingAudio {
            stopSelectedFreestyleAudio()
        }
        try recordingStore.delete(id: recording.id)
        freestyleRecordings = recordingStore.loadAll()
        rebuildMergedSongs(keepCurrentSelection: false)
        scheduleNotice("“\(recording.title)” was deleted.")
    }

    func importSong(from sourceURL: URL) {
        guard !isImportingSong else { return }
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let recordingID = UUID()
        let fileExtension = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension.lowercased()
        let audioFileName = "\(recordingID.uuidString).\(fileExtension)"
        let destinationURL = recordingStore.audioURL(forFileName: audioFileName)

        do {
            try FileManager.default.createDirectory(
                at: destinationURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            scheduleNotice("Could not add that audio file: \(error.localizedDescription)")
            return
        }

        isImportingSong = true
        let title = sourceURL.deletingPathExtension().lastPathComponent
        let layout = selectedLayout
        let key = selectedKey

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let analysis = try ImportedSongAnalyzer().analyze(url: destinationURL, layout: layout)
                DispatchQueue.main.async {
                    guard let self else { return }
                    let recording = FreestyleRecording(
                        id: recordingID,
                        title: title,
                        createdAt: Date(),
                        key: key,
                        layoutRawValue: layout.rawValue,
                        audioFileName: audioFileName,
                        notes: analysis.notes,
                        duration: analysis.duration,
                        source: .importedSong
                    )

                    do {
                        try self.recordingStore.save(recording)
                        self.freestyleRecordings = self.recordingStore.loadAll()
                        self.rebuildMergedSongs(keepCurrentSelection: false)
                        self.selectedSong = self.songs.first(where: { $0.id == recording.asSong.id })
                        self.isFreestyleMode = false
                        if analysis.usedFallback {
                            self.scheduleNotice("Song added with a starter harmonica phrase; the mix had no clear lead pitch.")
                        } else {
                            self.scheduleNotice("Song added with \(analysis.notes.count) suggested harmonica notes.")
                        }
                    } catch {
                        try? FileManager.default.removeItem(at: destinationURL)
                        self.scheduleNotice("Could not save the imported song: \(error.localizedDescription)")
                    }
                    self.isImportingSong = false
                }
            } catch {
                try? FileManager.default.removeItem(at: destinationURL)
                DispatchQueue.main.async {
                    self?.isImportingSong = false
                    self?.scheduleNotice("Could not analyze that song: \(error.localizedDescription)")
                }
            }
        }
    }

    func removeSelectedFreestyleAudio() throws {
        guard let recording = selectedRecording else { return }
        guard recording.hasAudioPlayback else {
            scheduleNotice("Background audio is already removed.")
            return
        }

        if isFreestylePlayingAudio {
            stopSelectedFreestyleAudio()
        }

        _ = try recordingStore.removeAudio(id: recording.id)
        freestyleRecordings = recordingStore.loadAll()
        rebuildMergedSongs(keepCurrentSelection: true)
        scheduleNotice("Background audio removed. Notes are still available for learning mode.")
    }

    func advanceNote() {
        guard currentNoteIndex + 1 < currentSongNotes.count else { return }
        currentNoteIndex += 1
    }

    private func rebuildMergedSongs(keepCurrentSelection: Bool) {
        let previousSelectionID = keepCurrentSelection ? selectedSong?.id : nil

        let freestyleSongs = freestyleRecordings.map(\.asSong)
        songs = bundledSongs + freestyleSongs

        var map: [String: FreestyleRecording] = [:]
        for (song, recording) in zip(freestyleSongs, freestyleRecordings) {
            map[song.id] = recording
        }
        recordingBySongId = map

        if let previousSelectionID, let matched = songs.first(where: { $0.id == previousSelectionID }) {
            selectedSong = matched
        } else {
            selectedSong = songs.first
        }
    }

    private func processFreestyleCapture(pitch: NotePitch?, timestamp: Date) {
        guard let pitch else {
            if freestyleCurrentNote != nil {
                if freestyleInvalidSince == nil {
                    freestyleInvalidSince = timestamp
                }
                if let invalidSince = freestyleInvalidSince,
                   timestamp.timeIntervalSince(invalidSince) >= 0.15 {
                    finalizeFreestyleCurrentEvent(at: invalidSince)
                    freestyleInvalidSince = nil
                }
            }
            return
        }

        let captureLayout = freestyleCaptureLayout ?? selectedLayout
        guard let hole = captureLayout.hole(for: pitch.fullName) else {
            if freestyleCurrentNote != nil {
                if freestyleInvalidSince == nil {
                    freestyleInvalidSince = timestamp
                }
                if let invalidSince = freestyleInvalidSince,
                   timestamp.timeIntervalSince(invalidSince) >= 0.15 {
                    finalizeFreestyleCurrentEvent(at: invalidSince)
                    freestyleInvalidSince = nil
                }
            }
            return
        }

        freestyleInvalidSince = nil

        if let current = freestyleCurrentNote,
           let currentHole = freestyleCurrentHole,
           current.fullName == pitch.fullName,
           currentHole == hole {
            return
        }

        finalizeFreestyleCurrentEvent(at: timestamp)

        freestyleCurrentNote = pitch
        freestyleCurrentHole = hole
        freestyleCurrentNoteStart = timestamp
    }

    private func finalizeFreestyleCurrentEvent(at timestamp: Date) {
        guard let currentNote = freestyleCurrentNote,
              let currentHole = freestyleCurrentHole,
              let start = freestyleCurrentNoteStart else {
            freestyleCurrentNote = nil
            freestyleCurrentHole = nil
            freestyleCurrentNoteStart = nil
            return
        }

        let rawDuration = timestamp.timeIntervalSince(start)
        let duration = normalizeDuration(rawDuration)

        let event = HarmonicaNoteEvent(
            note: currentNote.fullName,
            duration: duration,
            hole: holeCode(for: currentHole)
        )
        freestyleCapturedEvents.append(event)

        freestyleCurrentNote = nil
        freestyleCurrentHole = nil
        freestyleCurrentNoteStart = nil
    }

    private func normalizeDuration(_ duration: TimeInterval) -> TimeInterval {
        let rounded = (duration / 0.05).rounded() * 0.05
        return max(0.1, rounded)
    }

    private func holeCode(for hole: HarmonicaHole) -> String {
        "\(hole.index)\(hole.airflow == .blow ? "B" : "D")"
    }

    private func resetFreestyleCaptureState() {
        freestylePendingRecordingID = nil
        freestylePendingAudioFileName = nil
        freestyleCaptureLayout = nil
        freestyleCaptureKey = nil
        freestyleCapturedEvents = []
        freestyleCurrentNote = nil
        freestyleCurrentHole = nil
        freestyleCurrentNoteStart = nil
        freestyleInvalidSince = nil
        freestyleStartDate = nil
    }

    private func scheduleNotice(_ message: String) {
        noticeMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self, self.noticeMessage == message else { return }
            self.noticeMessage = nil
        }
    }

    private func bindAudioService() {
        audioService.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        audioService.$isRecordingFreestyle
            .sink { [weak self] value in
                self?.isFreestyleRecording = value
            }
            .store(in: &cancellables)

        audioService.$isPlayingFreestyleAudio
            .sink { [weak self] value in
                self?.isFreestylePlayingAudio = value
            }
            .store(in: &cancellables)

        notePlaybackService.$isPlaying
            .sink { [weak self] value in
                self?.isReferenceNotePlaying = value
            }
            .store(in: &cancellables)
    }
}
