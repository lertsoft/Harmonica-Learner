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

            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 12) {
                    progressHeader
                    calloutContent(
                        guide,
                        placement: .below,
                        caretOffset: proxy.size.width / 2,
                        isCompact: false
                    )
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(16)
                .background(AppColors.backgroundDeep)
            } else {
                ZStack {
                    dimmedBackground(cutout: target)

                    spotlightHighlight(target: target, guide: guide)

                    calloutContent(
                        guide,
                        placement: callout.placement,
                        caretOffset: callout.caretOffset,
                        isCompact: proxy.size.height < 500
                    )
                    .frame(width: callout.frame.width, height: callout.frame.height, alignment: .topLeading)
                    .position(x: callout.frame.midX, y: callout.frame.midY)

                    if exposesLayoutProbes {
                        layoutProbe(identifier: "onboarding-highlight-frame", frame: target.insetBy(dx: -6, dy: -6))
                        layoutProbe(identifier: "onboarding-callout-frame", frame: callout.frame)
                    }

                    progressHeader
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                .contentShape(Rectangle())
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .accessibilityAddTraits(overlayAccessibilityTraits)
    }

    // MARK: - Spotlight Highlight
    @ViewBuilder
    private func spotlightHighlight(target: CGRect, guide: Guide) -> some View {
        if guide.isCircular {
            let diameter = max(target.width, target.height) + 12
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .frame(width: diameter, height: diameter)
                .position(x: target.midX, y: target.midY)
                .shadow(color: accent.opacity(0.65), radius: 10)
        } else {
            RoundedRectangle(cornerRadius: guide.cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .frame(width: target.width + 12, height: target.height + 12)
                .position(x: target.midX, y: target.midY)
                .shadow(color: accent.opacity(0.65), radius: 10)
        }
    }

    // MARK: - Top Navigation Header
    private var progressHeader: some View {
        HStack(spacing: 10) {
            if stepIndex > 0 {
                Button(action: onBack) {
                    Label("Back", systemImage: "chevron.left")
                        .frame(minHeight: 44)
                }
            }

            Spacer()

            // Segmented story progress indicator
            HStack(spacing: 5) {
                if !dynamicTypeSize.isAccessibilitySize {
                    ForEach(0..<Self.guides.count, id: \.self) { index in
                        Capsule()
                            .fill(index <= stepIndex ? accent : Color.white.opacity(0.22))
                            .frame(width: index == stepIndex ? 20 : 12, height: 4)
                            .shadow(color: index == stepIndex ? accent.opacity(0.7) : .clear, radius: 4)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: stepIndex)
                    }
                }

                Text("\(stepIndex + 1) / \(Self.guides.count)")
                    .font(AppTypography.sectionLabel)
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.92))
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(Capsule().fill(Color.black.opacity(0.75)))
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))

            Spacer()

            Button("Skip") { onFinishWithoutMicrophone() }
                .accessibilityIdentifier("onboardingSkipButton")
                .frame(minWidth: 44, minHeight: 44)
        }
        .font(AppTypography.caption.weight(.semibold))
        .foregroundStyle(.white)
        .buttonStyle(.plain)
    }

    // MARK: - Callout Content
    private func calloutContent(
        _ guide: Guide,
        placement: Placement,
        caretOffset: CGFloat,
        isCompact: Bool
    ) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    ScrollView {
                        calloutBody(guide, isCompact: false)
                    }
                    .scrollIndicators(.hidden)
                    .scrollBounceBehavior(.basedOnSize)
                    calloutAction
                }
            } else {
                ViewThatFits(in: .vertical) {
                    fixedCalloutContent(guide, isCompact: isCompact)
                    fixedCalloutContent(guide, isCompact: true)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.leading, placement == .trailing ? (isCompact ? 24 : 30) : (isCompact ? 14 : 18))
        .padding(.trailing, placement == .leading ? (isCompact ? 24 : 30) : (isCompact ? 14 : 18))
        .padding(.top, placement == .below ? (isCompact ? 24 : 28) : (isCompact ? 14 : 18))
        .padding(.bottom, placement == .above ? (isCompact ? 24 : 28) : (isCompact ? 14 : 18))
        .background {
            ZStack {
                TooltipBubbleShape(placement: placement, caretOffset: caretOffset)
                    .fill(AppColors.backgroundMid.opacity(0.8))

                TooltipBubbleShape(placement: placement, caretOffset: caretOffset)
                    .fill(.ultraThinMaterial)

                TooltipBubbleShape(placement: placement, caretOffset: caretOffset)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.09), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )

                TooltipBubbleShape(placement: placement, caretOffset: caretOffset)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.38),
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.48), radius: 22, y: 8)
            .shadow(color: accent.opacity(0.12), radius: 16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding-callout")
    }

    private func fixedCalloutContent(_ guide: Guide, isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : 10) {
            calloutBody(guide, isCompact: isCompact)
            Spacer(minLength: 0)
            calloutAction
        }
    }

    private func calloutBody(_ guide: Guide, isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : 10) {
            HStack {
                Text(guide.badge.uppercased())
                    .font(.system(.caption2, design: .rounded).bold())
                    .tracking(0.8)
                    .foregroundStyle(accent)
                    .padding(.horizontal, isCompact ? 7 : 9)
                    .padding(.vertical, isCompact ? 3 : 4)
                    .background(
                        Capsule()
                            .fill(accent.opacity(0.16))
                            .overlay(Capsule().stroke(accent.opacity(0.35), lineWidth: 1))
                    )

                Spacer()

                Text("\(stepIndex + 1) of \(Self.guides.count)")
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.textTertiary)
            }

            Text(guide.title)
                .font(CoachTypography.title)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            stepSpecificContent(for: stepIndex, isCompact: isCompact)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var calloutAction: some View {
        Button(action: stepIndex == Self.guides.count - 1 ? onFinishWithMicrophone : onNext) {
            Text(stepIndex == Self.guides.count - 1 ? "Allow Mic & Start Playing" : "Next")
                .font(AppTypography.bodyStrong)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 46)
        }
        .buttonStyle(StudioControlButtonStyle(isProminent: true, tint: AppGradients.primary))
    }

    // MARK: - Step Visual Components
    @ViewBuilder
    private func stepSpecificContent(for index: Int, isCompact: Bool) -> some View {
        switch index {
        case 0:
            // Step 1: Built-in songs and supported audio sources.
            VStack(spacing: isCompact ? 4 : 8) {
                featureRow(
                    symbol: "music.note.list",
                    tint: AppColors.cyanAccent,
                    title: "Built-In Classics",
                    subtitle: "Curated starter songs and beginner melodies ready to play",
                    isCompact: isCompact
                )

                featureRow(
                    symbol: "square.and.arrow.down",
                    tint: AppColors.hitGradientStart,
                    title: "Bring Your Own Audio",
                    subtitle: "Import audio from Files or Music Library, record a song, or paste a supported song link",
                    isCompact: isCompact
                )
            }

        case 1:
            // Step 2: Tab Notation 101 (Visual breath pills + emerald match cue)
            VStack(spacing: isCompact ? 4 : 8) {
                HStack(spacing: isCompact ? 6 : 10) {
                    // Blow pill
                    VStack(spacing: isCompact ? 2 : 3) {
                        Text("+ 1")
                            .font(CoachTypography.example)
                            .foregroundStyle(AppColors.cyanAccent)
                        Text("💨 BLOW")
                            .font(CoachTypography.featureTitle)
                            .foregroundStyle(.white)
                        Text("Exhale out")
                            .font(CoachTypography.body.weight(.medium))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .padding(.vertical, isCompact ? 6 : 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.cyanAccent.opacity(0.15))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.cyanAccent.opacity(0.4), lineWidth: 1))
                    )

                    // Draw pill
                    VStack(spacing: isCompact ? 2 : 3) {
                        Text("− 1")
                            .font(CoachTypography.example)
                            .foregroundStyle(AppColors.hitGradientStart)
                        Text("🌬️ DRAW")
                            .font(CoachTypography.featureTitle)
                            .foregroundStyle(.white)
                        Text("Inhale in")
                            .font(CoachTypography.body.weight(.medium))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .padding(.vertical, isCompact ? 6 : 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.hitGradientStart.opacity(0.15))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.hitGradientStart.opacity(0.4), lineWidth: 1))
                    )
                }

                // Match confirmation badge
                HStack(spacing: 8) {
                    Circle()
                        .fill(AppColors.hitGradientStart)
                        .frame(width: 7, height: 7)
                        .shadow(color: AppColors.hitGradientStart, radius: 4)

                    Text("Target hole turns emerald green when your pitch matches!")
                        .font(CoachTypography.body.weight(.medium))
                        .foregroundStyle(AppColors.hitGradientStart)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, isCompact ? 5 : 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.hitGradientStart.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.hitGradientStart.opacity(0.25), lineWidth: 1))
                )
            }

        case 2:
            // Step 3: Practice Modes (Guided vs Freestyle jam, no truncation)
            VStack(spacing: isCompact ? 4 : 8) {
                featureRow(
                    symbol: "target",
                    tint: AppColors.cyanAccent,
                    title: "Guided Mode",
                    subtitle: "Note-by-note interactive sheet tabs with live pitch detection & auto-scroll",
                    isCompact: isCompact
                )

                featureRow(
                    symbol: "waveform.and.mic",
                    tint: Color(red: 0.75, green: 0.55, blue: 0.98),
                    title: "Freestyle Jam",
                    subtitle: "Play anything freely; the app listens and auto-transcribes your tabs live",
                    isCompact: isCompact
                )
            }

        default:
            // Step 4: Microphone & Audio Engine (Trust & Privacy guarantee)
            VStack(spacing: isCompact ? 4 : 8) {
                featureRow(
                    symbol: "waveform",
                    tint: AppColors.cyanAccent,
                    title: "Real-Time Pitch Detection",
                    subtitle: "Live pitch feedback helps you match the target note and its blow or draw hole",
                    isCompact: isCompact
                )

                HStack(spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: isCompact ? 14 : 16, weight: .semibold))
                        .foregroundStyle(AppColors.hitGradientStart)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("100% On-Device & Private")
                            .font(CoachTypography.featureTitle)
                            .foregroundStyle(.white)

                        Text("Microphone audio never leaves your phone. Zero cloud processing.")
                            .font(CoachTypography.body)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                .padding(isCompact ? 8 : 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                )
            }
        }
    }

    private func featureRow(
        symbol: String,
        tint: Color,
        title: String,
        subtitle: String,
        isCompact: Bool
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: isCompact ? 13 : 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: isCompact ? 26 : 30, height: isCompact ? 26 : 30)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tint.opacity(0.18))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(CoachTypography.featureTitle)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(CoachTypography.body)
                    .foregroundStyle(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(isCompact ? 5 : 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.07), lineWidth: 1))
        )
    }

    private func dimmedBackground(cutout: CGRect) -> some View {
        Color.black.opacity(0.72)
            .mask {
                Rectangle()
                    .overlay {
                        if guideForCurrentStep.isCircular {
                            let diameter = max(cutout.width, cutout.height) + 16
                            Circle()
                                .frame(width: diameter, height: diameter)
                                .position(x: cutout.midX, y: cutout.midY)
                                .blendMode(.destinationOut)
                        } else {
                            RoundedRectangle(cornerRadius: guideForCurrentStep.cornerRadius)
                                .frame(width: cutout.width + 16, height: cutout.height + 16)
                                .position(x: cutout.midX, y: cutout.midY)
                                .blendMode(.destinationOut)
                        }
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
        let isLandscape = size.width > size.height
        let topMargin: CGFloat = dynamicTypeSize.isAccessibilitySize ? 72 : 64
        let bottomMargin: CGFloat = 22
        let maximumHeight = max(180, size.height - topMargin - bottomMargin)
        let baseHeight = isLandscape ? min(guide.height, 300) : guide.height
        let scale: CGFloat = dynamicTypeSize.isAccessibilitySize ? (isLandscape ? 1.0 : 1.15) : 1.0
        let desiredHeight = baseHeight * scale
        return min(desiredHeight, maximumHeight)
    }

    private func calloutLayout(
        for target: CGRect,
        in size: CGSize,
        preferredPlacement: Placement,
        height: CGFloat
    ) -> CalloutLayout {
        let horizontalMargin: CGFloat = 19
        let topMargin: CGFloat = dynamicTypeSize.isAccessibilitySize ? 72 : 64
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

    // Typography matches the tab-notation step at every card density.
    // Compact cards reduce spacing, never the text size.
    private enum CoachTypography {
        static let title: Font = .system(.title2, design: .rounded).bold()
        static let example: Font = .system(.title3, design: .rounded).bold()
        static let featureTitle: Font = .system(.caption, design: .rounded).bold()
        static let body: Font = .caption
    }

    private struct Guide {
        let badge: String
        let title: String
        let placement: Placement
        let isCircular: Bool
        let cornerRadius: CGFloat
        let height: CGFloat
    }

    private static let guides: [Guide] = [
        Guide(
            badge: "Song Library",
            title: "Pick your track",
            placement: .below,
            isCircular: true,
            cornerRadius: 24,
            height: 335
        ),
        Guide(
            badge: "Tab Notation 101",
            title: "Read harmonica tabs instantly",
            placement: .below,
            isCircular: false,
            cornerRadius: 16,
            height: 315
        ),
        Guide(
            badge: "Practice Modes",
            title: "Choose how you play",
            placement: .below,
            isCircular: false,
            cornerRadius: 14,
            height: 335
        ),
        Guide(
            badge: "Audio Engine",
            title: "Tap to listen & score",
            placement: .above,
            isCircular: false,
            cornerRadius: 16,
            height: 335
        )
    ]
}

private extension CGRect {
    var area: CGFloat {
        guard !isNull, !isInfinite else { return 0 }
        return max(0, width) * max(0, height)
    }
}
