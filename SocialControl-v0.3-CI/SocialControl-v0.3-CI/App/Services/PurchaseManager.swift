import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {

    static let lifetimeProductID =
        "com.yourcompany.SocialControl.lifetime"

    @Published var hasPremium = false
    @Published var displayPrice: String?
    @Published var isBusy = false
    @Published var errorMessage: String?

    private var lifetimeProduct: Product?

    private var transactionTask:
        Task<Void, Never>?

    /*
     Solo se utiliza durante nuestras pruebas.

     nil   = comportamiento real de StoreKit
     true  = Premium forzado ON
     false = Premium forzado OFF
    */
    private let debugPremiumOverride: Bool?


    // MARK: - INIT

    init() {

        debugPremiumOverride =
            Self.readDebugPremiumOverride()

        /*
         IMPORTANTÍSIMO PARA GITHUB ACTIONS:

         El valor Premium queda establecido
         inmediatamente al crear PurchaseManager.

         Así SocialBrowserView puede saber desde
         el primer render si debe activar
         YouTubeAdBlocker.
        */

        if let debugPremiumOverride {

            hasPremium =
                debugPremiumOverride
        }


        transactionTask =
            Task { [weak self] in

                for await result
                    in Transaction.updates {

                    guard let self else {
                        return
                    }

                    if case .verified(
                        let transaction
                    ) = result {

                        await transaction.finish()

                        await self
                            .refreshEntitlements()
                    }
                }
            }
    }


    deinit {

        transactionTask?.cancel()
    }


    // MARK: - PREPARE

    func prepare() async {

        /*
         Durante nuestros tests automáticos
         NO queremos que StoreKit sobrescriba
         Premium ON/OFF.
        */

        if let debugPremiumOverride {

            hasPremium =
                debugPremiumOverride

            displayPrice =
                debugPremiumOverride
                ? "TEST PREMIUM"
                : nil

            return
        }


        await refreshEntitlements()


        do {

            lifetimeProduct =
                try await Product.products(
                    for: [
                        Self.lifetimeProductID
                    ]
                ).first

            displayPrice =
                lifetimeProduct?.displayPrice

        } catch {

            errorMessage =
                error.localizedDescription
        }
    }


    // MARK: - PURCHASE

    func purchaseLifetime() async {

        /*
         Nunca ejecutamos compras reales
         durante un test debug.
        */

        if debugPremiumOverride != nil {

            return
        }


        guard let lifetimeProduct else {

            errorMessage =
                "StoreKit product is not configured yet."

            return
        }


        isBusy = true

        defer {
            isBusy = false
        }


        do {

            let result =
                try await lifetimeProduct.purchase()


            switch result {

            case .success(
                let verification
            ):

                guard case .verified(
                    let transaction
                ) = verification
                else {

                    errorMessage =
                        "Purchase verification failed."

                    return
                }


                await transaction.finish()

                await refreshEntitlements()


            case .pending,
                 .userCancelled:

                break


            @unknown default:

                break
            }

        } catch {

            errorMessage =
                error.localizedDescription
        }
    }


    // MARK: - RESTORE

    func restore() async {

        /*
         No restauramos compras reales
         durante los tests.
        */

        if debugPremiumOverride != nil {

            return
        }


        do {

            try await AppStore.sync()

            await refreshEntitlements()

        } catch {

            errorMessage =
                error.localizedDescription
        }
    }


    // MARK: - ENTITLEMENTS

    private func refreshEntitlements()
        async {

        /*
         Si estamos ejecutando
         YouTube Ad Test,
         respetamos siempre el override.
        */

        if let debugPremiumOverride {

            hasPremium =
                debugPremiumOverride

            return
        }


        var unlocked = false


        for await result
            in Transaction.currentEntitlements {

            if case .verified(
                let transaction
            ) = result,

               transaction.productID ==
                Self.lifetimeProductID,

               transaction.revocationDate ==
                nil {

                unlocked = true
            }
        }


        hasPremium = unlocked
    }


    // MARK: - DEBUG ARGUMENTS

    private static func
        readDebugPremiumOverride()
        -> Bool? {

        #if DEBUG

        let arguments =
            ProcessInfo
                .processInfo
                .arguments


        /*
         Compatibilidad con nuestro
         antiguo argumento:
         -unlockPremium
        */

        if arguments.contains(
            "-unlockPremium"
        ) {

            return true
        }


        /*
         Nuevo sistema:

         -debugPremium true

         o

         -debugPremium false
        */

        if let index =
            arguments.firstIndex(
                of: "-debugPremium"
            ),

           arguments.indices.contains(
                index + 1
           ) {

            let value =
                arguments[index + 1]
                    .lowercased()


            switch value {

            case "true",
                 "1",
                 "yes",
                 "on":

                return true


            case "false",
                 "0",
                 "no",
                 "off":

                return false


            default:

                return nil
            }
        }

        #endif


        return nil
    }
}
