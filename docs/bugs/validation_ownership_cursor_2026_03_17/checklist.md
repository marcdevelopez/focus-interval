# Validation Checklist — Ownership Cursor Hardening (commit `7ddc1e6`)

Date: 17/03/2026
Branch: `fix-ownership-cursor-stamp`
Bugs: BUG-002 residual + BUG-F26-001 + BUG-F26-002
Devices: Android RMX3771 + macOS

---

## Commands

```bash
LOG_DIR="docs/bugs/validation_ownership_cursor_2026_03_17/logs"

# Android RMX3771 — debug (prod Firebase)
flutter run -v --debug -d RMX3771 \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-17_ownership_cursor_7ddc1e6_android_RMX3771_debug.log"

# macOS — debug (prod Firebase)
flutter run -v --debug -d macos \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-17_ownership_cursor_7ddc1e6_macos_debug.log"

# Android RMX3771 — release (prod)
flutter run -v --release -d RMX3771 \
  --dart-define=APP_ENV=prod \
  2>&1 | tee "$LOG_DIR/2026-03-17_ownership_cursor_7ddc1e6_android_RMX3771_release.log"

# macOS — release (prod)
flutter run -v --release -d macos \
  --dart-define=APP_ENV=prod \
  2>&1 | tee "$LOG_DIR/2026-03-17_ownership_cursor_7ddc1e6_macos_release.log"
```

---

## Protocolo de validación (ownership churn stress)

Con ambos dispositivos corriendo el mismo grupo activo:

### BUG-F26-001 — Cursor stale check
- [ ] Hacer 4–5 transferencias de ownership en ráfaga (< 30s entre cada una).
- [ ] En Firestore verificar tras cada transfer:
  - `phaseStartedAt` → hora real de la fase actual (no el inicio de la sesión)
  - `remainingSeconds` → > 0 y coherente con el timer visible
  - `sessionRevision` → incrementa en cada transfer

### BUG-F26-002 — Pomodoro counter
- [ ] El contador de pomodoros NO avanza en ningún transfer sin completar una fase real.

### BUG-002 residual — Rejection banner
- [ ] El banner de rejection desaparece inmediatamente en el owner al rechazar (sin esperar el snapshot Firestore).
- [ ] No se requiere segundo press de Reject para limpiar el banner.

### Timesync drop scenario
- [ ] Simular modo avión 5s en el owner durante un transfer → recovery.
- [ ] Verificar que `_pendingPublishAfterSync` dispara el write al recuperar.

---

## Log analysis — quick scan

```bash
LOG_ANDROID="docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-17_ownership_cursor_7ddc1e6_android_RMX3771_debug.log"
LOG_MACOS="docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-17_ownership_cursor_7ddc1e6_macos_debug.log"

# Verify cursor stamp on ownership transfer
grep -E "cursorSnapshot|publishCurrentSession|pendingPublishAfterSync|shouldHydrate|hotSwap|bumpSessionRevision" "$LOG_ANDROID" "$LOG_MACOS"

# Check for stale cursor signals
grep -E "remainingSeconds.*0|phaseStartedAt.*null|Syncing session" "$LOG_ANDROID" "$LOG_MACOS"

# Banner optimistic clear
grep -E "clearOwnershipRequest|notifySessionMeta|ownershipRequest.*null|bannerClear" "$LOG_ANDROID" "$LOG_MACOS"
```

---

## Results

| Check | Android RMX3771 | macOS | Result |
|---|---|---|---|
| Cursor coherent after each transfer | | | |
| Pomodoro counter stable | | | |
| Rejection banner immediate clear | | | |
| Timesync drop + retry | | | |

**Overall:** PASS / FAIL / PARTIAL

---

## Closure criteria

- All 4 checks PASS on both devices → BUG-002, BUG-F26-001, BUG-F26-002 → Closed/OK
- Update `validation_ledger.md` with `closed_commit_hash: 7ddc1e6` and evidence.
