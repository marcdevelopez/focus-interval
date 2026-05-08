# Deterministic model validation plan

## 1. Header

- Date: 07/05/2026 (updated 08/05/2026)
- Branch: `feature/deterministic-conflict-model-hub`
- Working commit hash: `03047b5` (post-fix predictive-drift snackbar trigger)
- Bugs covered: deterministic conflict-model migration closure packet (post PR #185)
- Target devices: Android owner (`RMX3771`) + iOS mirror (`ios simulator`) + macOS mirror (`macos`) + Chrome mirror (`localhost:5001`)

## 2. Objetivo

Validate end-to-end deterministic scheduling behavior after legacy conflict-model retirement: no destructive conflict modals in Groups Hub, deterministic at-risk/Lost handling in runtime, and planning conflict blocker showing effective windows (including postponed + paused anchor projection).

## 3. Síntoma original

Under the previous conflict model, users could hit inconsistent or destructive flows: conflict modals in Groups Hub asked to cancel/delete other groups, and Plan Group inline conflict chips could show stale/raw ranges (especially with postponed chains after a paused running anchor), forcing users to guess which group was truly blocking scheduling.

## 4. Root cause

- `groups_hub_screen.dart` still contained legacy conflict resolver methods (`_resolveRunningConflict`, `_resolveScheduledConflict`) that mutated/deleted blockers through modal actions.
- `task_group_planning_screen.dart` inline conflict chips used raw `scheduledStartTime/theoreticalEndTime` instead of effective windows, so postponed/paused-aware timing from scheduling helpers was not reflected in user-facing blocker context.

## 5. Protocolo de validación

### Scenario A — Scheduled group auto-starts in deterministic execution window

Preconditions:
1. Account Mode enabled.
2. One scheduled group configured to start in a near-future window.

Steps:
1. Keep owner device on Groups Hub/Run Mode until scheduled start enters execution window.
2. Let coordinator process scheduled action without manual conflict resolution.
3. Observe transition and route behavior.

Expected result with fix:
1. Group transitions to `running` automatically.
2. Timer route opens deterministically (`openTimer` action path).
3. No legacy conflict modal is shown.

Reference result without fix:
1. Legacy modal/queue-based conflict flow could block deterministic start path.

### Scenario B — Overdue scheduled group transitions to Lost

Preconditions:
1. Account Mode enabled.
2. A scheduled group is already outside execution window (overdue).

Steps:
1. Open app and let coordinator evaluate overdue scheduled groups.
2. Open Groups Hub history sections.

Expected result with fix:
1. Group is marked canceled with `canceledReason = 'lost'`.
2. Group appears under `Canceled` section with `Reason: Lost`.
3. No runtime conflict modal appears.

Reference result without fix:
1. Group could remain in stale scheduled/conflict state or route through legacy conflict-resolution flow.

### Scenario C — Running group shows at-risk snackbar (no modal)

Preconditions:
1. One running group active.
2. One or more scheduled groups enter overlapping execution windows.

Steps:
1. Keep owner in TimerScreen for running group.
2. Wait for at-risk set update from coordinator.
3. Trigger same at-risk set twice, then clear and re-arm.

Expected result with fix:
1. Snackbar appears with deterministic copy (`scheduled ... at risk while this group is active`).
2. Dedup works for identical set; snackbar re-arms after clear.
3. No blocking conflict modal is shown.

Reference result without fix:
1. Modal-driven overlap resolution path and repetitive stale prompts could appear.

### Scenario D — Re-plan from canceled Lost item keeps deterministic planning behavior

Preconditions:
1. At least one canceled group with `Reason: Lost`.
2. Existing scheduled/running blockers present.

Steps:
1. From the canceled lost card, tap `Re-plan group`.
2. In Plan Group, choose a conflicting slot first, then adjust.
3. Confirm with a non-conflicting slot.

Expected result with fix:
1. Planning conflict stays inline (no AlertDialog).
2. Conflict chips identify blockers with effective windows.
3. New group is created only after conflict-free selection.

Reference result without fix:
1. User-facing blocker range could be stale/raw, causing mismatch with actual timeline.

### Scenario E — Planning conflict block uses effective windows and disables Confirm

Preconditions:
1. At least one non-terminal blocker exists (`running`, `paused`, or `scheduled`).
2. Plan Group opened for a new scheduled group.

Steps:
1. Select a slot that conflicts with postponed effective window.
2. Observe red inline `Scheduling conflict` block.
3. Compare displayed chip range vs raw stored range.

Expected result with fix:
1. `Confirm` is disabled while conflicts exist.
2. Chips show effective `groupName/start/end` (running/paused projection aware), not stale range.
3. No conflict modal appears.

Reference result without fix:
1. Inline chip could show raw stored range and mislead blocker identification.

### Scenario F — Future start selection remains stable in Plan Group (12:00 regression)

Preconditions:
1. One running group active (for example ending at `11:59`).
2. Plan Group opened in Chrome/iOS for a second group.

Steps:
1. In `Schedule by start time`, edit start to a future value (e.g., `12:00`).
2. Return to plan card and review selected start label + conflict chip context.
3. Confirm selected time is still the chosen future value.

Expected result with fix:
1. Selected start remains at the user-picked future time (e.g., `12:00`).
2. Planner does not rewrite start to current planning time (`now`) while start is still in the future.
3. Conflict block reflects the chosen schedule context, not an unintended fallback to current time.

Reference result without fix:
1. Selected future start could degrade to current local planning time (for example `11:46`), producing a false conflict context.

## 6. Comandos de ejecución

```bash
# Android owner runtime validation
flutter run -v --debug -d RMX3771 --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_deterministic_2026_05_07/logs/2026-05-08_deterministic_03047b5_android_RMX3771_debug.log

# iOS mirror runtime validation
flutter run -v --debug -d "iPhone 17 Pro" --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_deterministic_2026_05_07/logs/2026-05-08_deterministic_03047b5_ios_debug.log

# macOS mirror runtime validation
flutter run -v --debug -d macos --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_deterministic_2026_05_07/logs/2026-05-08_deterministic_03047b5_macos_debug.log

# Chrome mirror runtime validation
flutter run -v --debug -d chrome --web-hostname=localhost --web-port=5001 --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_deterministic_2026_05_07/logs/2026-05-08_deterministic_03047b5_chrome_debug.log

# Local gate logs
flutter analyze \
  2>&1 | tee docs/bugs/validation_deterministic_2026_05_07/logs/2026-05-07_deterministic_f6ea1d2_local_analyze_debug.log

flutter test test/presentation/task_group_planning_screen_conflict_test.dart \
  2>&1 | tee docs/bugs/validation_deterministic_2026_05_07/logs/2026-05-07_deterministic_f6ea1d2_local_planning_conflict_debug.log

flutter test test/presentation/timer_screen_completion_navigation_test.dart \
  2>&1 | tee docs/bugs/validation_deterministic_2026_05_07/logs/2026-05-07_deterministic_f6ea1d2_local_timer_navigation_debug.log

flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart \
  2>&1 | tee docs/bugs/validation_deterministic_2026_05_07/logs/2026-05-07_deterministic_f6ea1d2_local_coordinator_debug.log
```

## 7. Log analysis — quick scan

### Bug present signals

```bash
# Legacy conflict-modal / queue traces should be absent
grep -nE "Conflict with running group|Conflict with scheduled group|Cancel running group|Delete scheduled group|late-start-queue|lateStartQueue" \
  docs/bugs/validation_deterministic_2026_05_07/logs/*_deterministic_03047b5_*.log
```

If any match appears in runtime logs during scenarios A-E, treat as regression candidate.

### Fix working signals

```bash
# Deterministic runtime signals expected across scenarios
grep -nE "ScheduledActionDiag.*actionType=openTimer|Scheduling conflict|at risk while this group is active|Lost|route=/timer|route=/groups" \
  docs/bugs/validation_deterministic_2026_05_07/logs/*_deterministic_03047b5_*.log
```

Plus visual evidence required in screenshots for scenarios B/C/D/E.

## 8. Verificación local

- `flutter analyze` -> PASS (expected, recorded in local log).
- `flutter test test/presentation/task_group_planning_screen_conflict_test.dart` -> PASS (effective window regression covered).
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> PASS (Groups Hub deterministic guard behavior covered).
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` -> PASS (execution window / Lost / at-risk behaviors covered).

## 9. Criterios de cierre

Close this packet only when all are PASS with attached evidence:
1. Scenario A PASS (deterministic auto-start in execution window).
2. Scenario B PASS (overdue -> Lost with correct reason/section).
3. Scenario C PASS (at-risk snackbar dedup + re-arm; no modal).
4. Scenario D PASS (Re-plan from canceled Lost remains inline deterministic).
5. Scenario E PASS (inline conflict chips use effective windows; Confirm disabled).
6. Scenario F PASS (future start remains stable; no auto-rewrite-to-now regression).
7. Regression smoke PASS (ownership request/transfer flow unaffected, paused projection coherence maintained).
8. Local gate PASS logs + device logs/screenshots synchronized in this packet.

## 10. Status

Closed/OK (08/05/2026). All scenarios A-F and regression smoke are covered with device evidence (`03047b5`) on Android + iOS + Chrome. One transient ownership-smoke visual mismatch (`14:37 -> 14:38` in task-item range after transfer/resume while status box stayed `14:37`) was observed once and was not reproducible in repeated attempts.
