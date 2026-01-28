#!/usr/bin/env bash
set -euo pipefail

SOURCE_URL=""
TARGET_URL=""

if [[ $# -eq 2 ]]; then
    SOURCE_URL="$1"
    TARGET_URL="$2"

elif [[ $# -ne 0 ]]; then
    echo "Usage: ./mirror_sync.sh <SOURCE_URL> <TARGET_URL>"
    echo "Or edit SOURCE_URL AND TARGET_URL inside the script."
    exit 1
fi

if [[ -z "$SOURCE_URL" || -z "$TARGET_URL" ]]; then
    echo "ERROR: SOURCE_URL and TARGET_URL must be set."
    exit 2
fi

# Insert token into an HTTPS URL:
with_token_https() {
    local url="$1"
    local token="$2"

    if [[ "$url" != https://* || -z "$token" ]]; then
        echo "$url"
        return 0
    fi

    echo "${url/https:\/\//https:\/\/${token}@}"
}

SOURCE_URL_AUTH="$(with_token_https "$SOURCE_URL" "${SOURCE_TOKEN:-}")"
TARGET_URL_AUTH="$(with_token_https "$TARGET_URL" "${TARGET_TOKEN:-}")"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "Source: $SOURCE_URL"
echo "Target: $TARGET_URL"
echo "Workdir: $WORKDIR"

cd "$WORKDIR"

echo "Cloning source as mirror..."
if ! git clone --mirror "$SOURCE_URL_AUTH" repo.git; then
    echo "ERROR: Failed to clone source. If it's private, set SOURCE_TOKEN (read)."
    exit 4
fi

cd repo.git

echo "Pushing mirror to target (overwrites target to match source)..."
git remote remove target >/dev/null 2>&1 || true
git remote add target "$TARGET_URL_AUTH"
git push --mirror target

echo "Done."

# How to run:
# Open Git bash in file
# chmod +x mirror_sync.sh
# export TARGET_TOKEN="YOUR_TOKEN"
# export SOURCE_TOKEN="YOUR_TOKEN" (If the source is private)
# ./mirror_sync.sh "SOURCE_URL" "TARGET_URL"