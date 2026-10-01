import AVFoundation

enum AppAudioSession {
    private static let configurationQueue = DispatchQueue(
        label: "com.kosukobo.Harmonica.audio-session",
        qos: .userInitiated
    )

    /// System pickers, exports, route changes, and interruptions can change or deactivate
    /// the shared session. Restore the app's expected configuration at every audio entry point.
    static func activate(configureInput: Bool = false) async throws {
        try await withCheckedThrowingContinuation { continuation in
            configurationQueue.async {
                do {
                    let session = AVAudioSession.sharedInstance()
                    if session.category != .playAndRecord
                        || session.mode != .measurement
                        || !session.categoryOptions.contains(.defaultToSpeaker) {
                        try session.setCategory(
                            .playAndRecord,
                            mode: .measurement,
                            options: [.defaultToSpeaker]
                        )
                    }

                    if configureInput {
                        _ = try? session.setPreferredInputNumberOfChannels(1)
                        _ = try? session.setPreferredOutputNumberOfChannels(2)
                        _ = try? session.setPreferredSampleRate(48_000)
                        _ = try? session.setPreferredIOBufferDuration(0.01)
                    }

                    try session.setActive(true)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
