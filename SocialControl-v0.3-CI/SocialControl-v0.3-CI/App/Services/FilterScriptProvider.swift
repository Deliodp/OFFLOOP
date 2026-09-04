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
        """
        (() => {
          const config = {
            reels: \(blockReels ? "true" : "false"),
            shorts: \(blockShorts ? "true" : "false"),
            ads: \(blockAds ? "true" : "false")
          };

          const hide = (el) => {
            if (!el) return;
            el.style.setProperty('display', 'none', 'important');
          };

          const visibleText = (el) =>
            (
              (el?.innerText || el?.textContent || '') +
              ' ' +
              (el?.getAttribute?.('aria-label') || '')
            ).toLowerCase();

          // MARK: - ROUTE PROTECTION

          const blockRoutes = () => {
            const host = location.hostname;
            const path = location.pathname;

            // Instagram Reels
            if (
              host.includes('instagram.com') &&
              config.reels &&
              (
                path.startsWith('/reel/') ||
                path.startsWith('/reels')
              )
            ) {
              location.replace('https://www.instagram.com/');
              return true;
            }

            // YouTube Shorts
            if (
              host.includes('youtube.com') &&
              config.shorts &&
              (
                path === '/shorts' ||
                path === '/shorts/' ||
                path.startsWith('/shorts/')
              )
            ) {
              location.replace('https://m.youtube.com/');
              return true;
            }

            return false;
          };

          // MARK: - INSTAGRAM

          const cleanInstagram = () => {
            if (
              !config.reels ||
              !location.hostname.includes('instagram.com')
            ) return;

            document.querySelectorAll(
              'a[href^="/reel/"],' +
              'a[href^="/reels/"],' +
              'a[href="/reels"],' +
              'a[href="/reels/"]'
            ).forEach(a => {

              const target =
                a.closest('article') ||
                a.closest('div[role="presentation"]') ||
                a.closest('nav') ||
                a.closest('div') ||
                a;

              hide(target);
            });

            // Fallback por texto/aria-label
            document.querySelectorAll('a,button').forEach(el => {
              const text = visibleText(el);
              const href = el.getAttribute?.('href') || '';

              if (
                text === 'reels' ||
                text.includes(' reels') ||
                href.includes('/reel')
              ) {
                hide(
                  el.closest('div') ||
                  el.closest('nav') ||
                  el
                );
              }
            });
          };

          // MARK: - YOUTUBE SHORTS

          const cleanYouTubeShorts = () => {
            if (
              !config.shorts ||
              !location.hostname.includes('youtube.com')
            ) return;

            /*
             * YouTube tiene DOM diferente en:
             * - youtube.com
             * - m.youtube.com
             *
             * Cubrimos ambos.
             */

            const selectors = [
              'a[href="/shorts"]',
              'a[href="/shorts/"]',
              'a[href^="/shorts/"]',
              'a[href*="youtube.com/shorts"]',
              'a[title="Shorts"]',
              '[aria-label="Shorts"]',
              '[aria-label*="Shorts"]'
            ];

            selectors.forEach(selector => {

              document.querySelectorAll(selector).forEach(el => {

                const target =
                  // Mobile YouTube
                  el.closest('ytm-pivot-bar-item-renderer') ||
                  el.closest('ytm-reel-shelf-renderer') ||
                  el.closest('ytm-rich-item-renderer') ||
                  el.closest('ytm-video-with-context-renderer') ||

                  // Desktop YouTube
                  el.closest('ytd-reel-shelf-renderer') ||
                  el.closest('ytd-rich-shelf-renderer') ||
                  el.closest('ytd-rich-item-renderer') ||
                  el.closest('ytd-video-renderer') ||
                  el.closest('ytd-guide-entry-renderer') ||
                  el.closest('ytd-mini-guide-entry-renderer') ||

                  // Generic fallback
                  el.closest('nav') ||
                  el.parentElement ||
                  el;

                hide(target);
              });
            });

            // Estanterías/carruseles completas
            document.querySelectorAll(
              'ytm-reel-shelf-renderer,' +
              'ytd-reel-shelf-renderer,' +
              'ytd-rich-shelf-renderer[is-shorts]'
            ).forEach(hide);

            /*
             * Fallback especial para barra inferior móvil.
             *
             * Algunas versiones de YouTube generan Shorts sin un href
             * fácilmente detectable pero mantienen el texto "Shorts".
             */
            document.querySelectorAll(
              'ytm-pivot-bar-item-renderer,' +
              'a,' +
              'button'
            ).forEach(el => {

              const text = visibleText(el);
              const href = el.getAttribute?.('href') || '';

              if (
                text === 'shorts' ||
                href === '/shorts' ||
                href === '/shorts/' ||
                href.startsWith('/shorts/')
              ) {

                const target =
                  el.closest('ytm-pivot-bar-item-renderer') ||
                  el.closest('ytd-guide-entry-renderer') ||
                  el;

                hide(target);
              }
            });
          };

          // MARK: - YOUTUBE ADS

          const cleanYouTubeAds = () => {
            if (
              !config.ads ||
              !location.hostname.includes('youtube.com')
            ) return;

            /*
             * Conservador:
             * ocultamos elementos publicitarios del DOM
             * y usamos el botón Skip de YouTube cuando existe.
             *
             * NO bloqueamos googlevideo.com porque podría
             * romper vídeos normales.
             */

            const selectors = [
              '.ytp-ad-module',
              '.ytp-ad-overlay-container',
              '.ytp-ad-player-overlay',

              'ytd-ad-slot-renderer',
              'ytd-display-ad-renderer',
              'ytd-promoted-video-renderer',
              'ytd-in-feed-ad-layout-renderer',
              'ytd-banner-promo-renderer',
              'ytd-action-companion-ad-renderer',

              'ytm-promoted-sparkles-web-renderer',
              'ytm-promoted-video-renderer',
              'ytm-companion-ad-renderer'
            ];

            selectors.forEach(selector => {
              document
                .querySelectorAll(selector)
                .forEach(hide);
            });

            // Pulsamos únicamente el botón oficial de saltar anuncio.
            document.querySelectorAll(
              '.ytp-ad-skip-button,' +
              '.ytp-ad-skip-button-modern,' +
              'button.ytp-skip-ad-button'
            ).forEach(button => {

              if (
                button instanceof HTMLElement &&
                !button.disabled
              ) {
                button.click();
              }
            });
          };

          // MARK: - APPLY

          const apply = () => {

            if (blockRoutes()) {
              return;
            }

            cleanInstagram();
            cleanYouTubeShorts();
            cleanYouTubeAds();
          };

          /*
           * Instagram y YouTube son SPA:
           * modifican la página constantemente sin recargarla.
           *
           * MutationObserver vuelve a aplicar los filtros
           * cuando cambia el DOM.
           */

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

          apply();

          if (!window.__socialControlObserver) {

            window.__socialControlObserver =
              new MutationObserver(schedule);

            window.__socialControlObserver.observe(
              document.documentElement,
              {
                childList: true,
                subtree: true,
                attributes: false
              }
            );
          }

          /*
           * Reaplicar cuando el usuario navega
           * dentro de la SPA.
           */

          window.addEventListener(
            'popstate',
            schedule
          );

          window.addEventListener(
            'pageshow',
            schedule
          );

          window.addEventListener(
            'hashchange',
            schedule
          );

        })();
        """
    }
}
