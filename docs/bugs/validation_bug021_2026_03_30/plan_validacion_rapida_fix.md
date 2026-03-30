# Plan validacion rapida fix

## 1. Header
- Date: 2026-03-30
- Branch: `fix/bug021-ownership-snackbar-autodismiss`
- Commit hash: `pending-local`
- Bugs covered: `BUG-021` / `BUGLOG-021`
- Target devices: `android_RMX3771`, `macos`

## 2. Objetivo
Validate and close the Run Mode ownership snackbar coherence bug where a rejection snackbar can remain visible after its ownership context is no longer valid. The fix must auto-dismiss stale ownership feedback immediately on ownership-state transitions.

## 3. Sintoma original
From user perspective, the rejection snackbar (`Ownership request rejected at ...`) can remain visible if the user does not press `OK`, even after ownership context changes (requester becomes owner, request is replaced, or request is cleared). This leaves contradictory feedback in Run Mode.

## 4. Root cause
`TimerScreen` tracked rejection snackbar lifecycle with a visibility boolean and partial invalidation checks only (`isOwnerForCurrentSession`, `isOwnershipRequestPendingForThisDevice`). It did not bind the visible snackbar to a concrete rejected request key, so request replacement/clear transitions could leave stale snackbar content onscreen.

## 5. Protocolo de validacion

### Scenario A - Stale rejection snackbar after ownership grant
- Preconditions:
  1. Two devices in Account Mode with active Run Mode session.
  2. Requester device can receive ownership rejection snackbar.
- Steps:
  1. Trigger rejection snackbar on requester.
  2. Leave snackbar visible (do not tap `OK`).
  3. Approve a new ownership request so requester becomes owner.
- Expected with fix:
  - Previous rejection snackbar auto-dismisses immediately when ownership changes.
- Reference result without fix:
  - Rejection snackbar remains visible although requester is now owner.

### Scenario B - Stale rejection snackbar after new requestId
- Preconditions:
  1. Requester has visible rejection snackbar from a previous request.
- Steps:
  1. While old snackbar remains visible, issue a new ownership request.
  2. Observe pending state and snackbar visibility.
- Expected with fix:
  - Old rejection snackbar auto-dismisses when new request is submitted.
- Reference result without fix:
  - Old snackbar remains visible and conflicts with new pending state.

### Scenario C - Stale rejection snackbar after request clear/replace
- Preconditions:
  1. Rejection snackbar is currently visible on requester.
- Steps:
  1. Resolve ownership request from owner side (clear/replace metadata).
  2. Keep Run Mode open and observe ownership feedback.
- Expected with fix:
  - Snackbar auto-dismisses as soon as rejection context is no longer active.
- Reference result without fix:
  - Snackbar remains anchored until manual `OK`.

## 6. Comandos de ejecucion

```bash
flutter run -v --debug -d RMX3771 --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug021_2026_03_30/logs/2026-03-30_bug021_pending_android_RMX3771_debug.log
```

```bash
flutter run -v --debug -d macos --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug021_2026_03_30/logs/2026-03-30_bug021_pending_macos_debug.log
```

## 7. Log analysis - quick scan

### Bug present signals
```bash
grep -nE "Ownership request rejected|ownershipRequest|requestId|ownerDeviceId|pending|rejected" \
  docs/bugs/validation_bug021_2026_03_30/logs/2026-03-30_bug021_pending_android_RMX3771_debug.log
```

### Fix working signals
```bash
grep -nE "Ownership request rejected|ownerDeviceId|requestId|approved|pending|rejected" \
  docs/bugs/validation_bug021_2026_03_30/logs/2026-03-30_bug021_pending_android_RMX3771_debug.log
```

## 8. Verificacion local
- [x] `flutter analyze` - PASS (2026-03-30)
- [x] `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Run Mode dismisses stale rejection snackbar"` - PASS (2026-03-30)

## 9. Criterios de cierre
- Exact repro scenarios A/B/C accepted as PASS via targeted tests + log review for rejection-snackbar invalidation.
- Regression smoke PASS for ownership request/reject/approve flow.
- Checklist + logs/screenshots updated.
- `docs/bugs/bug_log.md` and `docs/validation/validation_ledger.md` updated to `Closed/OK` with closure evidence.
- Scope note: original user report referenced automatic owner switch without explicit ownership request; that path does not emit the rejection snackbar targeted by this fix. User accepted closure based on implemented behavior, logs, and local gate.

## 10. Status line
Status: Closed/OK
