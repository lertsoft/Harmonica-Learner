import SwiftUI
import MediaPlayer
import StoreKit
import UniformTypeIdentifiers

struct PracticeView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @StateObject private var fullAccessStore = FullAccessStore()
    @AppStorage("hasSeenPracticeOnboarding") private var hasSeenOnboarding = false
    @AppStorage("callAndResponseEnabled") private var callAndResponseEnabled = false
    @AppStorage("practice.sensitivity") private var storedSensitivity = 0.035
    @AppStorage("practice.layout") private var storedLayout = HarmonicaLayout.diatonicC.rawValue
    @AppStorage("practice.selectedSongID") private var storedSelectedSongID = ""
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("practice.reviewPromptedVersion") private var reviewPromptedVersion = ""
    @AppStorage("practice.reviewFreestyleOfferedVersion") private var reviewFreestyleOfferedVersion = ""
    @AppStorage("practice.reviewImportOfferedVersion") private var reviewImportOfferedVersion = ""
    @AppStorage("practice.reviewGuidedOfferedVersion") private var reviewGuidedOfferedVersion = ""

    @State private var showOnboarding = false
    @State private var onboardingStep = 0
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
    @State private var isStartingSongRecording = false
    @State private var songRecordingStartTask: Task<Void, Never>?
    @State private var showSetupSheet = false
    @State private var lastMissHapticDate = Date.distantPast
    @State private var hasRestoredPreferences = false
    @State private var reviewPromptMoment: ReviewPromptMoment?
    @State private var pendingReviewPromptTask: Task<Void, Never>?

    private var isPurchaseRequired: Bool {
        viewModel.successfulMusicLibraryImports >= LibraryImportAllowance.freeSongCount
            && !fullAccessStore.hasFullAccess
    }

    var body: some View {
        practiceScreen
            .onAppear {
                restorePreferencesIfNeeded()
                showOnboarding = !hasSeenOnboarding
                viewModel.hasFullAccess = fullAccessStore.hasFullAccess
                #if DEBUG
                UITestFixtures.importChordIfRequested(into: viewModel)
                #endif
            }
            .onChange(of: fullAccessStore.hasFullAccess) { _, unlocked in
                viewModel.hasFullAccess = unlocked
            }
            .onChange(of: viewModel.successfulMusicLibraryImports) { _, count in
                if count >= LibraryImportAllowance.freeSongCount && !fullAccessStore.hasFullAccess {
                    if viewModel.isFreestyleRecording {
                        _ = try? viewModel.stopFreestyleRecordingAndSave(selectSavedSong: false)
                    }
                    viewModel.audioService.stop()
                    viewModel.notePlaybackService.stop()
                }
            }
            .onChange(of: viewModel.isPracticeComplete) { _, completed in
                promptForReviewIfAppropriate(completed: completed)
            }
            .onChange(of: viewModel.lastSuccessfulSongImportID) { _, importID in
                guard importID != nil else { return }
                queueReviewPrompt(for: .songImport)
            }
            .onChange(of: viewModel.lastSuccessfulFreestyleRecordingID) { _, recordingID in
                guard recordingID != nil else { return }
                queueReviewPrompt(for: .freestyle)
            }
            .onChange(of: showOnboarding) { _, presented in
                if presented {
                    pendingReviewPromptTask?.cancel()
                    pendingReviewPromptTask = nil
                }
            }
            .onDisappear {
                pendingReviewPromptTask?.cancel()
                pendingReviewPromptTask = nil
            }
    }

    private var practiceScreen: some View {
        GeometryReader { proxy in
            let layout = AdaptivePracticeLayout.resolve(
                size: proxy.size,
                usesLargeText: dynamicTypeSize >= .xxLarge,
                usesAccessibilityText: dynamicTypeSize.isAccessibilitySize
            )

            ZStack {
                backgroundLayer

                VStack(spacing: layout.contentSpacing) {
                    if dynamicTypeSize.isAccessibilitySize {
                        ScrollView {
                            practiceContent(layout: layout)
                                .frame(maxWidth: layout.contentMaxWidth)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, layout.horizontalPadding)
                        }
                        .accessibilityIdentifier("accessible-practice-content")
                        .allowsHitTesting(!showOnboarding && !viewModel.isImportingSong && !isPurchaseRequired)
                    } else {
                        practiceContent(layout: layout)
                            .frame(maxWidth: layout.contentMaxWidth)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.horizontal, layout.horizontalPadding)
                            .allowsHitTesting(!showOnboarding && !viewModel.isImportingSong && !isPurchaseRequired)
                    }

                    controlsPanel(safeAreaBottom: 0, usesCompactLayout: layout.isCompactHeight)
                        .disabled(showOnboarding || viewModel.isImportingSong || isPurchaseRequired)
                }
                .padding(.vertical, 8)
                .accessibilityElement(children: .contain)
                .accessibilityHidden(showOnboarding || viewModel.isImportingSong || isPurchaseRequired)

                if viewModel.isImportingSong && !isPurchaseRequired {
                    importingOverlay
                }

                if isPurchaseRequired {
                    purchaseOverlay
                }
            }
            .overlayPreferenceValue(OnboardingCoachTargetKey.self) { targets in
                GeometryReader { overlayProxy in
                    if showOnboarding && !isPurchaseRequired {
                        onboardingOverlay(
                            targetFrame: targets[currentOnboardingTarget].map { overlayProxy[$0] }
                        )
                        .transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: onboardingStep)
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
                    DispatchQueue.main.async {
                        onboardingStep = 0
                        showOnboarding = true
                    }
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
                libraryImportCount: viewModel.successfulMusicLibraryImports,
                onChooseFile: { presentAfterAddSheet { isSongImporterPresented = true } },
                onChooseMusic: { presentAfterAddSheet { requestMusicLibraryAccess() } },
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
            cancelPendingSongRecordingStart()
            if viewModel.isRecordingSong {
                viewModel.cancelSongRecording()
            }
        }) {
            songRecorderSheet
                .interactiveDismissDisabled(viewModel.isRecordingSong || isStartingSongRecording)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(item: $reviewPromptMoment) { moment in
            ReviewCallToActionSheet(
                moment: moment,
                onReview: { requestAppStoreReview(from: moment) },
                onNotNow: { reviewPromptMoment = nil }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
            .interactiveDismissDisabled()
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
                usesDenseLayout: layout.isCompactHeight,
                preferredTextSize: dynamicTypeSize,
                onToggleFreestyleMode: handleFreestyleModeToggle,
                onSelectSong: { _ = selectSongForPractice($0) },
                onShowSetup: { showSetupSheet = true },
                onAddSong: { showAddSongOptions = true },
                onRenameSong: prepareRename,
                onDeleteSong: prepareDelete
            )
            .accessibilityHidden(showOnboarding || viewModel.isImportingSong || isPurchaseRequired)

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
            HStack(spacing: layout.contentSpacing) {
                targetNoteContent(usesCompactLayout: layout.isCompactHeight, usesHorizontalLayout: layout.usesCompactHeader)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                pitchAndProgressContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            targetNoteContent(usesCompactLayout: layout.isCompactHeight)
                .frame(maxHeight: .infinity)
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

    private func targetNoteContent(usesCompactLayout: Bool, usesHorizontalLayout: Bool = false) -> some View {
        TargetNoteView(
            targetNote: viewModel.currentTargetNote,
            targetHole: viewModel.currentTargetHole,
            sourceNotes: viewModel.currentTargetEvent?.sourceNotes,
            hasUnrecoveredAudio: viewModel.selectedRecording?.notes.isEmpty == true,
            detectedPitch: viewModel.detectedPitch,
            matchState: viewModel.matchState,
            isAudioRunning: viewModel.isAudioRunning,
            isReferenceNotePlaying: viewModel.isReferenceNotePlaying,
            canProgress: viewModel.selectedFreestyleHasPlayableNotes,
            isComplete: viewModel.isPracticeComplete,
            usesCompactLayout: usesCompactLayout,
            usesHorizontalLayout: usesHorizontalLayout,
            onRestart: viewModel.startNewAttempt,
            onSkip: viewModel.advanceNote,
            onToggleReferenceNote: handleReferenceNoteToggle
        )
        .accessibilityHidden(showOnboarding || viewModel.isImportingSong || isPurchaseRequired)
    }

    private var pitchAndProgressContent: some View {
        ProgressTrackView(
            song: viewModel.selectedSong,
            currentNoteIndex: viewModel.currentNoteIndex,
            matchState: viewModel.matchState,
            layout: viewModel.selectedLayout,
            arrangementExplanation: viewModel.selectedRecording?.arrangement?.explanation
        )
        .accessibilityHidden(showOnboarding || viewModel.isImportingSong || isPurchaseRequired)
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
                    .accessibilityIdentifier("freestyleElapsedTime")
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
        .frame(maxHeight: .infinity)
        .liquidGlass(cornerRadius: 18, intensity: 0.03)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("freestyle-live-card")
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
                Text("Melody and chord tones become a playable arrangement. Dense mixes may be less accurate.")
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
        ScrollView {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                if isStartingSongRecording {
                    ProgressView()
                        .controlSize(.large)
                        .tint(AppColors.primaryGradientStart)
                        .frame(width: 48, height: 48)
                } else {
                    Image(systemName: viewModel.isRecordingSong ? "waveform.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(viewModel.isRecordingSong ? AppColors.missGradientStart : AppColors.primaryGradientStart)
                }
                Text(isStartingSongRecording ? "Preparing the recorder…" : (viewModel.isRecordingSong ? "Recording the song…" : "Record a Playing Song"))
                    .font(AppTypography.title)
                    .foregroundStyle(AppColors.textPrimary)
                Text(viewModel.isRecordingSong
                     ? "Play the song near this device. The full recording is analyzed; clearer audio gives better note and chord estimates."
                     : "Play a song on another device or perform nearby. Audio stays on this device and becomes an approximate harmonica arrangement with chord tones played in sequence. Other apps’ internal audio is not captured.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            TextField("Song name (optional)", text: $recordedSongTitle)
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.isRecordingSong || isStartingSongRecording)

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
            .disabled(isStartingSongRecording)

            if viewModel.isRecordingSong {
                Button("Discard Recording", role: .destructive) {
                    viewModel.cancelSongRecording()
                    isSongRecorderPresented = false
                }
            } else {
                Button("Cancel", role: .cancel) {
                    cancelPendingSongRecordingStart()
                    isSongRecorderPresented = false
                }
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(22)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
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

    private var currentOnboardingTarget: OnboardingCoachTarget {
        switch onboardingStep {
        case 0: return .songLibrary
        case 1: return .targetNote
        case 2: return .practiceStyle
        default: return .primaryAction
        }
    }

    private func onboardingOverlay(targetFrame: CGRect?) -> some View {
        OnboardingCoachOverlay(
            stepIndex: onboardingStep,
            targetFrame: targetFrame,
            onBack: { onboardingStep = max(0, onboardingStep - 1) },
            onNext: { onboardingStep = min(3, onboardingStep + 1) },
            onFinishWithMicrophone: requestMicPermissionFromOnboarding,
            onFinishWithoutMicrophone: finishOnboardingWithoutMicrophone
        )
    }

    private var purchaseOverlay: some View {
        ZStack {
            AppColors.backgroundDeep.ignoresSafeArea()
            BackgroundGradientView().opacity(0.45).ignoresSafeArea()

            if !fullAccessStore.hasCheckedEntitlement {
                ProgressView("Checking purchase…")
                    .tint(AppColors.cyanAccent)
                    .foregroundStyle(AppColors.textPrimary)
            } else {
                ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "music.note.house.fill")
                        .font(.system(size: 54, weight: .light))
                        .foregroundStyle(AppColors.cyanAccent)
                        .padding(.top, 12)

                    Text("Keep the music going")
                        .font(AppTypography.hero)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)

                    Text("You've added five songs from your Music Library. Unlock Harmonica Learner to keep practicing and add more songs.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 12) {
                        onboardingRow(icon: "checkmark.circle.fill", text: "Keep your saved songs and recordings")
                        onboardingRow(icon: "checkmark.circle.fill", text: "Continue importing local Music Library tracks")
                        onboardingRow(icon: "checkmark.circle.fill", text: "One-time purchase, no subscription")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .liquidGlass(cornerRadius: 20, intensity: 0.04)

                    Button {
                        Task { await fullAccessStore.purchase() }
                    } label: {
                        Text(fullAccessStore.product.map { "Unlock for \($0.displayPrice)" } ?? "Purchase unavailable")
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(StudioControlButtonStyle(isProminent: true, tint: AppGradients.primary))
                    .disabled(fullAccessStore.product == nil || fullAccessStore.isBusy)

                    Button("Restore Purchase") {
                        Task { await fullAccessStore.restore() }
                    }
                    .frame(minHeight: 44)
                    .disabled(fullAccessStore.isBusy)

                    if fullAccessStore.product == nil {
                        Button("Retry Purchase Loading") {
                            Task { await fullAccessStore.loadProduct() }
                        }
                        .frame(minHeight: 44)
                        .disabled(fullAccessStore.isBusy)
                    }

                    if fullAccessStore.isBusy {
                        ProgressView().tint(AppColors.cyanAccent)
                    }
                    if let error = fullAccessStore.errorMessage {
                        Text(error)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                }
            }
        }
        .accessibilityAddTraits(.isModal)
    }

    private func controlsPanel(safeAreaBottom: CGFloat, usesCompactLayout: Bool) -> some View {
        controlsContent(usesCompactLayout: usesCompactLayout)
        .accessibilityHidden(showOnboarding || viewModel.isImportingSong || isPurchaseRequired)
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

            Task { @MainActor in
                do {
                    try await viewModel.audioService.start()
                    hasSeenOnboarding = true
                    showOnboarding = false
                    playCallAndResponseReferenceIfNeeded()
                } catch {
                    micAlertMessage = "Could not start audio input: \(error.localizedDescription)"
                    showMicAlert = true
                }
            }
        }
    }

    private func finishOnboardingWithoutMicrophone() {
        hasSeenOnboarding = true
        showOnboarding = false
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

            Task { @MainActor in
                do {
                    try await viewModel.audioService.start()
                    if autoHideOnStart { playCallAndResponseReferenceIfNeeded() }
                } catch {
                    micAlertMessage = "Could not start audio input: \(error.localizedDescription)"
                    showMicAlert = true
                }
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
                try await viewModel.startFreestyleRecording()
            } catch {
                micAlertMessage = "Could not start freestyle recording: \(error.localizedDescription)"
                showMicAlert = true
            }
        }
    }

    private func requestMusicLibraryAccess() {
        guard !isPurchaseRequired else { return }
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                guard !isPurchaseRequired else { return }
                if status == .authorized {
                    isMusicLibraryPickerPresented = true
                } else {
                    micAlertMessage = "Music Library access is required to choose local songs. Enable it in Settings, or import an audio file from Files instead."
                    showMicAlert = true
                }
            }
        }
    }

    private func promptForReviewIfAppropriate(completed: Bool) {
        guard completed, !isPurchaseRequired, !showOnboarding else { return }
        queueReviewPrompt(for: .guidedPractice, delay: .seconds(2))
    }

    private var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    private func queueReviewPrompt(
        for moment: ReviewPromptMoment,
        delay: Duration = .milliseconds(650)
    ) {
        let version = currentAppVersion
        guard reviewPromptedVersion != version,
              offeredReviewVersion(for: moment) != version,
              reviewPromptMoment == nil,
              hasSeenOnboarding,
              !showOnboarding,
              !isPurchaseRequired else { return }

        // Only a completed activity outside the tour can schedule a review offer.
        pendingReviewPromptTask?.cancel()
        pendingReviewPromptTask = Task { @MainActor in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }
            guard scenePhase == .active,
                  reviewPromptedVersion != version,
                  offeredReviewVersion(for: moment) != version,
                  reviewPromptMoment == nil,
                  !showOnboarding,
                  !isPurchaseRequired else { return }
            markReviewOffered(moment, version: version)
            reviewPromptMoment = moment
        }
    }

    private func requestAppStoreReview(from moment: ReviewPromptMoment) {
        let version = currentAppVersion
        markReviewOffered(moment, version: version)
        reviewPromptedVersion = version
        reviewPromptMoment = nil

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            guard scenePhase == .active, !isPurchaseRequired, !showOnboarding else { return }
            requestReview()
        }
    }

    private func offeredReviewVersion(for moment: ReviewPromptMoment) -> String {
        switch moment {
        case .freestyle: reviewFreestyleOfferedVersion
        case .songImport: reviewImportOfferedVersion
        case .guidedPractice: reviewGuidedOfferedVersion
        }
    }

    private func markReviewOffered(_ moment: ReviewPromptMoment, version: String) {
        switch moment {
        case .freestyle: reviewFreestyleOfferedVersion = version
        case .songImport: reviewImportOfferedVersion = version
        case .guidedPractice: reviewGuidedOfferedVersion = version
        }
    }

    private func handleSongRecordingToggle() {
        guard !isStartingSongRecording else { return }

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

        isStartingSongRecording = true
        viewModel.audioService.requestPermission { granted in
            guard isSongRecorderPresented else {
                isStartingSongRecording = false
                return
            }
            guard granted else {
                isStartingSongRecording = false
                micAlertMessage = "Microphone access is required to record a playing song. Enable it in Settings."
                showMicAlert = true
                return
            }
            songRecordingStartTask = Task { @MainActor in
                defer {
                    isStartingSongRecording = false
                    songRecordingStartTask = nil
                }
                do {
                    try Task.checkCancellation()
                    try await viewModel.startSongRecording(title: recordedSongTitle)
                    try Task.checkCancellation()
                    guard isSongRecorderPresented else {
                        viewModel.cancelSongRecording()
                        return
                    }
                } catch is CancellationError {
                    if viewModel.isRecordingSong {
                        viewModel.cancelSongRecording()
                    }
                } catch {
                    micAlertMessage = "Could not start song recording: \(error.localizedDescription)"
                    showMicAlert = true
                }
            }
        }
    }

    private func cancelPendingSongRecordingStart() {
        songRecordingStartTask?.cancel()
        songRecordingStartTask = nil
        isStartingSongRecording = false
    }

    private func handleFreestylePlaybackToggle() {
        if viewModel.isFreestylePlayingAudio {
            viewModel.stopSelectedFreestyleAudio()
            return
        }

        Task { @MainActor in
            do {
                try await viewModel.playSelectedFreestyleAudio()
            } catch {
                micAlertMessage = "Could not play recording: \(error.localizedDescription)"
                showMicAlert = true
            }
        }
    }

    private func handleReferenceNoteToggle() {
        if viewModel.isReferenceNotePlaying {
            viewModel.stopCurrentReferenceNote()
            return
        }

        Task { @MainActor in
            do {
                try await viewModel.playCurrentReferenceNote()
            } catch {
                micAlertMessage = "Could not play the reference note: \(error.localizedDescription)"
                showMicAlert = true
            }
        }
    }

    private func handleSynthesizedCoverToggle() {
        if viewModel.isSynthesizedCoverPlaying {
            viewModel.stopSelectedSynthesizedCover()
            return
        }

        Task { @MainActor in
            do {
                try await viewModel.playSelectedSynthesizedCover()
            } catch {
                micAlertMessage = "Could not play the harmonica cover: \(error.localizedDescription)"
                showMicAlert = true
            }
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

    private func ensureAudioReady(onReady: @escaping @MainActor () async -> Void) {
        if viewModel.isAudioRunning {
            Task { @MainActor in await onReady() }
            return
        }

        viewModel.audioService.requestPermission { granted in
            guard granted else {
                micAlertMessage = "Microphone access is required to record freestyle sessions. Enable it in Settings."
                showMicAlert = true
                return
            }

            Task { @MainActor in
                do {
                    try await viewModel.audioService.start()
                    await onReady()
                } catch {
                    micAlertMessage = "Could not start audio input: \(error.localizedDescription)"
                    showMicAlert = true
                }
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
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            guard callAndResponseEnabled, viewModel.isAudioRunning,
                  !viewModel.isPracticeComplete else { return }
            try? await viewModel.playCurrentReferenceNote()
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

    private func presentAfterAddSheet(_ presentation: @escaping @MainActor @Sendable () -> Void) {
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

private enum ReviewPromptMoment: String, Identifiable {
    case freestyle
    case songImport
    case guidedPractice

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .freestyle: "waveform"
        case .songImport: "music.note.list"
        case .guidedPractice: "checkmark.circle.fill"
        }
    }

    var title: String {
        switch self {
        case .freestyle: "Enjoying Freestyle?"
        case .songImport: "Your song is ready"
        case .guidedPractice: "Nice practice session"
        }
    }

    var message: String {
        switch self {
        case .freestyle:
            "If capturing your own playing feels useful, share a quick review on the App Store."
        case .songImport:
            "If adding your own music makes practice better, tell other learners in a quick review."
        case .guidedPractice:
            "If Harmonica Learner is helping you improve, a quick review would mean a lot."
        }
    }
}

private struct ReviewCallToActionSheet: View {
    let moment: ReviewPromptMoment
    let onReview: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: moment.icon)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(AppColors.cyanAccent)
                    .frame(width: 76, height: 76)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("ENJOYING HARMONICA LEARNER?")
                        .font(AppTypography.sectionLabel)
                        .foregroundStyle(AppColors.cyanAccent)
                        .multilineTextAlignment(.center)

                    Text(moment.title)
                        .font(AppTypography.title)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(moment.message)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: onReview) {
                    Label("Review Harmonica", systemImage: "star.fill")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(StudioControlButtonStyle(isProminent: true, tint: AppGradients.primary))
                .accessibilityIdentifier("reviewAppButton")

                Button("Not Now", action: onNotNow)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("reviewNotNowButton")
            }
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(AppColors.backgroundDeep.ignoresSafeArea())
        .accessibilityAddTraits(.isModal)
    }
}

private struct AddPracticeSongSheet: View {
    @Environment(\.dismiss) private var dismiss
    let libraryImportCount: Int
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
                    detail: "Choose downloaded, unprotected music owned by you. \(min(libraryImportCount, LibraryImportAllowance.freeSongCount)) of \(LibraryImportAllowance.freeSongCount) free imports used.",
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
