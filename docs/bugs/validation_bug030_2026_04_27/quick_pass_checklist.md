## Exact repro

- [ ] Scenario A PASS: macOS mirror stays in Groups Hub ≥ 60s with active owner session (no forced redirect).
- [ ] Scenario B PASS: macOS mirror stays in Task List ≥ 60s with active owner session (no forced redirect).
- [ ] Scenario C PASS: PHASE6 non-regression (phase transition on timer route does not break Run Mode).
- [ ] Scenario D PASS: re-entry via "Open Run Mode" works after intentional departure.

## Regression smoke

- [x] `[PHASE6] auto-open guard clears when VM is disposed mid-session` PASS.
- [x] `[BUG-030] auto-open stays suppressed after intentional departure from Run Mode` PASS.
- [x] Full `timer_screen_syncing_overlay_test.dart` suite PASS.

## Local gate

- [x] flutter analyze PASS.

## Closure rule

- [ ] Close only when all boxes above are checked with logs/screenshots evidence and docs are synchronized.
