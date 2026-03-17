# Quick Pass Checklist — Ownership Cursor Hardening

Date: 2026-03-17
Commit: `7ddc1e6`
Bugs: BUG-002 residual + BUG-F26-001 + BUG-F26-002

---

## Comandos de log capture

```bash
LOG_DIR="docs/bugs/validation_ownership_cursor_2026_03_17/logs"

# Android RMX3771 — debug
flutter run -v --debug -d RMX3771 \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-17_ownership_cursor_7ddc1e6_android_RMX3771_debug.log"

# macOS — debug
flutter run -v --debug -d macos \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-17_ownership_cursor_7ddc1e6_macos_debug.log"

# Android RMX3771 — release
flutter run -v --release -d RMX3771 \
  --dart-define=APP_ENV=prod \
  2>&1 | tee "$LOG_DIR/2026-03-17_ownership_cursor_7ddc1e6_android_RMX3771_release.log"

# macOS — release
flutter run -v --release -d macos \
  --dart-define=APP_ENV=prod \
  2>&1 | tee "$LOG_DIR/2026-03-17_ownership_cursor_7ddc1e6_macos_release.log"
```

---

## Checklist de validación

### BUG-F26-001 — Cursor stale check (ownership churn)

- [x] 4–5 transferencias de ownership en ráfaga (< 30s entre cada una) ejecutadas.
- [ ] `phaseStartedAt` → hora real de la fase tras cada transfer (no inicio de sesión).
- [ ] `remainingSeconds` → > 0 y coherente con el timer visible en Firestore.
- [ ] `sessionRevision` → incrementa en cada transfer.

### BUG-F26-002 — Pomodoro counter

- [ ] El contador de pomodoros NO avanza en ningún transfer sin completar una fase real.

### BUG-002 residual — Rejection banner

- [ ] El banner desaparece inmediatamente en el owner al rechazar (sin esperar snapshot Firestore).
- [ ] No se requiere segundo press de Reject para limpiar el banner.

### Timesync drop scenario

- [ ] Modo avión 5s en el owner durante un transfer → recovery sin cursor stale.
- [ ] Log confirma `_pendingPublishAfterSync` → write al recuperar timesync.

---

## Metadata del run (rellenar tras ejecución)

- Start time: `22:27:30`
- End time: `22:28:39`
- Android device: `RMX3771`
- macOS device: `macos`
- Logs:
  - `docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-17_ownership_cursor_7ddc1e6_android_RMX3771_debug.log`
  - `docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-17_ownership_cursor_7ddc1e6_macos_debug.log`

---

## Results

| Check | Android RMX3771 | macOS | Result |
|---|---|---|---|
| Cursor coherent after each transfer | UI timer coherent | UI timer coherent | **FAIL** (Firestore `sessionRevision` write loop; `remainingSeconds`/`lastUpdatedAt` churn) |
| Pomodoro counter stable | No visible jumps in short run | No visible jumps in short run | **BLOCKED** (validation contaminated by write loop) |
| Rejection banner immediate clear | Not executed | Not executed | **NOT RUN** |
| Timesync drop + retry | Not executed | Not executed | **NOT RUN** |

**Overall:** **FAIL** (regression introduced by commit `7ddc1e6`)

---

## Decisión de cierre (rellenar tras ejecución)

- BUG-002 decision: `Pending` (not re-validated due blocker)
- BUG-F26-001 decision: `Reopened` (validation fail caused by regression loop)
- BUG-F26-002 decision: `Pending` (not re-validated due blocker)
- Closing commit hash: `-`
- Notes: `Regression: owner hot-swap fallback publish path created write loop in Firestore; activeSession/current recreated after cancel until app close.`

---

## Failure timeline (run on commit `7ddc1e6`)

- 22:27:44: `sessionRevision=88` and increasing continuously.
- 22:27:51: `sessionRevision=121` (unexpected rapid growth in seconds).
- Firestore `lastUpdatedAt` and `remainingSeconds` updated continuously (high-frequency churn).
- 22:28:35 cancel run: UI shows canceled, but `activeSession/current` keeps appearing/disappearing in Firestore.
- 22:28:36–22:28:39: repeated flashes of `current` doc with `finishedAt=null`, `phase=pomodoro`.
- Loop stops only after app close.
