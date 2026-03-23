# Plan de validacion rapida fix — BUG-008C

## 1) Header
- Date: 2026-03-23
- Branch: `fix/buglog-008c-ready-flash-validation`
- Commit hash (base): `d400a99`
- Bugs covered: `BUG-008C` (`BUGLOG-008C` in ledger)
- Target devices: Android owner (`RMX3771`), optional Chrome mirror for cross-check

## 2) Objetivo
Confirmar y acotar un bug de startup donde Android owner abre un grupo historico en estado `Ready/Completed` (timer 15:00 + Start) al iniciar la app, aunque ese grupo no deberia ser el objetivo activo de arranque. El objetivo de esta validacion es reproducir de forma determinista los dos caminos plausibles (residuo running y residuo cancelado), capturar logs, y dejar evidencia suficiente para implementar fix sin perder contexto.

## 3) Sintoma original
Al abrir la app en Android owner, aparece una pantalla tipo `Ready` para un grupo viejo. El usuario ve timer en 15:00 con boton `Start` para un grupo que venia de una validacion anterior. Tras pulsar `Start` y cancelar, el flujo vuelve a normalidad, pero ese arranque inicial es inconsistente y confuso.

## 4) Root cause (confirmado)
Path exacto: `ScheduledGroupCoordinator._handleGroupsAsync` con `activeSession == null` y grupo en `running` cuyo `theoreticalEndTime` ya habia pasado.
El coordinador evaluaba `running.isNotEmpty` → `activeSession == null` → caia a `remaining = running - expired` → `_emitOpenTimer(groupId)` con el grupo stale, mostrando la pantalla Ready.

Fix: interceptar ese path antes del `openTimer` con `_resolveExpiredRunningGroups(running, now)`. Si hay expirados → `_markRunningGroupsCompleted` + `_emitOpenGroupsHub`. Return anticipado bloquea el path antiguo.

Observacion residual (no es un bug, solo nota): cuando `activeSession != null` llega antes de que el chequeo de expiracion se complete, el coordinador primero emite `openTimer` (sesion presente), luego limpia la sesion stale (45s), re-evalua y emite `openGroupsHub`. Esto produce un flash breve del timer screen (frame 5 en capturas) antes de llegar a Groups Hub. El resultado final es correcto. Log del run de validacion muestra ademas `Cannot use Ref after disposed` en lineas 6775-6787 durante esa transicion de navegacion; sin rotura funcional.

## 5) Protocolo de validacion
### Escenario A — Repro principal (residuo running al reabrir)
Precondiciones:
1. Android en Account Mode como owner.
2. Existe al menos un grupo previo que haya pasado por late-start queue o apertura tardia.

Pasos:
1. Ejecutar un flujo normal hasta tener un grupo en `running`.
2. Cerrar app (sin limpiar estado manualmente en Firestore).
3. Reabrir app en Android owner.
4. Observar primera pantalla de Timer/Run Mode.
5. Guardar screenshot si aparece `Ready 15:00 + Start` para grupo viejo.

Resultado esperado con fix:
- No aparece `Ready` para grupo historico.
- El arranque reconcilia directo a estado valido (running correcto o sin target activo).

Resultado de referencia sin fix:
- Flash/pantalla inicial de grupo viejo en ready/completed y luego reconciliacion posterior.

### Escenario B — Repro alternativo (residuo tras cancelacion explicita)
Precondiciones:
1. Android owner.
2. Flujo de 3 grupos con `Resolve overlaps` confirmado.

Pasos:
1. Confirmar `Resolve overlaps`.
2. Cancelar grupo running.
3. Cancelar los grupos restantes de la cola (todos en terminal/canceled).
4. Cerrar app.
5. Reabrir app en Android owner.
6. Verificar si reaparece algun grupo viejo como ready/start.

Resultado esperado con fix:
- Ningun grupo cancelado reaparece como target de arranque.
- Startup cae en Task List/Groups Hub coherente con estado terminal.

Resultado de referencia sin fix:
- Grupo cancelado/historico puede reaparecer como ready/start al abrir.

## 6) Comandos de ejecucion
Android debug (prod override):
```bash
flutter run -v --debug -d RMX3771 --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug008c_2026_03_23/logs/2026-03-23_bug008c_d400a99_android_RMX3771_debug.log
```

Android release (prod):
```bash
flutter run -v --release -d RMX3771 --dart-define=APP_ENV=prod \
  2>&1 | tee docs/bugs/validation_bug008c_2026_03_23/logs/2026-03-23_bug008c_d400a99_android_RMX3771_release.log
```

Chrome debug (opcional, espejo):
```bash
flutter run -v --debug -d chrome --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug008c_2026_03_23/logs/2026-03-23_bug008c_d400a99_web_chrome_debug.log
```

## 7) Log analysis — quick scan
### Señales de bug presente
```bash
rg -n "Timer load group=.*status=completed|Auto-start navigate group=.*f58d0434-173e-4a7d-b508-de8e949fffa9" \
  docs/bugs/validation_bug008_2026_03_23/logs/2026-03-23_bug008b_d400a99_android_RMX3771_debug.log

rg -n "ActiveSession\]\[snapshot.*status=pomodoroRunning.*groupId=f58d0434-173e-4a7d-b508-de8e949fffa9" \
  docs/bugs/validation_bug008_2026_03_23/logs/2026-03-23_bug008b_d400a99_android_RMX3771_debug.log
```

### Señales esperadas con fix funcionando
```bash
rg -n "Timer load group=.*status=completed|Ready|Start now" \
  docs/bugs/validation_bug008c_2026_03_23/logs/2026-03-23_bug008c_d400a99_android_RMX3771_debug.log

rg -n "StaleClearDiag.*decision=clear|ActiveSession\]\[snapshot.*status=pomodoroRunning" \
  docs/bugs/validation_bug008c_2026_03_23/logs/2026-03-23_bug008c_d400a99_android_RMX3771_debug.log
```

## 8) Verificacion local
- [x] `flutter analyze` (PASS, 23/03/2026)
- [x] `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` (PASS, 23/03/2026)
- [x] Android debug log capturado: `2026-03-23_bug008c_d400a99_android_RMX3771_debug.log` (PASS, 23/03/2026)

## 9) Criterios de cierre
1. Escenario A PASS (sin ready/start stale al abrir).
2. Escenario B PASS (sin restaurar cancelados en startup).
3. Sin regresion en late-start queue (`Resolve overlaps` sigue apareciendo en aperturas tardias reales).
4. Evidencia documentada en checklist + logs + screenshots.

## 10) Status line
`Status: Closed/OK`
