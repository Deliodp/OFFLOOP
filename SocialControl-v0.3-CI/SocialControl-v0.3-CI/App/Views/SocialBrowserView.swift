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
        Coordinator(
            platform: platform,
            blockReels: blockReels,
            blockShorts: blockShorts,
            blockAds: blockAds
        )
    }

    func makeUIView(context: Context) -> UIView {

        let container = UIView()
        container.backgroundColor = .systemBackground

        Task { @MainActor in

            let configuration =
                await BrowserSession.shared.makeConfiguration(
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
                webView.leadingAnchor.constraint(
                    equalTo: container.leadingAnchor
                ),
                webView.trailingAnchor.constraint(
                    equalTo: container.trailingAnchor
                ),
                webView.topAnchor.constraint(
                    equalTo: container.topAnchor
                ),
                webView.bottomAnchor.constraint(
                    equalTo: container.bottomAnchor
                )
            ])

            context.coordinator.webView = webView

            let arguments =
                ProcessInfo.processInfo.arguments

            var debugURL: URL?

            if let index =
                arguments.firstIndex(of: "-debugURL"),
               arguments.indices.contains(index + 1) {

                debugURL =
                    URL(string: arguments[index + 1])
            }

            let defaultURL: URL

            switch platform {

            case .instagram:

                defaultURL =
                    URL(
                        string:
                            "https://www.instagram.com/"
                    )!

            case .youtube:

                defaultURL =
                    URL(
                        string:
                            "https://m.youtube.com/"
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

        context.coordinator.updateSettings(
            platform: platform,
            blockReels: blockReels,
            blockShorts: blockShorts,
            blockAds: blockAds
        )

        guard let webView =
                context.coordinator.webView
        else {
            return
        }

        let script =
            FilterScriptProvider.script(
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

    final class Coordinator:
        NSObject,
        WKNavigationDelegate {

        weak var webView: WKWebView?

        private var platform: SocialPlatform
        private var blockReels: Bool
        private var blockShorts: Bool
        private var blockAds: Bool

        init(
            platform: SocialPlatform,
            blockReels: Bool,
            blockShorts: Bool,
            blockAds: Bool
        ) {

            self.platform = platform
            self.blockReels = blockReels
            self.blockShorts = blockShorts
            self.blockAds = blockAds
        }

        func updateSettings(
            platform: SocialPlatform,
            blockReels: Bool,
            blockShorts: Bool,
            blockAds: Bool
        ) {

            self.platform = platform
            self.blockReels = blockReels
            self.blockShorts = blockShorts
            self.blockAds = blockAds
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction:
                WKNavigationAction,
            decisionHandler:
                @escaping (WKNavigationActionPolicy) -> Void
        ) {

            guard let url =
                    navigationAction.request.url
            else {

                decisionHandler(.allow)
                return
            }

            let host =
                url.host?.lowercased() ?? ""

            let path =
                url.path.lowercased()

            // ----------------------------------
            // INSTAGRAM REELS
            // ----------------------------------

            if (
                blockReels &&
                host.contains("instagram.com") &&
                (
                    path.hasPrefix("/reel/") ||
                    path.hasPrefix("/reels")
                )
            ) {

                decisionHandler(.cancel)

                let safeURL =
                    URL(
                        string:
                            "https://www.instagram.com/"
                    )!

                DispatchQueue.main.async {

                    webView.load(
                        URLRequest(
                            url: safeURL
                        )
                    )
                }

                return
            }

            // ----------------------------------
            // YOUTUBE SHORTS
            // ----------------------------------

            if (
                blockShorts &&
                host.contains("youtube.com") &&
                (
                    path == "/shorts" ||
                    path == "/shorts/" ||
                    path.hasPrefix("/shorts/")
                )
            ) {

                decisionHandler(.cancel)

                let safeURL =
                    URL(
                        string:
                            "https://m.youtube.com/"
                    )!

                DispatchQueue.main.async {

                    webView.load(
                        URLRequest(
                            url: safeURL
                        )
                    )
                }

                return
            }

            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation!
        ) {

            let script =
                FilterScriptProvider.script(
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
    }
}
