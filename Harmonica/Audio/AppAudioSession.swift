import AVFoundation

enum AppAudioSession {
    /// System pickers, exports, route changes, and interruptions can change or deactivate
    /// the shared session. Restore the app's expected configuration at every audio entry point.
    static func activate() throws {
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
        try session.setActive(true)
    }
}
