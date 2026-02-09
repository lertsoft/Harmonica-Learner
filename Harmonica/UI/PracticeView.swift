import SwiftUI

struct PracticeView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @AppStorage("hasSeenPracticeOnboarding") private var hasSeenOnboarding = false

    @State private var showOnboarding = false
    @State private var showMicAlert = false
    @State private var micAlertMessage = ""
    @State private var showRemoveAudioConfirm = false
    @State private var isControlsPanelVisible = true
    @State private var controlsPanelDragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                backgroundLayer

                VStack(spacing: 12) {
                    HeaderView(
                        selectedSong: $viewModel.selectedSong,
                        selectedKey: $viewModel.selectedKey,
                        selectedLayout: $viewModel.selectedLayout,
                        songs: viewModel.songs,
                        isFreestyleMode: viewModel.isFreestyleMode,
                        onToggleFreestyleMode: handleFreestyleModeToggle
                    )

                    statusLine
                        .padding(.horizontal, 16)

                    if let notice = viewModel.noticeMessage {
                        noticeBanner(notice)
                            .padding(.horizontal, 16)
                    }

                    if viewModel.isFreestyleMode {
                        freestyleLiveCard
                            .padding(.horizontal, 16)

                        DetectedPitchView(
                            pitch: viewModel.detectedPitch,
                            matchState: viewModel.matchState
                        )
                        .padding(.horizontal, 16)
                    } else {
                        TargetNoteView(
                            targetNote: viewModel.currentTargetNote,
                            targetHole: viewModel.currentTargetHole,
                            matchState: viewModel.matchState,
                            detectedNote: viewModel.detectedPitch?.fullName,
                            isAudioRunning: viewModel.audioService.isRunning,
                            onToggleListening: handleTargetPillTap
                        )
                        .frame(maxHeight: 250)

                        VStack(spacing: 10) {
                            DetectedPitchView(
                                pitch: viewModel.detectedPitch,
                                matchState: viewModel.matchState
                            )

                            ProgressTrackView(
                                song: viewModel.selectedSong,
                                currentNoteIndex: viewModel.currentNoteIndex,
                                matchState: viewModel.matchState,
                                layout: viewModel.selectedLayout
                            )
                        }
                        .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.top, proxy.safeAreaInsets.top + 8)
                .padding(.bottom, isControlsPanelVisible ? 182 : 20)
                .allowsHitTesting(!showOnboarding)

                if showOnboarding {
                    onboardingOverlay
                }

                if isControlsPanelVisible {
                    controlsPanel(safeAreaBottom: max(8, proxy.safeAreaInsets.bottom))
                        .offset(y: controlsPanelDragOffset)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.32, dampingFraction: 0.84), value: isControlsPanelVisible)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if value.translation.height > 0 {
                                        controlsPanelDragOffset = value.translation.height
                                    }
                                }
                                .onEnded { value in
                                    if value.translation.height > 80 {
                                        hideControlsPanel()
                                    }
                                    controlsPanelDragOffset = 0
                                }
                        )
                        .disabled(showOnboarding)
                }
            }
            .ignoresSafeArea(edges: .top)
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
        .alert("Microphone Access", isPresented: $showMicAlert) {
            Button("Open Settings") {
                openAppSettings()
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(micAlertMessage)
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
            Text("This keeps note targets for learning mode, but deletes playback audio for this freestyle session.")
        }
    }

    private var statusLine: some View {
        HStack {
            Button(action: showControlsPanel) {
                Label(viewModel.audioService.isRunning ? "Listening" : "Mic Off", systemImage: viewModel.audioService.isRunning ? "waveform" : "mic.slash")
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer()

            if viewModel.isFreestyleMode {
                Text(viewModel.isFreestyleRecording ? "Recording" : "Freestyle")
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(viewModel.isFreestyleRecording ? AppColors.missGradientStart : AppColors.primaryGradientStart)
            } else {
                Text(stageText)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(stageColor)
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

            VStack(alignment: .leading, spacing: 14) {
                Text("Quick Start")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Allow microphone access, then match each target note.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)

                VStack(alignment: .leading, spacing: 8) {
                    onboardingRow(icon: "arrow.up", text: "Blow: push air out through the harmonica")
                    onboardingRow(icon: "arrow.down", text: "Draw: pull air in through the harmonica")
                }

                Button {
                    requestMicPermissionFromOnboarding()
                } label: {
                    Text("Enable Microphone")
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(StudioControlButtonStyle(isProminent: true, tint: AppGradients.primary))

                Button {
                    hasSeenOnboarding = true
                    showOnboarding = false
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                }
                .buttonStyle(StudioControlButtonStyle())
            }
            .padding(18)
            .liquidGlass(cornerRadius: 20, intensity: 0.04)
            .padding(.horizontal, 22)
        }
    }

    private func controlsPanel(safeAreaBottom: CGFloat) -> some View {
        VStack(spacing: 6) {
            Capsule()
                .fill(Color.white.opacity(0.25))
                .frame(width: 44, height: 5)
                .padding(.top, 6)

            ControlsView(
                isAudioRunning: viewModel.audioService.isRunning,
                sensitivity: $viewModel.sensitivity,
                attemptCount: viewModel.attemptCount,
                isFreestyleMode: viewModel.isFreestyleMode,
                isFreestyleRecording: viewModel.isFreestyleRecording,
                canPlayFreestyleAudio: viewModel.selectedFreestyleHasAudio,
                isFreestylePlayingAudio: viewModel.isFreestylePlayingAudio,
                isProgressionEnabled: viewModel.selectedFreestyleHasPlayableNotes,
                isFreestyleSong: viewModel.selectedSongIsFreestyle,
                canRemoveFreestyleAudio: viewModel.selectedFreestyleHasAudio,
                onStartStop: handleControlsStartStop,
                onNewAttempt: viewModel.startNewAttempt,
                onNextNote: viewModel.advanceNote,
                onToggleFreestyleRecording: handleFreestyleRecordingToggle,
                onToggleFreestylePlayback: handleFreestylePlaybackToggle,
                onRemoveFreestyleAudio: handleRemoveFreestyleAudio
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, safeAreaBottom)
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
                hideControlsPanel()
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
                if autoHideOnStart {
                    hideControlsPanel()
                }
            } catch {
                micAlertMessage = "Could not start audio input: \(error.localizedDescription)"
                showMicAlert = true
            }
        }
    }

    private func handleControlsStartStop() {
        handleAudioToggle(autoHideOnStart: true)
    }

    private func handleTargetPillTap() {
        guard !showOnboarding else { return }
        if viewModel.audioService.isRunning {
            if isControlsPanelVisible {
                hideControlsPanel()
            } else {
                showControlsPanel()
            }
            return
        }
        showControlsPanel()
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
            showControlsPanel()
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if viewModel.isFreestyleRecording {
                        hideControlsPanel()
                    }
                }
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

    private func showControlsPanel() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
            isControlsPanelVisible = true
        }
    }

    private func hideControlsPanel() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
            isControlsPanelVisible = false
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

#Preview {
    PracticeView()
}
