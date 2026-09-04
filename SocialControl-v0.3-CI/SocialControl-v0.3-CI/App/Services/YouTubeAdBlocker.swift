import WebKit

@MainActor
final class YouTubeAdBlocker {

    static let shared = YouTubeAdBlocker()

    private let identifier = "OFFLOOP.YouTubeAds.v2"

    /*
     OFFLOOP YouTube Ad Shield

     Principio:
     - Bloquear endpoints publicitarios conocidos.
     - NO bloquear googlevideo.com de forma global.
     - NO bloquear youtubei/v1/player globalmente.
     - Preservar reproducción normal, login, búsqueda,
       comentarios y recomendaciones.
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

        do {

            let list = try await contentRuleList()

            controller.add(list)

            addCosmeticScript(to: controller)

        } catch {

            /*
             Aunque la lista de red no pudiera compilar,
             mantenemos la capa cosmética.

             Preferimos que YouTube funcione con algún anuncio
             antes que romper la reproducción.
            */

            addCosmeticScript(to: controller)
        }
    }


    // MARK: - NETWORK BLOCKING

    private func contentRuleList() async throws
        -> WKContentRuleList {

        let store =
            WKContentRuleListStore.default()

        /*
         Primero intentamos reutilizar una versión
         ya compilada.

         WKContentRuleListStore persiste las listas,
         así evitamos recompilarlas cada vez.
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

                } else {

                    continuation.resume(
                        throwing:
                            error ??
                            NSError(
                                domain:
                                    "OFFLOOP.AdBlock",
                                code: 1,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "Rule list not found"
                                ]
                            )
                    )
                }
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

                } else {

                    continuation.resume(
                        throwing:
                            error ??
                            NSError(
                                domain:
                                    "OFFLOOP.AdBlock",
                                code: 2,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "Unable to compile rules"
                                ]
                            )
                    )
                }
            }
        }
    }


    // MARK: - COSMETIC / DOM LAYER

    private func addCosmeticScript(
        to controller: WKUserContentController
    ) {

        let script = """

        (() => {

          if (window.__offloopAdShieldInstalled) {
            return;
          }

          window.__offloopAdShieldInstalled = true;


          const hide = (element) => {

            if (!element) {
              return;
            }

            element.style.setProperty(
              'display',
              'none',
              'important'
            );
          };


          const removeAds = () => {

            const selectors = [

              /*
               Desktop / player
              */

              '.ytp-ad-module',
              '.ytp-ad-overlay-container',
              '.ytp-ad-player-overlay',
              '.ytp-ad-text-overlay',
              '.ytp-ad-preview-container',
              '.ytp-ad-image-overlay',

              /*
               Desktop feed
              */

              'ytd-ad-slot-renderer',
              'ytd-display-ad-renderer',
              'ytd-promoted-video-renderer',
              'ytd-in-feed-ad-layout-renderer',
              'ytd-banner-promo-renderer',
              'ytd-action-companion-ad-renderer',
              'ytd-promoted-sparkles-web-renderer',

              /*
               Mobile YouTube
              */

              'ytm-promoted-video-renderer',
              'ytm-companion-ad-renderer',
              'ytm-promoted-sparkles-web-renderer',
              'ytm-display-ad-renderer'
            ];


            selectors.forEach(selector => {

              document
                .querySelectorAll(selector)
                .forEach(hide);
            });


            /*
             Si YouTube ofrece oficialmente
             "Saltar anuncio", lo pulsamos.
            */

            const skipSelectors = [

              '.ytp-ad-skip-button',
              '.ytp-ad-skip-button-modern',
              'button.ytp-skip-ad-button',
              '.ytp-skip-ad-button'
            ];


            skipSelectors.forEach(selector => {

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
            });
          };


          /*
           YouTube modifica continuamente su DOM.
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


          removeAds();


          const observer =
            new MutationObserver(schedule);


          observer.observe(
            document.documentElement,
            {
              childList: true,
              subtree: true
            }
          );


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
}
