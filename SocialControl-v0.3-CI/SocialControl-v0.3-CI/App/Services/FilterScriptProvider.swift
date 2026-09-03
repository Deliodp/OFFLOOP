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
            ((el?.innerText || el?.textContent || '') + ' ' + (el?.getAttribute?.('aria-label') || '')).toLowerCase();

          const blockRoutes = () => {
            const host = location.hostname;
            const path = location.pathname;

            if (host.includes('instagram.com') && config.reels &&
                (path.startsWith('/reel/') || path.startsWith('/reels'))) {
              location.replace('https://www.instagram.com/');
              return true;
            }

            if (host.includes('youtube.com') && config.shorts &&
                path.startsWith('/shorts')) {
              location.replace('https://www.youtube.com/');
              return true;
            }

            return false;
          };

          const cleanInstagram = () => {
            if (!config.reels || !location.hostname.includes('instagram.com')) return;

            document.querySelectorAll(
              'a[href^="/reel/"],a[href^="/reels/"],a[href="/reels/"]'
            ).forEach(a => {
              const target =
                a.closest('article') ||
                a.closest('div[role="presentation"]') ||
                a.closest('nav') ||
                a.closest('div') ||
                a;
              hide(target);
            });

            // Fallback for navigation elements when route selectors change.
            document.querySelectorAll('a,button').forEach(el => {
              const text = visibleText(el);
              if (text === 'reels' || text.includes(' reels')) {
                const href = el.getAttribute?.('href') || '';
                if (href.includes('/reel')) hide(el.closest('div') || el);
              }
            });
          };

          const cleanYouTubeShorts = () => {
            if (!config.shorts || !location.hostname.includes('youtube.com')) return;

            document.querySelectorAll(
              'a[href^="/shorts/"],a[href*="youtube.com/shorts/"],a[title="Shorts"]'
            ).forEach(a => {
              const target =
                a.closest('ytd-reel-shelf-renderer') ||
                a.closest('ytd-rich-shelf-renderer') ||
                a.closest('ytd-rich-item-renderer') ||
                a.closest('ytd-video-renderer') ||
                a.closest('ytd-guide-entry-renderer') ||
                a.closest('ytd-mini-guide-entry-renderer') ||
                a;
              hide(target);
            });

            document.querySelectorAll('ytd-reel-shelf-renderer').forEach(hide);
        };

          const cleanYouTubeAds = () => {
            if (!config.ads || !location.hostname.includes('youtube.com')) return;

            const selectors = [
              '.ytp-ad-module',
              '.ytp-ad-overlay-container',
              '.ytp-ad-player-overlay',
              'ytd-ad-slot-renderer',
              'ytd-display-ad-renderer',
              'ytd-promoted-video-renderer',
              'ytd-in-feed-ad-layout-renderer',
              'ytd-banner-promo-renderer',
              'ytd-action-companion-ad-renderer'
            ];

            selectors.forEach(selector => {
              document.querySelectorAll(selector).forEach(hide);
            });

            // We only trigger YouTube's own skip control when it exists.
            document.querySelectorAll(
              '.ytp-ad-skip-button,.ytp-ad-skip-button-modern,button.ytp-skip-ad-button'
            ).forEach(button => {
              if (button instanceof HTMLElement && !button.disabled) button.click();
            });
          };

          const apply = () => {
            if (blockRoutes()) return;
            cleanInstagram();
            cleanYouTubeShorts();
            cleanYouTubeAds();
          };

          let scheduled = false;
          const schedule = () => {
            if (scheduled) return;
            scheduled = true;
            requestAnimationFrame(() => {
              scheduled = false;
              apply();
            });
          };

          apply();

          if (!window.__socialControlObserver) {
            window.__socialControlObserver = new MutationObserver(schedule);
            window.__socialControlObserver.observe(document.documentElement, {
              childList: true,
              subtree: true
            });
          }

          window.addEventListener('popstate', schedule);
          window.addEventListener('pageshow', schedule);
        })();
        """
    }
}
