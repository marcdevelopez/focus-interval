#!/usr/bin/env bash
set -euo pipefail

changed_files=$(git diff --name-only --cached)
if [ -z "$changed_files" ]; then
  changed_files=$(git diff --name-only)
fi

if [ -z "$changed_files" ]; then
  echo "No changes detected."
  exit 0
fi

schema_changed=false
for file in $changed_files; do
  if [[ "$file" == "firestore.rules" ]] || [[ "$file" == lib/data/models/* ]]; then
    schema_changed=true
    break
  fi
done

if [ "$schema_changed" = true ]; then
  has_specs=false
  has_dev_log=false
  for file in $changed_files; do
    if [[ "$file" == "docs/specs.md" ]]; then
      has_specs=true
    fi
    if [[ "$file" == "docs/dev_log.md" ]]; then
      has_dev_log=true
    fi
  done

  if [ "$has_specs" = false ] || [ "$has_dev_log" = false ]; then
    echo "Release safety check failed."
    echo "Firestore rules or model schema changed without updating docs/specs.md and docs/dev_log.md."
    echo "Changed files:"
    echo "$changed_files"
    exit 1
  fi
fi

echo "Release safety check passed."
