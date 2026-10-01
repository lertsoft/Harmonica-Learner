import XCTest
@testable import Harmonica

@MainActor
final class SongLibraryTests: XCTestCase {
    func testDecodeSongsThrowsForInvalidJSON() {
        let invalid = Data("not valid json".utf8)

        XCTAssertThrowsError(try SongLibrary.decodeSongs(from: invalid))
    }
}
