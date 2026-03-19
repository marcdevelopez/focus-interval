# Quick Pass Checklist — BUG-F25-I

## Exact repro
- [ ] Escenario A PASS: postpone + cancel anchor mantiene hora postponed original en iOS.
- [ ] Escenario A PASS: postpone + cancel anchor mantiene hora postponed original en Chrome.
- [ ] No transición `sample ...22:35 -> ...22:22` tras cancel del anchor.
- [ ] No `start-timer-fired` prematuro antes de la hora postponed.

## Regression smoke
- [ ] Escenario B PASS: drift por pausa/reanudar funciona mientras anchor sigue running.
- [ ] Escenario C PASS: cancel simple sin linkage postponed no altera `scheduledStart` de otros grupos.
- [ ] Sin regresiones de navegación/sync en owner+mirror.

## Local gate
- [ ] `flutter analyze` PASS.
- [ ] `flutter test test/presentation/utils/scheduled_group_timing_test.dart` PASS.
- [ ] `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` PASS.
- [ ] `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` PASS.

## Closure rule
- [ ] Cerrar solo con Exact repro + Regression smoke + Local gate en PASS, con evidencia en logs/screenshots y actualización de `bug_log.md` + `validation_ledger.md` a Closed/OK.
