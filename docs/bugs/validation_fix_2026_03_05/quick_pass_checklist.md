# Lista de verificacion rapida — Correccion de validacion 2026-03-05

Alcance: notice clamp, owner pausa re-entry jump, overlaps falsos en Local → Account.

## Preparacion
1. Owner iOS + mirror Chrome (Account Mode).
2. Asegurate de que no haya grupos en ejecucion.
3. Guarda capturas en `docs/bugs/validation_fix_2026_03_05/screenshots/`.

## Validaciones (pendiente de implementacion)
1. Notice clamp aplicado al grupo (Fix 23).
2. Owner no re-suma pausa al volver al Timer Run (Fix 24).
3. Local → Account sin overlaps falsos; request ownership llega (Fix 25).

## Regression checks
1. Auto-open gating: durante Plan group no reabre Run Mode; en resume auto-open ocurre una sola vez.
2. iOS notice 0: programado notice 0 sin pantalla negra.
3. Local Mode: "Open Run Mode" no reinicia el grupo running.
4. Completion: tras el modal de completion vuelve a Groups Hub.
