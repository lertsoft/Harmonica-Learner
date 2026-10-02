import XCTest

@MainActor
final class PracticeJourneysUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testFirstLaunchTourAndQuickStartReplay() {
        let app = launchApp(hasSeenOnboarding: false)

        XCTAssertTrue(app.staticTexts["Pick your track"].waitForExistence(timeout: 10))
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Read harmonica tabs instantly"].waitForExistence(timeout: 5))
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Choose how you play"].waitForExistence(timeout: 5))
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Tap to listen & score"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Allow Mic & Start Playing"].waitForExistence(timeout: 5))
        app.buttons["onboardingSkipButton"].tap()

        XCTAssertTrue(app.buttons["Practice setup"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["reviewAppButton"].waitForExistence(timeout: 3))
        app.buttons["Practice setup"].tap()
        app.buttons["Show Quick Start"].tap()
        XCTAssertTrue(app.staticTexts["Pick your track"].waitForExistence(timeout: 5))
        app.buttons["onboardingSkipButton"].tap()
        XCTAssertFalse(app.buttons["reviewAppButton"].waitForExistence(timeout: 3))
    }

    func testCompletedSongOffersReviewOncePerVersion() {
        let app = launchApp(seedRecording: true)
        app.buttons["Practice library"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("UI Test Session")
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "UI Test Session")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["1/2"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["reviewAppButton"].exists)
        app.buttons["Skip"].tap()
        XCTAssertFalse(app.buttons["reviewAppButton"].exists)
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.staticTexts["Nice practice session"].waitForExistence(timeout: 5))
        app.buttons["reviewNotNowButton"].tap()
        app.buttons["Restart"].tap()
        app.buttons["Skip"].tap()
        app.buttons["Skip"].tap()
        XCTAssertFalse(app.buttons["reviewAppButton"].waitForExistence(timeout: 3))

        app.terminate()
        app.launchArguments = ["-hasSeenPracticeOnboarding", "YES", "-libraryImport.successfulCount", "0"]
        app.launch()
        XCTAssertTrue(app.buttons["Restart"].waitForExistence(timeout: 10))
        app.buttons["Restart"].tap()
        app.buttons["Skip"].tap()
        app.buttons["Skip"].tap()
        XCTAssertFalse(app.buttons["reviewAppButton"].waitForExistence(timeout: 3))
    }

    func testSavedFreestyleSessionOffersReview() {
        let app = launchApp()
        addUIInterruptionMonitor(withDescription: "Microphone access") { alert in
            guard alert.buttons["Allow"].exists else { return false }
            alert.buttons["Allow"].tap()
            return true
        }
        XCTAssertTrue(app.buttons["Freestyle"].waitForExistence(timeout: 10))
        app.buttons["Freestyle"].tap()
        XCTAssertFalse(app.buttons["reviewAppButton"].waitForExistence(timeout: 3))
        app.buttons["Record Freestyle"].tap()
        let stop = app.buttons["Stop & Save"]
        if !stop.waitForExistence(timeout: 2) { app.tap() }
        XCTAssertTrue(stop.waitForExistence(timeout: 10))
        let recordedLongEnough = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND label != %@ AND label != %@", "00:00", "00:01"),
            object: app.staticTexts["freestyleElapsedTime"]
        )
        XCTAssertEqual(XCTWaiter.wait(for: [recordedLongEnough], timeout: 5), .completed)
        stop.tap()
        XCTAssertTrue(app.staticTexts["Enjoying Freestyle?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["reviewAppButton"].exists)
        app.buttons["reviewNotNowButton"].tap()
    }

    func testMicrophoneGraphStartsPausesAndRestartsAfterReferencePlayback() {
        let app = launchApp()
        addUIInterruptionMonitor(withDescription: "Microphone access") { alert in
            guard alert.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "microphone")).firstMatch.exists,
                  alert.buttons["Allow"].exists else { return false }
            alert.buttons["Allow"].tap()
            return true
        }
        let start = app.buttons["Start Practice"]
        let pause = app.buttons["Pause Practice"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        start.tap()
        if !pause.waitForExistence(timeout: 2) { app.tap() }
        XCTAssertTrue(pause.waitForExistence(timeout: 10))
        pause.tap()
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        app.buttons["Hear target note"].tap()
        start.tap()
        XCTAssertTrue(pause.waitForExistence(timeout: 10))
        pause.tap()
        XCTAssertTrue(start.waitForExistence(timeout: 5))
    }

    func testLibrarySearchSelectionSkipAndRestart() {
        let app = launchApp()
        let library = app.buttons["Practice library"]
        XCTAssertTrue(library.waitForExistence(timeout: 10))
        library.tap()

        XCTAssertTrue(app.navigationBars["Practice Library"].waitForExistence(timeout: 5))
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("Twinkle")
        let song = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Twinkle Twinkle")).firstMatch
        XCTAssertTrue(song.waitForExistence(timeout: 5))
        song.tap()

        XCTAssertTrue(app.staticTexts["1/14"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Concert pitch C5"].exists)
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.staticTexts["2/14"].waitForExistence(timeout: 5))
        app.buttons["Restart"].tap()
        XCTAssertTrue(app.staticTexts["1/14"].waitForExistence(timeout: 5))
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.staticTexts["2/14"].waitForExistence(timeout: 5))

        library.tap()
        search.tap()
        search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 7) + "Mary")
        let mary = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Mary Had a Little Lamb")).firstMatch
        XCTAssertTrue(mary.waitForExistence(timeout: 5))
        mary.tap()
        XCTAssertTrue(app.staticTexts["1/13"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Concert pitch E5"].exists)
    }

    func testSetupAndModePersistAcrossRelaunch() {
        let app = launchApp()
        let setup = app.buttons["Practice setup"]
        XCTAssertTrue(setup.waitForExistence(timeout: 10))
        setup.tap()
        XCTAssertTrue(app.navigationBars["Practice Setup"].waitForExistence(timeout: 5))
        let tuning = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Tuning")).firstMatch
        XCTAssertTrue(tuning.waitForExistence(timeout: 5))
        tuning.tap()
        app.buttons["Lee Oskar"].tap()
        app.buttons["Done"].tap()

        app.buttons["Freestyle"].tap()
        XCTAssertTrue(app.buttons["Record Freestyle"].waitForExistence(timeout: 5))
        app.buttons["Practice library"].tap()
        let mary = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Mary Had a Little Lamb")).firstMatch
        XCTAssertTrue(mary.waitForExistence(timeout: 5))
        mary.tap()
        XCTAssertTrue(app.buttons["Start Practice"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1/13"].exists)

        app.terminate()
        app.launch()
        XCTAssertTrue(setup.waitForExistence(timeout: 10))
        setup.tap()
        XCTAssertTrue(app.staticTexts["Lee Oskar"].waitForExistence(timeout: 5))
    }

    func testAddSongShowsSourcesAndRejectsInvalidLink() {
        let app = launchApp()
        let library = app.buttons["Practice library"]
        XCTAssertTrue(library.waitForExistence(timeout: 10))
        library.tap()
        app.buttons["Add Song"].tap()

        XCTAssertTrue(app.navigationBars["Add Practice Song"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Audio File"].exists)
        XCTAssertTrue(app.staticTexts["Music Library"].exists)
        XCTAssertTrue(app.staticTexts["Record a Playing Song"].exists)
        let songLink = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Song Link")).firstMatch
        XCTAssertTrue(songLink.waitForExistence(timeout: 5))
        songLink.tap()

        let linkAlert = app.alerts["Paste Song Link"]
        XCTAssertTrue(linkAlert.waitForExistence(timeout: 5))
        let field = linkAlert.textFields.firstMatch
        field.tap()
        field.typeText("not-a-link")
        linkAlert.buttons["Analyze"].tap()
        XCTAssertTrue(app.alerts["Song Link"].waitForExistence(timeout: 5))
    }

    func testMainPracticeFitsWithoutScrollingOrBouncing() {
        let app = launchApp(extraLaunchArguments: ["-ui-test-seed-screen-fit-song"])
        XCTAssertTrue(app.staticTexts["1/1,405"].waitForExistence(timeout: 10))
        assertMainPracticeFits(in: app)
        let target = app.descendants(matching: .any).matching(identifier: "target-note-card").firstMatch
        let originalFrame = target.frame
        app.swipeUp()
        XCTAssertEqual(target.frame, originalFrame)
        app.swipeDown()
        XCTAssertEqual(target.frame, originalFrame)
        XCTAssertEqual(app.scrollViews.count, 0)
        attachScreen(app, name: "Fitted portrait practice")

        app.buttons["Freestyle"].tap()
        XCTAssertTrue(app.buttons["Record Freestyle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Record Freestyle"].isHittable)
        let freestyle = app.descendants(matching: .any).matching(identifier: "freestyle-live-card").firstMatch
        XCTAssertTrue(app.frame.contains(freestyle.frame))
        XCTAssertEqual(app.scrollViews.count, 0)
        app.buttons["Guided"].tap()
        XCTAssertTrue(app.buttons["Start Practice"].waitForExistence(timeout: 5))

        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        assertMainPracticeFits(in: app)
        attachScreen(app, name: "Fitted landscape practice")
    }

    func testPracticeControlsRemainReachableInLandscape() {
        let app = launchApp()
        assertPracticeColumns(in: app)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }

        let library = app.buttons["Practice library"]
        XCTAssertTrue(library.waitForExistence(timeout: 10))
        XCTAssertTrue(library.isHittable)
        XCTAssertTrue(app.buttons["Practice setup"].isHittable)
        XCTAssertTrue(app.buttons["Start Practice"].isHittable)
        assertPracticeColumns(in: app)
        library.tap()
        XCTAssertTrue(app.navigationBars["Practice Library"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
    }

    func testOnboardingCalloutAvoidsTargetInLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }

        let app = launchApp(
            hasSeenOnboarding: false,
            extraLaunchArguments: ["-ui-test-onboarding-layout-probes"]
        )
        XCTAssertTrue(app.staticTexts["Pick your track"].waitForExistence(timeout: 10))
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Read harmonica tabs instantly"].waitForExistence(timeout: 5))

        let target = app.descendants(matching: .any).matching(identifier: "onboarding-highlight-frame").firstMatch
        let callout = app.descendants(matching: .any).matching(identifier: "onboarding-callout-frame").firstMatch
        XCTAssertTrue(target.waitForExistence(timeout: 5))
        XCTAssertTrue(callout.waitForExistence(timeout: 5))
        XCTAssertFalse(callout.frame.intersects(target.frame))
    }

    func testOnboardingCardsFitWithoutScrolling() {
        defer { XCUIDevice.shared.orientation = .portrait }
        let steps: [(title: String, details: [String])] = [
            ("Pick your track", ["Built-In Classics", "Bring Your Own Audio",
                "Curated starter songs and beginner melodies ready to play",
                "Import audio from Files or Music Library, record a song, or paste a supported song link"]),
            ("Read harmonica tabs instantly", ["Exhale out", "Inhale in",
                "Target hole turns emerald green when your pitch matches!"]),
            ("Choose how you play", ["Guided Mode", "Freestyle Jam",
                "Note-by-note interactive sheet tabs with live pitch detection & auto-scroll",
                "Play anything freely; the app listens and auto-transcribes your tabs live"]),
            ("Tap to listen & score", ["Real-Time Pitch Detection", "100% On-Device & Private",
                "Live pitch feedback helps you match the target note and its blow or draw hole",
                "Microphone audio never leaves your phone. Zero cloud processing."])
        ]
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            let app = launchApp(hasSeenOnboarding: false)
            for (index, step) in steps.enumerated() {
                let title = app.staticTexts[step.title]
                XCTAssertTrue(title.waitForExistence(timeout: 10))
                let callout = app.descendants(matching: .any)
                    .matching(identifier: "onboarding-callout").firstMatch
                XCTAssertTrue(callout.exists)
                XCTAssertEqual(app.scrollViews.count, 0)
                for label in [step.title] + step.details {
                    let text = app.staticTexts[label]
                    XCTAssertTrue(text.isHittable, label)
                    XCTAssertTrue(callout.frame.contains(text.frame),
                        "\(label): \(text.frame) outside \(callout.frame)")
                }
                let action = app.buttons[index == steps.count - 1 ? "Allow Mic & Start Playing" : "Next"]
                XCTAssertTrue(action.isHittable)
                XCTAssertTrue(callout.frame.contains(action.frame))
                let originalFrame = title.frame
                title.swipeUp()
                XCTAssertEqual(title.frame, originalFrame)
                title.swipeDown()
                XCTAssertEqual(title.frame, originalFrame)
                attachScreen(app, name: "Fixed onboarding step \(index + 1) \(orientation.rawValue)")
                if index < steps.count - 1 { action.tap() }
            }
            app.terminate()
        }
    }

    func testFifthMusicLibraryImportShowsPurchaseGate() {
        let app = launchApp(musicLibraryImportCount: 5)
        XCTAssertTrue(app.staticTexts["Keep the music going"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Restore Purchase"].exists)
        XCTAssertFalse(app.buttons["Practice library"].exists)
    }

    func testPracticeNavigationRemainsUsableAtAccessibilityTextSize() {
        let app = launchApp(extraLaunchArguments: ["-ui-test-seed-screen-fit-song"])
        let normalTitleHeight = app.staticTexts["Harmonica Practice"].frame.height
        app.terminate()
        app.launchArguments = [
            "-hasSeenPracticeOnboarding", "YES",
            "-libraryImport.successfulCount", "0",
            "-ui-test-seed-screen-fit-song",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        let library = app.buttons["Practice library"]
        XCTAssertTrue(library.waitForExistence(timeout: 10))
        XCTAssertTrue(library.isHittable)
        XCTAssertGreaterThan(app.staticTexts["Harmonica Practice"].frame.height, normalTitleHeight * 1.5)
        XCTAssertTrue(app.scrollViews["accessible-practice-content"].exists)
        XCTAssertTrue(app.buttons["Start Practice"].isHittable)
        attachScreen(app, name: "Scrollable accessibility practice")
        library.tap()
        XCTAssertTrue(app.navigationBars["Practice Library"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        let setup = app.buttons["Practice setup"]
        XCTAssertTrue(setup.isHittable)
        setup.tap()
        XCTAssertTrue(app.navigationBars["Practice Setup"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        let dashboard = app.scrollViews["accessible-practice-content"]
        let skip = app.buttons["Skip"]
        for _ in 0..<8 {
            if skip.isHittable { break }
            dashboard.swipeUp()
        }
        XCTAssertTrue(skip.isHittable)
        XCTAssertTrue(app.buttons["Hear target note"].isHittable)
        skip.tap()
        XCTAssertTrue(app.staticTexts["Concert pitch D4"].exists)
        let details = app.buttons["arrangement-details-button"]
        for _ in 0..<8 {
            if details.isHittable { break }
            dashboard.swipeUp()
        }
        XCTAssertTrue(details.isHittable)
        XCTAssertTrue(app.buttons["Start Practice"].isHittable)
        attachScreen(app, name: "Readable accessibility progress")
        details.tap()
        XCTAssertTrue(app.staticTexts["arrangement-explanation"].waitForExistence(timeout: 5))
        attachScreen(app, name: "Accessible arrangement details")
    }

    func testOnboardingRemainsUsableAtAccessibilityTextSize() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenPracticeOnboarding", "NO",
            "-libraryImport.successfulCount", "0",
            "-ui-test-reset-review-prompts",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Pick your track"].waitForExistence(timeout: 10))
        let title = app.staticTexts["Pick your track"]
        XCTAssertGreaterThan(title.frame.height, 40)
        let imports = app.staticTexts["Bring Your Own Audio"]
        for _ in 0..<6 {
            if imports.isHittable { break }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(imports.isHittable)
        XCTAssertTrue(app.buttons["Next"].isHittable)
        attachScreen(app, name: "Readable accessibility onboarding")
        for title in ["Read harmonica tabs instantly", "Choose how you play", "Tap to listen & score"] {
            let next = app.buttons["Next"]
            XCTAssertTrue(next.isHittable)
            next.tap()
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5))
        }
        XCTAssertTrue(app.buttons["onboardingSkipButton"].isHittable)
        app.buttons["onboardingSkipButton"].tap()
        XCTAssertTrue(app.buttons["Practice setup"].waitForExistence(timeout: 5))
    }

    func testArrangementDetailsPersistAcrossRelaunch() {
        let app = launchApp(extraLaunchArguments: ["-ui-test-seed-screen-fit-song"])
        for launch in 0..<2 {
            let details = app.buttons["arrangement-details-button"]
            XCTAssertTrue(details.waitForExistence(timeout: 10))
            XCTAssertTrue(details.isHittable)
            details.tap()
            let explanation = app.staticTexts["arrangement-explanation"]
            XCTAssertTrue(explanation.waitForExistence(timeout: 5))
            XCTAssertTrue(explanation.label.contains("Approximate arrangement"))
            XCTAssertTrue(explanation.label.contains("Transposed -5 semitones"))
            XCTAssertTrue(explanation.label.contains("Register +2 octaves"))
            app.buttons["Done"].tap()
            if launch == 0 {
                app.terminate()
                app.launchArguments = ["-hasSeenPracticeOnboarding", "YES", "-libraryImport.successfulCount", "0"]
                app.launch()
            }
        }
    }

    func testSavedSongCanBePracticedRenamedAndDeletedAcrossLaunches() {
        let app = launchApp(seedRecording: true)
        let library = app.buttons["Practice library"]
        XCTAssertTrue(library.waitForExistence(timeout: 10))
        library.tap()
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("UI Test Session")
        let original = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "UI Test Session")).firstMatch
        XCTAssertTrue(original.waitForExistence(timeout: 5))
        original.tap()
        XCTAssertTrue(app.staticTexts["1/2"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Concert pitch C5"].exists)

        library.tap()
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "UI Test Session")).firstMatch
        row.swipeLeft()
        app.buttons["Rename"].tap()
        let rename = app.alerts["Rename Saved Song"]
        XCTAssertTrue(rename.waitForExistence(timeout: 5))
        let field = rename.textFields.firstMatch
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "UI Test Session".count) + "New Session")
        rename.buttons["Save"].tap()

        app.terminate()
        app.launchArguments = ["-hasSeenPracticeOnboarding", "YES", "-libraryImport.successfulCount", "0"]
        app.launch()
        XCTAssertTrue(library.waitForExistence(timeout: 10))
        library.tap()
        let renamedSearch = app.searchFields.firstMatch
        renamedSearch.tap()
        renamedSearch.typeText("New Session")
        let renamed = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "New Session")).firstMatch
        XCTAssertTrue(renamed.waitForExistence(timeout: 5))
        renamed.tap()
        XCTAssertTrue(app.staticTexts["1/2"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Concert pitch C5"].exists)
        library.tap()
        renamed.swipeLeft()
        app.buttons["Delete"].tap()
        let confirm = app.buttons["Delete"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()

        app.terminate()
        app.launch()
        XCTAssertTrue(library.waitForExistence(timeout: 10))
        library.tap()
        let finalSearch = app.searchFields.firstMatch
        finalSearch.tap()
        finalSearch.typeText("New Session")
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "New Session")).firstMatch.exists)
    }

    func testImportedChordCanBePracticedPreviewedAndReopened() {
        let app = launchApp(extraLaunchArguments: ["-ui-test-import-chord"])
        let context = app.staticTexts["source-chord-context"]
        XCTAssertTrue(context.waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["Your song is ready"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["reviewAppButton"].exists)
        app.buttons["reviewNotNowButton"].tap()
        XCTAssertTrue(context.label.contains("C5 · E5 · G5"))
        XCTAssertTrue(app.staticTexts["Concert pitch C5"].exists)
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.staticTexts["Concert pitch E5"].waitForExistence(timeout: 5))
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.staticTexts["Concert pitch G5"].waitForExistence(timeout: 5))
        app.buttons["Playback options"].tap()
        app.buttons["Hear Harmonica Cover"].tap()
        app.buttons["Playback options"].tap()
        XCTAssertTrue(app.buttons["Stop Harmonica Cover"].waitForExistence(timeout: 5))
        app.buttons["Stop Harmonica Cover"].tap()
        app.buttons["Playback options"].tap()
        XCTAssertTrue(app.buttons["Hear Harmonica Cover"].waitForExistence(timeout: 5))
        app.buttons["Hear Imported Source"].tap()
        app.terminate()
        app.launchArguments = ["-hasSeenPracticeOnboarding", "YES", "-libraryImport.successfulCount", "0"]
        app.launch()
        XCTAssertTrue(app.buttons["Practice library"].waitForExistence(timeout: 10))
        app.buttons["Practice library"].tap()
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("UI Chord Arrangement")
        let song = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "UI Chord Arrangement")).firstMatch
        XCTAssertTrue(song.waitForExistence(timeout: 5))
        song.tap()
        XCTAssertTrue(context.waitForExistence(timeout: 5))
        XCTAssertTrue(context.label.contains("C5 · E5 · G5"))
    }

    private func launchApp(
        hasSeenOnboarding: Bool = true,
        musicLibraryImportCount: Int = 0,
        seedRecording: Bool = false,
        extraLaunchArguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenPracticeOnboarding", hasSeenOnboarding ? "YES" : "NO",
            "-libraryImport.successfulCount", String(musicLibraryImportCount),
            "-ui-test-reset-review-prompts"
        ]
        if seedRecording { app.launchArguments.append("-ui-test-seed-recording") }
        app.launchArguments.append(contentsOf: extraLaunchArguments)
        app.launch()
        return app
    }

    private func assertMainPracticeFits(in app: XCUIApplication) {
        let viewport = app.frame.insetBy(dx: 0, dy: 1)
        let target = app.descendants(matching: .any).matching(identifier: "target-note-card").firstMatch
        let progress = app.descendants(matching: .any).matching(identifier: "progress-track").firstMatch
        let controls = app.descendants(matching: .any).matching(identifier: "practice-controls").firstMatch
        for id in ["practice-header", "target-note-card", "progress-track", "practice-controls", "harmonica-comb"] {
            let element = app.descendants(matching: .any).matching(identifier: id).firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: 5), id)
            XCTAssertTrue(viewport.contains(element.frame), "\(id): \(element.frame) outside \(viewport)")
        }
        XCTAssertLessThanOrEqual(target.frame.maxY, controls.frame.minY)
        XCTAssertLessThanOrEqual(progress.frame.maxY, controls.frame.minY)
        for title in ["Practice library", "Practice setup", "Restart", "Skip", "Hear target note", "Start Practice"] {
            XCTAssertTrue(app.buttons[title].isHittable, title)
            XCTAssertTrue(viewport.contains(app.buttons[title].frame), title)
        }
        XCTAssertFalse(app.staticTexts["Start practice when you’re ready."].exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Approximate arrangement")).firstMatch.exists)
        XCTAssertEqual(app.scrollViews.count, 0)
        let source = app.staticTexts["source-chord-context"]
        if source.exists {
            XCTAssertTrue(target.frame.contains(source.frame))
        }
        let comb = app.descendants(matching: .any).matching(identifier: "harmonica-comb").firstMatch
        XCTAssertTrue(target.frame.contains(comb.frame))
    }

    private func attachScreen(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func assertPracticeColumns(in app: XCUIApplication) {
        let target = app.descendants(matching: .any).matching(identifier: "target-note-card").firstMatch
        let progress = app.descendants(matching: .any).matching(identifier: "progress-track").firstMatch
        XCTAssertTrue(target.waitForExistence(timeout: 5))
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        if app.frame.width >= 700 {
            XCTAssertGreaterThan(progress.frame.minX, target.frame.maxX - 5)
        } else {
            XCTAssertGreaterThan(progress.frame.minY, target.frame.maxY - 5)
        }
    }
}
