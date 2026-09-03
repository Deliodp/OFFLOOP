# Engineering Gates

No feature moves forward unless the previous gate passes.

## Gate 0 — Product scope
Frozen:
- Instagram Reels OFF
- YouTube Shorts OFF
- YouTube Ads OFF (Premium)
- Insights
- Session persistence

No new platforms or major features before Gate 4.

## Gate 1 — Cloud compilation
Must pass:
- XcodeGen generation.
- App target builds for iOS Simulator.
- Safari extension compiles.
- Device Activity Report extension compiles.
- Unit tests pass.

## Gate 2 — Core navigation
On simulator/device:
- Onboarding works.
- Home opens.
- Insights opens.
- Settings do not crash.
- Premium UI behaves correctly.

## Gate 3 — Platform behavior
On real iPhone:
- Instagram session persists.
- YouTube session persists.
- Reels removal passes acceptance.
- Shorts removal passes acceptance.

## Gate 4 — Premium + Insights
On real iPhone:
- YouTube ad blocking tested on at least 20 monetized videos.
- Zero normal-playback breakage.
- Screen Time authorization works.
- Real Device Activity values render.
- No hardcoded analytics in release.

## Gate 5 — App Store readiness
Only after Gates 1–4:
- Final name.
- Final icon.
- Privacy policy.
- App Store screenshots.
- StoreKit production product.
- Apple Developer membership.
- TestFlight.
- App Review.
