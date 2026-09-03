#!/bin/zsh
set -euo pipefail

xcodegen generate

xcodebuild \
  -project SocialControl.xcodeproj \
  -scheme SocialControl \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  clean build

xcodebuild \
  -project SocialControl.xcodeproj \
  -scheme SocialControlTests \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  test
