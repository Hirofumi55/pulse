#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <release-directory>" >&2
  exit 1
fi

RELEASE_DIR="$1"

if [[ -z "${VERSION:-}" ]]; then
  echo "VERSION environment variable is required." >&2
  exit 1
fi

GENERATE_APPCAST="${GENERATE_APPCAST:-generate_appcast}"

if ! command -v "$GENERATE_APPCAST" >/dev/null 2>&1; then
  echo "generate_appcast command was not found." >&2
  exit 1
fi

mkdir -p gh-pages
if [[ -n "${SPARKLE_PRIVATE_KEY:-}" ]]; then
  printf "%s\n" "$SPARKLE_PRIVATE_KEY" | "$GENERATE_APPCAST" \
    --ed-key-file - \
    --download-url-prefix "https://github.com/Hirofumi55/pulse/releases/download/v${VERSION}/" \
    -o gh-pages/appcast.xml \
    "$RELEASE_DIR"
else
  "$GENERATE_APPCAST" \
    --download-url-prefix "https://github.com/Hirofumi55/pulse/releases/download/v${VERSION}/" \
    -o gh-pages/appcast.xml \
    "$RELEASE_DIR"
fi
