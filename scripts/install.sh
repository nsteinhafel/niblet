#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Generating Xcode project..."
xcodegen generate --spec "$PROJECT_DIR/project.yml" --project "$PROJECT_DIR"

echo "Building Niblet..."
xcodebuild -project "$PROJECT_DIR/Niblet.xcodeproj" -scheme Niblet -configuration Debug build -quiet

BUILD_DIR=$(xcodebuild -project "$PROJECT_DIR/Niblet.xcodeproj" -scheme Niblet -configuration Debug -showBuildSettings 2>/dev/null | grep -m1 "BUILT_PRODUCTS_DIR" | awk '{print $3}')

echo "Installing to /Applications..."
rm -rf /Applications/Niblet.app
ditto "$BUILD_DIR/Niblet.app" /Applications/Niblet.app

echo "Verifying signature..."
codesign -vv /Applications/Niblet.app

echo "Done."
