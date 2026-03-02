# Plan — Rapid Validation Fixes (Late-start, Pre-Run, Ranges, Black Screen)

Date: 2026-02-24
Source: docs/bugs/validacion_rapida.md and docs/bugs/capturas-validacion

## Scope (Bugs To Fix)
1. Late-start queue Cancel all does not resolve mirrors; mirrors can continue after owner cancel.
2. Resolve overlaps with zero selected groups should behave like Cancel all (no black screen).
3. Pre-Run auto-open bounces or duplicates; must be idempotent on owner and mirror.
4. Pre-Run to Running sometimes shows Resolve overlaps without real conflict.
5. Groups Hub schedule shows +1 minute gap; scheduled time vs pre-run start confusion.
6. Timer status boxes and task item ranges are out of sync after pause and resume.
7. Postpone updates do not propagate to mirror quickly (stale schedule).
8. Black screen on logout while running or paused, and any other navigation path that can blank the UI.

## Decisions And Requirements
- Mirror after Cancel all shows a modal "Owner resolved" with OK, then navigates to Groups Hub.
- Zero selected groups in Resolve overlaps equals Cancel all (same modal and cleanup).
- Groups Hub shows "Pre-Run X min starts at HH:mm" when notice applies.
- Scheduled in Groups Hub shows the run start time, not the pre-run start.
- Pre-Run and Run Mode auto-open must occur on both owner and mirror.
- If the user leaves Pre-Run, Run Mode still auto-opens at group start.
- Cancel and Logout must never leave a blank screen.

## Plan (Docs First, Then Code)
1. Update specs to define the expected flows, UI copy, and navigation guard rules.
2. Update roadmap reopened items for black screen and new UI requirement if missing.
3. Append dev log entry for changes and decisions.
4. Implement late-start queue mirror resolution flow and guard against actions after cancel.
5. Treat zero selection as Cancel all (reuse the same path).
6. Make auto-open idempotent with route guards keyed by groupId and phase.
7. Ensure Pre-Run to Running does not route to Resolve overlaps unless an actual conflict exists.
8. Fix schedule display by separating run start from pre-run start and eliminate extra minute.
9. Align Timer status boxes with authoritative ranges (actualStartTime plus pause offsets).
10. Ensure mirror schedule updates refresh immediately after postpone.
11. Add navigation guards to prevent black screens on logout or cancel and keep UI navigable.

## Acceptance Criteria
1. Mirror gets "Owner resolved" modal after Cancel all and exits to Groups Hub.
2. Resolve overlaps with zero selection yields the same result as Cancel all with no black screen.
3. Pre-Run auto-opens once on both devices with no duplicate navigation or Groups Hub bounce.
4. Run Mode opens at group start on both devices even if the user left Pre-Run.
5. Resolve overlaps does not appear without a real conflict after pre-run.
6. Groups Hub shows explicit pre-run start time and correct scheduled run start.
7. Timer status boxes and task item ranges always match.
8. Postpone updates appear on mirror without stale schedule.
9. Logout while running or paused does not produce a black screen.

## Validation Checklist
- Re-run steps A through H in docs/bugs/validacion_rapida.md.
- Verify screenshots 01 to 28 are no longer reproducible.
- Confirm on macOS and Android in owner and mirror roles.
