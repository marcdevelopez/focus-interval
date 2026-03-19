# Quick Pass Checklist — BUG-F25-I

## Exact repro
- [x] Escenario A PASS: postpone + cancel anchor mantiene hora postponed original en iOS.
- [x] Escenario A PASS: postpone + cancel anchor mantiene hora postponed original en Chrome.
- [x] No transición prematura de hora tras cancel del anchor (G2 mantiene 23:29).
- [x] No auto-start prematuro antes de la hora postponed.

## Regression smoke
- [x] Escenario C PASS: cancel simple sin linkage postponed no altera comportamiento de otros grupos.
- [x] Sin regresiones de navegación/sync en owner+mirror (ambos dispositivos muestran estado correcto).

## Local gate
- [x] `flutter analyze` PASS.
- [x] `flutter test test/presentation/utils/scheduled_group_timing_test.dart` PASS (incluyendo 2 tests nuevos de F25-I).
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` PASS.
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS.
- [x] `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` PASS.

## Closure rule
Close only when all boxes above are checked with evidence.
