import SwiftUI
import FamilyControls
import DeviceActivity

extension DeviceActivityReport.Context {
    static let socialSummary = Self("socialSummary")
}

struct InsightsView: View {
    @StateObject private var selectionStore = UsageSelectionStore()
    @State private var showPicker = false
    @State private var authorized = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            Group {
                if !authorized {
                    permissionView
                } else if selectionStore.selection.applicationTokens.isEmpty {
                    selectionView
                } else {
                    reportView
                }
            }
            .navigationTitle("Insights")
            .familyActivityPicker(
                isPresented: $showPicker,
                selection: $selectionStore.selection
            )
            .onChange(of: selectionStore.selection) {
                selectionStore.save()
            }
        }
    }

    private var permissionView: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 46))
                .foregroundStyle(.blue)

            Text("Entiende tus hábitos")
                .font(.title2.bold())

            Text("Da permiso a Tiempo de uso. NoScroll analiza la actividad seleccionada usando las APIs de Apple.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Permitir Tiempo de uso") {
                Task {
                    do {
                        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                        authorized = true
                    } catch {
                        errorText = error.localizedDescription
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            Text("Los datos permanecen protegidos por Screen Time.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let errorText {
                Text(errorText)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding(24)
    }

    private var selectionView: some View {
        VStack(spacing: 18) {
            Spacer()

            Text("Elige Instagram y YouTube una vez")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Apple requiere que confirmes qué apps quieres analizar. Después la selección queda guardada.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Elegir apps") {
                showPicker = true
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding(24)
    }

    private var reportView: some View {
        VStack(spacing: 12) {
            DeviceActivityReport(
                .socialSummary,
                filter: DeviceActivityFilter(
                    segment: .daily(
                        during: Calendar.current.dateInterval(
                            of: .weekOfYear,
                            for: .now
                        )!
                    ),
                    users: .all,
                    devices: .all,
                    applications: selectionStore.selection.applicationTokens,
                    categories: selectionStore.selection.categoryTokens,
                    webDomains: selectionStore.selection.webDomainTokens
                )
            )

            Button("Cambiar apps analizadas") {
                showPicker = true
            }
            .font(.footnote)
        }
    }
}
