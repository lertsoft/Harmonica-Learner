import XCTest
@testable import Harmonica

final class HarmonicaLayoutTests: XCTestCase {
    func testHoleLookupReturnsExpectedMapping() {
        let hole = HarmonicaLayout.diatonicC.hole(for: "C5")

        XCTAssertEqual(hole, HarmonicaHole(index: 4, airflow: .blow))
    }

    func testHoleLookupReturnsNilForUnknownNote() {
        XCTAssertNil(HarmonicaLayout.diatonicC.hole(for: "F#4"))
    }

    func testNoteToHoleContainsExpectedNumberOfEntries() {
        XCTAssertEqual(HarmonicaLayout.diatonicC.noteToHole.count, 19)
    }

    func testLeeOskarSharesCurrentMappingSet() {
        XCTAssertEqual(HarmonicaLayout.leeOskarC.noteToHole, HarmonicaLayout.diatonicC.noteToHole)
    }
}
