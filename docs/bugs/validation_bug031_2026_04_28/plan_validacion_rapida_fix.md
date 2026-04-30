# BUG-031 validation plan

## 1. Header

- Date: 28/04/2026 (updated 30/04/2026)
- Branch: `fix/bug031-validate-on-develop`
- Working commit hash: `f2005cc` (cherry-pick of runtime patch `f16341f` on top of `develop`)
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
  2>&1 | tee docs/bugs/validation_bug031_2026_04_28/logs/2026-04-30_bug031_f2005cc_ios_iPhone17Pro_debug.log

# Chrome mirror (fixed OAuth-safe localhost:5001)
flutter run -v --debug -d chrome --web-hostname=localhost --web-port=5001 --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug031_2026_04_28/logs/2026-04-30_bug031_f2005cc_chrome_debug.log
```

## 7. Log analysis — quick scan

### Bug present signals

```bash
grep -nE "runningOverlap=true|Owner is resolving this conflict\. Request ownership if needed\." docs/bugs/validation_bug031_2026_04_28/logs/2026-04-30_bug031_f2005cc_chrome_debug.log
```

Manual correlation required: if overlap is resolved on owner and message remains visible in mirror timeline -> bug still present.

### Fix working signals

```bash
grep -nE "runningOverlap=false|16:03:00\.000|route=/groups|route=/tasks|RunModeDiag" docs/bugs/validation_bug031_2026_04_28/logs/2026-04-30_bug031_f2005cc_chrome_debug.log
```

Plus widget evidence from local tests:
- `Timer mirror shows persistent conflict snackbar until explicit OK` PASS.
- `Timer mirror dismisses conflict snackbar when overlap decision clears` PASS.

## 8. Verificación local

- Local gate rerun on 30/04/2026 (branch `fix/bug031-validate-on-develop`, commit `f2005cc`):
  - `flutter analyze lib/presentation/screens/timer_screen.dart test/presentation/timer_screen_completion_navigation_test.dart` -> PASS (`No issues found!`).
  - `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Timer mirror shows persistent conflict snackbar until explicit OK"` -> PASS.
  - `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Timer mirror dismisses conflict snackbar when overlap decision clears"` -> PASS.

- Device validation (30/04/2026, iOS owner + Chrome mirror) using:
  - `docs/bugs/validation_bug031_2026_04_28/logs/2026-04-30_bug031_f2005cc_ios_iPhone17Pro_debug.log`
  - `docs/bugs/validation_bug031_2026_04_28/logs/2026-04-30_bug031_f2005cc_chrome_debug.log`
  - `docs/bugs/validation_bug031_2026_04_28/screenshots/Captura de pantalla 2026-04-30 a las 15.56.54.png`
  - `docs/bugs/validation_bug031_2026_04_28/screenshots/Captura de pantalla 2026-04-30 a las 15.57.55.png`
- Scenario A PASS:
  - Owner run started at 15:45:30; scheduled mirror group remained planned with pre-run.
  - Owner pause at 15:49:00 triggered overlap path; conflict UX appeared on both devices as expected.
- Scenario B PASS:
  - Owner selected `Postpone` at 15:49:46; schedule shifted from `16:02` to `16:03`.
  - Log correlation confirms schedule update on both devices (`sample=...16:03:00.000`).
  - Mirror stale conflict warning no longer remained after owner resolution.
- Scenario C PASS:
  - Mirror navigation around 15:49:53-15:50:02 (`/timer` -> `/groups` -> `/tasks` -> `/timer`) stayed clean with no stale conflict warning reappearing.
  - `RunModeDiag` route transitions confirm stable navigation state while conflict state remained resolved.

## 9. Criterios de cierre

- Scenario A PASS with log evidence.
- Scenario B PASS with log + screenshot evidence.
- Scenario C PASS (no stale snackbar after clear across navigation).
- Local gate PASS (analyze + targeted widget tests).
- `bug_log.md` + `validation_ledger.md` + `dev_log.md` synchronized with closure metadata.

## 10. Status

Closed/OK (30/04/2026; local gate PASS + device scenarios A/B/C PASS with logs and screenshots)
