import StoreKitTest
import XCTest
@testable import Harmonica

final class FullAccessStoreTests: XCTestCase {
    @MainActor
    func testLocalPurchaseUnlocksAndRestoresEntitlement() async throws {
        let configurationURL = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "FullAccess", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: configurationURL)
        session.disableDialogs = true
        session.clearTransactions()
        defer { session.clearTransactions() }

        let store = FullAccessStore()
        await store.loadProduct()
        XCTAssertEqual(store.product?.id, FullAccessStore.productID)
        XCTAssertFalse(store.hasFullAccess)

        await store.purchase()
        XCTAssertTrue(store.hasFullAccess, store.errorMessage ?? "Purchase did not unlock full access")

        let restoredStore = FullAccessStore()
        await restoredStore.restore()
        XCTAssertTrue(restoredStore.hasFullAccess)
    }
}
