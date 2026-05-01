# BUG-027 Quick Validation Plan

Date: 2026-05-01  
Branch: `fix/bug033-foreground-service-crash`  
Commit: `pending-local`  
Bugs covered: `BUG-027`  
Target devices: Android owner path (primary), macOS/Chrome mirror path (secondary)

## Objetivo
Validate that conflict messaging now includes explicit blocker identity and time-range context across all BUG-027 surfaces (planning, pre-run, runtime, mirror), and confirm no regression in overlap decision ownership actions.

## Síntoma original
Conflict UX showed generic messages without enough context to identify the blocking pair and compare ranges. Users had to manually inspect cards/screens to understand why the overlap happened and what changed after resolution.

## Root cause
Conflict copy was fragmented across multiple screens with no shared context formatter. `RunningOverlapDecision` only propagated IDs, while planning/runtime/mirror surfaces built independent hardcoded strings, causing missing name/range details and inconsistent explanations.

## Protocolo de validación

### Scenario A — Groups Hub re-plan conflict modal (V03)
Preconditions:
1. One running group active.
2. Re-plan another group into an overlapping range.

Steps:
1. Open Groups Hub and trigger re-plan conflict.
2. Validate running conflict modal copy.

Expected result with fix:
- Modal includes selected range plus blocker group name and range.

Reference result without fix:
- Generic "A group is already running" copy without blocker context.

### Scenario B — Groups Hub pre-run conflict snackbar (V05)
Preconditions:
1. Scheduled start configured with noticeMinutes > 0.
2. Pre-run window overlaps running or scheduled blocker.

Steps:
1. Re-plan notice minutes until pre-run overlap appears.
2. Observe snackbar copy.

Expected result with fix:
- Snackbar includes blocker name + blocker range + candidate pre-run window.

Reference result without fix:
- Generic "Notice Xm overlaps..." without pair/range detail.

### Scenario C — Timer runtime overlap modal (V24 runtime)
Preconditions:
1. Running group drifts into next scheduled pre-run threshold.
2. Running overlap decision is emitted.

Steps:
1. Open Timer on running group.
2. Wait for overlap modal.

Expected result with fix:
- Runtime modal shows:
  - `Running: <name>` + range
  - `Scheduled: <name>` + range
  - `Pre-Run: HH:mm` (when applicable)

Reference result without fix:
- Only partial scheduled context; missing running projection context.

### Scenario D — Mirror warning surfaces (V19/V24 mirror)
Preconditions:
1. Non-owner mirror device with active running overlap decision.
2. Owner still active (or stale path for claim CTA).

Steps:
1. Open Task List and Groups Hub on mirror.
2. Open Timer on mirror while overlap is active.
3. Validate mirror banner/snackbar content and ownership CTA action.

Expected result with fix:
- Base warning message remains visible.
- Context summary is available (tooltip in Task List/Groups Hub; summary line in Timer snackbar).
- `Request ownership` / `Claim ownership` action remains functional.

Reference result without fix:
- Generic warning without pair identity/range context.

## Comandos de ejecución

```bash
flutter run -d android --dart-define=APP_ENV=prod 2>&1 | tee docs/bugs/validation_bug027_2026_05_01/logs/2026-05-01_bug027_pending-local_android_RMX3771_debug.log
```

```bash
flutter run -d macos --dart-define=APP_ENV=prod 2>&1 | tee docs/bugs/validation_bug027_2026_05_01/logs/2026-05-01_bug027_pending-local_macos_debug.log
```

```bash
flutter run -d chrome --dart-define=APP_ENV=prod 2>&1 | tee docs/bugs/validation_bug027_2026_05_01/logs/2026-05-01_bug027_pending-local_chrome_debug.log
```

## Log analysis — quick scan

### Bug present signals
```bash
grep -nE "Owner is resolving this conflict\. Request ownership if needed\.$" docs/bugs/validation_bug027_2026_05_01/logs/2026-05-01_bug027_pending-local_*_debug.log
```

```bash
grep -nE "Conflict with running group|Conflict with scheduled group" docs/bugs/validation_bug027_2026_05_01/logs/2026-05-01_bug027_pending-local_*_debug.log
```

### Fix working signals
```bash
grep -nE "Running: |Scheduled: |Pre-Run:" docs/bugs/validation_bug027_2026_05_01/logs/2026-05-01_bug027_pending-local_*_debug.log
```

```bash
grep -nE "requestOwnership|claimOwnership|Owner seems unavailable" docs/bugs/validation_bug027_2026_05_01/logs/2026-05-01_bug027_pending-local_*_debug.log
```

## Verificación local

- `flutter analyze` -> PASS (2026-05-01).
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> PASS (2026-05-01).
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` -> PASS (2026-05-01).

## Criterios de cierre

1. Exact repro scenarios A-D PASS with runtime evidence.
2. Mirror CTA behavior PASS (request/claim action still works).
3. No regression in overlap routing/modals/snackbars.
4. Checklist updated with PASS marks and evidence references (logs/screenshots).

## Status

In validation.
