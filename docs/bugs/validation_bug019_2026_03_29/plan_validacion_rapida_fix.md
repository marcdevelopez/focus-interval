# Plan validacion rapida fix

## 1. Header
- Date: 2026-03-29
- Branch: `fix/bug019-android-back-navigation-exit`
- Commit hash: `a4b1915` (docs-registration baseline)
- Bugs covered: `BUG-019` / `BUGLOG-019`
- Target devices: `android_RMX3771` (primary), `macos` (control)

## 2. Objetivo
Validate and document the intermittent Android system-back regression where app flows under Run Mode/Groups Hub can terminate the app instead of returning to the app root route. This packet defines exact repro, expected fixed behavior, and closure evidence rules before runtime implementation starts.
Additionally, this validation must preserve existing stack-based back behavior on
screens that already navigate correctly (for example, Settings).

## 3. Sintoma original
From user perspective, pressing Android back sometimes closes Focus Interval immediately (returns to launcher) without warning, instead of going back to the initial app screen (Task List root). The issue is intermittent and appears after route-replacement navigation paths (Task List -> Groups Hub, Task List -> Run Mode, cancel/re-entry flows).

## 4. Root cause
Root cause is not confirmed yet. Current hypothesis: top-level routes (`/timer/:id`, `/groups`) are often opened with replacement navigation (`go`) and may have no pop stack; Android system back then exits the app unless an explicit deterministic fallback route is handled. Additional hypothesis: current Run Mode PopScope blocking conditions may not cover all non-active execution combinations.

## 5. Protocolo de validacion

### Scenario A — Groups Hub root back behavior (Android)
- Preconditions:
  1. App open in Account or Local mode.
  2. Navigate to `/groups` from Task List.
- Steps:
  1. Confirm current screen is Groups Hub.
  2. Press Android system back once.
  3. Repeat from fresh app launch three times.
- Expected with fix:
  - App navigates to Task List root (`/tasks`) and does not terminate unexpectedly.
- Reference result without fix:
  - Intermittent immediate app termination to launcher.

### Scenario B — Run Mode non-active back behavior (Android)
- Preconditions:
  1. Open a group in Run Mode (`/timer/:groupId`) with no active-execution cancellation dialog expected.
- Steps:
  1. Press Android system back once.
  2. Repeat after entering Run Mode from different paths (`/tasks`, `/groups`).
- Expected with fix:
  - Back returns to app root route according to navigation policy; app does not terminate unexpectedly.
- Reference result without fix:
  - Intermittent app termination.

### Scenario C — Run Mode active execution guard behavior (Android)
- Preconditions:
  1. Group actively running in Run Mode.
- Steps:
  1. Press Android system back.
  2. Observe confirmation/cancel policy.
  3. Confirm that rejecting cancel keeps run open.
- Expected with fix:
  - Existing cancel/confirmation policy is preserved; no silent app exit.
- Reference result without fix:
  - Inconsistent behavior depending on route stack and flow sequence.

### Scenario D — Settings stack-back non-regression (Android)
- Preconditions:
  1. Start from Task List root (`/tasks`).
  2. Navigate to Settings (`/settings`) using current UI entrypoint.
- Steps:
  1. Confirm Settings is visible.
  2. Press AppBar back.
  3. Reopen Settings.
  4. Press Android system back.
- Expected with fix:
  - Both AppBar back and Android system back return to the previous route in stack.
  - No fallback-to-root override is applied while stack pop is available.
  - No app termination.
- Reference result without fix:
  - Not a known bug path; this is an explicit non-regression guard.

## 6. Comandos de ejecucion

```bash
flutter run -v --debug -d RMX3771 --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug019_2026_03_29/logs/2026-03-29_bug019_a4b1915_android_RMX3771_debug.log
```

```bash
flutter run -v --debug -d macos --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug019_2026_03_29/logs/2026-03-29_bug019_a4b1915_macos_debug.log
```

## 7. Log analysis - quick scan

### Bug present signals
```bash
grep -nE "AppLifecycleState\.detached|SystemNavigator\.pop|onPopInvoked|route=/timer|route=/groups" \
  docs/bugs/validation_bug019_2026_03_29/logs/2026-03-29_bug019_a4b1915_android_RMX3771_debug.log
```

### Fix working signals
```bash
grep -nE "route=/tasks|Cancel nav:|didPop=true|didPop=false" \
  docs/bugs/validation_bug019_2026_03_29/logs/2026-03-29_bug019_a4b1915_android_RMX3771_debug.log
```

```bash
grep -nE "route=/settings|route=/tasks|didPop=true|didPop=false" \
  docs/bugs/validation_bug019_2026_03_29/logs/2026-03-29_bug019_a4b1915_android_RMX3771_debug.log
```

## 8. Verificacion local
- [ ] `flutter analyze` (pending)
- [ ] `flutter test test/presentation/timer_screen_completion_navigation_test.dart` (pending)
- [ ] Additional navigation/system-back regression tests (pending; TBD after implementation)

## 9. Criterios de cierre
- Exact repro PASS on Android (`Scenario A`, `B`, `C`) with log evidence.
- Settings stack-back non-regression PASS (`Scenario D`) with log evidence.
- Regression smoke PASS (no break in active-run cancel confirmation and no forced app exit).
- Validation artifacts fully updated:
  - `quick_pass_checklist.md`
  - runtime logs in `logs/`
  - screenshots in `screenshots/` when needed.
- `docs/bugs/bug_log.md` + `docs/validation/validation_ledger.md` moved to `Closed/OK` with commit/evidence fields.

## 10. Status line
Status: Open
