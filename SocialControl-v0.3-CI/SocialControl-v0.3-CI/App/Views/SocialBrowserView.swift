import SwiftUI
import WebKit

struct SocialBrowserView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var purchaseManager: PurchaseManager

    let platform: SocialPlatform

    var body: some View {
        BrowserWebView(
            platform: platform,
            blockReels: appState.blockInstagramReels,
            blockShorts: appState.blockYouTubeShorts,
            blockAds: purchaseManager.hasPremium && appState.blockYouTubeAds
        )
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle(platform == .instagram ? "Instagram" : "YouTube")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct BrowserWebView: UIViewRepresentable {
    let platform: SocialPlatform
    let blockReels: Bool
    let blockShorts: Bool
    let blockAds: Bool

    func makeUIView(context: Context) -> WKWebView {
        // A temporary view is returned immediately; the persistent configuration
        // is applied once created below.
        let view = WKWebView(frame: .zero)
        Task { @MainActor in
            let configuration = await BrowserSession.shared.makeConfiguration(
                platform: platform,
                blockReels: blockReels,
                blockShorts: blockShorts,
                blockAds: blockAds
            )

            let configured = WKWebView(frame: view.bounds, configuration: configuration)
            configured.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            configured.navigationDelegate = context.coordinator
            configured.allowsBackForwardNavigationGestures = true
            configured.scrollView.keyboardDismissMode = .interactive

            view.addSubview(configured)
            context.coordinator.webView = configured

            let url = platform == .instagram
                ? URL(string: "https://www.instagram.com/")!
                : URL(string: "https://www.youtube.com/")!

            configured.load(URLRequest(url: url))
        }

        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let webView = context.coordinator.webView else { return }

        let script = FilterScriptProvider.script(
            platform: platform,
            blockReels: blockReels,
            blockShorts: blockShorts,
            blockAds: blockAds
        )

        webView.evaluateJavaScript(script)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Persistent cookies/local storage are handled by WKWebsiteDataStore.default().
        }
    }
}
