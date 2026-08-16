import SwiftUI

struct TargetNoteView: View {
    let targetNote: String?
    let targetHole: HarmonicaHole?
    let detectedPitch: NotePitch?
    let matchState: NoteMatchState
    let isAudioRunning: Bool
    let isReferenceNotePlaying: Bool
    let canProgress: Bool
    let onRestart: () -> Void
    let onSkip: () -> Void
    let onToggleReferenceNote: () -> Void

    @State private var successScale: CGFloat = 1

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                utilityButton("arrow.counterclockwise", label: "Restart", action: onRestart)
                VStack(spacing: 3) {
                    Text("PLAY")
                        .font(AppTypography.sectionLabel)
                        .foregroundStyle(AppColors.textTertiary)
                    Text(tabInstruction)
                        .font(.custom("AvenirNextCondensed-DemiBold", size: 58, relativeTo: .largeTitle))
                        .foregroundStyle(matchState == .hit ? AppColors.hitGradientStart : AppColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .scaleEffect(successScale)
                    Text(targetNote.map { "Concert pitch \($0)" } ?? "Choose a song to begin")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                utilityButton("forward.end.fill", label: "Skip", action: onSkip)
            }

            if let targetHole { HarmonicaCombView(activeHole: targetHole, matchState: matchState) }
            Divider().overlay(Color.white.opacity(0.08))
            HStack(spacing: 16) {
                PitchTargetGauge(pitch: detectedPitch, matchState: matchState, isListening: isAudioRunning)
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle).font(AppTypography.bodyStrong).foregroundStyle(statusColor)
                    Text(statusDetail)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
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
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20, intensity: 0.035)
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(matchState == .hit ? AppColors.hitGradientStart.opacity(0.8) : Color.clear, lineWidth: 2))
        .onChange(of: matchState) { oldValue, newValue in
            guard newValue == .hit, oldValue != .hit else { return }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.45)) { successScale = 1.08 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { successScale = 1 }
            }
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

    private var tabInstruction: String {
        guard let hole = targetHole else { return "—" }
        return "\(hole.airflow == .blow ? "+" : "−")\(hole.index)  \(hole.airflow == .blow ? "Blow" : "Draw")"
    }

    private var statusTitle: String {
        guard isAudioRunning else { return "Microphone off" }
        switch matchState {
        case .hit: return "In tune"
        case .miss: return detectedPitch?.centsOffset ?? 0 > 0 ? "A little sharp" : "A little flat"
        case .idle: return "Listening…"
        }
    }

    private var statusDetail: String {
        guard isAudioRunning else { return "Start practice when you’re ready." }
        guard let detectedPitch else { return "Play one clear hole and hold it steady." }
        let cents = Int(abs(detectedPitch.centsOffset).rounded())
        return matchState == .hit ? "Hold for a moment to advance." : "Heard \(detectedPitch.fullName) • \(cents)¢ off target"
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
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: pitch?.centsOffset)
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
                       isAudioRunning: true, isReferenceNotePlaying: false, canProgress: true,
                       onRestart: {}, onSkip: {}, onToggleReferenceNote: {})
            .padding()
    }
}
