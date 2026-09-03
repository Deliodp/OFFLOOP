import SwiftUI

@main
struct SocialControlApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(purchaseManager)
                .task {
                    await purchaseManager.prepare()
                }
        }
    }
}
