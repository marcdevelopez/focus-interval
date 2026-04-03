# Feature: IDEA-039 — Scheduling Conflict Explainer + Guided Start Suggestions

## Backlog reference
Backlog file: `docs/features/feature_backlog.md`
Backlog ID: IDEA-039
Backlog title: Scheduling Conflict Explainer + Guided Start Suggestions
Backlog status at extraction: in_progress
Execution order slot (if listed): 39

## Problem / Goal
Plan Group previously detected execution conflicts only after pressing Confirm,
with low-context dialogs and coarse resolution behavior. The goal is to surface
conflicts proactively in the planning UI, block invalid confirms deterministically,
and provide a unified conflict-resolution modal that supports partial selection.

## Scope
In scope:
- Shared conflict helpers extracted from Task List flow.
- Plan Group migration to `ConsumerStatefulWidget` with live provider inputs.
- Layer 1 inline conflict indicator and Confirm gating for scheduled options.
- Layer 2 unified blocking modal with running/scheduled badges and checkboxes.
- Transactional destructive intent propagation (`pendingCancelIds`,
  `pendingDeleteIds`) from Plan Group to Task List save flow.
- Task List cleanup: remove legacy running/scheduled conflict dialogs and legacy
  pre-confirm conflict checks.

Out of scope:
- New visual redesign beyond specified conflict UX.
- Additional multi-device ownership behavior changes outside IDEA-039 contract.

## Implementation log (commits)
- `d336179` — `refactor(conflicts): extract conflict detection helpers to shared utility`
- `0cadda4` — `feat(planning): migrate TaskGroupPlanningScreen to ConsumerStatefulWidget`
- `ecbd366` — `feat(idea039): add inline conflict indicators and unified conflict modal to Plan Group`
- `81de9e2` — `refactor(task-list): remove legacy conflict dialogs superseded by Plan Group flow`

Documentation/process commits in same branch:
- `7a59025` — feature backlog + handoff sync
- `2a58926` — merge-order safety rules for ledger integrity

## Validation strategy
1. Local gate (mandatory):
   - `flutter analyze`
   - `flutter test test/presentation/task_group_planning_screen_conflict_test.dart`
   - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
   - `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart`
   - `flutter test test/presentation/timer_screen_syncing_overlay_test.dart`
   - `flutter test test/presentation/utils/scheduled_group_timing_test.dart`
   - `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
2. Device validation (required before closure):
   - Scenario A (pre-run only): auto-clamp notice, no execution conflict UI, Confirm enabled.
   - Scenario B (execution conflict): inline chips + disabled Confirm in stable state.
   - Scenario C (race/modal path): modal actions produce expected selected running/scheduled resolution and final save behavior.

## Current status
- Local gate: PASS (2026-04-02).
- Device packet: pending.
- Feature status: In validation.
