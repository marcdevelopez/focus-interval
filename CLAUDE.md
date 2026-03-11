# Focus Interval — Mandatory Context for Claude & Codex

Read this file **before touching any code**. It contains architectural invariants and
anti-patterns confirmed by real production bugs. Violating these has caused repeated
irrecoverable `Syncing session...` freezes.

---

## 1. Mandatory pre-read before touching timer/sync code

If you are about to edit any of these files, read the listed docs first:

| File to edit | Must read first |
|---|---|
| `lib/presentation/viewmodels/pomodoro_view_model.dart` | This file + [Anti-patterns](#3-confirmed-anti-patterns-do-not-repeat) + [Guardrails](#4-implementation-guardrails) |
| `lib/data/services/time_sync_service.dart` | This file + [TimeSyncService rules](#5-timesyncservice-invariants) |
| `lib/data/repositories/firestore_pomodoro_session_repository.dart` | This file + [Stream null semantics](#3-confirmed-anti-patterns-do-not-repeat) |
| Any sync/ownership/session code | `docs/specs.md` sections 8–10 + [Guardrails](#4-implementation-guardrails) |

---

## 2. Project orientation

- **Specs**: `docs/specs.md` — authoritative source of truth for all behavior
- **Active bugs**: `docs/bugs/bug_log.md`
- **Current validation**: `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md`
- **Dev log**: `docs/dev_log.md` — full history, use to understand context of past decisions
- **Roadmap**: `docs/roadmap.md` — active phase and open bugs

Current active branch: `fix26-reopen-black-syncing-2026-03-09`
Last confirmed-safe baseline commit: `961f7eb`
Latest fix commit: `b085ea6`

---

## 3. Confirmed anti-patterns — DO NOT REPEAT

These patterns caused real production bugs. Each one has been confirmed in device logs.

### AP-1 — Canceling session subscriptions inside `build()` [CRITICAL]

**Bug caused:** Fix 26 regression (10/03/2026). Android stuck in `Syncing session...` for 40+ min.

**The bad pattern:**
```dart
// ❌ NEVER DO THIS inside build()
_sessionSub?.close();
_sessionSub = null;
_subscribeToRemoteSession();
```

**Why it is wrong:** Riverpod `build()` re-runs on every `ref.watch()`ed provider emission,
including Firebase Auth token refreshes (which are unrelated to session state). Canceling
`_sessionSub` here kills the live Firestore listener. The new listener emits `null` during
the auth reconnect window → `_sessionMissingWhileRunning = true` → permanent freeze.

**The correct pattern:**
- Keep `_sessionSub` lifecycle only in `ref.onDispose()`, `loadGroup`, and explicit
  mode-switch/resume handlers.
- For deduplication: `if (_sessionSub != null) return;` — guard the re-subscribe, never
  cancel the existing one from `build()`.
- Riverpod-managed subscriptions (`ref.listen`) need no manual lifecycle in `build()`.

---

### AP-2 — Treating stream `null` as authoritative session deletion [CRITICAL]

**Bug caused:** Original Fix 26 vulnerability — present even at baseline `961f7eb`.

**The bad pattern:**
```dart
// ❌ NEVER treat stream null as proof of deletion without grace period
if (session == null) {
  _sessionMissingWhileRunning = true;
  _clearRunningState();
}
```

**Why it is wrong:** `pomodoroSessionStreamProvider` emits `AsyncData<null>` for transient
reasons unrelated to session deletion:
- Firestore SDK cache miss during reconnect
- SDK state reset during brief offline window
- `fireImmediately: true` emits `null` before the first real snapshot arrives

**The correct pattern:**
- Always debounce: wait ≥3s before latching `_sessionMissingWhileRunning = true`.
- For recovery after latch: always include a server-fetch fallback (`preferServer: true`)
  to confirm actual state before any destructive clear.
- Specs rule: `docs/specs.md` lines 669–672 — do not clear on single lookup null.

---

### AP-3 — Recovery paths that only write, never read

**Bug caused:** Missing-session hold never recovering when another device holds ownership.

**The bad pattern:**
```dart
// ❌ Incomplete recovery: only tries to claim/write
await tryClaimSession(snapshot);
await publishSession(snapshot);
// if both fail silently (other device is owner) → permanent freeze
```

**The correct pattern:**
- Write-only recovery fails when another device is owner (correct by design).
- After write fails: fetch from server (`preferServer: true`) to discover current owner,
  then apply discovered snapshot to unfreeze the latch.
- The `_sessionMissingWhileRunning` latch MUST be clearable by a server fetch that
  confirms a valid active session exists, even if this device is not the owner.

---

### AP-4 — Timeline gate must not block missing-session hold exit

**Bug caused:** Fix 26 reopen (Block 564, commit `b085ea6`).

**The bad pattern:**
```dart
if (!shouldApplyTimeline) {
  if (ownershipMetaChanged) { _notifySessionMetaChanged(); }
  return; // ❌ wasMissing=true: overlay clears but timer stays frozen
}
```

**The correct pattern (per specs 10.4.8.b — single-shot bypass):**

When `wasMissing=true` and a valid snapshot arrives (groupId match, active
`isActiveExecution` status, concrete `AsyncData` value), bypass the gate entirely:
- Apply the snapshot to the timer projection (not just notify)
- Remove `Syncing session...` overlay
- Update timer countdown, ring, status boxes, task list — all in the same frame
- Reset applied watermarks (revision/updatedAt) to the exit snapshot values

After this one event the gate resumes normally.

**Note:** `b085ea6` is a partial fix — it clears the overlay but does NOT apply
the timeline to the timer. The refactor must complete this.

**See:** `docs/specs.md` section 10.4.8.b, decision table.

---

## 4. Implementation guardrails

### G-1 Subscription lifecycle
- `_sessionSub?.close()` and `_subscribeToRemoteSession()` → **only** in:
  `loadGroup`, `ref.onDispose()`, resume handlers, mode-switch handlers.
- **Never** in `build()`.

### G-2 Change isolation
- Listener lifecycle changes must be in a dedicated commit. No unrelated UI or routing
  edits in the same commit. This enables surgical rollback.

### G-3 Regression test before merge
- Any change to `_subscribeToRemoteSession`, `_sessionMissingWhileRunning`, or
  `build()` must include/refresh a test proving that a provider rebuild
  (auth/token refresh equivalent) does NOT drop session-listener continuity.

### G-4 Validation before closure
- Required: exact degraded-network repro PASS + ≥4h soak window.
- Soak must include at least one Firebase id-token refresh event in logs
  without ending in indefinite `Syncing session...`.

### G-5 Stop-the-line
- If any run reproduces indefinite `Syncing session...` hold, stop new features,
  record logs, rollback the listener-lifecycle commit immediately.

### G-6 No destructive clear without corroboration
- Before calling any method that clears running state (`_clearRunningState`,
  `_sessionMissingWhileRunning = true` as permanent), first check:
  1. Is `wasMissing` already false? (stream recovered)
  2. Has `_groupRepo.getById` confirmed group is non-running?
  Only proceed if at least one corroborated signal exists.

---

## 5. TimeSyncService invariants

- Reject measurement when roundtrip > 3000ms.
- Reject abrupt offset jump > 5000ms delta when a previous offset exists.
- On rejection: keep previous offset, do NOT update last successful sync time.
- Apply 3s rejection cooldown to avoid tight retry loops on unstable network.
- These rules prevent offset-poisoning during reconnect (bug fixed in `418c75f`).

---

## 6. Specs coherence — known issues patched by Codex (2026-03)

Codex identified and patched 10 incoherencies in `docs/specs.md`. These are now aligned:
1. Write policy during `time sync unavailable` — unified (no contradictions)
2. Destructive clear rule — unified (no single-null-clear allowed)
3. `remainingSeconds` — compat/fallback only; timeline fields are authoritative
4. `actualStartTime` in `TaskRunGroup` model — now declared
5. `scheduledByDeviceId` ownership block — no longer split/broken
6. Reconciliation matrix `group.status` vs `session.status` — now explicit
7. "Source of truth for render" vs "timeline-anchored ranges" — prioritized
8. Finalisation without devices — aligned with modal completion in foreground
9. Sequencing (+1min vs round-up) — unified
10. `lastUpdatedAt` role (liveness vs tie-breaker) — explicit priority order

If you spot a contradiction in specs, **stop and report it before implementing**.
Do not resolve ambiguous spec sections by guessing — ask the user.

---

## 7. Testing commands

```bash
# Analyze + test before any PR/merge on session/timer code
flutter analyze
flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart
flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart
flutter test test/presentation/timer_screen_syncing_overlay_test.dart
```

---

## 8. When this file should be updated

- After each confirmed bug closure: add the anti-pattern summary here.
- After each spec incoherence is patched: update section 6.
- When a new guardrail is confirmed necessary: add it to section 4.
- **Do not add speculative rules** — only add confirmed patterns from real incidents.
