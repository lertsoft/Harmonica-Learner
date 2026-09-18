import SwiftUI

struct HeaderView: View {
    @State private var isLibraryPresented = false
    @State private var librarySearchText = ""
    let selectedSong: HarmonicaSong?
    let songs: [HarmonicaSong]
    let isFreestyleMode: Bool
    let selectedSongIsImported: Bool
    let usesCompactLayout: Bool
    let onToggleFreestyleMode: () -> Void
    let onSelectSong: (HarmonicaSong) -> Void
    let onShowSetup: () -> Void
    let onAddSong: () -> Void
    let onRenameSong: (HarmonicaSong) -> Void
    let onDeleteSong: (HarmonicaSong) -> Void

    var body: some View {
        Group {
            if usesCompactLayout {
                compactHeader
            } else {
                regularHeader
            }
        }
        .padding(usesCompactLayout ? 8 : 14)
        .liquidGlass(cornerRadius: AppMetrics.cardRadius, intensity: 0.03)
        .sheet(isPresented: $isLibraryPresented) {
            librarySheet
        }
    }

    private var regularHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Harmonica Practice")
                        .font(AppTypography.title)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                    Text("Listen • Match • Move")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 8)

                libraryButton

                Button(action: onShowSetup) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: AppMetrics.controlHeight, height: AppMetrics.controlHeight)
                        .background(Circle().fill(Color.white.opacity(0.07)))
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppColors.textPrimary)
                .accessibilityLabel("Practice setup")
            }

            modePicker

            contextSummary
        }
    }

    private var compactHeader: some View {
        HStack(spacing: 8) {
            contextSummary
                .frame(maxWidth: .infinity)

            modePicker
                .frame(width: 210)

            libraryButton

            Button(action: onShowSetup) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: AppMetrics.controlHeight, height: AppMetrics.controlHeight)
                    .background(Circle().fill(Color.white.opacity(0.07)))
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColors.textPrimary)
            .accessibilityLabel("Practice setup")
        }
    }

    private var modePicker: some View {
        Picker("Practice mode", selection: Binding(
            get: { isFreestyleMode },
            set: { wantsFreestyle in
                guard wantsFreestyle != isFreestyleMode else { return }
                onToggleFreestyleMode()
            }
        )) {
            Text("Guided").tag(false)
            Text("Freestyle").tag(true)
        }
        .pickerStyle(.segmented)
        .accessibilityHint("Switches between song practice and free recording")
    }

    private var contextSummary: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(isFreestyleMode ? "Free play" : (selectedSongIsImported ? "Practice line" : "Song"))
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)
            Text(isFreestyleMode ? "Capture a new idea" : selectedSong.map(displayName) ?? "Choose a song")
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .frame(minHeight: usesCompactLayout ? AppMetrics.controlHeight : 56)
        .background(RoundedRectangle(cornerRadius: AppMetrics.controlRadius).fill(Color.white.opacity(0.05)))
        .accessibilityElement(children: .combine)
    }

    private var libraryButton: some View {
        Button { isLibraryPresented = true } label: {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 15, weight: .semibold))
                .frame(width: AppMetrics.controlHeight, height: AppMetrics.controlHeight)
                .background(Circle().fill(Color.white.opacity(0.07)))
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppColors.textPrimary)
        .accessibilityLabel("Practice library")
    }

    private var librarySheet: some View {
        NavigationStack {
            List {
                songSection("Built In", songs: filteredSongs.filter { !$0.id.hasPrefix("recording:") })
                songSection("My Practice", songs: filteredSongs.filter { $0.id.hasPrefix("recording:") })
            }
            .searchable(text: $librarySearchText, prompt: "Search songs")
            .navigationTitle("Practice Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isLibraryPresented = false }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isLibraryPresented = false
                        DispatchQueue.main.async(execute: onAddSong)
                    } label: {
                        Label("Add Song", systemImage: "plus")
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func songSection(_ title: String, songs: [HarmonicaSong]) -> some View {
        if !songs.isEmpty {
            Section(title) {
                ForEach(songs) { song in
                    Button {
                        onSelectSong(song)
                        isLibraryPresented = false
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(displayName(for: song))
                                Text("\(song.notes.count) notes • Pitch practice")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedSong?.id == song.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .contextMenu {
                        if song.id.hasPrefix("recording:") {
                            Button {
                                isLibraryPresented = false
                                DispatchQueue.main.async { onRenameSong(song) }
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                isLibraryPresented = false
                                DispatchQueue.main.async { onDeleteSong(song) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if song.id.hasPrefix("recording:") {
                            Button(role: .destructive) {
                                isLibraryPresented = false
                                DispatchQueue.main.async { onDeleteSong(song) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                isLibraryPresented = false
                                DispatchQueue.main.async { onRenameSong(song) }
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(AppColors.primaryGradientStart)
                        }
                    }
                }
            }
        }
    }

    private var filteredSongs: [HarmonicaSong] {
        let query = librarySearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return songs }
        return songs.filter { $0.songTitle.localizedCaseInsensitiveContains(query) }
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
        HeaderView(selectedSong: nil, songs: [], isFreestyleMode: false,
                   selectedSongIsImported: false, usesCompactLayout: false,
                   onToggleFreestyleMode: {}, onSelectSong: { _ in }, onShowSetup: {}, onAddSong: {},
                   onRenameSong: { _ in }, onDeleteSong: { _ in })
            .padding()
    }
}
