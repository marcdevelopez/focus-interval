## Exact repro
- [x] Escenario A PASS: único device, background ≥5min, reanudar → NO "Ready" ámbar, timer correcto.
- [x] Escenario B PASS: owner apagado, auto-takeover, background, reanudar → NO "Ready" ámbar.

## Regression smoke
- [x] Escenario C PASS: último task del grupo se completa → Groups Hub (finished es correcto).
- [x] flutter test pomodoro_view_model_session_gap_test.dart PASS.
- [x] flutter test pomodoro_view_model_pause_expiry_test.dart PASS.
- [x] flutter test timer_screen_syncing_overlay_test.dart PASS.
- [x] flutter test scheduled_group_coordinator_test.dart PASS.

## Local gate
- [x] flutter analyze PASS.

## Closure rule
Close only when all boxes above are checked with evidence.
