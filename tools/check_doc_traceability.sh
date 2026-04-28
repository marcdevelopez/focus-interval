#!/usr/bin/env bash
set -euo pipefail

# Prevent traceability placeholders from being introduced in critical docs.
# The check intentionally scans only ADDED lines in the current diff so
# historical placeholders can be cleaned incrementally without blocking
# unrelated work.

FILES=(
  "docs/dev_log.md"
  "docs/validation/validation_ledger.md"
  "docs/bugs/bug_log.md"
)

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Doc traceability check failed: not inside a git repository."
  exit 1
fi

DIFF_MODE="working-tree"
if ! git diff --cached --quiet -- "${FILES[@]}"; then
  DIFF_MODE="staged"
fi

if [[ "$DIFF_MODE" == "staged" ]]; then
  DIFF_OUTPUT="$(git diff --cached -U0 -- "${FILES[@]}")"
else
  DIFF_OUTPUT="$(git diff -U0 -- "${FILES[@]}")"
fi

if [[ -z "$DIFF_OUTPUT" ]]; then
  echo "Doc traceability check passed (no critical doc changes)."
  exit 0
fi

ADDED_LINES="$(printf '%s\n' "$DIFF_OUTPUT" | rg '^\+' | rg -v '^\+\+\+' || true)"
if [[ -z "$ADDED_LINES" ]]; then
  echo "Doc traceability check passed (no added lines in critical docs)."
  exit 0
fi

VIOLATIONS="$(printf '%s\n' "$ADDED_LINES" | rg -n '\*\*Commit:\*\* `pending-local`|closed_commit_hash: `pending-local`|closed_commit_message: `pending-local`' || true)"
if [[ -n "$VIOLATIONS" ]]; then
  echo "Doc traceability check failed."
  echo "Found placeholder commit markers in added lines (${DIFF_MODE} diff):"
  printf '%s\n' "$VIOLATIONS"
  echo
  echo "Replace placeholders with real commit hashes before committing."
  exit 1
fi

echo "Doc traceability check passed."
