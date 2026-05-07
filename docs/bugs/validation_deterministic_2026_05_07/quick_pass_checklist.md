## Exact repro

- [ ] Scenario A PASS: scheduled group auto-starts in deterministic execution window without conflict modal.
- [ ] Scenario B PASS: overdue scheduled group transitions to Lost (`canceledReason = 'lost'`) and appears under Lost section.
- [ ] Scenario C PASS: at-risk snackbar appears/dedupes/re-arms while running group is active, with no modal.
- [ ] Scenario D PASS: Re-plan from Lost keeps inline conflict blocking behavior and creates new group only after conflict-free slot.
- [ ] Scenario E PASS: Plan Group inline chips show effective blocker window (not raw stale range) and Confirm stays disabled while conflict exists.

## Regression smoke

- [ ] Ownership request/transfer flow still works in Account Mode (no regression from deterministic changes).
- [ ] Paused session projection remains coherent across Groups Hub and Plan Group conflict surfaces.
- [ ] No legacy conflict-modal strings/flows observed during scenarios A-E.

## Local gate

- [x] `flutter analyze` PASS.
- [x] `flutter test test/presentation/task_group_planning_screen_conflict_test.dart` PASS.
- [x] `flutter test test/presentation/timer_screen_completion_navigation_test.dart` PASS.
- [x] `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` PASS.

## Closure rule

Close only when all Exact repro and Regression smoke boxes are checked with logs/screenshots saved under this packet and closure docs synchronized.
