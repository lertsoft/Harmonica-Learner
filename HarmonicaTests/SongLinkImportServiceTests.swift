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

    func testRejectsNonHTTPLinks() {
        XCTAssertThrowsError(try SongLinkDescriptor.parse("file:///tmp/song.m4a"))
        XCTAssertThrowsError(try SongLinkDescriptor.parse("not a link"))
    }

    func testBackendEventsAreClampedAndRemappedToSelectedLayout() {
        let events = [
            HarmonicaNoteEvent(note: "C5", duration: 12, hole: "wrong"),
            HarmonicaNoteEvent(note: "C#5", duration: 0.01, hole: "wrong"),
            HarmonicaNoteEvent(note: "D5", duration: 0.01, hole: "wrong")
        ]

        let playable = SongLinkImportService.playableEvents(from: events, layout: .diatonicC)

        XCTAssertEqual(playable.map(\.note), ["C5", "D5"])
        XCTAssertEqual(playable.map(\.hole), ["4B", "4D"])
        XCTAssertEqual(playable.map(\.duration), [4, 0.1])
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
