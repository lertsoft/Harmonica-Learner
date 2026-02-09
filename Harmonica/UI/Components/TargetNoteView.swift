import SwiftUI

struct TargetNoteView: View {
    let targetNote: String?
    let targetHole: HarmonicaHole?
    let matchState: NoteMatchState
    let detectedNote: String?
    let isAudioRunning: Bool
    let onToggleListening: () -> Void

    @State private var successScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                Text("Target")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)

                Text(targetNote ?? "--")
                    .font(AppTypography.hero)
                    .foregroundStyle(AppColors.textPrimary)
                    .scaleEffect(successScale)

                statePill
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .liquidGlass(cornerRadius: 18, intensity: 0.03)

            holeInstruction
        }
        .padding(.horizontal, 16)
        .onChange(of: matchState) { oldValue, newValue in
            if newValue == .hit && oldValue != .hit {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.45)) {
                    successScale = 1.08
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        successScale = 1.0
                    }
                }
            }
        }
    }

    private var statePill: some View {
        Button(action: onToggleListening) {
            Text(stateText)
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(stateColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(stateColor.opacity(0.14)))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var holeInstruction: some View {
        if let hole = targetHole {
            HStack(spacing: 8) {
                Text("Hole \(hole.index)")
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)

                Text(hole.airflow == .blow ? "Blow" : "Draw")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.08)))

                if let detectedNote {
                    Text("Heard \(detectedNote)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .lineLimit(1)
                }
            }
        } else {
            Text("Select a song to begin")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var stateColor: Color {
        guard isAudioRunning else { return AppColors.textSecondary }
        switch matchState {
        case .hit: return AppColors.hitGradientStart
        case .miss: return AppColors.missGradientStart
        case .idle: return AppColors.textSecondary
        }
    }

    private var stateText: String {
        guard isAudioRunning else { return "Tap Start" }
        switch matchState {
        case .hit: return "On Pitch"
        case .miss: return "Adjust"
        case .idle: return "Listening"
        }
    }
}

#Preview {
    ZStack {
        AppColors.backgroundDeep.ignoresSafeArea()
        TargetNoteView(
            targetNote: "C4",
            targetHole: HarmonicaHole(index: 4, airflow: .blow),
            matchState: .idle,
            detectedNote: nil,
            isAudioRunning: false,
            onToggleListening: {}
        )
    }
}
