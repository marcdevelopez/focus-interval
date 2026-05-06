## Exact repro

- [x] Scenario A PASS — automated widget evidence refreshed on 2026-05-06 (`task_group_planning_screen_conflict_test.dart` + `timer_screen_completion_navigation_test.dart --plain-name "shows running-overlap modal when decision already exists on mount"`).
- [x] Scenario B PASS — pre-run/range context path validated through shared conflict formatter + planning conflict packet refresh (see `2026-05-06_bug027_8600f44_local_task_group_planning_conflict.log`).
- [x] Scenario C PASS — runtime modal context labels validated (`Running:` / `Scheduled:` + conditional `Pre-Run`) in refreshed widget packet (`2026-05-06_bug027_8600f44_local_timer_overlap_modal.log`).
- [x] Scenario D PASS — mirror warning context + ownership CTA validated in refreshed widget packet (`2026-05-06_bug027_8600f44_local_task_list_mirror_banner.log`, `2026-05-06_bug027_8600f44_local_groups_hub_mirror_banner.log`, `2026-05-06_bug027_8600f44_local_timer_mirror_snackbar.log`).

## Regression smoke

- [x] No duplicate conflict messaging on same screen (banner vs snackbar contract preserved).
- [x] Postpone/cancel/end overlap actions still route and update state correctly.
- [x] Task List / Groups Hub navigation remains stable while overlap decision is active.

## Local gate

- [x] `flutter analyze` PASS (2026-05-01).
- [x] `flutter test test/presentation/timer_screen_completion_navigation_test.dart` PASS (2026-05-01).
- [x] `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` PASS (2026-05-01).
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` PASS (2026-05-01, clean re-run).
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS (2026-05-01).
- [x] `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` PASS (2026-05-01).
- [x] `flutter test test/presentation/utils/scheduled_group_timing_test.dart` PASS (2026-05-01).
- [x] `flutter analyze` PASS (2026-05-06 refresh).
- [x] `flutter test test/presentation/task_group_planning_screen_conflict_test.dart` PASS (2026-05-06 refresh).
- [x] `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "shows running-overlap modal when decision already exists on mount"` PASS (2026-05-06 refresh).
- [x] `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Task List mirror conflict banner shows request ownership CTA and triggers request"` PASS (2026-05-06 refresh).
- [x] `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Groups Hub mirror conflict banner shows request ownership CTA and triggers request"` PASS (2026-05-06 refresh).
- [x] `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Timer mirror shows persistent conflict snackbar until explicit OK"` PASS (2026-05-06 refresh).
- [x] `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Timer mirror dismisses conflict snackbar when overlap decision clears"` PASS (2026-05-06 refresh).

## Closure rule

- [x] Close `BUG-027` after A-D + regression smoke PASS with refreshed packet evidence (automated widget/runtime logs captured 2026-05-06).
