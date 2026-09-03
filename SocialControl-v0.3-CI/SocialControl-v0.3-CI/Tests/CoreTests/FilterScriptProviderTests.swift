import XCTest
@testable import SocialControl

final class FilterScriptProviderTests: XCTestCase {

    func testInstagramScriptContainsReelsRouteProtection() {
        let script = FilterScriptProvider.script(
            platform: .instagram,
            blockReels: true,
            blockShorts: false,
            blockAds: false
        )

        XCTAssertTrue(script.contains("/reel/"))
        XCTAssertTrue(script.contains("/reels"))
        XCTAssertTrue(script.contains("instagram.com"))
    }

    func testYouTubeScriptContainsShortsRouteProtection() {
        let script = FilterScriptProvider.script(
            platform: .youtube,
            blockReels: false,
            blockShorts: true,
            blockAds: false
        )

        XCTAssertTrue(script.contains("/shorts"))
        XCTAssertTrue(script.contains("youtube.com"))
    }

    func testAdCleanupOnlyIncludedWhenEnabledInConfiguration() {
        let enabled = FilterScriptProvider.script(
            platform: .youtube,
            blockReels: false,
            blockShorts: false,
            blockAds: true
        )

        let disabled = FilterScriptProvider.script(
            platform: .youtube,
            blockReels: false,
            blockShorts: false,
            blockAds: false
        )

        XCTAssertTrue(enabled.contains("ads: true"))
        XCTAssertTrue(disabled.contains("ads: false"))
    }

    func testFilterScriptNeverContainsBroadGoogleVideoBlock() {
        let script = FilterScriptProvider.script(
            platform: .youtube,
            blockReels: true,
            blockShorts: true,
            blockAds: true
        )

        XCTAssertFalse(script.contains("googlevideo.com"))
    }
}
