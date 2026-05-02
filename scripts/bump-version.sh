#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <marketing-version> [build-number]" >&2
  exit 1
fi

VERSION="$1"
BUILD_NUMBER="${2:-}"
PBXPROJ="Pulse.xcodeproj/project.pbxproj"
PLIST="Pulse/App/Info.plist"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "Marketing version must be SemVer-like, for example 0.1.1 or 1.0.0-beta.1." >&2
  exit 1
fi

if [[ ! -f "$PBXPROJ" ]]; then
  echo "Xcode project file was not found: ${PBXPROJ}" >&2
  exit 1
fi

if [[ ! -f "$PLIST" ]]; then
  echo "Info.plist was not found: ${PLIST}" >&2
  exit 1
fi

CURRENT_BUILD="$(
  awk -F'= ' '/CURRENT_PROJECT_VERSION = / {
    gsub(/[;[:space:]]/, "", $2)
    print $2
    exit
  }' "$PBXPROJ"
)"

if [[ -z "$CURRENT_BUILD" || ! "$CURRENT_BUILD" =~ ^[0-9]+$ ]]; then
  echo "Could not read numeric CURRENT_PROJECT_VERSION from ${PBXPROJ}." >&2
  exit 1
fi

if [[ -z "$BUILD_NUMBER" ]]; then
  BUILD_NUMBER=$((CURRENT_BUILD + 1))
fi

if [[ ! "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Build number must be a positive integer." >&2
  exit 1
fi

if ((BUILD_NUMBER < 1)); then
  echo "Build number must be a positive integer." >&2
  exit 1
fi

perl -0pi -e \
  "s/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = ${VERSION};/g; s/CURRENT_PROJECT_VERSION = [^;]+;/CURRENT_PROJECT_VERSION = ${BUILD_NUMBER};/g" \
  "$PBXPROJ"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString \$(MARKETING_VERSION)" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion \$(CURRENT_PROJECT_VERSION)" "$PLIST"

echo "Pulse version bumped to ${VERSION} (${BUILD_NUMBER})."
