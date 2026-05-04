# BUG-035 Quick Validation Plan

Date: 2026-05-04  
Branch: `fix/bug035-macos-global-keyboard-repair`  
Commit: `pending-local`  
Bugs covered: `BUG-035`  
Target devices: macOS

## Objetivo

Prevent intermittent macOS stuck-key failures from blocking typing outside Authentication by extending stale-key recovery to app scope (bootstrap + resume) while preserving existing LoginScreen safeguards.

## Síntoma original

When the user is already authenticated and using normal app screens, typing can stop working and logs repeat `A KeyDownEvent is dispatched, but the state shows that the physical key is already pressed`. The issue can affect any editable field and usually clears only after app restart.

## Root cause

Current stale-key repair logic exists in `LoginScreen` only. Authenticated flows that never open `/login` do not execute repair, so stale `HardwareKeyboard` pressed-key state can persist after macOS focus/resume transitions and block input globally.

## Protocolo de validación

### Scenario A — App-wide keyboard input remains usable after resume/focus churn

Preconditions:
1. macOS desktop run.
2. User authenticated and navigated to non-login editor flow.

Steps:
1. Navigate between Task List, Task Editor, and Preset Editor.
2. Move focus away from app and back (Cmd+Tab/click outside-window then return).
3. Type in editable fields after each resume.

Expected result with fix:
- Typing continues to work on all tested screens; no persistent key lock requiring restart.

Reference result without fix:
- Intermittently, typing stops and duplicate key-down exceptions repeat for the same key.

### Scenario B — Authentication screen behavior remains unchanged (defense in depth)

Preconditions:
1. Same run.
2. Open `/login` path (sign-out flow or direct navigation in supported environment).

Steps:
1. Tap email/password fields.
2. Type after one or more app resume cycles.

Expected result with fix:
- Login fields still accept typing and local Auth repair path remains functional.

Reference result without fix:
- Existing BUG-022 behavior could block typing in Authentication after account-switch flow.

### Scenario C — Validation exception (user-approved)

Preconditions:
1. Bug trigger is non-deterministic in normal runs.

Steps:
1. Record gate-only closure evidence (`flutter analyze` + targeted regression test).
2. Document explicit user decision to waive exact deterministic device repro for this item.

Expected result with fix:
- Traceability packet reflects user-approved repro waiver and local gate PASS evidence.

Reference result without fix:
- Item would remain blocked waiting for deterministic exact repro that is not reproducible on demand.

## Comandos de ejecución

```bash
flutter run -v --debug -d macos --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true 2>&1 | tee docs/bugs/validation_bug035_2026_05_04/logs/2026-05-04_bug035_pending-local_macos_debug.log
```

```bash
flutter analyze 2>&1 | tee docs/bugs/validation_bug035_2026_05_04/logs/2026-05-04_bug035_pending-local_local_analyze.log
```

```bash
flutter test test/presentation/timer_screen_completion_navigation_test.dart 2>&1 | tee docs/bugs/validation_bug035_2026_05_04/logs/2026-05-04_bug035_pending-local_local_timer_screen_completion_navigation_test.log
```

## Log analysis — quick scan

Bug present signals:

```bash
rg -n "A KeyDownEvent is dispatched, but the state shows that the physical key is already pressed|KeyDownEvent#|physical key is already pressed" docs/bugs/validation_bug035_2026_05_04/logs/*bug035*_macos_debug.log
```

Fix working signals:

```bash
rg -n "\[GlobalKeyboardRepair\]|\[AuthKeyboardRepair\]|trigger=app_wrapper_bootstrap|trigger=app_resumed" docs/bugs/validation_bug035_2026_05_04/logs/*bug035*.log
```

## Verificación local

- `flutter analyze` -> PASS (`No issues found!`), log: `docs/bugs/validation_bug035_2026_05_04/logs/2026-05-04_bug035_pending-local_local_analyze.log`.
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> PASS (`All tests passed!`, `+39`), log: `docs/bugs/validation_bug035_2026_05_04/logs/2026-05-04_bug035_pending-local_local_timer_screen_completion_navigation_test.log`.

## Criterios de cierre

1. Local gate PASS (`flutter analyze` + targeted regression test).
2. No regression reported in Authentication typing behavior.
3. Validation packet updated with explicit user-approved non-deterministic repro waiver.

## Status

In validation.
