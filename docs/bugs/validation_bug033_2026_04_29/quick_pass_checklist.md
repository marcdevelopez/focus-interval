## Exact repro

- [ ] Scenario A PASS: exact same-conditions crash repro executed and evidence collected.
- [ ] Scenario B PASS: pause-first control run executed to isolate BUG-032 from BUG-033.
- [x] Scenario C executed (2026-05-01): prolonged background + memory pressure run captured as non-repro (13:05-14:35 EDT).

## Regression smoke

- [ ] No unrelated ownership/session continuity regressions observed in Android + macOS during BUG-033 runs.
- [ ] No persistent network/DNS instability during background windows (`firestore.googleapis.com` host resolution remains healthy).

## Local gate

- [ ] `flutter analyze` PASS.
- [ ] Targeted service-lifecycle test coverage PASS (when implemented).

## Closure rule

- [ ] Crash signatures absent in fixed run logs (`ForegroundServiceStartNotAllowedException`, `FATAL EXCEPTION`, `SIG: 9`).
- [ ] Validation packet includes final logs and screenshot evidence references.
- [ ] Rolling monitor protocol ready for next sessions (dual capture commands kept in plan and reused each run).
