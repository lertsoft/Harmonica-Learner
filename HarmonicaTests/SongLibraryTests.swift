import XCTest
@testable import Harmonica

final class SongLibraryTests: XCTestCase {
    func testDecodeSongsParsesValidJSON() throws {
        let json = """
        [
          {
            "songTitle": "Scale",
            "bpm": 90,
            "key": "C",
            "notes": [
              {"note": "C5", "duration": 0.5, "hole": "4B"}
            ]
          }
        ]
        """

        let songs = try SongLibrary.decodeSongs(from: Data(json.utf8))

        XCTAssertEqual(songs.count, 1)
        XCTAssertEqual(songs.first?.songTitle, "Scale")
        XCTAssertEqual(songs.first?.notes.first?.note, "C5")
    }

    func testDecodeSongsThrowsForInvalidJSON() {
        let invalid = Data("not valid json".utf8)

        XCTAssertThrowsError(try SongLibrary.decodeSongs(from: invalid))
    }

    func testLoadBundledSongsReturnsEmptyWhenResourceIsMissing() {
        let songs = SongLibrary.loadBundledSongs(bundle: Bundle(for: type(of: self)))

        XCTAssertEqual(songs, [])
    }
}
