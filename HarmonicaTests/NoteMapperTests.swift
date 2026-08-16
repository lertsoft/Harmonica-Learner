import XCTest
@testable import Harmonica

final class NoteMapperTests: XCTestCase {
    func testFrequencyAndMIDIRoundTripForScientificNoteName() {
        XCTAssertEqual(NoteMapper.midiNumber(for: "A4"), 69)
        XCTAssertEqual(NoteMapper.frequency(for: "A4") ?? 0, 440, accuracy: 0.0001)
        XCTAssertNil(NoteMapper.frequency(for: "not-a-note"))
    }
    func testPitchMapsConcertA() {
        let mapped = NoteMapper.pitch(for: 440)

        XCTAssertNotNil(mapped)
        XCTAssertEqual(mapped?.noteName, "A")
        XCTAssertEqual(mapped?.octave, 4)
        XCTAssertEqual(mapped?.centsOffset ?? 999, 0, accuracy: 0.0001)
    }

    func testPitchMapsCSharp4() {
        let mapped = NoteMapper.pitch(for: 277.1826309768721)

        XCTAssertNotNil(mapped)
        XCTAssertEqual(mapped?.noteName, "C#")
        XCTAssertEqual(mapped?.octave, 4)
    }

    func testPitchReturnsNilForNonPositiveFrequency() {
        XCTAssertNil(NoteMapper.pitch(for: 0))
        XCTAssertNil(NoteMapper.pitch(for: -1))
    }

    func testCentsOffsetIsPositiveWhenFrequencyAboveReference() {
        let mapped = NoteMapper.pitch(for: 445)

        XCTAssertNotNil(mapped)
        XCTAssertEqual(mapped?.noteName, "A")
        XCTAssertEqual(mapped?.octave, 4)
        XCTAssertGreaterThan(mapped?.centsOffset ?? 0, 0)
    }

    func testCentsOffsetIsNegativeWhenFrequencyBelowReference() {
        let mapped = NoteMapper.pitch(for: 435)

        XCTAssertNotNil(mapped)
        XCTAssertEqual(mapped?.noteName, "A")
        XCTAssertEqual(mapped?.octave, 4)
        XCTAssertLessThan(mapped?.centsOffset ?? 0, 0)
    }
}
