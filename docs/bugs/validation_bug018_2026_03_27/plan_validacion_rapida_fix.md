# Plan de validación rápida — BUG-018

**Fecha:** 27/03/2026
**Rama:** `fix/bug018-running-zero-resume`
**Commit validado:** `547c6f7`
**Bugs cubiertos:** BUG-018
**Dispositivos:** Android (RMX3771, owner)

---

## Objetivo

Validar que, tras background largo del owner en Account Mode, la sesión no entra
en estado imposible (`running + remainingSeconds=0`) ni muestra `Ready` inválido,
y que la reanudación reconcilia timeline en segundos con transición correcta de fase.

---

## Síntoma original

En el bug original, al volver de background largo, la sesión podía quedar
~21 minutos en `pomodoroRunning + remaining=0`, y la UI mostraba `Ready 00:00`
inválido aunque el grupo seguía `running` en Firestore.

---

## Root cause

1. `handleAppResumed` en Account Mode no reconciliaba timeline antes de resync remoto.
2. Se podían publicar snapshots imposibles (`running + remaining=0`) sin transición
   real de máquina.
3. En mirrors, snapshots imposibles podían proyectarse a estado terminal visual.
4. Un fix intermedio introdujo amplificación de publish por interacción entre
   reconciliación en publish normal + hot-swap owner echo.

Fix final validado (`547c6f7`):
- Se elimina reconciliación del publish normal y se mantiene reconciliación explícita
  en resume path.
- Se evita amplificación de publish en owner-echo.
- Se mantienen guardas para estado imposible.

---

## Protocolo de validación

### Escenario A — Background largo owner Android

**Precondiciones:**
- Grupo en ejecución con múltiples tareas (G1/G2/G3).
- Android como owner activo.

**Pasos:**
1. Iniciar grupo y confirmar `pomodoroRunning`.
2. Poner app Android en background a las 19:37:55.
3. Mantener background hasta las 20:00.
4. Volver a foreground.

**Expected con fix:**
- Reanudación en segundos con fase/tarea coherente por timeline.
- Sin estado `running + remaining=0`.
- Sin `Ready` inválido.

**Reference sin fix:**
- Freeze prolongado en `running + remaining=0` y `Ready` inválido durante ~21 min.

---

### Escenario B — Integridad de transiciones (pomodoro ↔ break)

**Precondiciones:**
- Misma ejecución del escenario A.

**Pasos:**
1. Revisar log desde `19:50` a `20:02`.
2. Verificar transición de `pomodoro` a `shortBreak` y luego a siguiente `pomodoro`.
3. Verificar que no hay ráfagas de transiciones repetidas.

**Expected con fix:**
- Una sola transición válida por frontera de fase.
- Cadencia de snapshots estable.

**Reference sin fix:**
- Sonidos/transiciones repetidas y `sessionRevision` subiendo de forma anómala.

---

## Comandos de ejecución

```bash
flutter run -v --debug -d 192.168.1.25:5555 \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug018_2026_03_27/logs/2026-03-27_bug018_547c6f7_android_RMX3771_debug.log
```

---

## Log analysis — quick scan

### Señales de bug presente

```bash
rg -n "status=pomodoroRunning.*remaining=0|status=shortBreakRunning.*remaining=0|running status with remaining=0" \
  docs/bugs/validation_bug018_2026_03_27/logs/2026-03-27_bug018_547c6f7_android_RMX3771_debug.log

rg -n "Suppressed impossible publish|UnknownHostException|Unable to resolve host firestore.googleapis.com" \
  docs/bugs/validation_bug018_2026_03_27/logs/2026-03-27_bug018_547c6f7_android_RMX3771_debug.log
```

Resultado validación 27/03/2026:
- `running+remaining=0`: 0 coincidencias.
- `UnknownHostException`: 0 coincidencias.

### Señales de fix funcionando

```bash
rg -n "Reconciled owner timeline before publish reason=resume" \
  docs/bugs/validation_bug018_2026_03_27/logs/2026-03-27_bug018_547c6f7_android_RMX3771_debug.log

rg -n "TimeSync] refreshed \\(break-start\\)|TimeSync] refreshed \\(pomodoro-start\\)" \
  docs/bugs/validation_bug018_2026_03_27/logs/2026-03-27_bug018_547c6f7_android_RMX3771_debug.log

rg -n "2026-03-27 19:51:59|2026-03-27 19:56:59|2026-03-27 20:00:55" \
  docs/bugs/validation_bug018_2026_03_27/logs/2026-03-27_bug018_547c6f7_android_RMX3771_debug.log
```

Resultado validación 27/03/2026:
- Reconciliación en resume: 1 vez.
- `break-start`: 1 vez.
- `pomodoro-start`: 2 veces (inicio de grupo + inicio de siguiente pomodoro).
- Snapshots coherentes en ventana de resume (`remaining=663` a las 20:00:55).

---

## Verificación local

- [x] `flutter analyze` — PASS (27/03/2026).
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` — PASS (27/03/2026, 30 tests).

---

## Criterios de cierre

1. Escenario A PASS (background largo → foreground sin `Ready` inválido).
2. Escenario B PASS (transiciones de fase sin bucle/anomalía).
3. No `running + remaining=0` en log validado.
4. `flutter analyze` PASS.
5. Test de regresión de sesión PASS.

---

## Status

Closed/OK (27/03/2026).

