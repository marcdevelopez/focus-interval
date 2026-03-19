# Plan de Validación Rápida — BUG-F25-I

## 1. Header
- Fecha: 19/03/2026 (CET)
- Rama activa: `fix-f25-i-postponed-start-drifts-on-cancel`
- Commit baseline reproducido: `68429c5`
- Bug cubierto: `BUG-F25-I`
- Dispositivos objetivo: iOS iPhone17Pro (`9A6B6687`) + Chrome (owner/mirror)
- Logs base:
  - `docs/bugs/validation_f25i_2026_03_19/logs/2026-03-19_f25i_68429c5_ios_iPhone17Pro_9A6B6687_debug.log`
  - `docs/bugs/validation_f25i_2026_03_19/logs/2026-03-19_f25i_68429c5_chrome_debug.log`

## 2. Objetivo
Validar y cerrar la regresión donde un grupo `postponed` pierde su hora planificada al cancelar el grupo `running` que actuaba como anchor. Tras el fix, cancelar el anchor NO debe adelantar el `scheduledStart` del postponed a `now`, y NO debe provocar auto-start prematuro.

## 3. Síntoma original
Flujo observado en usuario real:
- Se hace `Postpone scheduled` ante overlap (ejemplo: G2 movido a 22:35).
- Se cancela G1 (running anchor) antes de las 22:35.
- G2 cambia su `Scheduled` a hora actual redondeada (ejemplo: 22:22) y arranca al minuto siguiente.

Impacto:
- Se rompe la intención del usuario (postponer para más tarde).
- Se dispara ejecución no deseada.
- El scheduler queda impredecible en cancelaciones de anchor.

## 4. Root cause
Causa raíz probable (pendiente de confirmación final en code review de fix):
- En `lib/presentation/utils/scheduled_group_timing.dart`, la resolución del anchor postponed puede caer a `anchor.updatedAt` cuando el anchor ya no está `running` y no hay `effectiveEnd` estable.
- Al cancelar, `updatedAt` del anchor pasa a “ahora”.
- En `lib/presentation/viewmodels/scheduled_group_coordinator.dart`, `_finalizePostponedGroupsIfNeeded()` re-evalúa/post-finaliza con ese valor, re-anclando el postponed a `now` y programando timer de inicio inmediato.

Evidencia directa en logs:
- iOS:
  - `51210`: sample mantiene futuro `...22:35|22:36`
  - `51216`: `Cancel nav: group stream canceled`
  - `51224`: sample colapsa a `...22:22|22:22`
  - `51225+`: `schedule-start-timer ... start=22:22:00`
  - `51244+`: `start-timer-fired ... now=22:22:00`
- Chrome:
  - `2623/2632/2658`: sample `...22:35|22:35/22:36`
  - `2670+`: sample pasa a `...22:22|22:22`
  - `2687`: `start-timer-fired ... now=22:22:00`

## 5. Protocolo de validación

### Escenario A — Exact repro (postpone + cancel anchor)
Precondiciones:
1. Dos dispositivos logueados en la misma cuenta (iOS + Chrome).
2. G1 `running` y G2 `scheduled` con overlap.

Pasos:
1. En owner, pausar si hace falta para forzar overlap y mostrar modal.
2. Elegir `Postpone scheduled` para G2.
3. Anotar hora mostrada en snackbar (ejemplo 22:35).
4. Cancelar G1 antes de llegar a esa hora.
5. Observar `Scheduled` de G2 en ambos dispositivos durante 60-90s.

Resultado esperado CON fix:
- G2 mantiene la hora postpuesta (ej. 22:35).
- No se reescribe a `now`.
- No dispara `start-timer-fired` hasta su hora real.

Resultado sin fix (baseline):
- Salta a `now` (22:22) y auto-start al minuto siguiente.

### Escenario B — Regression smoke (pause drift while anchor running)
Precondiciones:
1. G1 `running` aún no cancelado.
2. G2 `postponed` por overlap.

Pasos:
1. Mantener G1 en pausa/reanudar para generar drift normal.
2. Verificar que la hora efectiva de G2 se ajusta mientras anchor sigue `running` (comportamiento esperado).

Resultado esperado CON fix:
- Drift por pausa sigue funcionando mientras anchor está `running`.
- Se rompe linkage únicamente cuando anchor queda terminal (`canceled/completed`).

### Escenario C — Cancel simple sin postpone linkage
Precondiciones:
1. G1 `running`.
2. G2 `scheduled` sin `postponedAfterGroupId` activo.

Pasos:
1. Cancelar G1.
2. Verificar G2.

Resultado esperado CON fix:
- G2 permanece con su `scheduledStart` original.
- Sin auto-start prematuro.

## 6. Comandos de ejecución
```bash
flutter run -d 9A6B6687 2>&1 | tee docs/bugs/validation_f25i_2026_03_19/logs/2026-03-19_f25i_68429c5_ios_iPhone17Pro_9A6B6687_debug.log
flutter run -d chrome 2>&1 | tee docs/bugs/validation_f25i_2026_03_19/logs/2026-03-19_f25i_68429c5_chrome_debug.log
```

## 7. Log analysis — quick scan

### Señales de bug presente
```bash
rg -n "22:35|22:36|22:22|schedule-start-timer|start-timer-fired|postpone-finalized" docs/bugs/validation_f25i_2026_03_19/logs/2026-03-19_f25i_68429c5_ios_iPhone17Pro_9A6B6687_debug.log
rg -n "22:35|22:36|22:22|schedule-start-timer|start-timer-fired|postpone-finalized" docs/bugs/validation_f25i_2026_03_19/logs/2026-03-19_f25i_68429c5_chrome_debug.log
```

### Señales de fix funcionando
```bash
rg -n "postpone-finalized|schedule-start-timer|start-timer-fired" docs/bugs/validation_f25i_2026_03_19/logs/2026-03-19_f25i_68429c5_ios_iPhone17Pro_9A6B6687_debug.log
rg -n "postpone-finalized|schedule-start-timer|start-timer-fired" docs/bugs/validation_f25i_2026_03_19/logs/2026-03-19_f25i_68429c5_chrome_debug.log
# Esperado con fix: no transición de sample 22:35 -> 22:22 tras cancel del anchor.
```

## 8. Verificación local
- [ ] `flutter analyze` PASS
- [ ] `flutter test test/presentation/utils/scheduled_group_timing_test.dart` PASS
- [ ] `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` PASS
- [ ] `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` PASS (regresión crítica de navegación/sync)

## 9. Criterios de cierre
1. Escenario A PASS en iOS y Chrome, con evidencia de logs y screenshots.
2. Sin salto de `scheduledStart` a `now` tras cancel de anchor.
3. Sin `start-timer-fired` prematuro para grupo postponed.
4. Escenario B PASS (drift en pausa sigue válido mientras anchor running).
5. Escenario C PASS (cancel simple no altera horarios ajenos).
6. Local gate PASS (`analyze` + tests objetivo).

## 10. Status
Open — reproducido y documentado; pendiente implementación de fix y re-validación.
