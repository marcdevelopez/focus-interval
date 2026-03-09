# Feature: IDEA-035 — Groups Hub Status Borders + Offline Completion Highlight

## Backlog reference
Backlog file: `docs/features/feature_backlog.md`
Backlog ID: IDEA-035
Backlog title: Groups Hub Status Borders + Offline Completion Highlight
Backlog status at extraction: idea
Execution order slot (if listed): 34

## Problem / Goal
Groups Hub cards do not consistently communicate status at a glance. Completed
cards sometimes show inconsistent colors (green vs amber), and canceled groups
are not visually distinct. Users also need a clear visual cue when a group
completed while no device was open (offline completion).

## Summary
Unify Groups Hub card border colors by status and add an offline-completion
highlight. Ensure the completed color always matches the Run Mode completion
color, and provide a subtle amber highlight when a group completed while no
app was open.

## Scope
In scope:
- Standardize card border colors for Scheduled, Completed, and Canceled.
- Offline-completion highlight (amber or green↔amber alternation).
- Ensure completed color matches Run Mode completion color.

Out of scope:
- Collapsible section headers or category labels (covered by IDEA-008).
- Any changes to scheduling or conflict logic.

## Design / UX
Layout / placement:
Card border stroke color based on status.

Visual states:
- Scheduled: neutral grey (current).
- Completed: green (same as Run Mode completion color).
- Canceled: red (negative state).
- Completed while offline: amber or smooth alternation between green and amber.

Animation rules:
If alternation is used, keep it slow and smooth (no flashing). Provide a static
amber fallback if animation is not feasible.

Interaction:
No new interaction (visual-only).

Text / typography:
No changes.

## Data & logic
Source of truth:
TaskRunGroup status + a “completed while offline” signal.

Calculations:
Derive offline-completion when completion is reconciled on open after a period
with no foreground devices. Decide whether to persist a flag or compute per
session (must be deterministic).

Sync / multi-device:
Presentation only. No new sync writes unless a persistent flag is required.

## Edge cases
- If completion is reconciled on open, first render must already show the
  offline-completion highlight.
- Canceled state overrides any completion styling.

## Accessibility
Ensure colors meet contrast requirements and include semantic labels for status
in accessibility where applicable.

## Dependencies
- IDEA-008 for collapsible category sections.
- Requires a deterministic rule for detecting offline-completion.

## Risks
Overuse of color or inconsistent completion detection could confuse users.

## Acceptance criteria
- Scheduled cards remain neutral grey.
- Completed cards always use the same green as Run Mode completion.
- Canceled cards use red.
- Completed while offline shows amber (or smooth green↔amber alternation).

## Testing
Manual checks:
- Verify each status color in Groups Hub.
- Verify offline-completion highlight on first render after reopening.

Automated checks:
- N/A (UI visual states).

## Notes
This feature is purely visual and must not change scheduling or sync logic.
