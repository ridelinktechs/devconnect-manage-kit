#!/bin/bash
#
# Build the macOS distribution assets for a DevConnect Manage Tool release.
#
# Produces 6 assets (matching the v1.0.0 / v1.0.1 release layout):
#   DevConnectManageTool-macOS-v<VER>-arm64.dmg       + -arm64-app.zip
#   DevConnectManageTool-macOS-v<VER>-x86_64.dmg       + -x86_64-app.zip
#   DevConnectManageTool-macOS-v<VER>-universal.dmg    + -universal-app.zip
#
# Run AFTER `flutter build macos --release`. The built .app is universal
# (arm64 + x86_64); arch-specific variants are produced by thinning it with
# `ditto --arch`, which rewrites every Mach-O in the bundle (executable +
# frameworks + dylibs) to a single slice.

set -euo pipefail

VERSION="${1:-1.0.2}"
SRC_APP="build/macos/Build/Products/Release/DevConnect.app"
APP_NAME="DevConnect"                       # name of the .app inside the dmg/zip
VOLNAME="DevConnect Manage Tool v${VERSION}"
OUT="release_assets/v${VERSION}"

if [ ! -d "$SRC_APP" ]; then
  echo "ERROR: built app not found at $SRC_APP"
  echo "       Run 'flutter build macos --release' first."
  exit 1
fi

rm -rf "$OUT"
mkdir -p "$OUT"

build_variant() {
  local arch="$1"      # arm64 | x86_64 | universal
  local label="$2"     # arm64 | x86_64 | universal
  local stage="$OUT/.stage-$label"
  local app="$stage/$APP_NAME.app"
  local zip="$OUT/DevConnectManageTool-macOS-v${VERSION}-${label}-app.zip"
  local dmg="$OUT/DevConnectManageTool-macOS-v${VERSION}-${label}.dmg"

  echo "==> $label"
  rm -rf "$stage"; mkdir -p "$stage"

  if [ "$arch" = "universal" ]; then
    cp -R "$SRC_APP" "$app"
  else
    ditto --arch "$arch" "$SRC_APP" "$app"
  fi

  # Verify the thinned binary actually carries the expected arch(es).
  local got
  got="$(lipo -archs "$app/Contents/MacOS/$APP_NAME")"
  echo "    exe arches: $got"

  # .app zip (ditto preserves symlinks / extended attrs for frameworks).
  # NOTE: ditto -c -k silently no-ops when the source is relative and the
  # destination is absolute ("No destination"), so the source must be absolute.
  ditto -c -k --sequesterRsrc --keepParent "$app" "$zip"

  # DMG (read-only, compressed; app at volume root).
  hdiutil create \
    -volname "$VOLNAME" \
    -srcfolder "$app" \
    -fs HFS+ \
    -ov -format UDZO \
    "$dmg" >/dev/null

  rm -rf "$stage"
  echo "    -> $(basename "$zip")"
  echo "    -> $(basename "$dmg")"
}

build_variant arm64     arm64
build_variant x86_64    x86_64
build_variant universal universal

echo ""
echo "=== $OUT ==="
ls -la "$OUT"
