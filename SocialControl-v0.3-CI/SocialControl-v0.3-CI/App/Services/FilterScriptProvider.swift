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

          const blockRoutes = () => {
            const host = location.hostname;
            const path = location.pathname;

            if (
              config.reels &&
              host.includes("instagram.com") &&
              (
                path.startsWith("/reel/") ||
                path.startsWith("/reels")
              )
            ) {
              location.replace("https://www.instagram.com/");
              return true;
            }

            if (
              config.shorts &&
              host.includes("youtube.com") &&
              (
                path === "/shorts" ||
                path === "/shorts/" ||
                path.startsWith("/shorts/")
              )
            ) {
              location.replace("https://m.youtube.com/");
              return true;
            }

            return false;
          };

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

              const target =
                link.closest("article") ||
                link.closest('div[role="presentation"]') ||
                link.closest("nav") ||
                link;

              hide(target);
            });
          };

          const cleanYouTubeShorts = () => {

            if (
              !config.shorts ||
              !location.hostname.includes("youtube.com")
            ) {
              return;
            }

            document.querySelectorAll(
              "ytm-reel-shelf-renderer," +
              "ytd-reel-shelf-renderer"
            ).forEach(hide);

            document.querySelectorAll(
              'a[href="/shorts"],' +
              'a[href="/shorts/"],' +
              'a[href^="/shorts/"]'
            ).forEach((link) => {

              const rect = link.getBoundingClientRect();

              if (rect.top > window.innerHeight * 0.70) {

                let candidate = link;

                for (let i = 0; i < 5; i++) {

                  if (!candidate.parentElement) break;

                  const parent = candidate.parentElement;
                  const parentRect = parent.getBoundingClientRect();

                  if (
                    parentRect.width < window.innerWidth * 0.55 &&
                    parentRect.height < 160
                  ) {
                    candidate = parent;
                  } else {
                    break;
                  }
                }

                hide(candidate);
              }
            });

            document.querySelectorAll(
              "a,button,span,div"
            ).forEach((element) => {

              const text =
                (element.innerText || element.textContent || "")
                  .trim()
                  .toLowerCase();

              if (text !== "shorts") {
                return;
              }

              const rect = element.getBoundingClientRect();

              if (
                rect.top < window.innerHeight * 0.70 ||
                rect.top > window.innerHeight
              ) {
                return;
              }

              let candidate = element;

              for (let i = 0; i < 5; i++) {

                if (!candidate.parentElement) break;

                const parent = candidate.parentElement;
                const parentRect = parent.getBoundingClientRect();

                if (
                  parentRect.width < window.innerWidth * 0.55 &&
                  parentRect.height < 160
                ) {
                  candidate = parent;
                } else {
                  break;
                }
              }

              hide(candidate);
            });
          };

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

          const apply = () => {

            if (blockRoutes()) {
              return;
            }

            cleanInstagram();
            cleanYouTubeShorts();
            cleanYouTubeAds();
          };

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

          window.addEventListener("popstate", schedule);
          window.addEventListener("pageshow", schedule);

        })();
        """
    }
}
