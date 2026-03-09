# Global Validation Ledger — Rules

This directory tracks validation status across **all work types**:

- bugs
- features
- refactors
- infra/process

Active ledger file:

- `docs/validation/validation_ledger.md`

## Mandatory usage

1. Every new pending validation must be added to the ledger with:
   - stable ID
   - type
   - priority
   - status
   - source path + line
2. Before switching to unrelated work, update the current item status.
3. Do not leave an item in ambiguous state (use only: `Pending`, `In validation`,
   `Validated`, `Closed/OK`).

## Closure traceability (required)

When closing any item, record:

- `closed_commit_hash`
- `closed_commit_message`
- evidence reference (logs/screenshots/checklist line)

If one implementation closes multiple items, close each affected ID explicitly.
