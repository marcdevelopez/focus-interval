# Rapid Validation Checklist — Fix 2026-03-02

Date: 2026-03-02
Scope: Allow prod debug override (`APP_ENV=prod` with `ALLOW_PROD_IN_DEBUG=true`).
Status: ✅ Completed

## Exact Repro (executed)

- [x] Chrome debug + prod + override:
  `flutter run -d chrome --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true`
- [x] macOS debug + prod + override:
  `flutter run -d macos --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true`
- [x] Chrome debug + prod without override:
  `flutter run -d chrome --dart-define=APP_ENV=prod`
  (manual confirmation; no log recorded)
- [x] Chrome release + prod:
  `flutter run -d chrome --release --dart-define=APP_ENV=prod`
  (manual confirmation; no log recorded)

## Evidence

- Chrome debug log:
  `docs/bugs/validation_fix_2026_03_02-01/logs/2026-03-02_web_chrome_debug.log`
- macOS debug log:
  `docs/bugs/validation_fix_2026_03_02-03/logs/2026_03_02_macos_debug.log`
