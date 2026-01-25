#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*"; }

REMOTE_NAME="${REMOTE_NAME:-mirror}"

: "${TARGET_URL:?TARGET_URL is required}"

# Ensure we are inside a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repo. Did you forget to checkout repository?"
  exit 1
fi

log "Fetching full history + tags..."
git fetch --all --tags --prune

# Build authenticated URL if HTTPS + token provided
TARGET_AUTH_URL="$TARGET_URL"
if [[ "$TARGET_URL" == https://* && "${GIT_TOKEN:-}" != ""]]; then
  TARGET_AUTH_URL="https://x-access-token:${GIT_TOKEN}@${TARGET_URL#https://}"
fi

# Reset remote every run (avoids cached/wrong credentials)
git remote remove "$REMOTE_NAME" >/dev/null 2>&1 || true
git remote add "$REMOTE_NAME" "$TARGET_AUTH_URL"

log "Remotes configured:"
git remote -v | sed -E 's#x-access-token:[^@]+@#x-access-token:***@#g'

log "Pushing true mirror (branches + tags) with overwrite..."
git push "$REMOTE_NAME" --mirror --force

log "Mirror sync complete"