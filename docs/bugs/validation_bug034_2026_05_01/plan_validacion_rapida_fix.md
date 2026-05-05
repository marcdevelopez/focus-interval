# BUG-034 Quick Validation Plan

Date: 2026-05-01  
Branch: `fix/bug034-shared-timeline-break-desync`  
Commit: `f910caf`  
Bugs covered: `BUG-034`  
Target devices: macOS owner path (primary), Android owner path (secondary)

## Objetivo

Validate and isolate a shared-mode timeline logic inconsistency where Run Mode predicts a long break in `Next status` but executes a short break, and where contextual task ranges diverge from status-box ranges after that transition.

## Síntoma original

In Run Mode for a running shared-structure group, `Next status` announces `Break: 15 min`, but when the transition happens the real phase is `Break: 5 min`. After the transition, contextual task-item ranges (for upcoming tasks) stop matching the timeline implied by status boxes and the executed break.

## Root cause

Initial technical hypothesis points to timeline logic divergence across runtime surfaces:

- Runtime phase execution path (authoritative): `PomodoroMachine` via `PomodoroViewModel` transition handlers.
- Status-box preview path: Timer screen projection for `Current status` / `Next status`.
- Contextual task-list range path: task-range projection helper used by Run Mode list items.

The bug indicates at least one path is applying break insertion with a different rule than the shared-mode global pomodoro counter (`longBreakInterval` across all tasks).

## Protocolo de validación

### Scenario A — Next status predicts long break but runtime executes short break

Preconditions:
1. Group running in `integrityMode = shared`.
2. Global sequence near task boundary (`Proyecto Focus Interval (mañana)` final pomodoro).

Steps:
1. Observe `Next status` before boundary transition.
2. Capture screenshot when `Next status` shows `Break: 15 min`.
3. Wait for actual phase transition and capture screenshot.

Expected result with fix:
- Predicted break type/duration matches executed break type/duration.

Reference result without fix:
- `Next status` shows `Break: 15 min`, execution enters `Break: 5 min`.

### Scenario B — Contextual list ranges stay aligned with authoritative runtime timeline

Preconditions:
1. Same run as Scenario A.
2. Capture after transition into next task (`Curso Develop Flutter`).

Steps:
1. Compare status-box ranges (`Current` / `Next`) with contextual task-item ranges.
2. Verify that next-task start/end aligns with executed break duration.

Expected result with fix:
- Status boxes and contextual task list are derived from the same timeline and remain aligned.

Reference result without fix:
- Contextual list appears computed from a 15-minute break while runtime/status path uses 5-minute break.

### Scenario C — Cross-mode guard (shared vs other integrity modes)

Preconditions:
1. Reproduce Scenario A/B in `shared`.
2. Run equivalent boundary case in another mode (`individual`) when available.

Steps:
1. Execute same transition checks for break prediction vs execution.
2. Compare range coherence behavior by mode.

Expected result with fix:
- Shared mode is coherent and no regressions introduced in other modes.

Reference result without fix:
- Shared mode desync persists; cross-mode behavior unknown.

## Comandos de ejecución

```bash
flutter run -d macos --dart-define=APP_ENV=prod 2>&1 | tee docs/bugs/validation_bug034_2026_05_01/logs/2026-05-01_bug034_f910caf_macos_debug.log
```

```bash
flutter run -d android --dart-define=APP_ENV=prod 2>&1 | tee docs/bugs/validation_bug034_2026_05_01/logs/2026-05-01_bug034_f910caf_android_RMX3771_debug.log
```

## Log analysis — quick scan (secondary only)

This bug is primarily a visual/runtime-coherence issue. Screenshots/video are authoritative.

Potential supporting signals:

```bash
rg -n "da943ceb-31f9-42b5-b994-235bee6586d0|Pomodoro 8 of 8|Break: 15 min|Break: 5 min|End of task" docs/bugs/validation_bug034_2026_05_01/logs/*bug034_f910caf*_debug.log
```

```bash
rg -n "integrityMode|shared|currentPomodoro|phase" docs/bugs/validation_bug034_2026_05_01/logs/*bug034_f910caf*_debug.log
```

## Verificación local

- `flutter analyze` -> PASS (2026-05-04, no issues found).
- Targeted timeline tests -> PASS (2026-05-04):
  - `flutter test test/presentation/timer_screen_break_prediction_test.dart`
  - `flutter test test/data/models/task_run_group_mode_a_breaks_test.dart`

## Criterios de cierre

1. Scenario A PASS: predicted break and executed break are identical in type/duration.
2. Scenario B PASS: contextual task-item ranges and status-box ranges remain aligned to executed timeline.
3. Scenario C PASS: no regression in non-shared integrity modes.
4. Validation checklist updated with logs/screenshots references.

## Status

In validation.
