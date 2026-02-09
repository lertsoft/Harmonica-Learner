import SwiftUI

@main
struct HarmonicaLearnerApp: App {
    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    var body: some Scene {
        WindowGroup {
            if isRunningTests {
                Color.clear
            } else {
                ContentView()
            }
        }
    }
}
