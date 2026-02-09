import XCTest
@testable import Harmonica

final class FreestyleRecordingStoreTests: XCTestCase {
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

    func testSaveAndLoadAllSortsByCreatedAtDescending() throws {
        let older = makeRecording(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            title: "Older",
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let newer = makeRecording(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            title: "Newer",
            createdAt: Date(timeIntervalSince1970: 200)
        )

        try store.save(older)
        try store.save(newer)

        let loaded = store.loadAll()
        XCTAssertEqual(loaded.map(\.title), ["Newer", "Older"])
    }

    func testSaveReplacesExistingRecordingWithSameID() throws {
        let id = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!
        let first = makeRecording(id: id, title: "First", createdAt: Date(timeIntervalSince1970: 100))
        let updated = makeRecording(id: id, title: "Updated", createdAt: Date(timeIntervalSince1970: 300))

        try store.save(first)
        try store.save(updated)

        let loaded = store.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.title, "Updated")
    }

    func testDeleteRemovesRecordingAndAudioFile() throws {
        let recording = makeRecording(
            id: UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!,
            audioFileName: "delete-me.m4a"
        )
        try createAudioFile(named: "delete-me.m4a")
        try store.save(recording)

        try store.delete(id: recording.id)

        XCTAssertEqual(store.loadAll(), [])
        let audioURL = store.audioURL(forFileName: "delete-me.m4a")
        XCTAssertFalse(FileManager.default.fileExists(atPath: audioURL.path))
    }

    func testRemoveAudioClearsAudioReferenceAndDeletesFile() throws {
        let recording = makeRecording(
            id: UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!,
            audioFileName: "remove-me.m4a"
        )
        try createAudioFile(named: "remove-me.m4a")
        try store.save(recording)

        let updated = try store.removeAudio(id: recording.id)

        XCTAssertEqual(updated?.id, recording.id)
        XCTAssertNil(updated?.audioFileName)
        let loaded = store.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertNil(loaded.first?.audioFileName)
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.audioURL(forFileName: "remove-me.m4a").path))
    }

    func testLoadAllDropsRecordingWhenAudioMissingAndNoNotes() throws {
        let recording = makeRecording(
            id: UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!,
            audioFileName: "missing.m4a",
            notes: []
        )
        try store.save(recording)

        let loaded = store.loadAll()

        XCTAssertEqual(loaded, [])
    }

    func testLoadAllKeepsNotesWhenAudioMissing() throws {
        let recording = makeRecording(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            audioFileName: "missing-but-keep.m4a",
            notes: [HarmonicaNoteEvent(note: "G5", duration: 0.5, hole: "6B")]
        )
        try store.save(recording)

        let loaded = store.loadAll()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertNil(loaded.first?.audioFileName)
        XCTAssertEqual(loaded.first?.notes.count, 1)
    }

    func testAudioURLForRecordingReturnsNilWhenNoAudioFileName() {
        let nilName = makeRecording(audioFileName: nil)
        let emptyName = makeRecording(audioFileName: "")

        XCTAssertNil(store.audioURL(for: nilName))
        XCTAssertNil(store.audioURL(for: emptyName))
    }

    private func makeRecording(
        id: UUID = UUID(),
        title: String = "Session",
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

    private func createAudioFile(named fileName: String) throws {
        let url = store.audioURL(forFileName: fileName)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("audio".utf8).write(to: url)
    }

    private func clearStore() {
        guard let store else { return }
        for recording in store.loadAll() {
            try? store.delete(id: recording.id)
        }
    }
}
