import XCTest
@testable import Harmonica

@MainActor
final class SongLinkImportServiceTests: XCTestCase {
    func testRecognizesSupportedStreamingProviders() throws {
        XCTAssertEqual(
            try SongLinkDescriptor.parse("https://open.spotify.com/track/abc").provider,
            .spotify
        )
        XCTAssertEqual(
            try SongLinkDescriptor.parse("https://youtu.be/abc").provider,
            .youtube
        )
        XCTAssertEqual(
            try SongLinkDescriptor.parse("https://music.apple.com/us/song/example/123").provider,
            .appleMusic
        )
    }

    func testRecognizesDirectAudioLink() throws {
        let descriptor = try SongLinkDescriptor.parse("https://example.com/music/demo.M4A?download=1")
        XCTAssertEqual(descriptor.provider, .directAudio)
    }

    func testLookalikeDomainIsNotRecognizedAsProvider() throws {
        let descriptor = try SongLinkDescriptor.parse("https://open.spotify.com.evil.example/track/abc")
        XCTAssertEqual(descriptor.provider, .web)
    }

    func testBackendEventsAreAdaptedWithoutDroppingChromaticNotesOrLongDurations() {
        let events = [
            HarmonicaNoteEvent(note: "C5", duration: 12, hole: "wrong"),
            HarmonicaNoteEvent(note: "C#5", duration: 0.01, hole: "wrong"),
            HarmonicaNoteEvent(note: "D5", duration: 0.1, hole: "wrong")
        ]

        let playable = SongLinkImportService.playableEvents(from: events, layout: .diatonicC)

        XCTAssertEqual(playable.map(\.note), ["C5", "C5", "D5"])
        XCTAssertEqual(playable.map(\.hole), ["4B", "4B", "4D"])
        for (event, duration) in zip(playable, [12.0, 0.08, 0.1]) {
            XCTAssertEqual(event.duration, duration, accuracy: 0.00001)
        }
    }

    func testTimedServiceChordsAndRestsSurviveArrangement() throws {
        let events = ["C5", "E5", "G5"].map {
            HarmonicaNoteEvent(note: $0, duration: 0.6, hole: "ignored", startTime: 0.3)
        }
        let arrangement = SongLinkImportService.arrange(events: events, layout: .diatonicC)
        XCTAssertEqual(arrangement.summary.detectedChordCount, 1)
        XCTAssertEqual(arrangement.notes.map(\.note), ["C5", "E5", "G5"])
        XCTAssertEqual(try XCTUnwrap(arrangement.notes.first?.startTime), 0.3, accuracy: 0.001)
    }

    func testServiceRetainsMoreThan512NotesAndRejectsInvalidNumbers() {
        var events = (0..<600).map {
            HarmonicaNoteEvent(note: $0.isMultiple(of: 2) ? "C5" : "D5", duration: 0.1, hole: "ignored")
        }
        events.append(HarmonicaNoteEvent(note: "C5", duration: .infinity, hole: "ignored"))
        events.append(HarmonicaNoteEvent(note: "C5", duration: .nan, hole: "ignored"))
        let notes = SongLinkImportService.playableEvents(from: events, layout: .diatonicC)
        XCTAssertEqual(notes.count, 600)
    }

    func testProtectedProviderExplainsLicensedServiceRequirementWhenUnconfigured() async throws {
        let descriptor = try SongLinkDescriptor.parse("https://open.spotify.com/track/abc")
        let service = SongLinkImportService(transcriptionEndpoint: nil)

        do {
            _ = try await service.resolve(descriptor, layout: .diatonicC, key: "C")
            XCTFail("Expected a licensed-service error")
        } catch let error as SongLinkImportError {
            XCTAssertEqual(error, .licensedServiceRequired(.spotify))
        }
    }
}
