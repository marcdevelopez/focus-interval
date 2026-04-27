# BUG-030 validation plan

## 1. Header

- Date: 27/04/2026
- Branch: fix/bug030-auto-open-suppression (to be created from develop after BUG-028 merges)
- Working commit hash: pending (base from develop after BUG-028 merge)
- Bugs covered: BUG-030 / BUGLOG-030
- Target devices: macOS mirror + Android owner

## 2. Objetivo

Validate that `ActiveSessionAutoOpener` no longer forces the mirror device back to Run
Mode after the user has explicitly navigated away from `/timer/:groupId` to
`/groups` or `/tasks`. The fix must preserve the PHASE6 contract (unexpected VM
disposal while still on the timer route still triggers force-refresh recovery).

## 3. Síntoma original

macOS mirror user starts planning work (Groups Hub / Task List) while a group is
running on the Android owner. The mirror is repeatedly and involuntarily redirected
back to Run Mode within seconds of arriving in Groups Hub or Task List, making it
impossible to complete planning actions.

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

### Scenario A — Mirror stays in Groups Hub after intentional departure

Preconditions:
1. Account Mode on both devices.
2. G1 running on Android owner.
3. macOS mirror has been auto-opened to Run Mode for G1.

Steps:
1. On macOS mirror, navigate back to Groups Hub from Run Mode.
2. Remain in Groups Hub for ≥ 60 seconds without manually returning to Run Mode.
3. Alternate focus between macOS app window and another application at least 3 times.
4. Observe Groups Hub on macOS.

Expected result with fix:
1. macOS mirror stays in Groups Hub.
2. No involuntary redirect to `/timer/:groupId`.
3. Log shows `[RunModeDiag] Auto-open suppressed (... departed=<groupId> ...)` on each session tick.

Reference result without fix:
1. Mirror is redirected to Run Mode within seconds of arriving in Groups Hub.

### Scenario B — Mirror stays in Task List after intentional departure

Preconditions: same as Scenario A.

Steps:
1. On macOS mirror, navigate from Run Mode to Groups Hub, then to Task List.
2. Remain in Task List for ≥ 60 seconds.

Expected result with fix:
1. macOS mirror stays in Task List.
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
# Android owner
flutter run -v --debug -d RMX3771 --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug030_2026_04_27/logs/2026-04-XX_bug030_<commit>_android_RMX3771_debug.log

# macOS mirror
flutter run -v --debug -d macos --dart-define=APP_ENV=prod --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee docs/bugs/validation_bug030_2026_04_27/logs/2026-04-XX_bug030_<commit>_macos_debug.log
```

Replace `XX` with actual date and `<commit>` with 7-char commit hash.

## 7. Log analysis — quick scan

### Bug present signals (fix not working)

```bash
grep -nE "Attempting auto-open to TimerScreen" \
  docs/bugs/validation_bug030_2026_04_27/logs/*_macos_debug.log
```

Any match on this line while user is in `/groups` or `/tasks` = BUG-030 still active.

### Fix working signals

```bash
# Departure suppression active
grep -nE "Auto-open suppressed.*departed=" \
  docs/bugs/validation_bug030_2026_04_27/logs/*_macos_debug.log

# PHASE6 contract intact (unexpected VM disposal on timer route → force refresh)
grep -nE "Auto-open recovery: VM disposed, clearing guard" \
  docs/bugs/validation_bug030_2026_04_27/logs/*_macos_debug.log
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

- Scenario A PASS on macOS mirror with log evidence.
- Scenario B PASS on macOS mirror with log evidence.
- Scenario C PASS (PHASE6 non-regression) with log evidence.
- Scenario D PASS (re-entry works) with log evidence.
- Local gate PASS (flutter analyze + PHASE6 test + BUG-030 test).
- bug_log + validation_ledger + dev_log synchronized with closure metadata.

## 10. Status

Open (27/04/2026)
