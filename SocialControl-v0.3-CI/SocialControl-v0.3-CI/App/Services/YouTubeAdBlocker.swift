import WebKit

@MainActor
final class YouTubeAdBlocker {

    static let shared = YouTubeAdBlocker()

    /*
     Cambiamos el identificador cada vez que
     modificamos las reglas.

     WebKit guarda las listas compiladas en caché.
     Si reutilizáramos "v3", podría seguir usando
     las reglas antiguas.
    */
    private let identifier =
        "OFFLOOP.YouTubeAds.v4"


    // MARK: - NETWORK RULES

    /*
     Estrategia conservadora.

     Bloqueamos proveedores publicitarios externos
     conocidos, pero NO bloqueamos endpoints internos
     de youtube.com ni googlevideo.com.

     Prioridad:
     YouTube nunca debe dejar de reproducir un vídeo
     por culpa de OFFLOOP.
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
          "url-filter": ".*googlesyndication\\\\.com.*"
        },
        "action": {
          "type": "block"
        }
      },

      {
        "trigger": {
          "url-filter": ".*googleadservices\\\\.com.*"
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
         La capa visual siempre se instala.

         Incluso si las reglas de red fallan,
         OFFLOOP puede seguir limpiando la interfaz.
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
             Fail-safe.

             Es preferible mostrar algún anuncio
             antes que romper YouTube.
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

        guard let store =
                WKContentRuleListStore.default()
        else {

            throw AdBlockError.ruleStoreUnavailable
        }


        /*
         Si esta versión ya está compilada,
         la reutilizamos.
        */

        if let existing =
            try? await existingRuleList(
                store: store
            ) {

            return existing
        }


        return try await compileRuleList(
            store: store
        )
    }


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


    // MARK: - DOM SHIELD

    private func addCosmeticScript(
        to controller: WKUserContentController
    ) {

        let script = """

        (() => {

          /*
           Una sola instalación por documento.
          */

          if (window.__offloopYouTubeShield) {
            return;
          }

          window.__offloopYouTubeShield = true;


          // ============================================
          // HELPERS
          // ============================================

          const hide = (element) => {

            if (!element) {
              return;
            }


            if (
              element.dataset &&
              element.dataset.offloopHidden === 'true'
            ) {
              return;
            }


            element.style.setProperty(
              'display',
              'none',
              'important'
            );


            if (element.dataset) {

              element.dataset.offloopHidden =
                'true';
            }
          };


          const normalizedText = (element) => {

            return (
              element.innerText ||
              element.textContent ||
              ''
            )
            .trim()
            .replace(/\\s+/g, ' ')
            .toLowerCase();
          };


          // ============================================
          // STANDARD ADS
          // ============================================

          const cleanStandardAds = () => {

            const selectors = [

              /*
               Player
              */

              '.ytp-ad-module',
              '.ytp-ad-overlay-container',
              '.ytp-ad-player-overlay',
              '.ytp-ad-text-overlay',
              '.ytp-ad-preview-container',
              '.ytp-ad-image-overlay',
              '.ytp-ad-action-interstitial',
              '.ytp-ad-player-overlay-layout',


              /*
               Desktop
              */

              'ytd-ad-slot-renderer',
              'ytd-display-ad-renderer',
              'ytd-promoted-video-renderer',
              'ytd-in-feed-ad-layout-renderer',
              'ytd-banner-promo-renderer',
              'ytd-action-companion-ad-renderer',
              'ytd-promoted-sparkles-web-renderer',
              'ytd-engagement-panel-section-list-renderer[target-id*="ads"]',


              /*
               Mobile
              */

              'ytm-promoted-video-renderer',
              'ytm-companion-ad-renderer',
              'ytm-promoted-sparkles-web-renderer',
              'ytm-display-ad-renderer',
              'ytm-ad-slot-renderer'
            ];


            selectors.forEach(
              selector => {

                document
                  .querySelectorAll(selector)
                  .forEach(hide);
              }
            );
          };


          // ============================================
          // SKIP AD
          // ============================================

          const clickSkipButtons = () => {

            const selectors = [

              '.ytp-ad-skip-button',

              '.ytp-ad-skip-button-modern',

              'button.ytp-skip-ad-button',

              '.ytp-skip-ad-button',

              '.ytp-ad-skip-button-container button'
            ];


            selectors.forEach(
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


          // ============================================
          // "OPEN APP" PROMO
          // ============================================

          /*
           YouTube móvil muestra una franja
           "Open App" en la parte superior.

           No ocultamos todo el header porque
           queremos mantener búsqueda y menú.

           Buscamos únicamente el control
           "Open App" y su contenedor compacto.
          */

          const cleanOpenAppPromo = () => {

            document
              .querySelectorAll(
                'a, button, span, div'
              )
              .forEach(element => {

                const text =
                  normalizedText(element);


                if (
                  text !== 'open app' &&
                  text !== 'open youtube'
                ) {
                  return;
                }


                const rect =
                  element.getBoundingClientRect();


                /*
                 Solo elementos en la zona superior.
                */

                if (
                  rect.top < 0 ||
                  rect.top > 220
                ) {
                  return;
                }


                let candidate =
                  element;


                /*
                 Ascendemos únicamente por
                 contenedores pequeños.

                 Así evitamos borrar toda
                 la cabecera de YouTube.
                */

                for (
                  let i = 0;
                  i < 4;
                  i++
                ) {

                  if (!candidate.parentElement) {
                    break;
                  }


                  const parent =
                    candidate.parentElement;

                  const parentRect =
                    parent.getBoundingClientRect();


                  if (
                    parentRect.height <= 120 &&
                    parentRect.width <=
                      window.innerWidth * 0.75
                  ) {

                    candidate =
                      parent;

                  } else {

                    break;
                  }
                }


                hide(candidate);
              });
          };


          // ============================================
          // SPONSORED FEED ITEMS
          // ============================================

          const cleanSponsoredCards = () => {

            document
              .querySelectorAll(
                'ytm-rich-item-renderer,' +
                'ytm-video-with-context-renderer,' +
                'ytd-rich-item-renderer,' +
                'ytd-video-renderer'
              )
              .forEach(card => {

                const text =
                  normalizedText(card);


                /*
                 Solo usamos etiquetas publicitarias
                 inequívocas.

                 No bloqueamos vídeos simplemente
                 porque contengan determinadas palabras.
                */

                if (
                  text.includes('sponsored') ||
                  text.includes('promoted')
                ) {

                  hide(card);
                }
              });
          };


          // ============================================
          // APPLY
          // ============================================

          const apply = () => {

            cleanStandardAds();

            clickSkipButtons();

            cleanOpenAppPromo();

            cleanSponsoredCards();
          };


          // ============================================
          // OBSERVER
          // ============================================

          let scheduled = false;


          const schedule = () => {

            if (scheduled) {
              return;
            }


            scheduled = true;


            requestAnimationFrame(() => {

              scheduled = false;

              apply();
            });
          };


          /*
           Primera pasada.
          */

          apply();


          /*
           YouTube es una SPA.

           Los elementos aparecen después
           de que la página ya haya cargado.
          */

          const observer =
            new MutationObserver(
              schedule
            );


          observer.observe(
            document.documentElement,
            {
              childList: true,
              subtree: true
            }
          );


          /*
           Navegación interna.
          */

          window.addEventListener(
            'pageshow',
            schedule
          );


          window.addEventListener(
            'popstate',
            schedule
          );


          /*
           YouTube dispara este evento
           al navegar internamente.
          */

          document.addEventListener(
            'yt-navigate-finish',
            schedule
          );


          /*
           Barrido periódico ligero.

           Nos ayuda con elementos que aparecen
           después de animaciones o retrasos
           sin estar mutando continuamente.
          */

          window.setInterval(
            apply,
            1500
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
