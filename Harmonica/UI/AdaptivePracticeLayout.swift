import CoreGraphics

struct AdaptivePracticeLayout: Equatable {
    let isWide: Bool
    let isCompactHeight: Bool
    let horizontalPadding: CGFloat
    let contentMaxWidth: CGFloat
    let contentSpacing: CGFloat

    var usesTwoColumnPractice: Bool {
        isWide
    }

    static func resolve(
        size: CGSize,
        usesAccessibilityText: Bool = false
    ) -> AdaptivePracticeLayout {
        let width = max(0, size.width)
        let height = max(0, size.height)
        let isWide = width >= 700
        let isCompactHeight = height < 620

        let horizontalPadding: CGFloat
        if width < 360 {
            horizontalPadding = 10
        } else if isWide {
            horizontalPadding = 24
        } else {
            horizontalPadding = 16
        }

        return AdaptivePracticeLayout(
            isWide: isWide,
            isCompactHeight: isCompactHeight,
            horizontalPadding: horizontalPadding,
            contentMaxWidth: isWide ? 1_080 : 760,
            contentSpacing: isCompactHeight || usesAccessibilityText ? 8 : 12
        )
    }
}
