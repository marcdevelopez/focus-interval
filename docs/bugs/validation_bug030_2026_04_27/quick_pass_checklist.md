## Exact repro

- [x] Scenario A PASS: Chrome mirror stays in Groups Hub ≥ 60s with active owner session (no forced redirect).
- [x] Scenario B PASS: Chrome mirror stays in Task List/Plan Group ≥ 60s with active owner session (no forced redirect).
- [x] Scenario C PASS: PHASE6 non-regression (phase transition on timer route does not break Run Mode).
- [x] Scenario D PASS: re-entry via "Open Run Mode" works after intentional departure.

## Regression smoke

- [x] `[PHASE6] auto-open guard clears when VM is disposed mid-session` PASS.
- [x] `[BUG-030] auto-open stays suppressed after intentional departure from Run Mode` PASS.
- [x] Full `timer_screen_syncing_overlay_test.dart` suite PASS.

## Local gate

- [x] flutter analyze PASS.

## Closure rule

- [x] Close only when all boxes above are checked with logs/screenshots evidence and docs are synchronized.
