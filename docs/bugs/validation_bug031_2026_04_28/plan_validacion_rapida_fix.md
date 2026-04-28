# BUG-031 validation plan

## 1. Header

- Date: 28/04/2026
- Branch: `fix/bug031-stale-conflict-snackbar-base030`
- Working commit hash: `pending-local` (base HEAD: `cfffc92`)
- Bugs covered: `BUG-031` / `BUGLOG-031`
- Target devices: iOS owner (`iPhone 17 Pro`) + Chrome mirror (`localhost:5001`)

## 2. Objetivo

Validate that mirror conflict snackbar lifecycle is coherent after conflict resolution: stale `Owner is resolving this conflict...` snackbar must be dismissed when overlap decision is cleared/invalidated, and it must not survive as outdated warning after conflict state changes.

## 3. Síntoma original

Mirror user receives conflict snackbar during overlap, owner resolves or cancels overlap, but mirror keeps showing old warning while user continues working in Groups Hub/Task List. This blocks confidence and creates outdated UX state.

## 4. Root cause

In `lib/presentation/screens/timer_screen.dart`, mirror conflict snackbar lifecycle was fragmented in local flags and did not centralize dismissal when overlap decision changed. `_consumeRunningOverlapDecision` only partially handled state transitions and did not consistently clear snackbar + dismissal keys when decision became null or invalid for current session/groups.

## 5. Protocolo de validación

### Scenario A — Conflict snackbar appears while overlap is active

Preconditions:
1. Account Mode on both devices.
2. Owner has running `G1` and schedules `G2` with overlap pre-run.

Steps:
1. Keep mirror in Run Mode for running group.
2. Trigger overlap decision from owner timeline.
3. Observe mirror snackbar.

Expected result with fix:
1. Mirror shows snackbar once with message `Owner is resolving this conflict. Request ownership if needed.`
2. Snackbar remains until explicit `OK` or conflict-state change.

Reference result without fix:
1. Snackbar appears, but later can become stale after conflict resolution.

### Scenario B — Snackbar dismisses when conflict decision clears

Preconditions:
1. Scenario A snackbar is visible on mirror.

Steps:
1. On owner, resolve overlap (`Postpone scheduled` or `Cancel scheduled`).
2. Wait for mirror to receive updated overlap state.

Expected result with fix:
1. Mirror snackbar is auto-dismissed.
2. Mirror no longer shows stale conflict warning.

Reference result without fix:
1. Snackbar remains visible after conflict is resolved.

### Scenario C — Snackbar stays coherent across normal navigation

Preconditions:
1. Scenario B completed (decision cleared).

Steps:
1. Navigate mirror through Run Mode -> Groups Hub -> Task List.
2. Return to Run Mode.

Expected result with fix:
1. No stale conflict snackbar reappears after decision clear.

Reference result without fix:
1. Stale snackbar can persist/reappear despite resolved conflict.

## 6. Comandos de ejecución

```bash
# iOS owner
flutter run -v --debug -d "iPhone 17 Pro" --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug031_2026_04_28/logs/2026-04-28_bug031_cfffc92_ios_iPhone17Pro_debug.log

# Chrome mirror (fixed OAuth-safe localhost:5001)
flutter run -v --debug -d chrome --web-hostname=localhost --web-port=5001 --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug031_2026_04_28/logs/2026-04-28_bug031_cfffc92_chrome_debug.log
```

## 7. Log analysis — quick scan

### Bug present signals

```bash
grep -nE "Owner is resolving this conflict\. Request ownership if needed\.|running overlap" docs/bugs/validation_bug031_2026_04_28/logs/*_chrome_debug.log
```

Manual correlation required: if overlap is resolved on owner and message remains visible in mirror timeline -> bug still present.

### Fix working signals

```bash
grep -nE "runningOverlapDecisionProvider|RunModeDiag|Auto-open" docs/bugs/validation_bug031_2026_04_28/logs/*_chrome_debug.log
```

Plus widget evidence from local tests:
- `Timer mirror shows persistent conflict snackbar until explicit OK` PASS.
- `Timer mirror dismisses conflict snackbar when overlap decision clears` PASS.

## 8. Verificación local

- `flutter analyze lib/presentation/screens/timer_screen.dart test/presentation/timer_screen_completion_navigation_test.dart` -> PASS.
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Timer mirror shows persistent conflict snackbar until explicit OK"` -> PASS.
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Timer mirror dismisses conflict snackbar when overlap decision clears"` -> PASS.

## 9. Criterios de cierre

- Scenario A PASS with log evidence.
- Scenario B PASS with log + screenshot evidence.
- Scenario C PASS (no stale snackbar after clear across navigation).
- Local gate PASS (analyze + targeted widget tests).
- `bug_log.md` + `validation_ledger.md` + `dev_log.md` synchronized with closure metadata.

## 10. Status

In validation (28/04/2026)
