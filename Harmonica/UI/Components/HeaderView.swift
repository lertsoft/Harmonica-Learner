import SwiftUI

struct HeaderView: View {
    @Binding var selectedSong: HarmonicaSong?
    @Binding var selectedKey: String
    @Binding var selectedLayout: HarmonicaLayout

    let songs: [HarmonicaSong]
    let isFreestyleMode: Bool
    let onToggleFreestyleMode: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Harmonica Practice")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Button(action: onToggleFreestyleMode) {
                    HStack(spacing: 6) {
                        Image(systemName: isFreestyleMode ? "waveform.badge.mic" : "mic")
                            .font(.system(size: 11, weight: .semibold))
                        Text(isFreestyleMode ? "Exit Freestyle" : "Freestyle")
                            .font(AppTypography.caption.weight(.semibold))
                    }
                    .foregroundStyle(isFreestyleMode ? AppColors.textPrimary : AppColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isFreestyleMode ? AppColors.primaryGradientStart.opacity(0.26) : Color.white.opacity(0.07))
                    )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Menu {
                    ForEach(songs) { song in
                        Button(song.songTitle) {
                            selectedSong = song
                        }
                    }
                } label: {
                    compactCard(label: "Song", value: selectedSong?.songTitle ?? "Select")
                }

                Menu {
                    Button("C") { selectedKey = "C" }
                } label: {
                    compactCard(label: "Key", value: selectedKey)
                }

                Menu {
                    ForEach(HarmonicaLayout.allCases) { layout in
                        Button(layout.rawValue) {
                            selectedLayout = layout
                        }
                    }
                } label: {
                    compactCard(label: "Layout", value: selectedLayout.rawValue)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .liquidGlass(cornerRadius: 16, intensity: 0.03)
        .padding(.horizontal, 16)
    }

    private func compactCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)

            HStack(spacing: 4) {
                Text(value)
                    .font(AppTypography.bodyStrong)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    ZStack {
        AppColors.backgroundDeep.ignoresSafeArea()
        VStack {
            HeaderView(
                selectedSong: .constant(nil),
                selectedKey: .constant("C"),
                selectedLayout: .constant(.diatonicC),
                songs: [],
                isFreestyleMode: false,
                onToggleFreestyleMode: {}
            )
            Spacer()
        }
    }
}
