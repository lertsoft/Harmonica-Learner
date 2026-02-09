import Foundation

enum SongLibrary {
    static func loadBundledSongs(bundle: Bundle = .main) -> [HarmonicaSong] {
        let url =
            bundle.url(forResource: "songs", withExtension: "json", subdirectory: "Songs") ??
            bundle.url(forResource: "songs", withExtension: "json")

        guard let url else {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try decodeSongs(from: data)
        } catch {
            return []
        }
    }

    static func decodeSongs(from data: Data) throws -> [HarmonicaSong] {
        try JSONDecoder().decode([HarmonicaSong].self, from: data)
    }
}
