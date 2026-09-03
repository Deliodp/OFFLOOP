import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Inicio", systemImage: "house.fill") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }
        }
        .tint(.blue)
    }
}
