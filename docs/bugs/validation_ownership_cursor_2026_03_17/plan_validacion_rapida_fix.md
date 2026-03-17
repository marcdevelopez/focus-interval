# Plan — Rapid Validation (Ownership Cursor Hardening)

Date: 2026-03-17
Branch: `fix-ownership-cursor-stamp`
Commit: `7ddc1e6` (validation FAIL)
Bugs: BUG-002 residual + BUG-F26-001 + BUG-F26-002
Devices: Android RMX3771 + macOS

---

## Objetivo

Confirmar que los tres bugs relacionados con el cursor de sesión durante ownership churn
quedan resueltos con el commit `7ddc1e6`.

---

## Estado actual (post-validación 17/03/2026)

`7ddc1e6` **NO es cerrable**. La validación en dispositivos detectó una regresión crítica:

- `sessionRevision` sube en bucle (88→121 en ~7s).
- `lastUpdatedAt` y `remainingSeconds` se reescriben continuamente.
- Tras cancelar el grupo, el documento `activeSession/current` se recrea y elimina
  en loop hasta cerrar la app.

Root cause confirmado en código:

- El fallback publish añadido para hot-swap owner en
  `PomodoroViewModel._applySessionTimelineProjection` ejecuta
  `_bumpSessionRevision()+_publishCurrentSession()` en snapshots repetidos sin
  guardia one-shot por ownership acquisition.
- Ese path genera feedback loop Firestore→VM→Firestore.

Follow-up patch aplicado (pendiente de commit y revalidación):

- Campo nuevo `_hotSwapPublishedForRevision` en `PomodoroViewModel`.
- Fallback publish protegido para ejecutarse solo una vez por revision/handoff.
- Reset del guard en `_resetLocalSessionState` y cambio de modo.
- Test nuevo: `owner hot-swap fallback publish is one-shot for repeated snapshots`
  en `pomodoro_view_model_session_gap_test.dart`.

Local validation del follow-up patch:

- `flutter analyze` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → PASS
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart` → PASS

---

## Contexto y root causes

### BUG-F26-001 — Cursor stale en Firestore tras ownership transfer

**Causa raíz:** Triple condición de fallo simultáneo:
1. `remainingSeconds: 0` ya persistido en Firestore (sesión del owner anterior).
2. Churn rápido de ownership (< 30s entre transfers) que impide que el heartbeat normal
   actualice el cursor.
3. `isTimeSyncReady=false` en el momento exacto del claim — `_publishCurrentSession()`
   hace drop silencioso sin retry.

**Gap estructural principal:** El gate `shouldHydrate` (PomodoroViewModel líneas 1605–1610)
solo dispara `_publishCurrentSession()` cuando `_machine.state.status == idle`. En un
mirror→owner hot-swap (machine ya corriendo), el gate se salta completamente y el cursor
nunca se publica para el nuevo owner.

### BUG-F26-002 — Pomodoro counter avanza en transfers sin completar fase

**Causa raíz:** Mismo cursor stale — si `currentPomodoro` es incoherente en el snapshot
que se publica tras el hot-swap, el counter puede reflejar un valor incorrecto.

### BUG-002 residual — Banner de rejection no se limpia inmediatamente

**Causa raíz:** `rejectOwnershipRequest()` esperaba la ronda Firestore antes de actualizar
el estado local. El owner veía el banner hasta que llegaba el snapshot de confirmación
(hasta ~30s en worst case) y a veces requería un segundo press de Reject.

---

## Cambios implementados (commit `7ddc1e6`)

1. **Atomic cursor stamp en `respondToOwnershipRequest(approved: true)`**
   - `PomodoroSession.toCursorMap()` — nuevo método con todos los campos de cursor
     (phase, phaseStartedAt, remainingSeconds, currentPomodoro, totalPomodoros,
     phaseDurationSeconds, accumulatedPausedSeconds).
   - Firestore transaction incluye el cursor snapshot atómicamente junto con ownerDeviceId
     y sessionRevision.

2. **Fallback publish cuando machine es non-idle en el hot-swap**
   - `shouldHydrate` gate: rama `else if (_machine.state.status != idle)` ahora llama
     `_bumpSessionRevision()` + `_publishCurrentSession()` directamente.

3. **`_pendingPublishAfterSync` — retry tras timesync recovery**
   - Si `_publishCurrentSession()` hace drop por `isTimeSyncReady=false`, activa el flag.
   - `_refreshTimeSyncIfNeeded()` comprueba el flag tras sync exitoso y replay el publish.

4. **Optimistic banner clear para rejection**
   - `rejectOwnershipRequest()` llama `_clearOwnershipRequestLocallyForOwner()` +
     `_notifySessionMetaChanged()` inmediatamente, antes del round-trip Firestore.

---

## Protocolo de validación (ownership churn stress)

Con ambos dispositivos corriendo el mismo grupo activo:

### Escenario A — BUG-F26-001: Cursor coherente tras cada transfer

1. Hacer 4–5 transferencias de ownership en ráfaga (< 30s entre cada una).
2. En Firestore verificar tras cada transfer:
   - `phaseStartedAt` → hora real de la fase actual (no el inicio de la sesión)
   - `remainingSeconds` → > 0 y coherente con el timer visible
   - `sessionRevision` → incrementa en cada transfer

### Escenario B — BUG-F26-002: Pomodoro counter estable

- El contador de pomodoros NO avanza en ningún transfer sin completar una fase real.

### Escenario C — BUG-002 residual: Banner immediate clear

- El banner de rejection desaparece inmediatamente en el owner al rechazar
  (sin esperar el snapshot Firestore).
- No se requiere segundo press de Reject para limpiar el banner.

### Escenario D — Timesync drop scenario

- Simular modo avión 5s en el owner durante un transfer → recovery.
- Verificar que `_pendingPublishAfterSync` dispara el write al recuperar.

---

## Comandos de ejecución

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

## Log analysis — quick scan

```bash
LOG_ANDROID="docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-17_ownership_cursor_7ddc1e6_android_RMX3771_debug.log"
LOG_MACOS="docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-17_ownership_cursor_7ddc1e6_macos_debug.log"

# Verificar cursor stamp en ownership transfer
grep -E "cursorSnapshot|publishCurrentSession|pendingPublishAfterSync|shouldHydrate|hotSwap|bumpSessionRevision" "$LOG_ANDROID" "$LOG_MACOS"

# Señales de cursor stale
grep -E "remainingSeconds.*0|phaseStartedAt.*null|Syncing session" "$LOG_ANDROID" "$LOG_MACOS"

# Banner optimistic clear
grep -E "clearOwnershipRequest|notifySessionMeta|ownershipRequest.*null|bannerClear" "$LOG_ANDROID" "$LOG_MACOS"
```

---

## Criterios de cierre

- Escenarios A, B, C, D PASS en ambos dispositivos:
  → BUG-002, BUG-F26-001, BUG-F26-002 → Closed/OK
- Actualizar `validation_ledger.md` con `closed_commit_hash: 7ddc1e6` y evidencia.
