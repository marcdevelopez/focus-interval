# BUG-017 Quick Validation Plan

Header:

- Date: 31/03/2026
- Branch: fix/bug017-preset-dropdown-custom
- Commit hash: pending-local
- Bugs covered: BUG-017 / BUGLOG-017
- Target devices: macOS desktop + Android (RMX3771)

## 1. Objective

Validate that Edit Task preset selector never injects a synthetic `Custom` option, while preserving normal selection for real persisted presets (including a real preset named `Custom`) and preserving deterministic linked/unlinked preset state communication.

## 2. Original symptom

Users opening Edit Task saw `Custom` as a selectable dropdown option mixed with real presets. This was misleading because `Custom` was not a real saved preset. In projects with a real preset named `Custom`, UI meaning became ambiguous.

## 3. Root cause

`TaskEditorScreen._presetSelectorRow` was adding a synthetic sentinel dropdown item (`__custom__`) mapped to label `Custom` and defaulting unlinked state to that sentinel value. This rendered a pseudo-option as if it were a persisted preset.

## 4. Validation protocol

Scenario A - synthetic dropdown option removed

- Preconditions:
  - Task exists with no linked preset.
  - Preset list contains `Classic Pomodoro` and at least one user preset.
- Steps:
  1. Open Edit Task for the task.
  2. Open Preset dropdown.
  3. Count visible `Custom` entries.
- Expected result with fix:
  - No synthetic option appears.
  - Dropdown displays only persisted presets.
- Reference result without fix:
  - `Custom` appears as an extra synthetic option.

Scenario B - real preset named `Custom` remains valid

- Preconditions:
  - A real preset exists with name `Custom`.
- Steps:
  1. Open Preset dropdown.
  2. Select the real preset named `Custom`.
- Expected result with fix:
  - Exactly one `Custom` option exists and is selectable.
  - Task links to that real preset.
- Reference result without fix:
  - Ambiguous `Custom` display (real + synthetic) may appear.

Scenario C - linked/unlinked transitions remain deterministic

- Preconditions:
  - Task linked to a persisted preset.
- Steps:
  1. Confirm linked indicator is visible.
  2. Modify pomodoro duration manually.
  3. Observe preset state.
- Expected result with fix:
  - Task auto-detaches from preset (`presetId = null`).
  - Unlinked indicator appears and `Save as new preset` becomes visible.
- Reference result without fix:
  - Unlinked communication depends on synthetic dropdown item instead of dedicated indicator/hint.

## 5. Execution commands

```bash
flutter analyze 2>&1 | tee docs/bugs/validation_bug017_2026_03_31/logs/2026-03-31_bug017_pending-local_analyze.log
flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Edit Task preset selector" 2>&1 | tee docs/bugs/validation_bug017_2026_03_31/logs/2026-03-31_bug017_pending-local_widget_debug.log
```

Manual device run templates:

```bash
flutter run -d macos 2>&1 | tee docs/bugs/validation_bug017_2026_03_31/logs/2026-03-31_bug017_pending-local_macos_debug.log
flutter run -d android 2>&1 | tee docs/bugs/validation_bug017_2026_03_31/logs/2026-03-31_bug017_pending-local_android_debug.log
```

## 6. Log analysis - quick scan

Bug present signals:

```bash
grep -E "Expected: exactly one matching node|Too many elements|Test failed" docs/bugs/validation_bug017_2026_03_31/logs/2026-03-31_bug017_pending-local_widget_debug.log
```

Fix working signals:

```bash
grep -E "All tests passed|\+1: All tests passed" docs/bugs/validation_bug017_2026_03_31/logs/2026-03-31_bug017_pending-local_widget_debug.log
grep -E "No issues found" docs/bugs/validation_bug017_2026_03_31/logs/2026-03-31_bug017_pending-local_analyze.log
```

## 7. Local verification

- [x] `flutter analyze` PASS.
- [x] `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Edit Task preset selector"` PASS.

## 8. Closure criteria

- Scenario A PASS with evidence.
- Scenario B PASS with evidence.
- Scenario C PASS with evidence.
- Local gate PASS (`flutter analyze` + targeted regression test).
- Validation ledger and bug log synchronized with resulting status.

## 9. Status

Closed/OK (31/03/2026, pending-local).
