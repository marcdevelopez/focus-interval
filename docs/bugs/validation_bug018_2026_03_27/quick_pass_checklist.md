## Exact repro
- [x] Escenario A PASS: owner Android en background largo (~22 min) y retorno a foreground sin `Ready` inválido.
- [x] Firestore `current` mantiene sesión coherente (`pomodoroRunning` en G2 con `remaining` monotónico tras resume).

## Regression smoke
- [x] Escenario B PASS: transición `pomodoro -> shortBreak -> pomodoro` sin bucles de transición.
- [x] Sin patrón `running + remaining=0` en el log validado.
- [x] Reconciliación de resume aparece una sola vez (`reason=resume`).

## Local gate
- [x] `flutter analyze` PASS (27/03/2026).
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` PASS (27/03/2026).

## Closure rule
Cerrar solo cuando todas las casillas estén en PASS con evidencia en log.

