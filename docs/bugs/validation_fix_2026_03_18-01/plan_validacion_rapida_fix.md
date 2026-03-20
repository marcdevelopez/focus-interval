# Plan — Rapid Validation (BUG-F25-D)

Date: 2026-03-18
Branch: `fix-f25-d-overlap-build-phase`
Commit: `07ac0cb` (FAIL) → `f5b1d2c` (FAIL) → `73d0f23` + `79c534d` (PASS)
Bugs: BUG-F25-D
Devices: iOS iPhone 17 Pro (`9A6B6687`) + Chrome

---

## Objetivo

Confirmar que el mirror no muestra pantalla roja de error de Flutter cuando el owner
hace Resume de un grupo en pausa y el overlap con el siguiente grupo scheduled se ha
activado durante la pausa.

---

## Síntoma original (sin fix)

El usuario ve en el **mirror** una pantalla roja de error de Flutter durante < 1s
cuando el owner reanuda (Resume) tras una pausa suficientemente larga como para que
el grupo running proyecte solaparse con el siguiente grupo scheduled. La app se
recupera sola pero parece un crash visible.

---

## Root cause

`ScheduledGroupCoordinator._updateRunningOverlapDecision` llama a
`runningOverlapDecisionProvider.notifier.state = RunningOverlapDecision(...)` de forma
síncrona. El mirror tiene el timer ticking (frames continuos cada ~16ms). Cuando el
snapshot de Firestore llega durante el Resume mientras Flutter está en build phase,
Riverpod lanza un error de mutación de estado durante build → pantalla roja.

El fix introduce `_runRunningOverlapMutation()`: comprueba `SchedulerBinding.instance.schedulerPhase`
y difiere la mutación con `addPostFrameCallback` cuando el scheduler está en fase de build.
Guards de stale-key y dispose evitan escrituras obsoletas en el callback diferido.

---

## Cómo funciona la detección de overlap durante pausa

`resolveProjectedRunningEnd` durante pausa:
```
projectedEnd = baseEnd + (now - pausedAt)
```
`baseEnd` = `actualStartTime + totalGroupDuration` (fijo, no cambia con la pausa).
Mientras el grupo está pausado, `projectedEnd` crece a medida que pasa el tiempo.

El coordinator programa `_scheduleRunningOverlapRecheck` cuando no hay overlap todavía
pero la sesión está pausada: un timer que dispara `overlapThreshold - projectedEnd`
segundos después, exactamente cuando la pausa acumulada cruza el umbral.

Umbral de overlap: `scheduledStart - noticeMinutes + 1 min (grace)`.

**Nota sobre `noticeMinutes = 0`:** con notice=0, `threshold = scheduledStart + 1 min`.
Esto significa que el alert salta cuando `projectedEnd` ya supera el start de G2 en
1 minuto — el running group proyecta terminar dentro del slot del scheduled. El aviso
llega "tarde" en términos de solapamiento real. Con `noticeMinutes > 0` el threshold
se adelanta (`scheduledStart − noticeMinutes + 1 min`) y el aviso llega antes del
start de G2, que es el comportamiento útil para el usuario.

---

## Condición de overlap (setup de la validación real)

Valores reales usados en la validación del 2026-03-18:

| Variable | Valor |
|---|---|
| G1 `actualStartTime` | 20:45:31 |
| G1 `theoreticalEndTime` (`baseEnd`) | 21:00:31 (= 20:45:31 + 15 min) |
| G2 `scheduledStartTime` | 21:01:00 |
| Gap G1 end → G2 start | **29 segundos** |
| G2 `noticeMinutes` | 0 → `preRunStart = 21:01:00` |
| Threshold | 21:01:00 + 1 min grace = **21:02:00** |
| Pausa necesaria para overlap | 21:02:00 − 21:00:31 = **1 min 29 s** |
| Alert disparó a las | 20:51:34 (pause = 1m30s desde 20:50:04) ✓ |
| `projectedEnd` cuando alert disparó | 21:02:00 = G2 start + 1 min (aviso tardío para notice=0) |

Para el **Escenario B** (notice=5): `threshold = 21:01:00 − 5 min + 1 min = 20:57:00`.
Pausa necesaria: 20:57:00 − 21:00:31 < 0 → el overlap ya es activo SIN pausa
(incluso con G1 running sin pausar). Alert debería saltar inmediatamente al evaluar.

---

## Protocolo de validación

### Preparación (ambos dispositivos)

1. Abrir la app en ambos dispositivos — modo Account, mismo usuario.
2. **Owner**: crear Group B (scheduled) con `scheduledStartTime = ahora + 26 min`.
   Al menos 1 tarea. Confirmar sin pre-aviso (noticeMinutes = 0).
3. **Owner**: crear Group A con duración 25 min. Iniciar (Start now).
   → Group A `baseEnd = ahora + 25 min`, Group B empieza en `ahora + 26 min`.
   → Threshold = `ahora + 27 min`. Sin overlap todavía.
4. **Mirror**: navegar a la pantalla Timer y mantenerla en primer plano activo.

> Nota: crear Group B primero, luego Group A, para que Group A sea el running y
> Group B quede en estado scheduled.

### Escenario A — Sin pre-aviso (noticeMinutes = 0)

5. **Owner**: pausa Group A en cualquier momento.
6. Esperar **> 2 min** de pausa acumulada.
   → `projectedEnd = baseEnd + pause_time > threshold` → overlap activado.
   → El coordinator dispara el recheck timer; el modal de overlap debe aparecer en mirror.
7. **Owner**: presionar **Resume**.
8. **Mirror**: observar pantalla en el momento del Resume.

**Esperado (con fix):**
- ✅ El modal/overlay de running overlap apareció durante la pausa (Paso 6).
- ✅ No aparece pantalla roja al Resume.
- ✅ Timer del mirror reanuda normalmente.

**Referencia sin fix:**
- ❌ Pantalla roja de Flutter < 1s en el mirror al Resume.

### Escenario B — Con pre-aviso (noticeMinutes > 0)

Repetir el setup con Group B configurado con `noticeMinutes = 5`.

Calcular el tiempo de pausa necesario:
- `preRunStart = scheduledStart - 5 min = T + 1 min - 5 min = T - 4 min`
- `threshold = preRunStart + 1 min = T - 3 min`
- Pausa necesaria: > 0 min (el overlap puede activarse SIN pausa, o muy rápido).

9. Ejecutar igual: pausa → esperar → resume → verificar mirror.

**Esperado:**
- ✅ El overlap se activa antes (o sin pausa si el grupo ya está cerca de su fin).
- ✅ No pantalla roja al Resume.

### Escenario C — Smoke BUG-F25-C

- Con el overlap modal activo en el mirror, owner presiona Continue.
- Owner **NO debe ver** el modal "Owner resolved" (solo el mirror lo recibe).

---

## Comandos de ejecución

```bash
LOG_DIR="docs/bugs/validation_fix_2026_03_18-01/logs"

# iOS iPhone 17 Pro — debug (prod Firebase)
flutter run -v --debug -d 9A6B6687-8DE2-4573-A939-E4FFD0190E1A \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-18_f25d_f5b1d2c_ios_iPhone17Pro_9A6B6687_debug.log"

# Chrome — debug (prod Firebase)
flutter run -v --debug -d chrome \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-18_f25d_f5b1d2c_chrome_debug.log"
```

---

## Log analysis — quick scan

```bash
LOG_IOS="docs/bugs/validation_fix_2026_03_18-01/logs/2026-03-18_f25d_f5b1d2c_ios_iPhone17Pro_9A6B6687_debug.log"
LOG_CHROME="docs/bugs/validation_fix_2026_03_18-01/logs/2026-03-18_f25d_f5b1d2c_chrome_debug.log"

# Señal de bug presente (antes del fix): error de build-phase mutation
grep -E "setState.*build|markNeedsBuild.*build|FlutterError|Assertion failed.*phase" \
  "$LOG_IOS" "$LOG_CHROME"

# Flujo del coordinator (overlap detection y recheck timer)
grep -E "\[ScheduledGroups\]|runningOverlap|overlapDecision|runningOverlap=true|recheck" \
  "$LOG_IOS" "$LOG_CHROME"

# Señales de crash o excepción no esperada
grep -E "Unhandled Exception|Exception caught by|Error caught" \
  "$LOG_IOS" "$LOG_CHROME"
```

> **La validación es por ausencia:** si no aparece ningún `setState() called during build`
> ni pantalla roja en ninguno de los ciclos Pause→espera→Resume → fix confirmado.

---

## Verificación local (pre-device)

- `flutter analyze` → PASS
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "running overlap decision"` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → PASS
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` → PASS
- `flutter test` (full suite) → FAIL (fallos pre-existentes en `scheduled_group_coordinator_test.dart`, NO introducidos por este patch)

---

## Criterios de cierre

- Escenarios A, B, C PASS en ambos dispositivos con evidencia.
- Actualizar `quick_pass_checklist.md` con resultado y logs.
- Actualizar `validation_ledger.md` con `closed_commit_hash: 07ac0cb` y evidencia.
- Merge `fix-f25-d-overlap-build-phase` → `develop` tras cierre.

---

## Resultado validación — 2026-03-18 (iOS + Chrome)

**Status: FAIL — fix `07ac0cb` insuficiente.**

### Observaciones

**Setup confirmado:**
- G1: `actualStartTime=20:45:31`, `theoreticalEndTime=21:00:31`, `noticeMinutes=5` (del running group, irrelevante para el overlap)
- G2: `scheduledStartTime=21:01:00`, `noticeMinutes=0`
- G1 pausado a las 20:50:04 (`pausedAt=20:50:04`)
- `threshold = 21:01:00 + 1 min grace = 21:02:00`
- Pausa necesaria: `21:00:31 + pause > 21:02:00` → pause > 1m29s ✓

**Error ocurrió DOS veces:**

1. **20:51:34** — Recheck timer disparó (pause ≈ 1m30s). Mirror: pantalla roja < 1s.
   "Tried to modify a provider while the widget tree was building" — `RunningOverlapDecision`.
   Tras desaparecer: mirror mostró "Owner is resolving this conflict" correctamente.

2. **20:51:48** — Owner pulsó Postpone → Firestore update → mirror: pantalla roja < 1s otra vez.
   Mismo error, misma causa: `_clearRunningOverlapDecisionIfNeeded` o nuevo `_setRunningOverlapDecision`
   durante propagación Riverpod.

**20:52:41 — Resume:** sin error. ✓
**Real-time update de G2 en mirror:** funcionó (Scheduled: 21:03 visible en mirror). ✓
**Modal "Scheduling conflict" en owner (Chrome):** apareció correctamente. ✓

### Por qué falla el fix `07ac0cb`

`_runRunningOverlapMutation` comprueba `SchedulerBinding.instance.schedulerPhase`.
Cuando el timer/update llega con fase `idle` → corre **inmediatamente** → pero Riverpod
puede estar propagando un cambio de estado propio (stream de Firestore u otro provider).
La check interna de Riverpod (`_debugCurrentBuildingElement`) no está ligada a la fase
del scheduler de Flutter sino al estado interno de Riverpod. El phase check es insuficiente.

El propio mensaje de error de Riverpod indica la solución correcta:
*"Delay your modification by encapsulating it in a `Future(() {...})`"*

### Fix correcto requerido

Reemplazar el body de `_runRunningOverlapMutation` por `Future(() => mutation())`:
- Siempre difiere al siguiente turno del event loop.
- Garantiza que cualquier propagación Riverpod activa haya completado.
- Requiere actualizar tests: los que dependían del try/catch para ejecución inmediata
  necesitan `await Future.delayed(Duration.zero)` o equivalente después de llamar al coordinator.

## Resultado final — 2026-03-18 (iOS owner + Chrome mirror)

**Status: PASS — Closed/OK. closed_commit_hash: `79c534d`**

El bug tenía DOS fuentes independientes:
1. **Coordinator** (`_runRunningOverlapMutation`): `SchedulerBinding.schedulerPhase` insuficiente → fix con `Future(() {})` (macrotask, fuera de cualquier propagación Riverpod) — commit `73d0f23`.
2. **Widget** (`GroupsHubScreen.build():283`, `TaskListScreen.build():561`): mutación directa de `runningOverlapDecisionProvider` dentro de `build()` — fix con `WidgetsBinding.instance.addPostFrameCallback` + `mounted` guard + token guard — commit `79c534d`.

Validación device: iOS (owner) + Chrome (mirror). Overlap modal apareció correctamente. Ningún red screen en mirror en detección de conflicto ni tras acción Postpone del owner.

## Status

**PASS — Closed/OK.** closed_commit_hash: `79c534d`
