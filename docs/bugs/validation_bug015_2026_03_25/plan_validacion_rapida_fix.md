# Plan de validación rápida — BUG-015

**Fecha:** 25/03/2026
**Rama:** `fix/buglog-running-without-foreground-ready-invalid`
**Commit base:** `f929117`
**Bugs cubiertos:** BUG-015
**Dispositivos:** Android (RMX3771) + macOS

---

## Objetivo

Verificar que un grupo en ejecución (`running`) nunca muestra pantalla "Ready" con
anillo ámbar dorado ni escribe `finished` en Firestore `current` cuando el grupo aún
tiene tiempo restante, independientemente de si ningún device tiene la app en foreground.

---

## Síntoma original

Al reanudar la app en Android tras haber sido el único device con la app abierta
(macOS apagado) y haber ido a background:
- Pantalla de timer muestra "Ready" + anillo ámbar + botón Start.
- Firestore `current` tiene `status: "finished"`.
- Abrir macOS "repara" el estado (republica sesión activa).

---

## Root cause

**Vector primario validado (stream/mirror path):**
`SessionSyncService -> _onSyncStateChanged -> _ingestResolvedSession` ingería el
snapshot remoto crudo sin reparar cursor inconsistente. Con snapshots tipo
`currentTaskIndex=0` + `currentPomodoro=2/1`, la proyección podía caer a estado
terminal visual (`Ready 00:00`) aunque el grupo siguiera en `running`.

**Fix aplicado (principal):**
reparación síncrona previa a ingest en stream path:
`_repairStreamSessionForCurrentGroup(session)` con guards por grupo/estado y uso de
`_repairInconsistentSessionCursor(...)` (sin IO ni side effects async).

**Guardrails complementarios ya incluidos en el patch BUG-015:**
- recovery en owner-hydration para overshoot de tarea;
- bloqueo de publish `finished` transitorio cuando el grupo no está completado.

---

## Protocolo de validación

### Escenario A — Único device, foreground perdido, reanudación

**Precondiciones:**
- Grupo activo con ≥2 tareas (e.g., tasks con 25min pomodoros).
- Android como único device con la app.
- Android era owner (macOS apagado o cerrado completamente).

**Pasos:**
1. Verificar que el timer corre correctamente en Android.
2. Poner Android en background (home button). Esperar ≥5 min (suficiente para que
   pase al menos una fase/tarea si el timer lo permite).
3. Volver a foreground en Android.
4. **Expected:** Timer retoma en la posición correcta según timeline del grupo.
   NO aparece "Ready" + anillo ámbar. NO hay `finished` en Firestore `current`.

**Resultado sin fix:** App abre en "Ready" + ámbar; Firestore `current.status = finished`.
**Resultado con fix:** Timer continúa en posición correcta; Firestore `current.status = pomodoroRunning`.

---

### Escenario B — Owner apagado, mirror toma ownership, background, reanudación

**Precondiciones:**
- Android en mirror, macOS como owner.
- Grupo con ≥2 tareas con pomodoros largos (≥10min) para dar tiempo al escenario.

**Pasos:**
1. macOS corriendo como owner.
2. Apagar macOS (o cerrar app por completo).
3. Esperar 45s+ para que Android auto-tome ownership.
4. Confirmar en Android que ownership fue tomado (logs: `[AutoTakeover]`).
5. Poner Android en background. Esperar ≥5 min.
6. Volver a foreground en Android.
7. **Expected:** Timer en posición correcta; NO pantalla "Ready"; NO `finished` en Firestore.

**Resultado sin fix:** "Ready" + ámbar (bug original reportado).
**Resultado con fix:** Timer correcto; Firestore `current.status = pomodoroRunning`.

---

### Escenario C — Regression: último task del grupo se completa correctamente

**Precondiciones:**
- Grupo con 1 tarea de 1 pomodoro (pomodoro corto, e.g., 1 min en test o normal).

**Pasos:**
1. Iniciar grupo en Android.
2. Esperar a que el pomodoro complete (el último).
3. **Expected:** Grupo va a pantalla de completado (Groups Hub); Firestore `current.status = finished`;
   grupo `status = completed`. Este comportamiento NO debe romperse.

---

## Comandos de ejecución

```bash
# Android RMX3771
flutter run -v --debug -d RMX3771 \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug015_2026_03_25/logs/2026-03-25_bug015_f929117_android_RMX3771_debug_2.log

# macOS
flutter run -v --debug -d macos \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug015_2026_03_25/logs/2026-03-25_bug015_f929117_macos_debug.log
```

---

## Log analysis — quick scan

### Señales de bug presente (sin fix):
```bash
grep -n "PomodoroStatus.finished\|status=finished\|Ready\|amber" <logfile>
grep -n "\[ActiveSession\]\[snapshot\].*status=finished" <logfile>
```

### Señales de fix funcionando:
```bash
# Stream cursor repair (cuando llega snapshot inconsistente):
grep -n "Repaired stream snapshot before ingest" <logfile>

# Reanudación válida sin fallback terminal:
grep -n "Auto-open confirmed in timer" <logfile>
grep -n "\[ActiveSession\]\[snapshot\].*status=pomodoroRunning.*remaining=[1-9]" <logfile>
```

---

## Verificación local

- [x] `flutter analyze` — PASS (25/03/2026)
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` — PASS (25/03/2026)
- [x] `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` — PASS (25/03/2026)
- [x] `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` — PASS (25/03/2026)
- [x] `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` — PASS (25/03/2026)

---

## Criterios de cierre

1. Escenario A PASS: Android reanuda desde background → timer correcto, NO "Ready" ámbar.
2. Escenario B PASS: auto-takeover + background → reanudación sin "Ready" ámbar.
3. Escenario C PASS (regression): último task completa correctamente → Groups Hub.
4. `flutter analyze` PASS.
5. Todos los tests PASS.

---

## Status

Closed/OK (25/03/2026).

Evidence summary:
- Device validation PASS:
  `docs/bugs/validation_bug015_2026_03_25/logs/2026-03-25_bug015_f929117_android_RMX3771_debug_2.log`
- Resume window around 21:15 confirms valid running continuity:
  `Auto-open confirmed in timer` + snapshots with
  `status=pomodoroRunning` and remaining `460 -> 429 -> 399` (no amber `Ready 00:00` fallback).
