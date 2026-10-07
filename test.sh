#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$ROOT/.build/module-cache"
xcrun swiftc "$ROOT/Sources/Settings.swift" "$ROOT/Tests/main.swift" \
  -module-cache-path "$ROOT/.build/module-cache" -o "$ROOT/.build/policy-tests"
"$ROOT/.build/policy-tests"
plutil -lint "$ROOT/Info.plist"
