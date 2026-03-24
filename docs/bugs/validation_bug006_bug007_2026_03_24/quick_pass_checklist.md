# Quick pass checklist — BUG-006 + BUG-007

## BUG-006 — Status box pause anchoring

- [ ] Escenario A PASS: tras pause 60s + resume, caja Current mantiene start original.
- [ ] Escenario A PASS: end de caja Current se extiende ~60s respecto al end pre-pausa.
- [ ] Cajas Current/Next y lista de tareas muestran rangos coherentes tras resume.

## BUG-007 — Owner resume re-anchor

- [ ] Escenario B PASS: Android muestra mismo remaining que macOS (±2s) tras background 90s+.
- [ ] Sin navegar a Groups Hub para sincronizar.
- [ ] Log Android contiene `[ActiveSession] Resync start (resume).`

## Local gate

- [ ] `flutter analyze` PASS (`No issues found!`)
- [ ] `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS

## Closure rule

Cerrar solo cuando todos los boxes anteriores estén marcados con evidencia.
