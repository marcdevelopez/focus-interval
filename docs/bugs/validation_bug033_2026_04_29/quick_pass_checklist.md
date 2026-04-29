## Exact repro

- [ ] Scenario A PASS: exact same-conditions crash repro executed and evidence collected.
- [ ] Scenario B PASS: pause-first control run executed to isolate BUG-032 from BUG-033.

## Regression smoke

- [ ] No unrelated ownership/session continuity regressions observed in Android + macOS during BUG-033 runs.

## Local gate

- [ ] `flutter analyze` PASS.
- [ ] Targeted service-lifecycle test coverage PASS (when implemented).

## Closure rule

- [ ] Crash signatures absent in fixed run logs (`ForegroundServiceStartNotAllowedException`, `FATAL EXCEPTION`, `SIG: 9`).
- [ ] Validation packet includes final logs and screenshot evidence references.
