# BUG-024 Quick Validation Plan

Date: 02/04/2026
Branch: validation-rvp021-028-sync
Commit: pending-local
Bugs covered: BUG-024
Target devices: Android RMX3771 (owner) + macOS/Chrome mirror

## Objetivo

Validate that owner-side rejection of an ownership request remains dismissed when the same pending request is re-ingested with a later materialized `requestId`, without breaking existing ownership pending/rejection flows.

## Sintoma original

From the owner perspective in Run Mode, an ownership request banner can disappear after pressing `Reject` and then reappear seconds later even though the requester and pending intent are the same. Users experience this as a flicker/reopen loop and may think rejection did not apply.

## Root cause

- `lib/presentation/screens/timer_screen.dart`
  - `_isDismissedOwnershipRequest(...)` matched dismissal by `requestId` when present.
  - Rejected/dismissed pending requests initially ingested without `requestId` used requester-based fallback (`_dismissedOwnershipRequesterId`), but once backend re-ingested the same pending request with a materialized `requestId`, fallback matching no longer applied.
  - Result: `showOwnerRequestBanner` became true again for the same requester request.

## Protocolo de validacion

### Scenario A - Exact repro (owner reject + requestId materialization)

Preconditions:

1. Account Mode, active running group in TimerScreen on owner device.
2. Ownership request arrives as `pending` without `requestId` (same requester id).

Steps:

1. On owner device, confirm `Ownership request` banner is visible.
2. Tap `Reject` once.
3. Re-ingest/update the same pending ownership request for the same requester, now with materialized `requestId`.

Expected result with fix:

- Banner remains hidden after step 3.
- No immediate reopen/flicker.

Reference result without fix:

- Banner reappears after step 3.

### Scenario B - Regression smoke (critical ownership flow unchanged)

Preconditions:

1. Mirror device requests ownership from sheet CTA.

Steps:

1. Mirror requests ownership from AppBar ownership sheet.
2. Pending state persists until owner response.
3. Owner rejects and requester clears pending correctly.

Expected result with fix:

- Existing sheet-only ownership flow remains unchanged.
- Pending/rejected transitions continue to work.

Reference result without fix:

- Not a regression target (baseline already PASS before BUG-024 fix).

### Scenario C - Device validation packet

Preconditions:

1. Android owner + desktop mirror connected to same account/group.

Steps:

1. Execute Scenario A on real devices.
2. Execute Scenario B smoke on same run.
3. Capture logs/screenshots.

Expected result with fix:

- Scenario A and B PASS on devices.

Reference result without fix:

- Scenario A can re-show banner after requestId materialization.

## Comandos de ejecucion

```bash
cd /Users/devcodex/development/focus_interval && flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "owner reject dismissal stays hidden when pending request gets requestId materialized" 2>&1 | tee docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_widget_exact_repro_debug.log
```

```bash
cd /Users/devcodex/development/focus_interval && flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "critical ownership flow stays appbar-sheet-only and pending remains stable until owner response" 2>&1 | tee docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_widget_regression_critical_debug.log
```

```bash
cd /Users/devcodex/development/focus_interval && flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "rejection clears local pending and old rejected requestId does not suppress a new request" 2>&1 | tee docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_widget_regression_requestid_debug.log
```

```bash
cd /Users/devcodex/development/focus_interval && flutter analyze 2>&1 | tee docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_analyze.log
```

```bash
cd /Users/devcodex/development/focus_interval && flutter run -v --debug -d RMX3771 --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true 2>&1 | tee docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_android_RMX3771_debug.log
```

```bash
cd /Users/devcodex/development/focus_interval && flutter run -v --debug -d macos --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true 2>&1 | tee docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_macos_debug.log
```

## Log analysis - quick scan

### Bug present signals

```bash
grep -nE "Test failed|Expected: no matching candidates|Some tests failed|Ownership request" docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_widget_exact_repro_debug.log
```

### Fix working signals

```bash
grep -nE "owner reject dismissal stays hidden when pending request gets requestId materialized|All tests passed" docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_widget_exact_repro_debug.log
```

```bash
grep -nE "critical ownership flow stays appbar-sheet-only and pending remains stable until owner response|rejection clears local pending and old rejected requestId does not suppress a new request|All tests passed" docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_widget_regression_critical_debug.log docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_widget_regression_requestid_debug.log
```

```bash
grep -n "No issues found!" docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_analyze.log
```

## Verificacion local

- [x] `flutter test` exact repro PASS.
- [x] Ownership regression smoke tests PASS.
- [x] `flutter analyze` PASS.

## Verificacion en devices

- [x] Scenario A PASS on Android owner + macOS mirror (02/04/2026): banner did not reappear after reject when request flow was re-validated in real run.
- [x] Scenario B PASS on Android owner + macOS mirror (02/04/2026): sheet-only request flow and pending/reject transitions behaved correctly.
- [x] Scenario C PASS (closure packet criteria) on real devices (02/04/2026): A + B validated in same run; no regressions observed.

## Criterios de cierre

1. Exact repro PASS (local + device) with logs/screenshots evidence.
2. Regression smoke PASS (local + device).
3. No ownership flow regressions in owner/mirror real run.
4. If any regression appears on devices, rollback fix and leave BUG-024 open as observation (do not close RVP-059).

Status: Closed/OK
