# Feature: IDEA-034 — Offline Continuation With Rejoin/Sync Choice

## Backlog reference
Backlog file: `docs/features/feature_backlog.md`
Backlog ID: IDEA-034
Backlog title: Offline Continuation With Rejoin/Sync Choice
Backlog status at extraction: in_progress
Execution order slot (if listed): N/A

## Problem / Goal
When a device loses network during a running or paused Account Mode session, the
UI can remain stuck in “Syncing session...”, blocking the user. We need a safe
and explicit way to keep the user productive without violating the single source
of truth or introducing silent merges.

## Summary
Detect real offline conditions, show a persistent Offline banner, and offer an
explicit choice to continue locally. If the user chooses local continuation, a
local-only fork is created and clearly labeled. When the network returns, the
user must choose to rejoin the Account session (discard local) or keep the local
fork. No implicit merges are allowed.

## Scope
In scope:
- Offline detection based on evidence (connectivity + timeSync/activeSession
  refresh failure).
- Offline banner/pill in Run Mode with `Retry sync` / `Continue locally`.
- Explicit Local Mode switch with a local-only fork marker.
- Reconnect reconciliation choice (rejoin vs keep local).
- Persistent “Local-only / Offline” label in Run Mode and Groups Hub for local
  forks.
Out of scope:
- Auto-switching to Local Mode without user confirmation.
- Auto-merge between Account and Local sessions.
- Presence indicators, offline caching upgrades, or background sync changes.

## Design / UX
Layout / placement:
- Run Mode banner/pill at top: “Offline — local only”.
- Inline CTA row: `Retry sync` and `Continue locally`.

Visual states:
- Offline banner visible only when evidence confirms offline.
- If local continuation is chosen, show a persistent “Local-only / Offline”
  badge on Run Mode and Groups Hub.

Animation rules:
- No animation required; keep UI steady to avoid confusion.

Interaction:
- `Retry sync` triggers a timeSync refresh and activeSession fetch.
- `Continue locally` switches to Local Mode and creates a local-only fork.
- On reconnect, present a persistent choice UI (modal or snackbar) that cannot
  be dismissed until the user chooses:
  - `Rejoin account session` (discard local)
  - `Keep local (stay Local Mode)`

Text / typography:
- Clear warnings about non-synced state and the impact of rejoining.

## Data & logic
Source of truth:
- Account Mode session remains authoritative.
- Local continuation never writes to Account Mode.

Calculations:
- Local continuation uses Local Mode timers and storage only.

Sync / multi-device:
- Other devices remain in Account Mode and continue as owner/mirror.
- Offline device does not publish to Account Mode.
- On reconnect, the user must choose; no implicit merge/overwrite.

## Edge cases
- Account session completes while offline: rejoin opens Groups Hub.
- Multiple offline devices: each must choose independently; no implicit merge.
- Rapid pause/resume while offline: local-only fork continues without Account
  writes.
- Avoid duplicate groups: Account and Local sessions must remain isolated.

## Accessibility
- Offline banner and reconnect choice must be announced clearly.

## Dependencies
- Fix 22 (timeSync + single source of truth).
- Local/Account isolation rules (no silent merge).
- Reliable connectivity/timeSync checks.

## Risks
- User confusion about active mode.
- Accidental loss of local-only progress if rejoin is chosen.
- Connectivity flapping causing repeated prompts.

## Acceptance criteria
- Offline is shown only with evidence (no false offline UI).
- User can continue locally only after explicit confirmation.
- Local-only fork is clearly labeled and never syncs to Account Mode.
- On reconnect, user must choose rejoin vs keep local; no implicit merge.
- Account Mode session remains unchanged while offline.

## Testing
Manual checks:
- Simulate offline during running session; verify banner + CTA.
- Choose `Continue locally`; verify Local-only label and no Account writes.
- Restore network; verify reconciliation choice and outcomes.
- Confirm no duplicate Account writes or merges.

Automated checks:
- N/A

## Notes
- This feature must not auto-switch modes; Local/Account remains explicit.
