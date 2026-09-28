#if DEBUG
import Foundation

enum UITestFixtures {
    static func seedIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-ui-test-seed-recording") else { return }
        let id = UUID(uuidString: "84781077-38A0-43E9-B6FA-388D1648D277")!
        let store = FreestyleRecordingStore()
        guard !store.loadAll().contains(where: { $0.id == id }) else { return }
        let recording = FreestyleRecording(
            id: id,
            title: "UI Test Session",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            key: "C",
            layoutRawValue: HarmonicaLayout.diatonicC.rawValue,
            audioFileName: nil,
            notes: [
                HarmonicaNoteEvent(note: "C5", duration: 0.5, hole: "4B"),
                HarmonicaNoteEvent(note: "D5", duration: 0.5, hole: "4D")
            ],
            duration: 1
        )
        try? store.save(recording)
    }
}
#endif
