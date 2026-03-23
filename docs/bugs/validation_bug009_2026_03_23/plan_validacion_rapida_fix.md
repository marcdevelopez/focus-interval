# Validation Plan — BUG-009B / BUG-013 / BUG-014

## 1. Header
- Date: 2026-03-23
- Branch: `fix-bug009b-cascade-completion-overlap`
- Base commit: `76ee374`
- Bugs covered: `BUGLOG-009B`, `BUGLOG-013`, `BUGLOG-014`
- Target devices: iOS Simulator `iPhone 17 Pro`, web `chrome`

## 2. Objective
Validate and document the reproduced overlap-resolution regressions found on 2026-03-23, then deliver a coordinated fix packet for queue cascade coverage, queue post-confirm revalidation, completion-modal auto-dismiss on next-group auto-open, and deterministic postpone conflict-dismiss behavior.

## 3. Original user-facing symptom
- Queue flow resolves only part of an overlap chain (first two groups), leaving a later group unresolved.
- Completion modal from a finished group remains visible while the next group starts (pre-run/running), blocking Run Mode.
- Running-overlap modal action `Postpone scheduled` can require two presses (first press shows success SnackBar but modal remains/reappears).

## 4. Root cause (confirmed)
- `BUGLOG-009B` layer 1: late-start conflict-set detection is not fully cascading when initial overdue seed is small (single-overdue path).
- `BUGLOG-009B` layer 2: queue confirm path is missing strict revalidation against scheduled groups outside current selection (spec 10.4.1.b).
- `BUG-013`: completion dialog lifecycle handled group switch/running transitions but not the pre-run announcement of a different next group (`scheduledAutoStartGroupIdProvider` was ignored when `next != widget.groupId`).
- `BUG-014`: race between postpone write propagation and running-overlap re-evaluation can re-open/retain the same modal.

### Implementation status (23/03/2026)
- `BUGLOG-009B` layer 1 implemented in `resolveLateStartConflictSet` with iterative cascading conflict expansion.
- `BUGLOG-009B` layer 2 implemented in queue apply flow with post-confirm revalidation and queue reopen when extra overlaps are detected.
- `BUG-013` updated in `TimerScreen` listener so completion modal is dismissed when a different group enters pre-run auto-open (`scheduledAutoStartGroupIdProvider` emits next group id).
- `BUG-014` implemented with deterministic postpone guard (`decision key + expected scheduled start`) synchronized from repository snapshots.

### Validation update (fix_v2 packet, 23/03/2026)
- `BUGLOG-009B`: PASS in device logs. iOS shows one late-start queue opening (`overdue=3`) and no second runtime queue (`overdue=2` absent). G2 pre-run and start timers then fire normally.
- `BUG-013`: PARTIAL in device logs. iOS pre-run starts at `14:03`, but modal auto-dismiss happened at `14:04` (`group switch`), not at pre-run boundary.
- `BUG-014`: no repeat modal observed in local deterministic guard test; device rerun remains pending for explicit one-tap confirmation in this patch set.

### Validation update (fix_v3 user rerun, 23/03/2026 15:07)
- User rerun still reported `BUG-013` behavior (completion modal stayed visible at pre-run and only dismissed at next-group start).
- User rerun also reported queue-timing coherence issue: G3 pre-run minute still matched G2 end minute in Groups Hub after overlap confirmation.
- Follow-up implementation applied in current branch:
  - allow `openTimer` actions while completion modal is visible (so pre-run auto-open is not deferred),
  - enforce anchored scheduled starts so pre-run begins strictly after anchor end when `noticeMinutes > 0`.
- Device rerun required with new logs (`fix_v4`) before closure.

### Validation update (fix_v4 rerun, 23/03/2026 16:40–17:24)
- `BUGLOG-009B`: PASS (iOS + web).
  - One queue flow opens with full chain: `LateStartQueue overdue=3` + `Opening late-start overlap queue`.
  - No second runtime queue (`LateStartQueue overdue=2` absent in both logs).
- `BUG-013`: PASS (iOS + web mirror behavior coherent).
  - iOS shows next-group pre-run at `17:00:00` (`prealert-timer-fired` for G2).
  - Completion modal auto-dismiss occurs at `17:00:00` (`Auto-dismiss completion dialog: group switch`), before G2 start timer at `17:01:00`.
- `BUG-014`: PASS.
  - User rerun confirms one-tap postpone behavior and no repeated conflict modal.
  - No `Scheduling conflict` signatures in fix_v4 logs after overlap confirmation.
- Timing coherence check: PASS.
  - `postpone-finalized` sample for G3 is `17:18:00` while G2 end is `17:16`, so pre-run/start no longer shares previous-end minute in the problematic chain.

## 5. Validation protocol
### Scenario A — Queue cascade coverage (`BUGLOG-009B`)
Preconditions:
1. Account Mode.
2. Three planned groups with 1m pre-run, consecutive windows.

Steps:
1. Open app late so overlap queue appears.
2. Confirm queue selection.
3. Observe resulting scheduling and later runtime behavior.

Expected with fix:
1. Queue includes all implied conflicting groups in one flow.
2. No later runtime overlap modal from the same unresolved chain.

Reference without fix:
1. Third group remains outside queue.
2. Runtime `Scheduling conflict` reappears later.

### Scenario B — Completion modal auto-dismiss (`BUG-013`)
Preconditions:
1. Consecutive planned groups.
2. Run Mode open.

Steps:
1. Let group N complete and keep completion modal visible.
2. Wait for group N+1 pre-run/start.

Expected with fix:
1. Completion modal auto-dismisses at pre-run announcement of group N+1 (or earlier), not waiting for running state.
2. User can see pre-run/running UI without manual `OK`.

Reference without fix:
1. Completion modal remains and blocks Run Mode until manual dismiss.

### Scenario C — Postpone one-tap dismissal (`BUG-014`)
Preconditions:
1. Running-overlap modal visible.

Steps:
1. Press `Postpone scheduled` once.
2. Observe modal + SnackBar behavior.

Expected with fix:
1. One press updates schedule and closes modal deterministically.
2. Modal does not re-open for same decision after write confirmation.

Reference without fix:
1. SnackBar appears but modal remains/reopens.
2. Second press needed.

## 6. Run commands
```bash
flutter run -d "iPhone 17 Pro" --debug 2>&1 | tee docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_fix_v4_76ee374_ios_simulator_iphone_17_pro_debug.log
```

```bash
flutter run -d chrome --web-port 56541 --debug 2>&1 | tee docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_fix_v4_76ee374_web_chrome_debug.log
```

## 7. Log analysis — quick scan
### Bug-present signatures
```bash
grep -nE "LateStartQueue.*overdue=2|Scheduling conflict" \
  docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_fix_v4_76ee374_ios_simulator_iphone_17_pro_debug.log \
  docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_fix_v4_76ee374_web_chrome_debug.log
```

```bash
grep -nE "prealert-timer-fired group=d8658ab0|Auto-dismiss completion dialog: group switch|start-timer-fired group=d8658ab0" \
  docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_fix_v4_76ee374_ios_simulator_iphone_17_pro_debug.log
```

### Fix-working signatures (target)
```bash
grep -nE "LateStartQueue.*overdue=3|Opening late-start overlap queue" \
  docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_fix_v4_76ee374_ios_simulator_iphone_17_pro_debug.log \
  docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_fix_v4_76ee374_web_chrome_debug.log
```

```bash
grep -nE "prealert-timer-fired group=d8658ab0|Auto-dismiss completion dialog: group switch|start-timer-fired group=d8658ab0" \
  docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_fix_v4_76ee374_ios_simulator_iphone_17_pro_debug.log
```

```bash
grep -nE "postpone-finalized|17:18:00.000|Scheduling conflict" \
  docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_fix_v4_76ee374_ios_simulator_iphone_17_pro_debug.log \
  docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_fix_v4_76ee374_web_chrome_debug.log
```

## 8. Local verification
- `flutter analyze`: PASS (`No issues found!`, 23/03/2026, current branch)
- `flutter test test/presentation/utils/scheduled_group_timing_test.dart`: PASS (`+7`, includes anchored-group exclusion case)
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart`: PASS (`+21`, includes pre-run auto-dismiss regression test)
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart`: PASS (`+19`)

## 9. Closure criteria
1. Scenario A PASS on iOS + web (single queue flow resolves full chain).
2. Scenario B PASS on iOS + web (completion modal auto-dismiss on next-group auto-open).
3. Scenario C PASS on web (single postpone tap closes conflict modal).
4. Local gate PASS: `flutter analyze` + targeted test suite.

## 10. Status
Closed/OK (23/03/2026).
- `BUGLOG-009B`: PASS in `fix_v4` logs (single queue chain, no runtime re-queue).
- `BUG-013`: PASS in `fix_v4` logs (dismiss at pre-run boundary, before start timer).
- `BUG-014`: PASS in `fix_v4` rerun (one-tap postpone behavior confirmed, no repeated conflict).
- Implementation commit: `2fdd99b` (`fix(late-start, timer): BUGLOG-009B re-queue + BUG-013 modal + BUG-014 postpone`).
