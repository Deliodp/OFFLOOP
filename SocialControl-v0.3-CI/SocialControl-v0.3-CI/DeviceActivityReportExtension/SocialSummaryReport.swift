import DeviceActivity
import SwiftUI

extension DeviceActivityReport.Context {
    static let socialSummary = Self("socialSummary")
}

struct SocialSummaryReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .socialSummary
    let content: (SocialUsageSummary) -> SocialSummaryView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> SocialUsageSummary {
        var total: TimeInterval = 0
        var apps: [String: TimeInterval] = [:]

        for await activityData in data {
            for await segment in activityData.activitySegments {
                total += segment.totalActivityDuration

                for await category in segment.categories {
                    for await application in category.applications {
                        let name = application.application.localizedDisplayName ?? "App"
                        apps[name, default: 0] += application.totalActivityDuration
                    }
                }
            }
        }

        let sorted = apps
            .map { SocialUsageSummary.AppUsage(name: $0.key, duration: $0.value) }
            .sorted { $0.duration > $1.duration }

        return SocialUsageSummary(total: total, applications: sorted)
    }
}

struct SocialSummaryView: View {
    let configuration: SocialUsageSummary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Esta semana")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Text(format(configuration.total))
                    .font(.system(size: 38, weight: .bold, design: .rounded))

                ForEach(configuration.applications) { app in
                    HStack {
                        Text(app.name)
                        Spacer()
                        Text(format(app.duration))
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
        }
    }

    private func format(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        return "\(minutes / 60) h \(minutes % 60) min"
    }
}

@main
struct SocialControlReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        SocialSummaryReport { summary in
            SocialSummaryView(configuration: summary)
        }
    }
}
