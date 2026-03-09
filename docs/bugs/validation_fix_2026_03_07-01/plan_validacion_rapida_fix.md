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

## Monitoring Window Result (updated 2026-03-09)
- Status changed from **Monitoring** to **FAIL / Reopened**.
- Failure scenario confirmed on 2026-03-08:
  1. macOS owner went to sleep/background.
  2. Android remained as the only active/open app with intermittent screen-off cycles.
  3. Around 19:00 (2026-03-08), Android entered `Syncing session...` with amber ring and never recovered.
  4. On macOS wake, app resumed into `Syncing session...` + black screen.
- Recovery attempts reported: screen wake, navigation changes, and retry interactions did not recover Android state.
- Evidence:
  - Screenshot:
    - `docs/bugs/validation_fix_2026_03_07-01/screenshots/Screenshot_2026-03-08-19-02-12-76_24a6c2193a9deb7da51ed61dc48f62e5.jpg`
  - Logs:
    - `/Users/devcodex/MEGA/Trabajo-INGRESOS/1_JORNADAS-INGRESOS-INVERSIONES/DEVELOP/3_PROYECTO-PERSONAL/focus-interval/testing/logs/Android-2026-03-08-cc5f55b.log`
    - `/Users/devcodex/MEGA/Trabajo-INGRESOS/1_JORNADAS-INGRESOS-INVERSIONES/DEVELOP/3_PROYECTO-PERSONAL/focus-interval/testing/logs/macos-2026-03-08-cc5f55b.log`
- Log correlation summary:
  - Android: sustained Firestore `UNAVAILABLE` + `UnknownHostException` during the incident window, with stale session snapshots.
  - macOS: `Missing snapshot; clearing session` and `Resync missing; clearing state` during resume path.
- Closure impact:
  - Fix 26 closure criteria are not met.
  - Keep Fix 26 open and blocked for further hardening/re-validation.

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

Implementation status (2026-03-07) — first attempt FAIL
- Commit: `5ac3d6b` (`fix: restore Local->Account overdue auto-start reentry`).
- Changes: `app_mode_change_guard.dart` + `scheduled_group_coordinator.dart`.
- Result: validation failed — timer did not open on mode switch.
- Root cause of failure: `ref.invalidate(scheduledGroupCoordinatorProvider)` disposed the
  coordinator's `ref.listen` subscriptions. Firestore stream data arrived during the race
  window before the new coordinator instance rebuilt and re-registered its listeners.

Implementation status (2026-03-07) — second attempt PASS — **Closed/OK**
- Code change: removed `ref.invalidate(scheduledGroupCoordinatorProvider)` from
  `_handleModeChange`. The coordinator's own `ref.listen<AppMode>` handler correctly
  calls `_resetForModeChange()` + `_handleGroups()` on every mode change; invalidating it
  was breaking that natural subscription chain.
- `forceReevaluate()` calls (postFrameCallback + 600ms delay) kept as backup triggers.
- Analyzer: PASS.
- Validation logs:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_07_fix27v2_ios_debug.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_07_fix27v2_chrome_debug.log`
- Exact repro PASS (iOS + Chrome, 2026-03-07 22:49): group scheduled at 22:48, user in
  Local Mode, switched back to Account Mode at 22:49 — auto-start fired immediately,
  Timer Run Mode opened without app restart.
- Regression smoke PASS: no Fix 24/Fix 26 regressions observed in v2 logs.

## Closure criteria for Fix 26
1. Exact repro for original syncing hold remains PASS during the 2-day window.
2. Regression smoke checks remain PASS.
3. No new `Syncing session...` indefinite hold in owner/mirror cross-device runs.
