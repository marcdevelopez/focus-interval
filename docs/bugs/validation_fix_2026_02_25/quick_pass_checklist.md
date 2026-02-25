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
