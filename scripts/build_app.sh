#!/usr/bin/env bash
#
# build_app.sh — assemble a distributable LiquidGlassDemo.app from the SwiftPM
# build. Produces dist/LiquidGlassDemo.app with an Info.plist, an AppIcon.icns,
# the embedded Sparkle framework, and (if a Developer ID is configured in app.yml)
# a hardened-runtime code signature.
#
# Usage:
#   scripts/build_app.sh [--version X.Y.Z] [--build N]
#
# Without a configured Developer ID it emits an UNSIGNED bundle — fine for local
# testing, not for distribution. See RELEASE.md for the full pipeline.
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="app.yml"
yaml_get() { sed -n "s/^$1:[[:space:]]*\"\{0,1\}\([^\"#]*[^\"# ]\)\"\{0,1\}.*/\1/p" "$CONFIG" | head -1; }

APP_NAME="$(yaml_get app_name)"
EXECUTABLE="$(yaml_get executable)"
BUNDLE_ID="$(yaml_get bundle_identifier)"
CATEGORY="$(yaml_get category)"
MIN_OS="$(yaml_get minimum_system_version)"
FEED_URL="$(yaml_get feed_url)"
ED_KEY="$(yaml_get sparkle_public_ed_key)"
DEV_ID="$(yaml_get developer_id_application)"

VERSION="1.0.0"
BUILD="1"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --build)   BUILD="$2";   shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

DIST="dist"
APP="$DIST/$APP_NAME.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RES="$CONTENTS/Resources"
FW="$CONTENTS/Frameworks"

echo "==> Building $APP_NAME $VERSION ($BUILD)"
rm -rf "$APP"
mkdir -p "$MACOS" "$RES" "$FW"

# 1. Release binary.
swift build -c release --product "$EXECUTABLE"
BIN_DIR="$(swift build -c release --show-bin-path)"
cp "$BIN_DIR/$EXECUTABLE" "$MACOS/$EXECUTABLE"

# 2. Embed Sparkle and point the executable at Contents/Frameworks.
SPARKLE_FW="$(find .build/artifacts -path '*Sparkle.xcframework*/macos-*/Sparkle.framework' -type d | head -1)"
[[ -n "$SPARKLE_FW" ]] || { echo "Sparkle.framework not found — run 'swift build' first" >&2; exit 1; }
cp -R "$SPARKLE_FW" "$FW/"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$MACOS/$EXECUTABLE" 2>/dev/null || true

# 3. App icon: render the SwiftUI icon to PNG (via the app itself), then icns.
ICON_PNG="$(mktemp -t icon).png"
"$MACOS/$EXECUTABLE" --icon "$ICON_PNG"
ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z "$s" "$s"           "$ICON_PNG" --out "$ICONSET/icon_${s}x${s}.png"    >/dev/null
  sips -z "$((s*2))" "$((s*2))" "$ICON_PNG" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$RES/AppIcon.icns"

# 4. Info.plist. The Sparkle keys are written only when a real Ed25519 public key
#    is configured — otherwise the app would start Sparkle with an invalid key and
#    show a configuration error at launch. Without them, Updater stays dormant.
SPARKLE_KEYS=""
if [[ -n "$ED_KEY" && "$ED_KEY" != *"TODO"* ]]; then
  SPARKLE_KEYS="    <key>SUFeedURL</key><string>$FEED_URL</string>
    <key>SUPublicEDKey</key><string>$ED_KEY</string>
    <key>SUEnableInstallerLauncherService</key><true/>"
else
  echo "ℹ️  Sparkle keys omitted (sparkle_public_ed_key not set) — auto-update stays off in this build."
fi

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleDisplayName</key><string>$APP_NAME</string>
    <key>CFBundleExecutable</key><string>$EXECUTABLE</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$BUILD</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>$MIN_OS</string>
    <key>LSApplicationCategoryType</key><string>$CATEGORY</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
$SPARKLE_KEYS
</dict>
</plist>
PLIST

# 5. PkgInfo.
printf 'APPL????' > "$CONTENTS/PkgInfo"

# 6. Code signing (only when a real Developer ID is configured).
if [[ "$DEV_ID" == *"YOUR NAME"* || -z "$DEV_ID" ]]; then
  echo "⚠️  UNSIGNED build — set developer_id_application in app.yml to sign (see RELEASE.md)."
else
  echo "==> Signing with: $DEV_ID"
  SP_VER="$FW/Sparkle.framework/Versions/B"
  # Sparkle's nested helpers must be signed first, then the framework, then the app.
  for item in \
    "$SP_VER/XPCServices/Installer.xpc" \
    "$SP_VER/XPCServices/Downloader.xpc" \
    "$SP_VER/Autoupdate" \
    "$SP_VER/Updater.app"; do
    [[ -e "$item" ]] && codesign -f -o runtime --timestamp -s "$DEV_ID" "$item"
  done
  codesign -f -o runtime --timestamp -s "$DEV_ID" "$FW/Sparkle.framework"
  codesign -f -o runtime --timestamp -s "$DEV_ID" "$MACOS/$EXECUTABLE"
  codesign -f -o runtime --timestamp -s "$DEV_ID" "$APP"
  codesign --verify --deep --strict --verbose=2 "$APP"
fi

echo "==> Built $APP"
