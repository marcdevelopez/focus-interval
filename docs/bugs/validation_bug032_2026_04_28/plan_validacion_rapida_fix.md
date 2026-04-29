# BUG-032 Quick Validation Plan

## 1. Header

- Date: 29/04/2026
- Branch: `fix/bug032-paused-session-expiry-guard`
- Base commit: `5df97ec` (working tree with uncommitted BUG-032 patch)
- Bug(s): `BUG-032`
- Target devices: Android RMX3771 + macOS (Account Mode, ownership transfer via sleep/background)
- Status: `In validation`

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

### Scenario A - Primary repro guard (paused must not complete)

Preconditions:

1. Account Mode with a running group.
2. Ownership changes after sleep/background (macOS sleep -> Android owner).
3. Group is paused on owner device.

Steps:

1. Keep Android in background for a window that crosses group `theoreticalEndTime`.
2. Reopen Android and macOS.
3. Inspect Run Mode and Groups Hub status.

Expected with fix:

- Group remains paused (not completed).
- No auto-complete from null-session expiry path.

Reference without fix:

- Group can appear completed after reopen.

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
  2>&1 | tee docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_5df97ec_android_RMX3771_debug.log
```

macOS debug run:

```bash
flutter run -v --debug -d macos --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_5df97ec_macos_debug.log
```

Local gate:

```bash
flutter analyze \
  2>&1 | tee docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_5df97ec_local_analyze_debug.log

flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart \
  2>&1 | tee docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_5df97ec_coordinator_tests_debug.log
```

Focused BUG-032 cases:

```bash
flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "does not complete expired running group when stream is null but server has paused session for same group" \
  2>&1 | tee docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_5df97ec_case_paused_server_debug.log

flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "completes expired running group without active session and routes to Groups Hub" \
  2>&1 | tee docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_5df97ec_case_zombie_run_debug.log
```

## 7. Log analysis - quick scan

Bug-present signatures:

```bash
grep -n "expire-running-groups-no-active-session\\|mark-running-group-completed\\|Resync missing; no session snapshot\\|Syncing session" \
  docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_5df97ec_android_RMX3771_debug.log \
  docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_5df97ec_macos_debug.log
```

Fix-working signatures:

```bash
grep -n "skip-expiry-no-active-session-server-session\\|skip-expiry-session-not-running\\|does not complete expired running group when stream is null but server has paused session for same group\\|All tests passed!" \
  docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_5df97ec_coordinator_tests_debug.log \
  docs/bugs/validation_bug032_2026_04_28/logs/2026-04-29_bug032_5df97ec_case_paused_server_debug.log
```

## 8. Local verification

- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` -> PASS (`All tests passed!`).
- `flutter analyze` -> PASS (`No issues found!`).

## 9. Closure criteria

Close BUG-032 only when all are PASS:

1. Exact paused ownership-transfer repro does not auto-complete.
2. Zombie-run legitimate completion still works when session is truly absent.
3. Regression smoke on coordinator suite stays green.
4. Evidence captured in logs/screenshots and checklist.
5. `bug_log`, `validation_ledger`, and `dev_log` synchronized with final closure commit.

## 10. Status line

Status: `In validation` (Phase 1 implemented; device repro pending).
