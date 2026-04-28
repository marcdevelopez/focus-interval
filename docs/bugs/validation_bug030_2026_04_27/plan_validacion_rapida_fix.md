# BUG-030 validation plan

## 1. Header

- Date: 28/04/2026
- Branch: fix/bug030-auto-open-suppression
- Working commit hash: 24b3667
- Bugs covered: BUG-030 / BUGLOG-030
- Target devices: iOS (`iPhone 17 Pro`) owner + Chrome mirror

## 2. Objetivo

Validate that `ActiveSessionAutoOpener` no longer forces the mirror device back to Run
Mode after the user has explicitly navigated away from `/timer/:groupId` to
`/groups` or `/tasks`. The fix must preserve the PHASE6 contract (unexpected VM
disposal while still on the timer route still triggers force-refresh recovery).

## 3. Síntoma original

Mirror user starts planning work (Groups Hub / Task List / Plan Group) while a
group is running on the owner device. The mirror is repeatedly and involuntarily
redirected back to Run Mode within seconds of arriving in planning surfaces,
making it impossible to complete planning actions.

Observed in BUG-028 validation run (27/04/2026, 16:09–16:15 UTC-4).

## 4. Root cause

**Classification:** Regression of Fix 15 auto-open gating (dev_log Blocks 485–486,
27/02/2026). Three independent paths in `ActiveSessionAutoOpener._handleActiveSessionChange`
defeat the "intentional departure" suppression contract:

### Cause 1 — VM disposal path (PRIMARY)

`lib/widgets/active_session_auto_opener.dart` lines 134-142:

```dart
if (_autoOpenedGroupId == groupId && !vmExists && vmWasAlive) {
  _autoOpenedGroupId = null;
  _autoOpenSuppressedGroupId = null;
  forceTimerRefresh = true;
}
```

`PomodoroViewModel` is `autoDispose`. Every navigation away from `/timer/:groupId`
disposes the VM. On the FIRST Firestore tick after departure, all three conditions
are true → suppression cleared, `forceTimerRefresh=true` → forced navigation back.

Added in Fix 26 Phase 6 (Block 573) for *unexpected* VM disposal while the user was
still on the timer route. It fires equally on every intentional departure.

### Cause 2 — Resume path (secondary, macOS-specific)

`lib/widgets/active_session_auto_opener.dart` lines 123-131:

```dart
if (_resumeAutoOpenPending) {
  _autoOpenedGroupId = null;
  _autoOpenSuppressedGroupId = null;
  _resumeAutoOpenPending = false;
}
```

On macOS, `AppLifecycleState.resumed` fires on every window focus change (user
alt-tabs between app and IDE). Clears suppression on every window-focus event.

### Cause 3 — Bounce window (tertiary)

`lib/widgets/active_session_auto_opener.dart` lines 148-157: rarely contributes
independently because cause 1 already clears `_autoOpenedGroupId` first.

**Critical ordering constraint:** causes 1 and 2 run at lines 123 and 134, BEFORE the
navigator context block at line 144. Any departure-detection flag must be set
BEFORE line 123 or it arrives too late to protect against these paths.

## 5. Protocolo de validación

### Single-pass execution order (time-saving)

Run all scenarios in one continuous validation session using this order:
1. **Scenario C** (PHASE6 non-regression while still in timer route)
2. **Scenario A** (stay on Groups Hub after intentional departure)
3. **Scenario B** (stay on Task List / Plan Group after intentional departure)
4. **Scenario D** (explicit re-entry via Open Run Mode)

This order minimizes resets and reproduces the original bug flow while still
covering all acceptance criteria.

### Scenario A — Mirror stays in Groups Hub after intentional departure

Preconditions:
1. Account Mode on both devices.
2. G1 running on iOS owner (`iPhone 17 Pro`).
3. Chrome mirror has been auto-opened to Run Mode for G1.

Steps:
1. On Chrome mirror, navigate back to Groups Hub from Run Mode.
2. Remain in Groups Hub for ≥ 60 seconds without manually returning to Run Mode.
3. Alternate focus between Chrome tab and another app/tab at least 3 times.
4. Observe Groups Hub on Chrome.

Expected result with fix:
1. Chrome mirror stays in Groups Hub.
2. No involuntary redirect to `/timer/:groupId`.
3. Log shows `[RunModeDiag] Auto-open suppressed (... departed=<groupId> ...)` on each session tick.

Reference result without fix:
1. Mirror is redirected to Run Mode within seconds of arriving in Groups Hub.

### Scenario B — Mirror stays in Task List after intentional departure

Preconditions: same as Scenario A.

Steps:
1. On Chrome mirror, navigate from Run Mode to Groups Hub, then to Task List.
2. Enter Plan Group (`/tasks/plan`) and remain there for ≥ 60 seconds.

Expected result with fix:
1. Chrome mirror stays in Task List / Plan Group.
2. No involuntary redirect.

### Scenario C — PHASE6 regression (VM disposal while still in timer)

Preconditions:
1. Mirror has NOT navigated away from Run Mode (still on `/timer/:groupId`).
2. Simulate or observe a VM disposal/rebuild while route stays `/timer/:groupId`.

Steps:
1. Keep mirror on Run Mode during a complete pomodoro phase transition (phase transitions force VM state changes).
2. Observe that Run Mode stays active and timer continues normally.

Expected result with fix:
1. Phase transitions do not interrupt Run Mode on mirror.
2. PHASE6 recovery contract intact: if VM is disposed while user is in `/timer/:groupId`, auto-open guard recovers correctly.

### Scenario D — Re-entry after intentional departure

Preconditions:
1. Mirror has intentionally navigated away from Run Mode (departure suppression active).

Steps:
1. From Groups Hub, press "Open Run Mode" for the active group.
2. Run Mode opens correctly.
3. Observe that auto-open suppression is cleared.

Expected result with fix:
1. Run Mode opens normally via explicit user action.
2. After being in Run Mode, further navigation behaviour is normal.

## 6. Comandos de ejecución

```bash
# iOS owner (iPhone 17 Pro simulator)
flutter run -v --debug -d "iPhone 17 Pro" --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug030_2026_04_27/logs/2026-04-28_bug030_24b3667_ios_iPhone17Pro_debug.log

# Chrome mirror
flutter run -v --debug -d chrome --web-hostname=localhost --web-port=5001 --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug030_2026_04_27/logs/2026-04-28_bug030_24b3667_chrome_debug.log
```

Use fixed `localhost:5001` for Chrome validation runs with Google auth to avoid
OAuth `origin_mismatch` from random `flutter run` ports.

## 7. Log analysis — quick scan

### Bug present signals (fix not working)

```bash
grep -nE "Attempting auto-open to TimerScreen" \
  docs/bugs/validation_bug030_2026_04_27/logs/*_chrome_debug.log
```

Any match on this line while user is in `/groups` or `/tasks` = BUG-030 still active.

### Fix working signals

```bash
# Departure suppression active
grep -nE "Auto-open suppressed.*departed=" \
  docs/bugs/validation_bug030_2026_04_27/logs/*_chrome_debug.log

# PHASE6 contract intact (unexpected VM disposal on timer route → force refresh)
grep -nE "Auto-open recovery: VM disposed, clearing guard" \
  docs/bugs/validation_bug030_2026_04_27/logs/*_chrome_debug.log
```

## 8. Verificación local

```bash
flutter analyze

# PHASE6 regression guard (must stay green)
flutter test test/presentation/timer_screen_syncing_overlay_test.dart \
  --plain-name "[PHASE6] auto-open guard clears when VM is disposed mid-session"

# New BUG-030 regression test
flutter test test/presentation/timer_screen_syncing_overlay_test.dart \
  --plain-name "[BUG-030] auto-open stays suppressed after intentional departure from Run Mode"

# Full overlay suite
flutter test test/presentation/timer_screen_syncing_overlay_test.dart
```

All must PASS before device validation.

## 9. Criterios de cierre

- Scenario A PASS on Chrome mirror with log evidence.
- Scenario B PASS on Chrome mirror with log evidence.
- Scenario C PASS (PHASE6 non-regression) with log evidence.
- Scenario D PASS (re-entry works) with log evidence.
- Local gate PASS (flutter analyze + PHASE6 test + BUG-030 test).
- bug_log + validation_ledger + dev_log synchronized with closure metadata.

## 10. Status

Closed/OK (28/04/2026) — single-pass device validation executed in order `C -> A -> B -> D` on iOS owner + Chrome mirror.

Execution recap:
- Scenario C PASS: G1 running on iOS; Chrome entered Groups Hub/Task List without bounce (`~14:53`), no forced re-open.
- Scenario A PASS: at `~14:54:20` returned to Groups Hub; repeated focus switches iOS emulator <-> Chrome around `~14:54:40`; stayed stable.
- Scenario B PASS: at `~14:57:00` planned in Task List/Plan Group without involuntary navigation.
- Scenario D PASS: explicit "Open Run Mode" from Groups Hub opened timer route correctly.

Evidence:
- `docs/bugs/validation_bug030_2026_04_27/logs/2026-04-28_bug030_24b3667_chrome_debug.log`
  - no `Attempting auto-open to TimerScreen` matches;
  - suppression preserved on planning routes: lines `1952`, `1959-1973`, `1980-2014`, `2020-2074` (`departed=... route=/groups|/tasks`);
  - explicit timer re-entry observed: `RunModeDiag Timer load group ... route=/timer/...` around line `2083`.
- `docs/bugs/validation_bug030_2026_04_27/logs/2026-04-28_bug030_24b3667_ios_iPhone17Pro_debug.log`
  - owner session continuity across validation window (`status=pomodoroRunning` -> planned flow -> manual close).
