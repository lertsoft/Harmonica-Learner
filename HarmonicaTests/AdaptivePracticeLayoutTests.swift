import XCTest
@testable import Harmonica

final class AdaptivePracticeLayoutTests: XCTestCase {
    func testSmallPhoneUsesCompactSingleColumnLayout() {
        let layout = AdaptivePracticeLayout.resolve(size: CGSize(width: 320, height: 568))

        XCTAssertTrue(layout.isCompactHeight)
        XCTAssertFalse(layout.usesTwoColumnPractice)
        XCTAssertEqual(layout.horizontalPadding, 10)
    }

    func testLargePhonePortraitUsesScrollableSingleColumnLayout() {
        let layout = AdaptivePracticeLayout.resolve(size: CGSize(width: 430, height: 932))

        XCTAssertFalse(layout.isCompactHeight)
        XCTAssertFalse(layout.usesTwoColumnPractice)
        XCTAssertEqual(layout.horizontalPadding, 16)
        XCTAssertEqual(layout.contentMaxWidth, 760)
    }

    func testPhoneLandscapeUsesCompactTwoColumnLayout() {
        let layout = AdaptivePracticeLayout.resolve(size: CGSize(width: 932, height: 430))

        XCTAssertTrue(layout.isCompactHeight)
        XCTAssertTrue(layout.usesTwoColumnPractice)
        XCTAssertEqual(layout.horizontalPadding, 24)
        XCTAssertEqual(layout.contentMaxWidth, 1_080)
    }

    func testIPadUsesWideTwoColumnLayout() {
        let layout = AdaptivePracticeLayout.resolve(size: CGSize(width: 1_024, height: 1_366))

        XCTAssertFalse(layout.isCompactHeight)
        XCTAssertTrue(layout.usesTwoColumnPractice)
        XCTAssertEqual(layout.horizontalPadding, 24)
    }

    func testAccessibilityTextUsesCompactContentSpacing() {
        let standard = AdaptivePracticeLayout.resolve(
            size: CGSize(width: 430, height: 932),
            usesAccessibilityText: false
        )
        let accessibility = AdaptivePracticeLayout.resolve(
            size: CGSize(width: 430, height: 932),
            usesAccessibilityText: true
        )

        XCTAssertEqual(standard.contentSpacing, 12)
        XCTAssertEqual(accessibility.contentSpacing, 8)
    }
}
