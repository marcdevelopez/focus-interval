## Exact repro

- [ ] Scenario A PASS on deterministic reproduce-on-demand run.
- [x] Exact deterministic repro waived by user decision (bug trigger is non-deterministic/intermittent on macOS).
- [x] Scenario B PASS in Authentication path after resume/focus churn.

## Regression smoke

- [x] Non-login editors accept keyboard input after resume/focus churn (no persistent lock requiring restart).
- [x] LoginScreen still accepts typing (legacy BUG-022 path non-regression).

## Local gate

- [x] `flutter analyze` PASS.
- [x] `flutter test test/presentation/timer_screen_completion_navigation_test.dart` PASS.

## Closure rule

- [x] Close only after local gate PASS + packet evidence sync + explicit user acceptance of the non-deterministic repro waiver.
