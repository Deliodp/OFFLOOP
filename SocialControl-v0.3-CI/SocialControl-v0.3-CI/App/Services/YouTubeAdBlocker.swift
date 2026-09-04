import WebKit

@MainActor
final class YouTubeAdBlocker {

    static let shared = YouTubeAdBlocker()

    private let identifier = "OFFLOOP.YouTubeAds.v3"

    /*
     OFFLOOP YouTube Ad Shield

     Objetivo:
     1. Bloquear peticiones publicitarias conocidas.
     2. Eliminar elementos publicitarios de la interfaz.
     3. Pulsar automáticamente "Skip Ad" cuando YouTube
        ofrece ese botón.
     4. NO bloquear googlevideo.com de forma global,
        porque podríamos romper los vídeos normales.
    */

    private let rulesJSON = """
    [
      {
        "trigger": {
          "url-filter": ".*doubleclick\\\\.net.*"
        },
        "action": {
          "type": "block"
        }
      },

      {
        "trigger": {
          "url-filter": ".*googleads\\\\.g\\\\.doubleclick\\\\.net.*"
        },
        "action": {
          "type": "block"
        }
      },

      {
        "trigger": {
          "url-filter": ".*googlesyndication\\\\.com.*"
        },
        "action": {
          "type": "block"
        }
      },

      {
        "trigger": {
          "url-filter": ".*youtube\\\\.com/pagead/.*"
        },
        "action": {
          "type": "block"
        }
      },

      {
        "trigger": {
          "url-filter": ".*youtube\\\\.com/api/stats/ads.*"
        },
        "action": {
          "type": "block"
        }
      },

      {
        "trigger": {
          "url-filter": ".*youtube\\\\.com/ptracking.*"
        },
        "action": {
          "type": "block"
        }
      },

      {
        "trigger": {
          "url-filter": ".*youtube\\\\.com/pagead/conversion.*"
        },
        "action": {
          "type": "block"
        }
      },

      {
        "trigger": {
          "url-filter": ".*youtube\\\\.com/get_midroll_info.*"
        },
        "action": {
          "type": "block"
        }
      }
    ]
    """

    private init() {}


    // MARK: - PUBLIC

    func attachContentRules(
        to controller: WKUserContentController
    ) async {

        /*
         Ponemos siempre la capa DOM.

         Así, incluso si WebKit no pudiera cargar
         las reglas de red, seguimos teniendo
         protección cosmética.
        */

        addCosmeticScript(
            to: controller
        )

        do {

            let list =
                try await contentRuleList()

            controller.add(list)

        } catch {

            /*
             Fail-safe:

             Si falla la lista de bloqueo,
             NO rompemos YouTube.

             La navegación sigue funcionando
             usando únicamente la capa DOM.
            */

            print(
                "OFFLOOP Ad Shield: network rules unavailable:",
                error
            )
        }
    }


    // MARK: - CONTENT RULE LIST

    private func contentRuleList()
        async throws -> WKContentRuleList {

        /*
         WKContentRuleListStore.default()
         puede devolver nil.

         Esta comprobación es precisamente
         lo que corrige el fallo de compilación.
        */

        guard let store =
                WKContentRuleListStore.default()
        else {

            throw AdBlockError.ruleStoreUnavailable
        }


        /*
         Primero intentamos recuperar
         una lista previamente compilada.
        */

        if let existing =
            try? await existingRuleList(
                store: store
            ) {

            return existing
        }


        /*
         Si no existe todavía,
         compilamos las reglas.
        */

        return try await compileRuleList(
            store: store
        )
    }


    // MARK: - EXISTING RULES

    private func existingRuleList(
        store: WKContentRuleListStore
    ) async throws -> WKContentRuleList {

        try await withCheckedThrowingContinuation {
            continuation in

            store.lookUpContentRuleList(
                forIdentifier: identifier
            ) { list, error in

                if let list {

                    continuation.resume(
                        returning: list
                    )

                    return
                }


                if let error {

                    continuation.resume(
                        throwing: error
                    )

                    return
                }


                continuation.resume(
                    throwing:
                        AdBlockError.ruleListNotFound
                )
            }
        }
    }


    // MARK: - COMPILE RULES

    private func compileRuleList(
        store: WKContentRuleListStore
    ) async throws -> WKContentRuleList {

        try await withCheckedThrowingContinuation {
            continuation in

            store.compileContentRuleList(
                forIdentifier: identifier,
                encodedContentRuleList:
                    rulesJSON
            ) { list, error in

                if let list {

                    continuation.resume(
                        returning: list
                    )

                    return
                }


                if let error {

                    continuation.resume(
                        throwing: error
                    )

                    return
                }


                continuation.resume(
                    throwing:
                        AdBlockError.ruleCompilationFailed
                )
            }
        }
    }


    // MARK: - DOM / COSMETIC LAYER

    private func addCosmeticScript(
        to controller: WKUserContentController
    ) {

        let script = """

        (() => {

          /*
           Evitamos instalar dos veces
           el mismo observer.
          */

          if (window.__offloopAdShieldInstalled) {
            return;
          }

          window.__offloopAdShieldInstalled = true;


          const hide = (element) => {

            if (!element) {
              return;
            }

            if (
              element.dataset &&
              element.dataset.offloopAdHidden === 'true'
            ) {
              return;
            }

            element.style.setProperty(
              'display',
              'none',
              'important'
            );

            if (element.dataset) {

              element.dataset.offloopAdHidden =
                'true';
            }
          };


          const removeAds = () => {

            /*
             ELEMENTOS PUBLICITARIOS
             DEL PLAYER Y DEL FEED
            */

            const selectors = [

              '.ytp-ad-module',

              '.ytp-ad-overlay-container',

              '.ytp-ad-player-overlay',

              '.ytp-ad-text-overlay',

              '.ytp-ad-preview-container',

              '.ytp-ad-image-overlay',

              'ytd-ad-slot-renderer',

              'ytd-display-ad-renderer',

              'ytd-promoted-video-renderer',

              'ytd-in-feed-ad-layout-renderer',

              'ytd-banner-promo-renderer',

              'ytd-action-companion-ad-renderer',

              'ytd-promoted-sparkles-web-renderer',

              'ytm-promoted-video-renderer',

              'ytm-companion-ad-renderer',

              'ytm-promoted-sparkles-web-renderer',

              'ytm-display-ad-renderer'
            ];


            selectors.forEach(
              selector => {

                document
                  .querySelectorAll(selector)
                  .forEach(hide);
              }
            );


            /*
             SKIP AD

             Solo usamos botones que
             YouTube ya muestra al usuario.
            */

            const skipSelectors = [

              '.ytp-ad-skip-button',

              '.ytp-ad-skip-button-modern',

              'button.ytp-skip-ad-button',

              '.ytp-skip-ad-button'
            ];


            skipSelectors.forEach(
              selector => {

                document
                  .querySelectorAll(selector)
                  .forEach(button => {

                    if (
                      button instanceof HTMLElement &&
                      !button.disabled
                    ) {

                      button.click();
                    }
                  });
              }
            );
          };


          /*
           YouTube funciona como SPA
           y modifica el DOM constantemente.

           MutationObserver vuelve a aplicar
           el filtro cuando aparecen
           nuevos elementos.
          */

          let scheduled = false;


          const schedule = () => {

            if (scheduled) {
              return;
            }

            scheduled = true;


            requestAnimationFrame(() => {

              scheduled = false;

              removeAds();
            });
          };


          /*
           Primera limpieza.
          */

          removeAds();


          /*
           Limpieza dinámica.
          */

          const observer =
            new MutationObserver(schedule);


          observer.observe(
            document.documentElement,
            {
              childList: true,
              subtree: true
            }
          );


          /*
           YouTube cambia de vídeo
           sin recargar siempre la página.
          */

          window.addEventListener(
            'pageshow',
            schedule
          );


          window.addEventListener(
            'popstate',
            schedule
          );

        })();

        """


        controller.addUserScript(
            WKUserScript(
                source: script,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
        )
    }


    // MARK: - ERRORS

    private enum AdBlockError: Error {

        case ruleStoreUnavailable

        case ruleListNotFound

        case ruleCompilationFailed
    }
}
