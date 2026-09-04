import SwiftUI
import WebKit

struct SocialBrowserView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var purchaseManager: PurchaseManager

    let platform: SocialPlatform

    var body: some View {
        PersistentSocialWebView(
            platform: platform,
            blockReels: appState.blockInstagramReels,
            blockShorts: appState.blockYouTubeShorts,
            blockAds: purchaseManager.hasPremium && appState.blockYouTubeAds
        )
        .background(Color.white)
        .navigationTitle(platform == .instagram ? "Instagram" : "YouTube")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PersistentSocialWebView: UIViewRepresentable {
    let platform: SocialPlatform
    let blockReels: Bool
    let blockShorts: Bool
    let blockAds: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground

        Task { @MainActor in
            let configuration = await BrowserSession.shared.makeConfiguration(
                platform: platform,
                blockReels: blockReels,
                blockShorts: blockShorts,
                blockAds: blockAds
            )

            let webView = WKWebView(frame: .zero, configuration: configuration)
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.navigationDelegate = context.coordinator
            webView.allowsBackForwardNavigationGestures = true
            webView.scrollView.keyboardDismissMode = .interactive

            // Keep normal mobile website behavior.
            webView.customUserAgent = nil

            container.addSubview(webView)

            NSLayoutConstraint.activate([
                webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                webView.topAnchor.constraint(equalTo: container.topAnchor),
                webView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            context.coordinator.webView = webView

            let url: URL
            switch platform {
            case .instagram:
                url = URL(string: "https://www.instagram.com/")!
            case .youtube:
                url = URL(string: "https://m.youtube.com/")!
            }

            webView.load(URLRequest(url: url))
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let webView = context.coordinator.webView else { return }

        let script = FilterScriptProvider.script(
            platform: platform,
            blockReels: blockReels,
            blockShorts: blockShorts,
            blockAds: blockAds
        )

        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Session cookies and local storage use WKWebsiteDataStore.default()
            // from BrowserSession, so they persist across launches.
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(.allow)
        }
    }
}
