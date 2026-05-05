## Exact repro

- [x] Scenario A PASS: exact same-conditions crash repro executed and evidence collected (2026-05-05 dual logs).
- [ ] Scenario B PASS: pause-first control run executed to isolate BUG-032 from BUG-033.
- [x] Scenario C executed (2026-05-01): prolonged background + memory pressure run captured as non-repro (13:05-14:35 EDT).

## Regression smoke

- [ ] No unrelated ownership/session continuity regressions observed in Android + macOS during BUG-033 runs.
- [ ] No persistent network/DNS instability during background windows (`firestore.googleapis.com` host resolution remains healthy).

## Local gate

- [x] `flutter analyze` PASS (2026-05-05).
- [x] Targeted local regression test PASS (`flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`, 2026-05-05).

## Closure rule

- [ ] Crash signatures absent in fixed run logs (`ForegroundServiceStartNotAllowedException`, `FATAL EXCEPTION`, `SIG: 9`).
- [ ] Validation packet includes final logs and screenshot evidence references.
- [x] Rolling monitor protocol ready for next sessions (dual capture commands kept in plan and reused each run).
