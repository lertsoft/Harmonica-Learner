import AVFoundation
import Combine
import XCTest
@testable import Harmonica

final class LibraryImportGateIntegrationTests: XCTestCase {
    @MainActor
    func testFifthSavedLibrarySongLocksFurtherImportsUntilPurchase() async throws {
        let suite = "LibraryImportGateIntegrationTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let audioURL = try makeToneFile()
        defer {
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: directory)
            try? FileManager.default.removeItem(at: audioURL)
        }

        let store = FreestyleRecordingStore(documentsDirectoryURL: directory)
        let allowance = LibraryImportAllowance(defaults: defaults)
        let model = PracticeViewModel(
            recordingStore: store,
            libraryImportAllowance: allowance,
            enableAudioBindings: false
        )

        for count in 1...LibraryImportAllowance.freeSongCount {
            let saved = expectation(description: "Saved library song \(count)")
            let observation = model.$successfulMusicLibraryImports
                .filter { $0 == count }
                .first()
                .sink { _ in saved.fulfill() }
            model.importSong(from: audioURL, titleOverride: "Song \(count)", source: .musicLibrary)
            await fulfillment(of: [saved], timeout: 10)
            observation.cancel()
        }

        XCTAssertEqual(store.loadAll().count, 5)
        model.importSong(from: audioURL, titleOverride: "Blocked", source: .musicLibrary)
        XCTAssertEqual(store.loadAll().count, 5)
        XCTAssertEqual(model.successfulMusicLibraryImports, 5)

        model.hasFullAccess = true
        let unlocked = expectation(description: "Saved song after purchase")
        let observation = model.$successfulMusicLibraryImports
            .filter { $0 == 6 }
            .first()
            .sink { _ in unlocked.fulfill() }
        model.importSong(from: audioURL, titleOverride: "Unlocked", source: .musicLibrary)
        await fulfillment(of: [unlocked], timeout: 10)
        observation.cancel()
        XCTAssertEqual(store.loadAll().count, 6)
    }

    private func makeToneFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("library-gate-\(UUID().uuidString).caf")
        let sampleRate = 44_100.0
        let frameCount = AVAudioFrameCount(sampleRate * 0.25)
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1))
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount))
        let samples = try XCTUnwrap(buffer.floatChannelData?[0])
        buffer.frameLength = frameCount
        for frame in 0..<Int(frameCount) {
            samples[frame] = Float(sin(2 * .pi * 523.251 * Double(frame) / sampleRate) * 0.4)
        }
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
        return url
    }
}
