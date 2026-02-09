import SwiftUI

struct ControlsView: View {
    let isAudioRunning: Bool
    @Binding var sensitivity: Double
    let attemptCount: Int

    let isFreestyleMode: Bool
    let isFreestyleRecording: Bool
    let canPlayFreestyleAudio: Bool
    let isFreestylePlayingAudio: Bool
    let isProgressionEnabled: Bool
    let isFreestyleSong: Bool
    let canRemoveFreestyleAudio: Bool

    let onStartStop: () -> Void
    let onNewAttempt: () -> Void
    let onNextNote: () -> Void
    let onToggleFreestyleRecording: () -> Void
    let onToggleFreestylePlayback: () -> Void
    let onRemoveFreestyleAudio: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Sensitivity")
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Text(String(format: "%.0f%%", normalizedSensitivity * 100))
                    .font(AppTypography.caption.monospacedDigit())
                    .foregroundStyle(AppColors.textSecondary)
            }

            Slider(value: $sensitivity, in: 0.005...0.2)
                .tint(AppColors.primaryGradientStart)

            HStack(spacing: 8) {
                preset(label: "Low", value: 0.02)
                preset(label: "Medium", value: 0.04)
                preset(label: "High", value: 0.08)

                Spacer()

                Text("Attempts \(attemptCount)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if isFreestyleMode {
                Button(action: onToggleFreestyleRecording) {
                    Text(isFreestyleRecording ? "Stop Recording" : "Record")
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(StudioControlButtonStyle(isProminent: true, tint: isFreestyleRecording ? AppGradients.miss : AppGradients.primary))

                if canPlayFreestyleAudio {
                    Button(action: onToggleFreestylePlayback) {
                        Text(isFreestylePlayingAudio ? "Stop Playback" : "Play Recording")
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                    }
                    .buttonStyle(StudioControlButtonStyle())
                }
            } else {
                Button(action: onStartStop) {
                    Text(isAudioRunning ? "Stop" : "Tap Start")
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(StudioControlButtonStyle(isProminent: true, tint: AppGradients.primary))

                HStack(spacing: 8) {
                    Button(action: onNewAttempt) {
                        Text("Retry")
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                    }
                    .buttonStyle(StudioControlButtonStyle())
                    .disabled(!isProgressionEnabled)

                    Button(action: onNextNote) {
                        Text("Skip")
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                    }
                    .buttonStyle(StudioControlButtonStyle())
                    .disabled(!isProgressionEnabled)
                }

                if isFreestyleSong {
                    if canRemoveFreestyleAudio {
                        Button(action: onRemoveFreestyleAudio) {
                            Text("Remove Background Audio")
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                        }
                        .buttonStyle(StudioControlButtonStyle())
                    } else {
                        Text("Notes-only session")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .liquidGlass(cornerRadius: 16, intensity: 0.03)
    }

    private func preset(label: String, value: Double) -> some View {
        let active = abs(sensitivity - value) < 0.01
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                sensitivity = value
            }
        } label: {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(active ? AppColors.textPrimary : AppColors.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(active ? AppColors.primaryGradientStart.opacity(0.24) : Color.white.opacity(0.06))
                )
        }
        .buttonStyle(.plain)
    }

    private var normalizedSensitivity: Double {
        (sensitivity - 0.005) / (0.2 - 0.005)
    }
}

struct StudioControlButtonStyle: ButtonStyle {
    var isProminent: Bool = false
    var tint: LinearGradient = AppGradients.brass

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodyStrong)
            .foregroundStyle(isProminent ? Color.white : AppColors.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isProminent ? AnyShapeStyle(tint) : AnyShapeStyle(Color.white.opacity(0.08)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        AppColors.backgroundDeep.ignoresSafeArea()
        ControlsView(
            isAudioRunning: false,
            sensitivity: .constant(0.04),
            attemptCount: 3,
            isFreestyleMode: true,
            isFreestyleRecording: false,
            canPlayFreestyleAudio: true,
            isFreestylePlayingAudio: false,
            isProgressionEnabled: true,
            isFreestyleSong: true,
            canRemoveFreestyleAudio: true,
            onStartStop: {},
            onNewAttempt: {},
            onNextNote: {},
            onToggleFreestyleRecording: {},
            onToggleFreestylePlayback: {},
            onRemoveFreestyleAudio: {}
        )
        .padding()
    }
}
