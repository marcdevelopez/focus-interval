# Focus Interval — Plan maestro hacia la v1.0 en tiendas

Versión: **v1.1 (2026-10-15)**, documentos movidos dentro del proyecto · Autor: Claude · Revisado con las auditorías de Codex del 15/10
Fuentes:
- conversación del owner con Claude (13–15/10);
- `chatgpt-chat.md`;
- `FOCUSINTERVAL-notas-todo.txt`;
- auditorías de Codex.

Ubicación: `docs/features/feature_2026_10_15_v1-store-release/`, convención de `AGENTS.md`. Se versiona en el
paso 1.3. Cuando el owner apruebe D1/D2/D3, el estado vivo pasa también a `docs/roadmap.md` y `docs/dev_log.md`.

Documentos asociados:
- `codex_handoff.md`, en esta carpeta: respaldo, documentación de planificación, tests, integración y recuperación.
- `docs_reconciliation_proposal.md`, en esta carpeta: propuesta D1/D2/D3, sin aprobar.
- `logs/`, en esta carpeta: logs del diagnóstico de entorno (ignorados por `*.log`; publicarlos lo decide el owner).
- `docs/nuevas-funcionalidades/2026-10-15_matriz_trazabilidad_notas_42.md`: matriz de las 42 ideas del owner, en su
  carpeta privada (ignorada por git porque el repo es público), sin aprobar.

Idioma: estos documentos de trabajo están en español porque los usa el owner. Los textos que entran en documentos
canónicos (specs, roadmap, backlog, bug_log, ledger, dev_log) van en inglés (`AGENTS.md` §10).

---

## 1. Decisiones del owner ya tomadas (estratégicas)

| Decisión | Fecha |
|---|---|
| v1.0 = primera versión comercial en tiendas (Android + iOS, incluido iPad) | 14/10 |
| Lanzamiento objetivo **15/01/2027**, sujeto a evidencias y capacidad; 18/12/2026 = versión candidata; checkpoint de ritmo el 15/11 | 14/10 |
| Idiomas: inglés (principal) + español | 14/10 |
| v1.0 gratis y sin anuncios; más adelante anuncios no intrusivos + versión de pago sin anuncios | 14/10 |
| iPad y orientación horizontal en teléfonos | 14/10 |
| Solo tema oscuro en v1.0 (claro más adelante) | 14/10 |
| Login: añadir Sign in with Apple; mantener GitHub | 14/10 |
| Validación en dispositivos periódica, en todas las plataformas (los cambios sensibles conservan sus controles) | 14/10 |
| Flujo: Claude + Codex + ChatGPT web; el owner decide y modera | 14/10 |
| Dirección aprobada, con diseño pendiente de revisión: nombre de grupo, barra de progreso del grupo, ayuda de primer uso, pestañas (condicionadas a esfuerzo y a demostrar que no hay regresiones) | 14/10 |
| Las decisiones importantes de UX/UI las toma el owner, pantalla a pantalla | 13/10 |
| Punto seguro: tag `safety-20261015-develop-ff30e15-pre-main-sync` → `ff30e15` (publicado) | 15/10 |

## 2. Estado de aprobaciones

| Elemento | Estado |
|---|---|
| Integración `main` → `develop` (opción A, merge commit) | ✅ Aprobada |
| Reparación de los 2 tests (BUG-036, test-only) | ✅ Aprobada |
| Licencias de Android | ✅ Hecho |
| Respaldo verificado (`codex_handoff.md` §2) | ✅ Creado y verificado por Claude el 15/10 a las 13:32 (copia local). Destino fuera del Mac: Google Drive del owner, carpeta restringida `JORNADA/DEVELOP/3_PROYECTO-PERSONAL/focus-interval/backups/2026-10-15_pre-v1-stage1/` (con `LEEME`). ✅ Subida a Drive verificada por Claude (15/10): 5 ficheros con tamaño idéntico al byte a la copia local. Enlaces y sumas en el registro privado `docs/nuevas-funcionalidades/registro_copias_seguridad.md` |
| Versionar los documentos de planificación (paso 1.3) | ✅ Pedido por el owner (15/10) |
| D1 trazabilidad · D2 reglas de proceso · D3 especificación v1.0 | ⏸️ Pendientes (se aprueban por separado) |
| Clasificación de producto / matriz de 42 ideas | ⏸️ Pendiente (propuesta) |
| Configuración local de VS Code "prod-debug" | ⏸️ Pendiente |
| Registrar BUG-037 a 040 (pendientes de reproducción) | ⏸️ Pendiente (va con D1) |
| Publicar los 3 logs de entorno (`git add -f`, en el paso 1.3) | ✅ Aprobado por el owner (15/10) |
| Visibilidad del repositorio | ✅ Se mantiene **público** (owner 15/10: el proyecto sirve también para darse a conocer). Se publican el plan y los documentos de planificación |

## 3. Reparto de roles

- **Owner:** decide; valida en dispositivos; mueve los mensajes entre agentes.
- **Claude:** orquesta; redacta handoffs y documentación; revisa el diff de cada PR antes del merge;
  propone fichas de decisión UX. En esta sesión no ejecuta commits ni merges, porque el sistema de
  permisos se lo bloquea.
- **Codex:** ejecuta los pasos de Git y la implementación con acceso a la copia local; revisa
  especificaciones y reporta errores antes de implementar.
- **ChatGPT web:** apoyo y auditorías.

## 4. Pasos definitivos, en orden

### Etapa 1 — Proteger y estabilizar (ahora; alcance autorizado)

| # | Paso | Quién | Referencia | Condición para avanzar |
|---|---|---|---|---|
| 1.1 | Respaldo verificado + copia fuera del Mac | **✅ Completado 15/10:** copia creada por Claude, subida a Drive por el owner y verificada por Claude. Codex no lo repite | handoff §2 | 408 archivos ignorados + personales + carpeta de planificación + instantánea del merge; SHA-256 OK; copia externa confirmada |
| 1.2 | Cerrar el merge local (sin push) | Codex | handoff §3 | Árbol = develop antes del commit; 2 padres; sin diferencias con develop |
| 1.3 | Versionar los documentos de planificación (rama `fix/docs-v1-release-program`, Block 770) → PR → merge | Codex; Claude revisa | handoff §3b | Solo esta carpeta + `docs/dev_log.md`; push inmediato; **mergear antes del 1.4** |
| 1.4 | BUG-036: fix de test + docs (Block 771) → PR | Codex; Claude revisa | handoff §4 | 219/219 **en la rama real**, registrado; solo cambian el test y 3 docs |
| 1.5 | Integración: traer develop + Block 772 → PR → merge commit | Codex; Claude revisa | handoff §5 | Árbol = develop antes del bloque; después, solo `docs/dev_log.md`; 219/219 |
| 1.6 | Verificaciones posteriores | Codex | handoff §5.4 | `main` contenido en `develop`; 0 commits exclusivos de `main`; 219/219 en develop |

### Etapa 2 — Documentación (cada PR con su propia aprobación)

| # | Paso | Depende de |
|---|---|---|
| 2.1 | D1 trazabilidad: roadmap reestructurado; RVP-075 a 087 en el ledger; BUG-037 a 040 pendientes de reproducción; hashes; IDEA-034; logs reubicados con nombre normativo | Aprobación de D1; etapa 1 terminada |
| 2.2 | D2 reglas de proceso: roles, AP-4, suite completa, puntos seguros y recuperación, rigor por riesgo, validación periódica sin rebajar R3, protocolo prod-debug, logs | Aprobación de D2 |
| 2.3 | Configuración local de VS Code "prod-debug" | Aprobación del owner |

### Etapa 3 — Revisión UX con el owner (puede empezar ya: la app funciona en Local y en Cuenta)

Orden de las sesiones. Cada una produce una ficha con estado actual, problemas, 2–3 alternativas,
recomendación, coste y riesgo:

1. Primer uso y Task List: estado vacío, explicar Local/Cuenta, selección y Next, título y AppBar.
2. Run Mode: indicador de pausa, barra de grupo, hora del sistema, banner o modal al terminar,
   responsive en horizontal e iPad.
3. Selección → Plan Group → aviso de integridad (presentación "brusca" de las opciones).
4. Groups Hub: finalidad y nombre, secciones, tarjetas, nombre de grupo.
5. Task Editor: pulido estético, autofoco, tarjeta (checkbox o toque, círculos, tiempo total).
6. Settings y cuenta: eliminación de cuenta, privacidad, soporte, versión; quitar las opciones
   desactivadas.
7. Login: propuesta de valor, logo, Apple + Google + GitHub, errores comprensibles.
8. Identidad visual: icono, nombre, logo y pantalla de arranque.

**Spike técnico de pestañas** (Codex + Claude, ~1 día) antes de decidir. Debe validar:
- botón atrás;
- apertura automática;
- conservación del estado;
- cambio entre Local y Cuenta;
- continuidad de la sesión, incluidos los servicios persistentes de temporizador y sincronización.

Salida de la etapa: fichas aprobadas → **D3** (specs v1.0) → **congelación del alcance** con la
matriz de 42 ideas decidida.

### Etapa 4 — Implementación por tareas atómicas

- Cada tarea lleva handoff con archivos permitidos y prohibidos, rigor según su nivel de riesgo
  (R0–R3), suite completa y revisión del PR por Claude.
- La i18n (inglés/español) se hace después de revisar los textos en inglés.
- El responsive para iPad y horizontal va antes de las capturas de tienda.

### Etapa 5 — Bloqueantes técnicos (en paralelo con la etapa 4)

- Lista de regresión RVP-075 a 087.
- BUG-037 a 040: reproducir y decidir.
- Prueba en modo avión con Firebase real.
- Cierre forzado y reapertura en frío durante una sesión.
- `onTimeout` del servicio en primer plano en Android 15.
- Firma de release (keystore de subida + copia).

### Etapa 6 — Requisitos de tiendas

- Eliminación de cuenta (Apple 5.1.1(v), Google Play) dentro de la app y por web.
- Política de privacidad, Data safety y App Privacy.
- Sign in with Apple.
- Icono y marca.
- Staging configurado antes del lanzamiento.
- Tipo de cuenta de Play (prueba cerrada de 14 días con 12 testers si aplica).
- Fichas de tienda en inglés y español; capturas de iPhone, iPad y Android.

### Etapa 7 — Usuarios

- 5 sesiones de usabilidad con los criterios de los recorridos 1–8.
- Comentarios de la prueba cerrada de Play.

### Etapa 8 — Regresión y versión candidata

- Congelación del código.
- Regresión completa en release en todas las plataformas.
- Soak de 4 h o más con refresco de token.
- `develop → main` solo con cero P0/P1 abiertos.

### Etapa 9 — Publicación

- Envíos y ciclos de revisión.
- Lanzamiento escalonado en Play.
- Monitorización.
- Procedimiento de hotfix.

## 5. Hechos establecidos (15/10)

- **Entorno:** los fallos del 14/10 se debían a ejecutar debug con `APP_ENV=dev` sin emuladores.
- **Cuenta con Firebase real:** funciona en iOS y en Android (logs; login confirmado en el log de
  Android).
- **Local y Samsung físico:** funcionan (comprobación manual del owner, sin log).
- **Pendientes de verificación:** cierre en frío durante una sesión y el bucle de Run Mode sin backend.
- **Suite:** `flutter analyze` PASS; 217/2 en develop. El fix de BUG-036 está validado en una copia
  aislada con 219/219 y debe repetirse en la rama real.

## 6. Seguimiento de la etapa 1 (Codex, 15/10/2026)

**Current branch intent:** Process docs — version the approved planning artifacts without applying D1/D2/D3 or changing runtime behavior.

| Paso | Estado y evidencia |
|---|---|
| 1.1 Respaldo | Completado previamente por Claude y el owner. Codex verificó de nuevo las tres sumas SHA-256 locales: OK; no se repitió el respaldo ni la subida. |
| 1.2 Merge local | Completado: `9605f4ffc93c79f57d84a6815b074714ef317697`, `merge(git): integrate origin/main into develop lineage (PR #159/#160 ancestry)`. Padres: `ff30e15` y `65552c4`. Árbol: `89374764fc36ce853968b224390d7558cd4528df`, idéntico a `develop`. Solo en `fix/sync-main-into-develop`, sin push. |
| 1.3 Documentación | Preparada para revisión en `fix/docs-v1-release-program`, desde `develop` (`ff30e15`). Commit de contenido: `2f5ddf0e4743d573d5fc6c674a40ea2cb6ed2300`, `docs(v1-release): add v1.0 store-release program plan, Stage 1 handoff and doc-reconciliation proposal`. El PR se detiene antes del merge para revisión de Claude. D1/D2/D3 siguen sin aprobar ni aplicar. |
| 1.4 BUG-036 | Pendiente del merge del PR documental. Los dos tests siguen sin modificar; el 219/219 todavía no se ha comprobado en la rama real. |
| 1.5–1.6 Integración y verificación | Pendientes de los PRs anteriores y de sus revisiones. `main` y `develop` no se han movido. |

No se versionan `respuesta-claude.md`, los archivos personales de la raíz ni `docs/nuevas-funcionalidades/`.
Los dos stashes preexistentes permanecen intactos.

Verificación del paso documental: `flutter analyze --no-pub` PASS (`No issues found!`, 37.8 s);
`git diff --cached --check -- '*.md'` PASS; ámbito previsto de siete archivos comprobado; ningún cambio en código, tests,
configuración ni documentos canónicos aparte del bloque 770 y la fecha del dev_log. La suite completa
conserva su resultado previo de 217 PASS / 2 FAIL; no se ha repetido para estos cambios documentales.
Los tres logs conservan sus bytes originales, incluidos los espacios finales emitidos por Flutter;
se excluyen de la normalización de formato para preservar la evidencia.

## 7. Próximas acciones inmediatas

1. Codex: revisar este plan, `codex_handoff.md` y (si quiere) `docs_reconciliation_proposal.md`; confirmar o corregir;
   ejecutar la etapa 1 en orden (1.1 → 1.6), deteniéndose antes de cada merge para la revisión de Claude.
2. Owner: copiar el respaldo fuera del Mac y confirmarlo; revisar la propuesta documental y la matriz de ideas;
   decidir sobre "prod-debug". (Publicar los logs y mantener el repo público: aprobado el 15/10.)
3. Claude: revisar cada PR de la etapa 1 antes del merge; preparar la ficha de la sesión UX 1.
