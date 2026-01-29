#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCT="DefaultOpener"

cd "$ROOT"

VERSION="${VERSION:-}"
if [[ -z "$VERSION" ]]; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    TAG="$(git describe --tags --abbrev=0 2>/dev/null || true)"
    if [[ "$TAG" =~ ^v[0-9] ]]; then
      VERSION="${TAG#v}"
    fi
  fi
fi
VERSION="${VERSION:-0.1.0}"

REV="$(git rev-parse --short HEAD 2>/dev/null || echo dev)"
DIST="$ROOT/dist"
APP_DIR="$DIST/${PRODUCT}.app"

mkdir -p "$DIST"
rm -rf "$APP_DIR"

echo "Building (release)…"
swift build -c release

BIN="$ROOT/.build/release/$PRODUCT"
if [[ ! -x "$BIN" ]]; then
  echo "ERROR: executable not found at $BIN" >&2
  exit 1
fi

echo "Creating .app bundle…"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN" "$APP_DIR/Contents/MacOS/$PRODUCT"

if [[ -f "$ROOT/Assets/DefaultOpener.icns" ]]; then
  cp "$ROOT/Assets/DefaultOpener.icns" "$APP_DIR/Contents/Resources/DefaultOpener.icns"
fi

cat >"$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${PRODUCT}</string>
  <key>CFBundleIdentifier</key>
  <string>com.ryderwe.defaultopener</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${PRODUCT}</string>
  <key>CFBundleDisplayName</key>
  <string>${PRODUCT}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${VERSION}-${REV}</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.utilities</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>CFBundleIconFile</key>
  <string>DefaultOpener</string>
</dict>
</plist>
PLIST

touch "$APP_DIR"

if command -v codesign >/dev/null 2>&1; then
  echo "Codesigning (ad-hoc)…"
  codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true
fi

echo "Creating DMG…"
DMG_ROOT="$DIST/dmg-root"
rm -rf "$DMG_ROOT"
mkdir -p "$DMG_ROOT"
cp -R "$APP_DIR" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"

DMG_OUT="$DIST/${PRODUCT}-${VERSION}.dmg"
rm -f "$DMG_OUT"
hdiutil create -volname "$PRODUCT" -srcfolder "$DMG_ROOT" -ov -format UDZO "$DMG_OUT" >/dev/null

ZIP_OUT="$DIST/${PRODUCT}-${VERSION}.zip"
rm -f "$ZIP_OUT"
(cd "$DIST" && ditto -c -k --sequesterRsrc --keepParent "${PRODUCT}.app" "$(basename "$ZIP_OUT")")

echo "Done:"
echo "  $DMG_OUT"
echo "  $ZIP_OUT"

