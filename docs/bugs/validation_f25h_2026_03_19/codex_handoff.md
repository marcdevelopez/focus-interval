# Codex Handoff — BUG-F25-H

**Branch:** crear `fix-f25-h-cancel-syncing-hold` desde `develop`.
**Reference commit:** `3cb2f6c` (baseline de diagnóstico)

**Regla obligatoria:** Leer `CLAUDE.md` secciones 3 (AP-1..AP-4) y 4 (G-1..G-6) antes de
implementar. Si algo en este handoff contradice esas reglas, PARAR y reportar a Claude
antes de continuar.

---

## Overview

Tres cambios quirúrgicos en tres archivos. Cada uno va en un commit separado.
Orden: Fix 0 → Fix 1 → Fix 2.

---

## Fix 0 — `lib/presentation/viewmodels/pomodoro_view_model.dart`

**Por qué:** `_resetLocalSessionState()` llama `_machine.cancel()` pero NO llama
`_timerService.stopTick()`. Si el timer sigue ticking cuando llega el primer null del
stream post-cancelación, `SessionSyncService._onSessionNull()` entra en el path de
debounce/hold en vez del quiet-clear path (gate: `timer.isTickingCandidate`). Agregar
`stopTick()` antes del reset garantiza `isTickingCandidate == false` cuando llega el null.

### Cambio 0a — `cancel()` (línea 881)

**Código actual:**
```dart
Future<void> cancel({String? reason}) async {
  if (!_controlsEnabled) return;
  _resetLocalSessionState();
  await _markGroupCanceled(reason: reason ?? TaskRunCanceledReason.user);
  await _sessionRepo.clearSessionAsOwner();
}
```

**Reemplazar con:**
```dart
Future<void> cancel({String? reason}) async {
  if (!_controlsEnabled) return;
  _timerService.stopTick();
  _resetLocalSessionState();
  await _markGroupCanceled(reason: reason ?? TaskRunCanceledReason.user);
  await _sessionRepo.clearSessionAsOwner();
}
```

### Cambio 0b — `applyRemoteCancellation()` (línea 888)

**Código actual:**
```dart
void applyRemoteCancellation() {
  _resetLocalSessionState();
}
```

**Reemplazar con:**
```dart
void applyRemoteCancellation() {
  _timerService.stopTick();
  _resetLocalSessionState();
}
```

**Restricción crítica:** NO agregar `stopTick()` dentro de `_resetLocalSessionState()`
— ese método también se llama en la transición owner→mirror (línea ~1647) donde el timer
no debe detenerse (lo re-proyecta `_setMirrorSession` inmediatamente después).

---

## Fix 1 — `lib/presentation/screens/timer_screen.dart`

**Por qué:** `pomodoroViewModelProvider` es un singleton global (no parametrizado por
groupId). Al navegar de G1 a G2, `_currentGroup` del VM aún tiene datos de G1
(status=canceled) en el primer frame de build de G2. El check en línea 680 dispara con
datos obsoletos → llama `_navigateToGroupsHub()` desde dentro de `build()` → excepción
Flutter assertion (`setState()/markNeedsBuild() called during build`, confirmada Chrome
log línea 2238) + `_cancelNavigationHandled = true` bloqueado permanentemente.

### Cambio (líneas 680–683)

**Código actual:**
```dart
    if (currentGroup?.status == TaskRunStatus.canceled &&
        !_cancelNavigationHandled) {
      _navigateToGroupsHub(reason: 'build canceled');
    }
```

**Reemplazar con:**
```dart
    if (currentGroup?.status == TaskRunStatus.canceled &&
        currentGroup?.id == widget.groupId &&
        !_cancelNavigationHandled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _navigateToGroupsHub(reason: 'build canceled');
      });
    }
```

**Restricciones:**
- Solo estos dos cambios: guard `currentGroup?.id == widget.groupId` +
  wrap en `addPostFrameCallback` con guard `!mounted`.
- No tocar `_navigateToGroupsHub()` (línea ~1790).
- No tocar los listeners de líneas 512–514 ni 541–543 — ya están fuera de `build()`.
- No cambiar cuándo/cómo se setea `_cancelNavigationHandled`.

---

## Fix 2 — `lib/presentation/viewmodels/session_sync_service.dart`

**Por qué:** `_recoverFromServer()` con `serverSession == null` solo programa retry cada
5s indefinidamente. No verifica si el grupo adjunto es terminal. Dos señales corroboradas
(session null + grupo terminal) son suficientes para confirmar cancelación legítima
(AP-3) — el hold debe limpiarse y los reintentos deben detenerse.

### Cambio — `_recoverFromServer()` (líneas 366–386)

**Código actual:**
```dart
  Future<void> _recoverFromServer() async {
    try {
      final repo = ref.read(pomodoroSessionRepositoryProvider);
      final serverSession = await repo.fetchSession(preferServer: true);
      if (!state.holdActive) return;
      if (serverSession != null && _isSessionForGroup(serverSession)) {
        _onSessionReceived(serverSession);
        return;
      }
      if (state.recoveryStatus != RecoveryStatus.failed) {
        state = state.copyWith(recoveryStatus: RecoveryStatus.failed);
      }
      _scheduleRecoveryRetry(_recoveryCooldown);
    } catch (_) {
      if (!state.holdActive) return;
      if (state.recoveryStatus != RecoveryStatus.failed) {
        state = state.copyWith(recoveryStatus: RecoveryStatus.failed);
      }
      _scheduleRecoveryRetry(_recoveryCooldown);
    }
  }
```

**Reemplazar con:**
```dart
  Future<void> _recoverFromServer() async {
    try {
      final repo = ref.read(pomodoroSessionRepositoryProvider);
      final serverSession = await repo.fetchSession(preferServer: true);
      if (!state.holdActive) return;
      if (serverSession != null && _isSessionForGroup(serverSession)) {
        _onSessionReceived(serverSession);
        return;
      }
      // AP-3: dos señales corroboradas — session null + grupo terminal.
      // Si el grupo adjunto es canceled o completed, limpiar hold y salir.
      final groupId = state.attachedGroupId;
      if (groupId != null) {
        final groupRepo = ref.read(taskRunGroupRepositoryProvider);
        final group = await groupRepo.getById(groupId);
        if (!state.holdActive) return;
        if (group != null &&
            (group.status == TaskRunStatus.canceled ||
                group.status == TaskRunStatus.completed)) {
          _latchTimer?.cancel();
          _latchTimer = null;
          _recoveryRetryTimer?.cancel();
          _recoveryRetryTimer = null;
          state = state.copyWith(
            holdActive: false,
            clearLatestSession: true,
            recoveryStatus: RecoveryStatus.idle,
          );
          if (kDebugMode) {
            debugPrint(
              '[SessionSync] hold cleared — group terminal '
              'groupId=$groupId status=${group.status.name}',
            );
          }
          return;
        }
      }
      if (state.recoveryStatus != RecoveryStatus.failed) {
        state = state.copyWith(recoveryStatus: RecoveryStatus.failed);
      }
      _scheduleRecoveryRetry(_recoveryCooldown);
    } catch (_) {
      if (!state.holdActive) return;
      if (state.recoveryStatus != RecoveryStatus.failed) {
        state = state.copyWith(recoveryStatus: RecoveryStatus.failed);
      }
      _scheduleRecoveryRetry(_recoveryCooldown);
    }
  }
```

**Restricciones:**
- `taskRunGroupRepositoryProvider` ya está importado y usado en línea ~304 del mismo
  archivo (`_maybeReconcileTerminalSnapshot`). No se necesitan imports nuevos.
- El segundo `if (!state.holdActive) return;` tras el `await groupRepo.getById(...)` es
  OBLIGATORIO — el hold puede haberse limpiado mientras el fetch estaba en curso.
- El bloque `catch (_)` queda sin cambios — si el fetch del grupo falla, reintenta.
- No llamar `stopTick()` desde aquí — eso es responsabilidad del Fix 0.
- `TaskRunStatus`, `kDebugMode`, `debugPrint` ya están importados.

---

## Orden de commits

```
1. fix(f25-h): add stopTick() to cancel and applyRemoteCancellation paths
   → lib/presentation/viewmodels/pomodoro_view_model.dart

2. fix(f25-h): guard build-phase cancel check with groupId + defer to post-frame
   → lib/presentation/screens/timer_screen.dart

3. fix(f25-h): add terminal-group exit to _recoverFromServer()
   → lib/presentation/viewmodels/session_sync_service.dart
```

---

## Tests a ejecutar tras los 3 commits

```bash
flutter analyze
flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart
flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart
flutter test test/presentation/timer_screen_syncing_overlay_test.dart
```

Todos deben pasar (0 analyze issues, todos los tests green). Reportar resultados a
Claude para QA review antes de validación en device.
