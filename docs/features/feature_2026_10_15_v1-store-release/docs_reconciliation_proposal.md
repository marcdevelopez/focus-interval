# Propuesta de reconciliación documental — Focus Interval

Versión: **v2 (2026-10-15)**, tras la revisión de Codex · Autor: Claude
Estado: **PROPUESTA. Nada aplicado.** D1, D2 y D3 se aprueban por separado. Aprobar el arreglo técnico
(`codex_handoff.md`, en esta misma carpeta) no aprueba nada de este documento.

## Principios

- No reabrir bugs cerrados sin evidencia nueva.
- No convertir entradas históricas en trabajo pendiente de forma automática.
- No cambiar comportamiento estable a partir de texto desactualizado.
- Mover un elemento de sitio no equivale a validarlo: todo lo pendiente conserva ID, estado, prioridad y
  referencia en el ledger.
- En los problemas reportados, separar el síntoma observado de la causa hipotética.
- Una sola familia de alcance por PR (regla R-7).

Ya cubierto por `codex_handoff.md` (alcance autorizado): versionado de esta carpeta (dev_log Block 770), BUG-036 + BUGLOG-036 (Block 771) e integración main → develop (Block 772).

---

## PR D1 — Trazabilidad (familia: roadmap/validation closure)

- Rama: `fix/docs-traceability-reconciliation`.
- Archivos: `docs/roadmap.md`, `docs/validation/validation_ledger.md`, `docs/bugs/bug_log.md`,
  `docs/dev_log.md`, `docs/features/feature_backlog.md`.
- Validación: revisión del diff (sin código).

### D1.1 Roadmap "Reopened phases"

Hay 38 viñetas sin tachar: 36 elementos y 2 líneas meta (L568 es una nota y L569 una regla).

Propuesta de estructura:
- **(a) Reabiertos con evidencia.**
- **(b) Lista de verificación de regresión v1.0:** cada elemento con su ID de ledger.
- **(c) Requisitos de producto:** pasan al alcance v1.0 o al backlog.

Nada se borra: lo cerrado queda tachado con su referencia. Los IDs nuevos (`RVP-075` en adelante,
`BUG-037` en adelante) son provisionales.

| Línea | Elemento | Disposición | ID ledger (estado · prioridad) | Evidencia / referencia |
|---|---|---|---|---|
| L504 | Timeline en shared-mode (BUGLOG-034) | Tachar: cerrado | BUGLOG-034 (ya Closed/OK) | Closed/OK 05/05/2026 |
| L563 | Countdowns en tiempo real (BUG-028) | Tachar: cerrado | BUGLOG-028 (ya Closed/OK) | Closed/OK 28/04/2026 (`05b1001`) |
| L565 | Back de Android (BUG-019) | Tachar: cerrado | BUGLOG-019 (ya Closed/OK) | `ed97de7` |
| L537 | BUG-F26-001 | Tachar: cerrado | ya Closed/OK | 18/03/2026 (`92731b3`) |
| L540 | BUG-F26-002 | Tachar: cerrado | ya Closed/OK | 18/03/2026 |
| L543 | BUG-F26-003 | Tachar: cerrado | ya Closed/OK | 18/03/2026 |
| L535 | Auto-reparación del cursor | Tachar: cubierto | — | BUG-F26-001/002 Closed/OK |
| L533 | Sin borrado destructivo en sesión ausente | Tachar: cubierto | — | P0-F26-006 Closed/OK (`cbd800a`) + suite session-gap |
| L556 | Aprobación/rechazo de ownership | Tachar: implementado | — | BUG-002, BUG-021, BUG-024 Closed/OK |
| L561 | Cancelados visibles + re-plan | Tachar: implementado | — | Paquete determinista, escenario D PASS (RVP-074) |
| L513 | Postpone en mirrors | Tachar: superseded | — | Postpone retirado como estrategia (specs 10.4.1.c) |
| L515 | Ajuste de minutos de pre-run | Verificar y cerrar | RVP-075 (Pending · P2) | Existe `pre_run_notice_settings_screen.dart`; falta evidencia de sincronización en Cuenta |
| L521 | Motivo de cancelación pulsable | Verificar y cerrar | RVP-076 (Pending · P2) | Existe `_showCanceledReasonDialog` |
| L532 | Estado Syncing + refresco manual | Verificar y cerrar | RVP-077 (Pending · P1) | Existe "Retry sync" (Fix 26) |
| L555 | Visibilidad de ownership + tomar el control | Verificar y cerrar | RVP-078 (Pending · P1) | Hoja "Session ownership" (specs 10.4.11) |
| L562 | CTA fijo "Go to Task List" | Verificar y cerrar | RVP-079 (Pending · P2) | Fuera del scroll; puede quedar superado por las pestañas |
| L495 | El mirror no arranca atrasado al reanudar | Lista de regresión | RVP-080 (Pending · P1) | Sin prueba específica registrada |
| L511 | Auto-apertura de Pre-Run idempotente | Lista de regresión ("Resolve overlaps" superseded) | RVP-081 (Pending · P1) | Modelo determinista 07/05 |
| L524 | Sin estado Ready transitorio al reanudar | Lista de regresión | RVP-082 (Pending · P1) | Relacionado con BUG-015/018 |
| L525 | Rangos anclados a actualStartTime | Lista de regresión | RVP-083 (Pending · P1) | Relacionado con BUG-006 |
| L526 | Status boxes = rangos de la lista | Lista de regresión | RVP-084 (Pending · P1) | Relacionado con BUG-006/034 |
| L527 | Las pausas extienden theoreticalEndTime entre dispositivos | Lista de regresión | RVP-085 (Pending · P1) | Relacionado con BUG-028/032 |
| L528 | Retry de solicitud de ownership caducada | Lista de regresión | RVP-086 (Pending · P2) | specs 10.4.11 |
| L557 | Auto-takeover por heartbeat caducado | Lista de regresión | RVP-087 (Pending · P1) | specs 10.4.10.3 |
| L518 | Logout en ejecución → pantalla negra | Bug pendiente de reproducción | BUG-040 / BUGLOG-040 (Pending · P1 propuesta) | Ver D1.5 |
| L497 | Chip de tiempo total + color en Task Editor | A producto | (backlog; ledger al implementarse) | No implementado |
| L498 | Edit Group: trabajo + duración total | A producto | (backlog) | No implementado |
| L499 | Task List: nombre de grupo + resumen + tiempo por tarea + reset | Dividir: reset ya existe (`selection.clear`); el resto a producto | (backlog) | Parcial |
| L516 | Modelo: nombre de grupo + color + integrityMode | integrityMode existe; el resto a producto | (backlog) | Parcial |
| L559 | Barra de progreso de grupo + colores | A producto (dirección aprobada 14/10) | (backlog → v1.0) | No implementado |
| L560 | Nombre de grupo + renombrar en el Hub | A producto (dirección aprobada 14/10) | (backlog → v1.0) | No implementado |
| L514 | Sonidos globales | A backlog | — | No implementado |
| L517 | Perfil (nombre + avatar) | A backlog | — | No implementado |
| L564 | Hora real "Started" | A backlog | IDEA-040 (ya en ledger, Pending P2) | No implementado |
| L566 | IDEA-041 | A backlog | IDEA-041 (ya en ledger, Pending P2) | Deferred |
| L567 | Persistencia de sesión web | A backlog | — | Web fuera de v1.0 |

Resultado:
- **11 cierres** con evidencia que ya existe.
- **5 "verificar y cerrar"** (RVP-075 a 079, siguen abiertos hasta tener evidencia).
- **8 de regresión** (RVP-080 a 087).
- **1 bug pendiente de reproducción** (BUG-040).
- **11 a producto o backlog.**

Las prioridades son propuestas del owner y se pueden cambiar.

### D1.2 Hashes provisionales

Recuento:
- Ledger: 31 (29 `pending-local` + 2 `not-backfilled`).
- bug_log: 12.
- dev_log: 58.

Método:
- Buscar cada commit por mensaje: `git log --all --format='%h %s' | grep -F "<mensaje>"`.
- Coincidencia única → sustituir el placeholder por el hash.
- Ambigua o inexistente → `not-traceable (<motivo>)`. Nunca adivinar.

### D1.3 IDEA-034

- Hoy figura `in_progress`, pero solo existe el plan (PR #139), sin código.
- Propuesta: pasarla a `planned (docs only, not implemented)`, con nota de cobertura parcial por Fix 26.
- Objetivo propuesto: v1.1. Sin entrada en el ledger mientras no esté activa (alternativa: Pending P2).

### D1.4 Cabecera del dev_log

Se resuelve en los Blocks 770–772 (`codex_handoff.md`).

### D1.5 Problemas reportados → bug_log como pendientes de reproducción

Formato de cada entrada: **síntoma observado** separado de **causa hipotética**. Estado
`Open — pending reproduction`; en el ledger, `Pending`.

| ID provisional | Síntoma observado (fuente) | Hipótesis (no demostrada) | Prioridad propuesta |
|---|---|---|---|
| BUG-037 | En iOS, al editar el nº de pomodoros, Apply y la flecha atrás quedan bajo la AppBar y no se pueden pulsar (notas del owner, "PARA CODEX") | La hoja se abre con `isScrollControlled: true` sin `useSafeArea`. Su `SafeArea` interno puede no proteger arriba porque la ruta modal elimina el padding superior | P1 si bloquea la edición |
| BUG-038 | El desplegable de presets muestra nombres largos en dos líneas (notas del owner) | El `Text` del ítem no tiene `maxLines: 1` ni elipsis y no hay `selectedItemBuilder` | P2 |
| BUG-039 | Run Mode se monta y desmonta repetidamente con "Server fetch failed" y el grupo queda en "Loading" (log del 15/10, DEV sin emuladores) | Falta de manejo cuando el backend no es alcanzable. Confirmar con Firebase real + modo avión | Por determinar tras reproducir |
| BUG-040 | Logout con sesión en ejecución o en pausa → pantalla negra (reportado en roadmap L518) | Sin hipótesis técnica actual; requiere reproducción | P1 (callejón sin salida) |

Los logs del 15/10 ya están dentro del proyecto con nombre normativo en
`docs/features/feature_2026_10_15_v1-store-release/logs/` (ignorados por `*.log`; se versionan con `git add -f` en el paso 1.3,
publicación aprobada por el owner el 15/10). Si se registra BUG-039, su carpeta de validación
`docs/bugs/validation_bug039_2026_10_15/` los referenciará (o se moverán allí con el prefijo `bug039`).

---

## PR D2 — Reglas de proceso (familia: process-governance)

- Rama: `fix/process-governance-v1-workflow`.
- Archivos: `CLAUDE.md`, `AGENTS.md`, `docs/team_roles.md`, `docs/git_strategy.md`, `docs/bugs/README.md`.

| # | Cambio | Motivo |
|---|---|---|
| D2.1 | Roles: Claude (orquestación, documentación, QA, revisión de PR) + Codex (implementación y operaciones Git; con acceso a la copia local) + ChatGPT web (apoyo y auditorías). Gemini pasa a opcional | Decisión del owner 14/10 |
| D2.2 | AGENTS.md §13 AP-4 alineado con CLAUDE.md AP-4 / specs 10.4.8.b | Contradicción entre documentos |
| D2.3 | Suite completa obligatoria antes de cada merge a develop, más las suites focalizadas; registrar los fallos previos antes de empezar | BUG-036 |
| D2.4 | Puntos seguros en `docs/git_strategy.md`: convención `safety-YYYYMMDD-<rama>-<hash>-<motivo>`; tabla de tags; **recuperación por PR mediante revert de merges concretos o commit explícito de restauración** (`codex_handoff.md` §8), detallando qué se revierte y qué se conserva; nunca force-push; nunca "fusionar el tag antiguo" (no deshace nada). Límite explícito: el tag no cubre personales, evidencias ignoradas ni estado sin commit; para eso existe el respaldo fuera del Mac | Petición del owner + corrección de Codex |
| D2.5 | Handoffs con "Allowed files" / "Forbidden changes" | spec-driven-ai-dev |
| D2.6 | Rigor proporcional (R0 docs · R1 tests/textos/assets · R2 lógica no sync · R3 sync/temporizador/sesión/auth/persistencia) | Petición del owner |
| D2.7 | Validación en dispositivos periódica para cambios R0–R2 (smoke semanal en Android + iPhone + iPad; regresión completa en cada versión candidata). **Los cambios R3 conservan todos sus controles específicos:** repro exacto, regresión, test de continuidad del listener (G-3) y soak ≥4 h con refresco de token (G-4) cuando aplique | Decisión del owner, acotada por Codex |
| D2.8 | Pruebas contra producción en debug (`ALLOW_PROD_IN_DEBUG`): protocolo controlado (registrar entorno, modo, cuenta, dispositivo, commit y log) hasta configurar staging; staging obligatorio antes del lanzamiento. Documentar la configuración local de VS Code "prod-debug" para evitar el arranque accidental en DEV sin emuladores (causa del 14/10) | Diagnóstico del 15/10 |
| D2.9 | Logs de diagnóstico sin bug asignado: registrar antes el candidato (pendiente de reproducción) y guardar en su carpeta de validación con fecha real y hash; si no es posible, preguntar al owner antes de usar otra ruta | Error de Claude del 15/10 |
| D2.10 | Ubicación de documentos de trabajo: planes, handoffs, propuestas y logs **siempre dentro del proyecto**, en su carpeta de feature o de validación; notas privadas del owner en `docs/nuevas-funcionalidades/` (privada, ignorada). Fuera del repo solo van las copias de seguridad, que además deben salir del Mac. Prohibido usar carpetas sueltas en `~` | Error repetido de Claude (13–15/10) |
| D2.11 | Resolver la contradicción entre `docs/features/README.md` (carpetas `IDEA-xxx-slug` con brief/scope/acceptance/ux/testing) y `AGENTS.md` (carpetas `feature_YYYY_MM_DD_slug` con `feature_plan.md` / `feature_checklist.md`, que es lo que se usa en la práctica) | Incoherencia detectada el 15/10 |

---

## PR D3 — Especificación de producto v1.0 (familia: feature/spec)

- Rama: `feature/v1-scope-definition`.
- Solo DESPUÉS de las sesiones de revisión UX.

| # | Cambio |
|---|---|
| D3.1 | §14: v1.0 = primera versión en tiendas (Android, iOS, iPadOS) |
| D3.2 | §2: plataformas de v1.0; escritorio y web después |
| D3.3 | Solo tema oscuro en v1.0 (§10.6.E, §10.8, §14) |
| D3.4 | Inglés + español con autodetección; los textos de las specs pasan a claves EN/ES |
| D3.5 | **Coherencia de sincronización conservando la distinción entre proyección y autoridad.** La proyección visual (anillo, MM:SS) continúa durante la desconexión (10.4.10.2, L2196–2206). Eso **no** habilita escrituras ni controles sin autoridad confirmada: solo escribe el owner y, a partir de 45 s, se bloquean las acciones que mutan ownership/sesión hasta reconfirmar. Solo se marcan como superseded las partes de L1923–1924 y L1986–1989 que ordenan congelar u ocultar la proyección; la parte de L1986–1989 que desactiva controles se conserva o se alinea con lo que haga el código, **previa verificación en código** |
| D3.6 | Alcance v1.0 aprobado pantalla a pantalla tras las fichas UX |
| D3.7 | Roadmap: fase 28 = "Publicación móvil v1.0"; sección "Después de v1.0" |
| D3.8 | Backlog: incorporar la matriz `docs/nuevas-funcionalidades/2026-10-15_matriz_trazabilidad_notas_42.md` con campo `Target` y trazabilidad al apartado original. Como el repo es **público**, el owner decide qué ideas se publican en el backlog y cuáles permanecen en su carpeta privada |

---

## Respaldo

Procedimiento completo y verificado en `codex_handoff.md` §2. Cubre:
- 408 archivos ignorados de `docs/` (404 evidencias + 3 logs de entorno + matriz privada);
- los ficheros personales y `.env.local`;
- esta carpeta de planificación mientras no esté versionada;
- la instantánea del merge pendiente;
- sumas SHA-256;
- el bundle de Git tras el paso 1.2.

Copia fuera del Mac antes de excluir o borrar nada.
