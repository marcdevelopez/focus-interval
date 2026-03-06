# Plan — Rapid Validation Fixes (Post-Rollback 2026-03-05)

Date: 2026-03-05
Source: re-validacion post-rollback tras volver al baseline `2c788c3` y re-aplicar
Plan Group notice control + debug prod override.

## Rollback Note (05/03/2026)
Branch reset to commit `2c788c3` (Fix 22 P0-3 validation baseline) to eliminate
post‑P0‑3 regressions. Only **Plan Group notice control** features and the
**debug prod override** were re‑applied. Any fixes introduced **after** P0‑3
must be treated as **not present** in this branch and should be re‑implemented
or re‑validated before closing related scopes.

## Re-validacion post-rollback (05/03/2026)
Owner: iOS. Mirror: Chrome.

Resultados confirmados con capturas:
1. FAIL — Auto-clamp de pre-run notice no se aplica al grupo. Snackbar reduce el notice
   (ej.: “Pre-run notice reduced to 2m”), pero al confirmar aparece
   “That start time is too soon...” y no permite planificar.
   Evidencia: `docs/bugs/validation_fix_2026_03_05/screenshots/2026_03_05_notice_clamp/notice_clamp_01.png`,
   `notice_clamp_02.png`, `notice_clamp_03.png`, `notice_clamp_04.png`.
2. FAIL — Owner suma el tiempo pausado al volver de otra pantalla (solo la primera vez).
   Tras pausa/resume, al salir y volver al Timer Run el contador vuelve atras
   sumando los segundos pausados. En mirror no ocurre.
   Evidencia: `docs/bugs/validation_fix_2026_03_05/screenshots/2026_03_05_pause_owner_jump/`
   (`pause_owner_jump_01.png` a `pause_owner_jump_10.png`).
3. FAIL — Resolve overlaps aparece sin conflicto real al volver de Local → Account.
   Request ownership no llega al otro dispositivo y el ownership cambia automatico.
   Cancel all funciona correctamente.
   Evidencia: `docs/bugs/validation_fix_2026_03_05/screenshots/2026_03_05_overlaps_false_conflict/`
   (`overlaps_false_conflict_01.png` a `overlaps_false_conflict_08.png`).

Observaciones adicionales (sin logs, pendientes de repro formal):
1. Mirror queda en “Syncing session” indefinidamente al iniciar desde pre-run.
2. Pausa en mirror deja botones habilitados pero no responde hasta salir/volver.
3. Timers se congelan y solo se corrigen al cambiar de pantalla.
4. Owner cambia a background y el mirror sigue; al volver el owner el mirror se congela unos segundos.
5. Pre-run a veces se queda en Groups Hub en vez de entrar a pre-run.
6. Owner se congela al entrar en break tras background (circulo gris completo).
7. Notificacion “Pomodoro running” aparece sin sesion activa.
8. Cancelacion por conflicto no muestra motivo en Groups Hub.
9. En Local Mode aparecen avisos de grupos cancelados de Account.
Evidencia parcial: `docs/bugs/validation_fix_2026_03_05/screenshots/2026_03_05_other_observations/other_observation_01.png`.

Regla adicional reafirmada:
- El fin de un grupo y el inicio del pre-run del siguiente no pueden ser el mismo minuto.
  El siguiente start/pre-run debe ser al menos +1 minuto.

## Scope (Bugs To Fix)
1. Auto-clamp de pre-run notice debe aplicarse al grupo (aunque no cambie el global) y permitir planificar sin error (regresion).
2. Owner no debe re-sumar tiempo pausado al re-entrar al Timer Run tras navegar (regresion).
3. Local → Account no debe disparar Resolve overlaps sin conflicto real; request ownership debe entregarse correctamente.

## Decisions And Requirements
- El auto-clamp aplica al grupo planificado; si el global no cambia, la UI debe
  informarlo claramente.
- El aviso debe ser un **snackbar** con accion para aplicar el notice efectivo
  como **global**; si el usuario no acepta, el global se mantiene.
- La UI debe explicar brevemente que el **global notice** es el valor por defecto
  para futuros grupos programados.
- El aviso rojo del plan group se elimina (no es error). En su lugar:
  - Linea informativa persistente en la tarjeta de notice.
  - Snackbar persistente con “Don’t show again” + OK (per‑device).
- Si el start seleccionado ya pasó mientras se está en Plan group, el sistema
  actualiza el **start a ahora** (mismo minuto), fuerza **pre‑run = 0m** y
  muestra una linea informativa persistente indicando que puede editar otra hora.
  Aplica a schedule start/range/total; en range el end se mantiene y si queda
  inválido se bloquea con error.
- El owner nunca debe modificar la linea de tiempo al volver al Timer Run despues
  de una pausa y navegacion.
- Request ownership debe entregarse al owner activo; no hay flips automaticos
  salvo reglas de takeover documentadas.

## Fix Order (Implementation Sequence)
Each item below is a separate fix and must be committed separately.
1. Fix 23 — aplicar notice clamped al grupo o actualizar global de forma coherente (Scope 1).
2. Fix 24 — evitar re-suma de pausa al rehidratar el owner tras navegar (Scope 2).
3. Fix 25 — eliminar overlaps falsos y asegurar entrega de request ownership (Scope 3).

## Execution Gate (mandatory)
- No iniciar nuevas features de `docs/feature_backlog.md` hasta cerrar:
  1. Fix 24 validado.
  2. Fix 25 validado.
  3. Regression checks (los 4 items) en verde para el estado post-fix.
- Si alguno falla, se mantiene bloqueado el trabajo de features y se prioriza el fix.

## Fix Closure Policy (mandatory)
- Un fix se marca **Closed/OK** automaticamente cuando:
  1. Exact Repro pasa.
  2. Regression checks pasan.
  3. Hay evidencia registrada (checklist + logs/screenshots cuando aplique).
- No se pide confirmacion extra para cerrar un fix cuando se cumplen esas 3 condiciones.

## Fix Status
- Fix 23 (Scope 1): **Closed/OK** (06/03/2026).
  - Code commit: `a884c94` (`feat: clamp planning notice with global apply and fix persistent banner actions`).
  - Validation: PASS (owner iOS + mirror Chrome), including:
    - notice auto-clamp applied to the planned group,
    - schedule confirmation succeeds without "too soon" false block,
    - `Apply globally` action updates global notice default,
    - planned group appears in Groups Hub with effective pre-run.
  - Regression smoke checks: PASS (all 4 checklist items).
- Fix 24 (Scope 2): Code updated in isolated branch `fix24-owner-pause-reentry-jump`
  (06/03/2026). Tests: `flutter analyze` (pass). Validation pending.
  Notes:
  - Owner hydration now pins `_localPhaseStartedAt` from `session.phaseStartedAt`
    for both running and paused states.
  - Owner hydration no longer applies group timeline projection in Account Mode.

## Acceptance Criteria
1. Si el notice es auto-clamped, el grupo se planifica con el notice efectivo y el snackbar:
   - explica que el global no cambia,
   - permite aplicar ese valor al global si el usuario lo desea.
2. El owner no ajusta el timer al volver al Timer Run despues de una pausa y navegacion.
3. Local → Account no muestra Resolve overlaps sin conflicto real y el request ownership llega al owner.

## Regression checks (obligatorio en cada fix)
1. Auto-open gating: durante Plan group no reabre Run Mode; en resume auto-open ocurre una sola vez.
2. iOS notice 0: programado notice 0 sin pantalla negra ni errores en log.
3. Local Mode: "Open Run Mode" no reinicia el grupo running.
4. Completion: tras el modal de completion la app vuelve a Groups Hub (nunca Ready).

## Exact Repro (Fix 23 — notice clamp no aplicado)
1. Ajustar Global notice = 5m.
2. Planificar grupo a now+2 min.
3. Ver snackbar “Pre-run notice reduced to 2m”.
4. Confirmar planificacion.
   - Resultado esperado/actual (06/03/2026): el grupo se planifica con notice
     efectivo, no bloquea con "too soon", y permite `Apply globally`.

## Exact Repro (Fix 24 — owner suma pausa al re-entrar)
1. Owner iOS inicia Start now.
2. Pausar ~10s y reanudar.
3. Salir a otra pantalla (Groups Hub) y volver al Timer Run.
   - Resultado actual: el timer retrocede sumando el tiempo pausado (solo primera vez).

## Exact Repro (Fix 25 — overlaps falsos + ownership erratico)
1. Programar dos grupos seguidos sin solapamiento real.
2. Pasar a Local Mode en iOS (owner original).
3. Volver a Account en macOS al llegar el start time.
   - Resultado actual: Resolve overlaps aparece sin conflicto real.
   - Request ownership no llega; ownership cambia automaticamente.
