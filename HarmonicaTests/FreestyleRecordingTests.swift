import XCTest
@testable import Harmonica

final class FreestyleRecordingTests: XCTestCase {
    func testHasAudioPlaybackReflectsAudioFileNamePresence() {
        let withAudio = makeRecording(audioFileName: "sample.m4a")
        let noAudio = makeRecording(audioFileName: nil)
        let emptyAudioName = makeRecording(audioFileName: "")

        XCTAssertTrue(withAudio.hasAudioPlayback)
        XCTAssertFalse(noAudio.hasAudioPlayback)
        XCTAssertFalse(emptyAudioName.hasAudioPlayback)
    }

    func testAsSongMapsFreestyleRecordingFields() {
        let note = HarmonicaNoteEvent(note: "C5", duration: 0.5, hole: "4B")
        let recording = makeRecording(title: "Session", key: "G", notes: [note])

        let song = recording.asSong

        XCTAssertEqual(song.songTitle, "Session")
        XCTAssertEqual(song.bpm, 90)
        XCTAssertEqual(song.key, "G")
        XCTAssertEqual(song.notes, [note])
        XCTAssertEqual(song.id, "Session")
    }

    func testMakeTitleUsesExpectedPrefixAndIDFragment() {
        let id = UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!
        let title = FreestyleRecording.makeTitle(for: Date(timeIntervalSince1970: 0), id: id)

        XCTAssertTrue(title.hasPrefix("Freestyle • "))
        XCTAssertTrue(title.hasSuffix(" • 1234"))
    }

    private func makeRecording(
        id: UUID = UUID(),
        title: String = "Freestyle",
        createdAt: Date = Date(),
        key: String = "C",
        layoutRawValue: String = HarmonicaLayout.diatonicC.rawValue,
        audioFileName: String? = "clip.m4a",
        notes: [HarmonicaNoteEvent] = [HarmonicaNoteEvent(note: "C5", duration: 0.5, hole: "4B")],
        duration: TimeInterval = 2
    ) -> FreestyleRecording {
        FreestyleRecording(
            id: id,
            title: title,
            createdAt: createdAt,
            key: key,
            layoutRawValue: layoutRawValue,
            audioFileName: audioFileName,
            notes: notes,
            duration: duration
        )
    }
}
