import SwiftUI

enum OnboardingCoachTarget: Hashable {
    case practiceStyle
    case songLibrary
    case targetNote
    case primaryAction
}

struct OnboardingCoachTargetKey: PreferenceKey {
    static var defaultValue: [OnboardingCoachTarget: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [OnboardingCoachTarget: Anchor<CGRect>],
        nextValue: () -> [OnboardingCoachTarget: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, newest in newest })
    }
}

extension View {
    func onboardingCoachTarget(_ target: OnboardingCoachTarget) -> some View {
        anchorPreference(key: OnboardingCoachTargetKey.self, value: .bounds) { [target: $0] }
    }
}

struct OnboardingCoachOverlay: View {
    let stepIndex: Int
    let targetFrame: CGRect?
    let onBack: () -> Void
    let onNext: () -> Void
    let onFinishWithMicrophone: () -> Void
    let onFinishWithoutMicrophone: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let accent = AppColors.cyanAccent

    var body: some View {
        GeometryReader { proxy in
            let guide = guideForCurrentStep
            let target = targetFrame ?? fallbackTarget(in: proxy.size)
            let callout = calloutLayout(
                for: target,
                in: proxy.size,
                preferredPlacement: guide.placement,
                height: calloutHeight(for: guide, in: proxy.size)
            )

            ZStack {
                dimmedBackground(cutout: target)

                RoundedRectangle(cornerRadius: guide.cornerRadius)
                    .stroke(accent, lineWidth: 3)
                    .frame(width: target.width + 12, height: target.height + 12)
                    .position(x: target.midX, y: target.midY)
                    .shadow(color: accent.opacity(0.65), radius: 8)

                calloutContent(
                    guide,
                    placement: callout.placement,
                    caretOffset: callout.caretOffset
                )
                    .frame(width: callout.frame.width, height: callout.frame.height, alignment: .topLeading)
                    .position(x: callout.frame.midX, y: callout.frame.midY)

                if exposesLayoutProbes {
                    layoutProbe(identifier: "onboarding-highlight-frame", frame: target.insetBy(dx: -6, dy: -6))
                    layoutProbe(identifier: "onboarding-callout-frame", frame: callout.frame)
                }

                progressHeader
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .contentShape(Rectangle())
        }
        .ignoresSafeArea(edges: .bottom)
        .accessibilityAddTraits(overlayAccessibilityTraits)
    }

    private var progressHeader: some View {
        HStack(spacing: 10) {
            if stepIndex > 0 {
                Button(action: onBack) {
                    Label("Back", systemImage: "chevron.left")
                        .frame(minHeight: 44)
                }
            }

            Spacer()

            Text("QUICK TOUR  \(stepIndex + 1) / \(Self.guides.count)")
                .font(AppTypography.sectionLabel)
                .tracking(1.2)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(minHeight: 36)
                .background(Capsule().fill(Color.black.opacity(0.78)))

            Spacer()

            Button("Skip") { onFinishWithoutMicrophone() }
                .frame(minWidth: 44, minHeight: 44)
        }
        .font(AppTypography.caption.weight(.semibold))
        .foregroundStyle(.white)
        .buttonStyle(.plain)
    }

    private func calloutContent(
        _ guide: Guide,
        placement: Placement,
        caretOffset: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(guide.title)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(guide.lines, id: \.self) { line in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("•")
                                    .foregroundStyle(accent)
                                Text(LocalizedStringKey(line))
                                    .foregroundStyle(.white.opacity(0.96))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .lineSpacing(3)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)

            Button(action: stepIndex == Self.guides.count - 1 ? onFinishWithMicrophone : onNext) {
                Text(stepIndex == Self.guides.count - 1 ? "Allow Mic & Start Playing" : "Next")
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(StudioControlButtonStyle(isProminent: true, tint: AppGradients.primary))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, placement == .trailing ? 30 : 18)
        .padding(.trailing, placement == .leading ? 30 : 18)
        .padding(.top, placement == .below ? 28 : 18)
        .padding(.bottom, placement == .above ? 28 : 18)
        .background {
            TooltipBubbleShape(placement: placement, caretOffset: caretOffset)
                .fill(Color.black.opacity(0.95))
                .overlay {
                    TooltipBubbleShape(placement: placement, caretOffset: caretOffset)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.48), radius: 18, y: 8)
        }
    }

    private func dimmedBackground(cutout: CGRect) -> some View {
        Color.black.opacity(0.68)
            .mask {
                Rectangle()
                    .overlay {
                        RoundedRectangle(cornerRadius: guideForCurrentStep.cornerRadius)
                            .frame(width: cutout.width + 18, height: cutout.height + 18)
                            .position(x: cutout.midX, y: cutout.midY)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
            }
    }

    private var guideForCurrentStep: Guide {
        Self.guides[min(max(stepIndex, 0), Self.guides.count - 1)]
    }

    private var exposesLayoutProbes: Bool {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains("-ui-test-onboarding-layout-probes")
#else
        false
#endif
    }

    private var overlayAccessibilityTraits: AccessibilityTraits {
        exposesLayoutProbes ? [] : .isModal
    }

    private func layoutProbe(identifier: String, frame: CGRect) -> some View {
        Color.clear
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(identifier)
            .accessibilityIdentifier(identifier)
    }

    private func calloutHeight(for guide: Guide, in size: CGSize) -> CGFloat {
        let maximumHeight = max(180, size.height - 86)
        let desiredHeight = dynamicTypeSize.isAccessibilitySize ? guide.height * 1.35 : guide.height
        return min(desiredHeight, maximumHeight)
    }

    private func calloutLayout(
        for target: CGRect,
        in size: CGSize,
        preferredPlacement: Placement,
        height: CGFloat
    ) -> CalloutLayout {
        let horizontalMargin: CGFloat = 19
        let topMargin: CGFloat = 64
        let bottomMargin: CGFloat = 22
        let gap: CGFloat = 14
        let viewport = CGRect(
            x: horizontalMargin,
            y: topMargin,
            width: max(1, size.width - horizontalMargin * 2),
            height: max(1, size.height - topMargin - bottomMargin)
        )
        let verticalWidth = min(360, viewport.width)
        let sideWidth = min(360, min(viewport.width, max(220, viewport.width * 0.44)))
        let verticalX = clamped(
            target.midX - verticalWidth / 2,
            minimum: viewport.minX,
            maximum: viewport.maxX - verticalWidth
        )
        let sideY = clamped(
            target.midY - height / 2,
            minimum: viewport.minY,
            maximum: viewport.maxY - height
        )

        let candidates: [CalloutLayout] = [
            CalloutLayout(
                frame: CGRect(x: verticalX, y: target.maxY + gap, width: verticalWidth, height: height),
                placement: .below,
                caretOffset: 0
            ),
            CalloutLayout(
                frame: CGRect(x: verticalX, y: target.minY - height - gap, width: verticalWidth, height: height),
                placement: .above,
                caretOffset: 0
            ),
            CalloutLayout(
                frame: CGRect(x: target.maxX + gap, y: sideY, width: sideWidth, height: height),
                placement: .trailing,
                caretOffset: 0
            ),
            CalloutLayout(
                frame: CGRect(x: target.minX - sideWidth - gap, y: sideY, width: sideWidth, height: height),
                placement: .leading,
                caretOffset: 0
            )
        ]
        let preferredOrder: [Placement]
        if size.width > size.height {
            let roomOnLeading = target.minX - viewport.minX
            let roomOnTrailing = viewport.maxX - target.maxX
            let roomierSide: Placement = roomOnTrailing >= roomOnLeading ? .trailing : .leading
            preferredOrder = [roomierSide, roomierSide == .trailing ? .leading : .trailing, preferredPlacement, preferredPlacement.opposite]
        } else {
            preferredOrder = [preferredPlacement, preferredPlacement.opposite, .trailing, .leading]
        }

        let expandedTarget = target.insetBy(dx: -8, dy: -8)
        for placement in preferredOrder {
            guard let candidate = candidates.first(where: { $0.placement == placement }) else { continue }
            if viewport.contains(candidate.frame), !candidate.frame.intersects(expandedTarget) {
                return candidate.withCaret(pointingAt: target)
            }
        }

        let clampedCandidates = preferredOrder.compactMap { placement in
            candidates.first(where: { $0.placement == placement })?.clamped(to: viewport)
        }
        let leastObstructive = clampedCandidates.min { lhs, rhs in
            lhs.frame.intersection(expandedTarget).area < rhs.frame.intersection(expandedTarget).area
        } ?? candidates[0].clamped(to: viewport)
        return leastObstructive.withCaret(pointingAt: target)
    }

    private func clamped(_ value: CGFloat, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
        min(max(minimum, value), max(minimum, maximum))
    }

    private func fallbackTarget(in size: CGSize) -> CGRect {
        CGRect(x: size.width * 0.2, y: size.height * 0.18, width: size.width * 0.6, height: 50)
    }

    private enum Placement: Equatable {
        case below
        case above
        case leading
        case trailing

        var opposite: Placement {
            switch self {
            case .below: .above
            case .above: .below
            case .leading: .trailing
            case .trailing: .leading
            }
        }
    }

    private struct CalloutLayout {
        let frame: CGRect
        let placement: Placement
        let caretOffset: CGFloat

        func clamped(to viewport: CGRect) -> CalloutLayout {
            let x = min(max(viewport.minX, frame.minX), max(viewport.minX, viewport.maxX - frame.width))
            let y = min(max(viewport.minY, frame.minY), max(viewport.minY, viewport.maxY - frame.height))
            return CalloutLayout(
                frame: CGRect(x: x, y: y, width: frame.width, height: frame.height),
                placement: placement,
                caretOffset: caretOffset
            )
        }

        func withCaret(pointingAt target: CGRect) -> CalloutLayout {
            let offset: CGFloat
            switch placement {
            case .above, .below:
                offset = target.midX - frame.minX
            case .leading, .trailing:
                offset = target.midY - frame.minY
            }
            return CalloutLayout(frame: frame, placement: placement, caretOffset: offset)
        }
    }

    private struct TooltipBubbleShape: Shape {
        let placement: Placement
        let caretOffset: CGFloat

        func path(in rect: CGRect) -> Path {
            switch placement {
            case .above, .below:
                verticalPath(in: rect)
            case .leading, .trailing:
                horizontalPath(in: rect)
            }
        }

        private func verticalPath(in rect: CGRect) -> Path {
            let radius: CGFloat = 22
            let caretHeight: CGFloat = 12
            let caretHalfWidth: CGFloat = 12
            let pointsUp: Bool
            switch placement {
            case .below: pointsUp = true
            case .above, .leading, .trailing: pointsUp = false
            }
            let cardMinY = pointsUp ? caretHeight : 0
            let cardMaxY = pointsUp ? rect.maxY : rect.maxY - caretHeight
            let safeCaretX = min(max(caretOffset, radius + caretHalfWidth), rect.maxX - radius - caretHalfWidth)

            var path = Path()
            path.move(to: CGPoint(x: radius, y: cardMinY))

            if pointsUp {
                path.addLine(to: CGPoint(x: safeCaretX - caretHalfWidth, y: cardMinY))
                path.addLine(to: CGPoint(x: safeCaretX, y: rect.minY))
                path.addLine(to: CGPoint(x: safeCaretX + caretHalfWidth, y: cardMinY))
            }

            path.addLine(to: CGPoint(x: rect.maxX - radius, y: cardMinY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: cardMinY + radius),
                control: CGPoint(x: rect.maxX, y: cardMinY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: cardMaxY - radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - radius, y: cardMaxY),
                control: CGPoint(x: rect.maxX, y: cardMaxY)
            )

            if !pointsUp {
                path.addLine(to: CGPoint(x: safeCaretX + caretHalfWidth, y: cardMaxY))
                path.addLine(to: CGPoint(x: safeCaretX, y: rect.maxY))
                path.addLine(to: CGPoint(x: safeCaretX - caretHalfWidth, y: cardMaxY))
            }

            path.addLine(to: CGPoint(x: radius, y: cardMaxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: cardMaxY - radius),
                control: CGPoint(x: rect.minX, y: cardMaxY)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: cardMinY + radius))
            path.addQuadCurve(
                to: CGPoint(x: radius, y: cardMinY),
                control: CGPoint(x: rect.minX, y: cardMinY)
            )
            path.closeSubpath()
            return path
        }

        private func horizontalPath(in rect: CGRect) -> Path {
            let radius: CGFloat = 22
            let caretWidth: CGFloat = 12
            let caretHalfHeight: CGFloat = 12
            let pointsLeft: Bool
            switch placement {
            case .trailing: pointsLeft = true
            case .above, .below, .leading: pointsLeft = false
            }
            let cardMinX = pointsLeft ? caretWidth : 0
            let cardMaxX = pointsLeft ? rect.maxX : rect.maxX - caretWidth
            let safeCaretY = min(max(caretOffset, radius + caretHalfHeight), rect.maxY - radius - caretHalfHeight)

            var path = Path()
            path.move(to: CGPoint(x: cardMinX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: cardMaxX - radius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: cardMaxX, y: rect.minY + radius),
                control: CGPoint(x: cardMaxX, y: rect.minY)
            )

            if !pointsLeft {
                path.addLine(to: CGPoint(x: cardMaxX, y: safeCaretY - caretHalfHeight))
                path.addLine(to: CGPoint(x: rect.maxX, y: safeCaretY))
                path.addLine(to: CGPoint(x: cardMaxX, y: safeCaretY + caretHalfHeight))
            }

            path.addLine(to: CGPoint(x: cardMaxX, y: rect.maxY - radius))
            path.addQuadCurve(
                to: CGPoint(x: cardMaxX - radius, y: rect.maxY),
                control: CGPoint(x: cardMaxX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: cardMinX + radius, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: cardMinX, y: rect.maxY - radius),
                control: CGPoint(x: cardMinX, y: rect.maxY)
            )

            if pointsLeft {
                path.addLine(to: CGPoint(x: cardMinX, y: safeCaretY + caretHalfHeight))
                path.addLine(to: CGPoint(x: rect.minX, y: safeCaretY))
                path.addLine(to: CGPoint(x: cardMinX, y: safeCaretY - caretHalfHeight))
            }

            path.addLine(to: CGPoint(x: cardMinX, y: rect.minY + radius))
            path.addQuadCurve(
                to: CGPoint(x: cardMinX + radius, y: rect.minY),
                control: CGPoint(x: cardMinX, y: rect.minY)
            )
            path.closeSubpath()
            return path
        }
    }

    private struct Guide {
        let title: String
        let lines: [String]
        let placement: Placement
        let cornerRadius: CGFloat
        let height: CGFloat
    }

    private static let guides: [Guide] = [
        Guide(
            title: "Pick your track",
            lines: ["Explore built-in classics, import your own tabs, or return to recent favorites."],
            placement: .below,
            cornerRadius: 24,
            height: 230
        ),
        Guide(
            title: "Read harmonica tabs instantly",
            lines: ["**+** means blow out, **−** means draw in. Match the target hole and hold the note until it turns green."],
            placement: .below,
            cornerRadius: 14,
            height: 260
        ),
        Guide(
            title: "Choose how you play",
            lines: [
                "**Guided:** Follow songs note by note with live pitch feedback.",
                "**Freestyle:** Play anything; the app tracks and transcribes your notes."
            ],
            placement: .below,
            cornerRadius: 14,
            height: 270
        ),
        Guide(
            title: "Tap to listen & score",
            lines: [
                "Tap **Start Practice** to activate real-time pitch detection. The app only listens when you're ready.",
                "Pitch detection happens entirely on-device."
            ],
            placement: .above,
            cornerRadius: 16,
            height: 280
        )
    ]
}

private extension CGRect {
    var area: CGFloat {
        guard !isNull, !isInfinite else { return 0 }
        return max(0, width) * max(0, height)
    }
}
