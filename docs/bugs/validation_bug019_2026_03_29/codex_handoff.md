# Codex Handoff — BUG-019 Android Back Navigation Exit

## 1. Branch

`fix/bug019-android-back-navigation-exit` (already created — do NOT create a new branch)

## 2. Reference commit

`39c1777` (latest docs commit on this branch)

## 3. Regla obligatoria

**Read `CLAUDE.md` sections 3 and 4 before coding.** This fix touches navigation
and widget lifecycle. No changes to session/timer/sync logic are permitted.
G-2 applies: navigation lifecycle changes must be in dedicated commits with no
unrelated UI edits.

## 4. Overview

Two commits. Two files changed. No new files created, no test files modified (new
tests are added to the existing file). Order is GroupsHubScreen first (simpler,
no existing logic), then TimerScreen (modifies existing PopScope).

Commit 1 — `fix(bug019): add PopScope fallback in GroupsHubScreen`
Commit 2 — `fix(bug019): fix PopScope empty-stack exit in TimerScreen`
Commit 3 — `test(bug019): add system-back regression tests for back navigation`

---

## 5a. Fix 1 — GroupsHubScreen

**File**: `lib/presentation/screens/groups_hub_screen.dart`

**Why**: `GroupsHubScreen` is always navigated to via `context.go('/groups')`, which
replaces the entire navigation stack. When the stack has a single entry and the user
presses Android system back, go_router has nothing to pop and delegates to Android,
which exits the app. There is currently no `PopScope` on this screen.

The fix is to wrap the returned `Scaffold` in a `PopScope(canPop: false)` that
intercepts all pops and either pops the stack (if something is there) or navigates
to `/tasks` as the fallback root.

**Exact current code block** (line 315 in `groups_hub_screen.dart`):

```dart
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Groups Hub'),
        actions: [const ModeIndicatorAction(compact: true)],
      ),
```

**Exact replacement code block**:

```dart
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/tasks');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Groups Hub'),
          actions: [const ModeIndicatorAction(compact: true)],
        ),
```

**Closing bracket**: The `return Scaffold(...)` statement ends at the bottom of
`build()`. After wrapping, close the `PopScope` child with one additional `)` + `;`
to close the `PopScope`. The existing closing `)` + `;` of `Scaffold` becomes the
closing of `child: Scaffold(...)` inside `PopScope`.

**Constraints**:
- Do NOT touch any logic inside `GroupsHubScreen` beyond this structural wrap.
- The `onPopInvokedWithResult` must be synchronous (no `async`) — no dialog, no
  awaiting anything.
- No import changes needed: `go_router` is already imported (`context.go` is used
  at line 327).
- Do NOT add `leading` to the AppBar or change any existing back-button behavior.

---

## 5b. Fix 2 — TimerScreen

**File**: `lib/presentation/screens/timer_screen.dart`

**Why**: `TimerScreen` is always navigated to via `context.go('/timer/:id')`, which
replaces the entire navigation stack. The current `PopScope` uses
`canPop: !shouldBlockExit`:

- When `shouldBlockExit=true` (active execution): `canPop=false` → intercepted →
  shows confirmation dialog via `_confirmExit`. **`_confirmExit` ALWAYS returns
  `false` for active execution** (it handles navigation internally via
  `_cancelAndNavigateToHub`). The `navigator.pop()` at line 734 is **dead code**
  — it is never reached when `shouldBlockExit=true`.

- When `shouldBlockExit=false` (non-active): `canPop=true` → go_router finds
  nothing to pop → Android exits the app. **This is the bug.**

The fix: change to `canPop: false` always. Split the handler into two paths:
active (delegates to existing `_confirmExit` unchanged) and non-active (pop if
possible, otherwise go to the appropriate root screen).

**CRITICAL — no regression on running group**: The active path (`shouldBlockExit=true`)
must be **unchanged in behavior**. We only delegate to `_confirmExit(state, vm)` and
return. We do NOT touch `_confirmExit`, `_cancelAndNavigateToHub`, or
`_confirmCancelDialog`. The only change to the active path is removing the unreachable
dead code (`navigator.pop()`).

**Exact current code block** (lines 727–735 in `timer_screen.dart`):

```dart
    return PopScope(
      canPop: !shouldBlockExit,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldExit = await _confirmExit(state, vm);
        if (!mounted || !shouldExit) return;
        navigator.pop();
      },
      child: Scaffold(
```

**Exact replacement code block**:

```dart
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (shouldBlockExit) {
          // Active execution: delegate to confirmation + cancellation flow.
          // _confirmExit handles dialog, group cancellation, and navigation
          // internally. It always returns false for active execution.
          // DO NOT add navigator.pop() here — it would be dead code and
          // could conflict with _cancelAndNavigateToHub.
          await _confirmExit(state, vm);
          return;
        }
        // Non-active: navigate back in stack, or fall back to root screen.
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(isLocalMode ? '/tasks' : '/groups');
        }
      },
      child: Scaffold(
```

**Variables already in scope** (captured from `build()` closure — do not redeclare):
- `shouldBlockExit` — line 645: `final shouldBlockExit = state.status.isActiveExecution;`
- `isLocalMode` — line 646: `final isLocalMode = appMode == AppMode.local;`
- `state` — line 640: `final state = ref.watch(pomodoroViewModelProvider);`
- `vm` — available in `build()` scope

**Constraints**:
- Do NOT touch any line in `timer_screen.dart` other than lines 727–735.
- Do NOT touch `_confirmExit`, `_cancelAndNavigateToHub`, `_confirmCancelDialog`.
- Do NOT add any session/group writes, cancellations, or state mutations.
- The `isLocalMode` variable is already defined at line 646. Do not add a new
  `ref.read(appModeProvider)` call — use the closure-captured `isLocalMode`.
- `context.canPop()` is go_router's method (not `Navigator.of(context).canPop()`).
  Both are imported via `go_router`. Use `context.canPop()`.

---

## 6. Commit order

```
Commit 1:
fix(bug019): add PopScope fallback in GroupsHubScreen

Wraps the Scaffold in PopScope(canPop: false). System back now
pops the stack if available, otherwise navigates to /tasks.
Fixes the root case where context.go('/groups') leaves no pop
history and Android exits the app on system back.

Commit 2:
fix(bug019): fix PopScope empty-stack exit in TimerScreen

Changes canPop from !shouldBlockExit to false (always intercept).
- Active path: delegates to _confirmExit unchanged (dead navigator.pop()
  removed; _confirmExit handles group cancellation and nav internally).
- Non-active path: pops stack if available, otherwise goes to /tasks
  or /groups per app mode.
No changes to _confirmExit, _cancelAndNavigateToHub, or any session logic.

Commit 3:
test(bug019): add system-back regression tests for back navigation

New tests in timer_screen_completion_navigation_test.dart covering:
- GroupsHubScreen: system back with empty stack → goes to /tasks.
- TimerScreen non-active: system back with empty stack → goes to root.
- TimerScreen active: system back shows confirmation dialog (no silent exit).
- Settings non-regression: system back pops correctly without fallback.
```

---

## 7. Tests to run

After all commits, run:

```bash
flutter analyze
```

```bash
flutter test test/presentation/timer_screen_completion_navigation_test.dart
flutter test test/presentation/timer_screen_syncing_overlay_test.dart
```

All must pass before handing back to Claude for QA review.

---

## 8. Test implementation guidance (Commit 3)

Add new `testWidgets` cases to
`test/presentation/timer_screen_completion_navigation_test.dart`.

### How to simulate system back in tests

```dart
// Triggers Android system back through the entire widget tree
await tester.binding.handlePopRoute();
await tester.pumpAndSettle();
```

### Test A — GroupsHubScreen system back navigates to /tasks

Setup: build a GoRouter with `/groups` as initial location (single entry stack —
use `GoRouter(initialLocation: '/groups', routes: [...])`). Pump `GroupsHubScreen`.
Action: `await tester.binding.handlePopRoute(); await tester.pumpAndSettle();`
Assert: router's current location is `/tasks` (not app exited).

### Test B — TimerScreen non-active system back navigates to root

Setup: build GoRouter with `/timer/:id` as initial location, session status
non-active (e.g., `PomodoroStatus.ready`). Pump `TimerScreen`.
Action: simulate system back.
Assert: current location is `/tasks` (local mode) or `/groups` (account mode).

### Test C — TimerScreen active system back shows confirmation dialog

Setup: session status active (`isActiveExecution = true`). Pump `TimerScreen`.
Action: simulate system back.
Assert: confirmation dialog appears (check for dialog widget or dialog text).
Sub-action: tap "Cancel" in dialog.
Assert: still on `/timer/:id` (no navigation, group not cancelled).

### Test D — Settings non-regression (system back pops, no fallback)

Setup: build GoRouter navigating `/tasks` → `context.push('/settings')` (stack
has 2 entries). Pump `SettingsScreen`.
Action: simulate system back.
Assert: current location is `/tasks` (popped back, NOT went to /tasks via fallback).

**Note**: Use the existing fake infrastructure already in
`timer_screen_completion_navigation_test.dart` for provider mocks. Do not
re-implement fakes — reuse `FakeTaskRunGroupRepository`, `FakePomodoroSessionRepository`,
etc. that already exist in that file.

---

## 9. Out of scope (do NOT implement in this branch)

- `LateStartOverlapQueueScreen` — also navigated via `context.go`, same pattern,
  but out of BUG-019 scope. Document as future known case if user confirms.
- Any navigation changes for Settings sub-routes (`/settings/presets/...`) —
  already use `context.push` and work correctly.
- Any UI changes (buttons, labels, AppBar back icons).
