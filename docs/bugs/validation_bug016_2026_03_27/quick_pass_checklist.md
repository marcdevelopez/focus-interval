## Exact repro
- [x] Scenario A PASS: G3 `80%` / `69%` no longer collapses to `43%` on blur.
- [x] Scenario B PASS: G1 `50%` no longer collapses to `36%` on blur.
- [x] Scenario C PASS: G1 `80%` / `45%` no longer collapses to `35%` on blur.
- [x] Save result is deterministic: editor state and Task List state match.
- [x] Selected-group total pomodoros does not shrink unexpectedly from intermediate typing state.

## Regression smoke
- [x] Task weight snackbar appears only for true precision limits, not for inconsistent intermediate state.
- [x] Total pomodoros edits remain coherent with Task weight (%) display.
- [x] Unselected tasks remain unaffected by weight edits.

## Local gate
- [x] flutter analyze PASS.
- [x] flutter test test/domain/task_weighting_test.dart PASS.
- [x] flutter test test/presentation/viewmodels/task_editor_view_model_test.dart PASS.

## Closure rule
- [x] Close only when all boxes above are checked with evidence in logs and screenshots.
