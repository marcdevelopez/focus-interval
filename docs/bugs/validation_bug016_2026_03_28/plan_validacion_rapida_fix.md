# Quick Validation Plan — BUG-016 Patch 2

**Date:** 2026-03-28  
**Branch:** `fix/bug016-weight-edit-preview-modes`  
**Commit base:** `7736f7b`  
**Bugs covered:** BUG-016 (Patch 2 preview UX follow-up)  
**Target devices:** macOS

---

## 1. Objective

Validate the final preview-first UX implementation for Task weight (%) and Total pomodoros in Task Editor, including Fixed/Flexible mode behavior, apply/cancel semantics, consistency between preview/editor/list, and post-polish UI correctness.

---

## 2. Original symptom (user perspective)

Before Patch 2, editing task weight was effectively blind and unstable: users could not preview deterministic outcomes before apply/save, and blur-time behavior could diverge from list-level persisted values. Patch 2 introduces a full-screen preview sub-screen with explicit modes and draft-apply semantics to eliminate ambiguity and improve predictability.

---

## 3. Root cause (technical, file/method level)

Patch 1 fixed correctness (baseline freeze + blur/save sync). Patch 2 addressed the UX root issue: per-keystroke inline editing in the main editor was replaced with a dedicated preview flow and deterministic apply lifecycle.

Primary runtime scope:
- `lib/presentation/screens/task_editor_screen.dart`
- `lib/presentation/screens/task_weight_preview_sheet.dart`
- `lib/presentation/viewmodels/task_editor_view_model.dart`
- `lib/domain/continuous_plan_load.dart`
- `lib/widgets/task_card.dart`

Key technical outcomes validated:
- Tap-target fields open preview screen (no blind inline redistribution).
- Fixed/Flexible mode contracts run through ViewModel redistribution helpers.
- Preview -> Apply (draft) -> Save (persist) remains deterministic.
- Warning and status messages are interaction-gated and non-redundant.
- Continuous-time caution levels and reminder chips are consistent with computed totals.

---

## 4. Validation protocol

### Scenario A — Task weight (%) preview and mode behavior

**Preconditions**
- Multi-task selected group with mixed durations.

**Steps**
1. Open Edit Task.
2. Tap Task weight (%).
3. Test Fixed and Flexible with representative values (low/mid/high).
4. Apply in preview; Save in editor.
5. Reopen task and compare with Task List.

**Expected with fix**
- Preview values match post-Apply draft and post-Save persisted state.
- Fixed/Flexible semantics are stable and consistent.

**Reference without fix**
- Blind inline edits and unstable blur/save coherence.

---

### Scenario B — Total pomodoros preview and deterministic persistence

**Preconditions**
- Same selected scope.

**Steps**
1. Open Total pomodoros preview.
2. Test no-change, feasible, and constrained high values.
3. Apply + Save and compare list/reopen values.

**Expected with fix**
- Deterministic preview/apply/save equivalence.
- Closest-achievable message shown only when exact cannot be reached.

**Reference without fix**
- No explicit preview-first deterministic flow.

---

### Scenario C — Back/Cancel semantics and non-duplicated hint

**Preconditions**
- Modify value in preview but do not Apply.

**Steps**
1. Exit via Back.
2. Repeat with system back gesture.

**Expected with fix**
- `No changes applied.` hint appears once (not duplicated).
- If no interaction/unapplied change, exit stays silent.

**Reference without fix**
- Duplicate hint could appear due to dual emit path.

---

### Scenario D — Continuous-time caution + list/hub reminder consistency

**Preconditions**
- Generate long continuous plans (Unusual/Superhuman/Machine thresholds).

**Steps**
1. Trigger caution in preview.
2. Save and confirm reminder chips in Task List and Groups Hub.

**Expected with fix**
- Correct threshold level and consistent reminder rendering.

---

## 5. Execution commands

```bash
mkdir -p docs/bugs/validation_bug016_2026_03_28/logs && flutter run -v --debug -d macos --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true 2>&1 | tee docs/bugs/validation_bug016_2026_03_28/logs/2026-03-28_bug016p2_7736f7b_macos_debug.log
```

---

## 6. Log analysis — quick scan

### Bug-present signals
```bash
grep -n "Unhandled Exception\|No changes applied\|TaskWeight\|Closest achievable\|ERROR" docs/bugs/validation_bug016_2026_03_28/logs/2026-03-28_bug016p2_7736f7b_macos_debug.log
```

### Fix-working signals
```bash
# Environment sanity + no crash-level runtime issue markers
grep -n "AppConfig: env=prod" docs/bugs/validation_bug016_2026_03_28/logs/2026-03-28_bug016p2_7736f7b_macos_debug.log
grep -n "Unhandled Exception" docs/bugs/validation_bug016_2026_03_28/logs/2026-03-28_bug016p2_7736f7b_macos_debug.log
```

---

## 7. Local verification

- [x] `flutter analyze` — PASS (2026-03-29).
- [x] `flutter test test/domain/task_weighting_test.dart` — PASS.
- [x] `flutter test test/presentation/viewmodels/task_editor_view_model_test.dart` — PASS.
- [x] `flutter test test/domain/continuous_plan_load_test.dart` — PASS.

---

## 8. Closure criteria

1. Preview/apply/save behavior is deterministic for Task weight (%) and Total pomodoros.
2. Fixed/Flexible outcomes are consistent with current spec wording.
3. Back/Cancel semantics are coherent and non-duplicative.
4. Continuous-time caution/reminder levels render correctly in preview/list/hub.
5. Local gate passes (`analyze` + targeted tests).

---

## 9. Evidence references

- Device log:
  - `docs/bugs/validation_bug016_2026_03_28/logs/2026-03-28_bug016p2_7736f7b_macos_debug.log`
- User-run visual packet:
  - Validation screenshots reviewed in the 2026-03-28/29 closure thread and captured in
    `docs/bugs/validation_bug016_2026_03_28/screenshots/` (when exported to repo).

---

## 10. Status

Closed/OK (Patch 2 preview UX validated and finalized).
