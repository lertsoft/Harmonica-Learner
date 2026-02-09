import XCTest
@testable import Harmonica

@MainActor
final class PracticeViewModelTests: XCTestCase {
    private var store: FreestyleRecordingStore!

    override func setUpWithError() throws {
        store = FreestyleRecordingStore()
        clearStore()
    }

    override func tearDown() {
        clearStore()
        store = nil
        super.tearDown()
    }

    func testStartNewAttemptIncrementsAttemptAndResetsProgress() {
        let viewModel = makeViewModelWithSong(["A4", "B4"])
        viewModel.currentNoteIndex = 1
        viewModel.matchState = .hit

        viewModel.startNewAttempt()

        XCTAssertEqual(viewModel.attemptCount, 1)
        XCTAssertEqual(viewModel.currentNoteIndex, 0)
        XCTAssertEqual(viewModel.matchState, .idle)
    }

    func testHandleFrequencyWithoutSignalResetsDetectedPitchAndMatchState() {
        let viewModel = makeViewModelWithSong(["A4"])
        viewModel.handleFrequency(440, amplitude: 0.2)
        XCTAssertNotNil(viewModel.detectedPitch)

        viewModel.handleFrequency(10, amplitude: 0)

        XCTAssertNil(viewModel.detectedPitch)
        XCTAssertEqual(viewModel.matchState, .idle)
    }

    func testHandleFrequencyAdvancesAfterThreeConsecutiveHits() {
        let viewModel = makeViewModelWithSong(["A4", "B4"])

        viewModel.handleFrequency(440, amplitude: 0.2)
        viewModel.handleFrequency(440, amplitude: 0.2)
        XCTAssertEqual(viewModel.currentNoteIndex, 0)

        viewModel.handleFrequency(440, amplitude: 0.2)

        XCTAssertEqual(viewModel.currentNoteIndex, 1)
        XCTAssertEqual(viewModel.matchState, .hit)
    }

    func testMissResetsHitStreakSoThreeNewHitsAreRequired() {
        let viewModel = makeViewModelWithSong(["A4", "B4"])

        viewModel.handleFrequency(440, amplitude: 0.2)
        viewModel.handleFrequency(440, amplitude: 0.2)
        viewModel.handleFrequency(523.251, amplitude: 0.2)

        viewModel.handleFrequency(440, amplitude: 0.2)
        viewModel.handleFrequency(440, amplitude: 0.2)
        XCTAssertEqual(viewModel.currentNoteIndex, 0)

        viewModel.handleFrequency(440, amplitude: 0.2)
        XCTAssertEqual(viewModel.currentNoteIndex, 1)
    }

    func testFreestyleModeSkipsNoteMatchingProgress() {
        let viewModel = makeViewModelWithSong(["A4", "B4"])
        viewModel.enterFreestyleMode()

        viewModel.handleFrequency(440, amplitude: 0.2)
        viewModel.handleFrequency(440, amplitude: 0.2)
        viewModel.handleFrequency(440, amplitude: 0.2)

        XCTAssertEqual(viewModel.currentNoteIndex, 0)
        XCTAssertEqual(viewModel.matchState, .idle)
    }

    func testCurrentTargetHoleReflectsLayoutForCurrentNote() {
        let viewModel = makeViewModelWithSong(["C5"])
        viewModel.selectedLayout = .diatonicC

        XCTAssertEqual(viewModel.currentTargetHole, HarmonicaHole(index: 4, airflow: .blow))
    }

    func testHandleSelectedSongChangeResetsStateWhenSwitchingSongs() {
        let viewModel = makeViewModelWithSong(["A4", "B4"])
        let oldSong = viewModel.selectedSong
        let newSong = makeSong(title: "New Song", notes: ["C5"])

        viewModel.currentNoteIndex = 1
        viewModel.matchState = .hit
        viewModel.handleSelectedSongChange(from: oldSong, to: newSong)

        XCTAssertEqual(viewModel.currentNoteIndex, 0)
        XCTAssertEqual(viewModel.matchState, .idle)
    }

    func testHandleSelectedSongChangeIsNoOpWhenSongIDUnchanged() {
        let viewModel = makeViewModelWithSong(["A4", "B4"])
        let song = viewModel.selectedSong

        viewModel.currentNoteIndex = 1
        viewModel.matchState = .hit
        viewModel.handleSelectedSongChange(from: song, to: song)

        XCTAssertEqual(viewModel.currentNoteIndex, 1)
        XCTAssertEqual(viewModel.matchState, .hit)
    }

    private func makeViewModelWithSong(_ notes: [String]) -> PracticeViewModel {
        let viewModel = PracticeViewModel(recordingStore: store, enableAudioBindings: false)
        let song = makeSong(title: "Test Song", notes: notes)
        viewModel.songs = [song]
        viewModel.selectedSong = song
        return viewModel
    }

    private func makeSong(title: String, notes: [String]) -> HarmonicaSong {
        let mappedNotes = notes.enumerated().map { index, note in
            HarmonicaNoteEvent(note: note, duration: 0.5 + Double(index) * 0.1, hole: "4B")
        }
        return HarmonicaSong(songTitle: title, bpm: 90, key: "C", notes: mappedNotes)
    }

    private func clearStore() {
        guard let store else { return }
        for recording in store.loadAll() {
            try? store.delete(id: recording.id)
        }
    }
}
