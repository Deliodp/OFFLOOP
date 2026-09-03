import Foundation
import FamilyControls

@MainActor
final class UsageSelectionStore: ObservableObject {
    @Published var selection = FamilyActivitySelection()

    init() {
        if let data = SharedConfig.defaults.data(forKey: SharedConfig.selectedAppsKey),
           let saved = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = saved
        }
    }

    func save() {
        if let data = try? PropertyListEncoder().encode(selection) {
            SharedConfig.defaults.set(data, forKey: SharedConfig.selectedAppsKey)
        }
    }
}
