import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var page = 0

    private let background = Color(
        red: 246 / 255,
        green: 250 / 255,
        blue: 255 / 255
    )

    private let primaryBlue = Color(
        red: 74 / 255,
        green: 144 / 255,
        blue: 226 / 255
    )

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            if page == 0 {
                welcomePage
            } else {
                setupPage
            }
        }
    }

    // MARK: - PAGE 1

    private var welcomePage: some View {
        VStack(spacing: 0) {

            Spacer()

            ZStack {
                Circle()
                    .fill(primaryBlue.opacity(0.12))
                    .frame(width: 82, height: 82)

                Circle()
                    .fill(primaryBlue)
                    .frame(width: 62, height: 62)

                Circle()
                    .stroke(Color.white, lineWidth: 6)
                    .frame(width: 31, height: 31)
            }

            Spacer()
                .frame(height: 30)

            Text("Quédate con lo bueno.")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .tracking(-1.1)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal, 32)

            Spacer()
                .frame(height: 15)

            Text("Quita Reels y Shorts sin dejar\nInstagram ni YouTube.")
                .font(.system(size: 18, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .lineSpacing(4)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    page = 1
                }
            } label: {
                Text("Continuar")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .foregroundStyle(.white)
                    .background(primaryBlue)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 28)

            Spacer()
                .frame(height: 17)

            Text("Sin cuenta propia. Sin publicidad dentro de la app.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
                .frame(height: 34)
        }
    }

    // MARK: - PAGE 2

    private var setupPage: some View {
        VStack(alignment: .leading, spacing: 0) {

            Spacer()
                .frame(height: 70)

            Text("CONFIGÚRALO EN 10 SEGUNDOS")
                .font(.system(size: 12, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(primaryBlue)

            Spacer()
                .frame(height: 12)

            Text("¿Qué quieres quitar?")
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .tracking(-0.8)

            Spacer()
                .frame(height: 7)

            Text("Puedes cambiarlo cuando quieras.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            Spacer()
                .frame(height: 30)

            featureCard(
                title: "Instagram Reels",
                subtitle: "Ocultar contenido corto",
                icon: "camera.fill",
                isOn: $appState.blockInstagramReels
            )

            Spacer()
                .frame(height: 14)

            featureCard(
                title: "YouTube Shorts",
                subtitle: "Ocultar contenido corto",
                icon: "play.rectangle.fill",
                isOn: $appState.blockYouTubeShorts
            )

            Spacer()

            Button {
                appState.hasCompletedOnboarding = true
            } label: {
                Text("Listo")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .foregroundStyle(.white)
                    .background(primaryBlue)
                    .clipShape(Capsule())
            }

            Spacer()
                .frame(height: 16)

            Text("La primera vez que abras cada red tendrás que iniciar sesión una vez.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Spacer()
                .frame(height: 28)
        }
        .padding(.horizontal, 22)
    }

    // MARK: - COMPONENT

    private func featureCard(
        title: String,
        subtitle: String,
        icon: String,
        isOn: Binding<Bool>
    ) -> some View {

        HStack(spacing: 14) {

            Image(systemName: icon)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(primaryBlue)
                .frame(width: 52, height: 52)
                .background(primaryBlue.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 17))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.green)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(
            color: primaryBlue.opacity(0.07),
            radius: 16,
            y: 6
        )
    }
}
