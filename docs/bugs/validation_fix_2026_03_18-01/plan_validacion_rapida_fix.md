# Rapid Validation Plan — BUG-F25-D (2026-03-18)

Date: 2026-03-18
Bug: `BUG-F25-D`
Scope: Mirror red error flash when running overlap is detected on resume.

## User-facing symptom
On the mirror device, the app shows a red Flutter error screen for less than 1 second when the owner resumes and a running overlap is detected. The app recovers by itself, but it looks like a crash.

## Technical root cause
`ScheduledGroupCoordinator` updated `runningOverlapDecisionProvider` synchronously from `_updateRunningOverlapDecision` (and clear path) while Flutter could still be in build phase. Riverpod correctly throws a build-phase mutation error.

## Runtime fix implemented
- File: `lib/presentation/viewmodels/scheduled_group_coordinator.dart`
- Changes:
  - Added scheduler-aware mutation helper.
  - Deferred overlap decision set/clear with `addPostFrameCallback` only when scheduler is in build-phase callbacks.
  - Added stale/dispose guards to avoid stale writes.
  - Added safe fallback for tests/environments where scheduler binding is not initialized.

## Exact repro (required for closure)
1. Account mode with two devices (owner + mirror).
2. Have one group paused/running and a second scheduled group that overlaps when owner resumes.
3. Keep mirror on a screen listening to `runningOverlapDecisionProvider`.
4. On owner, press Resume.
5. Verify mirror behavior.

Expected after fix:
- No red error flash.
- Overlap decision flow still appears/works.

## Regression smoke checks (required for closure)
1. `BUG-F25-C`: owner must not show mirror-only "Owner resolved" modal after Continue.
2. `BUG-F25-A/B`: ownership request path still delivers + no context-after-dispose crash.
3. Timer sync overlay behavior remains stable (`timer_screen_syncing_overlay_test.dart`).
4. Session-gap protections remain stable (`pomodoro_view_model_session_gap_test.dart`).

## Local verification completed
- `flutter analyze` → PASS
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "running overlap decision"` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → PASS
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` → PASS
- `flutter test` (full suite) → FAIL (existing unrelated failures in `scheduled_group_coordinator_test.dart`, AppModeService init + one timeout).

## Status
In validation (device exact repro pending).

## Tracking
- Branch: `fix-f25-d-overlap-build-phase`
- Implementation commit: `07ac0cb` — `fix(f25-d): defer running-overlap provider mutation out of build phase`
