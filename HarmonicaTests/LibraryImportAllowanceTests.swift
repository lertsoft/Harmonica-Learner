import XCTest
@testable import Harmonica

@MainActor
final class LibraryImportAllowanceTests: XCTestCase {
    func testCountsOnlySuccessfulImportsAndPreservesLimitAfterDeletion() throws {
        let suite = "LibraryImportAllowanceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let allowance = LibraryImportAllowance(defaults: defaults)

        XCTAssertEqual(allowance.count(existingLibrarySongs: 0), 0)
        for previousCount in 0..<LibraryImportAllowance.freeSongCount {
            XCTAssertEqual(
                allowance.recordSuccessfulImport(existingLibrarySongs: previousCount),
                previousCount + 1
            )
        }
        XCTAssertEqual(allowance.count(existingLibrarySongs: 0), 5)
        XCTAssertEqual(LibraryImportAllowance(defaults: defaults).count(existingLibrarySongs: 1), 5)
    }

    func testExistingLibrarySongsSeedAllowanceWhenUpgrading() throws {
        let suite = "LibraryImportAllowanceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let allowance = LibraryImportAllowance(defaults: defaults)
        XCTAssertEqual(allowance.count(existingLibrarySongs: 5), 5)
        XCTAssertEqual(allowance.count(existingLibrarySongs: 2), 5)
    }
}
