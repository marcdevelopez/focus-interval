## Exact repro

- [x] Scenario A evidence captured: `Next status` predicts `Break: 15 min` before transition.
- [x] Scenario A evidence captured: runtime executes `Break: 5 min` after transition.
- [x] Scenario B evidence captured: contextual task-item ranges diverge from status-box/runtime timeline (`Curso Develop Flutter`).
- [ ] Scenario A/B reproduced again on demand in a fresh run.

## Regression smoke

- [ ] Shared mode: break prediction/execution and timeline ranges are coherent across boundary transitions.
- [ ] Non-shared mode smoke (`fixed`/`flexible`): no new timeline desync introduced.

## Local gate

- [ ] `flutter analyze` PASS.
- [ ] Targeted timeline regression tests PASS.

## Closure rule

- [ ] Close `BUG-034` only after exact repro + regression smoke + local gate PASS with logs/screenshots attached in this packet.
