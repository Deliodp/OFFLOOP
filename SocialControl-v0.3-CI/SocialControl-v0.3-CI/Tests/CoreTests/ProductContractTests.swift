import XCTest
@testable import SocialControl

final class ProductContractTests: XCTestCase {

    func testLifetimeProductIdentifierExists() {
        XCTAssertFalse(PurchaseManager.lifetimeProductID.isEmpty)
    }

    func testCoreFeatureDefaultsAreRepresentable() {
        // This is intentionally simple: the real acceptance tests happen on device.
        XCTAssertNotEqual(SharedConfig.reelsKey, SharedConfig.shortsKey)
        XCTAssertNotEqual(SharedConfig.adsKey, SharedConfig.shortsKey)
    }
}
