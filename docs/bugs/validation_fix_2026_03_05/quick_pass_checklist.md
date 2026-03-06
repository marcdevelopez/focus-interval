# Lista de verificacion rapida — Correccion de validacion 2026-03-05

Alcance: notice clamp, owner pausa re-entry jump, overlaps falsos en Local → Account.

Gate:
- Feature work is blocked until Fix 24 + Fix 25 + regression checks pass.
- A fix is marked **Closed/OK** automatically once Exact Repro + Regression checks
  pass and evidence is recorded.

## Preparacion
1. Owner iOS + mirror Chrome (Account Mode).
2. Asegurate de que no haya grupos en ejecucion.
3. Guarda capturas en `docs/bugs/validation_fix_2026_03_05/screenshots/`.

## Validaciones
1. [x] Notice clamp aplicado al grupo (Fix 23) — **Closed/OK** (06/03/2026).
   Evidence: in-session validation (owner iOS + mirror Chrome), attach set from
   20:21:30–20:22:10 showing:
   - auto-clamp applied to planned group notice,
   - scheduling succeeds (no "too soon" block),
   - `Apply globally` action updates global notice,
   - planned group visible in Groups Hub with effective pre-run.
2. [ ] Owner no re-suma pausa al volver al Timer Run (Fix 24).
3. [ ] Local → Account sin overlaps falsos; request ownership llega (Fix 25).

## Regression checks
1. [x] Auto-open gating: durante Plan group no reabre Run Mode; en resume auto-open ocurre una sola vez.
2. [x] iOS notice 0: programado notice 0 sin pantalla negra.
3. [x] Local Mode: "Open Run Mode" no reinicia el grupo running.
4. [x] Completion: tras el modal de completion vuelve a Groups Hub.
