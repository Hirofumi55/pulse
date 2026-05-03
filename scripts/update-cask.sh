#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <version>" >&2
  exit 1
fi

VERSION="$1"
APP_REPO="${APP_REPO:-Hirofumi55/pulse}"
TAP_REPO="${TAP_REPO:-Hirofumi55/homebrew-tap}"
TAP_BRANCH="${TAP_BRANCH:-main}"
CASK_NAME="${CASK_NAME:-pulse}"
ZIP_NAME="Pulse-${VERSION}.zip"
DOWNLOAD_URL="https://github.com/${APP_REPO}/releases/download/v${VERSION}/${ZIP_NAME}"

if [[ -z "${GH_TOKEN:-}" ]]; then
  echo "GH_TOKEN environment variable is required to update ${TAP_REPO}." >&2
  exit 1
fi

for command in curl git shasum awk; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "${command} command was not found." >&2
    exit 1
  fi
done

TMP_DIR="$(mktemp -d)"
GIT_CONFIG_FILE="${TMP_DIR}/gitconfig"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

cat >"$GIT_CONFIG_FILE" <<GITCONFIG
[http "https://github.com/"]
	extraheader = AUTHORIZATION: bearer ${GH_TOKEN}
GITCONFIG
chmod 600 "$GIT_CONFIG_FILE"

echo "Downloading ${DOWNLOAD_URL}"
curl -fsSL "$DOWNLOAD_URL" -o "${TMP_DIR}/${ZIP_NAME}"
SHA256="$(shasum -a 256 "${TMP_DIR}/${ZIP_NAME}" | awk '{print $1}')"

GIT_CONFIG_GLOBAL="$GIT_CONFIG_FILE" git clone "https://github.com/${TAP_REPO}.git" "${TMP_DIR}/tap"

cd "${TMP_DIR}/tap"
mkdir -p Casks
CASK_PATH="Casks/${CASK_NAME}.rb"

cat >"$CASK_PATH" <<CASK
cask "${CASK_NAME}" do
  version "${VERSION}"
  sha256 "${SHA256}"

  url "${DOWNLOAD_URL}",
      verified: "github.com/${APP_REPO}/"
  name "Pulse"
  desc "Modern menu bar system monitor for Apple Silicon"
  homepage "https://github.com/${APP_REPO}"

  depends_on macos: ">= :sonoma"

  app "Pulse.app"

  zap trash: [
    "~/Library/Application Support/Pulse",
    "~/Library/Logs/Pulse",
    "~/Library/Preferences/com.hirofumi.pulse.plist",
  ]
end
CASK

if [[ -z "$(git status --short -- "$CASK_PATH")" ]]; then
  echo "Homebrew Cask is already up to date for Pulse ${VERSION}."
  exit 0
fi

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add "$CASK_PATH"
git commit -m "Update Pulse cask to ${VERSION}"
GIT_CONFIG_GLOBAL="$GIT_CONFIG_FILE" git push origin "HEAD:${TAP_BRANCH}"

echo "Homebrew Cask updated for Pulse ${VERSION}."
