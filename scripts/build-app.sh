#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
APP_NAME="声锚 SoundAnchor"
BUILD_DIR="/private/tmp/soundanchor-app-build"
DIST_DIR="$ROOT/dist"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
DIST_APP="$DIST_DIR/$APP_NAME.app"
VERSION="$(plutil -extract CFBundleShortVersionString raw "$ROOT/App/Info.plist")"
DMG_PATH="$DIST_DIR/SoundAnchor-$VERSION-macOS.dmg"
DMG_STAGING_DIR="/private/tmp/soundanchor-dmg-staging"

rm -rf "$BUILD_DIR" "$DIST_APP" "$DMG_STAGING_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR" "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$ROOT/Assets/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
ditto "$ROOT/App/Resources" "$APP_DIR/Contents/Resources"

cd "$ROOT"
CLANG_MODULE_CACHE_PATH=/private/tmp/soundanchor-clang-cache \
SWIFT_MODULECACHE_PATH=/private/tmp/soundanchor-swift-cache \
swift build --disable-sandbox -c release --arch arm64
CLANG_MODULE_CACHE_PATH=/private/tmp/soundanchor-clang-cache \
SWIFT_MODULECACHE_PATH=/private/tmp/soundanchor-swift-cache \
swift build --disable-sandbox -c release --arch x86_64
ARM_BIN="$ROOT/.build/arm64-apple-macosx/release/SoundAnchor"
INTEL_BIN="$ROOT/.build/x86_64-apple-macosx/release/SoundAnchor"

lipo -create "$ARM_BIN" "$INTEL_BIN" -output "$APP_DIR/Contents/MacOS/SoundAnchor"
cp "$ROOT/App/Info.plist" "$APP_DIR/Contents/Info.plist"
chmod 755 "$APP_DIR/Contents/MacOS/SoundAnchor"
xattr -cr "$APP_DIR"
codesign --force --deep --sign - "$APP_DIR"
xattr -cr "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"

ditto "$APP_DIR" "$DIST_APP"
xattr -cr "$DIST_APP"
codesign --force --deep --sign - "$DIST_APP"
xattr -cr "$DIST_APP"
codesign --verify --deep --strict "$DIST_APP"

mkdir -p "$DMG_STAGING_DIR"
ditto "$APP_DIR" "$DMG_STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$DMG_STAGING_DIR/Applications"
rm -f "$DMG_PATH"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING_DIR" \
    -format UDZO \
    -ov \
    "$DMG_PATH"
hdiutil verify "$DMG_PATH"

echo "$DIST_APP"
echo "$DMG_PATH"
