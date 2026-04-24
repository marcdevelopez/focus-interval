## Exact repro

- [x] Scenario A PASS on Android owner: Start now from Plan Group lands directly in /timer/:groupId and stays there.
- [x] Scenario B PASS on macOS mirror: Syncing hold shown without inert Start; hydrates automatically on snapshot.

## Regression smoke

- [x] Scenario C PASS: canceled displayed group still navigates to Groups Hub.
- [x] Scenario D PASS: stale canceled mismatched group does not force Groups Hub navigation.
- [x] No route churn (/timer -> /tasks or /groups) after owner Start now.

## Local gate

- [x] flutter analyze PASS.
- [x] flutter test test/presentation/timer_screen_completion_navigation_test.dart PASS.
- [x] flutter test test/presentation/timer_screen_syncing_overlay_test.dart PASS.
- [x] Focused stale-cancel test no longer hangs.

## Closure rule

Close only when all boxes above are checked with logs/screenshots evidence and docs synchronized.
