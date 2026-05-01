## Exact repro

- [x] Scenario A PASS on Android owner (paused Ends keeps projecting while paused). Evidence: `2026-04-27_bug028_5df97ec_android_RMX3771_debug.log` + screenshots `scenarioAB_T0_paused_161302`, `scenarioAB_mid_paused_161349`, `scenarioAB_Tplus106_paused_161448`.
- [x] Scenario B PASS on macOS mirror (paused Ends stays coherent with scheduled cards). Evidence: `2026-04-27_bug028_5df97ec_macos_debug.log` + same screenshot series.
- [x] Scenario C PASS after resume (no timeline regression). Evidence: screenshot `scenarioC_post_resume_161459`.

## Regression smoke

- [x] test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Groups Hub paused running card updates Ends projection in real time" PASS.
- [x] test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Groups Hub core sections and actions are visible" PASS.

## Local gate

- [x] flutter analyze PASS.

## Closure rule

- [x] Close only when all boxes above are checked with logs/screenshots evidence and docs are synchronized.
