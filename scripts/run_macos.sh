#!/usr/bin/env bash
set -euo pipefail

if [ -f .env.local ]; then
  # shellcheck disable=SC1091
  source .env.local
fi

if [ -z "${GITHUB_OAUTH_CLIENT_ID:-}" ]; then
  echo "GITHUB_OAUTH_CLIENT_ID is required. Set it in .env.local." >&2
  exit 1
fi

GITHUB_OAUTH_EXCHANGE_ENDPOINT="${GITHUB_OAUTH_EXCHANGE_ENDPOINT:-https://us-central1-focus-interval.cloudfunctions.net/githubExchange}"

flutter run -d macos \
  --dart-define=GITHUB_OAUTH_CLIENT_ID="${GITHUB_OAUTH_CLIENT_ID}" \
  --dart-define=GITHUB_OAUTH_EXCHANGE_ENDPOINT="${GITHUB_OAUTH_EXCHANGE_ENDPOINT}" \
  -v "$@"
