import SwiftUI
import UniformTypeIdentifiers

struct PracticeView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @AppStorage("hasSeenPracticeOnboarding") private var hasSeenOnboarding = false
    @AppStorage("callAndResponseEnabled") private var callAndResponseEnabled = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var showOnboarding = false
    @State private var showMicAlert = false
    @State private var micAlertMessage = ""
    @State private var showRemoveAudioConfirm = false
    @State private var showDeleteRecordingConfirm = false
    @State private var showRenamePrompt = false
    @State private var isSongImporterPresented = false
    @State private var renameText = ""
    @State private var showSetupSheet = false

    var body: some View {
        GeometryReader { proxy in
            let layout = AdaptivePracticeLayout.resolve(
                size: proxy.size,
                usesAccessibilityText: dynamicTypeSize.isAccessibilitySize
            )

            ZStack {
                ZStack {
                    backgroundLayer

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
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    controlsPanel(safeAreaBottom: 8)
                        .disabled(showOnboarding || viewModel.isImportingSong)
                }

                if showOnboarding {
                    onboardingOverlay
                }

                if viewModel.isImportingSong {
                    importingOverlay
                }
            }
        }
        .onAppear {
            showOnboarding = !hasSeenOnboarding
        }
        .onReceive(viewModel.audioService.$frequency) { frequency in
            viewModel.handleFrequency(frequency, amplitude: viewModel.audioService.amplitude)
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
        }
        .onChange(of: viewModel.currentNoteIndex) { _, _ in
            playCallAndResponseReferenceIfNeeded()
        }
        .sheet(isPresented: $showSetupSheet) {
            PracticeSetupSheet(
                selectedKey: $viewModel.selectedKey,
                selectedLayout: $viewModel.selectedLayout,
                sensitivity: $viewModel.sensitivity,
                callAndResponseEnabled: $callAndResponseEnabled,
                liveAmplitude: viewModel.audioService.amplitude,
                onAutoCalibrate: autoCalibrateSensitivity
            )
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
                selectedSong: $viewModel.selectedSong,
                songs: viewModel.songs,
                selectedKey: viewModel.selectedKey,
                selectedLayout: viewModel.selectedLayout,
                isFreestyleMode: viewModel.isFreestyleMode,
                canManageSelectedSong: viewModel.selectedSongIsFreestyle,
                selectedSongIsImported: viewModel.selectedRecordingIsImportedSong,
                onToggleFreestyleMode: handleFreestyleModeToggle,
                onShowSetup: { showSetupSheet = true },
                onAddSong: { isSongImporterPresented = true },
                onRenameSelectedSong: prepareRename,
                onDeleteSelectedSong: { showDeleteRecordingConfirm = true }
            )

            statusLine

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
                targetNoteContent
                    .frame(maxWidth: .infinity, alignment: .top)

                pitchAndProgressContent
                    .frame(maxWidth: .infinity, alignment: .top)
            }
        } else {
            targetNoteContent
            pitchAndProgressContent
        }
    }

    @ViewBuilder
    private func freestyleContent(layout: AdaptivePracticeLayout) -> some View {
        if layout.usesTwoColumnPractice {
            HStack(alignment: .top, spacing: layout.contentSpacing) {
                freestyleLiveCard
                    .frame(maxWidth: .infinity)
                detectedPitchContent
                    .frame(maxWidth: .infinity)
            }
        } else {
            freestyleLiveCard
            detectedPitchContent
        }
    }

    private var targetNoteContent: some View {
        TargetNoteView(
            targetNote: viewModel.currentTargetNote,
            targetHole: viewModel.currentTargetHole,
            detectedPitch: viewModel.detectedPitch,
            matchState: viewModel.matchState,
            isAudioRunning: viewModel.audioService.isRunning,
            isReferenceNotePlaying: viewModel.isReferenceNotePlaying,
            canProgress: viewModel.selectedFreestyleHasPlayableNotes,
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

    private var detectedPitchContent: some View {
        DetectedPitchView(
            pitch: viewModel.detectedPitch,
            matchState: viewModel.matchState
        )
    }

    private var statusLine: some View {
        HStack {
            HStack(spacing: 7) {
                Circle()
                    .fill(unifiedStatusColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: unifiedStatusColor.opacity(0.7), radius: viewModel.audioService.isRunning ? 5 : 0)
                Text(unifiedStatusText)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(unifiedStatusColor)
            }

            Spacer()

            if viewModel.isFreestyleMode {
                Text(viewModel.isFreestyleRecording ? "Recording" : "Freestyle")
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(viewModel.isFreestyleRecording ? AppColors.missGradientStart : AppColors.primaryGradientStart)
            } else {
                Text(callAndResponseEnabled ? "Call & Response" : "Auto-advance • 0.3s hold")
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(.horizontal, 10)
    }

    private var freestyleLiveCard: some View {
        VStack(spacing: 10) {
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

            Text(viewModel.detectedPitch?.fullName ?? "--")
                .font(AppTypography.hero)
                .foregroundStyle(AppColors.textPrimary)

            Text("Play freely. Your notes and audio will be saved.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .liquidGlass(cornerRadius: 18, intensity: 0.03)
    }

    private var importingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .tint(AppColors.primaryGradientStart)
                    .scaleEffect(1.15)
                Text("Finding a playable harmonica line…")
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)
                Text("The result is a practice suggestion, especially for full-band mixes.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .liquidGlass(cornerRadius: 18, intensity: 0.04)
            .frame(maxWidth: 520)
            .padding(.horizontal, 24)
        }
    }

    private func noticeBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.primaryGradientStart)
            Text(message)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.07))
        )
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
                Text("Continue")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(StudioControlButtonStyle())
        }
        .padding(18)
        .liquidGlass(cornerRadius: 20, intensity: 0.04)
    }

    private func controlsPanel(safeAreaBottom: CGFloat) -> some View {
        controlsContent
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.bottom, safeAreaBottom)
    }

    private var controlsContent: some View {
        ControlsView(
            isAudioRunning: viewModel.audioService.isRunning,
            isFreestyleMode: viewModel.isFreestyleMode,
            isFreestyleRecording: viewModel.isFreestyleRecording,
            canPlayFreestyleAudio: viewModel.selectedFreestyleHasAudio,
            isFreestylePlayingAudio: viewModel.isFreestylePlayingAudio,
            isFreestyleSong: viewModel.selectedSongIsFreestyle,
            onPrimaryAction: {
                if viewModel.isFreestyleMode {
                    handleFreestyleRecordingToggle()
                } else {
                    handleControlsStartStop()
                }
            },
            onShowSettings: { showSetupSheet = true },
            onToggleFreestylePlayback: handleFreestylePlaybackToggle,
            onRemoveFreestyleAudio: handleRemoveFreestyleAudio
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

    private var stageText: String {
        switch viewModel.matchState {
        case .hit: return "On Target"
        case .miss: return "Adjust Pitch"
        case .idle: return "Ready"
        }
    }

    private var stageColor: Color {
        switch viewModel.matchState {
        case .hit: return AppColors.hitGradientStart
        case .miss: return AppColors.missGradientStart
        case .idle: return AppColors.textSecondary
        }
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
        if viewModel.audioService.isRunning {
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

    private func prepareRename() {
        guard let recording = viewModel.selectedRecording else { return }
        renameText = recording.title
        showRenamePrompt = true
    }

    private func handleRemoveFreestyleAudio() {
        guard viewModel.selectedSongIsFreestyle else { return }
        showRemoveAudioConfirm = true
    }

    private func ensureAudioReady(onReady: @escaping () -> Void) {
        if viewModel.audioService.isRunning {
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

    private var unifiedStatusText: String {
        guard viewModel.audioService.isRunning else { return "Mic Off • Ready to start" }
        switch viewModel.matchState {
        case .hit: return "Detected • In Tune"
        case .miss: return "Listening • Adjust pitch"
        case .idle: return "Listening"
        }
    }

    private var unifiedStatusColor: Color {
        guard viewModel.audioService.isRunning else { return AppColors.textSecondary }
        switch viewModel.matchState {
        case .hit: return AppColors.hitGradientStart
        case .miss: return AppColors.idleGradientStart
        case .idle: return AppColors.primaryGradientStart
        }
    }

    private func autoCalibrateSensitivity() {
        let measuredNoise = max(0.005, viewModel.audioService.amplitude)
        viewModel.sensitivity = min(0.2, max(0.012, measuredNoise * 1.8))
    }

    private func playCallAndResponseReferenceIfNeeded() {
        guard callAndResponseEnabled, viewModel.audioService.isRunning, !viewModel.isFreestyleMode else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard callAndResponseEnabled, viewModel.audioService.isRunning else { return }
            try? viewModel.playCurrentReferenceNote()
        }
    }

    private func formattedElapsed(_ value: TimeInterval) -> String {
        let seconds = max(0, Int(value.rounded()))
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
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
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .idle:
            break
        }
    }
}

private struct PracticeSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedKey: String
    @Binding var selectedLayout: HarmonicaLayout
    @Binding var sensitivity: Double
    @Binding var callAndResponseEnabled: Bool
    let liveAmplitude: Double
    let onAutoCalibrate: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Harmonica") {
                    Picker("Key", selection: $selectedKey) {
                        Text("Key of C").tag("C")
                    }
                    Picker("Tuning", selection: $selectedLayout) {
                        Text("Standard Richter").tag(HarmonicaLayout.diatonicC)
                        Text("Lee Oskar").tag(HarmonicaLayout.leeOskarC)
                    }
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
                        Label("Auto-Calibrate to Room", systemImage: "waveform.badge.magnifyingglass")
                    }
                    Text("Keep the room quiet, then calibrate. Current input level: \(String(format: "%.0f%%", min(1, liveAmplitude / 0.2) * 100)).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
