# Codex handoff — BUG-030 auto-open suppression regression

## 1. Branch

`fix/bug030-auto-open-suppression`

Create from `develop` after `fix/bug028-paused-ends-projection` has been merged.

## 2. Reference commit

Base commit: HEAD of `develop` after BUG-028 merge (hash TBD).
Key file to edit: `lib/widgets/active_session_auto_opener.dart`

## 3. Regla obligatoria

Read `CLAUDE.md` sections 3 and 4 BEFORE writing any code.
Read the [PHASE6] test at `test/presentation/timer_screen_syncing_overlay_test.dart:2362`
in full before touching `_handleActiveSessionChange`. That test must stay green.

## 4. Overview

One commit. One file with runtime changes (`active_session_auto_opener.dart`).
One file with test changes (`timer_screen_syncing_overlay_test.dart`).

The fix adds a single new field `_userDepartedGroupId` and guards three paths that
currently defeat the "intentional departure" suppression contract of Fix 15. A new
widget test validates the BUG-030 scenario. The PHASE6 test must stay green
(analytically verified — see section 5.5 note).

## 5. Per-fix sections

---

### Fix A — New field declaration

**File:** `lib/widgets/active_session_auto_opener.dart`

**Why:** The new sentinel field records that the user was auto-opened to a specific
group and then explicitly navigated away. Unlike `_autoOpenSuppressedGroupId` (which
protects planning routes), this flag is not cleared by resume events or VM disposal.

**Current code** (after line 40, `bool _lastPomodoroVmExists = false;`):
```dart
  bool _lastPomodoroVmExists = false;

  @override
  void initState() {
```

**Replacement:**
```dart
  bool _lastPomodoroVmExists = false;
  String? _userDepartedGroupId;

  @override
  void initState() {
```

**Constraints:** Do not rename or reorder existing fields.

---

### Fix B — Clear the new field in the session-null block

**File:** `lib/widgets/active_session_auto_opener.dart`

**Why:** When the active session ends (null), all auto-open state is reset. The
departure flag must be cleared too.

**Current code** (lines 100-112):
```dart
    if (session == null) {
      _autoOpenInFlight = false;
      _autoOpenedGroupId = null;
      _autoOpenSuppressedGroupId = null;
      _pendingGroupId = null;
      _lastAutoOpenAttemptAt = null;
      _lastAutoOpenAttemptGroupId = null;
      _retryAttempts = 0;
      _resumeAutoOpenPending = false;
      _retryTimer?.cancel();
      _retryTimer = null;
      _lastPomodoroVmExists = vmExists;
      return;
    }
```

**Replacement:**
```dart
    if (session == null) {
      _autoOpenInFlight = false;
      _autoOpenedGroupId = null;
      _autoOpenSuppressedGroupId = null;
      _userDepartedGroupId = null;
      _pendingGroupId = null;
      _lastAutoOpenAttemptAt = null;
      _lastAutoOpenAttemptGroupId = null;
      _retryAttempts = 0;
      _resumeAutoOpenPending = false;
      _retryTimer?.cancel();
      _retryTimer = null;
      _lastPomodoroVmExists = vmExists;
      return;
    }
```

---

### Fix C — Early departure detection (new block, CRITICAL ordering)

**File:** `lib/widgets/active_session_auto_opener.dart`

**Why:** The VM disposal path (cause 1) and resume path (cause 2) run at lines
134 and 123 respectively. Departure detection must happen BEFORE those paths so
the flag is set when they execute their guards. Placing the detection in the
navigator context block (line 144) is too late — `_autoOpenedGroupId` would
already be cleared by the VM disposal path.

**Current code** (lines 121-123 — the blank line and start of resume block):
```dart

    if (_resumeAutoOpenPending) {
```

**Replacement:**
```dart

    // Detect intentional departure BEFORE resume and VM-disposal paths can clear
    // _autoOpenedGroupId. This is the only correct position — any later placement
    // arrives after those paths erase the state needed for detection.
    if (_autoOpenedGroupId == groupId) {
      final detectNavCtx = widget.navigatorKey.currentContext;
      if (detectNavCtx != null && !_isAlreadyInTimer(groupId)) {
        _userDepartedGroupId = groupId;
      }
    }

    if (_resumeAutoOpenPending) {
```

**Constraints:**
- Do NOT move the existing `if (_resumeAutoOpenPending)` block. Insert BEFORE it.
- Do NOT call any `async` method inside this block.
- The local variable is named `detectNavCtx` (not `navigatorContext`) to avoid
  shadowing the `navigatorContext` variable declared at line 144.

---

### Fix D — Guard the resume path

**File:** `lib/widgets/active_session_auto_opener.dart`

**Why:** On macOS, `AppLifecycleState.resumed` fires on every window focus change.
The current code clears `_autoOpenSuppressedGroupId` unconditionally, defeating
user-intent suppression for the same group. With the departure flag set, we must
preserve the suppress state.

**Current code** (lines 123-131):
```dart
    if (_resumeAutoOpenPending) {
      debugPrint(
        '[RunModeDiag] Auto-open resume trigger. Clearing auto-open state '
        'group=$groupId route=${_currentRoute()}',
      );
      _autoOpenedGroupId = null;
      _autoOpenSuppressedGroupId = null;
      _resumeAutoOpenPending = false;
    }
```

**Replacement:**
```dart
    if (_resumeAutoOpenPending) {
      debugPrint(
        '[RunModeDiag] Auto-open resume trigger. Clearing auto-open state '
        'group=$groupId route=${_currentRoute()}',
      );
      _autoOpenedGroupId = null;
      if (_userDepartedGroupId != groupId) {
        _autoOpenSuppressedGroupId = null;
      }
      _resumeAutoOpenPending = false;
    }
```

**Constraints:** Only add the guard around `_autoOpenSuppressedGroupId = null`. Do
not change anything else in this block.

---

### Fix E — Guard the VM disposal path (PRIMARY FIX)

**File:** `lib/widgets/active_session_auto_opener.dart`

**Why:** This is the primary cause of BUG-030. `PomodoroViewModel` is `autoDispose`
and is discarded on every navigation away from `/timer/:groupId`. The current code
treats this as an "unexpected VM disposal" (Block 573 Phase 6 intent) and forces a
re-open. With the departure flag set, we know the departure was intentional and must
NOT force a re-open.

The PHASE6 contract must be preserved: when the VM is disposed while the user IS
still on `/timer/:groupId` (truly unexpected), `_userDepartedGroupId` will NOT be
set (because Fix C checks `!_isAlreadyInTimer(groupId)` which is false when user
is still in timer) → VM disposal path fires with `forceTimerRefresh=true` as before.

**Current code** (lines 133-142):
```dart
    var forceTimerRefresh = false;
    if (_autoOpenedGroupId == groupId && !vmExists && vmWasAlive) {
      debugPrint(
        '[RunModeDiag] Auto-open recovery: VM disposed, clearing guard '
        'group=$groupId route=${_currentRoute()}',
      );
      _autoOpenedGroupId = null;
      _autoOpenSuppressedGroupId = null;
      forceTimerRefresh = true;
    }
```

**Replacement:**
```dart
    var forceTimerRefresh = false;
    if (_autoOpenedGroupId == groupId && !vmExists && vmWasAlive) {
      _autoOpenedGroupId = null;
      if (_userDepartedGroupId != groupId) {
        // Unexpected VM disposal while user was still on the timer route.
        // Clear guard and force refresh (Phase-6 recovery contract).
        debugPrint(
          '[RunModeDiag] Auto-open recovery: VM disposed, clearing guard '
          'group=$groupId route=${_currentRoute()}',
        );
        _autoOpenSuppressedGroupId = null;
        forceTimerRefresh = true;
      } else {
        debugPrint(
          '[RunModeDiag] Auto-open suppressed (VM disposed after intentional departure) '
          'group=$groupId route=${_currentRoute()}',
        );
      }
    }
```

**Constraints:**
- The `debugPrint` message `'Auto-open recovery: VM disposed, clearing guard'` must
  remain INSIDE the `_userDepartedGroupId != groupId` branch. The PHASE6 test
  (`timer_screen_syncing_overlay_test.dart:2484`) checks for this exact string —
  it still passes because in that test `_userDepartedGroupId` is null. Do not alter
  the string.
- The `forceTimerRefresh = true` line stays inside the same branch.
- `_autoOpenedGroupId = null` must be OUTSIDE the guard (clear it in all cases).

---

### Fix F — Add departure to suppression check

**File:** `lib/widgets/active_session_auto_opener.dart`

**Why:** Even if the earlier guards work, the suppression check is the final safety
net. Adding `_userDepartedGroupId == groupId` as a condition makes the departure
flag an independent suppressor that does not depend on `_autoOpenSuppressedGroupId`
being set.

**Current code** (lines 168-177):
```dart
    if (_autoOpenInFlight ||
        _autoOpenedGroupId == groupId ||
        _autoOpenSuppressedGroupId == groupId) {
      debugPrint(
        '[RunModeDiag] Auto-open suppressed (in-flight=$_autoOpenInFlight '
        'opened=$_autoOpenedGroupId route=${_currentRoute()})',
      );
      _lastPomodoroVmExists = vmExists;
      return;
    }
```

**Replacement:**
```dart
    if (_autoOpenInFlight ||
        _autoOpenedGroupId == groupId ||
        _autoOpenSuppressedGroupId == groupId ||
        _userDepartedGroupId == groupId) {
      debugPrint(
        '[RunModeDiag] Auto-open suppressed (in-flight=$_autoOpenInFlight '
        'opened=$_autoOpenedGroupId departed=$_userDepartedGroupId '
        'route=${_currentRoute()})',
      );
      _lastPomodoroVmExists = vmExists;
      return;
    }
```

---

### Fix G — Clear departure when user explicitly returns to timer

**File:** `lib/widgets/active_session_auto_opener.dart`

**Why:** If the user navigated away (departure set) but then explicitly returns to
Run Mode via "Open Run Mode" or any explicit navigation, the departure flag must be
cleared so the auto-open lifecycle tracks normally from that point.

**Current code** (lines 158-165, inside the navigator context block):
```dart
      if (_autoOpenedGroupId == null && inTimer && !forceTimerRefresh) {
        debugPrint(
          '[RunModeDiag] Auto-open state set (already in timer) '
          'group=$groupId route=${_currentRoute()}',
        );
        _autoOpenedGroupId = groupId;
        _autoOpenSuppressedGroupId = null;
      }
```

**Replacement:**
```dart
      if (_autoOpenedGroupId == null && inTimer && !forceTimerRefresh) {
        debugPrint(
          '[RunModeDiag] Auto-open state set (already in timer) '
          'group=$groupId route=${_currentRoute()}',
        );
        _autoOpenedGroupId = groupId;
        _autoOpenSuppressedGroupId = null;
        _userDepartedGroupId = null;
      }
```

**Constraints:** Only add `_userDepartedGroupId = null;`. Do not change anything else
in this block.

---

## 6. New widget test

**File:** `test/presentation/timer_screen_syncing_overlay_test.dart`

**Location:** Insert immediately AFTER the `[PHASE6]` test (after its closing `});`
at line ~2508), before the `[PHASE5]` test.

**Test name:** `'[BUG-030] auto-open stays suppressed after intentional departure from Run Mode'`

**What to test:**
1. Start with router on `/timer/:groupId` (initial location).
2. Wait for `_autoOpenedGroupId` to be set (pump + pump(80ms), same as PHASE6 test).
3. Navigate the router to `/groups` (simulating user pressing back from Run Mode).
4. Pump once to let the route change settle.
5. Close vmSub and invalidate the VM (simulating VM autoDispose after navigation).
6. Pump once to let VM dispose.
7. Emit a new session tick via `sessionRepo.emit(nextSession)`.
8. Pump + pump(200ms).
9. **Assert:** router current route is still `/groups` (no navigation back to `/timer/:groupId`).
10. **Assert:** logs contain `'Auto-open suppressed (VM disposed after intentional departure)'`.
11. **Assert:** logs do NOT contain `'Auto-open recovery: forcing timer refresh'`.

The test scaffolding (container, overrides, group/session builders, router routes)
is identical to the PHASE6 test. Reuse those helpers. The only differences are:
- Step 3 (navigate to `/groups` before invalidating the VM).
- The final assertions (route stays, different log message).

**Note on route navigation in tests:** use `router.go('/groups')` or equivalent
GoRouter navigation. Pump afterwards to let the route change propagate before
invalidating the VM.

## 7. Commit order

Single commit:

```
fix(bug030): preserve intentional-departure suppression in ActiveSessionAutoOpener

Add _userDepartedGroupId sentinel that survives resume and VM-disposal paths.
Guards VM-disposal (primary cause), resume (macOS secondary), and suppression
check. PHASE6 recovery contract preserved: VM disposal while still in timer
route is unaffected. Fixes regression of Fix-15 auto-open gating (Blocks 485-486).
```

## 8. Tests to run before handing back to Claude

```bash
flutter analyze

# PHASE6 must stay green
flutter test test/presentation/timer_screen_syncing_overlay_test.dart \
  --plain-name "[PHASE6] auto-open guard clears when VM is disposed mid-session"

# New BUG-030 test must pass
flutter test test/presentation/timer_screen_syncing_overlay_test.dart \
  --plain-name "[BUG-030] auto-open stays suppressed after intentional departure from Run Mode"

# Full suite
flutter test test/presentation/timer_screen_syncing_overlay_test.dart
flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart
flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart
```

All must PASS before returning control to Claude for QA review.
