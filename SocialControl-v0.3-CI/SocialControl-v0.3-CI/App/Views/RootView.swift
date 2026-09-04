import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if let destination = appState.debugDestination {
                NavigationStack {
                    SocialBrowserView(platform: destination)
                }
            } else if appState.hasCompletedOnboarding {
                MainView()
            } else {
                OnboardingView()
            }
        }
    }
}
