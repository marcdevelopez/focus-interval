# Quick pass checklist — BUG-006 + BUG-007

## BUG-006 — Status box pause anchoring

- [x] Escenario A PASS: tras pause 60s + resume, caja Current mantiene start original (11:01 → 11:01).
- [x] Escenario A PASS: end de caja Current se extiende ~60s respecto al end pre-pausa (11:16 → 11:17).
- [x] Cajas Current/Next y lista de tareas muestran rangos coherentes tras resume (ambas 11:01–11:17).

## BUG-007 — Owner resume re-anchor

- [x] Escenario B PASS: Android muestra mismo remaining que macOS (±2s) tras background 90s+ (6:21 vs 6:20 → ±1s).
- [x] Sin navegar a Groups Hub para sincronizar.
- [x] Log Android contiene `[ActiveSession] Resync start (resume).` (línea 10402).

## Local gate

- [x] `flutter analyze` PASS (`No issues found!`)
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS (`+5`)

## Closure rule

Todos los boxes marcados con evidencia — ambos bugs CERRADOS.
