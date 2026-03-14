# Plan — Rapid Validation (Fix 26 cycle 4 + Fix 27)

Date: 2026-03-07
Branch: `fix27-local-account-reentry-autostart`
Scope: Re-validation after commit `26f0c7e` + implementation of Fix 27.
Latest branch update (2026-03-10): `fix26-reopen-black-syncing-2026-03-09`

## Objective
- Confirm that Fix 26 no longer leaves owner/mirror in indefinite `Syncing session...`.
- Keep Fix 26 open in monitoring mode for 2 days before final closure.

## Evidence (logs)
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_07_fix26_cycle4_ios_debug.log`
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_07_fix26_cycle4_chrome_debug.log`

## Current Result (provisional)
- Initial practical runs: no indefinite syncing hold observed.
- Status: **Monitoring** (not closed yet).
- Monitoring window: **2026-03-07 to 2026-03-09**.

## Monitoring Window Result (updated 2026-03-09)
- Status changed from **Monitoring** to **FAIL / Reopened**.
- Failure scenario confirmed on 2026-03-08:
  1. macOS owner went to sleep/background.
  2. Android remained as the only active/open app with intermittent screen-off cycles.
  3. Around 19:00 (2026-03-08), Android entered `Syncing session...` with amber ring (first screenshot at 19:02) and never recovered.
  4. On macOS wake, app resumed into `Syncing session...` + black screen.
  5. Stuck state remained until around 20:45 (2026-03-08).
- Recovery attempts reported: screen wake, navigation changes, and retry interactions did not recover Android state.
- Evidence:
  - Screenshot:
    - `docs/bugs/validation_fix_2026_03_07-01/screenshots/Screenshot_2026-03-08-19-02-12-76_24a6c2193a9deb7da51ed61dc48f62e5.jpg`
  - Logs:
    - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_08_fix26_incident_android_cc5f55b.log`
    - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_08_fix26_incident_macos_cc5f55b.log`
- Log correlation summary:
  - Android: sustained Firestore `UNAVAILABLE` + `UnknownHostException` during the incident window, with stale session snapshots.
  - macOS: `Missing snapshot; clearing session` and `Resync missing; clearing state` during resume path.
- Closure impact:
  - Fix 26 closure criteria are not met.
  - Keep Fix 26 open and blocked for further hardening/re-validation.

## Comparative Observation (2026-03-09 partial logs)
- New partial evidence added:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_observation_partial_android_cc5f55b.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_observation_partial_macos_cc5f55b.log`
- Summary:
  - No irrecoverable `Syncing session...` lock reproduced while both devices remained mostly active/open.
  - Android still reports repeated Firestore `UNAVAILABLE` + `UnknownHostException`.
  - Recovery behavior is present in this run: session snapshots continue advancing after error bursts.
  - macOS did not show `Missing snapshot; clearing session` / `Resync missing; clearing state` in the partial sample; only transient `Missing snapshot; holding in sync`.
- Updated hypothesis:
  - Trigger risk is concentrated in single-device effective ownership plus prolonged background/sleep and weak/offline network periods.
  - Hardening must prioritize resume/recovery when owner is alone and network is degraded.

## Fix 26 hardening implementation (2026-03-09)
- Status: **Implemented / Pending validation**.
- Branch: `fix26-reopen-black-syncing-2026-03-09`.
- Specs-first updates:
  - Added foreground bounded-backoff retry requirement during missing-session hold.
  - Added non-destructive clear guard requiring group-status recheck before local state clear.
  - Added resume listener rule to avoid forced close/recreate on every resume.
- Code changes applied:
  - `lib/presentation/viewmodels/pomodoro_view_model.dart`
    - Foreground missing-session retry loop upgraded from one-shot to periodic bounded backoff (`5s -> 10s -> 20s -> max 30s`).
    - Added repo recheck (`_groupRepo.getById`) before destructive clear when session snapshot is missing.
    - Added non-destructive clear path that preserves running projection state.
    - Added guarded session listener rebind policy on resume (rebind only when absent/stalled with cooldown).
    - Added explicit manual recovery API for session-gap stalls (`retrySessionGapRecovery`).
    - `applyRemoteCancellation()` now increments decision token and cancels foreground retry to prevent stale async hold after remote cancel.
  - `lib/presentation/screens/timer_screen.dart`
    - Sync overlay retry button now handles both time-sync stalls and session-gap stalls.
- Verification executed:
  - `flutter analyze` -> PASS.
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart` -> PASS.
- Tracking commits:
  - `3ad6c98` — `fix: harden fix26 missing-session recovery and resume sync`
  - `9f05951` — `fix: invalidate missing-session decision on remote cancellation`

## Related open bug found during this cycle
- Scenario:
  1. Plan a group in Account Mode.
  2. Switch to Local Mode.
  3. Let planned start time pass.
  4. Switch back to Account Mode.
- Current behavior: Run Mode does not auto-open immediately; if app is restarted, auto-open works.
- Impact: may cause unstable overlap resolution timing.
- Tracking: keep under reopened auto-open/overlap scope until triage+fix.

## Fix 27 — Local -> Account re-entry missed auto-start (new)

Objective
- Ensure overdue scheduled groups auto-start and open Run Mode immediately when re-entering Account Mode from Local Mode, without app restart, if there is no active conflict.

Implementation direction
- Keep auto-open route guards (no global intrusive opening behavior).
- Make mode switch behave like account cold re-entry for scheduling/session reevaluation:
  - refresh account group/session streams on mode change,
  - rebuild coordinator state for the new scope,
  - trigger deterministic post-switch reevaluation.

Validation target
- Exact repro:
  1. Schedule a group in Account Mode.
  2. Switch to Local Mode before scheduled start.
  3. Wait until scheduled start passes.
  4. Switch back to Account Mode without closing app.
  5. Expected: immediate auto-start + Timer Run Mode open.

Implementation status (2026-03-07) — first attempt FAIL
- Commit: `5ac3d6b` (`fix: restore Local->Account overdue auto-start reentry`).
- Changes: `app_mode_change_guard.dart` + `scheduled_group_coordinator.dart`.
- Result: validation failed — timer did not open on mode switch.
- Root cause of failure: `ref.invalidate(scheduledGroupCoordinatorProvider)` disposed the
  coordinator's `ref.listen` subscriptions. Firestore stream data arrived during the race
  window before the new coordinator instance rebuilt and re-registered its listeners.

Implementation status (2026-03-07) — second attempt PASS — **Closed/OK**
- Code change: removed `ref.invalidate(scheduledGroupCoordinatorProvider)` from
  `_handleModeChange`. The coordinator's own `ref.listen<AppMode>` handler correctly
  calls `_resetForModeChange()` + `_handleGroups()` on every mode change; invalidating it
  was breaking that natural subscription chain.
- `forceReevaluate()` calls (postFrameCallback + 600ms delay) kept as backup triggers.
- Analyzer: PASS.
- Validation logs:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_07_fix27v2_ios_debug.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_07_fix27v2_chrome_debug.log`
- Exact repro PASS (iOS + Chrome, 2026-03-07 22:49): group scheduled at 22:48, user in
  Local Mode, switched back to Account Mode at 22:49 — auto-start fired immediately,
  Timer Run Mode opened without app restart.
- Regression smoke PASS: no Fix 24/Fix 26 regressions observed in v2 logs.

## Closure criteria for Fix 26
1. Exact repro for the single-device + prolonged background/sleep + degraded-network scenario passes after this hardening implementation.
2. Regression smoke checks remain PASS (Fix 24 / Fix 25 / Fix 27 + overlap flow).
3. No new irrecoverable `Syncing session...` hold and no black-screen resume in the validated runs.

## Quick execution protocol (iOS + Chrome)

Date target: 2026-03-09
Purpose: fast regression confidence under unstable network without waiting full pomodoro cycles.

Steps:
1. Start one account-mode running group on iOS (owner).
2. Open the same group on Chrome (mirror) and verify sync baseline.
3. Run short background/resume on iOS (screen off / app background), then resume.
4. Simulate brief network instability on each device (about 60-90s), then recover and use retry if needed.
5. Trigger remote cancel while mirror is in/near sync-gap and verify mirror exits hold.
6. Run a short Fix 27 smoke check (Local -> Account re-entry path).

Expected PASS:
- No irreversible `Syncing session...` hold.
- No black-screen resume.
- No transient drop to Ready while active session is valid.
- Cancel path resolves on mirror after temporary gaps.

Planned logs:
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_ios_debug.log`
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_chrome_debug.log`

Command snippet:

```bash
flutter devices
flutter run -v --debug -d <IOS_DEVICE_ID> --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee /Users/devcodex/development/focus_interval/docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_ios_debug.log
flutter run -v --debug -d chrome --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee /Users/devcodex/development/focus_interval/docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_chrome_debug.log
```

Post-run documentation actions:
1. Update `quick_pass_checklist.md` R1-R5 and run metadata.
2. Update `validation_ledger.md` status for `P0-F26-001` and `P0-F26-002`.
3. If PASS, close Fix 26 and record closure commit hash/message/evidence.

## Quick run outcome (2026-03-09 iOS + Chrome)

Status: **FAIL (transient reconnect desync)**.

Observed:
- Baseline pause/resume and background/foreground behavior remained stable.
- During offline window + reconnect, Chrome briefly projected the timer with a
  large negative drift (~45s ahead of elapsed time), then self-corrected after
  the next sync cycle.
- No irreversible `Syncing session...` lock and no black-screen resume in this
  run.

Correlated evidence:
- Logs:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_ios_debug.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_chrome_debug.log`
- Screenshots:
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_07_204708.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_08_204802.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_09_205008.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_10_205046.png`
  - `docs/bugs/validation_fix_2026_03_07-01/screenshots/2026_03_09_fix26_quick_timeline_11_205103.png`

Root-cause summary:
- `TimeSyncService.refresh()` accepted an invalid reconnect measurement and
  produced a poisoned offset (`+45550ms`) that temporarily skewed projection.

## Follow-up implementation (2026-03-09) — timeSync measurement safety

Status: **Implemented / Re-validated PASS / Closed**.

Changes:
- `lib/data/services/time_sync_service.dart`
  - Reject measurement when roundtrip duration exceeds 3s.
  - Reject abrupt offset jumps (>5s delta) when a previous offset exists.
  - Add rejection cooldown (3s) to avoid tight retry loops on unstable network.
  - On rejection: keep previous offset, do not update last successful sync time.
- `docs/specs.md`
  - Added explicit rules for invalid timeSync measurement handling.

Verification:
- `flutter analyze` -> PASS.
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart` -> PASS.
- Commit:
  - `418c75f` — `fix: guard timesync offset against reconnect poisoning`.

## Re-validation outcome after `418c75f` (2026-03-09)

Status: **PASS**.

Observed:
- Exact degraded-network reconnect rerun no longer reproduced the transient timer jump.
- `Syncing session...` duration matched the real offline window (expected behavior).
- No irreversible `Syncing session...` hold and no black-screen resume in this rerun.

Evidence:
- Logs:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_ios_debug.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_chrome_debug.log`
- Chrome log markers (invalid samples rejected, prior offset preserved):
  - line 2255: `rejected measurement (roundTripMs=65971 offsetMs=32806 prevOffsetMs=-93)`
  - line 2466: `rejected measurement (roundTripMs=16288 offsetMs=7875 prevOffsetMs=-83)`
  - line 2506: `rejected measurement (roundTripMs=28286 offsetMs=13857 prevOffsetMs=-32)`

Closure decision (09/03/2026):
- Fix 26: **Closed/OK** on 2026-03-09.
- Closing commit reference:
  - `418c75f` — `fix: guard timesync offset against reconnect poisoning`.

---

## 2026-03-10 Regression + Rollback

Status: **Reopened — re-validation required**

- Regression observed during Fix 25 validation (~12:15 CET): Android stuck in
  irrecoverable `Syncing session...` for 40+ minutes with a healthy Firestore session.
- Root cause: Firebase Auth token refresh triggered `runningExpiry=true` false-positive
  (56ms) in `ScheduledGroups`, silently disconnecting the Firestore session listener.
  Second/third-cycle VM hardening commits (`9bab880`, `4f55010`, `26f0c7e`, `3ad6c98`)
  introduced this path. `418c75f` confirmed uninvolved.
- Rollback performed to `961f7eb` baseline (commit `4195ef1`):
  - `pomodoro_view_model.dart`, `timer_screen.dart`, `firestore_pomodoro_session_repository.dart`,
    `pomodoro_session_repository.dart` restored to `961f7eb` state.
  - Fix 27 and `418c75f` preserved.
- Fix 26 reopened. Next step: re-validate exact single-device degraded-network repro
  under commit `4195ef1`.

### Root cause analysis (exact mechanism — 10/03/2026)

**Commit that introduced the regression: `9bab880`**
(`fix: harden missing-session cleanup and rebind run-mode session listeners`)

The change that caused the regression was adding these lines at the **top** of `PomodoroViewModel.build()`:

```dart
// build() can re-run when watched providers refresh (e.g. auth/token updates).
_sub?.cancel();
_sub = null;
_sessionSub?.close();
_sessionSub = null;
```

**Why this is wrong:**

In Riverpod, `build()` on a `Notifier` re-runs whenever any `ref.watch()`ed provider
emits a new value — including `pomodoroSessionRepositoryProvider` which re-emits on
Firebase Auth token refreshes. These re-runs are completely unrelated to session state.

At `961f7eb` (baseline), `_sessionSub` was a `ProviderSubscription` created via
`ref.listen()` in a separate method. Riverpod manages its lifecycle; `build()` re-runs
do NOT affect it. The only place it was closed was `ref.onDispose()`.

After `9bab880`, `build()` unconditionally kills `_sessionSub` on EVERY re-run.
Re-subscription at the end of `build()` is conditional:
`if (appMode == account && hasLoadedContext)`. Even when the condition is met, the
new Firestore stream listener emits `null` during the brief auth-reconnect window.

`26f0c7e` added a microtask guard (`if (_sessionSub != null) return`) before calling
`_subscribeToRemoteSession()`, but that guard was neutralized by the earlier
`_sessionSub = null` at build start. In practice, build re-runs still re-opened the
listener.

**Full causal chain (10/03/2026 incident):**
1. Firebase Auth token refresh at ~12:15:09 → `pomodoroSessionRepositoryProvider` re-emits
2. Riverpod triggers `build()` re-run on PomodoroViewModel
3. `_sessionSub?.close()` at start of `build()` → Firestore session listener **killed**
4. `_subscribeToRemoteSession()` called at end of `build()` → new listener created
5. New listener emits `null` during auth reconnect window
6. `_handleMissingSessionFromStream(null)` → `_sessionMissingWhileRunning = true`
7. ScheduledGroups sees no active session → `runningExpiry=true` spike (56ms), then
   self-corrects; but `_sessionMissingWhileRunning` stays latched
8. Foreground retry fires every ~30s, checks group (status=running) →
   `_shouldKeepMissingSessionHoldAfterGroupRecheck()` returns `true` → hold preserved
9. `activePomodoroSessionProvider` (a separate Riverpod provider) keeps delivering
   valid session data every ~30s → visible in `[RunModeDiag] Active session change`
   logs — but this path does NOT clear `_sessionMissingWhileRunning`
10. Android stuck in "Syncing session..." indefinitely (40+ min observed)

**Anti-pattern to avoid in future implementations:**

> **Never cancel `_sessionSub` (or any session/group stream subscription)
> unconditionally inside `build()`.** Riverpod `build()` re-runs happen for
> reasons completely unrelated to session state (auth token refresh, any watched
> provider update). Canceling subscriptions inside `build()` creates fragile
> windows and can permanently lose the session stream.
>
> If deduplication of subscriptions is needed, use a guard on the subscription
> itself (`if (_sessionSub != null) return;`) rather than canceling at build start.
> For Riverpod-managed subscriptions (`ref.listen`), no manual lifecycle management
> inside `build()` is needed — Riverpod handles it.

## Mandatory guardrails for next Fix 26 implementation

1. Subscription lifecycle guardrail
   - Do not call `_sessionSub?.close()` or `_subscribeToRemoteSession()` from `build()`.
   - Keep listener close/open only in explicit lifecycle methods (`loadGroup`,
     app resume handlers, mode-switch handlers) with a reasoned debug log.
2. Change isolation guardrail
   - Listener lifecycle changes must be in a dedicated commit (no unrelated UI/routing
     edits in the same commit) so rollback is surgical.
3. Regression-test guardrail
   - Before merge, include/refresh a targeted test proving that a provider rebuild
     (auth/token refresh equivalent) does not drop session-listener continuity.
4. Validation guardrail
   - Required before closure: exact degraded-network repro PASS + extended soak
     window PASS (>=4h) on the target commit.
   - During that run, include at least one Firebase id-token refresh event in logs
     without ending in indefinite `Syncing session...`.
5. Stop-the-line guardrail
   - If any run reproduces indefinite hold again, stop new fixes/features, record logs,
     and rollback the listener-lifecycle commit immediately.

## 2026-03-10 Rollback Re-validation (partial logs, commit `4195ef1`)

Status: **In validation (partial run PASS, exact repro still pending)**

Evidence:
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_10_fix26_observation_partial_android_4195ef1.log`
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_10_fix26_observation_partial_macos_4195ef1.log`

Preliminary findings (13:19–13:42 CET):
- Android:
  - no `Missing snapshot; clearing session`.
  - no `Resync missing; clearing state`.
  - resume path showed `Resync start (resume)` + `Resync start (post-resume)`, then
    active snapshots continued without gaps.
- Snapshot cadence remained healthy (roughly every 30s) with advancing `remaining`
  values and stable remote owner (`macOS-6305354a-2d03-4248-b825-672fa88de542`).
- No irrecoverable `Syncing session...` reproduced in this partial window.
- Observation window is still short (~23 minutes), so this is not sufficient to
  rule out regression yet.

Next step:
- Complete the full exact repro packet (screen-off + unstable network + long
  foreground/background cycles) before closure.
- Keep Fix 26 in `In validation` status until an extended soak window is completed
  (minimum target: >=4h on rollback commit `4195ef1`).

## 2026-03-10 Follow-up bug: invalid cursor after reopen/owner switch

Status: **Closed/OK (validated on devices, 10/03/2026)**

Problem observed (post-fix `b8dbff5` run):
- `activeSession/current` persisted an inconsistent cursor:
  - `currentTaskIndex=1` (`Almorzar`, `totalPomodoros=1`)
  - `currentPomodoro=2`
- Result: Run Mode reopened in the wrong segment (`Pomodoro 2 of 1`) instead of
  progressing to the correct next task (`Trading`) by timeline.

Root cause:
- Session hydration trusted persisted `currentTaskIndex/currentPomodoro` even when
  mathematically invalid for the task snapshot (`currentPomodoro > totalPomodoros`).
- On reopen/owner switch this allowed stale/invalid cursor state to drive the UI.

Fix implemented:
- `PomodoroViewModel` now validates and repairs inconsistent active-session cursor
  during sanitize and stream processing:
  - detects invalid cursor (`currentPomodoro` out-of-range, taskId/index mismatch,
    task total mismatch),
  - reprojects against the running-group timeline anchor (with pause offset model),
  - rebuilds a coherent session snapshot for hydration,
  - if local device is owner in Account Mode, republishes repaired snapshot to Firestore.
- Added regression test:
  - `loadGroup repairs invalid task cursor and lands on expected running task`
  - file: `test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart`

Validation executed:
- `dart analyze lib/presentation/viewmodels/pomodoro_view_model.dart test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS
- `flutter analyze` PASS

Validation result:
- Android (`RMX3771`) + macOS manual validation PASS with release logs:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-10_fix26_postfix_250c24d_macos_diag.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-10_fix26_postfix_250c24d_android_RMX3771_diag.log`
- Reopen now lands on correct task/time segment when owner changes.
- No reappearance of `Pomodoro 2 of 1`.
- Firestore/session cursor remains coherent after reopen.

## 2026-03-10 Follow-up v2: `running` group with `finished` activeSession

Status: **Closed/OK (validated on devices, 10/03/2026)**

Problem observed (post-fix `1fa8ca7` logs):
- `TaskRunGroup` remains `status=running`, but `activeSession/current` is persisted as:
  - `status=finished`
  - `phase=null`, `remainingSeconds=0`
  - stale/invalid cursor (`currentPomodoro=2`, `totalPomodoros=1`).
- On reopen, both Android and macOS can end in `00:00` + `Syncing session...` with
  log loop:
  - `Active session cleared`
  - `Auto-start abort (state not idle) state=finished`

Root cause:
- Previous cursor repair path focused on active-execution snapshots and could miss
  repair when persisted session arrived already `finished` while the group was still
  `running`.

Fix implemented:
- Expanded `_sanitizeActiveSession` / `_repairInconsistentSessionCursor` handling so
  non-active sessions are also reconciled against the running group timeline when the
  cursor/task tuple is inconsistent.
- Added regression coverage for this exact pair (`running` + `finished` + invalid cursor):
  - `loadGroup repairs finished invalid cursor when group is still running`
  - file: `test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart`

Validation executed:
- `dart analyze lib/presentation/viewmodels/pomodoro_view_model.dart test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS

Validation result:
- Android (`RMX3771`) + macOS clean reopen/install PASS on post-fix logs.
- Timer lands on projected running segment (`Trading`) across both devices.
- No indefinite `Syncing session...`.
- No recurring auto-start abort loop with `state=finished` in this scenario.

## 2026-03-10 Follow-up v3: no-owner gap with stale `finished` session

Status: **Closed/OK (validated on devices, 10/03/2026)**

Problem observed after v2:
- Even with correct timer projection, Firestore still kept stale:
  - `activeSession/current.status=finished`
  - `ownerDeviceId=<old device id>`
  - stale `lastUpdatedAt`
- Result: both clients rendered as mirror/no-owner even while group stayed running.

Fix implemented:
- In `_sanitizeActiveSession`, after cursor repair:
  - when original snapshot is non-active (`finished`), stale, and repaired snapshot is active,
    claim recovery ownership on current device.
  - flow: clear stale non-active session -> `tryClaimSession` with recovered active snapshot
    and bumped `sessionRevision`.
  - if claim race is lost, fetch fresh snapshot from server and continue safely.

Validation executed:
- `dart analyze lib/presentation/viewmodels/pomodoro_view_model.dart test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS
- Regression test now asserts recovered session owner equals current device id.

Validation result:
- No-owner gap resolved: one deterministic owner is always visible.
- `activeSession/current` no longer remains latched on stale `finished` after reopen.
- Run Mode remains aligned on both devices without manual Firestore edits.

## 2026-03-10 Closure packet — `P0-F26-003`

Status: **Closed/OK**

Evidence summary:
- Commit implementing the final behavior: `250c24d`
  - `fix(f26): recover stale finished session ownership with expiry-safe guard`
- Logs used for closure:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-10_fix26_postfix_250c24d_macos_diag.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-10_fix26_postfix_250c24d_android_RMX3771_diag.log`
- Critical-pattern scan in both logs:
  - no `sessionMissing`
  - no `stream-missing-debounced`
  - no `Missing snapshot`
  - no `Syncing session...` latch
  - no `Unhandled Exception`
  - no `cloud_firestore/unavailable`
  - no `runningExpiry` false-positive signature
- Device-level behavior:
  - reopen/hydration lands on coherent running segment,
  - owner transition remains deterministic (`macOS -> Android`) with continuous run-mode updates,
  - timer values match wall-clock within expected second-level rounding bounds.

Decision:
- `P0-F26-003` is closed.
- `P0-F26-001` remains open until exact degraded-network repro + extended soak closure criteria are met.

---

## 2026-03-10 Reopen — Syncing session latch regression (post-250c24d)

Status: **In validation** (device logs running as of 10/03/2026)

### Incident summary

After `250c24d`, both devices showed the original symptoms again:
- macOS mirror: permanent `Syncing session...` overlay (25:00, Ready, Start)
- Android owner: frozen timer at ~03:24, gray/white circle, not counting down

### Root cause

`loadGroup` fetches session with `preferServer: true` → `_lastAppliedSessionUpdatedAt = T_server_fresh`.
`_subscribeToRemoteSession(fireImmediately: true)` → first event is null → 3 s debounce fires →
`_sessionMissingWhileRunning = true`, mirror timer cancelled, UI latches to `Syncing session...`.
Real Firestore snapshot arrives: `lastUpdatedAt = T_cached ≤ T_server_fresh` → `shouldApplyTimeline = false`.
The `!shouldApplyTimeline` early-return block only called `_notifySessionMetaChanged()` when
`ownershipMetaChanged`, **not** when `wasMissing`. No rebuild → UI stuck permanently.

### Applied fix

Commit `b085ea6` — `fix(f26): notify UI when missing-session latch clears but timeline skips`

```dart
// pomodoro_view_model.dart — _subscribeToRemoteSession listener
if (!shouldApplyTimeline) {
  if (ownershipMetaChanged || wasMissing) {   // ← added || wasMissing
    _notifySessionMetaChanged();
  }
  return;
}
```

### Deferred improvement — immediate timer unfreeze (not yet implemented)

**Problem this would solve:** After b085ea6, the `Syncing session...` overlay clears correctly.
However, the mirror timer position (frozen seconds) remains stale until the next Firestore write
where `lastUpdatedAt > T_server_fresh` (up to ~30 s). The owner's displayed time may be off during
this window.

**Proposed change** (implement only if device validation confirms the timer freeze is user-visible):

```dart
// pomodoro_view_model.dart — _subscribeToRemoteSession listener
if (!shouldApplyTimeline) {
  if (ownershipMetaChanged || wasMissing) {
    if (wasMissing) _setMirrorSession(session);  // ← unfreeze display immediately
    _notifySessionMetaChanged();
  }
  return;
}
```

**Required guard before adding this:**
- Verify `session.status.isActiveExecution` (not idle/finished) before calling `_setMirrorSession`.
- Verify `session.remainingSeconds > 0` to avoid applying a zero-second stale snapshot.
- Safe because `wasMissing=true` means mirror timer was already cancelled; we restore from null,
  not overwrite a live timer with a regressed snapshot.

**Risk if guard is omitted:** `_setMirrorSession` with a regressed `lastUpdatedAt` could display
slightly incorrect remaining time, but would not cause a permanent latch since
`_notifySessionMetaChanged()` always fires after it.

**Implement if:** device validation shows a noticeable timer freeze (> 5 s visible) after the
`Syncing session...` overlay clears.

## 2026-03-11 — Phase 2 log capture packet (`8c6cb73`)

Status: **Evidence captured (analysis pending)**

Logs saved for this validation cycle:
- Existing running-group smoke:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-11_fix26_phase2_8c6cb73_macos_diag.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-11_fix26_phase2_8c6cb73_android_RMX3771_diag.log`
- New-group exact repro:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-11_fix26_refactor_8c6cb73_ios_iPhone17Pro_debug.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-11_fix26_refactor_8c6cb73_chrome_debug.log`

Command profile used:
- macOS/Android in `--release` + `APP_ENV=prod`.
- iOS simulator/Chrome in `--debug` + `APP_ENV=prod` + `ALLOW_PROD_IN_DEBUG=true`.

## 2026-03-13 — Phase 5 log capture packet (`7daf636`)

Status: **IN PROGRESS — validation run launched**

Logs will be saved at:
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase5_7daf636_android_RMX3771_diag.log`
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase5_7daf636_ios_iPhone17Pro_debug.log`
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase5_7daf636_macos_diag.log`
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase5_7daf636_chrome_debug.log`

Command profile used:
- Android/macOS in `--release` + `APP_ENV=prod`.
- iOS/Chrome in `--debug` + `APP_ENV=prod` + `ALLOW_PROD_IN_DEBUG=true`.

New diagnostic events available in this packet (Phase 5 instrumentation):
- `[VMLifecycle] init/dispose vmToken=<uuid>` — detect ViewModel recreation
- `[SessionSub] open/close vmToken=<uuid> reason=<reason>` — detect what closes `_sessionSub`
- `[StaleClearDiag] decision=<clear|skip>` — detect if coordinator clears active session
- `[ScheduledActionDiag] action=<action>` — detect scheduled firings near freeze timestamp

## 2026-03-13 — Phase 5 packet closure (`7daf636`)

Status: **COMPLETED — root cause confirmed**

Outcome summary:
- Chrome and iOS debug logs captured `provider-dispose` while timer route remained
  active, confirming VM disposal race under `autoDispose`.
- Coordinator diagnostics confirmed active running group persisted (`decision=keep`)
  while timer UI froze.
- Root cause split finalized:
  - B1: keepAlive race during Firestore quiet window.
  - B2: auto-open suppression guard blocks re-navigation after VM dispose.

Decision:
- Phase 5 diagnostic objective met.
- Move to Phase 6 runtime hardening (B1+B2).

## 2026-03-13 — Phase 6 runtime implementation packet (local)

Status: **IN VALIDATION** (local smoke PASS; device exact repro pending)

Implemented scope:
- Commit: `2fc65e4` — `fix(f26): implement phase 6 runtime keepalive grace + auto-open recovery`
- B1 (`pomodoro_view_model.dart`):
  - `_lastActiveSessionTimestamp` + keepAlive grace window (2 min).
  - Grace re-check timer to release keepAlive when grace expires.
  - keepAlive sync updates after snapshot ingestion and stream null handling.
- B2 (`active_session_auto_opener.dart`):
  - detect VM disposed transition via `ref.exists(pomodoroViewModelProvider)`.
  - clear stale `_autoOpenedGroupId` guard on disposed VM.
  - force timer route refresh (`/timer/:id?refresh=...`) in recovery path.

Local evidence:
- `dart analyze` target set PASS (2 pre-existing info hints).
- `flutter test ...pomodoro_view_model_session_gap_test.dart --plain-name "[PHASE6]"` PASS.
- `flutter test ...timer_screen_syncing_overlay_test.dart --plain-name "[PHASE6]"` PASS.

Next mandatory step for closure:
- Device run with exact repro + regression smoke (all in debug for diagnostics)
  before marking Phase 6 as Closed/OK.

## 2026-03-13/14 — Phase 6 device validation packets — FAILED

Status: **FAILED — exact repro REPRODUCED; pass 2 cancelled**

Target devices: Android `RMX3771`, iOS `iPhone 17 Pro`, `macOS`, `Chrome`

Packet A (2026-03-13, 1h) — **EXECUTED — FAIL**:
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase6_2fc65e4_pass1_1h_android_RMX3771_debug.log`
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase6_2fc65e4_pass1_1h_ios_iPhone17Pro_debug.log`
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase6_2fc65e4_pass1_1h_macos_debug.log`
- `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-13_fix26_phase6_2fc65e4_pass1_1h_chrome_debug.log`

Packet B (2026-03-14, 4h30 soak) — **CANCELLED** (exact repro already failed in A; no value in soak).

Failure timeline (Packet A):
- 22:10:00 — user cut network on iOS/Chrome/macOS for 10s → no Syncing session (B1 working for this case)
- 22:21:37 — Android (owner) entered `Syncing session...` spontaneously (no user cut); stream null ≥3s → latch
- 22:22:01 — Android cleared Syncing but timer frozen at 08:25
- 22:23:14 — macOS entered Syncing (showing "ready" 15:00, ownership had transferred to iOS)
- 22:23:26 — Chrome entered Syncing (same as macOS)
- 22:25:44 — iOS entered Syncing (timer 04:22 frozen)
- 22:26:01 — iOS cleared Syncing but timer remained frozen
- 22:37:50 — validation ended; Android woke from screen-off and synced (owner = iOS)

Root cause of failure: `_sessionMissingWhileRunning` latch fires on any ≥3s Firestore stream null,
regardless of VM disposal. Phase 6 B1 only prevented the VM-disposal trigger path; the
spontaneous stream-null path (Firebase SDK reconnect/auth-refresh/cache-miss) survives.
This is an architectural problem, not a missing hardening.

Conclusion: no more focalized hardenings. Sync architecture rewrite required.

## 2026-03-14 — Rewrite Stage B device validation packet (current baseline `3b11847`)

Status: **PLANNED** (exact repro packet A, 1h)

Target devices (exact selectors):
- Android RMX3771 (USB): `HYGUT4GMJJOFVWSS`
- iPhone 17 Pro: `9A6B6687-8DE2-4573-A939-E4FFD0190E1A`
- macOS: `macos`
- Chrome: `chrome`

Protocol:
- Run active session for 1h.
- No manual network cut, no manual pause/resume.
- Objective: verify spontaneous stream-null hold path does not freeze countdown and clears deterministically.

Command block:

```bash
LOG_DIR="/Users/devcodex/development/focus_interval/docs/bugs/validation_fix_2026_03_07-01/logs"
mkdir -p "$LOG_DIR"

flutter run -v --debug -d HYGUT4GMJJOFVWSS \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_rewrite_stageB_3b11847_pass1_1h_android_HYGUT4GMJJOFVWSS_debug.log"

flutter run -v --debug -d 9A6B6687-8DE2-4573-A939-E4FFD0190E1A \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_rewrite_stageB_3b11847_pass1_1h_ios_iPhone17Pro_9A6B6687_debug.log"

flutter run -v --debug -d macos \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_rewrite_stageB_3b11847_pass1_1h_macos_debug.log"

flutter run -v --debug -d chrome \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_rewrite_stageB_3b11847_pass1_1h_chrome_debug.log"
```

Log URLs (repo-relative):
- `/docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-14_fix26_rewrite_stageB_3b11847_pass1_1h_android_HYGUT4GMJJOFVWSS_debug.log`
- `/docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-14_fix26_rewrite_stageB_3b11847_pass1_1h_ios_iPhone17Pro_9A6B6687_debug.log`
- `/docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-14_fix26_rewrite_stageB_3b11847_pass1_1h_macos_debug.log`
- `/docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-14_fix26_rewrite_stageB_3b11847_pass1_1h_chrome_debug.log`

## 2026-03-14 — Rewrite Stage C command reference (baseline `aa2d09b`)

Status: **PLANNED** (normalized command packet for execution traceability)

```bash
LOG_DIR="/Users/devcodex/development/focus_interval/docs/bugs/validation_fix_2026_03_07-01/logs"
mkdir -p "$LOG_DIR"

flutter run -v --debug -d HYGUT4GMJJOFVWSS \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_rewrite_stageC_aa2d09b_pass1_1h_android_HYGUT4GMJJOFVWSS_debug.log"

flutter run -v --debug -d 9A6B6687-8DE2-4573-A939-E4FFD0190E1A \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_rewrite_stageC_aa2d09b_pass1_1h_ios_iPhone17Pro_9A6B6687_debug.log"

flutter run -v --debug -d macos \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_rewrite_stageC_aa2d09b_pass1_1h_macos_debug.log"

flutter run -v --debug -d chrome \
  --dart-define=APP_ENV=prod \
  --dart-define=ALLOW_PROD_IN_DEBUG=true \
  2>&1 | tee "$LOG_DIR/2026-03-14_fix26_rewrite_stageC_aa2d09b_pass1_1h_chrome_debug.log"
```
