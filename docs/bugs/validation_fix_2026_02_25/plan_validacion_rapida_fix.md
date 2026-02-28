# Plan — Rapid Validation Fixes (Post-Validation 2026-02-24)

Date: 2026-02-25
Source: docs/bugs/validation_fix_2026_02_24/quick_pass_checklist.md + screenshots

## Scope (Bugs To Fix)
1. Late-start queue Cancel all: mirror does not show the "Owner resolved" modal; owner shows it instead.
2. After Cancel all, mirror can still act as owner and continue Resolve overlaps.
3. "Owner resolved" modal does not dismiss on OK (requires tapping outside).
4. Scheduling conflict modal triggers when the running group end time coincides with the next group's pre-run start (false conflict).
5. Groups Hub re-plan "Start now" sometimes fails to open Run Mode and remains on Groups Hub (regression).
6. After group completion, the app sometimes lands on the Ready screen with Start button instead of returning to Groups Hub (regression).
7. Android: black screen when leaving Timer Run -> Groups Hub -> Task List, then tapping logout in the AppBar (Chrome does not reproduce).
8. Groups Hub scheduled rows inconsistent between devices (owner shows "Pre-Run: X min starts at HH:mm" while mirror shows "Notice: X min").
9. Running task item time range is off by one minute compared to status boxes after pre-run/ownership transitions.
10. Analyzer warnings: remove unnecessary non-null assertions and avoid BuildContext across async gaps.
11. Timer Run Mode bounces back to Groups Hub after Start now / Run again / scheduled start (brief Timer flash, then Groups Hub). User must tap "Open Run Mode" manually. Root cause likely inconsistent entry paths into Run Mode.
12. Follow-up: Scheduled auto-start with notice 0 still bounces to Groups Hub on both devices; Run Mode opens only with manual "Open Run Mode" (validation 26/02/2026).
13. Follow-up: Account Mode Start now / Run again can create a running TaskRunGroup without `activeSession/current`; Run Mode shows "Syncing session" or stays in Groups Hub (validation 26/02/2026).
14. Follow-up: Late-start queue claim fails on some devices; mirror never shows Resolve overlaps or "Owner resolved" after Cancel all (validation 26/02/2026).
15. Follow-up: Switching Local → Account with overdue groups does not trigger late-start queue; Resolve overlaps appears only after app restart (validation 26/02/2026).
16. Auto-open de Run Mode se re-dispara e interrumpe al usuario fuera de los triggers permitidos (planificacion/edicion/modales).
17. iOS: programado notice 0 deja pantalla negra al confirmar (app queda sin ruta visible).
18. Local Mode: "Open Run Mode" reinicia el grupo running y desalinea rangos (follow-up Fix 17).
19. Rangos de tareas vs status boxes se desalinean tras pausa/resume (follow-up Fix 5).
20. Mirror: al abrir la app, el timer empieza con desfase de segundos hasta el siguiente snapshot (regresion).
21. Mirror: al volver de background o de Local -> Account, el timer arranca desfasado si `lastUpdatedAt` es viejo; debe compensar el delta hasta el siguiente snapshot (regresion).
22. P0: Run Mode single source of truth (time sync real + sessionRevision + paused offsets); eliminar drift y estados divergentes entre owner/mirror (regresion critica).

## Decisions And Requirements
- Cancel all must resolve the queue for **all** devices.
- The "Owner resolved" modal must appear on mirrors (not owners) and must dismiss on OK.
- After Cancel all, mirrors must not be able to proceed as owner; actions must be locked until the queue is fully resolved.
- Scheduling conflict should only appear when there is a **real overlap**; equality at the pre-run boundary must not trigger a conflict.
- Re-plan "Start now" must always navigate to Run Mode reliably.
- Group completion must always return to Groups Hub; Ready screen must never appear after group completion.
- Android logout must never show a black screen; behavior must match Chrome.
- Scheduled group rows must render the same fields on owner and mirror.
- Task item time ranges must match authoritative status box ranges.
- All entry points (Start now, Run again, scheduled auto-start) must use a single Run Mode start pipeline.
- The start pipeline must provide the new group snapshot to Run Mode to avoid read races on immediate navigation.
- If the group truly does not exist after the unified start pipeline, show "Selected group not found" and return to the correct hub screen.
- Account Mode Start now / Run again must publish `activeSession/current` as owner when a group transitions to running; a running group without `activeSession` is invalid.
- Auto-open debe ser por triggers explicitos y no re-dispararse en cada update del stream; nunca debe interrumpir planificacion/edicion/settings.
- iOS programado notice 0 nunca debe dejar pantalla negra; la app debe quedar en Run Mode o en un hub valido con CTA.

## Fix Order (Implementation Sequence)
Each item below is a separate fix and must be committed separately.
1. Late-start queue Cancel all: mirror modal, owner/mirror gating, modal OK (Scope 1–3).
2. Android logout black screen (Timer Run -> Groups Hub -> Task List -> logout) (Scope 7).
3. Completion must navigate to Groups Hub (no Ready screen) (Scope 6).
4. False conflict at pre-run boundary (Scope 4).
5. Task item time ranges must match status boxes (Scope 9).
6. Scheduled rows must match on owner/mirror (Pre-Run vs Notice) (Scope 8).
7. Re-plan "Start now" must always open Run Mode (Scope 5).
8. Analyzer warnings cleanup (Scope 10).
9. Timer Run Mode must not bounce back to Groups Hub after Start now / Run again / scheduled start by using a unified start pipeline (Scope 11).
10. Follow-up: Scheduled auto-start notice 0 must stay in Run Mode (Scope 12).
11. Follow-up: Scheduled auto-start must navigate immediately (no 1–2s Groups Hub flash) (Scope 12).
12. Follow-up: Account Mode Start now / Run again must create `activeSession/current` (Scope 13).
13. Follow-up: Late-start queue claim must not block mirror queue display or "Owner resolved" modal (Scope 14).
14. Follow-up: Mode switch (Local → Account) must re-evaluate and surface late-start queue when overdue conflicts exist (Scope 15).
15. Auto-open trigger-based y suppression en pantallas sensibles (Scope 16).
16. iOS scheduled notice 0 no black screen; asegurar navegacion estable (Scope 17).
17. Local Mode "Open Run Mode" no debe reiniciar el grupo; rangos deben coincidir (Scope 18).
18. Rangos de tareas vs status boxes deben coincidir tras pausa/resume (Scope 19).
19. Mirror debe iniciar ya sincronizado al abrir (sin desfase de segundos) (Scope 20).
20. Mirror debe compensar snapshots viejos al reanudar (sin desfase inicial) (Scope 21).
21. P0: Run Mode single source of truth (time sync + revision + pause offsets) (Scope 22).

### Repro exacto (Fix 16 — iOS notice 0 black screen)
- Modo: Account Mode en iOS simulador.
- Contexto: grupo G1 running en iOS; termina a las 13:19.
- Accion: planificar un grupo con notice = 0 para iniciar a las 13:20 (Plan group -> by time).
- Momento del fallo original: 13:10:55 al pulsar OK en el dialogo de planificacion.
- Resultado previo: pantalla negra en iOS (imagen 03). Imagen 02 justo antes de OK.
- Firebase (current) en ese instante: ownerDeviceId = web-6fbc21ef-e489-41bc-8d55-b35917480950, status = pomodoroRunning, phaseStartedAt = 13:04:24, remainingSeconds = 514.
- Logs asociados: `_ios_simulator_iphone_17_pro_diag-1.log` y `2026_02_25_web_chrome_diag-1.log`.

### Repro exacto (Fix 17 — Local Mode isolation + Run Mode stability)
1. Preparar: Account Mode activo en iOS (owner) con un grupo **running** en curso. Mantener la app abierta.
2. En Chrome: cambiar a Local Mode **sin cerrar la app**.
   - Bug observado: snackbar "Selected group not found" aparece al entrar.
3. En Chrome Local Mode: crear una tarea, seleccionarla y usar Plan group → Start now.
   - Bug observado: Run Mode abre y vuelve a Groups Hub.
4. En Chrome Local Mode: desde Groups Hub pulsar "Open Run Mode" varias veces.
   - Bug observado: el grupo **reinicia** cada vez.
5. En Chrome Local Mode: comparar rango del item en Run Mode vs "Ends" en Groups Hub.
   - Bug observado: los rangos **no coinciden**.
6. En iOS: cambiar a Local Mode sin cerrar la app mientras el grupo de Account sigue running.
   - Bug observado: snackbar "Selected group not found" y estado "Loading group..." con botones Pause/Cancel visibles.
7. En iOS Local Mode: pulsar Cancel.
   - Bug observado: Groups Hub muestra datos cruzados (Ends de grupo de Account en tarjeta Local).
8. En Settings (Local Mode): fijar notice = 0. Programar un grupo by time a 1–2 minutos.
   - Bug observado: error "That start time is too soon..." (incoherente con notice 0).

### Repro exacto (Fix 18 — Local Mode Open Run Mode restarts group)
1. En Chrome Local Mode: crear una tarea, seleccionar y Plan group → Start now.
2. Ir a Groups Hub y pulsar "Open Run Mode" varias veces.
   - Bug observado: el grupo se reinicia cada vez.
3. Comparar rango del item en Run Mode vs "Ends" en Groups Hub.
   - Bug observado: no coinciden tras el reinicio.

### Repro exacto (Fix 19 — Rangos vs status boxes tras pausa)
1. En Account Mode (owner): iniciar un grupo running.
2. Esperar 1–2 min, pausar durante ~1 min y reanudar.
3. Comparar el rango del item de tarea actual con la Status Box (Pomodoro 1 of X).
   - Bug observado: la Status Box mueve el start (+1 min) mientras el item mantiene el rango correcto.

### Repro exacto (Fix 20 — Mirror desfasado al iniciar)
1. Owner (Account Mode) con grupo running en iOS.
2. Abrir app en mirror (Chrome) mientras el grupo ya esta corriendo.
3. Observar el timer del mirror al entrar.
   - Bug observado: arranca con desfase de segundos y se corrige en el siguiente snapshot.

### Repro exacto (Fix 21 — Mirror desfasado tras resume / Local -> Account)
1. Owner (Account Mode) con grupo running en iOS.
2. Mirror (Chrome) en Account Mode: abrir Run Mode y confirmar que esta en sync.
3. En mirror: enviar la app a background o cambiar a Local Mode durante ~10s.
4. Volver a Account Mode en el mirror (o foreground).
5. Observar el timer del mirror justo al reanudar.
   - Bug observado: arranca con desfase de segundos respecto al owner y se corrige en el siguiente snapshot.
   - Logs: `2026_02_28_ios_simulator_iphone_17_pro_diag.log`, `2026_02_28_web_chrome_diag.log`.

## Fix Tracking
Update this section after each fix.
1. Fix 1 (Scope 1–3): Done (2026-02-25, tests: `flutter test`, commit: 9f614e6 "Fix 1: late-start owner resolved gating")
2. Fix 2 (Scope 7): Done (2026-02-25, tests: `flutter test`, commit: 0c66629 "Fix 2: stabilize Android logout navigation")
3. Fix 3 (Scope 6): Done (2026-02-25, tests: `flutter test`, commit: 16a6522 "Fix 3: ensure completion returns to Groups Hub")
4. Fix 4 (Scope 4): Done (2026-02-25, tests: `flutter test`, commit: 59ab399 "Fix 4: add pre-run overlap grace")
5. Fix 5 (Scope 9): Done (2026-02-25, tests: `flutter test`, commit: 34d1938 "Fix 5: align status box ranges")
6. Fix 6 (Scope 8): Done (2026-02-25, tests: `flutter test`, commit: b99decb "Fix 6: align scheduled pre-run rows")
7. Fix 7 (Scope 5): Done (2026-02-25, tests: `flutter test`, commit: 726d69b "Fix 7: ensure Start now opens Run Mode")
8. Fix 8 (Scope 10): Done (2026-02-25, tests: `flutter analyze`, commit: 3913cbd "Fix 8: analyzer warnings cleanup")
9. Fix 9 (Scope 11): Done (2026-02-26, tests: `flutter analyze`, commit: dfa0048 "Fix 9: unify Run Mode start pipeline") — unified Run Mode start pipeline with in-memory snapshot; prior attempt 16d2098 superseded. Validation: Start now + Run again OK; scheduled notice 0 still bounces (needs follow-up).
10. Fix 10 (Scope 12): Implemented (2026-02-26, tests: `flutter analyze`, commit: fd2a385 "Fix 10: stabilize auto-open gating") — auto-open now marks a group as opened only after confirming `/timer/:id`, and resets when not in timer. Root cause: auto-open marked opened before route confirmation, suppressing further auto-open after a bounce. Follow-up: scheduled auto-start still shows 1–2s in Groups Hub due to waiting on `getById` before navigation; fix by navigating first and prefetching after.
11. Fix 11 (Scope 12 follow-up): Implemented (2026-02-26, tests: `flutter analyze`, commit: 477ef31 "Fix 11: fast scheduled auto-start navigation") — scheduled auto-start navigates to `/timer/:id` before prefetch to avoid initial Groups Hub delay.
12. Fix 12 (Scope 13): Done (2026-02-26, tests: `flutter analyze`, commit: 7447f57 "Fix 12: auto-start running groups on load") — Account Mode Start now / Run again now auto-start on initial load and are gated to the initiating device when session is missing.
13. Fix 13 (Scope 14): Done (2026-02-26, tests: `flutter analyze`, commit: 618706f "Fix 13: harden late-start queue claim") — late-start claim is resilient to mixed timestamp formats and still surfaces the queue on mirrors if claim fails.
14. Fix 14 (Scope 15): Done (2026-02-26, tests: `flutter analyze`, commit: 4e1b92f "Fix 14: re-evaluate late-start queue on mode switch") — mode switch to Account re-evaluates late-start conflicts and removes the grace delay so Resolve overlaps can surface without restarting the app.
15. Fix 15 (Scope 16): Done (2026-02-27, tests: `flutter analyze`, commit: 94074b7 "Fix 15: gate Run Mode auto-open triggers") — auto-open now respects trigger-only rules and suppresses re-open on sensitive routes.
16. Fix 16 (Scope 17): Done (2026-02-28, tests: `flutter analyze`, commit: 9782fc3 "Fix 16: guard TimerScreen lifecycle on scheduled start") — TimerScreen now avoids ref/setState after unmount to prevent black screen.
17. Fix 17 (Scope 3–8): Done (2026-02-28, tests: `flutter analyze`, commit: 7b2a7ed "Fix 17: local mode isolation and run stability") — Local Mode isolation + Run Mode stability. Validation (28/02/2026): partial; still fails on Local Mode "Open Run Mode" restarting the group and Run Mode vs Groups Hub ranges mismatch (Chrome).
18. Fix 18 (Scope 18): Done (2026-02-28, tests: `flutter analyze`, commit: 55879f4 "Fix 18: prevent local run mode restart") — Local Mode Open Run Mode must not restart the group; ranges must align.
19. Fix 19 (Scope 19): Done (2026-02-28, tests: `flutter analyze`, commit: e7652fd "Fix 19: keep phase start on resume") — Status boxes must not shift on pause/resume; ranges must match task item.
20. Fix 20 (Scope 20): Done (2026-02-28, tests: `flutter analyze`, commit: bad12c3 "Fix 20: derive mirror offset without lastUpdatedAt") — Mirror must start in sync on first render. Validation FAILED (28/02/2026): mirror still starts behind when `lastUpdatedAt` is stale.
21. Fix 21 (Scope 21): In progress (2026-02-28) — attempt 1 regressed (mirror countdown accelerates); attempt 2 still desyncs after mode switch; attempt 3 (fresh-snapshot gating) still fails on iOS owner + Chrome mirror.
22. Fix 22 (Scope 22): In progress (2026-02-28) — P0 single source of truth refactor (time sync + sessionRevision + paused offsets). Implementation underway; tests: `flutter test` (VM + coordinator) + `flutter analyze`. Validation pending.

### Fix 22 — Plan de implementacion (P0 single source of truth)
1. Modelo/Firestore: añadir `sessionRevision` y `accumulatedPausedSeconds` en `PomodoroSession`; añadir `users/{uid}/timeSync` (serverTimestamp); actualizar `firestore.rules`; compatibilidad: campos ausentes -> 0.
2. Time sync real: crear repo/servicio para `timeSync` (write serverTimestamp + read Source.server); cachear offset; refrescar en launch/resume/mode switch con rate-limit.
3. Proyeccion unica: usar `serverNow` para running/paused; `remainingSeconds` queda legacy; si no hay offset, mantener estado valido y mostrar syncing (sin recalcular).
4. Orden determinista: aplicar snapshots solo si `sessionRevision` > lastApplied; para legacy, usar `lastUpdatedAt` solo como orden secundario.
5. Writes owner-only: pause/resume/phase change actualizan `accumulatedPausedSeconds`, `pausedAt`, `phaseStartedAt` y **siempre** incrementan `sessionRevision`.
6. Ownership transfer: el nuevo owner lee la sesion actual y publica el primer write con `revision+1`.
7. Validacion: multi-device (owner/mirror), pause/resume, background, Local→Account; drift <=2s; sin Ready falsos ni swaps.

### Fix 22 — Riesgos / fallos a vigilar
1. Doble tick (actualizar desde dos timelines a la vez).
2. Stale snapshots reescribiendo estado correcto (sessionRevision menor).
3. Proyeccion desde `lastUpdatedAt` (debe quedar solo como liveness).
4. Compatibilidad: clientes antiguos sin campos nuevos (defaults + dual-read/dual-write).

## Plan (Docs First, Then Code)
1. Update specs if any new edge-case rules or timing tolerances are added.
2. Update roadmap reopened items if new bugs/requirements are introduced.
3. Append dev log entry for decisions and scope.
4. Implement fixes in the order listed above, one fix per commit.

## Post-Validation Follow-ups
- Add a unit test: when a scheduled group is **in progress** (start passed, not overdue) and the next group starts after a non-overlapping gap (including pre-run), **late-start queue must not trigger**.
- Rule: When scheduling or re-planning (manual or automatic: resolve overlaps, postpone, re-plan), the **next scheduled start must be at least +1 minute after the previous group end** (does not change group durations; it is a scheduling constraint to avoid seconds-based overlaps).

## New findings — 27/02/2026 (pendientes de triage; tratar antes de nuevas features)
Nota: estos hallazgos deben resolverse en esta rama o registrarse como bugs a corregir antes de implementar nuevas features.

1. Auto-open de Run Mode se re-dispara desde cualquier pantalla (Task List, Groups Hub, planificacion, modales) sin accion directa del usuario. (Ahora en Scope 16)
2. Account Mode: programado notice 0 deja pantalla negra en iOS al confirmar (logs: `_ios_simulator_iphone_17_pro_diag-1.log`, `2026_02_25_web_chrome_diag-1.log`). (Ahora en Scope 17)
3. Local Mode: snackbar "Selected group not found" al entrar sin accion; en iOS queda "Loading group..." con botones Pause/Cancel visibles.
4. Local Mode: "Open Run Mode" en Groups Hub reinicia el grupo cada vez.
5. Local Mode: rangos inconsistentes entre Run Mode y Groups Hub (Ends no coincide con rango del item).
6. Local Mode: cruce de datos con Account Mode (Groups Hub muestra Ends de un grupo de Account tras cancelar en Local).
7. Local Mode: programado con notice 0 muestra error de pre-run "too soon" (incoherente).
8. Local Mode: Start now abre Run Mode pero termina en Groups Hub; "Open Run Mode" reinicia el grupo.
9. Account Mode iOS: documento `current` desaparece y reaparece; Run Mode aparece y rebota varias veces a Groups Hub.
10. Planificacion: tras confirmar grupo programado no aparece snackbar en Task List; solo se ve en Groups Hub.
11. Conflicto: snackbar de "Postpone scheduled" aparece en Groups Hub, no en Run Mode.
12. Notice 0: hay casos donde el grupo programado no inicia al llegar la hora pero cuenta para overlaps (Android fisico).

Hallazgos movidos a `docs/bug_log.md` (no bloquean esta rama, pero deben atacarse antes de nuevas features):
- BUG-010: Mirror desincronizado unos segundos al volver desde Local (timer difiere y luego se corrige).
- BUG-011: Pausa + background deja desfase de tiempo pausado; se corrige al cambiar de owner.
- BUG-012: Mirror queda indefinidamente en "Syncing session"; requiere click o entrar a Groups Hub para recuperar.

## Acceptance Criteria
1. Mirror shows "Owner resolved" modal after Cancel all; owner does not.
2. Modal dismisses on OK without requiring an outside tap.
3. Mirror cannot proceed as owner after Cancel all.
4. No conflict modal when the running end time equals the next pre-run start.
5. Re-plan "Start now" always opens Run Mode.
6. After group completion, the app always navigates to Groups Hub.
7. Android logout never produces a black screen (Timer Run -> Groups Hub -> Task List -> logout).
8. Owner and mirror show the same scheduled rows (Pre-Run line when notice applies).
9. Task item ranges match status boxes in Run Mode.
10. `flutter analyze` reports no warnings for the updated files.
11. Start now / Run again / scheduled auto-start keeps the user in Timer Run Mode (no bounce to Groups Hub).
12. All entry points use the same Run Mode start path (single authoritative flow).
13. If the group is truly missing after the unified start pipeline, show "Selected group not found" and navigate to the correct hub screen.
14. Account Mode Start now / Run again always creates `activeSession/current` for running groups; Run Mode never stays in "Syncing session" due to a missing session doc.
15. Auto-open solo ocurre en triggers explicitos (launch/resume, pre-run start, scheduled start, resolve overlaps o accion del usuario) y nunca interrumpe planificacion/edicion/settings.
16. iOS programado notice 0 nunca deja pantalla negra; tras confirmar, la app queda en Run Mode o en Groups Hub/Task List con CTA visible.
17. Cambiar de modo (Account ↔ Local) limpia Run Mode y regresa a Task List sin snackbars de "Selected group not found".
18. En Local Mode, Start now mantiene Run Mode abierto; "Open Run Mode" no reinicia el grupo.
19. En Local Mode, los rangos en Run Mode y Groups Hub coinciden (Ends correcto).
20. En Local Mode con notice = 0, programar no muestra el error de pre-run "too soon".
21. En mirror, al volver de background o Local→Account, el timer arranca ya sincronizado (sin desfase inicial) y se ajusta con el siguiente snapshot.
22. En Account Mode, owner/mirror comparten **una unica linea de tiempo** (drift ≤2s, sin swaps ni Ready falsos).

## Regression checks (obligatorio en cada fix)
1. Auto-open gating: durante Plan group no reabre Run Mode; en resume auto-open ocurre una sola vez.
2. iOS notice 0: confirmar programado notice 0 sin pantalla negra ni errores en log.
3. Local Mode: "Open Run Mode" no reinicia el grupo running.
4. Completion: tras el modal de completion la app vuelve a Groups Hub (nunca Ready).

## Validation Checklist
- Create `quick_pass_checklist.md` **after** implementation, focused only on the bugs above.
- Validate on macOS (owner) + Android (mirror) using fresh screenshots.
