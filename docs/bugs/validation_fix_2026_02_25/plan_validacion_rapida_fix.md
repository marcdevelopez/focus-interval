# Plan — Rapid Validation Fixes (Post-Validation 2026-02-24)

Date: 2026-02-25
Source: docs/bugs/validation_fix_2026_02_24/quick_pass_checklist.md + screenshots

## Scope (Bugs To Fix)
1. Late-start queue Cancel all: mirror does not show the "Owner resolved" modal; owner shows it instead.
2. After Cancel all, mirror can still act as owner and continue Resolve overlaps.
3. "Owner resolved" modal does not dismiss on OK (requires tapping outside).
4. Scheduling conflict modal triggers when the running group end time coincides with the next group's pre-run start (false conflict).
5. Groups Hub re-plan "Start now" sometimes fails to open Run Mode and remains on Groups Hub (regression).
6. After group completion, the app sometimes lands on the Ready screen with Start button instead of returning to Groups Hub (regression).
7. Android: black screen when leaving Timer Run -> Groups Hub -> Task List, then tapping logout in the AppBar (Chrome does not reproduce).
8. Groups Hub scheduled rows inconsistent between devices (owner shows "Pre-Run: X min starts at HH:mm" while mirror shows "Notice: X min").
9. Running task item time range is off by one minute compared to status boxes after pre-run/ownership transitions.
10. Analyzer warnings: remove unnecessary non-null assertions and avoid BuildContext across async gaps.
11. Timer Run Mode bounces back to Groups Hub after Start now / Run again / scheduled start (brief Timer flash, then Groups Hub). User must tap "Open Run Mode" manually. Root cause likely inconsistent entry paths into Run Mode.
12. Follow-up: Scheduled auto-start with notice 0 still bounces to Groups Hub on both devices; Run Mode opens only with manual "Open Run Mode" (validation 26/02/2026).
13. Follow-up: Account Mode Start now / Run again can create a running TaskRunGroup without `activeSession/current`; Run Mode shows "Syncing session" or stays in Groups Hub (validation 26/02/2026).
14. Follow-up: Late-start queue claim fails on some devices; mirror never shows Resolve overlaps or "Owner resolved" after Cancel all (validation 26/02/2026).

## Decisions And Requirements
- Cancel all must resolve the queue for **all** devices.
- The "Owner resolved" modal must appear on mirrors (not owners) and must dismiss on OK.
- After Cancel all, mirrors must not be able to proceed as owner; actions must be locked until the queue is fully resolved.
- Scheduling conflict should only appear when there is a **real overlap**; equality at the pre-run boundary must not trigger a conflict.
- Re-plan "Start now" must always navigate to Run Mode reliably.
- Group completion must always return to Groups Hub; Ready screen must never appear after group completion.
- Android logout must never show a black screen; behavior must match Chrome.
- Scheduled group rows must render the same fields on owner and mirror.
- Task item time ranges must match authoritative status box ranges.
- All entry points (Start now, Run again, scheduled auto-start) must use a single Run Mode start pipeline.
- The start pipeline must provide the new group snapshot to Run Mode to avoid read races on immediate navigation.
- If the group truly does not exist after the unified start pipeline, show "Selected group not found" and return to the correct hub screen.
- Account Mode Start now / Run again must publish `activeSession/current` as owner when a group transitions to running; a running group without `activeSession` is invalid.

## Fix Order (Implementation Sequence)
Each item below is a separate fix and must be committed separately.
1. Late-start queue Cancel all: mirror modal, owner/mirror gating, modal OK (Scope 1–3).
2. Android logout black screen (Timer Run -> Groups Hub -> Task List -> logout) (Scope 7).
3. Completion must navigate to Groups Hub (no Ready screen) (Scope 6).
4. False conflict at pre-run boundary (Scope 4).
5. Task item time ranges must match status boxes (Scope 9).
6. Scheduled rows must match on owner/mirror (Pre-Run vs Notice) (Scope 8).
7. Re-plan "Start now" must always open Run Mode (Scope 5).
8. Analyzer warnings cleanup (Scope 10).
9. Timer Run Mode must not bounce back to Groups Hub after Start now / Run again / scheduled start by using a unified start pipeline (Scope 11).
10. Follow-up: Scheduled auto-start notice 0 must stay in Run Mode (Scope 12).
11. Follow-up: Scheduled auto-start must navigate immediately (no 1–2s Groups Hub flash) (Scope 12).
12. Follow-up: Account Mode Start now / Run again must create `activeSession/current` (Scope 13).
13. Follow-up: Late-start queue claim must not block mirror queue display or "Owner resolved" modal (Scope 14).

## Fix Tracking
Update this section after each fix.
1. Fix 1 (Scope 1–3): Done (2026-02-25, tests: `flutter test`, commit: 9f614e6 "Fix 1: late-start owner resolved gating")
2. Fix 2 (Scope 7): Done (2026-02-25, tests: `flutter test`, commit: 0c66629 "Fix 2: stabilize Android logout navigation")
3. Fix 3 (Scope 6): Done (2026-02-25, tests: `flutter test`, commit: 16a6522 "Fix 3: ensure completion returns to Groups Hub")
4. Fix 4 (Scope 4): Done (2026-02-25, tests: `flutter test`, commit: 59ab399 "Fix 4: add pre-run overlap grace")
5. Fix 5 (Scope 9): Done (2026-02-25, tests: `flutter test`, commit: 34d1938 "Fix 5: align status box ranges")
6. Fix 6 (Scope 8): Done (2026-02-25, tests: `flutter test`, commit: b99decb "Fix 6: align scheduled pre-run rows")
7. Fix 7 (Scope 5): Done (2026-02-25, tests: `flutter test`, commit: 726d69b "Fix 7: ensure Start now opens Run Mode")
8. Fix 8 (Scope 10): Done (2026-02-25, tests: `flutter analyze`, commit: 3913cbd "Fix 8: analyzer warnings cleanup")
9. Fix 9 (Scope 11): Done (2026-02-26, tests: `flutter analyze`, commit: dfa0048 "Fix 9: unify Run Mode start pipeline") — unified Run Mode start pipeline with in-memory snapshot; prior attempt 16d2098 superseded. Validation: Start now + Run again OK; scheduled notice 0 still bounces (needs follow-up).
10. Fix 10 (Scope 12): Implemented (2026-02-26, tests: `flutter analyze`, commit: fd2a385 "Fix 10: stabilize auto-open gating") — auto-open now marks a group as opened only after confirming `/timer/:id`, and resets when not in timer. Root cause: auto-open marked opened before route confirmation, suppressing further auto-open after a bounce. Follow-up: scheduled auto-start still shows 1–2s in Groups Hub due to waiting on `getById` before navigation; fix by navigating first and prefetching after.
11. Fix 11 (Scope 12 follow-up): Implemented (2026-02-26, tests: `flutter analyze`, commit: 477ef31 "Fix 11: fast scheduled auto-start navigation") — scheduled auto-start navigates to `/timer/:id` before prefetch to avoid initial Groups Hub delay.
12. Fix 12 (Scope 13): Done (2026-02-26, tests: `flutter analyze`, commit: 7447f57 "Fix 12: auto-start running groups on load") — Account Mode Start now / Run again now auto-start on initial load and are gated to the initiating device when session is missing.
13. Fix 13 (Scope 14): Planned (2026-02-26, tests: TBD, commit: TBD) — late-start claim must be resilient to mixed timestamp formats and still surface the queue on mirrors even if claim fails.

## Plan (Docs First, Then Code)
1. Update specs if any new edge-case rules or timing tolerances are added.
2. Update roadmap reopened items if new bugs/requirements are introduced.
3. Append dev log entry for decisions and scope.
4. Implement fixes in the order listed above, one fix per commit.

## Acceptance Criteria
1. Mirror shows "Owner resolved" modal after Cancel all; owner does not.
2. Modal dismisses on OK without requiring an outside tap.
3. Mirror cannot proceed as owner after Cancel all.
4. No conflict modal when the running end time equals the next pre-run start.
5. Re-plan "Start now" always opens Run Mode.
6. After group completion, the app always navigates to Groups Hub.
7. Android logout never produces a black screen (Timer Run -> Groups Hub -> Task List -> logout).
8. Owner and mirror show the same scheduled rows (Pre-Run line when notice applies).
9. Task item ranges match status boxes in Run Mode.
10. `flutter analyze` reports no warnings for the updated files.
11. Start now / Run again / scheduled auto-start keeps the user in Timer Run Mode (no bounce to Groups Hub).
12. All entry points use the same Run Mode start path (single authoritative flow).
13. If the group is truly missing after the unified start pipeline, show "Selected group not found" and navigate to the correct hub screen.
14. Account Mode Start now / Run again always creates `activeSession/current` for running groups; Run Mode never stays in "Syncing session" due to a missing session doc.

## Validation Checklist
- Create `quick_pass_checklist.md` **after** implementation, focused only on the bugs above.
- Validate on macOS (owner) + Android (mirror) using fresh screenshots.
