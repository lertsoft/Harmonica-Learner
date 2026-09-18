import SwiftUI
import UniformTypeIdentifiers

struct PracticeView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @AppStorage("hasSeenPracticeOnboarding") private var hasSeenOnboarding = false
    @AppStorage("callAndResponseEnabled") private var callAndResponseEnabled = false
    @AppStorage("practice.sensitivity") private var storedSensitivity = 0.035
    @AppStorage("practice.layout") private var storedLayout = HarmonicaLayout.diatonicC.rawValue
    @AppStorage("practice.selectedSongID") private var storedSelectedSongID = ""
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var showOnboarding = false
    @State private var showMicAlert = false
    @State private var micAlertMessage = ""
    @State private var showRemoveAudioConfirm = false
    @State private var showDeleteRecordingConfirm = false
    @State private var showRenamePrompt = false
    @State private var isSongImporterPresented = false
    @State private var isMusicLibraryPickerPresented = false
    @State private var isSongRecorderPresented = false
    @State private var showAddSongOptions = false
    @State private var showSongLinkPrompt = false
    @State private var songLinkText = ""
    @State private var renameText = ""
    @State private var recordedSongTitle = ""
    @State private var showSetupSheet = false
    @State private var lastMissHapticDate = Date.distantPast
    @State private var hasRestoredPreferences = false

    var body: some View {
        GeometryReader { proxy in
            let layout = AdaptivePracticeLayout.resolve(
                size: proxy.size,
                usesAccessibilityText: dynamicTypeSize.isAccessibilitySize
            )

            ZStack {
                backgroundLayer

                VStack(spacing: 0) {
                    ScrollView {
                        practiceContent(layout: layout)
                            .frame(maxWidth: layout.contentMaxWidth)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, layout.horizontalPadding)
                            .padding(.top, 8)
                            .padding(.bottom, 16)
                    }
                    .scrollIndicators(.hidden)
                    .allowsHitTesting(!showOnboarding && !viewModel.isImportingSong)

                    controlsPanel(safeAreaBottom: 8, usesCompactLayout: layout.isCompactHeight)
                        .disabled(showOnboarding || viewModel.isImportingSong)
                }
                .accessibilityHidden(showOnboarding || viewModel.isImportingSong)

                if showOnboarding {
                    onboardingOverlay
                }

                if viewModel.isImportingSong {
                    importingOverlay
                }
            }
        }
        .onAppear {
            restorePreferencesIfNeeded()
            showOnboarding = !hasSeenOnboarding
        }
        .onChange(of: viewModel.matchState) { oldValue, newValue in
            if newValue == .hit && oldValue != .hit {
                triggerHapticFeedback(for: .hit)
            } else if newValue == .miss && oldValue != .miss {
                triggerHapticFeedback(for: .miss)
            }
        }
        .onChange(of: viewModel.selectedSong) { oldValue, newValue in
            viewModel.handleSelectedSongChange(from: oldValue, to: newValue)
            storedSelectedSongID = newValue?.id ?? ""
        }
        .onChange(of: viewModel.sensitivity) { _, newValue in
            storedSensitivity = newValue
        }
        .onChange(of: viewModel.selectedLayout) { _, newValue in
            storedLayout = newValue.rawValue
        }
        .onChange(of: viewModel.currentNoteIndex) { _, _ in
            playCallAndResponseReferenceIfNeeded()
        }
        .sheet(isPresented: $showSetupSheet) {
            PracticeSetupSheet(
                selectedLayout: $viewModel.selectedLayout,
                sensitivity: $viewModel.sensitivity,
                callAndResponseEnabled: $callAndResponseEnabled,
                audioService: viewModel.audioService,
                isCalibrating: viewModel.isCalibratingSensitivity,
                onAutoCalibrate: autoCalibrateSensitivity,
                onShowQuickStart: {
                    showSetupSheet = false
                    DispatchQueue.main.async { showOnboarding = true }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $isMusicLibraryPickerPresented) {
            MusicLibraryPicker { assetURL, title in
                isMusicLibraryPickerPresented = false
                viewModel.importSongFromMusicLibrary(assetURL: assetURL, title: title)
            } onFailure: { message in
                isMusicLibraryPickerPresented = false
                micAlertMessage = message
                showMicAlert = true
            } onCancel: {
                isMusicLibraryPickerPresented = false
            }
        }
        .sheet(isPresented: $showAddSongOptions) {
            AddPracticeSongSheet(
                onChooseFile: { presentAfterAddSheet { isSongImporterPresented = true } },
                onChooseMusic: { presentAfterAddSheet { isMusicLibraryPickerPresented = true } },
                onRecordSong: {
                    recordedSongTitle = ""
                    presentAfterAddSheet { isSongRecorderPresented = true }
                },
                onPasteLink: { presentAfterAddSheet { showSongLinkPrompt = true } }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isSongRecorderPresented, onDismiss: {
            if viewModel.isRecordingSong {
                viewModel.cancelSongRecording()
            }
        }) {
            songRecorderSheet
                .interactiveDismissDisabled(viewModel.isRecordingSong)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
        .alert("Harmonica Learner", isPresented: $showMicAlert) {
            Button("Open Settings") {
                openAppSettings()
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(micAlertMessage)
        }
        .alert("Paste Song Link", isPresented: $showSongLinkPrompt) {
            TextField("Spotify, YouTube, Apple Music, or audio URL", text: $songLinkText)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
            Button("Analyze") {
                viewModel.importSong(fromLink: songLinkText)
                songLinkText = ""
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Direct audio links work locally. Streaming-service links require an authorized transcription provider.")
        }
        .alert(
            "Song Link",
            isPresented: Binding(
                get: { viewModel.songLinkErrorMessage != nil },
                set: { if !$0 { viewModel.songLinkErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.songLinkErrorMessage = nil }
        } message: {
            Text(viewModel.songLinkErrorMessage ?? "")
        }
        .alert("Rename Saved Song", isPresented: $showRenamePrompt) {
            TextField("Song name", text: $renameText)
            Button("Save") {
                do {
                    try viewModel.renameSelectedRecording(to: renameText)
                } catch {
                    micAlertMessage = "Could not rename this song: \(error.localizedDescription)"
                    showMicAlert = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This changes the name in your saved practice library.")
        }
        .fileImporter(
            isPresented: $isSongImporterPresented,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.importSong(from: url)
                }
            case .failure(let error):
                micAlertMessage = "Could not open that song: \(error.localizedDescription)"
                showMicAlert = true
            }
        }
        .confirmationDialog(
            "Remove Background Audio?",
            isPresented: $showRemoveAudioConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove Audio", role: .destructive) {
                do {
                    try viewModel.removeSelectedFreestyleAudio()
                } catch {
                    micAlertMessage = "Could not remove background audio: \(error.localizedDescription)"
                    showMicAlert = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This keeps the note targets for practice, but deletes the saved playback audio.")
        }
        .confirmationDialog(
            "Delete Saved Song?",
            isPresented: $showDeleteRecordingConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                do {
                    try viewModel.deleteSelectedRecording()
                } catch {
                    micAlertMessage = "Could not delete this song: \(error.localizedDescription)"
                    showMicAlert = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes the saved notes and audio from this device.")
        }
    }

    private func practiceContent(layout: AdaptivePracticeLayout) -> some View {
        VStack(spacing: layout.contentSpacing) {
            HeaderView(
                selectedSong: viewModel.selectedSong,
                songs: viewModel.songs,
                isFreestyleMode: viewModel.isFreestyleMode,
                selectedSongIsImported: viewModel.selectedRecordingIsImportedSong,
                usesCompactLayout: layout.usesCompactHeader,
                onToggleFreestyleMode: handleFreestyleModeToggle,
                onSelectSong: { _ = selectSongForPractice($0) },
                onShowSetup: { showSetupSheet = true },
                onAddSong: { showAddSongOptions = true },
                onRenameSong: prepareRename,
                onDeleteSong: prepareDelete
            )

            if let notice = viewModel.noticeMessage {
                noticeBanner(notice)
            }

            if viewModel.isFreestyleMode {
                freestyleContent(layout: layout)
            } else {
                guidedContent(layout: layout)
            }
        }
    }

    @ViewBuilder
    private func guidedContent(layout: AdaptivePracticeLayout) -> some View {
        if layout.usesTwoColumnPractice {
            HStack(alignment: .top, spacing: layout.contentSpacing) {
                targetNoteContent(usesCompactLayout: layout.isCompactHeight)
                    .frame(maxWidth: .infinity, alignment: .top)

                pitchAndProgressContent
                    .frame(maxWidth: .infinity, alignment: .top)
            }
        } else {
            targetNoteContent(usesCompactLayout: layout.isCompactHeight)
            pitchAndProgressContent
        }
    }

    @ViewBuilder
    private func freestyleContent(layout: AdaptivePracticeLayout) -> some View {
        if layout.usesTwoColumnPractice {
            freestyleLiveCard
                .frame(maxWidth: 760)
        } else {
            freestyleLiveCard
        }
    }

    private func targetNoteContent(usesCompactLayout: Bool) -> some View {
        TargetNoteView(
            targetNote: viewModel.currentTargetNote,
            targetHole: viewModel.currentTargetHole,
            detectedPitch: viewModel.detectedPitch,
            matchState: viewModel.matchState,
            isAudioRunning: viewModel.isAudioRunning,
            isReferenceNotePlaying: viewModel.isReferenceNotePlaying,
            canProgress: viewModel.selectedFreestyleHasPlayableNotes,
            isComplete: viewModel.isPracticeComplete,
            usesCompactLayout: usesCompactLayout,
            onRestart: viewModel.startNewAttempt,
            onSkip: viewModel.advanceNote,
            onToggleReferenceNote: handleReferenceNoteToggle
        )
    }

    private var pitchAndProgressContent: some View {
        ProgressTrackView(
            song: viewModel.selectedSong,
            currentNoteIndex: viewModel.currentNoteIndex,
            matchState: viewModel.matchState,
            layout: viewModel.selectedLayout
        )
    }

    private var freestyleLiveCard: some View {
        VStack(spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isFreestyleRecording ? AppColors.missGradientStart : AppColors.textTertiary)
                        .frame(width: 9, height: 9)
                    Text(viewModel.isFreestyleRecording ? "REC" : "Ready")
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Text(formattedElapsed(viewModel.freestyleElapsed))
                    .font(AppTypography.mono.monospacedDigit())
                    .foregroundStyle(AppColors.textSecondary)
            }

            DetectedPitchView(
                pitch: viewModel.detectedPitch,
                matchState: viewModel.matchState,
                showsSurface: false
            )

            Text(viewModel.isFreestyleRecording
                 ? "Keep playing. Notes and audio are being saved on this device."
                 : "Start recording when you’re ready to capture notes and audio.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .liquidGlass(cornerRadius: 18, intensity: 0.03)
        .accessibilityElement(children: .contain)
    }

    private var importingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                if let progress = viewModel.importProgress {
                    ProgressView(value: progress)
                        .tint(AppColors.primaryGradientStart)
                        .frame(maxWidth: 260)
                    Text("\(Int((progress * 100).rounded()))%")
                        .font(AppTypography.mono.monospacedDigit())
                        .foregroundStyle(AppColors.textSecondary)
                } else {
                    ProgressView()
                        .tint(AppColors.primaryGradientStart)
                        .scaleEffect(1.15)
                }
                Text("Finding a playable harmonica line…")
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)
                Text("The result is a practice suggestion, especially for full-band mixes.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                if viewModel.canCancelSongImport {
                    Button("Cancel Analysis", role: .cancel) {
                        viewModel.cancelSongImport()
                    }
                    .buttonStyle(StudioControlButtonStyle())
                }
            }
            .padding(20)
            .liquidGlass(cornerRadius: 18, intensity: 0.04)
            .frame(maxWidth: 520)
            .padding(.horizontal, 24)
        }
    }

    private var songRecorderSheet: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Image(systemName: viewModel.isRecordingSong ? "waveform.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(viewModel.isRecordingSong ? AppColors.missGradientStart : AppColors.primaryGradientStart)
                Text(viewModel.isRecordingSong ? "Recording the song…" : "Record a Playing Song")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColors.textPrimary)
                Text(viewModel.isRecordingSong
                     ? "Play the song near this device. Stop when you have enough for a useful practice line."
                     : "The microphone recording stays on this device and will be analyzed into harmonica note guidance.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            TextField("Song name (optional)", text: $recordedSongTitle)
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.isRecordingSong)

            Text(formattedElapsed(viewModel.songRecordingElapsed))
                .font(AppTypography.mono.monospacedDigit())
                .foregroundStyle(AppColors.textPrimary)

            Button {
                handleSongRecordingToggle()
            } label: {
                Label(viewModel.isRecordingSong ? "Stop and Analyze" : "Start Recording",
                      systemImage: viewModel.isRecordingSong ? "stop.fill" : "record.circle")
                    .frame(maxWidth: .infinity, minHeight: 46)
            }
            .buttonStyle(StudioControlButtonStyle(isProminent: true, tint: viewModel.isRecordingSong ? AppGradients.miss : AppGradients.primary))

            if !viewModel.isRecordingSong {
                Button("Cancel", role: .cancel) { isSongRecorderPresented = false }
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(22)
        .frame(maxWidth: 560)
    }

    private func noticeBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.primaryGradientStart)
            Text(message)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.07))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Notice: \(message)")
    }

    private var onboardingOverlay: some View {
        ZStack {
            Color.black.opacity(0.52)
                .ignoresSafeArea()

            ViewThatFits(in: .vertical) {
                onboardingCard

                ScrollView {
                    onboardingCard
                        .padding(.vertical, 12)
                }
                .scrollIndicators(.hidden)
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
        }
    }

    private var onboardingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Start")
                .font(AppTypography.title)
                .foregroundStyle(AppColors.textPrimary)

            Text("Allow microphone access, then match each target note.")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                onboardingRow(icon: "arrow.up", text: "Blow: push air out through the harmonica")
                onboardingRow(icon: "arrow.down", text: "Draw: pull air in through the harmonica")
                onboardingRow(icon: "books.vertical.fill", text: "Library: choose built-in songs or add your own audio")
                onboardingRow(icon: "waveform.badge.mic", text: "Freestyle: capture a performance and practice it later")
            }

            Button {
                requestMicPermissionFromOnboarding()
            } label: {
                Text("Enable Microphone")
                    .frame(maxWidth: .infinity, minHeight: 46)
            }
            .buttonStyle(StudioControlButtonStyle(isProminent: true, tint: AppGradients.primary))

            Button {
                hasSeenOnboarding = true
                showOnboarding = false
            } label: {
                Text("Explore Without Microphone")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(StudioControlButtonStyle())
        }
        .padding(18)
        .liquidGlass(cornerRadius: 20, intensity: 0.04)
    }

    private func controlsPanel(safeAreaBottom: CGFloat, usesCompactLayout: Bool) -> some View {
        controlsContent(usesCompactLayout: usesCompactLayout)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.bottom, safeAreaBottom)
    }

    private func controlsContent(usesCompactLayout: Bool) -> some View {
        ControlsView(
            isAudioRunning: viewModel.isAudioRunning,
            isFreestyleMode: viewModel.isFreestyleMode,
            isFreestyleRecording: viewModel.isFreestyleRecording,
            canPlayFreestyleAudio: viewModel.selectedFreestyleHasAudio,
            isFreestylePlayingAudio: viewModel.isFreestylePlayingAudio,
            isFreestyleSong: viewModel.selectedSongIsFreestyle,
            isImportedSong: viewModel.selectedRecordingIsImportedSong,
            canPlaySynthesizedCover: viewModel.selectedSongHasPlayableNotes,
            isSynthesizedCoverPlaying: viewModel.isSynthesizedCoverPlaying,
            usesCompactLayout: usesCompactLayout,
            onPrimaryAction: {
                if viewModel.isFreestyleMode {
                    handleFreestyleRecordingToggle()
                } else {
                    handleControlsStartStop()
                }
            },
            onToggleFreestylePlayback: handleFreestylePlaybackToggle,
            onRemoveFreestyleAudio: handleRemoveFreestyleAudio,
            onToggleSynthesizedCover: handleSynthesizedCoverToggle
        )
    }

    private func onboardingRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.primaryGradientStart)
                .frame(width: 16)

            Text(text)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            AppColors.backgroundDeep
            BackgroundGradientView().opacity(0.45)
        }
        .ignoresSafeArea()
    }

    private func requestMicPermissionFromOnboarding() {
        viewModel.audioService.requestPermission { granted in
            guard granted else {
                micAlertMessage = "Microphone access is required to detect notes. Enable it in Settings."
                showMicAlert = true
                return
            }

            do {
                try viewModel.audioService.start()
                hasSeenOnboarding = true
                showOnboarding = false
                playCallAndResponseReferenceIfNeeded()
            } catch {
                micAlertMessage = "Could not start audio input: \(error.localizedDescription)"
                showMicAlert = true
            }
        }
    }

    private func handleAudioToggle(autoHideOnStart: Bool = false) {
        if viewModel.isAudioRunning {
            viewModel.audioService.stop()
            return
        }

        viewModel.audioService.requestPermission { granted in
            guard granted else {
                micAlertMessage = "Microphone access is required to start listening. Enable it in Settings."
                showMicAlert = true
                return
            }

            do {
                try viewModel.audioService.start()
                if autoHideOnStart { playCallAndResponseReferenceIfNeeded() }
            } catch {
                micAlertMessage = "Could not start audio input: \(error.localizedDescription)"
                showMicAlert = true
            }
        }
    }

    private func handleControlsStartStop() {
        handleAudioToggle(autoHideOnStart: true)
    }

    private func handleFreestyleModeToggle() {
        if viewModel.isFreestyleMode {
            if viewModel.isFreestyleRecording {
                do {
                    try viewModel.stopFreestyleRecordingAndSave()
                } catch {
                    micAlertMessage = "Could not finish recording: \(error.localizedDescription)"
                    showMicAlert = true
                }
            }
            viewModel.exitFreestyleMode()
        } else {
            viewModel.enterFreestyleMode()
        }
    }

    private func handleFreestyleRecordingToggle() {
        guard !showOnboarding else { return }

        if viewModel.isFreestyleRecording {
            do {
                try viewModel.stopFreestyleRecordingAndSave()
            } catch {
                micAlertMessage = "Could not save freestyle recording: \(error.localizedDescription)"
                showMicAlert = true
            }
            return
        }

        ensureAudioReady {
            do {
                try viewModel.startFreestyleRecording()
            } catch {
                micAlertMessage = "Could not start freestyle recording: \(error.localizedDescription)"
                showMicAlert = true
            }
        }
    }

    private func handleSongRecordingToggle() {
        if viewModel.isRecordingSong {
            do {
                try viewModel.stopSongRecordingAndAnalyze()
                isSongRecorderPresented = false
            } catch {
                micAlertMessage = "Could not finish the song recording: \(error.localizedDescription)"
                showMicAlert = true
            }
            return
        }

        viewModel.audioService.requestPermission { granted in
            guard granted else {
                micAlertMessage = "Microphone access is required to record a playing song. Enable it in Settings."
                showMicAlert = true
                return
            }
            do {
                try viewModel.startSongRecording(title: recordedSongTitle)
            } catch {
                micAlertMessage = "Could not start song recording: \(error.localizedDescription)"
                showMicAlert = true
            }
        }
    }

    private func handleFreestylePlaybackToggle() {
        if viewModel.isFreestylePlayingAudio {
            viewModel.stopSelectedFreestyleAudio()
            return
        }

        do {
            try viewModel.playSelectedFreestyleAudio()
        } catch {
            micAlertMessage = "Could not play recording: \(error.localizedDescription)"
            showMicAlert = true
        }
    }

    private func handleReferenceNoteToggle() {
        if viewModel.isReferenceNotePlaying {
            viewModel.stopCurrentReferenceNote()
            return
        }

        do {
            try viewModel.playCurrentReferenceNote()
        } catch {
            micAlertMessage = "Could not play the reference note: \(error.localizedDescription)"
            showMicAlert = true
        }
    }

    private func handleSynthesizedCoverToggle() {
        if viewModel.isSynthesizedCoverPlaying {
            viewModel.stopSelectedSynthesizedCover()
            return
        }

        do {
            try viewModel.playSelectedSynthesizedCover()
        } catch {
            micAlertMessage = "Could not play the harmonica cover: \(error.localizedDescription)"
            showMicAlert = true
        }
    }

    @discardableResult
    private func selectSongForPractice(_ song: HarmonicaSong) -> Bool {
        do {
            try viewModel.selectSongForGuidedPractice(song)
            return true
        } catch {
            micAlertMessage = "Could not finish the freestyle recording: \(error.localizedDescription)"
            showMicAlert = true
            return false
        }
    }

    private func prepareRename(_ song: HarmonicaSong) {
        guard selectSongForPractice(song) else { return }
        guard let recording = viewModel.selectedRecording else { return }
        renameText = recording.title
        showRenamePrompt = true
    }

    private func prepareDelete(_ song: HarmonicaSong) {
        guard selectSongForPractice(song) else { return }
        showDeleteRecordingConfirm = true
    }

    private func handleRemoveFreestyleAudio() {
        guard viewModel.selectedSongIsFreestyle else { return }
        showRemoveAudioConfirm = true
    }

    private func ensureAudioReady(onReady: @escaping () -> Void) {
        if viewModel.isAudioRunning {
            onReady()
            return
        }

        viewModel.audioService.requestPermission { granted in
            guard granted else {
                micAlertMessage = "Microphone access is required to record freestyle sessions. Enable it in Settings."
                showMicAlert = true
                return
            }

            do {
                try viewModel.audioService.start()
                onReady()
            } catch {
                micAlertMessage = "Could not start audio input: \(error.localizedDescription)"
                showMicAlert = true
            }
        }
    }

    private func autoCalibrateSensitivity() {
        ensureAudioReady {
            viewModel.startSensitivityCalibration()
        }
    }

    private func playCallAndResponseReferenceIfNeeded() {
        guard callAndResponseEnabled, viewModel.isAudioRunning,
              !viewModel.isFreestyleMode, !viewModel.isPracticeComplete else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard callAndResponseEnabled, viewModel.isAudioRunning,
                  !viewModel.isPracticeComplete else { return }
            try? viewModel.playCurrentReferenceNote()
        }
    }

    private func formattedElapsed(_ value: TimeInterval) -> String {
        let seconds = max(0, Int(value.rounded()))
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }

    private func restorePreferencesIfNeeded() {
        guard !hasRestoredPreferences else { return }
        hasRestoredPreferences = true

        viewModel.sensitivity = min(0.2, max(0.005, storedSensitivity))
        if let layout = HarmonicaLayout(rawValue: storedLayout) {
            viewModel.selectedLayout = layout
        }
        if let savedSong = viewModel.songs.first(where: { $0.id == storedSelectedSongID }) {
            viewModel.selectedSong = savedSong
        }
    }

    private func presentAfterAddSheet(_ presentation: @escaping () -> Void) {
        showAddSongOptions = false
        DispatchQueue.main.async(execute: presentation)
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func triggerHapticFeedback(for state: NoteMatchState) {
        switch state {
        case .hit:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                generator.impactOccurred()
            }
        case .miss:
            guard Date().timeIntervalSince(lastMissHapticDate) >= 1.2 else { return }
            lastMissHapticDate = Date()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .idle:
            break
        }
    }
}

private struct AddPracticeSongSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onChooseFile: () -> Void
    let onChooseMusic: () -> Void
    let onRecordSong: () -> Void
    let onPasteLink: () -> Void

    var body: some View {
        NavigationStack {
            List {
                sourceRow(
                    title: "Audio File",
                    detail: "Analyze an unprotected audio file from Files.",
                    icon: "doc.badge.plus",
                    action: onChooseFile
                )
                sourceRow(
                    title: "Music Library",
                    detail: "Choose downloaded, unprotected music owned by you.",
                    icon: "music.note.list",
                    action: onChooseMusic
                )
                sourceRow(
                    title: "Record a Playing Song",
                    detail: "Listen through the microphone and build a practice line locally.",
                    icon: "waveform.badge.mic",
                    action: onRecordSong
                )
                sourceRow(
                    title: "Song Link",
                    detail: "Direct audio works locally; streaming links need an authorized provider.",
                    icon: "link",
                    action: onPasteLink
                )
            }
            .navigationTitle("Add Practice Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func sourceRow(title: String, detail: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.primaryGradientStart)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct PracticeSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLayout: HarmonicaLayout
    @Binding var sensitivity: Double
    @Binding var callAndResponseEnabled: Bool
    @ObservedObject var audioService: AudioEngineService
    let isCalibrating: Bool
    let onAutoCalibrate: () -> Void
    let onShowQuickStart: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Harmonica") {
                    LabeledContent("Key", value: "C")
                    Picker("Tuning", selection: $selectedLayout) {
                        Text("Standard Richter").tag(HarmonicaLayout.diatonicC)
                        Text("Lee Oskar").tag(HarmonicaLayout.leeOskarC)
                    }
                    Text("This version currently supports C harmonicas. Additional keys will appear here when transposition is available.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Listening") {
                    Toggle("Call & Response", isOn: $callAndResponseEnabled)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Microphone sensitivity")
                            Spacer()
                            Text(String(format: "%.0f%%", normalizedSensitivity * 100))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $sensitivity, in: 0.005...0.2)
                    }
                    Button(action: onAutoCalibrate) {
                        Label(
                            isCalibrating ? "Listening to Room…" : "Auto-Calibrate to Room",
                            systemImage: "waveform.badge.magnifyingglass"
                        )
                    }
                    .disabled(isCalibrating)
                    Text("Keep the room quiet while calibration samples 1.5 seconds. Current input level: \(String(format: "%.0f%%", min(1, audioService.amplitude / 0.2) * 100)).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Help") {
                    Button(action: onShowQuickStart) {
                        Label("Show Quick Start", systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationTitle("Practice Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var normalizedSensitivity: Double {
        (sensitivity - 0.005) / (0.2 - 0.005)
    }
}

#Preview {
    PracticeView()
}
