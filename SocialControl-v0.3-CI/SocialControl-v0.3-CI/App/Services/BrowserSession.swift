import WebKit

@MainActor
final class BrowserSession: ObservableObject {
    static let shared = BrowserSession()

    // Persistent on-disk data store. Cookies and local storage survive relaunches.
    let websiteDataStore: WKWebsiteDataStore = .default()

    private init() {}

    func makeConfiguration(
        platform: SocialPlatform,
        blockReels: Bool,
        blockShorts: Bool,
        blockAds: Bool
    ) async -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = websiteDataStore
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let controller = WKUserContentController()
        let script = FilterScriptProvider.script(
            platform: platform,
            blockReels: blockReels,
            blockShorts: blockShorts,
            blockAds: blockAds
        )

        controller.addUserScript(
            WKUserScript(
                source: script,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
        )

        configuration.userContentController = controller

        if platform == .youtube && blockAds {
            await YouTubeAdBlocker.shared.attachContentRules(to: controller)
        }

        return configuration
    }
}
