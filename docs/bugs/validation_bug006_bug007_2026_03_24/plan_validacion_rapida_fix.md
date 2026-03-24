# Plan de validación rápida — BUG-006 + BUG-007

**Fecha:** 24/03/2026
**Rama:** `fix/buglog-006-007-validation`
**Commit base:** `97f6365`
**Bugs cubiertos:** BUG-006, BUG-007
**Dispositivos:** Android RMX3771 (owner), macOS (mirror — requerido para BUG-007)

---

## Objetivo

Confirmar que dos bugs con fixes ya en `develop` están efectivamente resueltos:

- **BUG-006:** Status box Current/Next muestra rangos HH:mm–HH:mm incorrectos tras
  pause/resume (no aplica pause-offset; reescribe el start de fase retroactivamente).
- **BUG-007:** Owner Android reanuda ~5s por detrás del mirror macOS tras
  crash/background prolongado; el timer no re-ancla desde el snapshot remoto al volver.

Ambos bugs se validan en **un único run combinado** de Android + macOS.

---

## Síntoma original

### BUG-006
En Run Mode, las cajas de estado (Current / Next) muestran rangos de tiempo que
no siguen el mismo comportamiento de anchoring que la lista de tareas contextual:
el start de la fase actual aparece desplazado retroactivamente en lugar de mantenerse
fijo, y el end no extiende por la duración de la pausa.

**Lo que ve el usuario:** Pausa durante un Pomodoro → reanuda → las cajas Current/Next
muestran rangos inconsistentes con la lista de tareas (start se mueve, end no cuadra).

### BUG-007
Tras cerrar la app en Android (o background prolongado con crash del sistema), al
volver el owner Android muestra ~5s menos de remaining que el mirror macOS.

**Lo que ve el usuario:** Al volver de background Android, el timer está visiblemente
por detrás del mirror macOS hasta que el usuario navega a Groups Hub o fuerza un
refocus.

---

## Root cause

### BUG-006
Las cajas de estado usaban `phaseStartedAt` sin ajustar por los segundos de pausa
acumulados **desde** el inicio de la fase actual (solo se descontaba el total de pausa
del grupo, no la fracción atribuible a esta fase concreta).

**Fix aplicado (commit `34d1938`, 25/02/2026):**
`currentPhaseStartFromGroup` / `currentPhaseEndFromGroup` en
`lib/presentation/viewmodels/pomodoro_view_model.dart` (líneas 2346–2365) ahora
calculan `_pauseSecondsSincePhaseStart` atribuyendo correctamente solo la pausa
posterior al inicio estimado de la fase actual (`_expectedPhaseStart`).
`timer_screen.dart` líneas 2689–2690 usa estos getters para las cajas Current/Next.

### BUG-007
En Account Mode, al volver del background Android reutilizaba el anchor de fase local
sin re-anclar desde el snapshot remoto, dejando el countdown adelantado en macOS.

**Fix aplicado (`handleAppResumed`, línea 2871):**
En Account Mode, `handleAppResumed()` llama:
- `_subscribeToRemoteSession(reason: 'resume-rebind')` — refresca el listener
- `syncWithRemoteSession(preferServer: true, reason: 'resume')` — re-ancla desde servidor
- `_schedulePostResumeResync()` — segunda sincronización 2s después

---

## Protocolo de validación

### Escenario A — BUG-006: pause/resume status box anchoring (Android solo)

**Precondiciones:**
- Android en Account Mode, grupo con al menos 1 Pomodoro.
- Pomodoro activo mostrando caja Current con rango HH:mm–HH:mm visible.

**Pasos:**
1. Inicia un grupo en Android owner (Start now, sin grupo planificado — más rápido).
2. Espera a que el Pomodoro esté corriendo y la caja **Current** muestre un rango
   `HH:mm–HH:mm`. Anota el start y end mostrados.
3. Pulsa **Pause**. Espera **60 segundos** (1 minuto exacto).
4. Pulsa **Resume**.
5. Observa la caja **Current** inmediatamente tras resume.

**Resultado esperado (PASS):**
- Start de la caja Current = mismo que antes de la pausa (no retrocede).
- End de la caja Current = end original + ~60s (se extiende por la pausa).
- La caja Next muestra rangos que arrancan después del nuevo end de Current.
- El rango de la lista de tareas (parte inferior) coincide con la caja Current.

**Resultado sin fix (FAIL):**
- Start de la caja Current cambia retroactivamente (se adelanta o retrocede).
- End no se extiende por la duración de la pausa.
- Las cajas y la lista de tareas no coinciden.

---

### Escenario B — BUG-007: resume re-anchor tras background (Android owner + macOS mirror)

**Precondiciones:**
- Android en Account Mode como owner, macOS como mirror, grupo running activo.
- Ambos mostrando el mismo countdown en Run Mode.

**Pasos:**
1. Ambos dispositivos en Run Mode con el mismo grupo activo.
2. Confirma que Android y macOS muestran el mismo (o muy próximo) remaining time.
3. En Android: background forzado durante **90–120 segundos**
   (puedes enviar un audio de WhatsApp o ir al launcher — lo que cause el
   "app has stopped working" / ANR es ideal, pero un simple background también vale).
4. Vuelve a la app en Android.
5. Compara inmediatamente el remaining time de Android con el de macOS.

**Resultado esperado (PASS):**
- Tras volver del background, Android muestra el mismo remaining (±2s) que macOS.
- No se necesita navegar a Groups Hub para sincronizar.
- En el log: `[ActiveSession] Resync start (resume).` aparece al volver.

**Resultado sin fix (FAIL):**
- Android muestra ~5s más remaining que macOS al volver.
- La diferencia solo se corrige al entrar a Groups Hub o hacer focus/refocus en macOS.

---

## Comandos de ejecución

### Android (debug, prod env)
```bash
cd /Users/devcodex/development/focus_interval
flutter run -v --debug -d RMX3771 \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug006_bug007_2026_03_24/logs/2026-03-24_bug006_bug007_97f6365_android_RMX3771_debug.log
```

### macOS (debug, prod env) — requerido para Escenario B
```bash
cd /Users/devcodex/development/focus_interval
flutter run -v --debug -d macos \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug006_bug007_2026_03_24/logs/2026-03-24_bug006_bug007_97f6365_macos_debug.log
```

---

## Log analysis — quick scan

### Señales de BUG-007 funcionando (PASS)

```bash
# Debe aparecer al volver del background en Android
rg -n "Resync start \(resume\)|Resync start \(post-resume\)|resume-rebind" \
  docs/bugs/validation_bug006_bug007_2026_03_24/logs/2026-03-24_bug006_bug007_97f6365_android_RMX3771_debug.log
```

Patrón esperado:
```
[ActiveSession] Resync start (resume).
[SessionSub] close vmToken=... reason=resume-rebind
[ActiveSession] Resync start (post-resume).
```

### Señales de BUG-007 roto (FAIL)

```bash
# Indicaría que no encontró sesión tras resume (no re-anclado)
rg -n "Resync missing; no session snapshot" \
  docs/bugs/validation_bug006_bug007_2026_03_24/logs/2026-03-24_bug006_bug007_97f6365_android_RMX3771_debug.log
```

### BUG-006 — validación visual

No tiene tag de log específico (es un getter de UI puro). La validación es
enteramente visual: comparar start/end de caja Current antes y después de pause/resume.
Los logs pueden confirmar la pausa/resume con `pause` / `resume` en el output del
ViewModel, pero el criterio de PASS es la pantalla.

---

## Verificación local

```bash
flutter analyze
# Expected: No issues found!

flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart
# Covers resume catch-up logic (RVP-067 — Closed/OK)

flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart
flutter test test/presentation/timer_screen_syncing_overlay_test.dart
```

---

## Criterios de cierre

### BUG-006 cerrado cuando:
- [ ] Escenario A PASS: caja Current mantiene start original + extiende end por pausa.
- [ ] Cajas y lista de tareas coinciden tras resume.

### BUG-007 cerrado cuando:
- [ ] Escenario B PASS: tras background 90s+ Android, timer aligns con macOS (±2s)
  sin navegar a Groups Hub.
- [ ] Log Android muestra `[ActiveSession] Resync start (resume).`

### Regla de cierre
Cerrar ambos bugs solo si los dos escenarios tienen PASS con evidencia de log
(para BUG-007) + observación visual (para BUG-006).

---

## Status

Open — pendiente de ejecución de device run.
