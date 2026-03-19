# Quick Pass Checklist — BUG-F25-H

## Exact repro

- [x] Escenario A PASS: G1→cancel→G2→cancel → Chrome navega a Groups Hub en ≤5s.
- [x] Escenario A PASS: G1→cancel→G2→cancel → iOS navega a Groups Hub en ≤5s.
- [x] Escenario A: ausencia de `hold-extend reason=recovery-failed` loop en Chrome log.
- [x] Escenario A: ausencia de `hold-extend reason=recovery-failed` loop en iOS log.

## Regression smoke

- [x] Escenario B PASS: cancelación simple de G1 (sin re-plan) → ambos dispositivos navegan a Groups Hub correctamente.
- [x] Escenario C PASS (o N/A): corte de red breve no produce hold permanente.
- [x] Sin excepción Flutter "setState/markNeedsBuild called during build" en timer_screen.dart en ningún log.

## Local gate

- [x] `flutter analyze` PASS.
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` PASS.
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS.
- [x] `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` PASS.

## Closure rule

Close only when all boxes above are checked with log evidence.
