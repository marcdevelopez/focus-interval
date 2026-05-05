# BUG-033 Quick Validation Plan

Date: 2026-04-29  
Branch: `fix/bug033-foreground-service-crash`  
Commit: `9f01491`  
Bugs covered: `BUG-033`  
Target devices: Android owner path (primary), macOS observer (secondary ownership side effect check)  
Protocol update: 2026-05-05

## Objetivo
Validate and reproduce under controlled conditions the Android crash caused by foreground-service promotion/update while app is backgrounded during active Account Mode execution, then collect missing evidence required for deterministic root-cause fix and closure criteria.

## Síntoma original
During a background window in Android, app crashes with system dialog and process kill. Log shows `ForegroundServiceStartNotAllowedException`, then session continuity is disrupted and ownership can migrate to another device.

## Root cause
Crash path currently points to Android service lifecycle:
- File: `android/app/src/main/kotlin/com/marcdevelopez/focusinterval/PomodoroForegroundService.kt`
- Methods: `onStartCommand(...)` -> `startOrUpdate()` -> `startForeground(...)`
- Exception observed: `android.app.ForegroundServiceStartNotAllowedException` (`mAllowStartForeground false`)

Deterministic repro was re-captured on 2026-05-05 with dual logs. Sequence shows service calls accepted while app is foreground (`uidState: TOP`) and later rejected in background (`uidState: SVC`) for the same owner session path, which triggers `ForegroundServiceStartNotAllowedException` and process kill.

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

### Scenario C — Parallel rolling monitor (multi-session non-repro tracking)
Preconditions:
1. `BUG-033` still unresolved (`Open` / `In validation`).
2. Any bugfix/feature work can proceed on other branches.
3. Dedicated terminals remain reserved for capture.

Steps:
1. Start dual capture (`adb logcat` + `flutter run`) with timestamped files.
2. Use app normally and force memory/background pressure (maps/media/long background).
3. If modal/crash appears, record exact wall-clock time and keep capture running for 1-2 minutes after event.
4. Stop capture and run quick-scan commands.
5. If no crash, mark session as `non-repro` and keep protocol active for next session.

Expected result with fix:
- Repeated non-repro under stress conditions and no crash signatures in app-focused logcat.

Reference result without fix:
- Any recurrence of `ForegroundServiceStartNotAllowedException` or fatal process kill signatures for `com.marcdevelopez.focusinterval`.

## Comandos de ejecución

Terminal A — setup + Android system capture (two commands in sequence):

```bash
mkdir -p docs/bugs/validation_bug033_2026_04_29/logs
```

```bash
adb -s 10.0.0.37:5555 logcat -v threadtime | grep --line-buffered -E "com\.marcdevelopez\.focusinterval|ForegroundServiceStartNotAllowedException|FATAL EXCEPTION|AndroidRuntime|PomodoroForegroundService|startForeground\(|Shutting down VM|Fatal signal|SIG: 9" | tee docs/bugs/validation_bug033_2026_04_29/logs/$(date +"%Y-%m-%d")_bug033_android_RMX3771_logcat_focus.log
```

Terminal B — Flutter run against real backend (single command):

```bash
flutter run -v --debug -d RMX3771 --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true 2>&1 | tee docs/bugs/validation_bug033_2026_04_29/logs/$(date +"%Y-%m-%d")_bug033_android_RMX3771_debug_prod.log
```

Stop capture cleanly:

```bash
# Terminal A (logcat): Ctrl+C
# Terminal B (flutter run): press q and Enter
```

Concurrent-work guardrails (to keep capture intact while fixing other bugs):

```bash
# Allowed in parallel: edit code/docs, run tests on other branches/devices, use other terminals/agents.
# Forbidden while capture is active on this device:
#   - launching a second `flutter run -d 10.0.0.37:5555`
#   - running `adb logcat -c`
#   - running `adb kill-server`
```

## Log analysis — quick scan

Bug present signals:

```bash
rg -n "ForegroundServiceStartNotAllowedException|FATAL EXCEPTION|AndroidRuntime|PomodoroForegroundService|startForeground\\(|Shutting down VM|Fatal signal|SIG: 9" docs/bugs/validation_bug033_2026_04_29/logs/*bug033*_android_RMX3771_logcat*.log
```

Process kill/context side-effects:

```bash
rg -n "Process com\\.marcdevelopez\\.focusinterval|SIG: 9|cloud_firestore/unavailable|Unable to resolve host firestore.googleapis.com" docs/bugs/validation_bug033_2026_04_29/logs/*bug033*.log
```

Fix working signals:

```bash
rg -n "ForegroundServiceStartNotAllowedException|FATAL EXCEPTION|AndroidRuntime|PomodoroForegroundService" docs/bugs/validation_bug033_2026_04_29/logs/*bug033*_android_RMX3771_logcat*.log
```

Expected for fix-working check: no matches.

## Verificación local

- `flutter analyze` -> PASS (2026-05-05, branch `fix/bug033-foreground-service-crash`).
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` -> PASS (2026-05-05, `+30`).

## Criterios de cierre

1. Scenario A exact repro repeated with deterministic evidence (PASS or deterministic FAIL with stable trigger notes).
2. Scenario B isolation run confirms BUG-032 validation is not contaminated by BUG-033 crash.
3. Crash signatures absent in fixed candidate run.
4. Checklist updated with logs + screenshots references.

## Historial de ejecución (rolling)

- 2026-05-01 (13:05 -> 14:35 EDT): non-repro under prolonged background + memory pressure.
  - No `ForegroundServiceStartNotAllowedException` for `com.marcdevelopez.focusinterval`.
  - No `FATAL EXCEPTION` tied to Focus Interval process in app-focused logcat run.
  - Separate connectivity noise observed (`Unable to resolve host firestore.googleapis.com`), tracked as parallel signal, not closure for BUG-033.
  - Evidence files:
    - `docs/bugs/validation_bug033_2026_04_29/logs/2026-05-01_bug033_5b9d85c_android_RMX3771_debug_prod.log`
    - `docs/bugs/validation_bug033_2026_04_29/logs/2026-05-01_bug033pid_5b9d85c_android_RMX3771_debug.log`
- 2026-05-05 (repro recaptured):
  - Exact crash modal reproduced after Android became owner, then stayed backgrounded.
  - `ForegroundServiceStartNotAllowedException` and fatal process shutdown path captured.
  - Evidence files:
    - `docs/bugs/validation_bug033_2026_04_29/logs/2026-05-05_bug033_android_RMX3771_debug_prod.log`
    - `docs/bugs/validation_bug033_2026_04_29/logs/2026-05-05_bug033_android_RMX3771_logcat_focus.log`
  - Runtime fix candidate implemented after repro recapture in `PomodoroForegroundService.kt`:
    - `startForeground(...)` guarded with Android S+ disallowed-start fallback (graceful stop, no crash throw path).
    - `onStartCommand` return switched from `START_STICKY` to `START_NOT_STICKY` to avoid restart-crash loop.

## Status

In validation — deterministic repro re-captured on 2026-05-05 and runtime fix candidate is now implemented with local gate PASS. Pending: fresh device validation scenarios A/B on the patched build to confirm no crash recurrence and no continuity regressions.
