# BUG-033 Quick Validation Plan

Date: 2026-04-29  
Branch: `fix/bug033-foreground-service-crash`  
Commit: `pending-local`  
Bugs covered: `BUG-033`  
Target devices: Android owner path (primary), macOS observer (secondary ownership side effect check)

## Objetivo
Validate and reproduce under controlled conditions the Android crash caused by foreground-service promotion/update while app is backgrounded during active Account Mode execution, then collect missing evidence required for deterministic root-cause fix and closure criteria.

## Síntoma original
During a background window in Android, app crashes with system dialog and process kill. Log shows `ForegroundServiceStartNotAllowedException`, then session continuity is disrupted and ownership can migrate to another device.

## Root cause
Crash path currently points to Android service lifecycle:
- File: `android/app/src/main/kotlin/com/marcdevelopez/focusinterval/PomodoroForegroundService.kt`
- Methods: `onStartCommand(...)` -> `startOrUpdate()` -> `startForeground(...)`
- Exception observed: `android.app.ForegroundServiceStartNotAllowedException` (`mAllowStartForeground false`)

Current evidence confirms crash location and stacktrace, but exact deterministic same-conditions repro must be repeated in one controlled pass to finalize fix constraints.

## Protocolo de validación

### Scenario A — Exact crash repro (same conditions)
Preconditions:
1. Account Mode enabled.
2. Android logged in and can become session owner.
3. A running group is active and Android is owner.

Steps:
1. Start active run and confirm owner is Android.
2. Leave Android app in background for several minutes without ending the run.
3. Keep macOS app connected as observer to detect ownership side effects.
4. Wait for lifecycle/service updates while Android remains backgrounded.
5. Re-open Android if process is still alive.

Expected result with fix:
- No crash dialog.
- No `ForegroundServiceStartNotAllowedException`.
- Session continuity preserved.

Reference result without fix:
- Crash dialog appears.
- Process kill (`SIG: 9`) after `ForegroundServiceStartNotAllowedException`.

### Scenario B — BUG-032 run isolation guard
Preconditions:
1. Same setup as Scenario A.
2. BUG-032 validation run prepared.

Steps:
1. Pause on Android before sending app to background (explicit pause-first control run).
2. Keep background interval.
3. Re-open Android and inspect state continuity.

Expected result with fix:
- No foreground-service crash in paused flow.
- BUG-032 signals remain isolatable (paused should remain paused).

Reference result without fix:
- Crash can contaminate BUG-032 validation and ownership continuity.

## Comandos de ejecución

```bash
flutter run -d android 2>&1 | tee docs/bugs/validation_bug033_2026_04_29/logs/2026-04-29_bug033_pending-local_android_debug.log
```

```bash
flutter run -d macos 2>&1 | tee docs/bugs/validation_bug033_2026_04_29/logs/2026-04-29_bug033_pending-local_macos_debug.log
```

## Log analysis — quick scan

Bug present signals:

```bash
grep -nE "ForegroundServiceStartNotAllowedException|Service.startForeground\(\) not allowed|FATAL EXCEPTION|Shutting down VM|SIG: 9" docs/bugs/validation_bug033_2026_04_29/logs/2026-04-29_bug033_pending-local_android_debug.log
```

Fix working signals:

```bash
grep -nE "ForegroundServiceStartNotAllowedException|FATAL EXCEPTION|SIG: 9" docs/bugs/validation_bug033_2026_04_29/logs/2026-04-29_bug033_pending-local_android_debug.log
```

Expected for fix-working check: no matches.

## Verificación local

- `flutter analyze` -> Pending
- Targeted test commands for service-lifecycle path -> Pending

## Criterios de cierre

1. Scenario A exact repro repeated with deterministic evidence (PASS or deterministic FAIL with stable trigger notes).
2. Scenario B isolation run confirms BUG-032 validation is not contaminated by BUG-033 crash.
3. Crash signatures absent in fixed candidate run.
4. Checklist updated with logs + screenshots references.

## Status

In validation — initial evidence captured, forced same-conditions repro pending.
