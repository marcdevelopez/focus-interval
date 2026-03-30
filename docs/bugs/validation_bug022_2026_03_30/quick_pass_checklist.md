## Exact repro
- [x] Scenario A PASS (macOS sign-out -> Authentication: email/password typing works immediately)
- [x] Scenario B PASS (same-session retries reported stable by user; no keyboard lock recurrence observed at closure time)

## Regression smoke
- [x] Android/non-macOS paths remain unaffected by this patch (no analyzer/test regressions; macOS-only guard)
- [x] macOS Authentication still supports password visibility toggle and normal auth actions

## Local gate
- [x] `flutter analyze` PASS
- [x] `flutter test test/presentation/timer_screen_completion_navigation_test.dart` PASS
- [x] Manual/user-run smoke in LoginScreen PASS

## Closure rule
- [x] Exact repro + regression smoke + local gate all PASS with evidence recorded in packet/thread
- [x] `BUG-022` and `BUGLOG-022` updated to `Closed/OK` with commit hash/message/evidence
