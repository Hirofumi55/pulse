#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <version>" >&2
  exit 1
fi

VERSION="$1"

echo "Homebrew Cask update for Pulse ${VERSION} is not implemented yet." >&2
echo "Implement this script once hirofumi/homebrew-tap is ready." >&2
exit 1
