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
2. [x] Owner no re-suma pausa al volver al Timer Run (Fix 24) — **Closed/OK** (06/03/2026).
   Evidence:
   - Logs:
     - `docs/bugs/validation_fix_2026_03_05/logs/2026_03_06_fix24_ios_debug.log`
     - `docs/bugs/validation_fix_2026_03_05/logs/2026_03_06_fix24_chrome_debug.log`
   - Screenshots:
     - `docs/bugs/validation_fix_2026_03_05/screenshots/2026_03_06_fix24_validation_and_fix26_discovery/fix24_pass/fix24_pass_01.png`
     - `docs/bugs/validation_fix_2026_03_05/screenshots/2026_03_06_fix24_validation_and_fix26_discovery/fix24_pass/fix24_pass_02.png`
     - `docs/bugs/validation_fix_2026_03_05/screenshots/2026_03_06_fix24_validation_and_fix26_discovery/fix24_pass/fix24_pass_03.png`
     - `docs/bugs/validation_fix_2026_03_05/screenshots/2026_03_06_fix24_validation_and_fix26_discovery/fix24_pass/fix24_pass_04.png`
     - `docs/bugs/validation_fix_2026_03_05/screenshots/2026_03_06_fix24_validation_and_fix26_discovery/fix24_pass/fix24_pass_05.png`
3. [ ] Local → Account sin overlaps falsos; request ownership llega (Fix 25).

## New finding (outside Fix 24 scope)
- [x] Fix 26 — Mirror/owner no queda en `Syncing session...` tras cancel y en
  recovery de background (Closed/OK, 06/03/2026).
  Evidence:
  - Logs:
    - `docs/bugs/validation_fix_2026_03_05/logs/2026_03_06_fix26_ios_debug.log`
    - `docs/bugs/validation_fix_2026_03_05/logs/2026_03_06_fix26_chrome_debug.log`
  - Screenshots: not required (PASS flow with no visible error states).

## Regression checks
1. [x] Auto-open gating: durante Plan group no reabre Run Mode; en resume auto-open ocurre una sola vez.
2. [x] iOS notice 0: programado notice 0 sin pantalla negra.
3. [x] Local Mode: "Open Run Mode" no reinicia el grupo running.
4. [x] Completion: tras el modal de completion vuelve a Groups Hub.
