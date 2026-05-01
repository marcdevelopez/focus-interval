## Exact repro

- [x] Scenario A PASS: mirror shows conflict snackbar while overlap is active.
- [x] Scenario B PASS: snackbar auto-dismisses after owner resolves overlap.
- [x] Scenario C PASS: after decision clear, navigation Run Mode <-> Groups Hub <-> Task List does not show stale conflict snackbar.

## Regression smoke

- [x] `Timer mirror shows persistent conflict snackbar until explicit OK` PASS.
- [x] `Timer mirror dismisses conflict snackbar when overlap decision clears` PASS.

## Local gate

- [x] `flutter analyze lib/presentation/screens/timer_screen.dart test/presentation/timer_screen_completion_navigation_test.dart` PASS.

## Closure rule

Close only when all Exact repro boxes are checked with log/screenshot evidence and docs are synchronized.
