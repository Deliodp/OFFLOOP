# V0.2 — Feature acceptance

The product is NOT considered ready until all four core features pass on a real iPhone.

## 1. Instagram Reels OFF
PASS only if:
- Instagram login works.
- Login survives app relaunch.
- Home feed works.
- Search/profile/messages web experience remains usable.
- Reels navigation disappears where detectable.
- Direct `/reel/...` and `/reels` routes are redirected away.
- No redirect loop.

## 2. YouTube Shorts OFF
PASS only if:
- YouTube login works and persists.
- Normal long-form videos play.
- Search/subscriptions/history remain usable.
- Shorts shelves/navigation disappear where detectable.
- Direct `/shorts/...` routes are redirected away.
- Fullscreen playback still works.

## 3. YouTube Ads OFF — Premium
PASS only if:
- Normal videos still start.
- No broad video CDN blocking is used.
- Page/banner ads are removed.
- Known ad endpoints are blocked conservatively.
- YouTube's own Skip button is pressed when available.
- At least 20 monetized-video tests are run.
- Playback breakage rate is 0%.

Important: YouTube changes ad delivery frequently. Do not market a permanent 100% guarantee until real-device testing supports it.

## 4. Insights
PASS only if:
- Screen Time authorization works.
- User selects Instagram + YouTube once via Apple's Family Activity picker.
- Selection persists.
- Device Activity report renders real, non-hardcoded usage values.
- No fake analytics appear in release builds.
- Privacy copy accurately matches Apple API behavior.

## 5. Session persistence — cross-cutting requirement
PASS only if:
- WKWebsiteDataStore.default() keeps Instagram/YouTube sessions across relaunches.
- The app never asks for platform passwords itself outside the platform webpage.
- No credentials are sent to an app-owned server.
