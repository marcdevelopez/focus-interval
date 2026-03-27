## Exact repro
- [ ] Scenario A PASS: G3 `80%` / `69%` no longer collapses to `43%` on blur.
- [ ] Scenario B PASS: G1 `50%` no longer collapses to `36%` on blur.
- [ ] Scenario C PASS: G1 `80%` / `45%` no longer collapses to `35%` on blur.
- [ ] Save result is deterministic: editor state and Task List state match.
- [ ] Selected-group total pomodoros does not shrink unexpectedly from intermediate typing state.

## Regression smoke
- [ ] Task weight snackbar appears only for true precision limits, not for inconsistent intermediate state.
- [ ] Total pomodoros edits remain coherent with Task weight (%) display.
- [ ] Unselected tasks remain unaffected by weight edits.

## Local gate
- [ ] flutter analyze PASS.
- [ ] flutter test test/domain/task_weighting_test.dart PASS.
- [ ] flutter test test/presentation/viewmodels/task_editor_view_model_test.dart PASS.

## Closure rule
- [ ] Close only when all boxes above are checked with evidence in logs and screenshots.
