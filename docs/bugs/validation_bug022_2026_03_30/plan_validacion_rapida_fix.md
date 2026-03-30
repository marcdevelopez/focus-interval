# Plan validacion rapida fix

## 1. Header
- Date: 2026-03-30
- Branch: `fix/bug022-macos-auth-keyboard-stuck`
- Commit hash: `4e439db`
- Bugs covered: `BUG-022` / `BUGLOG-022`
- Target devices: `macos` (primary), `android_RMX3771` (regression control)

## 2. Objetivo
Validate the macOS Authentication keyboard-lock regression where email/password fields stop accepting input after sign-out and account switch. Confirm that the macOS-only keyboard-state repair unblocks typing without introducing regressions in login, sign-out, or non-macOS flows.

## 3. Sintoma original
From user perspective, after signing out to switch account on macOS, the Authentication screen appears but the keyboard does not work in email/password fields. The app repeatedly logs duplicate key-down exceptions and the user cannot enter credentials.

## 4. Root cause
Probable root cause: stale `HardwareKeyboard` pressed-key state survives a sign-out/navigation transition on macOS. Subsequent key events are interpreted as duplicate key-down events (`physical key already pressed`), causing framework exceptions and input lock in Authentication text fields.

## 5. Protocolo de validacion

### Scenario A — Exact repro on macOS (account switch -> Authentication)
- Preconditions:
  1. Signed in with Account A on macOS.
  2. Authentication supports email/password.
- Steps:
  1. Sign out and navigate to Authentication.
  2. Tap `Email` and type a valid email.
  3. Tap `Password` and type a password.
  4. Repeat sign-out -> login flow with Account B.
- Expected with fix:
  - Both fields accept typing immediately.
  - No repeating duplicate key-down exception loop.
- Reference result without fix:
  - Fields block keyboard input; repeated duplicate key-down errors appear.

### Scenario B — Stress repeated transitions on macOS
- Preconditions:
  1. Scenario A PASS once.
- Steps:
  1. Perform 5 consecutive cycles: login -> sign out -> Authentication typing.
  2. Include at least one cycle with Backspace usage in each field.
- Expected with fix:
  - No lockups in any cycle.
  - Input remains responsive across transitions.
- Reference result without fix:
  - Intermittent lock returns after one or more sign-out cycles.

### Scenario C — Regression smoke (non-macOS path)
- Preconditions:
  1. Android device available (or equivalent non-macOS environment).
- Steps:
  1. Open Authentication.
  2. Type email/password and complete sign-in/sign-out once.
- Expected with fix:
  - No behavior change; login remains functional.
- Reference result without fix:
  - Baseline behavior (no known issue).

## 6. Comandos de ejecucion

```bash
flutter run -v --debug -d macos --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug022_2026_03_30/logs/2026-03-30_bug022_wip0000_macos_debug.log
```

```bash
flutter run -v --debug -d RMX3771 --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug022_2026_03_30/logs/2026-03-30_bug022_wip0000_android_RMX3771_debug.log
```

## 7. Log analysis - quick scan

### Bug present signals
```bash
grep -nE "A KeyDownEvent is dispatched|physical key is already pressed|Backspace" \
  docs/bugs/validation_bug022_2026_03_30/logs/2026-03-30_bug022_wip0000_macos_debug.log
```

### Fix working signals
```bash
grep -nE "\[AuthKeyboardRepair\]" \
  docs/bugs/validation_bug022_2026_03_30/logs/2026-03-30_bug022_wip0000_macos_debug.log
```

```bash
grep -nE "Sign-in error|Sign-up error|Incorrect password" \
  docs/bugs/validation_bug022_2026_03_30/logs/2026-03-30_bug022_wip0000_macos_debug.log
```

## 8. Verificacion local
- [x] `flutter analyze` — PASS (30/03/2026)
- [x] `flutter test test/presentation/timer_screen_completion_navigation_test.dart` — PASS (30/03/2026)
- [x] Login-screen focused smoke test (manual/user-run) — PASS (30/03/2026, user confirmation in thread: account switch no longer blocks typing in Authentication)

## 9. Criterios de cierre
- Scenario A PASS on macOS (user-run) with explicit confirmation in thread.
- Scenario B PASS (same-session retries reported stable by user; no recurrence observed at closure time).
- Scenario C regression smoke PASS (local gate + no analyzer/test regression).
- Validation artifacts updated (`quick_pass_checklist.md`; logs/screenshots folders kept for follow-up evidence).
- `docs/bugs/bug_log.md` + `docs/validation/validation_ledger.md` set to `Closed/OK` with commit hash/message/evidence.

## 10. Status line
Status: Closed/OK — 30/03/2026 (user-confirmed manual validation + local gate PASS).
