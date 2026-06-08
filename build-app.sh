#!/bin/bash
# Build .app bundle: Swift app + Info.plist, ad-hoc signed.
# Usage: build-app.sh [release|debug]   (default: release)
set -euo pipefail

CONFIG="${1:-release}"
case "$CONFIG" in
    release|debug) ;;
    *) echo "Usage: $0 [release|debug]" >&2; exit 1 ;;
esac

APP_NAME="Tmac"
SWIFT_TARGET="Tmac"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="$SCRIPT_DIR/bin"
APP_DIR="$OUT_DIR/$APP_NAME.app"

echo ">>> Building Swift app ($CONFIG)"
( cd "$SCRIPT_DIR" && swift build -c "$CONFIG" )

SWIFT_BIN="$SCRIPT_DIR/.build/$CONFIG/$SWIFT_TARGET"
if [[ ! -x "$SWIFT_BIN" ]]; then
    echo "Swift build did not produce expected binary: $SWIFT_BIN" >&2
    exit 1
fi

echo ">>> Assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$SWIFT_BIN" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$SCRIPT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
[ -f "$SCRIPT_DIR/Resources/AppIcon.icns" ] && cp "$SCRIPT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/"

echo ">>> Ad-hoc signing"
codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo ">>> Done: $APP_DIR ($CONFIG)"
