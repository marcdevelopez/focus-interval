# Quick Pass Checklist — Fix 26 cycle 4

Date: 2026-03-07
Last reviewed: 2026-03-11
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
- [x] Android RMX3771 + macOS manual validation PASS with post-fix logs (`2026-03-10_fix26_postfix_250c24d_macos_diag.log`, `2026-03-10_fix26_postfix_250c24d_android_RMX3771_diag.log`).
- [x] Confirm reopened session lands on correct task (`Trading`) and coherent pomodoro index (no `2/1`).

## 2026-03-10 Follow-up v2 — running group + finished session inconsistency

- [x] Reproduced inconsistent pair in Firestore: `TaskRunGroup.status=running` while `activeSession/current.status=finished` with stale cursor (`currentPomodoro=2`, `totalPomodoros=1`).
- [x] Confirmed symptom in logs on both devices: repeated `Active session cleared` and `Auto-start abort (state not idle) state=finished`.
- [x] Hardened cursor repair to also recover when session is non-active (`finished`) but group is still `running`.
- [x] Added regression test: `loadGroup repairs finished invalid cursor when group is still running`.
- [x] `dart analyze` (targeted files) PASS.
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS.
- [x] Android RMX3771 + macOS manual validation PASS with post-fix logs (`2026-03-10_fix26_postfix_250c24d_macos_diag.log`, `2026-03-10_fix26_postfix_250c24d_android_RMX3771_diag.log`).
- [x] Confirm auto-open/run mode no longer stays on `00:00 Syncing session...` for this inconsistent snapshot pair.

## 2026-03-10 Follow-up v3 — stale finished owner recovery

- [x] Identified ownership gap: `TaskRunGroup.status=running` with stale `activeSession.status=finished` left all clients as mirror/no-owner.
- [x] Implemented sanitize-time stale recovery: when repaired session is active but persisted snapshot is non-active+stale, claim ownership on current device and rebuild active session.
- [x] Added regression assertion that recovered session becomes owned by current device in test.
- [x] `dart analyze` (targeted files) PASS.
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS.
- [x] Android RMX3771 + macOS manual validation PASS with post-fix logs (`2026-03-10_fix26_postfix_250c24d_macos_diag.log`, `2026-03-10_fix26_postfix_250c24d_android_RMX3771_diag.log`).
- [x] Confirm Firestore `activeSession/current` transitions out of stale `finished` state after reopen.

## 2026-03-10 Closure Evidence — `P0-F26-003` (commit `250c24d`)

- [x] Cross-device reopen in run mode lands on coherent segment (`Trading`, `Pomodoro 4 of 4`) with matching countdown.
- [x] No recurrence of `Pomodoro 2 of 1` or `00:00 Syncing session...` in postfix logs.
- [x] Log scan for critical signatures is clean in both files:
  - `sessionMissing=0`
  - `stream-missing-debounced=0`
  - `Missing snapshot=0`
  - `Syncing session=0`
  - `Unhandled Exception=0`
  - `cloud_firestore/unavailable=0`
  - `runningExpiry=0`
- [x] Owner handoff remains deterministic (`macOS -> Android`) with continuous `pomodoroRunning` snapshots on both devices.
- [x] Timer exactness confirmed against wall-clock + phase window (`16:39-17:04`) after second-level review; false alarm discarded as user misread break length (15 min).
- [x] Closure decision: `P0-F26-003` -> **Closed/OK** (10/03/2026).

## Fix 27 Evidence
- iOS log: `2026_03_07_fix27v2_ios_debug.log` line 51016 — `Auto-start opening TimerScreen` at 22:49:03 for group `c2b7f11d`.
- Chrome log: `2026_03_07_fix27v2_chrome_debug.log` lines 2086–2090 — `Active session change route=/tasks` → `Attempting auto-open` → `Auto-open confirmed in timer route=/timer/c2b7f11d`.
- Root cause: `ref.invalidate(scheduledGroupCoordinatorProvider)` was disposing the coordinator's listeners, creating a race window where Firestore stream data arrived before the new coordinator instance rebuilt its subscriptions.
- Fix: removed the invalidation — coordinator's `ref.listen<AppMode>` handles mode transitions naturally via `_resetForModeChange()` + `_handleGroups()`.
- Fix commit: Block 550 in dev_log.md.

## 2026-03-11 Phase 3 validation logs — second run (`f25f294`) — IN PROGRESS

- [ ] All 4 devices running without freeze (monitoring)
- [ ] HoldDiag events visible in debug logs (iOS/Chrome)
- [ ] Network cut repro test pending
- Log files:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-11_fix26_phase3_f25f294_macos_diag.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-11_fix26_phase3_f25f294_android_RMX3771_diag.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-11_fix26_phase3_f25f294_ios_iPhone17Pro_debug.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-11_fix26_phase3_f25f294_chrome_debug.log`

---

## 2026-03-11 Phase 2 validation logs captured (`8c6cb73`)

- [x] Existing running-group smoke logs captured (macOS + Android RMX3771).
- [x] New-group exact repro logs captured (iOS simulator + Chrome debug).
- Log files:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-11_fix26_phase2_8c6cb73_macos_diag.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-11_fix26_phase2_8c6cb73_android_RMX3771_diag.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-11_fix26_refactor_8c6cb73_ios_iPhone17Pro_debug.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-11_fix26_refactor_8c6cb73_chrome_debug.log`

---

## 2026-03-12 Phase 4 validation run (`744f83b`) — REPRODUCED

- Commit under validation: `744f83b` (Phase 4 runtime).
- Log files confirmed:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-12_fix26_phase4_744f83b_macos_diag.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-12_fix26_phase4_744f83b_android_RMX3771_diag.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-12_fix26_phase4_744f83b_ios_iPhone17Pro_debug.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-12_fix26_phase4_744f83b_chrome_debug.log`

### Timeline reported (device run)

- 12:43: Android started as owner (group execution started).
- 13:10: network cut 10s on macOS+iOS+Chrome (Android kept online); no visible UI impact during this cut.
- 13:12: ownership requested on iOS and granted (confirmed on device + Firestore).
- 13:33:39: Android (mirror) entered `Syncing session...`, timer screen showed `Ready` with `60:00`.
- 13:36:22: macOS entered the same state (`Syncing session...` + `Ready` + `60:00`).
- From then on, all devices eventually ended frozen; user-reported last to freeze was iOS (frozen without prolonged `Syncing session...` overlay).

### Firestore `activeSession/current` evidence (reported)

- 13:33:15 `lastUpdatedAt`, owner remained iOS:
  - `ownerDeviceId=iOS-2c0371a1-461c-4bab-b636-5b6e156a3b99`
  - `phase=pomodoro`
  - `phaseDurationSeconds=3600`
  - `phaseStartedAt=2026-03-12 13:13:01 (UTC+1)`
- 13:36:16 `lastUpdatedAt`: owner still iOS while mirrors already showed `Syncing session...`.
- 14:01:02 `lastUpdatedAt`: owner still iOS, `remainingSeconds=719`, backend still advancing while clients remained frozen.

### Preliminary log notes from this packet

- iOS/Chrome debug logs show continuous `[ActiveSession][snapshot]` and `[TimeSync]` lines through the failing window.
- iOS/Chrome trigger scan shows no `[SyncOverlay]` lines in this packet.
- iOS/Chrome include `Missing snapshot; clearing session` only around pre-run/startup window (~12:42), not at the reported freeze timestamps.
- Android/macOS runs were captured in release mode; logs are less diagnostic for overlay trigger reason than iOS/Chrome debug logs.

### Current closure status

- Phase 4 device validation: **FAIL (reproduced freeze in production-like run)**.
- Fix 26 remains **open**.

---

## 2026-03-13 Phase 5 validation run (`7daf636`) — IN PROGRESS

- Commit under validation: `7daf636` (Phase 5 runtime lifecycle observability).
- Objective: capture `[VMLifecycle]`, `[SessionSub]`, `[StaleClearDiag]`, `[ScheduledActionDiag]` to identify what closes `_sessionSub` during freeze.
- Log files:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase5_7daf636_android_RMX3771_diag.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase5_7daf636_ios_iPhone17Pro_debug.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase5_7daf636_macos_diag.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase5_7daf636_chrome_debug.log`

### Commands used

```bash
# Android RMX3771 (release)
flutter run -v --release -d 192.168.1.25:5555 \
  --dart-define=APP_ENV=prod \
  2>&1 | tee docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase5_7daf636_android_RMX3771_diag.log

# iOS iPhone 17 Pro (debug)
flutter run -v --debug -d 9A6B6687-8DE2-4573-A939-E4FFD0190E1A \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase5_7daf636_ios_iPhone17Pro_debug.log

# macOS (release)
flutter run -v --release -d macos \
  --dart-define=APP_ENV=prod \
  2>&1 | tee docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase5_7daf636_macos_diag.log

# Chrome (debug)
flutter run -v --debug -d chrome \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase5_7daf636_chrome_debug.log
```

### Key events to grep after run completes

```bash
# vmToken consistency (detect ViewModel recreation)
grep "\[VMLifecycle\]" <log>

# SessionSub close reason (detect what closed _sessionSub)
grep "\[SessionSub\]" <log>

# Stale-clear decisions during active session
grep "\[StaleClearDiag\]" <log>

# Scheduled actions near freeze timestamp
grep "\[ScheduledActionDiag\]" <log>

# SyncOverlay transitions
grep "\[SyncOverlay\]" <log>
```

### Root cause analysis (2026-03-13)

**Chrome (froze 15:30:36) — full trace recovered:**
```
15:30:08.572  [ActiveSession][snapshot] remaining=773 owner=macOS   ← last snapshot
15:30:24.996  [ActiveSession][snapshot] remaining=773               ← stale resync
+10017 ms     [SessionSub] close vmToken=b2ce33ee reason=provider-dispose
+9 ms         [VMLifecycle] dispose vmToken=b2ce33ee
+158 ms       [ScheduledGroups] timer-state runningExpiry=true
[RunModeDiag] Auto-open suppressed (opened=aa8794d0 route=/timer/aa8794d0)
```
No `[VMLifecycle] init` after dispose — screen stayed at `/timer/...` with dead VM → `Ready + 25:00`.

**iOS (froze 15:35:16):** identical pattern. `provider-dispose` 18.6s after last Firestore activity.

**Android/macOS:** release logs have no Phase 5 diagnostic events (release mode filters them).
macOS crash at 15:48:18 (SIGSEGV from Firestore transaction) is a separate issue.

**Root cause confirmed (two sub-bugs):**

- **B1**: `autoDispose` + `_keepAliveLink` race — keepAlive closes during 10s Firestore
  quiet window → Riverpod disposes VM while session still active in Firestore.
- **B2**: `_autoOpenedGroupId == groupId` guard in `ActiveSessionAutoOpener` blocks
  re-navigation even after VM is dead. `ref.exists()` not checked.

**Phase 6 fix plan:** see `docs/specs.md` section 10.4.9.

### Current closure status

- Phase 5 device validation: **COMPLETE — root cause confirmed 2026-03-13**.
- Phase 6 runtime (B1+B2): **IMPLEMENTED (local validation PASS, 2026-03-13)**.
- Phase 6 device validation: **FAILED** (exact repro REPRODUCED 2026-03-14; pass 2 cancelled; architecture rewrite required).

### Phase 6 local validation evidence (2026-03-13)

```bash
dart analyze \
  lib/presentation/viewmodels/pomodoro_view_model.dart \
  lib/widgets/active_session_auto_opener.dart \
  test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart \
  test/presentation/timer_screen_syncing_overlay_test.dart
# PASS (2 pre-existing info hints in test helper)

flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart \
  --plain-name "[PHASE6]" --reporter compact
# PASS

flutter test test/presentation/timer_screen_syncing_overlay_test.dart \
  --plain-name "[PHASE6]" --reporter compact
# PASS
```

### Phase 6 device runbook (P0-F26-005)

Validation devices (fixed):
- Android: `RMX3771`
- iOS: `iPhone 17 Pro`
- Desktop: `macOS`
- Web: `Chrome`

#### Pass 1 (today, 1h) — log capture commands

```bash
LOG_DIR="docs/bugs/validation_fix_2026_03_07-01/logs"
mkdir -p "$LOG_DIR"

# Android RMX3771 (debug)
flutter run -v --debug -d "RMX3771" \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-13_fix26_phase6_2fc65e4_pass1_1h_android_RMX3771_debug.log"

# iOS iPhone 17 Pro (debug)
flutter run -v --debug -d "iPhone 17 Pro" \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-13_fix26_phase6_2fc65e4_pass1_1h_ios_iPhone17Pro_debug.log"

# macOS (debug)
flutter run -v --debug -d macos \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-13_fix26_phase6_2fc65e4_pass1_1h_macos_debug.log"

# Chrome (debug)
flutter run -v --debug -d chrome \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-13_fix26_phase6_2fc65e4_pass1_1h_chrome_debug.log"
```

#### Pass 2 (tomorrow, 4h30) — log capture commands

```bash
LOG_DIR="docs/bugs/validation_fix_2026_03_07-01/logs"
mkdir -p "$LOG_DIR"

# Android RMX3771 (debug)
flutter run -v --debug -d "RMX3771" \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_phase6_2fc65e4_pass2_4h30_android_RMX3771_debug.log"

# iOS iPhone 17 Pro (debug)
flutter run -v --debug -d "iPhone 17 Pro" \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_phase6_2fc65e4_pass2_4h30_ios_iPhone17Pro_debug.log"

# macOS (debug)
flutter run -v --debug -d macos \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_phase6_2fc65e4_pass2_4h30_macos_debug.log"

# Chrome (debug)
flutter run -v --debug -d chrome \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_phase6_2fc65e4_pass2_4h30_chrome_debug.log"
```

#### Phase 6 event checks after each pass

```bash
grep -E "\[VMLifecycle\]|\[SessionSub\]|\[SyncOverlay\]|\[HoldDiag\]|Auto-open recovery" <log>
grep -E "provider-dispose|resume-rebind|Unhandled Exception|SIGSEGV|EXC_BAD_ACCESS" <log>
```

If a device selector by name fails, run `flutter devices` and replace `-d "<name>"`
with the concrete device id.

## 2026-03-14 Rewrite Stage B device packet (P0-F26-006) — exact repro pass 1 (1h)

Status: **FAILED — exact repro REPRODUCED (2026-03-14)**

Validation devices (exact IDs):
- Android USB: `HYGUT4GMJJOFVWSS` (RMX3771)
- iOS: `9A6B6687-8DE2-4573-A939-E4FFD0190E1A` (iPhone 17 Pro)
- macOS: `macos`
- Chrome: `chrome`

Scenario protocol (exact repro target):
- No manual network cut.
- No manual pause/resume action.
- Let active session run for 1h and observe spontaneous hold path behavior.

```bash
LOG_DIR="/Users/devcodex/development/focus_interval/docs/bugs/validation_fix_2026_03_07-01/logs"
mkdir -p "$LOG_DIR"

# Android RMX3771 via USB (debug)
flutter run -v --debug -d HYGUT4GMJJOFVWSS \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_rewrite_stageB_3b11847_pass1_1h_android_HYGUT4GMJJOFVWSS_debug.log"

# iPhone 17 Pro (debug)
flutter run -v --debug -d 9A6B6687-8DE2-4573-A939-E4FFD0190E1A \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_rewrite_stageB_3b11847_pass1_1h_ios_iPhone17Pro_9A6B6687_debug.log"

# macOS (debug)
flutter run -v --debug -d macos \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_rewrite_stageB_3b11847_pass1_1h_macos_debug.log"

# Chrome (debug)
flutter run -v --debug -d chrome \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_rewrite_stageB_3b11847_pass1_1h_chrome_debug.log"
```

Log URLs (repo-relative):
- `/docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-14_fix26_rewrite_stageB_3b11847_pass1_1h_android_HYGUT4GMJJOFVWSS_debug.log`
- `/docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-14_fix26_rewrite_stageB_3b11847_pass1_1h_ios_iPhone17Pro_9A6B6687_debug.log`
- `/docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-14_fix26_rewrite_stageB_3b11847_pass1_1h_macos_debug.log`
- `/docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-14_fix26_rewrite_stageB_3b11847_pass1_1h_chrome_debug.log`

Execution notes (reported timeline):
- Planned group: `1e8e5564-9617-4a40-879b-1a8bbe18435a` (scheduled by Android).
- Pre-run entered at `13:14:00`; run started at `13:15:00` (expected).
- Initial owner at run start: macOS.
- `13:30:40` Android switched Wi-Fi -> mobile data; `13:30:50` switched back to Wi-Fi (no immediate issue).
- `13:32:00` Wi-Fi cut for `15s` on macOS/iOS/Chrome: no `Syncing session...` shown.
- `13:43:33` Android to background; `13:45:33` foreground resume: continued correctly.
- `14:01:21` Android (mirror) entered `Syncing session...` with background in `Ready 15:00`.
- `14:01:53` macOS (owner) entered `Syncing session...` with timer frozen at `08:09`.
- `14:02:07` Chrome entered `Syncing session...` with background in `Ready 15:00`.
- `14:02:14` iOS entered `Syncing session...` with background in `Ready 15:00`.
- `14:02:15` macOS removed `Syncing session...` overlay but remained frozen (`08:09`).
- `14:04:18` state still frozen while backend `current` continued running (`status=pomodoroRunning`, `remainingSeconds=347`, `ownerDeviceId=macOS...`).

Result:
- **FAIL**. Stage B local green (`[REWRITE-CORE]` + smoke) did not hold on real-device exact repro.
- Cascading `Syncing session...` and frozen/ready fallback screens are still reproducible across all four devices.

## 2026-03-14 Rewrite Stage C device packet (baseline `c0add32`) — command reference

Status: **PLANNED** (normalized run commands for copy/paste)

```bash
LOG_DIR="/Users/devcodex/development/focus_interval/docs/bugs/validation_fix_2026_03_07-01/logs"
mkdir -p "$LOG_DIR"

# Android RMX3771 via USB (debug)
flutter run -v --debug -d HYGUT4GMJJOFVWSS \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_rewrite_stageC_c0add32_pass1_1h_android_HYGUT4GMJJOFVWSS_debug.log"

# iPhone 17 Pro (debug)
flutter run -v --debug -d 9A6B6687-8DE2-4573-A939-E4FFD0190E1A \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_rewrite_stageC_c0add32_pass1_1h_ios_iPhone17Pro_9A6B6687_debug.log"

# macOS (debug)
flutter run -v --debug -d macos \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_rewrite_stageC_c0add32_pass1_1h_macos_debug.log"

# Chrome (debug)
flutter run -v --debug -d chrome \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_rewrite_stageC_c0add32_pass1_1h_chrome_debug.log"
```
