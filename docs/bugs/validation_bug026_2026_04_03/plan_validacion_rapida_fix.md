# BUG-026 Quick Validation Plan

Date: 03/04/2026
Branch: fix/bug026-owner-autostart-routing
Base commit: 018b6e6 (working tree contains uncommitted WIP)
Bug(s): BUG-026
Target devices: Android RMX3771 (owner), macOS (mirror)
Status: Closed/OK (2026-04-24, user-confirmed)

## Objective

Capture the exact current implementation status for BUG-026, preserve validated root-cause evidence, and define the next deterministic execution steps to finish the fix in the next session.

## Original symptom

From Plan Group (Start now), Android owner shows snackbar "Task group started." but does not reliably land in Run Mode. During the same window, macOS mirror can stay on a black Syncing screen with an inert Start CTA until the first activeSession snapshot arrives.

User-observed timeline:

- 13:55:07: Confirm on Android Start now.
- 13:55:07-13:55:24: Owner does not consistently stay in Run Mode; mirror shows Syncing session.
- 13:55:24: first activeSession snapshot arrives; both devices recover.

## Root cause

### Confirmed and already patched locally (not committed yet)

1. Stale canceled-group race in TimerScreen listeners:

- In TimerScreen VM listener, canceled navigation could trigger from VM group state without strict group-id match.
- Local WIP patch adds guard: navigate to Groups Hub only when `group.id == widget.groupId`.
- File: lib/presentation/screens/timer_screen.dart

### Still open / pending final fix

2. Owner auto-open churn while activeSession is still null:

- During Start now propagation gap (session not yet persisted/visible), coordinator can emit repeated openTimer actions.
- Owner route can churn between Task List/Groups Hub/Timer depending on timing and listener interleaving.
- Requires deterministic dedupe/serialization for owner auto-open path.

3. Mirror CTA contract during runningWithoutSession hold:

- Mirror can show Start while no session snapshot is available, but CTA is non-actionable by design.
- Requires explicit UI gating (disable/hide Start for mirror during runningWithoutSession hold).

## Protocol

### Scenario A - Exact owner flow (primary)

Preconditions:

1. Account Mode on Android owner + macOS mirror.
2. Existing running/scheduled overlap context matching BUG-026 reproduction.

Steps:

1. In Plan Group on Android, confirm Start now at T0.
2. Observe route transitions and logs for 20 seconds.
3. Verify owner lands and remains in /timer/:groupId without manual Open Run Mode tap.

Expected with fix:

- Single deterministic owner navigation to Timer.
- No bounce back to /tasks or /groups during startup.

Reference without fix:

- Route churn and manual Open Run Mode required.

### Scenario B - Mirror hold behavior

Preconditions:

1. Same session as Scenario A.

Steps:

1. Observe mirror UI between T0 and first activeSession snapshot.
2. Attempt Start from mirror while hold is active.

Expected with fix:

- Mirror shows Syncing indicator, but Start is not actionable (disabled/hidden).
- Mirror hydrates automatically once snapshot arrives.

Reference without fix:

- Inert Start appears during hold.

### Scenario C - Regression (valid cancel)

Preconditions:

1. Timer open for group Gx.
2. Gx becomes canceled.

Steps:

1. Trigger canceled state for displayed group.

Expected with fix:

- Timer navigates to Groups Hub once (existing behavior preserved).

### Scenario D - Regression (stale canceled mismatch)

Preconditions:

1. Timer displays group Gy.
2. VM transiently contains canceled state from another group Gz.

Steps:

1. Reproduce delayed load/mismatch state during listener callbacks.

Expected with fix:

- No unexpected navigation to Groups Hub.
- Timer for Gy remains stable.

## Execution commands

From repo root:

```bash
cd /Users/devcodex/development/focus_interval
```

Android owner debug capture:

```bash
flutter run -v --debug -d RMX3771 --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug026_2026_04_03/logs/2026-04-03_bug026_018b6e6_android_RMX3771_debug.log
```

macOS mirror debug capture:

```bash
flutter run -v --debug -d macos --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug026_2026_04_03/logs/2026-04-03_bug026_018b6e6_macos_debug.log
```

Local gate (must run after implementation is stabilized):

```bash
flutter analyze \
  2>&1 | tee docs/bugs/validation_bug026_2026_04_03/logs/2026-04-03_bug026_018b6e6_local_analyze_debug.log

flutter test test/presentation/timer_screen_completion_navigation_test.dart \
  2>&1 | tee docs/bugs/validation_bug026_2026_04_03/logs/2026-04-03_bug026_018b6e6_timer_completion_debug.log

flutter test test/presentation/timer_screen_syncing_overlay_test.dart \
  2>&1 | tee docs/bugs/validation_bug026_2026_04_03/logs/2026-04-03_bug026_018b6e6_timer_sync_overlay_debug.log
```

Focused single-case stale-cancel regression check:

```bash
flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Timer ignores stale canceled vm group when displayed group id differs"
```

## Log analysis - quick scan

Bug-present signatures:

```bash
grep -n "running-open-timer\|ScheduledActionDiag\|Auto-start navigate\|Resync missing; no session snapshot\|runningWithoutSession" \
  docs/bugs/validation_bug026_2026_04_03/logs/2026-04-03_bug026_018b6e6_android_RMX3771_debug.log

grep -n "Resync missing; no session snapshot\|SyncOverlay\|Auto-start attempt\|Auto-start startFromAutoStart" \
  docs/bugs/validation_bug026_2026_04_03/logs/2026-04-03_bug026_018b6e6_macos_debug.log
```

Fix-working signatures:

```bash
grep -n "Auto-start navigate group=.*route=/timer/\|Timer load group=.*status=running route=/timer/" \
  docs/bugs/validation_bug026_2026_04_03/logs/2026-04-03_bug026_018b6e6_android_RMX3771_debug.log

grep -n "SyncOverlay.*overlayVisibleAfter=false\|ActiveSession\[snapshot\].*status=pomodoroRunning" \
  docs/bugs/validation_bug026_2026_04_03/logs/2026-04-03_bug026_018b6e6_macos_debug.log
```

## Local verification

Current state snapshot (this branch, not yet finalized):

- TimerScreen canceled navigation guard active with strict displayed-group matching.
- Stale canceled mismatch regression test stabilized and passing.
- Scheduling overlap tests aligned with current planning behavior (pre-run-only overlap no longer blocks scheduling).

Validation update (2026-04-24):

- Scenario A PASS (Android owner): Start now landed in Timer and stayed stable (user run around 14:21:35).
- Scenario B PASS (macOS mirror): no inert Start CTA observed; no blocking/loop behavior reported.
- Scenario C PASS: cancel from Android (around 14:23:40) navigated to Groups Hub once, fluid, no loops.
- Scenario D PASS: stale canceled mismatch test passes and no longer hangs.
- Local gate PASS with fresh logs:
  - `docs/bugs/validation_bug026_2026_04_03/logs/2026-04-24_bug026fast_retry_018b6e6_local_analyze_debug.log`
  - `docs/bugs/validation_bug026_2026_04_03/logs/2026-04-24_bug026fast_retry_018b6e6_timer_completion_debug.log`
  - `docs/bugs/validation_bug026_2026_04_03/logs/2026-04-24_bug026fast_retry_018b6e6_timer_sync_overlay_debug.log`
  - `docs/bugs/validation_bug026_2026_04_03/logs/2026-04-24_bug026fast_retry_018b6e6_timer_stale_cancel_debug.log`

Mandatory before closure:

- `flutter analyze` PASS.
- `timer_screen_completion_navigation_test.dart` PASS.
- `timer_screen_syncing_overlay_test.dart` PASS.
- Scenario A/B device validation PASS with log evidence.

## Closure criteria

Close BUG-026 only when all conditions are met:

1. Exact repro PASS (owner auto-opens to Timer without manual intervention).
2. Mirror hold UX PASS (no inert Start CTA during runningWithoutSession).
3. Regression smoke PASS (valid cancel still navigates, stale mismatch does not).
4. Local gate PASS (analyze + focused test suites).
5. Evidence registered in logs/checklist and synced in bug_log + validation_ledger + dev_log.

Status: Closed/OK (all checks PASS; user-confirmed 2026-04-24)
