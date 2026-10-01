#if DEBUG
import Foundation
import AVFoundation

enum UITestFixtures {
    static func seedIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-ui-test-reset-review-prompts") {
            let defaults = UserDefaults.standard
            [
                "practice.reviewPromptedVersion",
                "practice.reviewFreestyleOfferedVersion",
                "practice.reviewImportOfferedVersion",
                "practice.reviewGuidedOfferedVersion"
            ].forEach(defaults.removeObject(forKey:))
        }

        guard arguments.contains("-ui-test-seed-recording") else { return }
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

    /// Exercises the real local audio import path, not preconstructed tablature.
    static func importChordIfRequested(into model: PracticeViewModel) {
        guard ProcessInfo.processInfo.arguments.contains("-ui-test-import-chord") else { return }
        let title = "UI Chord Arrangement"
        // A rerun imports afresh so changes to the analyzer are exercised.
        let store = FreestyleRecordingStore()
        for existing in store.loadAll() where existing.title == title { try? store.delete(id: existing.id) }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("chord-journey.caf")
        do {
            let rate = 44_100.0
            let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1)!
            let frames = AVAudioFrameCount(rate * 6)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
            buffer.frameLength = frames
            for frame in 0..<Int(frames) {
                let time = Double(frame) / rate
                let frequencies: [Double] = [523.251, 659.255, 783.991]
                var value = 0.0
                for frequency in frequencies { value += 0.2 * sin(2 * Double.pi * frequency * time) }
                buffer.floatChannelData![0][frame] = Float(value)
            }
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            try file.write(from: buffer)
        } catch { return }
        model.importSong(from: url, titleOverride: title)
        try? FileManager.default.removeItem(at: url)
    }

}
#endif
