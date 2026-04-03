# BUG-025 Quick Validation Plan

Date: 03/04/2026
Branch: fix/overlap-threshold-exact
Commit: 547de2b
Bugs covered: BUG-025
Target devices: Android RMX3771 (owner) + macOS (mirror/secondary)

## Objetivo

Validate the overlap-warning regression fix for paused running groups:
1) overlap must trigger at the exact conflict boundary (`runningEnd >= preRunStart`, no extra +1 minute),
2) Run Mode must consume an already-active overlap decision when entering/re-entering TimerScreen.

## Sintoma original

When a running group was paused and the next scheduled group reached its pre-run/start conflict boundary, the overlap decision UI could fail to appear (or appear too late). In practice, users could remain with an unresolved running/scheduled conflict without seeing the expected modal in Run Mode, even after conflict time had passed.

## Root cause

- `lib/presentation/utils/scheduled_group_timing.dart`
  - Overlap threshold used an extra 1-minute grace (`preRunStart + 1 minute`), delaying/neutralizing valid boundary conflicts.
- `lib/presentation/screens/timer_screen.dart`
  - Run Mode consumed overlap decisions only on provider changes (`ref.listen`), but not reliably when entering with an already-active decision.
  - Initial frame could evaluate against loading group stream, causing premature clear paths in edge timing.

## Protocolo de validacion

### Scenario A — Exact boundary conflict while paused (owner in Run Mode)

Preconditions:

1. Account Mode.
2. One running group (`G1`) owned by current device.
3. One scheduled group (`G2`) after `G1`.
4. `G1` paused with projected running end equal to `G2` pre-run start (or start if notice=0).

Steps:

1. Open Run Mode for `G1` on owner device.
2. Keep `G1` paused; wait until the exact boundary second.
3. Observe UI at boundary.

Expected result with fix:

- `Scheduling conflict` modal appears at the exact conflict boundary second.
- No extra 1-minute delay.

Reference result without fix:

- Modal appears late (after +1 minute) or never appears for boundary-equal cases.

### Scenario B — Decision already active before entering Run Mode

Preconditions:

1. Overlap decision already active in provider/coordinator context (conflict exists).
2. User is outside TimerScreen (e.g., Groups Hub or another route).

Steps:

1. Navigate to `/timer/:runningGroupId`.
2. Wait for first frame + group load.

Expected result with fix:

- TimerScreen consumes the existing decision and shows `Scheduling conflict` without requiring a new provider change.

Reference result without fix:

- No modal shown until a fresh decision emission happens.

### Scenario C — Re-enter Run Mode after route switch with ongoing conflict

Preconditions:

1. Conflict remains active.
2. User leaves TimerScreen and comes back to same/different running group route where conflict still applies.

Steps:

1. Exit TimerScreen.
2. Re-enter TimerScreen.

Expected result with fix:

- Existing active decision is consumed after load/re-entry and modal is shown (if still valid).

Reference result without fix:

- Modal may be skipped because no new decision event fires on route re-entry.

### Scenario D — Regression smoke (postpone duplicate suppression)

Preconditions:

1. Running overlap modal appears.

Steps:

1. Choose `Postpone scheduled`.
2. Confirm the modal closes.
3. Ensure no immediate duplicate overlap modal appears for same decision pair.

Expected result with fix:

- Existing suppression behavior remains intact (no duplicate immediate modal).

Reference result without fix:

- Potential immediate duplicate modal loop.

## Comandos de ejecucion

```bash
cd /Users/devcodex/development/focus_interval && flutter run -v --debug -d RMX3771 --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true 2>&1 | tee docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_android_RMX3771_debug.log
```

```bash
cd /Users/devcodex/development/focus_interval && flutter run -v --debug -d macos --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true 2>&1 | tee docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_macos_debug.log
```

```bash
cd /Users/devcodex/development/focus_interval && flutter analyze 2>&1 | tee docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_local_analyze.log
```

```bash
cd /Users/devcodex/development/focus_interval && flutter test test/presentation/utils/scheduled_group_timing_test.dart test/presentation/viewmodels/scheduled_group_coordinator_test.dart test/presentation/timer_screen_completion_navigation_test.dart 2>&1 | tee docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_local_targeted-tests.log
```

## Log analysis - quick scan

### Bug present signals

```bash
grep -nE "Some tests failed|Expected: exactly one matching candidate|Exception caught by flutter test framework" docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_local_targeted-tests.log
```

### Fix working signals

```bash
grep -nE "running overlap threshold treats exact pre-run boundary as conflict|flags overlap at exact pre-run start boundary|shows running-overlap modal when decision already exists on mount|All tests passed!" docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_local_targeted-tests.log
```

```bash
grep -n "No issues found!" docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_local_analyze.log
```

## Verificacion local

- [x] `flutter analyze` PASS recorded in packet log (`2026-04-03_bug025_547de2b_local_analyze.log`).
- [x] Targeted overlap test pack PASS recorded in packet log (`2026-04-03_bug025_547de2b_local_targeted-tests.log`).

## Criterios de cierre

1. Scenario A PASS on device (exact boundary trigger, no +1m delay).
2. Scenario B PASS on device (existing decision consumed on TimerScreen enter).
3. Scenario C PASS on device (re-entry consumes still-valid active decision).
4. Scenario D regression smoke PASS (no duplicate immediate overlap modal after postpone).
5. Local gate logs (`analyze` + targeted tests) attached in packet.
6. Evidence added to `quick_pass_checklist.md` + screenshots/log references.

Status: In validation
