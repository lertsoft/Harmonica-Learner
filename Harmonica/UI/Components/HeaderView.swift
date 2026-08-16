import SwiftUI

struct HeaderView: View {
    @Binding var selectedSong: HarmonicaSong?
    let songs: [HarmonicaSong]
    let selectedKey: String
    let selectedLayout: HarmonicaLayout
    let isFreestyleMode: Bool
    let canManageSelectedSong: Bool
    let selectedSongIsImported: Bool
    let onToggleFreestyleMode: () -> Void
    let onShowSetup: () -> Void
    let onAddSong: () -> Void
    let onRenameSelectedSong: () -> Void
    let onDeleteSelectedSong: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Harmonica Practice")
                        .font(AppTypography.title)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Listen • Match • Move")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                Spacer(minLength: 8)
                Button(action: onShowSetup) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.07)))
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppColors.textPrimary)
                .accessibilityLabel("Practice setup")
            }

            HStack(spacing: 8) {
                songMenu
                Button(action: onShowSetup) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Harmonica")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                        Text("Key of \(selectedKey) • \(layoutName)")
                            .font(AppTypography.bodyStrong)
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.68)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 56)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens key, tuning, and microphone settings")
            }
        }
        .padding(14)
        .liquidGlass(cornerRadius: 20, intensity: 0.03)
    }

    private var songMenu: some View {
        Menu {
            Button(action: onToggleFreestyleMode) {
                Label(isFreestyleMode ? "Return to Guided Practice" : "Freestyle", systemImage: "waveform.badge.mic")
            }
            Divider()
            let builtInSongs = songs.filter { !$0.id.hasPrefix("recording:") }
            let savedSongs = songs.filter { $0.id.hasPrefix("recording:") }
            if !builtInSongs.isEmpty {
                Section("Built In") {
                    ForEach(builtInSongs) { song in Button(displayName(for: song)) { selectedSong = song } }
                }
            }
            if !savedSongs.isEmpty {
                Section("My Practice") {
                    ForEach(savedSongs) { song in Button(displayName(for: song)) { selectedSong = song } }
                }
            }
            Divider()
            Button(action: onAddSong) { Label("Add Song", systemImage: "plus") }
            if canManageSelectedSong {
                Button(action: onRenameSelectedSong) { Label("Rename", systemImage: "pencil") }
                Button(role: .destructive, action: onDeleteSelectedSong) { Label("Delete", systemImage: "trash") }
            }
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(isFreestyleMode ? "Mode" : (selectedSongIsImported ? "Suggested Line" : "Song"))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
                HStack(spacing: 6) {
                    Text(isFreestyleMode ? "Freestyle" : selectedSong.map(displayName) ?? "Select")
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .frame(minHeight: 56)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
        }
        .frame(maxWidth: .infinity)
    }

    private var layoutName: String {
        switch selectedLayout {
        case .diatonicC: return "Standard Richter"
        case .leeOskarC: return "Lee Oskar"
        }
    }

    private func displayName(for song: HarmonicaSong) -> String {
        let parts = song.songTitle.components(separatedBy: " • ")
        guard parts.first == "Freestyle", parts.count >= 2 else { return song.songTitle }
        return "Freestyle • \(parts[1])"
    }
}

#Preview {
    ZStack {
        AppColors.backgroundDeep.ignoresSafeArea()
        HeaderView(selectedSong: .constant(nil), songs: [], selectedKey: "C", selectedLayout: .diatonicC,
                   isFreestyleMode: false, canManageSelectedSong: false, selectedSongIsImported: false,
                   onToggleFreestyleMode: {}, onShowSetup: {}, onAddSong: {}, onRenameSelectedSong: {}, onDeleteSelectedSong: {})
            .padding()
    }
}
