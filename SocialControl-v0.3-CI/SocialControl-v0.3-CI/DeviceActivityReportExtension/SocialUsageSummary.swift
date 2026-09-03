import Foundation

struct SocialUsageSummary {
    let total: TimeInterval
    let applications: [AppUsage]

    struct AppUsage: Identifiable {
        let id = UUID()
        let name: String
        let duration: TimeInterval
    }
}
