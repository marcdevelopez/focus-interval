## Exact repro

- [x] Single-run short repro executed with `~15 min` group in Account Mode.
- [x] Initial owner confirmed on macOS, then macOS entered real sleep (lid closed).
- [x] Android ownership takeover confirmed before pause action.
- [x] Android paused session, moved app to background, and remained backgrounded past `theoreticalEndTime`.
- [x] Android reopen PASS: group remains `paused` (not `completed`) in Timer and Groups Hub.
- [x] 20-30s smoke PASS on Android after reopen: `Resume` progressed normally, then `Pause` restored paused state (no terminal jump).
- [x] macOS wake + resync PASS: state remains non-terminal/paused-coherent (no forced completion).
- [x] Firestore post-wake snapshot captured and consistent with paused/non-terminal expectation.

## Regression smoke

- [x] Unit PASS: `does not complete expired running group when stream is null but server has paused session for same group`.
- [x] Unit PASS: `completes expired running group without active session and routes to Groups Hub`.
- [x] Unit PASS: `completes expired running group when stream is null but server session is for another group`.

## Local gate

- [x] `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` PASS.
- [x] `flutter analyze` PASS.

## Closure rule

Close only when all Exact repro + Regression smoke + Local gate checks are PASS with logs/screenshots evidence and synchronized docs (`bug_log` + `validation_ledger` + `dev_log`).
