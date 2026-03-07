# Plan — Rapid Validation (Fix 26 cycle 4 + Fix 27)

Date: 2026-03-07
Branch: `fix27-local-account-reentry-autostart`
Scope: Re-validation after commit `26f0c7e` + implementation of Fix 27.

## Objective
- Confirm that Fix 26 no longer leaves owner/mirror in indefinite `Syncing session...`.
- Keep Fix 26 open in monitoring mode for 2 days before final closure.

## Evidence (logs)
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_07_fix26_cycle4_ios_debug.log`
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_07_fix26_cycle4_chrome_debug.log`

## Current Result (provisional)
- Initial practical runs: no indefinite syncing hold observed.
- Status: **Monitoring** (not closed yet).
- Monitoring window: **2026-03-07 to 2026-03-09**.

## Related open bug found during this cycle
- Scenario:
  1. Plan a group in Account Mode.
  2. Switch to Local Mode.
  3. Let planned start time pass.
  4. Switch back to Account Mode.
- Current behavior: Run Mode does not auto-open immediately; if app is restarted, auto-open works.
- Impact: may cause unstable overlap resolution timing.
- Tracking: keep under reopened auto-open/overlap scope until triage+fix.

## Fix 27 — Local -> Account re-entry missed auto-start (new)

Objective
- Ensure overdue scheduled groups auto-start and open Run Mode immediately when re-entering Account Mode from Local Mode, without app restart, if there is no active conflict.

Implementation direction
- Keep auto-open route guards (no global intrusive opening behavior).
- Make mode switch behave like account cold re-entry for scheduling/session reevaluation:
  - refresh account group/session streams on mode change,
  - rebuild coordinator state for the new scope,
  - trigger deterministic post-switch reevaluation.

Validation target
- Exact repro:
  1. Schedule a group in Account Mode.
  2. Switch to Local Mode before scheduled start.
  3. Wait until scheduled start passes.
  4. Switch back to Account Mode without closing app.
  5. Expected: immediate auto-start + Timer Run Mode open.

Implementation status (2026-03-07)
- Implemented in branch `fix27-local-account-reentry-autostart`.
- Code changes:
  - `lib/widgets/app_mode_change_guard.dart`
  - `lib/presentation/viewmodels/scheduled_group_coordinator.dart`
- Analyzer: PASS.

## Closure criteria for Fix 26
1. Exact repro for original syncing hold remains PASS during the 2-day window.
2. Regression smoke checks remain PASS.
3. No new `Syncing session...` indefinite hold in owner/mirror cross-device runs.
