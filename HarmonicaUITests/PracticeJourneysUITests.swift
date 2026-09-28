import XCTest

final class PracticeJourneysUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFirstLaunchTourAndQuickStartReplay() {
        let app = launchApp(hasSeenOnboarding: false)

        XCTAssertTrue(app.staticTexts["Learn the breath pattern"].waitForExistence(timeout: 10))
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Listen, match, move"].exists)
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Build your practice library"].exists)
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Make practice your own"].exists)
        app.buttons["Explore Without Microphone"].tap()

        XCTAssertTrue(app.buttons["Practice setup"].waitForExistence(timeout: 5))
        app.buttons["Practice setup"].tap()
        app.buttons["Show Quick Start"].tap()
        XCTAssertTrue(app.staticTexts["Learn the breath pattern"].waitForExistence(timeout: 5))
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

    func testFifthMusicLibraryImportShowsPurchaseGate() {
        let app = launchApp(musicLibraryImportCount: 5)
        XCTAssertTrue(app.staticTexts["Keep the music going"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Restore Purchase"].exists)
        XCTAssertFalse(app.buttons["Practice library"].exists)
    }

    func testPracticeNavigationRemainsUsableAtAccessibilityTextSize() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenPracticeOnboarding", "YES",
            "-libraryImport.successfulCount", "0",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        let library = app.buttons["Practice library"]
        XCTAssertTrue(library.waitForExistence(timeout: 10))
        XCTAssertTrue(library.isHittable)
        library.tap()
        XCTAssertTrue(app.navigationBars["Practice Library"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        let setup = app.buttons["Practice setup"]
        XCTAssertTrue(setup.isHittable)
        setup.tap()
        XCTAssertTrue(app.navigationBars["Practice Setup"].waitForExistence(timeout: 5))
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

    private func launchApp(
        hasSeenOnboarding: Bool = true,
        musicLibraryImportCount: Int = 0,
        seedRecording: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenPracticeOnboarding", hasSeenOnboarding ? "YES" : "NO",
            "-libraryImport.successfulCount", String(musicLibraryImportCount)
        ]
        if seedRecording { app.launchArguments.append("-ui-test-seed-recording") }
        app.launch()
        return app
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
