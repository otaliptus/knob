#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/knob.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

rm -rf "$APP"
mkdir -p "$MACOS" "$RESOURCES"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"

swift "$ROOT/Tools/GenerateIcon.swift" "$ROOT"
iconutil -c icns "$ROOT/Resources/AppIcon.iconset" -o "$RESOURCES/AppIcon.icns"

swiftc \
  -O \
  -framework AppKit \
  "$ROOT/Sources/knob/main.swift" \
  -o "$MACOS/knob"

chmod +x "$MACOS/knob"
echo "$APP"
