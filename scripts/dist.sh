#!/bin/bash
set -e

# Builds a Release Niblet.app, ad-hoc signs it with hardened runtime, and zips
# it for handoff to another Mac. Ad-hoc signatures don't expire, unlike free
# "Apple Development" certs, so the app keeps launching.
#
# On the target Mac, move Niblet.app into /Applications, then run:
#   xattr -dr com.apple.quarantine /Applications/Niblet.app
# and grant Accessibility in System Settings > Privacy & Security > Accessibility.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$PROJECT_DIR/dist"

echo "Generating Xcode project..."
xcodegen generate --spec "$PROJECT_DIR/project.yml" --project "$PROJECT_DIR"

echo "Building Niblet (Release)..."
xcodebuild -project "$PROJECT_DIR/Niblet.xcodeproj" -scheme Niblet -configuration Release build -quiet

BUILD_DIR=$(xcodebuild -project "$PROJECT_DIR/Niblet.xcodeproj" -scheme Niblet -configuration Release -showBuildSettings 2>/dev/null | grep -m1 "BUILT_PRODUCTS_DIR" | awk '{print $3}')
APP="$BUILD_DIR/Niblet.app"

echo "Ad-hoc signing with hardened runtime..."
# No --deep: the bundle has no nested code, and Apple discourages deep signing
codesign --force --options runtime -s - "$APP"

echo "Verifying signature..."
codesign -vv "$APP"

echo "Packaging for handoff..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
ditto "$APP" "$DIST_DIR/Niblet.app"
ditto -c -k --keepParent "$DIST_DIR/Niblet.app" "$DIST_DIR/Niblet.zip"

echo ""
echo "Done. Hand off: $DIST_DIR/Niblet.zip"
echo "On the target Mac: unzip, move Niblet.app to /Applications, then run:"
echo "  xattr -dr com.apple.quarantine /Applications/Niblet.app"
echo "Then approve it under System Settings > Privacy & Security > Accessibility."
