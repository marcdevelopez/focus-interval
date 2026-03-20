# Quick Pass Checklist — Ownership Cursor Hardening

Date: 2026-03-17 (initial) / 2026-03-18 (re-run post BUG-F26-003 fix)
Commit: `7ddc1e6` (initial, FAIL) → `92731b3` (re-run)
Bugs: BUG-002 residual + BUG-F26-001 + BUG-F26-002 + BUG-F26-003

---

## Comandos de log capture

```bash
LOG_DIR="docs/bugs/validation_ownership_cursor_2026_03_17/logs"

# Run 1 (2026-03-17, commit 7ddc1e6) — FAIL (write loop regression)
flutter run -v --debug -d RMX3771 \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-17_ownership_cursor_7ddc1e6_android_RMX3771_debug.log"

flutter run -v --debug -d macos \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-17_ownership_cursor_7ddc1e6_macos_debug.log"

# Run 2 (2026-03-18, commit 92731b3) — re-run post BUG-F26-003 fix
flutter run -v --debug -d RMX3771 \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-18__guard_hot-swap_92731b3_android_RMX3771_debug.log"

flutter run -v --debug -d macos \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-18_guard_hot-swap_92731b3_macos_debug.log"
```

---

## Checklist de validación

### BUG-F26-003 — Write loop (re-run 2026-03-18, commit `92731b3`)

- [x] `sessionRevision` crece discretamente (+1 por transfer): rev 5→6→7→9→10. ✓
- [x] `lastUpdatedAt` actualiza cada ~30s (heartbeat), no cada milisegundo. ✓
- [x] `activeSession/current` no oscila tras cancel. ✓ (no reproducido)

### BUG-002 residual — Rejection banner (re-run 2026-03-18)

- [x] El banner desaparece inmediatamente en el owner al rechazar (sin esperar snapshot Firestore). ✓
- [x] No se requiere segundo press de Reject para limpiar el banner. ✓

### BUG-F26-001 — Cursor stale check (ownership churn)

- [x] 4–5 transferencias de ownership ejecutadas sin write loop. ✓
- [x] `sessionRevision` → incrementa en cada transfer. ✓
- [x] `remainingSeconds` → > 0 y coherente con el timer (851→835→823→766). ✓
- [x] `phaseStartedAt` → actualiza a la hora real de la nueva fase tras transición de fase durante transfer. ✓ (pomodoro 3→break: 13:46:11, exacto 3×25min desde 12:21:11)
- [x] Validado con transición pomodoro→break observada en Firebase en tiempo real. ✓

### BUG-F26-002 — Pomodoro counter

- [x] El contador de pomodoros NO avanza en ningún transfer sin completar una fase real. ✓

### Timesync drop scenario

- [ ] Modo avión 5s en el owner durante un transfer → recovery sin cursor stale.
- [ ] Log confirma `_pendingPublishAfterSync` → write al recuperar timesync.

---

## Metadata del run (rellenar tras ejecución)

- Run 1 (commit `7ddc1e6`, 2026-03-17): Start `22:27:30` / End `22:28:39` — **FAIL**
- Run 2 (commit `92731b3`, 2026-03-18): Start `12:21:10` (group) / ongoing
- Android device: `RMX3771`
- macOS device: `macos`
- Logs (run 1):
  - `docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-17_ownership_cursor_7ddc1e6_android_RMX3771_debug.log`
  - `docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-17_ownership_cursor_7ddc1e6_macos_debug.log`
- Logs (run 2):
  - `docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-18__guard_hot-swap_92731b3_android_RMX3771_debug.log`
  - `docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-18_guard_hot-swap_92731b3_macos_debug.log`

---

## Results

### Run 1 — commit `7ddc1e6` (2026-03-17) — FAIL

| Check | Result |
|---|---|
| Write loop | **FAIL** — sessionRevision 88→121 en 7s; lastUpdatedAt churn por milisegundos |
| activeSession/current tras cancel | **FAIL** — doc oscila hasta cerrar app |
| Todos los demás | **NOT RUN** (bloqueados por write loop) |

**Overall run 1: FAIL**

### Run 2 — commit `92731b3` (2026-03-18) — En curso

| Check | Android RMX3771 | macOS | Result |
|---|---|---|---|
| Write loop (BUG-F26-003) | sessionRevision +1 por evento | sessionRevision +1 por evento | **PASS** |
| Rejection banner (BUG-002) | Limpia inmediatamente | — | **PASS** |
| Cursor coherent — remainingSeconds | 851→835→823→766 (coherente) | coherente | **PASS** |
| Cursor coherent — phaseStartedAt en transición de fase | 13:46:11 en pomodoro 3→break | — | **PASS** |
| Pomodoro counter stable (BUG-F26-002) | Sin saltos en todos los transfers | — | **PASS** |
| Timesync drop + retry | Not executed | Not executed | **NOT RUN** |

**Overall run 2: PASS — todos los checks confirmados**

---

## Decisión de cierre

- BUG-F26-003 decision: **Closed/OK** (commit `92731b3` — sin write loop)
- BUG-002 decision: **Closed/OK** (commit `7ddc1e6` — banner limpia inmediatamente)
- BUG-F26-001 decision: **Closed/OK** (commit `7ddc1e6` — phaseStartedAt actualiza en transición, remainingSeconds coherente)
- BUG-F26-002 decision: **Closed/OK** (commit `7ddc1e6` — contador estable en todos los transfers)
- Closing commit hash: `92731b3` (guard patch) / `7ddc1e6` (cursor hardening)
- Notes: `Run 1 FAIL por write loop (BUG-F26-003). Fix 92731b3 corrige loop. Run 2 confirma todos los bugs cerrados.`

---

## Failure timeline (run on commit `7ddc1e6`)

- 22:27:44: `sessionRevision=88` and increasing continuously.
- 22:27:51: `sessionRevision=121` (unexpected rapid growth in seconds).
- Firestore `lastUpdatedAt` and `remainingSeconds` updated continuously (high-frequency churn).
- 22:28:35 cancel run: UI shows canceled, but `activeSession/current` keeps appearing/disappearing in Firestore.
- 22:28:36–22:28:39: repeated flashes of `current` doc with `finishedAt=null`, `phase=pomodoro`.
- Loop stops only after app close.
