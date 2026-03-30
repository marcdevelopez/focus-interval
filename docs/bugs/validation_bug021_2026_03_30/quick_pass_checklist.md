## Exact repro
- [x] Scenario A PASS (stale rejection snackbar auto-dismisses when requester becomes owner) — validated in widget test and log review.
- [x] Scenario B PASS (old rejection snackbar auto-dismisses when new request is submitted) — validated in widget test and log review.
- [x] Scenario C PASS (snackbar auto-dismisses when ownership request is cleared/replaced) — validated through key-based invalidation path and targeted checks.

## Regression smoke
- [x] Ownership request -> reject -> retry flow remains coherent in Run Mode.
- [x] Ownership indicator states (owner/mirror/pending) remain consistent while stale rejection snackbar is auto-dismissed.
- [x] No duplicate or contradictory rejection snackbar remains visible after ownership transitions in validated scenarios.

## Local gate
- [x] `flutter analyze` PASS
- [x] `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Run Mode dismisses stale rejection snackbar"` PASS

## Closure rule
- [x] Exact repro + regression smoke + local gate accepted as PASS with logs and tests.
- [x] `BUG-021` and `BUGLOG-021` moved to `Closed/OK` with closure evidence.
