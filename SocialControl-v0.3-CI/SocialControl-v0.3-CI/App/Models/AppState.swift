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

    let debugDestination: SocialPlatform?

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

        let args = ProcessInfo.processInfo.arguments

        if let index = args.firstIndex(of: "-debugPlatform"),
           args.indices.contains(index + 1) {
            switch args[index + 1].lowercased() {
            case "instagram":
                debugDestination = .instagram
            case "youtube":
                debugDestination = .youtube
            default:
                debugDestination = nil
            }
        } else {
            debugDestination = nil
        }

        #if DEBUG
        if args.contains("-skipOnboarding") {
            hasCompletedOnboarding = true
        }
        #endif
    }
}
