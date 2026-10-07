#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/dist/MX Jiggler.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
mkdir -p "$MACOS"
mkdir -p "$ROOT/.build/module-cache"
cp "$ROOT/Info.plist" "$CONTENTS/Info.plist"
xcrun swiftc "$ROOT"/Sources/*.swift -o "$MACOS/MXJiggler" \
  -O -target "$(uname -m)-apple-macosx11.0" \
  -module-cache-path "$ROOT/.build/module-cache" \
  -framework AppKit -framework ApplicationServices
codesign --force --sign "${SIGNING_IDENTITY:--}" "$APP"
codesign --verify --strict "$APP"
echo "Built: $APP"
