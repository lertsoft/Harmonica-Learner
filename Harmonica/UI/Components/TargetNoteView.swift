import SwiftUI

struct TargetNoteView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let targetNote: String?
    let targetHole: HarmonicaHole?
    var sourceNotes: [String]? = nil
    var hasUnrecoveredAudio: Bool = false
    let detectedPitch: NotePitch?
    let matchState: NoteMatchState
    let isAudioRunning: Bool
    let isReferenceNotePlaying: Bool
    let canProgress: Bool
    let isComplete: Bool
    let usesCompactLayout: Bool
    var usesHorizontalLayout: Bool = false
    let onRestart: () -> Void
    let onSkip: () -> Void
    let onToggleReferenceNote: () -> Void

    @State private var successScale: CGFloat = 1

    var body: some View {
        VStack(spacing: usesCompactLayout ? 6 : 12) {
            if dynamicTypeSize.isAccessibilitySize {
                noteInstruction
                sourceChord
                comb
                Text(compactStatusLine)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(statusColor)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    utilityButton("arrow.counterclockwise", label: "Restart", action: onRestart)
                    Spacer()
                    referenceButton
                    Spacer()
                    utilityButton("forward.end.fill", label: "Skip", action: onSkip)
                }
            } else {
                Spacer(minLength: 0)
                if usesHorizontalLayout {
                    HStack(spacing: 12) {
                        noteInstruction
                        VStack(spacing: 4) {
                            comb
                            sourceChord
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    HStack(spacing: 10) {
                        utilityButton("arrow.counterclockwise", label: "Restart", action: onRestart)
                        noteInstruction
                        utilityButton("forward.end.fill", label: "Skip", action: onSkip)
                    }
                    sourceChord
                    Spacer(minLength: 0)
                    comb
                }
                Spacer(minLength: 0)
                if !usesCompactLayout {
                    Divider().overlay(Color.white.opacity(0.08))
                }
                HStack(spacing: 10) {
                    if usesHorizontalLayout {
                        utilityButton("arrow.counterclockwise", label: "Restart", action: onRestart)
                    }
                    if isAudioRunning, detectedPitch != nil, !usesCompactLayout {
                        PitchTargetGauge(pitch: detectedPitch, matchState: matchState, isListening: true)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(usesCompactLayout ? compactStatusLine : statusTitle)
                            .font(AppTypography.bodyStrong)
                            .foregroundStyle(statusColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        if !usesCompactLayout, let statusDetail {
                            Text(statusDetail)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                                .lineLimit(2)
                        }
                    }
                    Spacer(minLength: 0)
                    referenceButton
                    if usesHorizontalLayout {
                        utilityButton("forward.end.fill", label: "Skip", action: onSkip)
                    }
                }
            }
        }
        .padding(usesCompactLayout ? 8 : 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlass(cornerRadius: AppMetrics.cardRadius, intensity: 0.035)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("target-note-card")
        .overlay(RoundedRectangle(cornerRadius: AppMetrics.cardRadius).strokeBorder(matchState == .hit ? AppColors.hitGradientStart.opacity(0.8) : Color.clear, lineWidth: 2))
        .onChange(of: matchState) { oldValue, newValue in
            guard newValue == .hit, oldValue != .hit else { return }
            withAnimation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.45)) { successScale = reduceMotion ? 1 : 1.08 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) { successScale = 1 }
            }
        }
    }

    private var noteInstruction: some View {
        VStack(spacing: 3) {
            Text("PLAY")
                .font(AppTypography.sectionLabel)
                .foregroundStyle(AppColors.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(isComplete ? "Complete" : tabInstruction)
                .font(.custom("AvenirNextCondensed-DemiBold", size: usesCompactLayout ? 42 : 58, relativeTo: .largeTitle))
                .foregroundStyle(matchState == .hit ? AppColors.hitGradientStart : AppColors.textPrimary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.35)
                .scaleEffect(successScale)
            Text(isComplete ? "Nice work — you finished this song" : targetNote.map { "Concert pitch \($0)" } ?? (hasUnrecoveredAudio ? "No playable notes recovered" : "Choose a song to begin"))
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.5)
        }
        .frame(maxWidth: .infinity)
        .onboardingCoachTarget(.targetNote)
    }

    @ViewBuilder
    private var sourceChord: some View {
        if let sourceNotes, sourceNotes.count > 1 {
            Text("Arpeggio from \(sourceNotes.joined(separator: " · "))")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.5)
                .accessibilityIdentifier("source-chord-context")
        }
    }

    @ViewBuilder
    private var comb: some View {
        if let targetHole {
            HarmonicaCombView(activeHole: targetHole, matchState: matchState)
                .accessibilityIdentifier("harmonica-comb")
        }
    }

    private func utilityButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.07)))
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppColors.textSecondary)
        .disabled(!canProgress)
        .opacity(canProgress ? 1 : 0.35)
        .accessibilityLabel(label)
    }

    private var referenceButton: some View {
        Button(action: onToggleReferenceNote) {
            Image(systemName: isReferenceNotePlaying ? "stop.fill" : "speaker.wave.2.fill")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Circle().fill(AppColors.primaryGradientStart.opacity(0.2)))
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppColors.textPrimary)
        .accessibilityLabel(isReferenceNotePlaying ? "Stop reference note" : "Hear target note")
    }

    private var tabInstruction: String {
        guard let hole = targetHole else { return "—" }
        return "\(hole.airflow == .blow ? "+" : "−")\(hole.index)  \(hole.airflow == .blow ? "Blow" : "Draw")"
    }

    private var statusTitle: String {
        if isComplete { return "Practice complete" }
        guard isAudioRunning else { return "Microphone off" }
        switch matchState {
        case .hit: return "In tune"
        case .miss: return detectedPitch?.centsOffset ?? 0 > 0 ? "A little sharp" : "A little flat"
        case .idle: return "Listening…"
        }
    }

    private var statusDetail: String? {
        if isComplete { return "Restart to practice it again and tighten your accuracy." }
        guard isAudioRunning else { return nil }
        guard let detectedPitch else { return "Play one clear hole and hold it steady." }
        let cents = Int(abs(detectedPitch.centsOffset).rounded())
        return matchState == .hit ? "Hold for a moment to advance." : "Heard \(detectedPitch.fullName) • \(cents)¢ off target"
    }

    private var compactStatusLine: String {
        if isComplete { return "Practice complete" }
        guard isAudioRunning else { return "Microphone off" }
        guard let detectedPitch else { return "Listening • Play one clear hole" }
        let cents = Int(abs(detectedPitch.centsOffset).rounded())
        return matchState == .hit ? "In tune • Hold to advance" : "\(detectedPitch.fullName) • \(cents)¢ off target"
    }

    private var statusColor: Color {
        switch matchState {
        case .hit: return AppColors.hitGradientStart
        case .miss: return AppColors.idleGradientStart
        case .idle: return AppColors.textPrimary
        }
    }
}

private struct HarmonicaCombView: View {
    let activeHole: HarmonicaHole
    let matchState: NoteMatchState

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 4) {
                ForEach(1...10, id: \.self) { hole in
                    VStack(spacing: 3) {
                        Image(systemName: activeHole.index == hole ? airflowIcon : "circle.fill")
                            .font(.system(size: activeHole.index == hole ? 11 : 4, weight: .bold))
                            .foregroundStyle(activeHole.index == hole ? airflowColor : AppColors.textTertiary.opacity(0.55))
                            .frame(height: 13)
                        Text("\(hole)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .foregroundStyle(activeHole.index == hole ? Color.white : AppColors.textTertiary)
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .background(RoundedRectangle(cornerRadius: 7).fill(activeHole.index == hole ? airflowColor.opacity(0.8) : Color.white.opacity(0.06)))
                    }
                }
            }
            Text(activeHole.airflow == .blow ? "↑  BLOW OUT" : "↓  DRAW IN")
                .font(AppTypography.sectionLabel)
                .foregroundStyle(airflowColor)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hole \(activeHole.index), \(activeHole.airflow == .blow ? "blow" : "draw")")
    }

    private var airflowIcon: String { activeHole.airflow == .blow ? "arrow.up" : "arrow.down" }
    private var airflowColor: Color {
        if matchState == .hit { return AppColors.hitGradientStart }
        return activeHole.airflow == .blow ? AppColors.primaryGradientStart : Color.orange
    }
}

private struct PitchTargetGauge: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let pitch: NotePitch?
    let matchState: NoteMatchState
    let isListening: Bool

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.08), lineWidth: 7)
            Circle().trim(from: 0, to: progress)
                .stroke(gaugeColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(pitch?.fullName ?? "—").font(.system(size: 16, weight: .bold, design: .rounded))
                Text(centsText).font(.system(size: 9, weight: .semibold, design: .monospaced)).foregroundStyle(AppColors.textTertiary)
            }
            .foregroundStyle(gaugeColor)
        }
        .frame(width: 66, height: 66)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: pitch?.centsOffset)
    }

    private var progress: CGFloat {
        guard isListening, let pitch else { return 0.08 }
        return CGFloat(max(0.08, 1 - min(abs(pitch.centsOffset), 50) / 50))
    }
    private var centsText: String {
        guard let pitch else { return "NO SIGNAL" }
        let cents = Int(pitch.centsOffset.rounded())
        return cents >= 0 ? "+\(cents)¢" : "\(cents)¢"
    }
    private var gaugeColor: Color {
        guard isListening, pitch != nil else { return AppColors.textTertiary }
        if matchState == .hit { return AppColors.hitGradientStart }
        return abs(pitch?.centsOffset ?? 0) <= 25 ? AppColors.idleGradientStart : AppColors.missGradientStart
    }
}

#Preview {
    ZStack {
        AppColors.backgroundDeep.ignoresSafeArea()
        TargetNoteView(targetNote: "C5", targetHole: HarmonicaHole(index: 4, airflow: .blow),
                       detectedPitch: NotePitch(noteName: "C", octave: 5, centsOffset: -7), matchState: .hit,
                       isAudioRunning: true, isReferenceNotePlaying: false, canProgress: true, isComplete: false,
                       usesCompactLayout: false,
                       onRestart: {}, onSkip: {}, onToggleReferenceNote: {})
            .padding()
    }
}
