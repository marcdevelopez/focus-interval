# Plan — Rapid Validation Fix (2026-03-02)

Date: 2026-03-02
Scope: Allow prod override in debug on all platforms (temporary).

## Context
- In debug, `APP_ENV=prod` is blocked and the app stays on "Starting Focus Interval...".
- We need a temporary override in debug for real Firebase testing while staging is not available.

## Exact Repro (before the fix)
1. Run on Chrome (debug):
   `flutter run -d chrome --dart-define=APP_ENV=prod`
2. Run on macOS (debug):
   `flutter run -d macos --dart-define=APP_ENV=prod`
3. Current result: the app stays on "Starting Focus Interval...".

## Required change
- Allow `APP_ENV=prod` in debug only when `ALLOW_PROD_IN_DEBUG=true`.
- Keep the block when the flag is not present.
- Must be reverted once staging exists.

## Rapid validation (after the fix)
1. Chrome debug with prod + override:
   `flutter run -d chrome --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true`
   Expected: app boots and allows Account Mode login.
2. macOS debug with prod + override:
   `flutter run -d macos --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true`
   Expected: app boots and allows Account Mode login.
3. Chrome debug with prod without override:
   `flutter run -d chrome --dart-define=APP_ENV=prod`
   Expected: still blocked in debug (StateError).
4. Chrome release prod without override:
   `flutter run -d chrome --release --dart-define=APP_ENV=prod`
   Expected: behavior unchanged.

## Result (2026-03-02)
- Chrome debug + prod + override: boots and allows Account Mode login.
- macOS debug + prod + override: boots and allows Account Mode login.
- Chrome debug + prod without override: remains blocked (expected).
- Chrome release + prod: unchanged (expected).

## Evidence
- Chrome debug log:
  `docs/bugs/validation_fix_2026_03_02-01/logs/2026-03-02_web_chrome_debug.log`
- macOS debug log:
  `docs/bugs/validation_fix_2026_03_02-03/logs/2026_03_02_macos_debug.log`
- Manual confirmations: debug without override, release prod (no logs recorded).

## Tracking
- State: Validated (2026-03-02).
- Commit: d5e08ae "Allow prod debug override on all platforms"
