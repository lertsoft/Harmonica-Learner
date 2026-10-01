import XCTest
import AVFoundation
import Combine
@testable import Harmonica

final class ImportedSongAnalyzerTests: XCTestCase {
    func testSuggestedEventsCollapseRepeatedPitchAndMapToHarmonicaHole() {
        let observations = [
            PitchObservation(frequency: 523.251, duration: 0.1),
            PitchObservation(frequency: 523.251, duration: 0.1),
            PitchObservation(frequency: 587.330, duration: 0.2)
        ]

        let events = ImportedSongAnalyzer.makeSuggestedEvents(
            from: observations,
            layout: .diatonicC
        )

        XCTAssertEqual(events.map(\.note), ["C5", "D5"])
        XCTAssertEqual(events.map(\.hole), ["4B", "4D"])
        XCTAssertEqual(events.map(\.duration), [0.2, 0.2])
    }

    func testSuggestedEventsIgnoreSilenceAndUnstableBlips() {
        let observations = [
            PitchObservation(frequency: nil, duration: 0.2),
            PitchObservation(frequency: 523.251, duration: 0.05),
            PitchObservation(frequency: nil, duration: 0.2)
        ]

        let events = ImportedSongAnalyzer.makeSuggestedEvents(
            from: observations,
            layout: .diatonicC
        )

        XCTAssertTrue(events.isEmpty)
    }

    func testNoDetectedPitchesProducesNoInventedPhrase() {
        XCTAssertTrue(ImportedSongAnalyzer.makeSuggestedEvents(
            from: [PitchObservation(frequency: nil, duration: 2)], layout: .diatonicC
        ).isEmpty)
    }

    func testChordTonesBecomeAnArpeggioWithSourceEvidenceAndTiming() throws {
        let source = ["C5", "E5", "G5"]
        let notes = ImportedSongAnalyzer.makeSuggestedEvents(from: [
            PitchObservation(frequency: nil, duration: 0.3),
            PitchObservation(frequencies: source.compactMap { NoteMapper.frequency(for: $0) }, duration: 0.6)
        ], layout: .diatonicC)
        XCTAssertEqual(notes.map(\.note), source)
        XCTAssertEqual(notes.map(\.hole), ["4B", "5B", "6B"])
        XCTAssertTrue(notes.allSatisfy { $0.sourceNotes == source })
        XCTAssertEqual(try XCTUnwrap(notes[0].startTime), 0.3, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(notes[2].startTime), 0.7, accuracy: 0.001)
        XCTAssertEqual(notes.reduce(0) { $0 + $1.duration }, 0.6, accuracy: 0.001)
    }

    func testArrangementTransposesAWholeKeyAndRetainsEveryFastNote() throws {
        let source = ["D#4", "F4", "G4", "G#4", "A#4", "C5", "D5"]
        let observations = try (0..<210).map { index in
            PitchObservation(frequency: try XCTUnwrap(NoteMapper.frequency(for: source[index % source.count])), duration: 0.09)
        }
        let arrangement = HarmonicaArrangement.make(from: observations, layout: .diatonicC)
        XCTAssertEqual(arrangement.summary.transpositionSemitones, -3)
        XCTAssertEqual(arrangement.notes.count, 210)
        XCTAssertEqual(Array(arrangement.notes.prefix(7).map(\.note)), ["C5", "D5", "E5", "F5", "G5", "A5", "B5"])
        XCTAssertTrue(arrangement.notes.allSatisfy { abs($0.duration - 0.09) < 0.001 })
    }

    func testRestsSeparateRepeatedNotesAndPlaybackRetainsRhythm() {
        let events = ImportedSongAnalyzer.makeSuggestedEvents(from: [
            PitchObservation(frequency: 523.251, duration: 0.09),
            PitchObservation(frequency: nil, duration: 0.3),
            PitchObservation(frequency: 523.251, duration: 3.2)
        ], layout: .diatonicC)
        XCTAssertEqual(events.count, 2)
        let tones = NotePlaybackService.coverTones(for: events)
        XCTAssertEqual(tones.count, 3)
        XCTAssertEqual(tones[0].duration, 0.09, accuracy: 0.001)
        XCTAssertEqual(tones[1].frequency, 0)
        XCTAssertEqual(tones[1].duration, 0.3, accuracy: 0.001)
        XCTAssertEqual(tones[2].duration, 3.2, accuracy: 0.001)
    }

    func testAnalyzeRecoversChordFromStereoEvenWithOppositePhase() throws {
        let url = try makeAudioFile(duration: 1, frequencies: [523.251, 659.255, 783.991], channels: 2, oppositePhase: true)
        defer { try? FileManager.default.removeItem(at: url) }
        let analysis = try ImportedSongAnalyzer().analyze(url: url, layout: .diatonicC)
        XCTAssertGreaterThan(analysis.arrangement.detectedChordCount, 0)
        XCTAssertTrue(Set(analysis.notes.map(\.note)).isSuperset(of: ["C5", "E5", "G5"]))
        XCTAssertTrue(analysis.notes.contains { $0.sourceNotes == ["C5", "E5", "G5"] })
    }

    func testHarmonicOvertonesAreNotInventedAsAChord() throws {
        let url = try makeAudioFile(duration: 1, frequencies: [261.626, 523.251, 784.877], amplitudes: [0.4, 0.2, 0.1])
        defer { try? FileManager.default.removeItem(at: url) }
        let analysis = try ImportedSongAnalyzer().analyze(url: url, layout: .diatonicC)
        XCTAssertEqual(analysis.arrangement.detectedChordCount, 0)
        XCTAssertTrue(analysis.notes.allSatisfy { $0.note == "C4" })
        XCTAssertFalse(analysis.notes.isEmpty)
    }

    func testHarmonicallyRichVoicesWithBroadbandNoiseRetainChordTones() throws {
        let fundamentals = [523.251, 659.255, 783.991]
        let frequencies = fundamentals + fundamentals.map { $0 * 2 } + fundamentals.map { $0 * 3 }
        let url = try makeAudioFile(
            duration: 1.5, frequencies: frequencies,
            amplitudes: [0.18, 0.18, 0.18, 0.07, 0.07, 0.07, 0.03, 0.03, 0.03],
            sampleRate: 22_050, noiseAmplitude: 0.08
        )
        defer { try? FileManager.default.removeItem(at: url) }
        let analysis = try ImportedSongAnalyzer().analyze(url: url, layout: .diatonicC)
        XCTAssertGreaterThan(analysis.arrangement.detectedChordCount, 0)
        XCTAssertTrue(analysis.notes.contains { $0.sourceNotes == ["C5", "E5", "G5"] })
        XCTAssertTrue(analysis.notes.allSatisfy { HarmonicaLayout.diatonicC.hole(for: $0.note) != nil })
    }

    func testAnalysisKeepsAudioAndNotesBeyondThreeMinutes() throws {
        let url = try makeAudioFile(duration: 182, frequencies: [523.251], silentUntil: 180.5)
        defer { try? FileManager.default.removeItem(at: url) }
        let analysis = try ImportedSongAnalyzer().analyze(url: url, layout: .diatonicC)
        XCTAssertEqual(analysis.duration, 182, accuracy: 0.01)
        XCTAssertFalse(analysis.notes.isEmpty)
        XCTAssertGreaterThan(try XCTUnwrap(analysis.notes.last?.startTime), 180)
    }

    func testAnalyzeReadsAudioFileAndFindsPlayablePitch() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("harmonica-analyzer-\(UUID().uuidString).caf")
        defer { try? FileManager.default.removeItem(at: url) }

        let sampleRate = 44_100.0
        let duration = 0.75
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = try XCTUnwrap(
            AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        )
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount))
        let samples = try XCTUnwrap(buffer.floatChannelData?[0])
        buffer.frameLength = frameCount

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            samples[frame] = Float(sin(2 * .pi * 523.251 * time) * 0.4)
        }

        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)

        let analysis = try ImportedSongAnalyzer().analyze(url: url, layout: .diatonicC)

        XCTAssertFalse(analysis.notes.isEmpty)
        XCTAssertFalse(analysis.notes.isEmpty)
        XCTAssertTrue(analysis.notes.allSatisfy { $0.note == "C5" })
        XCTAssertEqual(analysis.duration, duration, accuracy: 0.02)
    }

    func testAnalyzeReportsProgress() throws {
        let url = try makeToneFile(duration: 0.25)
        defer { try? FileManager.default.removeItem(at: url) }
        var progressValues: [Double] = []

        _ = try ImportedSongAnalyzer().analyze(
            url: url,
            layout: .diatonicC,
            progress: { progressValues.append($0) }
        )

        XCTAssertEqual(progressValues.first, 0)
        XCTAssertEqual(progressValues.last, 1)
    }

    func testAnalyzeCanBeCancelled() throws {
        let url = try makeToneFile(duration: 0.25)
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertThrowsError(
            try ImportedSongAnalyzer().analyze(
                url: url,
                layout: .diatonicC,
                shouldCancel: { true }
            )
        ) { error in
            XCTAssertEqual(error as? ImportedSongAnalyzerError, .cancelled)
        }
    }

    @MainActor
    func testCoverStreamsLongSequencesAndCompletesShortSequences() async throws {
        let playback = NotePlaybackService()
        try await playback.play(events: [HarmonicaNoteEvent(note: "C5", duration: 300, hole: "4B")])
        XCTAssertTrue(playback.isPlayingSequence)
        playback.stop()
        XCTAssertFalse(playback.isPlayingSequence)
        let finished = expectation(description: "Streamed cover completes")
        var started = false
        let observation = playback.$isPlayingSequence.sink { playing in
            if playing { started = true }
            if started && !playing { finished.fulfill() }
        }
        defer { observation.cancel(); playback.stop() }
        try await playback.play(events: [HarmonicaNoteEvent(note: "C5", duration: 0.15, hole: "4B")])
        await fulfillment(of: [finished], timeout: 5)
    }

    func testShortChordSlowsDownWithoutConsumingFollowingRest() {
        let events = ImportedSongAnalyzer.makeSuggestedEvents(from: [
            PitchObservation(frequencies: [523.251, 659.255, 783.991], duration: 0.09),
            PitchObservation(frequency: nil, duration: 0.3),
            PitchObservation(frequency: 587.330, duration: 0.1)
        ], layout: .diatonicC)
        let tones = NotePlaybackService.coverTones(for: events)
        XCTAssertEqual(tones.count, 5)
        XCTAssertEqual(tones[3].frequency, 0)
        XCTAssertEqual(tones[3].duration, 0.3, accuracy: 0.001)
    }

    @MainActor
    func testLibraryExportPersistsPlayableSong() async throws {
        let input = try makeAudioFile(duration: 1.5, frequencies: [523.251, 659.255, 783.991])
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: input)
            try? FileManager.default.removeItem(at: directory)
        }
        let store = FreestyleRecordingStore(documentsDirectoryURL: directory)
        let defaultsSuite = "LibraryExportTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsSuite))
        defer { defaults.removePersistentDomain(forName: defaultsSuite) }
        let model = PracticeViewModel(
            recordingStore: store,
            libraryImportAllowance: LibraryImportAllowance(defaults: defaults),
            enableAudioBindings: false
        )
        let saved = expectation(description: "Library audio exported and analyzed")
        let observation = model.$freestyleRecordings.filter { !$0.isEmpty }.first().sink { _ in saved.fulfill() }
        defer { observation.cancel() }
        model.importSongFromMusicLibrary(assetURL: input, title: "My Tune")
        XCTAssertTrue(model.canCancelSongImport)
        await fulfillment(of: [saved], timeout: 15)
        let recording = try XCTUnwrap(store.loadAll().first)
        XCTAssertEqual(recording.title, "My Tune")
        XCTAssertEqual(recording.source, .musicLibrary)
        XCTAssertFalse(recording.notes.isEmpty)
        XCTAssertTrue(Set(recording.notes.map(\.note)).isSuperset(of: ["C5", "E5", "G5"]))
        XCTAssertGreaterThan(try XCTUnwrap(recording.arrangement).detectedChordCount, 0)
        XCTAssertTrue(model.currentSongNotes.allSatisfy { HarmonicaLayout.diatonicC.hole(for: $0.note) != nil })
        XCTAssertTrue(model.currentSongNotes.contains { ($0.sourceNotes?.count ?? 0) > 1 })
        XCTAssertNotNil(store.audioURL(for: recording))
        XCTAssertEqual(model.lastSuccessfulSongImportID, recording.id)
        let reopened = FreestyleRecordingStore(documentsDirectoryURL: directory)
        XCTAssertEqual(reopened.loadAll().first?.id, recording.id)
        XCTAssertEqual(reopened.loadAll().first?.arrangement, recording.arrangement)
        XCTAssertEqual(reopened.loadAll().first?.notes, recording.notes)
        _ = try reopened.rename(id: recording.id, to: "Renamed Chord Song")
        _ = try reopened.removeAudio(id: recording.id)
        XCTAssertEqual(reopened.loadAll().first?.arrangement, recording.arrangement)
        XCTAssertEqual(reopened.loadAll().first?.notes, recording.notes)
    }

    @MainActor
    func testCancelledLibraryExportDoesNotSaveSong() async throws {
        let input = try makeToneFile(duration: 1.5)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: input)
            try? FileManager.default.removeItem(at: directory)
        }
        let store = FreestyleRecordingStore(documentsDirectoryURL: directory)
        let defaultsSuite = "LibraryExportTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsSuite))
        defer { defaults.removePersistentDomain(forName: defaultsSuite) }
        let model = PracticeViewModel(
            recordingStore: store,
            libraryImportAllowance: LibraryImportAllowance(defaults: defaults),
            enableAudioBindings: false
        )
        let saved = expectation(description: "Cancelled export never saves")
        saved.isInverted = true
        let observation = model.$freestyleRecordings.filter { !$0.isEmpty }.sink { _ in saved.fulfill() }
        defer { observation.cancel() }
        model.importSongFromMusicLibrary(assetURL: input, title: "Cancelled")
        model.cancelSongImport()
        XCTAssertFalse(model.isImportingSong)
        XCTAssertFalse(model.canCancelSongImport)
        await fulfillment(of: [saved], timeout: 2)
        XCTAssertTrue(store.loadAll().isEmpty)
    }

    private func makeToneFile(duration: TimeInterval) throws -> URL {
        try makeAudioFile(duration: duration, frequencies: [523.251])
    }

    private func makeAudioFile(
        duration: TimeInterval, frequencies: [Double], amplitudes: [Double]? = nil,
        channels: AVAudioChannelCount = 1, oppositePhase: Bool = false, silentUntil: TimeInterval = 0,
        sampleRate: Double = 44_100, noiseAmplitude: Double = 0
    ) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("harmonica-analyzer-\(UUID().uuidString).caf")
        var noiseState: UInt32 = 12345
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channels))
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        let total = Int(sampleRate * duration)
        var offset = 0
        while offset < total {
            let count = min(8_192, total - offset)
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(count)))
            buffer.frameLength = AVAudioFrameCount(count)
            for channel in 0..<Int(channels) {
                let samples = try XCTUnwrap(buffer.floatChannelData?[channel])
                for frame in 0..<count {
                    let time = Double(offset + frame) / sampleRate
                    let value = time < silentUntil ? 0 : frequencies.enumerated().reduce(0.0) { sum, item in
                        sum + sin(2 * .pi * item.element * time) * (amplitudes?[item.offset] ?? 0.25)
                    }
                    noiseState = noiseState &* 1_664_525 &+ 1_013_904_223
                    let noise = (Double(noiseState) / Double(UInt32.max) * 2 - 1) * noiseAmplitude
                    samples[frame] = Float((value + noise) * (oppositePhase && channel == 1 ? -1 : 1))
                }
            }
            try file.write(from: buffer)
            offset += count
        }
        return url
    }
}
