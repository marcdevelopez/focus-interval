# Lista de verificacion rapida — Correccion 2026-03-02

Fecha: 2026-03-02
Scope: TimeSync deadlock + auth gating (Account Mode, web/mac).

## Exact Repro (ejecutado)
- [x] Chrome debug + prod override: login con Google, Start now en grupo running.
- [x] Verificar que no aparece "Syncing session..." y que `sessionRevision` sube.
- [x] `users/{uid}/timeSync/anchor` creado con `serverTime` y `updatedAt`.

## Regression smoke check
- [x] Chrome debug + prod override arranca en Account Mode sin pantalla negra.
- [x] macOS debug + prod override arranca en Account Mode.
- [x] `activeSession/current.lastUpdatedAt` avanza (~30s) en web.
- [x] TimeSync anchor visible en Firestore (serverTime/updatedAt actuales).
- [x] Overlay "Syncing session..." no aparece al iniciar.

## Evidencia
- Log: `docs/bugs/validation_fix_2026_03_02-02/logs/2026-03-02_web_chrome_debug.log`.
- Firestore snapshot: sessionRevision=3, lastUpdatedAt=2026-03-02 03:08:40 UTC+1.
