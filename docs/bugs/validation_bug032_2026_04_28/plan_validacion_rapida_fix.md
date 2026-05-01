# BUG-032 Quick Validation Plan

## 1. Header

- Date: 29/04/2026
- Branch: `fix/bug032-paused-session-expiry-guard`
- Base runtime commit: `69472d7` (BUG-032 Phase 1 guard)
- Doc sync commit: `cefac60`
- Bug(s): `BUG-032`
- Target devices: Android RMX3771 + macOS (Account Mode, ownership transfer via real macOS sleep/lid close; Firestore inspection deferred until macOS wake)
- Status: `Closed/OK` (29/04/2026)

## 2. Objective

Validate and harden the BUG-032 fix so a legitimately paused run cannot be auto-completed by the coordinator expiry path when `activeSession` is temporarily null after ownership/sleep/background transitions.

## 3. Original symptom

After owner transition caused by macOS sleep, Android paused the session and showed a long `Syncing session...` window. Later, reopening showed the group as `completed` even though it should have remained paused and non-advancing.

## 4. Root cause

In `ScheduledGroupCoordinator._handleGroups`, the `activeSession == null` branch could complete expired `running` groups based only on group timeline (`theoreticalEndTime`) without server-side session corroboration.  
When stream/session visibility was transiently null, paused/running sessions still present on server could be ignored and the group incorrectly completed.

Implemented guard (Phase 1 only):

- File: `lib/presentation/viewmodels/scheduled_group_coordinator.dart`
- Path: `activeSession == null` running-expiry branch.
- Behavior: fetch `fetchSession(preferServer: true)` and suppress completion when:
  - `session != null`
  - `session.status.isActiveExecution == true`
  - `session.groupId` matches one of the currently running groups.

This preserves legitimate zombie-run completion when server also has no relevant active session.

## 5. Validation protocol

### Single-run constraint (approved adaptation)

- Validation will be executed in one continuous run with a short group (`~15 min`) to reduce waiting time.
- Exact state checks on Firestore/macOS are collected after macOS wake (owner slept with lid closed, so no live inspection during sleep window).
- This is valid because BUG-032 outcome is judged by post-reopen state consistency (`paused` vs `completed`) across Android + server evidence.

### Scenario A - Primary repro guard (single-run short repro, mandatory)

Preconditions:

1. Account Mode with a short group (`~15 min total`) so `theoreticalEndTime` is crossed quickly.
2. Initial owner is macOS.
3. Android is available as secondary device and can become owner.

Steps:

1. Start run on macOS (confirm owner on session panel/diag).
2. Close macOS lid (real system sleep).
3. Wait until Android takes ownership (expected inactivity transfer).
4. On Android owner, press `Pause`.
5. Leave Android in background while wall-clock passes group `theoreticalEndTime`.
6. Reopen Android and inspect Timer + Groups Hub state immediately.
7. Wake macOS, reopen app, and capture final cross-device/server evidence.

Expected with fix:

- Android remains `paused` (not `completed`) after reopen, even if `theoreticalEndTime` passed.
- Group does not auto-complete from null-session expiry path.
- macOS/server view converges to the same paused/non-terminal state after wake/resync.

Reference without fix:

- Android can reopen to `completed` and lose resume path.
- Cross-device state becomes incoherent (paused-looking local remnants vs completed group in hub/server).

### Scenario B - Null stream + server paused session (deterministic unit path)

Preconditions:

1. `activeSession` stream observed as null.
2. Server returns paused/active execution session for same group.

Steps:

1. Trigger coordinator reevaluation.
2. Verify group state after evaluation.

Expected with fix:

- Group status stays `running` (not force-completed).

### Scenario C - Legitimate zombie-run closure remains valid

Preconditions:

1. Running group already expired by timeline.
2. `activeSession` stream null and server session null (or unrelated group).

Steps:

1. Trigger coordinator reevaluation.
2. Verify action and persistence.

Expected with fix:

- Expired running group is completed.
- Coordinator routes to Groups Hub when appropriate.

### Scenario D - Regression smoke (existing expiry/autostart flow)

Steps:

1. Run scheduled coordinator test suite.
2. Confirm no regressions in stale-clear, running expiry, and auto-start paths.

Expected with fix:

- Existing tests remain green.

## 6. Execution commands

From repo root:

```bash
cd /Users/devcodex/development/focus_interval
```

Android debug run:

```bash
flutter run -v --debug -d RMX3771 --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_69472d7_android_RMX3771_debug.log
```

macOS debug run:

```bash
flutter run -v --debug -d macos --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_69472d7_macos_debug.log
```

Local gate:

```bash
flutter analyze \
  2>&1 | tee docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_69472d7_local_analyze_debug.log

flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart \
  2>&1 | tee docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_69472d7_coordinator_tests_debug.log
```

Focused BUG-032 cases:

```bash
flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "does not complete expired running group when stream is null but server has paused session for same group" \
  2>&1 | tee docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_69472d7_case_paused_server_debug.log

flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "completes expired running group without active session and routes to Groups Hub" \
  2>&1 | tee docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_69472d7_case_zombie_run_debug.log
```

## 7. Log analysis - quick scan

Bug-present signatures:

```bash
grep -n "expire-running-groups-no-active-session\\|mark-running-group-completed\\|Resync missing; no session snapshot\\|Syncing session" \
  docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_69472d7_android_RMX3771_debug.log \
  docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_69472d7_macos_debug.log
```

Fix-working signatures:

```bash
grep -n "skip-expiry-no-active-session-server-session\\|skip-expiry-session-not-running\\|does not complete expired running group when stream is null but server has paused session for same group\\|All tests passed!" \
  docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_69472d7_coordinator_tests_debug.log \
  docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_69472d7_case_paused_server_debug.log
```

## 8. Local verification

- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` -> PASS (`All tests passed!`).
- `flutter analyze` -> PASS (`No issues found!`).
- Device single-run repro PASS (29/04/2026):
  - Android reopened after `theoreticalEndTime` and remained paused with `Resume` available (not completed).
  - Android smoke PASS: resumed ~20-30s and elapsed time progressed normally, then paused again with no forced completion/terminal jump.
  - macOS post-wake logs show repeated paused snapshots and expiry skips without completion writes:
    - `[ExpiryCheck][skip-expiry-session-not-running]`
    - `[RepoNormalize][skip-complete] groupId=a4d46289-18b7-45d1-b8e2-486036a5daff ... theoreticalEndTime=2026-04-29 12:23:22.709404 ... now=12:40..12:43`
  - Firestore `activeSession` snapshot confirms non-terminal paused state after theoretical end:
    - `status=paused`, `ownerDeviceId=android-029abc12-52ba-4d42-bcca-eda2aaaf257e`, `remainingSeconds=722`, `lastUpdatedAt=2026-04-29 12:43:52` (UTC-4).
- Evidence artifacts:
  - Logs:
    - `docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_69472d7_android_RMX3771_debug.log`
    - `docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_69472d7_macos_debug.log`
  - Screenshots:
    - `docs/bugs/validation_bug032_2026_04_28/screenshots/Captura de pantalla 2026-04-29 a las 12.44.51.png`
    - `docs/bugs/validation_bug032_2026_04_28/screenshots/Captura de pantalla 2026-04-29 a las 12.45.19.png`
    - `docs/bugs/validation_bug032_2026_04_28/screenshots/Captura de pantalla 2026-04-29 a las 12.46.14.png`
      - `12.45.19`: resumed/running state (`Pause` visible).
      - `12.46.14`: paused-again state (`Resume` visible).

## 9. Closure criteria

Close BUG-032 only when all are PASS:

1. Exact paused ownership-transfer repro does not auto-complete.
2. Zombie-run legitimate completion still works when session is truly absent.
3. Regression smoke on coordinator suite stays green.
4. Evidence captured in logs/screenshots and checklist.
5. `bug_log`, `validation_ledger`, and `dev_log` synchronized with final closure commit.
6. Single-run short repro evidence includes:
   - Android reopen timestamp after `theoreticalEndTime`,
   - macOS post-wake state capture,
   - Firestore/group snapshot captured after wake.

## 10. Status line

Status: `Closed/OK` (29/04/2026, single-run device repro + local gate PASS).
