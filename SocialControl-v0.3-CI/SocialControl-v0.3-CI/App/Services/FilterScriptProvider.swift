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

          const hide = (element) => {
            if (!element) return;

            if (element.dataset?.socialControlHidden === "true") {
              return;
            }

            element.style.setProperty(
              "display",
              "none",
              "important"
            );

            if (element.dataset) {
              element.dataset.socialControlHidden = "true";
            }
          };


          // --------------------------------------------------
          // ROUTE PROTECTION
          // --------------------------------------------------

          const blockRoutes = () => {

            const host = location.hostname;
            const path = location.pathname;

            // Instagram Reels
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


            // YouTube Shorts
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


          // --------------------------------------------------
          // INSTAGRAM REELS
          // --------------------------------------------------

          const cleanInstagram = () => {

            if (
              !config.reels ||
              !location.hostname.includes("instagram.com")
            ) {
              return;
            }


            document.querySelectorAll(
              'a[href^="/reel/"],' +
              'a[href^="/reels/"],' +
              'a[href="/reels"],' +
              'a[href="/reels/"]'
            ).forEach((link) => {

              const navigationItem =
                link.closest("nav > div") ||
                link.closest('div[role="presentation"]') ||
                link.closest("article") ||
                link;

              hide(navigationItem);
            });
          };


          // --------------------------------------------------
          // YOUTUBE SHORTS
          // --------------------------------------------------

          const cleanYouTubeShorts = () => {

            if (
              !config.shorts ||
              !location.hostname.includes("youtube.com")
            ) {
              return;
            }


            /*
             MOBILE YOUTUBE
             Bottom navigation item:
             Home | Shorts | You
            */

            document
              .querySelectorAll(
                'ytm-pivot-bar-item-renderer a[href="/shorts"],' +
                'ytm-pivot-bar-item-renderer a[href="/shorts/"],' +
                'ytm-pivot-bar-item-renderer a[href^="/shorts/"]'
              )
              .forEach((link) => {

                const item =
                  link.closest(
                    "ytm-pivot-bar-item-renderer"
                  );

                hide(item);
              });


            /*
             Some mobile builds put the href directly
             on another element inside the navigation item.
            */

            document
              .querySelectorAll(
                'a[href="/shorts"],' +
                'a[href="/shorts/"]'
              )
              .forEach((link) => {

                const mobileNav =
                  link.closest(
                    "ytm-pivot-bar-item-renderer"
                  );

                if (mobileNav) {
                  hide(mobileNav);
                }
              });


            /*
             MOBILE SHORTS SHELVES
            */

            document
              .querySelectorAll(
                "ytm-reel-shelf-renderer"
              )
              .forEach(hide);


            /*
             DESKTOP SHORTS NAVIGATION
            */

            document
              .querySelectorAll(
                'ytd-guide-entry-renderer a[href="/shorts"],' +
                'ytd-mini-guide-entry-renderer a[href="/shorts"]'
              )
              .forEach((link) => {

                const item =
                  link.closest(
                    "ytd-guide-entry-renderer"
                  ) ||
                  link.closest(
                    "ytd-mini-guide-entry-renderer"
                  );

                hide(item);
              });


            /*
             DESKTOP SHORTS SHELVES
            */

            document
              .querySelectorAll(
                "ytd-reel-shelf-renderer"
              )
              .forEach(hide);
          };


          // --------------------------------------------------
          // YOUTUBE ADS
          // --------------------------------------------------

          const cleanYouTubeAds = () => {

            if (
              !config.ads ||
              !location.hostname.includes("youtube.com")
            ) {
              return;
            }


            const selectors = [

              ".ytp-ad-module",
              ".ytp-ad-overlay-container",
              ".ytp-ad-player-overlay",

              "ytd-ad-slot-renderer",
              "ytd-display-ad-renderer",
              "ytd-promoted-video-renderer",
              "ytd-in-feed-ad-layout-renderer",
              "ytd-banner-promo-renderer",
              "ytd-action-companion-ad-renderer",

              "ytm-promoted-video-renderer",
              "ytm-companion-ad-renderer"
            ];


            selectors.forEach((selector) => {

              document
                .querySelectorAll(selector)
                .forEach(hide);
            });


            /*
             Only use YouTube's own Skip button.
             We do NOT block googlevideo.com.
            */

            document
              .querySelectorAll(
                ".ytp-ad-skip-button," +
                ".ytp-ad-skip-button-modern," +
                "button.ytp-skip-ad-button"
              )
              .forEach((button) => {

                if (
                  button instanceof HTMLElement &&
                  !button.disabled
                ) {
                  button.click();
                }
              });
          };


          // --------------------------------------------------
          // APPLY
          // --------------------------------------------------

          const apply = () => {

            if (blockRoutes()) {
              return;
            }

            cleanInstagram();
            cleanYouTubeShorts();
            cleanYouTubeAds();
          };


          // --------------------------------------------------
          // OBSERVER
          // --------------------------------------------------

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

        })();
        """
    }
}
