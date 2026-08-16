import SwiftUI

struct ControlsView: View {
    let isAudioRunning: Bool
    let isFreestyleMode: Bool
    let isFreestyleRecording: Bool
    let canPlayFreestyleAudio: Bool
    let isFreestylePlayingAudio: Bool
    let isFreestyleSong: Bool
    let isImportedSong: Bool
    let canPlaySynthesizedCover: Bool
    let isSynthesizedCoverPlaying: Bool
    let onPrimaryAction: () -> Void
    let onShowSettings: () -> Void
    let onToggleFreestylePlayback: () -> Void
    let onRemoveFreestyleAudio: () -> Void
    let onToggleSynthesizedCover: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onShowSettings) {
                Image(systemName: "gearshape.fill")
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(StudioControlButtonStyle())
            .accessibilityLabel("Audio settings")

            Button(action: onPrimaryAction) {
                Label(primaryTitle, systemImage: primaryIcon)
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(StudioControlButtonStyle(isProminent: true, tint: primaryTint))

            if !isFreestyleMode && (isFreestyleSong || canPlaySynthesizedCover) {
                Menu {
                    if canPlaySynthesizedCover {
                        Button(action: onToggleSynthesizedCover) {
                            Label(
                                isSynthesizedCoverPlaying ? "Stop Harmonica Cover" : "Hear Harmonica Cover",
                                systemImage: isSynthesizedCoverPlaying ? "stop.fill" : "music.note.list"
                            )
                        }
                    }
                    if canPlayFreestyleAudio {
                        Button(action: onToggleFreestylePlayback) {
                            Label(isFreestylePlayingAudio ? "Stop Source Audio" : sourceAudioTitle,
                                  systemImage: isFreestylePlayingAudio ? "stop.fill" : "speaker.wave.2.fill")
                        }
                    }
                    if isFreestyleSong && canPlayFreestyleAudio {
                        Button(role: .destructive, action: onRemoveFreestyleAudio) {
                            Label("Remove Stored Audio", systemImage: "speaker.slash.fill")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(StudioControlButtonStyle())
                .accessibilityLabel("More recording controls")
            }
        }
        .padding(10)
        .liquidGlass(cornerRadius: 18, intensity: 0.04)
    }

    private var sourceAudioTitle: String {
        isImportedSong ? "Hear Imported Source" : "Hear Saved Recording"
    }

    private var primaryTitle: String {
        if isFreestyleMode { return isFreestyleRecording ? "Stop & Save" : "Record Freestyle" }
        return isAudioRunning ? "Pause Practice" : "Start Practice"
    }

    private var primaryIcon: String {
        if isFreestyleMode { return isFreestyleRecording ? "stop.fill" : "record.circle" }
        return isAudioRunning ? "pause.fill" : "mic.fill"
    }

    private var primaryTint: LinearGradient {
        isFreestyleMode && isFreestyleRecording ? AppGradients.miss : AppGradients.primary
    }
}

struct StudioControlButtonStyle: ButtonStyle {
    var isProminent: Bool = false
    var tint: LinearGradient = AppGradients.brass

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodyStrong)
            .foregroundStyle(isProminent ? Color.white : AppColors.textPrimary)
            .background(RoundedRectangle(cornerRadius: 14).fill(isProminent ? AnyShapeStyle(tint) : AnyShapeStyle(Color.white.opacity(0.08))))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        AppColors.backgroundDeep.ignoresSafeArea()
        ControlsView(isAudioRunning: false, isFreestyleMode: false, isFreestyleRecording: false,
                     canPlayFreestyleAudio: false, isFreestylePlayingAudio: false, isFreestyleSong: false,
                     isImportedSong: false, canPlaySynthesizedCover: true, isSynthesizedCoverPlaying: false,
                     onPrimaryAction: {}, onShowSettings: {}, onToggleFreestylePlayback: {},
                     onRemoveFreestyleAudio: {}, onToggleSynthesizedCover: {})
            .padding()
    }
}
