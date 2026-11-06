#!/bin/sh
# Ad-hoc signs the app inside an unsigned .xcarchive so that
# `xcodebuild -exportArchive` can re-sign it with a cloud-managed distribution
# certificate (App Store Connect API keys can export, but not archive).
#
#   scripts/adhoc_sign_archive.sh path/to/App.xcarchive TEAM_ID BUNDLE_ID
set -eu

archive="$1"
team="$2"
bundle="$3"

app=$(find "$archive/Products/Applications" -maxdepth 1 -name '*.app' | head -n 1)
if [ -z "$app" ]; then
  echo "::error::No .app found in $archive/Products/Applications"
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Nested code first (inside out). This app has none today, but keep it generic.
find "$app" -depth \( -name '*.framework' -o -name '*.dylib' -o -name '*.appex' \) -print | while read -r nested; do
  codesign --force --sign - --timestamp=none "$nested"
done

# Xcode normally adds these two entitlements when it signs; export expects them.
ent="$tmp/entitlements.plist"
/usr/libexec/PlistBuddy \
  -c "Add :application-identifier string $team.$bundle" \
  -c "Add :com.apple.developer.team-identifier string $team" \
  "$ent" >/dev/null

codesign --force --sign - --timestamp=none --generate-entitlement-der --entitlements "$ent" "$app"
codesign --verify --deep --strict "$app"
echo "Ad-hoc signed $(basename "$app") as $team.$bundle"
