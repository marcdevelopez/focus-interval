# Lista de verificacion rapida — Correccion de validacion 2026-02-25

Alcance: cancelacion de cola late-start, limite de pre-run, re-plan Start now, ruta de completado, logout Android, filas programadas, alineacion de rangos.

## Preparacion
1. Usa Account Mode con dos dispositivos: macOS como owner y Android como mirror.
2. Asegurate de que no haya grupos en ejecucion. Abre Groups Hub en ambos dispositivos.
3. Guarda las capturas en docs/bugs/validation_fix_2026_02_25/screenshots.

## Validaciones
1. Late-start queue Cancel all
Crea dos grupos programados ya vencidos (notice = 1 minuto) para que aparezca la cola late-start en owner.
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

## Notas de reproduccion previa (26/02/2026)
1. Account Mode: Start now crea activeSession y abre Run Mode tras un breve "Syncing session", pero al usar Run again vuelve rapido a Groups Hub.
2. Local Mode: Start now y Run again dejan la app en Groups Hub; Run Mode solo abre manualmente con "Open Run Mode".
3. Programado notice 0: permite programar y al iniciar hace flash de Run Mode pero regresa a Groups Hub.
