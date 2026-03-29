## Exact repro
- [x] Task weight (%) preview (Fixed/Flexible) is deterministic from preview -> Apply -> Save -> Task List -> reopen.
- [x] Total pomodoros preview (Fixed/Flexible) is deterministic from preview -> Apply -> Save -> Task List -> reopen.
- [x] Fixed/Flexible outcomes are coherent with current specs and rounding/indivisible constraints.
- [x] Back/Cancel path does not apply draft changes.
- [x] "No changes applied." hint is shown once (no duplicate snackbar).

## Regression smoke
- [x] Exact/closest warning behavior remains interaction-gated and non-redundant.
- [x] Continuous-time caution levels (`Unusual`/`Superhuman`/`Machine`) render consistently in preview and reminder chips.
- [x] Task List chip row remains usable on desktop and mobile (desktop wheel horizontal scroll enabled).
- [x] Preview selected-task rows clearly identify edited task/dimension.

## Local gate
- [x] flutter analyze PASS.
- [x] flutter test test/domain/task_weighting_test.dart PASS.
- [x] flutter test test/presentation/viewmodels/task_editor_view_model_test.dart PASS.
- [x] flutter test test/domain/continuous_plan_load_test.dart PASS.

## Closure rule
- [x] Close only when all boxes above are checked with evidence in logs/checklist and synced docs (bug log, ledger, roadmap, dev log).
