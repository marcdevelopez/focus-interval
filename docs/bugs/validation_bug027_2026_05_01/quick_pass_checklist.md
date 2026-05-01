## Exact repro
- [ ] Scenario A PASS — Groups Hub running conflict modal shows selected range + blocker name/range.
- [ ] Scenario B PASS — pre-run snackbar shows blocker name/range + candidate pre-run window.
- [ ] Scenario C PASS — Timer runtime modal shows Running/Scheduled context + conditional Pre-Run label.
- [ ] Scenario D PASS — mirror warning surfaces expose context summary and ownership CTA still works.

## Regression smoke
- [ ] No duplicate conflict messaging on same screen (banner vs snackbar contract preserved).
- [ ] Postpone/cancel/end overlap actions still route and update state correctly.
- [ ] Task List / Groups Hub navigation remains stable while overlap decision is active.

## Local gate
- [x] `flutter analyze` PASS (2026-05-01).
- [x] `flutter test test/presentation/timer_screen_completion_navigation_test.dart` PASS (2026-05-01).
- [x] `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` PASS (2026-05-01).

## Closure rule
- [ ] Close `BUG-027` only after A-D + regression smoke PASS with logs/screenshots captured in this packet.
