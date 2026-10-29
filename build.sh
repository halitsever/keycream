#!/bin/bash
# Builds a release binary and wraps it in build/KeyCream.app with its resources.
# Optional environment:
#   UNIVERSAL=1    build for both Apple Silicon and Intel
#   VERSION=1.2.3  CFBundleShortVersionString of the built app
#   BUILD_NUMBER=7 CFBundleVersion of the built app
#   SIGN_IDENTITY  codesign identity; defaults to a Developer ID Application certificate
#                  from the keychain if there is one, "-" forces an ad-hoc signature
set -euo pipefail
cd "$(dirname "$0")"

ARCH_FLAGS=()
if [[ "${UNIVERSAL:-0}" == "1" ]]; then
    ARCH_FLAGS=(--arch arm64 --arch x86_64)
fi
swift build -c release ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"}
BIN="$(swift build -c release ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"} --show-bin-path)/KeyCream"

APP=build/KeyCream.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/KeyCream"
cp Info.plist "$APP/Contents/Info.plist"
cp -R Resources/SoundPacks "$APP/Contents/Resources/"
cp -R Resources/Localization/*.lproj "$APP/Contents/Resources/"
cp Resources/Icons/MenuBarIconTemplate.png Resources/Icons/MenuBarIconTemplate@2x.png "$APP/Contents/Resources/"

if [[ -n "${VERSION:-}" ]]; then
    plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP/Contents/Info.plist"
fi
if [[ -n "${BUILD_NUMBER:-}" ]]; then
    plutil -replace CFBundleVersion -string "$BUILD_NUMBER" "$APP/Contents/Info.plist"
fi

ICONSET=build/AppIcon.iconset
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    sips -z $size $size Resources/Icons/AppIcon-1024.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    sips -z $((size * 2)) $((size * 2)) Resources/Icons/AppIcon-1024.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"

if [[ -z "${SIGN_IDENTITY:-}" ]]; then
    SIGN_IDENTITY=$(security find-identity -v -p codesigning | awk -F'"' '/Developer ID Application/ { print $2; exit }')
fi
if [[ -z "$SIGN_IDENTITY" || "$SIGN_IDENTITY" == "-" ]]; then
    # Input Monitoring is granted per ad-hoc signature, so every rebuild needs re-granting.
    codesign --force --sign - "$APP"
    echo "Built $APP (ad-hoc signed)"
else
    # Notarization requires the hardened runtime and a secure timestamp.
    codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
    echo "Built $APP (signed by $SIGN_IDENTITY)"
fi
