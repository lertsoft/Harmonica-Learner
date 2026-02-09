import SwiftUI

struct ProgressTrackView: View {
    let song: HarmonicaSong?
    let currentNoteIndex: Int
    let matchState: NoteMatchState
    let layout: HarmonicaLayout

    private let noteWidth: CGFloat = 58
    private let noteSpacing: CGFloat = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(song?.songTitle ?? "No Song")
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
            .frame(height: 58)
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
            Text(note)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(textColor)

            if let hole {
                Text(hole.displayName)
                    .font(AppTypography.caption)
                    .foregroundStyle(textColor.opacity(0.75))
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
