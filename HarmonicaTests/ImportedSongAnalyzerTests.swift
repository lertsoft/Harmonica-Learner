import XCTest
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
        XCTAssertEqual(events.map(\.duration), [0.25, 0.25])
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

    func testFallbackPhraseIsPlayableOnSelectedLayout() {
        let events = ImportedSongAnalyzer.fallbackPhrase(layout: .diatonicC)

        XCTAssertFalse(events.isEmpty)
        XCTAssertTrue(events.allSatisfy { HarmonicaHole.fromCode($0.hole) != nil })
        XCTAssertTrue(events.allSatisfy { HarmonicaLayout.diatonicC.hole(for: $0.note) != nil })
    }
}
