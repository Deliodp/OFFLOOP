import SafariServices

final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let response = NSExtensionItem()
        response.userInfo = [
            SFExtensionMessageKey: [
                "reels": SharedConfig.defaults.bool(forKey: SharedConfig.reelsKey),
                "shorts": SharedConfig.defaults.bool(forKey: SharedConfig.shortsKey),
                "ads": SharedConfig.defaults.bool(forKey: SharedConfig.adsKey)
            ]
        ]
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }
}
