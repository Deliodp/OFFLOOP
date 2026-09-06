import Foundation

enum SocialPlatform {
    case instagram
    case youtube
}

enum FilterScriptProvider {

    static func script(
        platform: SocialPlatform,
        blockReels: Bool,
        blockShorts: Bool,
        blockAds: Bool
    ) -> String {

        /*
         IMPORTANTE

         Este archivo se ocupa únicamente de:

         - Instagram Reels
         - YouTube Shorts

         Los anuncios de YouTube se gestionan
         exclusivamente en YouTubeAdBlocker.swift.

         De esta manera evitamos dos sistemas
         distintos modificando simultáneamente
         el player de YouTube.
        */

        """
        (() => {

          const config = {

            reels:
              \(blockReels ? "true" : "false"),

            shorts:
              \(blockShorts ? "true" : "false")
          };


          // ============================================
          // HELPERS
          // ============================================

          const hide = (element) => {

            if (!element) {
              return;
            }


            if (
              element.dataset &&
              element.dataset.socialControlHidden ===
                "true"
            ) {

              return;
            }


            element.style.setProperty(
              "display",
              "none",
              "important"
            );


            if (element.dataset) {

              element.dataset.socialControlHidden =
                "true";
            }
          };


          // ============================================
          // DIRECT ROUTES
          // ============================================

          const blockRoutes = () => {

            const host =
              location.hostname.toLowerCase();

            const path =
              location.pathname.toLowerCase();


            // ----------------------------------------
            // INSTAGRAM REELS
            // ----------------------------------------

            if (
              config.reels &&
              host.includes("instagram.com") &&
              (
                path.startsWith("/reel/") ||
                path.startsWith("/reels")
              )
            ) {

              location.replace(
                "https://www.instagram.com/"
              );

              return true;
            }


            // ----------------------------------------
            // YOUTUBE SHORTS
            // ----------------------------------------

            if (
              config.shorts &&
              host.includes("youtube.com") &&
              (
                path === "/shorts" ||
                path === "/shorts/" ||
                path.startsWith("/shorts/")
              )
            ) {

              location.replace(
                "https://m.youtube.com/"
              );

              return true;
            }


            return false;
          };


          // ============================================
          // INSTAGRAM REELS
          // ============================================

          const cleanInstagram = () => {

            if (
              !config.reels ||
              !location.hostname.includes(
                "instagram.com"
              )
            ) {

              return;
            }


            document
              .querySelectorAll(
                'a[href^="/reel/"],' +
                'a[href^="/reels/"],' +
                'a[href="/reels"],' +
                'a[href="/reels/"]'
              )
              .forEach(link => {

                /*
                 Intentamos ocultar el elemento
                 relacionado con Reels sin eliminar
                 grandes zonas de Instagram.
                */

                const target =
                  link.closest("article") ||
                  link.closest(
                    'div[role="presentation"]'
                  ) ||
                  link.closest("nav") ||
                  link;


                hide(target);
              });
          };


          // ============================================
          // YOUTUBE SHORTS
          // ============================================

          const cleanYouTubeShorts = () => {

            if (
              !config.shorts ||
              !location.hostname.includes(
                "youtube.com"
              )
            ) {

              return;
            }


            /*
             Shelves completos de Shorts.
            */

            document
              .querySelectorAll(
                "ytm-reel-shelf-renderer," +
                "ytd-reel-shelf-renderer"
              )
              .forEach(hide);


            /*
             Links directos.
            */

            document
              .querySelectorAll(
                'a[href="/shorts"],' +
                'a[href="/shorts/"],' +
                'a[href^="/shorts/"]'
              )
              .forEach(link => {

                const rect =
                  link.getBoundingClientRect();


                /*
                 Si está en la barra inferior,
                 eliminamos únicamente el botón.
                */

                if (
                  rect.top >
                  window.innerHeight * 0.70
                ) {

                  let candidate =
                    link;


                  for (
                    let i = 0;
                    i < 5;
                    i++
                  ) {

                    if (
                      !candidate.parentElement
                    ) {

                      break;
                    }


                    const parent =
                      candidate.parentElement;

                    const parentRect =
                      parent.getBoundingClientRect();


                    if (
                      parentRect.width <
                        window.innerWidth * 0.55 &&
                      parentRect.height < 160
                    ) {

                      candidate =
                        parent;

                    } else {

                      break;
                    }
                  }


                  hide(candidate);

                  return;
                }


                /*
                 Si no está en la navegación inferior,
                 intentamos detectar tarjetas/shelves
                 relacionados con Shorts.
                */

                const card =
                  link.closest(
                    "ytm-video-with-context-renderer"
                  ) ||
                  link.closest(
                    "ytm-rich-item-renderer"
                  ) ||
                  link.closest(
                    "ytd-rich-item-renderer"
                  ) ||
                  link.closest(
                    "ytd-video-renderer"
                  );


                if (card) {

                  hide(card);
                }
              });


            /*
             FALLBACK VISUAL

             Algunas versiones móviles de YouTube
             no dejan un href fácil de detectar.

             Buscamos texto EXACTAMENTE "Shorts"
             únicamente en la zona inferior.
            */

            document
              .querySelectorAll(
                "a, button, span, div"
              )
              .forEach(element => {

                const text =
                  (
                    element.innerText ||
                    element.textContent ||
                    ""
                  )
                  .trim()
                  .toLowerCase();


                if (text !== "shorts") {

                  return;
                }


                const rect =
                  element.getBoundingClientRect();


                if (
                  rect.top <
                    window.innerHeight * 0.70 ||
                  rect.top >
                    window.innerHeight
                ) {

                  return;
                }


                let candidate =
                  element;


                for (
                  let i = 0;
                  i < 5;
                  i++
                ) {

                  if (
                    !candidate.parentElement
                  ) {

                    break;
                  }


                  const parent =
                    candidate.parentElement;

                  const parentRect =
                    parent.getBoundingClientRect();


                  if (
                    parentRect.width <
                      window.innerWidth * 0.55 &&
                    parentRect.height < 160
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
          // APPLY
          // ============================================

          const apply = () => {

            if (blockRoutes()) {

              return;
            }


            cleanInstagram();

            cleanYouTubeShorts();
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
           Primera aplicación.
          */

          apply();


          /*
           Instagram y YouTube modifican
           continuamente el DOM.
          */

          if (
            !window.__socialControlObserver
          ) {

            window.__socialControlObserver =
              new MutationObserver(
                schedule
              );


            window.__socialControlObserver.observe(
              document.documentElement,
              {
                childList: true,
                subtree: true
              }
            );
          }


          window.addEventListener(
            "popstate",
            schedule
          );


          window.addEventListener(
            "pageshow",
            schedule
          );


          document.addEventListener(
            "yt-navigate-finish",
            schedule
          );

        })();
        """
    }
}
