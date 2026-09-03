import WebKit

@MainActor
final class YouTubeAdBlocker {
    static let shared = YouTubeAdBlocker()

    private let identifier = "SocialControlYouTubeAdsV1"

    // Conservative first-pass rules. Intentionally avoids broad googlevideo blocking,
    // which can break normal video playback.
    private let rulesJSON = """
    [
      {
        "trigger": {
          "url-filter": ".*doubleclick\\\\.net.*",
          "resource-type": ["script","image","style-sheet","raw"]
        },
        "action": { "type": "block" }
      },
      {
        "trigger": {
          "url-filter": ".*googleads\\\\.g\\\\.doubleclick\\\\.net.*"
        },
        "action": { "type": "block" }
      },
      {
        "trigger": {
          "url-filter": ".*youtube\\\\.com/pagead/.*"
        },
        "action": { "type": "block" }
      },
      {
        "trigger": {
          "url-filter": ".*youtube\\\\.com/api/stats/ads.*"
        },
        "action": { "type": "block" }
      }
    ]
    """

    private init() {}

    func attachContentRules(to controller: WKUserContentController) async {
        do {
            let list = try await compileRuleList()
            controller.add(list)
        } catch {
            // DOM cleanup remains available even if the rule list cannot compile.
        }
    }

    private func compileRuleList() async throws -> WKContentRuleList {
        try await withCheckedThrowingContinuation { continuation in
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: identifier,
                encodedContentRuleList: rulesJSON
            ) { list, error in
                if let list {
                    continuation.resume(returning: list)
                } else {
                    continuation.resume(
                        throwing: error ?? NSError(
                            domain: "SocialControl.AdBlock",
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Unable to compile content rules."]
                        )
                    )
                }
            }
        }
    }
}
