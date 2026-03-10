# Quick Pass Checklist — Fix 26 cycle 4

Date: 2026-03-07
Last reviewed: 2026-03-10
Status: **Reopened (10/03/2026 regression — rollback to 961f7eb baseline, re-validation required)**

- [x] iOS + Chrome run completed with debug logs saved.
- [x] Original Fix 26 symptom (indefinite `Syncing session...`) not reproduced in first practical runs.
- [x] Owner cancel path observed without indefinite mirror lock.
- [x] Two-day monitoring window completed (target: 2026-03-09) — **FAIL**.
- [x] Fix 26 hardening v4 implemented (foreground bounded-backoff retry, non-destructive clear with group recheck, resume listener rebind guard, sync overlay retry for session gap).
- [x] Static/targeted verification PASS (`flutter analyze` + targeted session-gap/overlay tests).
- [x] Exact repro re-run after hardening: single-device + prolonged background/sleep + degraded-network path.
- [x] Regression smoke re-run after hardening (Fix 24 / Fix 25 / Fix 27 + overlap flow).
- [x] Final closure recorded in validation docs.
- [x] Fix 27 exact repro PASS (Local -> Account after missed scheduled start opens Run Mode without restart).
- [x] Fix 27 regression smoke PASS (Fix 24, Fix 26, overlaps flow — iOS + Chrome logs confirm no regressions).

## Fix 26 Reopen Evidence (2026-03-08)
- Exact repro context:
  - macOS owner went to sleep/background.
  - Android remained as the only app/device open, with intermittent screen-off cycles.
  - First stuck observation: around 19:00 (2026-03-08), confirmed by screenshot timestamp 19:02.
  - Stuck window remained until around 20:45 (2026-03-08) with no recovery.
- Observed result:
  - Android stayed indefinitely on `Syncing session...` with amber ring from first observation (~19:00) through ~20:45, without recovery even after screen/navigation changes.
  - macOS resumed in `Syncing session...` with black screen after wake from sleep.
- Evidence:
  - Screenshot:
    - `docs/bugs/validation_fix_2026_03_07-01/screenshots/Screenshot_2026-03-08-19-02-12-76_24a6c2193a9deb7da51ed61dc48f62e5.jpg`
  - Logs:
    - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_08_fix26_incident_android_cc5f55b.log`
    - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_08_fix26_incident_macos_cc5f55b.log`
  - Key log signals:
    - Android: repeated Firestore `UNAVAILABLE` and `UnknownHostException` while session stayed stale.
    - macOS: repeated `Missing snapshot; clearing session` + `Resync missing; clearing state` after resume path.
- Decision:
  - Fix 26 remains open (not closable on 2026-03-09).

## Supplemental Observation (2026-03-09 partial logs)
- Context:
  - Both macOS and Android stayed mostly open/active during the run (no prolonged single-device owner gap).
  - Partial logs captured while session was still running.
- Evidence:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_observation_partial_android_cc5f55b.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_observation_partial_macos_cc5f55b.log`
- Observed result:
  - No irrecoverable `Syncing session...` hold reproduced in this partial run.
  - Android still shows repeated Firestore `UNAVAILABLE` + `UnknownHostException`, but snapshots keep advancing after those errors.
  - macOS shows transient `Missing snapshot; holding in sync` events without `Missing snapshot; clearing session` / `Resync missing; clearing state` in this partial run.
- Interpretation:
  - Failure scope appears narrower: high risk when ownership effectively collapses to one device with prolonged background/sleep + unstable network.
  - Fix 26 remains open until that exact single-device degraded-network scenario is hardened.

## Fix 26 Hardening (implemented 2026-03-09)
- Implemented:
  - VM foreground hold recovery now uses periodic bounded-backoff retries (no one-shot-only gap for mirrors in foreground).
  - Missing-session destructive clear now requires group-status recheck via repository first.
  - Resume path no longer forces listener close/recreate on every resume event.
  - Sync overlay retry now supports session-gap stall recovery in addition to time-sync retry.
  - `applyRemoteCancellation()` now invalidates in-flight async missing-session decisions (token increment + foreground retry cancel) to prevent stale hold after remote cancel.
- Verification:
  - `flutter analyze` -> PASS.
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart` -> PASS.
  - Commit: `3ad6c98` — `fix: harden fix26 missing-session recovery and resume sync`.
  - Commit: `9f05951` — `fix: invalidate missing-session decision on remote cancellation`.
  - Commit: `418c75f` — `fix: guard timesync offset against reconnect poisoning`.

## Quick Validation Packet (iOS + Chrome, 2026-03-09)

### Log capture commands

```bash
# 1) Discover device IDs
flutter devices

# 2) iOS debug + prod override log (replace <IOS_DEVICE_ID>)
flutter run -v --debug -d <IOS_DEVICE_ID> --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee /Users/devcodex/development/focus_interval/docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_ios_debug.log

# 3) Chrome debug + prod override log
flutter run -v --debug -d chrome --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee /Users/devcodex/development/focus_interval/docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_chrome_debug.log
```

### Execution checklist (quick regression)

- [x] R1 Baseline multi-device mirror sync PASS (no transient Ready, no irreversible sync hold).
- [x] R2 Owner background/resume PASS (no black screen, recovers <= 30s).
- [x] R3 Network degradation/recovery PASS on iOS + Chrome (manual retry recovers). Initial 20:32 packet failed (transient reconnect desync), but rerun after `418c75f` passed under the same offline/restore conditions.
- [x] R4 Remote cancel during gap PASS (mirror exits hold and reflects cancel).
- [x] R5 Fix 27 smoke PASS (Local -> Account re-entry still OK).

### Run metadata (fill after execution)

- Start time (local): `2026-03-09 20:32:21`
- End time (local): `2026-03-09 20:38:33`
- iOS device used: `iPhone 17 Pro` (simulator, owner)
- Chrome environment: `localhost web debug` (mirror, same machine/Wi-Fi)
- Logs:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_ios_debug.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_chrome_debug.log`
- Evidence screenshots:
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_01_204131.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_02_204211.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_03_204356.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_04_204503.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_05_204547.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_06_204617.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_07_204708.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_08_204802.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_09_205008.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_10_205046.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_11_205103.png`

### Closure decision (fill after execution)

- Fix 26 decision: `Closed/OK`
- Notes: `Re-validation passed after TimeSync measurement guard. Syncing duration matched the real offline window only; no reconnect timer jump reproduced.`
- Closing commit hash: `418c75f`
- Closing commit message: `fix: guard timesync offset against reconnect poisoning`

## 2026-03-09 quick run diagnosis
- Timeline summary:
  - 20:32:21 pause on iOS owner; 20:32:33 resume: PASS.
  - 20:33:00 iOS background; 20:36:01 foreground: PASS.
  - 20:36:14 iOS background.
  - 20:36:20 internet removed on both devices.
  - 20:37:27 iOS foreground while offline: still coherent with syncing hold.
  - 20:37:53 internet restored: transient owner/mirror desync shown.
  - 20:38:24/20:38:33 both views converged again.
- Log evidence:
  - Chrome shows poisoned `TimeSync` sample at reconnect (`offset=45550ms`) and later correction (`offset=-8ms`).
  - iOS snapshots remained authoritative (`lastUpdatedAt` advanced normally).

## 2026-03-09 re-validation after `418c75f` (PASS)
- Context:
  - Same iOS + Chrome setup and same degraded-network pattern (offline window + reconnect).
  - User observation confirmed: `Syncing session...` lasted only while internet was actually unavailable.
- Chrome evidence (`2026_03_09_fix26_quick_chrome_debug.log`):
  - Invalid reconnect samples were rejected instead of accepted:
    - line 2255: `rejected measurement (roundTripMs=65971 offsetMs=32806 prevOffsetMs=-93)`
    - line 2466: `rejected measurement (roundTripMs=16288 offsetMs=7875 prevOffsetMs=-83)`
    - line 2506: `rejected measurement (roundTripMs=28286 offsetMs=13857 prevOffsetMs=-32)`
  - No large positive projection offset appears in this rerun; offset stayed in a small range (about `0ms` to `-131ms`).
- Result:
  - No transient reconnect desync reproduced.
  - No irreversible `Syncing session...` hold reproduced.
  - Fix 26 closure criteria met.

## 2026-03-10 Regression + Rollback

- Context:
  - During Fix 25 validation (iOS owner + Android mirror), Android became stuck in
    irrecoverable `Syncing session...` at ~12:15 CET despite Firestore showing a healthy
    `pomodoroRunning` session (owner=macOS, `lastUpdatedAt` advancing normally).
- Root cause (confirmed from logs `2026_03_10_fix26_observation_partial_android_d03c150.log`):
  - Firebase Auth token refresh at ~12:15:11 caused `runningExpiry=true` false-positive
    (56ms spike) in `ScheduledGroups`.
  - Spike silently disconnected the Firestore session listener on Android without logging
    an explicit `Cancel nav` event.
  - With stream dead, `_sessionMissingWhileRunning = true` latched and never cleared
    despite foreground retry running every ~30s.
  - `418c75f` (TimeSync guard) confirmed uninvolved — all offsets clean (-136ms to -214ms).
- Rollback performed (commit `4195ef1`):
  - `pomodoro_view_model.dart`, `timer_screen.dart`, `firestore_pomodoro_session_repository.dart`,
    `pomodoro_session_repository.dart` restored to `961f7eb` state.
  - Second/third-cycle hardening commits (`9bab880`, `4f55010`, `26f0c7e`, `3ad6c98`) removed.
  - Fix 27 and `418c75f` preserved.
- Next step: Re-validate Fix 26 exact repro under `4195ef1`.

## 2026-03-10 Rollback Re-validation (partial logs, `4195ef1`)

- Evidence:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_10_fix26_observation_partial_android_4195ef1.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_10_fix26_observation_partial_macos_4195ef1.log`
- [x] Android partial run analyzed (13:19–13:42 CET).
- [x] macOS partial run analyzed (13:19–13:42 CET).
- [x] No `Missing snapshot; clearing session` found in rollback partial logs.
- [x] Resume flow reached `Resync start (resume/post-resume)` and recovered with continuous snapshots.
- [x] No irrecoverable `Syncing session...` reproduced in this partial window.
- [ ] Extended stability soak completed on rollback commit `4195ef1` (minimum target: >=4h before closure).
- [ ] Exact degraded-network repro packet completed end-to-end (required before closure).

## Mandatory guardrails before next Fix 26 code changes

- [ ] Do not close/rebind `_sessionSub` from `PomodoroViewModel.build()`.
- [ ] Keep listener-lifecycle changes isolated in a dedicated commit (no mixed UI/routing changes).
- [ ] Add/update targeted regression test for provider rebuild/auth-refresh listener continuity.
- [ ] Run exact repro + >=4h soak on the candidate commit before closure.
- [ ] Confirm at least one `FirebaseAuth` id-token refresh in logs without indefinite `Syncing session...`.

## 2026-03-10 Follow-up — invalid cursor after reopen/owner switch

- [x] Reproduced inconsistent persisted cursor (`currentTaskIndex=1`, `currentPomodoro=2`, `totalPomodoros=1`) with running group still active.
- [x] Implemented cursor repair in ViewModel sanitize + stream paths (repair by running-group timeline anchor when cursor is invalid).
- [x] Added regression test for invalid cursor repair on `loadGroup`.
- [x] `dart analyze` (targeted files) PASS.
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS.
- [x] `flutter analyze` PASS.
- [ ] Android RMX3771 + macOS manual validation PASS with post-fix logs.
- [ ] Confirm reopened session lands on correct task (`Trading`) and coherent pomodoro index (no `2/1`).

## Fix 27 Evidence
- iOS log: `2026_03_07_fix27v2_ios_debug.log` line 51016 — `Auto-start opening TimerScreen` at 22:49:03 for group `c2b7f11d`.
- Chrome log: `2026_03_07_fix27v2_chrome_debug.log` lines 2086–2090 — `Active session change route=/tasks` → `Attempting auto-open` → `Auto-open confirmed in timer route=/timer/c2b7f11d`.
- Root cause: `ref.invalidate(scheduledGroupCoordinatorProvider)` was disposing the coordinator's listeners, creating a race window where Firestore stream data arrived before the new coordinator instance rebuilt its subscriptions.
- Fix: removed the invalidation — coordinator's `ref.listen<AppMode>` handles mode transitions naturally via `_resetForModeChange()` + `_handleGroups()`.
- Fix commit: Block 550 in dev_log.md.
