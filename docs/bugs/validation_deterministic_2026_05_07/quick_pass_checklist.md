## Exact repro

- [x] Scenario A PASS: scheduled group auto-starts in deterministic execution window without conflict modal.
- [x] Scenario B PASS: overdue scheduled group transitions to Lost (`canceledReason = 'lost'`) and appears under Canceled section with `Reason: Lost`.
- [x] Scenario C PASS: at-risk snackbar appears/dedupes/re-arms while running group is active, with no modal.
- [x] Scenario C2 PASS (new trigger): paused drift reaches next scheduled start before scheduled window and shows at-risk snackbar (Android + iOS + Chrome).
- [x] Scenario D PASS: Re-plan from canceled Lost item keeps inline conflict blocking behavior and creates new group only after conflict-free slot.
- [x] Scenario E PASS: Plan Group inline chips show effective blocker window (not raw stale range) and Confirm stays disabled while conflict exists.
- [x] Scenario F PASS (time picker regression): selecting a future start time (including `12:00`) keeps that planned time in `Schedule by start time` and does not auto-rewrite to current local time.

## Regression smoke

- [x] Ownership request/transfer flow still works in Account Mode (no regression from deterministic changes).
- [x] Paused session projection remains coherent across Groups Hub and Plan Group conflict surfaces.
- [x] No legacy conflict-modal strings/flows observed during scenarios A-E.
- [x] Post-fix runtime logs captured with current hash tag (`03047b5`) for Android + iOS + Chrome.

## Local gate

- [x] `flutter analyze` PASS.
- [x] `flutter test test/presentation/task_group_planning_screen_conflict_test.dart` PASS.
- [x] `flutter test test/presentation/timer_screen_completion_navigation_test.dart` PASS.
- [x] `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` PASS.

## Closure rule

Close only when all Exact repro and Regression smoke boxes are checked with logs/screenshots saved under this packet and closure docs synchronized.
