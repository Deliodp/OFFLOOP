# SocialControl v0.3 — CI foundation

Codename project. Final product name is intentionally not chosen yet.

## Core-only build
This revision is organized around exactly four features:
1. Instagram Reels OFF
2. YouTube Shorts OFF
3. YouTube Ads OFF (Premium)
4. Insights (Screen Time)

No TikTok. No X. No social accounts. No extra tabs.

## Architecture
- SwiftUI app
- Persistent WKWebView sessions via WKWebsiteDataStore.default()
- JavaScript DOM filtering for Reels / Shorts
- WKContentRuleList + DOM cleanup for internal YouTube ad reduction
- Safari Web Extension with Declarative Net Request
- StoreKit 2 lifetime Premium purchase
- FamilyControls + DeviceActivityReport extension for real Screen Time data

## Important reality check
This source has not yet been compiled with Xcode or tested on a real iPhone.
That is the next hard gate. A source code claim is not proof that Instagram/YouTube still work after their next frontend change.

## Before first build
Replace:
- com.yourcompany.SocialControl
- com.yourcompany.SocialControl.Safari
- com.yourcompany.SocialControl.Report
- group.com.yourcompany.SocialControl
- com.yourcompany.SocialControl.lifetime
- APP NAME

Apple capabilities needed:
- App Groups
- Family Controls
- StoreKit / In-App Purchase
- Safari Web Extension
- Device Activity Report extension

## Generate project on macOS
```bash
brew install xcodegen
xcodegen generate
open SocialControl.xcodeproj
```

DEBUG Premium:
Add launch argument:
`-unlockPremium`


## New in v0.3
- GitHub Actions macOS compilation.
- Automatic iOS Simulator build.
- Unit tests for core filter contracts.
- Structural safety checks.
- Engineering gates.
- A free no-Mac compilation workflow.

Start with `GITHUB_BUILD_NO_MAC.md`.
