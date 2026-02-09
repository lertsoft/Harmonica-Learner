import XCTest
@testable import Harmonica

final class HarmonicaHoleTests: XCTestCase {
    func testFromCodeParsesBlowHole() {
        let hole = HarmonicaHole.fromCode("4B")

        XCTAssertEqual(hole, HarmonicaHole(index: 4, airflow: .blow))
    }

    func testFromCodeParsesDrawHoleCaseInsensitively() {
        let hole = HarmonicaHole.fromCode("7d")

        XCTAssertEqual(hole, HarmonicaHole(index: 7, airflow: .draw))
    }

    func testFromCodeTrimsWhitespace() {
        let hole = HarmonicaHole.fromCode(" 10B\n")

        XCTAssertEqual(hole, HarmonicaHole(index: 10, airflow: .blow))
    }

    func testFromCodeRejectsInvalidInputs() {
        XCTAssertNil(HarmonicaHole.fromCode(""))
        XCTAssertNil(HarmonicaHole.fromCode("7"))
        XCTAssertNil(HarmonicaHole.fromCode("BD"))
        XCTAssertNil(HarmonicaHole.fromCode("3X"))
    }

    func testDisplayNameAndID() {
        let hole = HarmonicaHole(index: 6, airflow: .draw)

        XCTAssertEqual(hole.id, "6-draw")
        XCTAssertEqual(hole.displayName, "6 Draw")
    }
}
