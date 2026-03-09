# Plan — Rapid Validation (Fix 26 cycle 4 + Fix 27)

Date: 2026-03-07
Branch: `fix27-local-account-reentry-autostart`
Scope: Re-validation after commit `26f0c7e` + implementation of Fix 27.
Latest branch update (2026-03-09): `fix26-reopen-black-syncing-2026-03-09`

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
  3. Around 19:00 (2026-03-08), Android entered `Syncing session...` with amber ring (first screenshot at 19:02) and never recovered.
  4. On macOS wake, app resumed into `Syncing session...` + black screen.
  5. Stuck state remained until around 20:45 (2026-03-08).
- Recovery attempts reported: screen wake, navigation changes, and retry interactions did not recover Android state.
- Evidence:
  - Screenshot:
    - `docs/bugs/validation_fix_2026_03_07-01/screenshots/Screenshot_2026-03-08-19-02-12-76_24a6c2193a9deb7da51ed61dc48f62e5.jpg`
  - Logs:
    - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_08_fix26_incident_android_cc5f55b.log`
    - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_08_fix26_incident_macos_cc5f55b.log`
- Log correlation summary:
  - Android: sustained Firestore `UNAVAILABLE` + `UnknownHostException` during the incident window, with stale session snapshots.
  - macOS: `Missing snapshot; clearing session` and `Resync missing; clearing state` during resume path.
- Closure impact:
  - Fix 26 closure criteria are not met.
  - Keep Fix 26 open and blocked for further hardening/re-validation.

## Comparative Observation (2026-03-09 partial logs)
- New partial evidence added:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_observation_partial_android_cc5f55b.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_observation_partial_macos_cc5f55b.log`
- Summary:
  - No irrecoverable `Syncing session...` lock reproduced while both devices remained mostly active/open.
  - Android still reports repeated Firestore `UNAVAILABLE` + `UnknownHostException`.
  - Recovery behavior is present in this run: session snapshots continue advancing after error bursts.
  - macOS did not show `Missing snapshot; clearing session` / `Resync missing; clearing state` in the partial sample; only transient `Missing snapshot; holding in sync`.
- Updated hypothesis:
  - Trigger risk is concentrated in single-device effective ownership plus prolonged background/sleep and weak/offline network periods.
  - Hardening must prioritize resume/recovery when owner is alone and network is degraded.

## Fix 26 hardening implementation (2026-03-09)
- Status: **Implemented / Pending validation**.
- Branch: `fix26-reopen-black-syncing-2026-03-09`.
- Specs-first updates:
  - Added foreground bounded-backoff retry requirement during missing-session hold.
  - Added non-destructive clear guard requiring group-status recheck before local state clear.
  - Added resume listener rule to avoid forced close/recreate on every resume.
- Code changes applied:
  - `lib/presentation/viewmodels/pomodoro_view_model.dart`
    - Foreground missing-session retry loop upgraded from one-shot to periodic bounded backoff (`5s -> 10s -> 20s -> max 30s`).
    - Added repo recheck (`_groupRepo.getById`) before destructive clear when session snapshot is missing.
    - Added non-destructive clear path that preserves running projection state.
    - Added guarded session listener rebind policy on resume (rebind only when absent/stalled with cooldown).
    - Added explicit manual recovery API for session-gap stalls (`retrySessionGapRecovery`).
    - `applyRemoteCancellation()` now increments decision token and cancels foreground retry to prevent stale async hold after remote cancel.
  - `lib/presentation/screens/timer_screen.dart`
    - Sync overlay retry button now handles both time-sync stalls and session-gap stalls.
- Verification executed:
  - `flutter analyze` -> PASS.
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart` -> PASS.
- Tracking commits:
  - `3ad6c98` — `fix: harden fix26 missing-session recovery and resume sync`
  - `9f05951` — `fix: invalidate missing-session decision on remote cancellation`

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
1. Exact repro for the single-device + prolonged background/sleep + degraded-network scenario passes after this hardening implementation.
2. Regression smoke checks remain PASS (Fix 24 / Fix 25 / Fix 27 + overlap flow).
3. No new irrecoverable `Syncing session...` hold and no black-screen resume in the validated runs.

## Quick execution protocol (iOS + Chrome)

Date target: 2026-03-09
Purpose: fast regression confidence under unstable network without waiting full pomodoro cycles.

Steps:
1. Start one account-mode running group on iOS (owner).
2. Open the same group on Chrome (mirror) and verify sync baseline.
3. Run short background/resume on iOS (screen off / app background), then resume.
4. Simulate brief network instability on each device (about 60-90s), then recover and use retry if needed.
5. Trigger remote cancel while mirror is in/near sync-gap and verify mirror exits hold.
6. Run a short Fix 27 smoke check (Local -> Account re-entry path).

Expected PASS:
- No irreversible `Syncing session...` hold.
- No black-screen resume.
- No transient drop to Ready while active session is valid.
- Cancel path resolves on mirror after temporary gaps.

Planned logs:
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_ios_debug.log`
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_chrome_debug.log`

Command snippet:

```bash
flutter devices
flutter run -v --debug -d <IOS_DEVICE_ID> --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee /Users/devcodex/development/focus_interval/docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_ios_debug.log
flutter run -v --debug -d chrome --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee /Users/devcodex/development/focus_interval/docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_chrome_debug.log
```

Post-run documentation actions:
1. Update `quick_pass_checklist.md` R1-R5 and run metadata.
2. Update `validation_ledger.md` status for `P0-F26-001` and `P0-F26-002`.
3. If PASS, close Fix 26 and record closure commit hash/message/evidence.

## Quick run outcome (2026-03-09 iOS + Chrome)

Status: **FAIL (transient reconnect desync)**.

Observed:
- Baseline pause/resume and background/foreground behavior remained stable.
- During offline window + reconnect, Chrome briefly projected the timer with a
  large negative drift (~45s ahead of elapsed time), then self-corrected after
  the next sync cycle.
- No irreversible `Syncing session...` lock and no black-screen resume in this
  run.

Correlated evidence:
- Logs:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_ios_debug.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_chrome_debug.log`
- Screenshots:
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_07_204708.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_08_204802.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_09_205008.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_10_205046.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_11_205103.png`

Root-cause summary:
- `TimeSyncService.refresh()` accepted an invalid reconnect measurement and
  produced a poisoned offset (`+45550ms`) that temporarily skewed projection.

## Follow-up implementation (2026-03-09) — timeSync measurement safety

Status: **Implemented / Pending re-validation**.

Changes:
- `lib/data/services/time_sync_service.dart`
  - Reject measurement when roundtrip duration exceeds 3s.
  - Reject abrupt offset jumps (>5s delta) when a previous offset exists.
  - Add rejection cooldown (3s) to avoid tight retry loops on unstable network.
  - On rejection: keep previous offset, do not update last successful sync time.
- `docs/specs.md`
  - Added explicit rules for invalid timeSync measurement handling.

Verification:
- `flutter analyze` -> PASS.
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart` -> PASS.
- Commit:
  - `418c75f` — `fix: guard timesync offset against reconnect poisoning`.
