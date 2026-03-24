# Quick pass checklist — BUG-005

## Escenario A — macOS owner sin foco

- [ ] Modal de ownership request aparece en macOS en ≤15s sin clickar la ventana.
- [ ] Log macOS contiene `[ActiveSession] Resync start (inactive-resync).` durante ventana sin foco.

## Escenario B — Android owner en foreground

- [ ] Banner/modal de ownership request aparece en Android en <5s.
- [ ] Sin navegar a Groups Hub ni hacer background.
- [ ] Log Android contiene `[RunModeDiag] Active session change` coincidiendo con la aparición del modal.

## Local gate

- [ ] `flutter analyze` PASS (`No issues found!`)
- [ ] `flutter test pomodoro_view_model_session_gap_test.dart` PASS

## Closure rule

Cerrar solo cuando todos los boxes estén marcados con evidencia.
