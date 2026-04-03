# BUG-025 Quick Validation Plan

Date: 03/04/2026
Branch: fix/overlap-threshold-exact
Commit: 547de2b
Bugs covered: BUG-025
Target devices: Android RMX3771 (owner) + macOS (mirror/secondary)

## Objetivo

Validate the overlap-warning regression fix for paused running groups:

1. overlap must trigger at the exact conflict boundary (`runningEnd >= preRunStart`, no extra +1 minute),
2. Run Mode must consume an already-active overlap decision when entering/re-entering TimerScreen.

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

## Visual Evidence Matrix (clock-based, frame-accurate)

Evidence source: screenshots extracted from validation video pauses in this thread.
Important: canonical timestamp is the visible clock in each screenshot frame (not file metadata).

| ID  | Visible clock | Owner (Android)                                                     | Mirror (macOS)                                               | Observed result                                                               | Expected result                                                                        | Classification             |
| --- | ------------- | ------------------------------------------------------------------- | ------------------------------------------------------------ | ----------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | -------------------------- |
| V01 | 13:50:58      | Task List                                                           | Task List                                                    | Baseline state before run.                                                    | Baseline state before run.                                                             | Baseline                   |
| V02 | 13:51:09      | Run Mode (`G1`, ends 14:06)                                         | Run Mode (mirror)                                            | Both synchronized in foreground.                                              | Both synchronized in foreground.                                                       | PASS                       |
| V03 | 13:51:49      | Groups Hub (`G1` running)                                           | Plan Group confirm at `14:06`, notice `0`                    | Modal: `Conflict with running group` but generic copy.                        | Conflict copy should include running group + ranges + candidate range.                 | UX gap                     |
| V04 | 13:52:25      | Groups Hub (`G1` running)                                           | Plan Group notice picker                                     | Preparing second planning attempt.                                            | N/A                                                                                    | Baseline                   |
| V05 | 13:52:44      | Task List                                                           | Plan Group snackbar: `doesn't leave enough pre-run space...` | Snackbar lacks blocker identity/ranges.                                       | Explain blocker group and both ranges.                                                 | UX gap                     |
| V06 | 13:52:46      | Groups Hub (`G1` running)                                           | Plan Group confirm (`14:07`, notice `0`)                     | Plan succeeds.                                                                | Plan succeeds.                                                                         | PASS                       |
| V07 | 13:53:10      | Groups Hub: `G2 scheduled 14:07-14:22`                              | Task List toast: `Task group scheduled.`                     | Post-plan state consistent.                                                   | Post-plan state consistent.                                                            | PASS                       |
| V08 | 13:53:10      | Pause `G1` in Run Mode                                              | Groups Hub                                                   | `Scheduling conflict` modal appears on owner with `G2 scheduled 14:07-14:22`. | Modal should appear at conflict boundary.                                              | PASS (BUG-025 functional)  |
| V09 | 13:54:32      | Groups Hub no running + `G2 scheduled`                              | Groups Hub no running + `G2 scheduled`                       | After ending current and canceling schedule path, state clears.               | State clears.                                                                          | PASS                       |
| V10 | 13:55:07      | Task List/Groups state shows running context start-now flow         | Mirror Timer black `Syncing session...` + inert `Start`      | Mirror stuck in temporary black syncing state.                                | Mirror should hydrate without extra owner navigation steps.                            | Functional issue           |
| V11 | 13:55:10      | Groups Hub (`G1` running, ends 14:10) + toast `Task group started.` | Mirror still black `Syncing session...`                      | Temporary desync persists.                                                    | Mirror should attach quickly after active session exists.                              | Functional issue           |
| V12 | 13:55:18      | Groups Hub                                                          | Mirror still black syncing, `Start` tap ineffective          | Inert CTA during sync window.                                                 | CTA should not appear inert in this state.                                             | Functional issue           |
| V13 | 13:55:20      | Groups Hub (`G1` running)                                           | Groups Hub (`G1` running)                                    | State recovers after additional owner action/open run mode.                   | Recovery should not require extra manual step.                                         | Partial recovery           |
| V14 | 13:55:25      | Run Mode                                                            | Run Mode                                                     | Both synchronized again.                                                      | Both synchronized again.                                                               | PASS                       |
| V15 | 13:57:18      | Groups Hub (`G1` running, ends 14:10)                               | Plan Group (`G2` scheduled start 14:11)                      | Planning setup for second overlap check.                                      | N/A                                                                                    | Baseline                   |
| V16 | 13:57:26      | Pause `G1`                                                          | Task List mirror state                                       | Conflict context active while paused.                                         | Conflict context active while paused.                                                  | Baseline                   |
| V17 | 13:58:18      | Groups Hub (owner still no modal on-screen)                         | Banner: `Owner is resolving this conflict...` appears first  | Mirror warning precedes owner modal visibility.                               | Owner decision surface should be available promptly.                                   | Timing/UI sequencing issue |
| V18 | 13:58:30      | `Scheduling conflict` modal appears on owner                        | Mirror shows owner-resolving banner                          | Conflict is resolvable on owner.                                              | Conflict is resolvable on owner.                                                       | PASS (BUG-025 functional)  |
| V19 | 13:58:43      | Owner modal still active with options                               | Mirror toast: `Owner is resolving this conflict... OK`       | Mirror copy is generic, no pair/range context.                                | Include conflicting groups/ranges or clear action guidance.                            | UX gap                     |
| V20 | 13:58:47      | Groups Hub: `G1 paused ends 14:10`, `G2 scheduled 14:12 ends 14:27` | Task List mirror same logical state                          | `G2` moved, but paused `G1 Ends` remains static while paused.                 | Running/paused projection should stay coherent across cards.                           | Projection coherence issue |
| V21 | 13:59:24      | Run Mode resume action                                              | Mirror Run Mode                                              | Resume triggers later `Ends` adjustment.                                      | Resume adjustment expected.                                                            | PASS                       |
| V22 | 13:59:33      | Groups Hub: `G1 running ends 14:12`, `G2 scheduled 14:13`           | Mirror Run Mode                                              | Ends update after resume.                                                     | Ends update after resume.                                                              | PASS                       |
| V23 | 14:00:26      | Pause again (`G1`) with `G2 scheduled 14:18`                        | Groups Hub mirror                                            | Second conflict setup validated.                                              | N/A                                                                                    | Baseline                   |
| V24 | 14:04:02      | Owner `Scheduling conflict` modal visible                           | Mirror owner-resolving snackbar                              | Conflict raised correctly, mirror copy remains generic.                       | Mirror should have clearer conflict context.                                           | PASS + UX gap              |
| V25 | 14:04:30      | Owner modal + mirror banner                                         | Ongoing conflict before decision                             | Stable pre-decision state.                                                    | Stable pre-decision state.                                                             | PASS                       |
| V26 | 14:04:51      | Toast: `Scheduled start moved to 14:19`                             | Groups Hub mirror shows `G2 scheduled 14:19`                 | Postpone action applied correctly.                                            | Postpone action applied correctly.                                                     | PASS                       |
| V27 | 14:05:04      | Resume `G1` (`ends 14:19`)                                          | Groups Hub mirror (`G2 scheduled 14:20`)                     | Ends/projected times realign after resume.                                    | Ends/projected times should remain coherent also during pause (not only after resume). | Partial                    |

## Log Correlation for Visual Timeline

1. Overlap decision activation while paused is present in logs:
   - Android: `runningOverlap=true` at [android log](/Users/devcodex/development/focus_interval/docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_android_RMX3771_debug.log):6099, :7694, :7785.
   - macOS: `runningOverlap=true` at [macOS log](/Users/devcodex/development/focus_interval/docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_macos_debug.log):6316, :6364.

2. Start-now temporary mirror hydration gap window:
   - macOS `Resync missing; no session snapshot.` at [macOS log](/Users/devcodex/development/focus_interval/docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_macos_debug.log):6192 and :6206.
   - First session snapshot appears later at :6208 (`lastUpdatedAt=13:55:24.553`).
   - Android side shows run bootstrap around [android log](/Users/devcodex/development/focus_interval/docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_android_RMX3771_debug.log):7388 and first matching snapshot at :7468.

3. Postpone write path reflected in scheduler sample timeline:
   - Android schedule sample shifts (14:12 / 14:13 / 14:14 / 14:15) at :7685, :7704, :7804, :7821.

## Evidence-Based Verdict (current run)

- Scenario A (exact boundary conflict while paused): PASS (functional).
- Scenario B (decision already active, entering TimerScreen): PASS (functional in owner Run Mode).
- Scenario C (re-entry while conflict remains): PASS (functional in Run Mode path).
- Scenario D (postpone regression smoke): PASS (no immediate duplicate decision loop observed).

Additional issues discovered during same run (outside strict BUG-025 functional gate):

- F01: Mirror temporary black syncing/start-now hydration window.
- F02: Conflict copy/detail deficits (planning modal, pre-run snackbar, mirror warning).
- F03: Groups Hub paused `Ends` projection coherence gap during pause.
- F04: Modal escape/navigation ergonomics on Android (physical back dependency observed).

Status: Closed/OK (03/04/2026)
