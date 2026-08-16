import SwiftUI

struct ProgressTrackView: View {
    let song: HarmonicaSong?
    let currentNoteIndex: Int
    let matchState: NoteMatchState
    let layout: HarmonicaLayout

    @ScaledMetric(relativeTo: .body) private var scaledNoteWidth: CGFloat = 58
    @ScaledMetric(relativeTo: .body) private var scaledNoteHeight: CGFloat = 58
    @ScaledMetric(relativeTo: .body) private var scaledNoteSpacing: CGFloat = 10

    private var noteWidth: CGFloat { min(90, max(58, scaledNoteWidth)) }
    private var noteHeight: CGFloat { min(86, max(58, scaledNoteHeight)) }
    private var noteSpacing: CGFloat { min(16, max(8, scaledNoteSpacing)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(displaySongTitle)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                Spacer()

                if let song {
                    Text("\(min(currentNoteIndex + 1, song.notes.count))/\(song.notes.count)")
                        .font(AppTypography.caption.monospacedDigit())
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            GeometryReader { geometry in
                let centerX = geometry.size.width / 2
                let offset = -CGFloat(currentNoteIndex) * (noteWidth + noteSpacing)

                HStack(spacing: noteSpacing) {
                    ForEach(Array((song?.notes ?? []).enumerated()), id: \.0) { index, note in
                        NoteChipView(
                            note: note.note,
                            hole: HarmonicaHole.fromCode(note.hole),
                            state: chipState(for: index),
                            isActive: index == currentNoteIndex
                        )
                        .frame(width: noteWidth)
                    }
                }
                .offset(x: centerX - noteWidth / 2 + offset)
                .animation(.spring(response: 0.38, dampingFraction: 0.82), value: currentNoteIndex)
            }
            .frame(height: noteHeight)
            .mask(
                LinearGradient(
                    colors: [.clear, .white, .white, .white, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            progressBar
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .liquidGlass(cornerRadius: 16, intensity: 0.03)
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1))
                Capsule()
                    .fill(AppGradients.primary)
                    .frame(width: progressWidth(in: geometry.size.width))
                    .animation(.spring(response: 0.38, dampingFraction: 0.8), value: currentNoteIndex)
            }
        }
        .frame(height: 5)
    }

    private func chipState(for index: Int) -> NoteChipState {
        if index < currentNoteIndex {
            return .completed
        } else if index == currentNoteIndex {
            return matchState == .hit ? .active : .current
        } else {
            return .upcoming
        }
    }

    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard let song, !song.notes.isEmpty else { return 0 }
        let progress = CGFloat(currentNoteIndex + 1) / CGFloat(song.notes.count)
        return totalWidth * min(1, max(0, progress))
    }

    private var displaySongTitle: String {
        guard let title = song?.songTitle else { return "No Song" }
        let parts = title.components(separatedBy: " • ")
        guard parts.first == "Freestyle", parts.count >= 2 else { return title }
        return "Freestyle • \(parts[1])"
    }
}

enum NoteChipState {
    case completed
    case current
    case active
    case upcoming
}

struct NoteChipView: View {
    let note: String
    let hole: HarmonicaHole?
    let state: NoteChipState
    let isActive: Bool

    var body: some View {
        VStack(spacing: 1) {
            Text(tabText)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            if hole != nil {
                Text(note)
                    .font(AppTypography.caption)
                    .foregroundStyle(textColor.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(borderColor, lineWidth: isActive ? 1.2 : 0.8)
        )
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isActive)
    }

    private var backgroundColor: Color {
        switch state {
        case .completed: return AppColors.hitGradientStart.opacity(0.18)
        case .current, .active: return AppColors.primaryGradientStart.opacity(0.2)
        case .upcoming: return Color.white.opacity(0.05)
        }
    }

    private var borderColor: Color {
        switch state {
        case .completed: return AppColors.hitGradientStart.opacity(0.45)
        case .current, .active: return AppColors.primaryGradientStart.opacity(0.7)
        case .upcoming: return Color.white.opacity(0.1)
        }
    }

    private var textColor: Color {
        switch state {
        case .completed: return AppColors.hitGradientStart
        case .current, .active: return AppColors.textPrimary
        case .upcoming: return AppColors.textTertiary
        }
    }

    private var tabText: String {
        guard let hole else { return "—" }
        return "\(hole.airflow == .blow ? "+" : "−")\(hole.index)"
    }
}

#Preview {
    ZStack {
        AppColors.backgroundDeep.ignoresSafeArea()
        ProgressTrackView(
            song: nil,
            currentNoteIndex: 2,
            matchState: .idle,
            layout: .diatonicC
        )
        .padding()
    }
}
