## Exact repro

- [ ] Scenario A PASS on Android owner (paused Ends keeps projecting while paused).
- [ ] Scenario B PASS on macOS mirror (paused Ends stays coherent with scheduled cards).
- [ ] Scenario C PASS after resume (no timeline regression).

## Regression smoke

- [x] test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Groups Hub paused running card updates Ends projection in real time" PASS.
- [x] test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Groups Hub core sections and actions are visible" PASS.

## Local gate

- [x] flutter analyze PASS.

## Closure rule

- [ ] Close only when all boxes above are checked with logs/screenshots evidence and docs are synchronized.
