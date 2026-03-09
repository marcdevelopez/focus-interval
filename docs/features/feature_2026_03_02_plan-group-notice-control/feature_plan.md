# Feature Plan — Plan Group Pre-Run Notice Control

Date: 02/03/2026
Feature ID: IDEA-032
Status: validated/closed — 02/03/2026
Validation reference: `docs/features/feature_2026_03_02_plan-group-notice-control/feature_checklist.md`

## Goal

Expose and edit the effective pre-run notice during Plan group and keep the re-plan flow coherent when notice constraints block scheduling.

## Scope

- Add a "Pre-run notice" row in Plan group with an edit affordance.
- Keep notice values within 0–15 and clamp to the real-time max allowed for the selected start.
- Ensure planning validation and new group creation use the selected notice value.
- In Groups Hub, provide a persistent snackbar with Change notice when the notice prevents scheduling.

## UX Notes

- Notice editor uses a modal slider and live-updates the allowed range as time advances.
- For Start now, the notice row is informative only; notice still applies to the next scheduled plan.
- Change notice from snackbar reopens Plan group with the prior schedule and a suggested valid notice.

## Data + Logic

- Use the global notice setting as the default; allow per-group override via planning.
- Save the selected notice into TaskRunGroup.noticeMinutes for the new group.
- Pre-run window checks respect the selected notice before conflicts are evaluated.

## Implementation Steps

1. Extend planning args/result to carry notice minutes.
2. Add pre-run notice UI to Plan group with realtime validity.
3. Wire Groups Hub snackbar "Change notice" to reopen Plan group with a valid notice.
4. Use selected notice in Task List and Groups Hub group creation.
5. Run analyzer and record results.

## Risks

- Notice validity can shrink while editing; UI must auto-clamp safely.

## Validation

- Validate scheduling with notice > 0 and notice = 0 in Task List and Groups Hub.
- Confirm re-plan uses the adjusted notice and new group persists it.
