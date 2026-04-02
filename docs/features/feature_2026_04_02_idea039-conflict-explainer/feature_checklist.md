# IDEA-039 Validation Checklist

Date: 2026-04-02
Branch: `feature/idea039-conflict-explainer`
Status: In validation

## Local gate (required)
- [x] `flutter analyze` PASS.
- [x] `flutter test test/presentation/task_group_planning_screen_conflict_test.dart` PASS (`+3`).
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` PASS.
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS.
- [x] `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` PASS.
- [x] `flutter test test/presentation/utils/scheduled_group_timing_test.dart` PASS.
- [x] `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` PASS.

## Scenario A — Pre-run only conflict (Case A)
- [ ] On device: select scheduled time with pre-run overlap only.
- [ ] Notice auto-clamps to available minutes.
- [ ] No execution conflict chips shown.
- [ ] Confirm remains enabled.

## Scenario B — Execution conflict inline (Case B)
- [ ] On device: select scheduled time with execution overlap.
- [ ] Inline `Scheduling conflict` indicator appears with chips.
- [ ] Confirm disabled in stable inline-conflict state.

## Scenario C — Unified modal + transactional application
- [ ] On device: trigger modal path and verify running/scheduled badges.
- [ ] Verify selected groups are accumulated as pending actions from Plan Group.
- [ ] Verify destructive actions are applied only after new group save succeeds.
- [ ] Verify final state is coherent when partial selection leaves remaining conflicts.

## Closure rule
- [ ] Device scenarios A/B/C PASS on real devices.
- [ ] Evidence captured (logs/screenshots if needed).
- [ ] Update `docs/validation/validation_ledger.md` to `Closed/OK` for `IDEA-039`.
- [ ] Sync `docs/features/feature_backlog.md` + `docs/roadmap.md` + `docs/dev_log.md`.
