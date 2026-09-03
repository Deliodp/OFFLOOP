import Foundation

enum SharedConfig {
    static let appGroup = "group.com.yourcompany.SocialControl"

    static let reelsKey = "blockInstagramReels"
    static let shortsKey = "blockYouTubeShorts"
    static let adsKey = "blockYouTubeAds"
    static let selectedAppsKey = "selectedAppsArchive"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }
}
