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

            let webView = WKWebView(
                frame: .zero,
                configuration: configuration
            )

            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.navigationDelegate = context.coordinator
            webView.allowsBackForwardNavigationGestures = true
            webView.scrollView.keyboardDismissMode = .interactive

            container.addSubview(webView)

            NSLayoutConstraint.activate([
                webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                webView.topAnchor.constraint(equalTo: container.topAnchor),
                webView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            context.coordinator.webView = webView

            let arguments = ProcessInfo.processInfo.arguments

            var debugURL: URL?

            if let index = arguments.firstIndex(of: "-debugURL"),
               arguments.indices.contains(index + 1) {
                debugURL = URL(string: arguments[index + 1])
            }

            let defaultURL: URL

            switch platform {
            case .instagram:
                defaultURL = URL(
                    string: "https://www.instagram.com/"
                )!

            case .youtube:
                defaultURL = URL(
                    string: "https://m.youtube.com/"
                )!
            }

            webView.load(
                URLRequest(
                    url: debugURL ?? defaultURL
                )
            )
        }

        return container
    }

    func updateUIView(
        _ uiView: UIView,
        context: Context
    ) {
        guard let webView = context.coordinator.webView else {
            return
        }

        let script = FilterScriptProvider.script(
            platform: platform,
            blockReels: blockReels,
            blockShorts: blockShorts,
            blockAds: blockAds
        )

        webView.evaluateJavaScript(
            script,
            completionHandler: nil
        )
    }

    final class Coordinator: NSObject, WKNavigationDelegate {

        weak var webView: WKWebView?

        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation!
        ) {
            let script = FilterScriptProvider.script(
                platform: inferPlatform(from: webView.url),
                blockReels: true,
                blockShorts: true,
                blockAds: false
            )

            webView.evaluateJavaScript(
                script,
                completionHandler: nil
            )
        }

        private func inferPlatform(
            from url: URL?
        ) -> SocialPlatform {

            if url?.host?.contains("instagram.com") == true {
                return .instagram
            }

            return .youtube
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
