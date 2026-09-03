import XCTest
@testable import SocialControl

final class SharedConfigTests: XCTestCase {

    func testCoreKeysAreStableAndDistinct() {
        let keys = [
            SharedConfig.reelsKey,
            SharedConfig.shortsKey,
            SharedConfig.adsKey,
            SharedConfig.selectedAppsKey
        ]

        XCTAssertEqual(Set(keys).count, keys.count)
    }

    func testAppGroupIsNotEmpty() {
        XCTAssertFalse(SharedConfig.appGroup.isEmpty)
    }
}
