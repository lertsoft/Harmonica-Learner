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
    @Published private(set) var freestyleElapsed: TimeInterval = 0

    @Published private(set) var bundledSongs: [HarmonicaSong] = []
    @Published private(set) var freestyleRecordings: [FreestyleRecording] = []
    @Published private(set) var recordingBySongId: [String: FreestyleRecording] = [:]
    @Published var noticeMessage: String?

    lazy var audioService = AudioEngineService()
    let toleranceModel = AttemptToleranceModel(startCents: 30, targetCents: 15, attemptsToTarget: 20)

    private let evaluator: NoteEvaluation
    private let recordingStore: FreestyleRecordingStore

    private var hitStreak: Int = 0
    private var cancellables = Set<AnyCancellable>()
    private let isRunningTests: Bool
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
        self.isRunningTests = runningTests
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

        guard hasFrequencySignal || hasAmplitudeSignal else {
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

        if isFreestyleMode {
            matchState = .idle
            hitStreak = 0
            return
        }

        guard let targetNote = currentTargetNote else { return }
        matchState = evaluator.evaluate(detected: detectedPitch, targetNote: targetNote, attempt: attemptCount)

        if matchState == .hit {
            hitStreak += 1
            if hitStreak >= 3 {
                advanceNote()
                hitStreak = 0
            }
        } else {
            hitStreak = 0
        }
    }

    func handleSelectedSongChange(from oldSong: HarmonicaSong?, to newSong: HarmonicaSong?) {
        guard oldSong?.id != newSong?.id else { return }
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

        if let newSong, let recording = recordingBySongId[newSong.id], recording.notes.isEmpty {
            scheduleNotice("This freestyle recording has no captured notes.")
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
            duration: max(recordingDuration, 0)
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
        try audioService.playFreestyleAudio(from: audioURL)
    }

    func stopSelectedFreestyleAudio() {
        audioService.stopFreestyleAudio()
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
    }
}
