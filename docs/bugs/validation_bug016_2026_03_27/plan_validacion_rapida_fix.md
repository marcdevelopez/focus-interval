# Quick Validation Plan — BUG-016

**Date:** 2026-03-27  
**Branch:** `fix/bug016-weight-edit-preview-modes`  
**Commit base:** `fa907c9`  
**Bugs covered:** BUG-016  
**Target devices:** macOS

---

## 1. Objective

Document and validate the current failure mode of Task weight editing in Edit Task before implementation, with reproducible evidence showing why requested percentages are not preserved and why selected-group pomodoro totals can shrink unexpectedly.

---

## 2. Original symptom (user perspective)

When editing `Task weight (%)` and then moving focus to `Total pomodoros`, the entered value is overwritten by a lower percentage (for example `69% -> 43%`, `50% -> 36%`, `45% -> 35%`). The same inconsistency repeats after retyping. After Save, Task List can show a different percentage than the editor preview path suggested, and the selected-group total pomodoros can drop significantly, making the requested target harder to reach.

---

## 3. Root cause (technical, file/method level)

The observed behavior is consistent with two coupled defects in `task_editor_screen.dart`:

1. **Reactive baseline corruption per keystroke**  
   - `Task weight (%)` `onChanged` recalculates redistribution on every character and writes the edited task immediately:
     - `onChanged`: `lib/presentation/screens/task_editor_screen.dart:2077`
     - immediate provider update: `lib/presentation/screens/task_editor_screen.dart:2106`
   - Baseline list is rebuilt from current provider state in `build()`:
     - `_selectedTasksForWeight`: `lib/presentation/screens/task_editor_screen.dart:1220`
   - This means intermediate values (for example `8` while typing `80`) alter the next baseline.

2. **Blur-time percent resync from partial state (before full redistribution apply)**  
   - On weight field blur, listener forces a sync from current task state:
     - focus listener: `lib/presentation/screens/task_editor_screen.dart:97`
     - `_syncWeightPercentFromTask`: `lib/presentation/screens/task_editor_screen.dart:1366`
     - `_currentWeightPercent`: `lib/presentation/screens/task_editor_screen.dart:1243`
   - At this point, redistribution for other selected tasks may still be pending in `_pendingRedistribution` and is only applied on Save:
     - `_handleSave` pending redistribution apply: `lib/presentation/screens/task_editor_screen.dart:295`
   - Result: field value can jump (`69 -> 43`) because it is recomputed from a mixed state.

3. **Selected-group total pomodoros shrink after Save**  
   - Pending redistribution map (computed from contaminated baseline) is applied to other selected tasks only on Save:
     - `applyRedistributedPomodoros` call path: `lib/presentation/screens/task_editor_screen.dart:309`
   - This can produce large total changes in selected pomodoros (captured in this validation: `11 -> 6`).

---

## 4. Validation protocol

### Scenario A — G3 weight entry overwritten on blur

**Preconditions**
- Selected group shown with initial values:  
  `G1=5 (43%)`, `G2=4 (34%)`, `G3=1 (9%)`, `G4=1 (14%)` (selected total: `11` pomodoros).

**Steps**
1. Open Edit Task for `G3`.
2. Enter `80` in `Task weight (%)`.
3. Move focus to `Total pomodoros`.
4. Observe snackbar and resulting field value.
5. Enter `69` (suggested by snackbar), then move focus again.

**Expected with fix**
- Entered value remains stable until explicit Apply/Save (or preview confirms exact/closest target).
- No unexpected overwrite on blur.

**Observed without fix**
- Field jumps to `43%` after blur.
- Snackbar says `Closest possible is 69% (requested 80%)`, but re-entering `69` still returns to `43%`.

---

### Scenario B — Same overwrite behavior on G1 with 50%

**Preconditions**
- Continue from Scenario A state.

**Steps**
1. Open Edit Task for `G1`.
2. Enter `50` in `Task weight (%)`.
3. Move focus to `Total pomodoros`.
4. Repeat once.

**Expected with fix**
- Stable entered value until explicit confirmation flow.

**Observed without fix**
- `50%` is overwritten to `36%` on blur repeatedly.
- Save result in Task List shows `51%`, inconsistent with blur-time display path.

---

### Scenario C — Group total shrink after target attempts

**Preconditions**
- Continue from previous scenarios.

**Steps**
1. Reopen `G1`, set `Task weight (%) = 80`.
2. Blur to `Total pomodoros` (field falls to `35%`).
3. Set suggested `45%`, blur again (`35%` again).
4. Save and return to Task List.
5. Compare selected-group total pomodoros before vs after.

**Expected with fix**
- No hidden destructive redistribution from intermediate typing state.
- Deterministic result aligned with chosen target/closest result.

**Observed without fix**
- Final Task List shows `G1=45%`, `G2=15%`, `G3=15%`, `G4=25%`.
- Selected-group pomodoros changed from `11` (`5+4+1+1`) to `6` (`3+1+1+1`).

---

## 5. Execution commands

```bash
mkdir -p docs/bugs/validation_bug016_2026_03_27/logs && flutter run -v --debug -d macos --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true 2>&1 | tee docs/bugs/validation_bug016_2026_03_27/logs/2026-03-27_bug016_fa907c9_macos_debug.log
```

---

## 6. Log analysis — quick scan

### Bug-present signals (current packet)
```bash
# Runtime started in expected environment (sanity)
grep -n "AppConfig: env=prod" docs/bugs/validation_bug016_2026_03_27/logs/2026-03-27_bug016_fa907c9_macos_debug.log

# Weight-edit diagnostics are currently not instrumented in runtime logs
grep -n "Closest possible is\\|Task weight\\|requested" docs/bugs/validation_bug016_2026_03_27/logs/2026-03-27_bug016_fa907c9_macos_debug.log
```

### Fix-working signals (required after implementation)
```bash
# Add and verify dedicated diagnostics in future patch (example tags)
grep -n "\\[TaskWeightDiag\\]" docs/bugs/validation_bug016_2026_03_27/logs/<new-fix-log>.log
grep -n "\\[TaskWeightBaseline\\]" docs/bugs/validation_bug016_2026_03_27/logs/<new-fix-log>.log
grep -n "\\[TaskWeightApply\\]" docs/bugs/validation_bug016_2026_03_27/logs/<new-fix-log>.log
```

---

## 7. Local verification

- [x] `flutter analyze` — PASS (28/03/2026).
- [x] targeted tests — PASS (28/03/2026):
  - `flutter test test/domain/task_weighting_test.dart`
  - `flutter test test/presentation/viewmodels/task_editor_view_model_test.dart`

---

## 8. Closure criteria

1. Scenario A PASS: `80 -> blur` no longer overwrites to unrelated percent.
2. Scenario B PASS: `50 -> blur` remains coherent.
3. Scenario C PASS: no unexpected selected-group total collapse from intermediate typing.
4. Local gate PASS (`flutter analyze` + targeted tests).
5. Evidence updated in checklist + logs + screenshots.

---

## 9. Evidence references

- Log:
  - `docs/bugs/validation_bug016_2026_03_27/logs/2026-03-27_bug016_fa907c9_macos_debug.log`
- Screenshots:
  - `docs/bugs/validation_bug016_2026_03_27/screenshots/2026-03-27_bug016_01_macos.png`
  - `docs/bugs/validation_bug016_2026_03_27/screenshots/2026-03-27_bug016_02_macos.png`
  - `docs/bugs/validation_bug016_2026_03_27/screenshots/2026-03-27_bug016_03_macos.png`
  - `docs/bugs/validation_bug016_2026_03_27/screenshots/2026-03-27_bug016_04_macos.png`
  - `docs/bugs/validation_bug016_2026_03_27/screenshots/2026-03-27_bug016_05_macos.png`
  - `docs/bugs/validation_bug016_2026_03_27/screenshots/2026-03-27_bug016_06_macos.png`
  - `docs/bugs/validation_bug016_2026_03_27/screenshots/2026-03-27_bug016_07_macos.png`
  - `docs/bugs/validation_bug016_2026_03_27/screenshots/2026-03-27_bug016_08_macos.png`
  - `docs/bugs/validation_bug016_2026_03_27/screenshots/2026-03-27_bug016_09_macos.png`
  - `docs/bugs/validation_bug016_2026_03_27/screenshots/2026-03-27_bug016_10_macos.png`
  - `docs/bugs/validation_bug016_2026_03_27/screenshots/2026-03-27_bug016_11_macos.png`
  - `docs/bugs/validation_bug016_2026_03_27/screenshots/2026-03-27_bug016_12_macos.png`
  - `docs/bugs/validation_bug016_2026_03_27/screenshots/2026-03-27_bug016_13_macos.png`
- User-driven post-fix validation packet (28/03/2026):
  - Exact repro rerun from the same baseline distribution using the Patch 1 runtime (`commit 8bad479`):
    - `80% -> 69%` closest result remains stable through blur/save/list/reopen.
    - `50%` case remains coherent through blur/save/list/reopen (no `36%` regression).
    - `1%` case reports `No change possible` and keeps deterministic values.
  - Manual visual evidence captured in the 28/03/2026 owner validation thread.

---

## 10. Status

Closed/OK (Patch 1 validated on 2026-03-28; Patch 2 preview UX remains a roadmap follow-up).
