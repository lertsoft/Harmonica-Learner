import Foundation

struct LibraryImportAllowance {
    static let freeSongCount = 5
    static let storageKey = "libraryImport.successfulCount"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func count(existingLibrarySongs: Int) -> Int {
        let count = max(defaults.integer(forKey: Self.storageKey), existingLibrarySongs)
        if count > defaults.integer(forKey: Self.storageKey) {
            defaults.set(count, forKey: Self.storageKey)
        }
        return count
    }

    @discardableResult
    func recordSuccessfulImport(existingLibrarySongs: Int) -> Int {
        let newCount = count(existingLibrarySongs: existingLibrarySongs) + 1
        defaults.set(newCount, forKey: Self.storageKey)
        return newCount
    }
}
