## Exact repro

- [x] Scenario A evidence captured: `Next status` predicts `Break: 15 min` before transition.
- [x] Scenario A evidence captured: runtime executes `Break: 5 min` after transition.
- [x] Scenario B evidence captured: contextual task-item ranges diverge from status-box/runtime timeline (`Curso Develop Flutter`).
- [ ] Scenario A/B reproduced again on demand in a fresh run.

## Regression smoke

- [ ] Shared mode: break prediction/execution and timeline ranges are coherent across boundary transitions.
- [ ] Non-shared mode smoke (`individual`): no new timeline desync introduced.

## Local gate

- [x] `flutter analyze` PASS.
- [x] Targeted timeline regression tests PASS (`flutter test test/presentation/timer_screen_break_prediction_test.dart`; `flutter test test/data/models/task_run_group_mode_a_breaks_test.dart`).

## Closure rule

- [ ] Close `BUG-034` only after exact repro + regression smoke + local gate PASS with logs/screenshots attached in this packet.
