# Lista de verificacion rapida — Correccion de validacion 2026-02-25

Alcance: cancelacion de cola late-start, limite de pre-run, re-plan Start now, ruta de completado, logout Android, filas programadas, alineacion de rangos.

## Preparacion
1. Usa Account Mode con dos dispositivos: macOS como owner y Android como mirror.
2. Asegurate de que no haya grupos en ejecucion. Abre Groups Hub en ambos dispositivos.
3. Guarda las capturas en docs/bugs/validation_fix_2026_02_25/screenshots.

## Validaciones
1. Late-start queue Cancel all (nuevo contexto)
Programa dos grupos con notice = 1 minuto, separados por 1–2 minutos.
Abre la app cuando el **primer grupo ya este vencido** y el segundo aun no (entrara en late-start en 1–2 minutos).
Espera a que ambos aparezcan en la cola late-start en el owner.
Pulsa Cancel all en owner.
Esperado: El mirror muestra el modal "Owner resolved" y el owner no.
Esperado: El modal se cierra con OK sin necesidad de tocar fuera.
Esperado: El mirror no puede continuar resolviendo overlaps ni actuar como owner tras Cancel all.

2. Limite de pre-run
Arranca un grupo running que termina exactamente cuando inicia el pre-run del siguiente (notice > 0).
Esperado: No aparece el modal de conflicto cuando el fin coincide con el inicio del pre-run; solo debe aparecer si el solapamiento supera el grace de 1 minuto.

3. Re-plan Start now
Desde Groups Hub, usa Run again o Re-plan en un grupo completed/canceled y elige Start now.
Si existe un grupo running, acepta la cancelacion.
Esperado: La app navega a Run Mode del nuevo grupo (no se queda en Groups Hub).

4. Navegacion tras completar
Completa un grupo en owner.
Esperado: Tras el dialogo de completion, la app vuelve a Groups Hub (nunca la pantalla Ready).

5. Logout Android pantalla negra
En Android: Timer Run -> Groups Hub -> Task List -> logout en AppBar.
Esperado: No hay pantalla negra; el logout navega correctamente (igual que Chrome).

6. Filas programadas owner/mirror
Con noticeMinutes > 0, ambos dispositivos muestran "Pre-Run X min starts at HH:mm".
Con noticeMinutes = 0, la fila Pre-Run se omite en ambos dispositivos.

7. Rangos de tareas vs status boxes
En Run Mode, compara los rangos de tiempo de cada task con los rangos de las status boxes tras pre-run/ownership transitions.
Esperado: Los rangos coinciden exactamente, sin desfase de 1 minuto.

8. Rebote de Run Mode (Start now / Run again / programado)
Account Mode: Start now desde Task List.
Esperado: Abre Run Mode y se mantiene ahi (no vuelve a Groups Hub).
Account Mode: Run again desde Groups Hub (grupo completed -> Start now).
Esperado: Abre Run Mode y se mantiene ahi.
Account Mode: Programado con notice 0 a 2-3 minutos.
Esperado: Al llegar la hora abre Run Mode y se mantiene ahi.
Local Mode: Start now desde Task List.
Esperado: Abre Run Mode y se mantiene ahi.
Local Mode: Programado con notice 0 a 2-3 minutos.
Esperado: Al llegar la hora abre Run Mode y se mantiene ahi.

Resultados (26/02/2026)
Account Mode (Android): Start now OK, Run again OK.
Account Mode (Android): Programado notice 0 (15:27). Resultado: rebote a Groups Hub; Run Mode solo abre con "Open Run Mode".
Local Mode (macOS): Start now OK.
Local Mode (macOS): al re-planificar, notice estaba en 5 min y se ajusto a 0 min para programar a 15:28.
Programado (15:28): en ambos dispositivos se abre Groups Hub y no se queda en Run Mode; Run Mode abre manual con "Open Run Mode".
Logs: ver docs/bugs/validation_fix_2026_02_25/logs/2026-02-26_android_RMX3771_runmode.log y 2026-02-26_macos_runmode.log (Auto-start opening TimerScreen + auto-open suppressed).

Resultados (26/02/2026, Fix 12)
Account Mode (Android): Start now OK.
Account Mode (Android): Run again OK (se mantiene en Run Mode).
Account Mode (Android): activeSession/current creado mientras running (verificado).
Account Mode (Android): Programado notice 0 OK (abre en Run Mode; se ve intento de volver a Groups Hub pero termina quedando en Run Mode).
Account Mode (macOS): Re-plan group + Start now OK (abre Run Mode y se mantiene; aparece un carrusel breve de Groups Hub antes).
Logs: ver docs/bugs/validation_fix_2026_02_25/logs/2026-02-26_android_RMX3771_diag.log y 2026-02-26_macos_diag.log.

Resultados (26/02/2026, Paso 2 - Limite de pre-run)
macOS: running termina 21:19, programado 21:20 con notice 1 min.
Mensaje: "That time doesn't leave enough pre-run space because another group is still running."
Resultado: no deja planificar; FAIL del punto 2.

Resultados (26/02/2026, Paso 3 - Re-plan Start now)
Contexto: grupo running en macOS. En Android: Run again sobre un completed -> Start now.
Durante el modal "Conflict with running group... Cancel running group", se reabre automaticamente el Timer Run del grupo running antes de confirmar, impidiendo cancelar.
Segundo intento: se logra cancelar y abre Run Mode correcto, pero aparecen 3-4 pantallas de Groups Hub en cascada (carrusel visible).
Resultado: FAIL (auto-open interrumpe cancelacion + exceso de carrusel Groups Hub).

Resultados (26/02/2026, Paso 1 - Late-start queue, intento 1)
Programado G1 (19:01) y G2 (19:17) con notice 1 min; ambos vencidos al abrir la app.
macOS (owner inicial): no aparece Resolve overlaps ni modal de conflicto al abrir.
Android: Resolve overlaps aparece a las 19:05:31 (lateStartOwnerDeviceId = android-633ffb6b...).
Android: Cancel all ejecutado a las 19:06:21.
macOS: no aparece modal "Owner resolved" tras Cancel all; no muestra nada relacionado a los grupos (como si no existieran).
Resultado: falla el flujo esperado en mirror (no hay modal ni bloqueo).

Resultados (26/02/2026, Paso 1 - Late-start queue, intento 2 - Fix 14)
Validacion (Local -> Account con grupos overdue): Resolve overlaps aparece sin reiniciar la app en macOS y Android. Fix 14 validado con exito.

Resultados (27/02/2026)
Punto 4 (Navegacion tras completar): OK. Tras el dialogo de completion vuelve a Groups Hub (no aparece pantalla Ready).
Punto 5 (Logout Android pantalla negra): OK en macOS y Android (segun reporte).
Punto 6 (Filas programadas owner/mirror): OK en macOS y Android (segun reporte).
Punto 7 (Rangos de tareas vs status boxes): FAIL. Tras pausa/resume, las status boxes mueven el start (+1 min) mientras el item de tarea mantiene el rango correcto (ej.: 13:03-13:18 -> 13:04-13:19; tambien 14:17-14:33 -> 14:19-14:34).
Punto 8 (Rebote de Run Mode):
Account Mode: Start now OK; Run again OK.
Account Mode: Programado notice 0 FAIL (pantalla negra en iOS al confirmar; auto-apertura repetida de Run Mode interrumpe).
Local Mode: Start now FAIL (al abrir "Open Run Mode" reinicia el grupo; snackbar "Selected group not found" al entrar en Local).
Local Mode: Programado notice 0 FAIL (no inicia al llegar la hora y aparece error de pre-run aun con notice 0).

Resultados (28/02/2026, Fix 15 - Auto-open trigger gating)
- Sesion running -> entrar a Plan group -> no auto-open: OK.
- Pre-run / scheduled start -> auto-open: OK.
- App resume con sesion activa -> auto-open una vez: OK.
- Ir a Groups Hub / Task List mientras corre sesion -> no auto-open repetido: OK.

Resultados (28/02/2026, Fix 16 - iOS notice 0 black screen)
- Repro exacto (Account Mode, G1 running, programado notice 0 a 13:20, OK a las 13:10:55): OK.
- Sin pantalla negra y sin excepciones tipo setState after dispose / Using ref when unmounted en el log.

Resultados (28/02/2026, Fix 17 - Local Mode isolation + Run Mode stability)
Logs: docs/bugs/validation_fix_2026_02_25/logs/2026_02_28_ios_simulator_iphone_17_pro_diag.log y 2026_02_28_web_chrome_diag.log.
1. Chrome → Local Mode (sin cerrar app): OK (no aparece "Selected group not found").
2. Chrome Local → Plan group -> Start now: OK (Run Mode se mantiene; no rebota a Groups Hub).
3. Chrome Local → Groups Hub -> Open Run Mode: FAIL (reinicia el grupo cada vez).
4. Chrome Local → Rangos Run Mode vs Ends en Groups Hub: FAIL (no coinciden; Run Mode se recalcula con cada reinicio).
5. iOS → Local Mode (sin cerrar app mientras Account running): OK (sin snackbar "Selected group not found" ni "Loading group..." con controles).
6. iOS Local → Cancel: OK (sin datos cruzados de Account en Groups Hub).
7. Local Mode Settings → notice = 0 → programar by time (1–2 min): OK (no aparece error "too soon").

Resultados (28/02/2026, Fix 18 - Local Mode Open Run Mode no reinicia)
Logs: docs/bugs/validation_fix_2026_02_25/logs/2026_02_28_ios_simulator_iphone_17_pro_diag.log y 2026_02_28_web_chrome_diag.log.
1. Chrome Local → Plan group -> Start now: OK.
2. Chrome Local → Groups Hub -> Open Run Mode (varias veces): OK (no reinicia el grupo).
3. Chrome Local → Rangos Run Mode vs Ends en Groups Hub: OK (coinciden).

Regression checks (obligatorio tras cada fix)
1. Auto-open gating: durante Plan group no reabre Run Mode; en resume auto-open ocurre una sola vez.
2. iOS notice 0: confirmar programado notice 0 sin pantalla negra ni errores en log.
3. Local Mode: "Open Run Mode" no reinicia el grupo running.
4. Completion: tras el modal de completion la app vuelve a Groups Hub (nunca Ready).

Resultados (28/02/2026, Regression checks - Fix 18)
1. Auto-open gating: OK.
2. iOS notice 0: OK.
3. Local Mode Open Run Mode: OK.
4. Completion → Groups Hub: OK.

Resultados (28/02/2026, Fix 20 - Mirror initial sync drift)
Logs: docs/bugs/validation_fix_2026_02_25/logs/2026_02_28_ios_simulator_iphone_17_pro_diag.log y 2026_02_28_web_chrome_diag.log.
Repro: iOS owner running; Chrome mirror vuelve de Local → Account (o foreground tras ~10s).
Resultado: FAIL. El mirror arranca con desfase de segundos respecto al owner y se corrige en el siguiente snapshot.

Resultados (28/02/2026, Fix 21 - Mirror stale compensation attempt)
Repro: Owner en Chrome running; iOS mirror pasa a Local y vuelve a Account.
Resultado: FAIL. El mirror descuenta ~2s por tick (acelera) y el desfase crece hasta el siguiente snapshot (sincroniza temporalmente y vuelve a acelerar).

Resultados (28/02/2026, Fix 21 - Attempt 2)
Logs: docs/bugs/validation_fix_2026_02_25/logs/2026_02_28_ios_simulator_iphone_17_pro_diag.log y 2026_02_28_web_chrome_diag.log.
Repro: Chrome owner running. iOS mirror pasa a Local y vuelve a Account (queda casi en sync). Luego el owner (Chrome) pasa a Local y vuelve a Account.
Resultado: FAIL. El owner vuelve con ~24s menos que el mirror y el desfase sigue creciendo incluso con nuevos `lastUpdatedAt`. Al pulsar Cancel en owner, ambos se sincronizan al instante pero la sesión no se cancela (requiere un segundo cancel).

Resultados (28/02/2026, Fix 21 - Attempt 3)
Logs: docs/bugs/validation_fix_2026_02_25/logs/2026_02_28_ios_simulator_iphone_17_pro_diag.log y 2026_02_28_web_chrome_diag.log.
Repro: iOS owner running. iOS pasa a Local y vuelve a Account: FAIL (desfase). Chrome pasa a Local y vuelve a Account: FAIL (sin solucion). Chrome logs siguen incompletos tras launch.

Resultados (01/03/2026, Fix 22 P0-3)
Checklist de validacion multi-dispositivo: OK (segun reporte).
Notas: no se reportaron nuevos fallos; logs pendientes de adjuntar.

Notas adicionales (27/02/2026) — nuevos bugs observados (fuera del checklist)
1. Auto-open de Run Mode se re-dispara de forma periodica desde cualquier pantalla (Task List, Groups Hub, planificacion, modales). Interrumpe al usuario y reabre Run Mode aunque no haya accion directa.
2. Account Mode: programado notice 0 genera pantalla negra en iOS tras confirmar (imagenes 02–03). Logs: `_ios_simulator_iphone_17_pro_diag-1.log` y `2026_02_25_web_chrome_diag-1.log`. Reintento con logs `*_diag-2.log`.
3. Local Mode: al abrir aparece snackbar "Selected group not found" sin accion previa (imagenes 07 y 15). En iOS se queda en "Loading group..." con botones Pause/Cancel visibles.
4. Local Mode: "Open Run Mode" en Groups Hub reinicia el grupo cada vez (imagenes 09–10).
5. Local Mode: rangos de tiempo inconsistentes entre Run Mode y Groups Hub (ej.: item 14:20–16:15 vs Ends 16:13) (imagenes 11–12).
6. Local Mode: se cruzan datos con Account Mode (Groups Hub muestra Ends de un grupo de Account tras cancelar en Local) (imagen 17).
7. Local Mode: programado con notice 0 muestra snackbar de pre-run "too soon" (incoherente) (imagen 19).
8. Local Mode: Start now abre Run Mode pero termina en Groups Hub; "Open Run Mode" reinicia el grupo (imagen 20 / 29).
9. Account Mode: al volver desde Local, el mirror queda desincronizado unos segundos (timer distinto) y luego se corrige (imagenes 13–14).
10. Account Mode iOS: al cambiar a Account, el documento `current` desaparece y reaparece; Run Mode aparece y rebota varias veces a Groups Hub.
11. Planificacion: tras confirmar un grupo programado no aparece snackbar en Task List; solo se ve en Groups Hub (imagenes 26–27).
12. Conflicto: modal aparece al reanudar (no cuando falta 1 min) y el snackbar de "Postpone scheduled" aparece en Groups Hub, no en Run Mode (imagenes 30–31).
13. Account Mode notice 0: hay casos donde el grupo programado no inicia al llegar la hora, pero cuenta para overlaps (Android fisico).
14. Pausa + background: el tiempo pausado queda desfasado tras volver a foreground; se corrige al cambiar de owner.
15. Mirror: "Syncing session" se queda indefinidamente; requiere click o abrir Groups Hub para recuperar (macOS mirror, recurrente).

Features solicitadas (27/02/2026)
1. Modal de conflicto con informacion completa: grupo actual (nombre, inicio/fin, duracion) + grupo programado (inicio/fin, pre-run) en tarjetas y con scroll si no cabe.
2. Groups Hub debe indicar explicitamente cuando un grupo fue "postponed".
3. Snackbar de postponed con notice 0 no debe mostrar "pre-run at ..."; debe omitirlo o indicar "sin pre-run".
4. Plan group debe mostrar y permitir modificar el notice (pre-run) desde la misma pantalla.
5. Cuando un grupo nuevo comienza mientras aun se muestra el modal de completion del anterior, resaltar la tarjeta de running en Groups Hub (indicador visual).

## Notas de reproduccion previa (26/02/2026)
1. Account Mode: Start now crea activeSession y abre Run Mode tras un breve "Syncing session", pero al usar Run again vuelve rapido a Groups Hub.
2. Local Mode: Start now y Run again dejan la app en Groups Hub; Run Mode solo abre manualmente con "Open Run Mode".
3. Programado notice 0: permite programar y al iniciar hace flash de Run Mode pero regresa a Groups Hub.
