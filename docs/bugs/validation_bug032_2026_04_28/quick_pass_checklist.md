## Exact repro

- [ ] Scenario A PASS: paused group remains paused after owner sleep/background transfer and later reopen.
- [ ] No unexpected auto-complete while paused even when `theoreticalEndTime` is in the past.

## Regression smoke

- [x] Unit PASS: `does not complete expired running group when stream is null but server has paused session for same group`.
- [x] Unit PASS: `completes expired running group without active session and routes to Groups Hub`.
- [x] Unit PASS: `completes expired running group when stream is null but server session is for another group`.

## Local gate

- [x] `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` PASS.
- [x] `flutter analyze` PASS.

## Closure rule

Close only when all Exact repro + Regression smoke + Local gate checks are PASS with logs/screenshots evidence and synchronized docs.
