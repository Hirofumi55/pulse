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

mkdir -p gh-pages
generate_appcast \
  --download-url-prefix "https://github.com/Hirofumi55/pulse/releases/download/v${VERSION}/" \
  --output-dir gh-pages \
  "$RELEASE_DIR"
