import SwiftUI

@main
struct HarmonicaLearnerApp: App {
    init() {
        #if DEBUG
        UITestFixtures.seedIfRequested()
        #endif
    }

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
