import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var purchaseManager: PurchaseManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    platformCard(
                        title: "Instagram Reels",
                        subtitle: appState.blockInstagramReels ? "Reels desactivados" : "Reels activados",
                        icon: "camera.fill",
                        isOn: $appState.blockInstagramReels,
                        platform: .instagram
                    )

                    platformCard(
                        title: "YouTube Shorts",
                        subtitle: appState.blockYouTubeShorts ? "Shorts desactivados" : "Shorts activados",
                        icon: "play.rectangle.fill",
                        isOn: $appState.blockYouTubeShorts,
                        platform: .youtube
                    )

                    premiumCard
                }
                .padding(20)
            }
            .background(Color(red: 0.96, green: 0.98, blue: 1.0))
            .navigationTitle("APP NAME")
        }
    }

    private func platformCard(
        title: String,
        subtitle: String,
        icon: String,
        isOn: Binding<Bool>,
        platform: SocialPlatform
    ) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 46, height: 46)
                    .background(.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 15))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(isOn.wrappedValue ? .green : .secondary)
                }

                Spacer()

                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(.green)
            }

            NavigationLink {
                SocialBrowserView(platform: platform)
            } label: {
                Text(platform == .instagram ? "Abrir Instagram" : "Abrir YouTube")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
    }

    private var premiumCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("PREMIUM", systemImage: "sparkles")
                .font(.caption.bold())
                .foregroundStyle(.blue)

            Text("YouTube sin anuncios.")
                .font(.title3.bold())

            Text("Sin suscripción. Sin interrupciones.")
                .foregroundStyle(.secondary)
                .font(.subheadline)

            Toggle(
                "Bloquear anuncios",
                isOn: Binding(
                    get: { purchaseManager.hasPremium && appState.blockYouTubeAds },
                    set: { value in
                        guard purchaseManager.hasPremium else { return }
                        appState.blockYouTubeAds = value
                    }
                )
            )
            .tint(.green)
            .disabled(!purchaseManager.hasPremium)

            if !purchaseManager.hasPremium {
                Button {
                    Task { await purchaseManager.purchaseLifetime() }
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Desbloquear para siempre")
                                .fontWeight(.semibold)
                            Text("PAGO ÚNICO")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(purchaseManager.displayPrice ?? "9,99 €")
                            .fontWeight(.bold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            }
        }
        .padding(18)
        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
    }
}
