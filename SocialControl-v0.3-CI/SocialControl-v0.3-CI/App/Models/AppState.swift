import SwiftUI

@MainActor
final class AppState: ObservableObject {
    private let shared = UserDefaults(suiteName: SharedConfig.appGroup) ?? .standard

    @Published var blockInstagramReels: Bool {
        didSet { shared.set(blockInstagramReels, forKey: SharedConfig.reelsKey) }
    }

    @Published var blockYouTubeShorts: Bool {
        didSet { shared.set(blockYouTubeShorts, forKey: SharedConfig.shortsKey) }
    }

    @Published var blockYouTubeAds: Bool {
        didSet { shared.set(blockYouTubeAds, forKey: SharedConfig.adsKey) }
    }

    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false

    init() {
        if shared.object(forKey: SharedConfig.reelsKey) == nil {
            shared.set(true, forKey: SharedConfig.reelsKey)
        }
        if shared.object(forKey: SharedConfig.shortsKey) == nil {
            shared.set(true, forKey: SharedConfig.shortsKey)
        }

        blockInstagramReels = shared.bool(forKey: SharedConfig.reelsKey)
        blockYouTubeShorts = shared.bool(forKey: SharedConfig.shortsKey)
        blockYouTubeAds = shared.bool(forKey: SharedConfig.adsKey)
    }
}
