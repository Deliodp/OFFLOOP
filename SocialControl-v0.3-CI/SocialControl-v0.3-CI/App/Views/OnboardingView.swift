import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var page = 0

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.98, blue: 1.0).ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                if page == 0 {
                    Image(systemName: "circle.circle.fill")
                        .font(.system(size: 58))
                        .foregroundStyle(.blue)

                    Text("Quédate con lo bueno.")
                        .font(.system(size: 36, weight: .bold, design: .rounded))

                    Text("Quita Reels y Shorts sin dejar Instagram ni YouTube.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("¿Qué quieres quitar?")
                        .font(.system(size: 30, weight: .bold, design: .rounded))

                    Toggle("Instagram Reels", isOn: $appState.blockInstagramReels)
                        .tint(.green)
                        .padding()
                        .background(.white, in: RoundedRectangle(cornerRadius: 20))

                    Toggle("YouTube Shorts", isOn: $appState.blockYouTubeShorts)
                        .tint(.green)
                        .padding()
                        .background(.white, in: RoundedRectangle(cornerRadius: 20))
                }

                Spacer()

                Button(page == 0 ? "Continuar" : "Listo") {
                    if page == 0 {
                        withAnimation(.snappy) { page = 1 }
                    } else {
                        appState.hasCompletedOnboarding = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text(page == 0
                     ? "Sin cuenta propia. Sin publicidad dentro de la app."
                     : "La primera vez que abras cada red, inicia sesión una vez.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
            }
            .padding(24)
        }
    }
}
