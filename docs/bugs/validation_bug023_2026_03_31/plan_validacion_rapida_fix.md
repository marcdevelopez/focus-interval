# BUG-023 Quick Validation Plan

Date: 31/03/2026
Branch: fix/bug023-save-as-preset-autolink
Commit: pending-local
Bugs covered: BUG-023
Target devices: local widget validation + macOS manual PASS + Android manual quick PASS

## Objetivo

Validate that Task Editor `Save as new preset` now auto-links the resulting preset when returning from Preset Editor, including deterministic id mapping across duplicate-resolution branches, without introducing analyzer/test regressions.

## Sintoma original

From Edit Task in Custom mode, users could save/create a preset via `Save as new preset`, return to Task Editor, and still see `Select preset` (unlinked). This made the flow feel broken because the just-saved (or explicitly selected duplicate) preset was not attached to the edited task.

## Root cause

- `lib/presentation/screens/task_editor_screen.dart`: save-as-preset flow pushed `/settings/presets/new` without awaiting/using a return payload.
- `lib/presentation/screens/preset_editor_screen.dart`: save/exit paths popped without returning a preset id to caller.
- Duplicate-resolution branches returned only local enum state (`savedAndExit/blocked`) and did not expose a deterministic link target id.

## Protocolo de validacion

### Scenario A - New preset save auto-links in Task Editor (exact repro)

Preconditions:

1. Existing task in Custom/unlinked state (`presetId=null`).
2. Preset repository available with at least one preset.

Steps:

1. Open Edit Task.
2. Tap `Save as new preset`.
3. In Preset Editor, enter preset name and tap `Save`.
4. Return to Edit Task.

Expected result with fix:

- Preset link indicator is linked.
- `Save as new preset` button disappears (task is no longer Custom/unlinked).
- Task stores non-null `presetId` for the returned/saved preset.

Reference result without fix:

- Task returns unlinked (`Select preset`) after save.

### Scenario B - Duplicate-resolution mapping contract

Preconditions:

1. Duplicate configuration exists.

Steps:

1. Trigger duplicate dialog from Preset Editor save.
2. Select each resolution branch.

Expected result with fix:

- `Save anyway` -> returns/syncs newly saved preset id.
- `Use existing` -> returns/syncs duplicate existing id.
- `Rename existing` -> returns/syncs renamed existing duplicate id (no new preset).
- `Cancel`/blocked -> returns null (Task remains unlinked).

Reference result without fix:

- No deterministic id propagation to Task Editor; linkage remains stale or missing.

## Comandos de ejecucion

```bash
cd /Users/devcodex/development/focus_interval && flutter analyze 2>&1 | tee docs/bugs/validation_bug023_2026_03_31/logs/2026-03-31_bug023_pending-local_analyze.log
```

```bash
cd /Users/devcodex/development/focus_interval && flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Edit Task" 2>&1 | tee docs/bugs/validation_bug023_2026_03_31/logs/2026-03-31_bug023_pending-local_widget_debug.log
```

## Log analysis - quick scan

### Bug present signals

```bash
grep -nE "Some tests failed|Expected: exactly one matching node|Exception caught by widgets library|Failed assertion" docs/bugs/validation_bug023_2026_03_31/logs/2026-03-31_bug023_pending-local_widget_debug.log
```

### Fix working signals

```bash
grep -nE "Edit Task Save as new preset auto-links returned preset|All tests passed" docs/bugs/validation_bug023_2026_03_31/logs/2026-03-31_bug023_pending-local_widget_debug.log
```

```bash
grep -n "No issues found!" docs/bugs/validation_bug023_2026_03_31/logs/2026-03-31_bug023_pending-local_analyze.log
```

## Verificacion local

- [x] `flutter analyze` PASS (`No issues found!`).
- [x] `flutter test ... --plain-name "Edit Task"` PASS (includes BUG-017 + BUG-023 Task Editor preset flows).

## Verificacion en dispositivo (live)

- [x] macOS manual PASS (31/03/2026):
  - Scenario A (`Save anyway`) returned to Edit Task with linked indicator active,
    selected preset visible, and `Save as new preset` hidden.
  - Scenario B (`Use existing`) returned to Edit Task linked to existing duplicate
    preset (`preset 20 min (2)`), with unlinked state not shown.
  - Evidence captured via user screenshots during live run in thread.
- [x] Android manual quick validation PASS (31/03/2026):
  - Scenario A (new preset save return) restored linked Edit Task state (`preset 21 min`).
  - Scenario B (`Use existing`) restored linked Edit Task state (`preset 20 min (2)`).
  - Runtime log captured at
    `docs/bugs/validation_bug023_2026_03_31/logs/2026-03-31_bug023_pending-local_android_debug.log`.
  - Evidence captured via user screenshots during live run in thread.

## Criterios de cierre

1. Exact repro scenario (A) PASS with evidence in widget test output.
2. Regression smoke PASS (`Edit Task` focused suite green, no analyzer issues).
3. Device validation packet updated (macOS + Android manual PASS captured) before final closure in bug log + ledger.

Status: Closed/OK
