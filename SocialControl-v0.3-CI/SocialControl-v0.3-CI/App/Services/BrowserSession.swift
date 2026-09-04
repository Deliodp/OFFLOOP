import WebKit

@MainActor
final class BrowserSession: ObservableObject {

    static let shared = BrowserSession()

    // Almacenamiento persistente en disco.
    // Cookies, localStorage, IndexedDB, etc. sobreviven al cierre de la app.
    let websiteDataStore: WKWebsiteDataStore = .default()

    // Compartimos el mismo proceso web entre los WebViews.
    private let processPool = WKProcessPool()

    private init() {}

    func makeConfiguration(
        platform: SocialPlatform,
        blockReels: Bool,
        blockShorts: Bool,
        blockAds: Bool
    ) async -> WKWebViewConfiguration {

        let configuration = WKWebViewConfiguration()

        // Persistencia real de sesión.
        configuration.websiteDataStore = websiteDataStore

        // Compartir sesión/proceso entre WebViews.
        configuration.processPool = processPool

        // JavaScript necesario para Instagram y YouTube.
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        // Reproducción de vídeo más natural.
        configuration.allowsInlineMediaPlayback = true

        // Evita requerir interacción extra para reproducción multimedia
        // cuando el sitio web permita autoplay.
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let controller = WKUserContentController()

        let filterScript = FilterScriptProvider.script(
            platform: platform,
            blockReels: blockReels,
            blockShorts: blockShorts,
            blockAds: blockAds
        )

        controller.addUserScript(
            WKUserScript(
                source: filterScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
        )

        // Premium: reglas específicas de publicidad de YouTube.
        if platform == .youtube && blockAds {
            await YouTubeAdBlocker.shared.attachContentRules(
                to: controller
            )
        }

        configuration.userContentController = controller

        return configuration
    }
}
