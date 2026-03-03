# Plan — Rapid Validation Fixes (Late-start, Pre-Run, Ranges, Black Screen)

Date: 2026-02-24
Source: docs/bugs/validacion_rapida.md and docs/bugs/capturas-validacion

## Scope (Bugs To Fix)
1. Late-start queue Cancel all does not resolve mirrors; mirrors can continue after owner cancel.
2. Resolve overlaps with zero selected groups should behave like Cancel all (no black screen).
3. Pre-Run auto-open bounces or duplicates; must be idempotent on owner and mirror.
4. Pre-Run to Running sometimes shows Resolve overlaps without real conflict.
5. Groups Hub schedule shows +1 minute gap; scheduled time vs pre-run start confusion.
6. Timer status boxes and task item ranges are out of sync after pause and resume.
7. Postpone updates do not propagate to mirror quickly (stale schedule).
8. Black screen on logout while running or paused, and any other navigation path that can blank the UI.
9. Account pre-run notifications still fire after switching to Local Mode (macOS).

## Decisions And Requirements
- Mirror after Cancel all shows a modal "Owner resolved" with OK, then navigates to Groups Hub.
- Zero selected groups in Resolve overlaps equals Cancel all (same modal and cleanup).
- Groups Hub shows "Pre-Run X min starts at HH:mm" when notice applies.
- Scheduled in Groups Hub shows the run start time, not the pre-run start.
- Pre-Run and Run Mode auto-open must occur on both owner and mirror.
- If the user leaves Pre-Run, Run Mode still auto-opens at group start.
- Cancel and Logout must never leave a blank screen.
- Switching to Local Mode must cancel any pending Account pre-run notifications on that device.

## Plan (Docs First, Then Code)
1. Update specs to define the expected flows, UI copy, and navigation guard rules.
2. Update roadmap reopened items for black screen and new UI requirement if missing.
3. Append dev log entry for changes and decisions.
4. Implement late-start queue mirror resolution flow and guard against actions after cancel.
5. Treat zero selection as Cancel all (reuse the same path).
6. Make auto-open idempotent with route guards keyed by groupId and phase.
7. Ensure Pre-Run to Running does not route to Resolve overlaps unless an actual conflict exists.
8. Fix schedule display by separating run start from pre-run start and eliminate extra minute.
9. Align Timer status boxes with authoritative ranges (actualStartTime plus pause offsets).
10. Ensure mirror schedule updates refresh immediately after postpone.
11. Add navigation guards to prevent black screens on logout or cancel and keep UI navigable.
12. Add debug-only instrumentation for late-start evaluation and a one-shot recheck after Local → Account when time sync and group streams are ready.

## Acceptance Criteria
1. Mirror gets "Owner resolved" modal after Cancel all and exits to Groups Hub.
2. Resolve overlaps with zero selection yields the same result as Cancel all with no black screen.
3. Pre-Run auto-opens once on both devices with no duplicate navigation or Groups Hub bounce.
4. Run Mode opens at group start on both devices even if the user left Pre-Run.
5. Resolve overlaps does not appear without a real conflict after pre-run.
6. Groups Hub shows explicit pre-run start time and correct scheduled run start.
7. Timer status boxes and task item ranges always match.
8. Postpone updates appear on mirror without stale schedule.
9. Logout while running or paused does not produce a black screen.
10. After switching to Local Mode, no **Account Mode** pre-run notifications fire (OS-level schedule must be canceled).

## Validation Checklist
- Re-run steps A through H in docs/bugs/validacion_rapida.md.
- Verify screenshots 01 to 28 are no longer reproducible.
- Confirm on macOS and Android in owner and mirror roles.

## Validation Attempts

### 2026-03-03 — Account Mode (Local → Account switch, re-plan canceled groups)
- Setup: macOS owner + Android mirror. Groups created by re-plan (no brand-new groups).
- Flow: switched to Local Mode, then back to Account Mode (no app close).
- Result: FAIL at late-start trigger.
  - No late-start queue or Resolve overlaps surfaced after scheduledStartTime passed.
  - Firestore shows groups still `status=scheduled` after scheduledStartTime.
  - lateStart fields remained null (`lateStartAnchorAt/lateStartQueueId/lateStartOwnerDeviceId`).
- Evidence:
  - Screenshot 21.
  - Logs:
    - `docs/bugs/validation_fix_2026_02_24/logs/2026_03_02_android_RMX3771_debug.log`
    - `docs/bugs/validation_fix_2026_02_24/logs/2026_03_02_macos_debug.log`

### 2026-03-03 — Account → Local (macOS)
- Observation: After switching to Local Mode, the “1 minute remaining” pre-run
  notification still fired for an Account scheduled group.
- Evidence: user observation (logs did not include runtime notification traces).

### 2026-03-03 — Steps 4–6 partial (owner + mirror)
- Step 4 (Run again → Start now) and Step 5 (mirror reopen/background) passed.
- Step 6: pause/resume range looked correct, but after navigating to Groups Hub
  and returning to Run Mode, timers drifted between devices (screenshots around
  03:09 and 03:12). Android log was lost after closing the app in Step 5.

### 2026-03-03 — Mirror stuck in “Syncing session...” (owner running)
- Approx time: ~18:41 CET (Pomodoro 2/16, mirror stuck at 25:00).
- Owner: macOS (deviceId `macOS-720d9b30-8d36-4c25-bac5-68832adace86`).
- Mirror: Android RMX3771.
- Firebase session snapshot (key fields): `sessionRevision=6`, `status=pomodoroRunning`,
  `phaseStartedAt=2026-03-03 18:49:01`, `remainingSeconds=999`,
  `lastUpdatedAt=2026-03-03 18:57:23`, `timeSync.serverTime=2026-03-03 18:57:23`.
- Evidence: chat capture (Syncing session on mirror while owner advances).
- Logs:
  - `docs/bugs/validation_fix_2026_02_24/logs/2026_03_02_android_RMX3771_debug.log`
  - `docs/bugs/validation_fix_2026_02_24/logs/2026_03_02_macos_debug.log`

### 2026-03-03 — Mirror stuck in “Syncing session...” (repeat)
- Approx time: ~19:41 CET (Pomodoro 4/16). Mirror still shows 25:00 + “Syncing session...”
  while owner continues (shows ~02:03 remaining).
- Mirror: Android RMX3771. Owner: macOS.
- Evidence: chat capture at 19:41.
- Logs (same ongoing run):
  - `docs/bugs/validation_fix_2026_02_24/logs/2026_03_02_android_RMX3771_debug.log`
  - `docs/bugs/validation_fix_2026_02_24/logs/2026_03_02_macos_debug.log`

### 2026-03-03 — Syncing session recovery via Groups Hub (owner + mirror)
- Scenario: Mirror showed **Syncing session...** while owner continued running.
- Action: Opened Groups Hub and returned to Run Mode.
- Result: Mirror re-synced and timer aligned with owner (19:03 CET).
- Evidence: chat capture at 19:03 (Pomodoro 3/16, 10:58 remaining on both).
- Logs: ongoing debug logs
  - `docs/bugs/validation_fix_2026_02_24/logs/2026_03_02_android_RMX3771_debug.log`
  - `docs/bugs/validation_fix_2026_02_24/logs/2026_03_02_macos_debug.log`

### 2026-03-03 — Step 5/6 failure (iOS owner + Chrome mirror)
- Step 5 (mirror reopen/background) initial reopen OK; owner snapshot valid.
- Pause ~60s: mirror showed **Syncing session...** for ~30s, then recovered.
- After Groups Hub → Run Mode, `phaseStartedAt` advanced and `remainingSeconds`
  shifted forward. Repeating the navigation compounded the drift until
  `remainingSeconds` reset to 900 (screens around 20:12–20:15).
- Chrome mirror additionally froze at **15:00** for a period, then resumed
  ticking but remained desynchronized.
- Drift is monotonic and increases by roughly the same delta on each return
  (e.g., 08:39 vs 09:43 → 09:33 vs 10:37 → 10:30 vs 11:34 → 11:26 vs 12:30,
  then 15:00/15:00 snapshots), indicating cumulative offset per reopen.
- Repro also occurs when the **owner** navigates away to other screens (e.g.,
  Task List) and returns; not limited to Groups Hub.
- Effect: owner/mirror timers diverge and “add time” with each round-trip.
- Evidence: chat captures at 20:10–20:15 (iOS simulator + Chrome).
- Logs:
  - `docs/bugs/validation_fix_2026_02_24/logs/2026_03_03_ios_simulator_debug.log`
  - `docs/bugs/validation_fix_2026_02_24/logs/2026_03_03_chrome_debug.log`

### 2026-03-03 — Step 5/6 failure (post-fix, Chrome owner + iOS mirror)
- Roles: Chrome owner, iOS mirror (owner ownership handed back to iOS for pause).
- Ownership accept required two taps on macOS (21:18 CET) before the request
  stayed accepted.
- Pause at ~21:19 CET; iOS showed **Syncing session...** for ~60s, then recovered.
- After Groups Hub → Run Mode (and other screen returns), the drift reappeared.
  Repeating the navigation compounded the drift (≈6 times) until Chrome froze
  at **15:00** and then resumed ticking but remained desynced.
- Evidence: chat captures at ~21:21–21:22 showing monotonic drift deltas
  (screenshots 27–35).
- Logs (post-fix run):
  - `docs/bugs/validation_fix_2026_02_24/logs/2026_03_03_ios_simulator_postfix_debug.log`
  - `docs/bugs/validation_fix_2026_02_24/logs/2026_03_03_chrome_postfix_debug.log`

### 2026-03-04 — Step 6 pass (post-fix2, iOS owner + Chrome mirror)
- Flow: iOS owner started G1, ownership handed to macOS on request, iOS closed
  and reopened, backgrounded ~10s, then Groups Hub → Run Mode return stayed in
  sync. Paused ~60s and resumed; timers remained aligned (no drift after
  navigation).
- Result: PASS (Step 6).
- Logs:
  - `docs/bugs/validation_fix_2026_02_24/logs/2026_03_03_ios_simulator_postfix2_debug.log`
  - `docs/bugs/validation_fix_2026_02_24/logs/2026_03_03_chrome_postfix2_debug.log`
- Commit: `ead72fb` — Fix account session hydrate drift and validate step 6.

### 2026-03-04 — Steps 7–13 pass (post-fix2)
- Step 7: scheduling accepts; if it cannot align by seconds, warning appears and
  auto-shifts to +1 minute (notice handled from Groups Hub).
- Step 8: Groups Hub scheduled row matches (Pre-Run 1 min starts at HH:mm).
- Step 9: G2 pre-run auto-opened correctly (~00:12).
- Step 10: G1 completion waited until pre-run time in Groups Hub; OK.
- Step 11: G2 start time auto-opened; cancel returned to Groups Hub.
- Step 12: Logout safety OK on Android; iOS + Chrome also OK (Local Mode).
- Step 13: Local Mode pre-run suppression OK.
- Logs (shared with Step 6 run):
  - `docs/bugs/validation_fix_2026_02_24/logs/2026_03_03_ios_simulator_postfix2_debug.log`
  - `docs/bugs/validation_fix_2026_02_24/logs/2026_03_03_chrome_postfix2_debug.log`

## Root Cause (Confirmed)
- `_resetForModeChange()` clears in-memory timers and `_scheduledNotices`, but does
  **not** cancel OS-level scheduled notifications via `NotificationService`.
- Three scheduling paths can leave OS notifications active across mode changes:
  - `ScheduledGroupCoordinator._scheduleLocalPreAlert` (tracked in `_scheduledNotices` only).
  - `TaskListScreen._scheduleGroupPreAlert` (no tracking).
  - `GroupsHubScreen` scheduling path (no tracking).
- Late-start heartbeat updates crashed due to a Firestore transaction
  read-after-write pattern in `updateLateStartOwnerHeartbeat`, interrupting
  overlap queue processing (see 2026-03-02 logs).
- AppModeChangeGuard invalidation disposes `ScheduledGroupCoordinator` on mode
  switches, canceling freshly scheduled pre-run/start timers when returning to
  Account Mode from Local Mode.
- Account Mode timer drift: `_hydrateOwnerSession` re-anchors running phases
  from `remainingSeconds` (already reflects `accumulatedPausedSeconds`) and then
  republishes, inflating `remainingSeconds` on each owner screen return.

## Hypotheses (Root Cause Candidates)
1. Late-start detection did not run after Local → Account switch, or ran before Firestore groups were loaded.
2. Overdue detection returned empty because effective scheduled start shifted (e.g., via unintended `postponedAfterGroupId` or schedule recalculation).
3. Auto-start for overdue groups failed (time sync or repo gating), leaving groups `scheduled` without triggering late-start queue.

## Implementation Updates

### 2026-03-03
- Moved Account → Local pre-run notification cancellation into `ScheduledGroupCoordinator` to avoid provider circular dependency (covers all scheduling paths via group-id cancel).
- Added debug-only late-start evaluation logs, timer scheduling logs, and an account-mode recheck after Local → Account when group/session streams and time sync are ready.
- Validation pending (see `docs/bugs/validation_fix_2026_02_24/quick_pass_checklist.md`).

### 2026-03-03 (follow-up)
- Added debug-only timer state logs and AppModeChangeGuard invalidation logs to track timer cancellations and provider resets.

### 2026-03-03 (late-start recheck burst + heartbeat fix)
- Added a bounded account recheck burst (short retries) after Local → Account
  to recover late-start evaluation and scheduled timers after provider disposal.
- Fixed Firestore late-start heartbeat update to avoid read-after-write in
  transactions.
- Specs updated to document the bounded recheck behavior.

### 2026-03-03 (coordinator retention on logout)
- Removed `invalidate(scheduledGroupCoordinatorProvider)` during logout/local
  switch so the coordinator is not disposed mid-schedule; mode change now relies
  on `_resetForModeChange()` to clear timers safely.

### 2026-03-03 (mirror queue resolution guard)
- Mirror now treats a resolved late-start queue (owner/anchor cleared) as
  "Owner resolved" and disables actions; auto-claim is suppressed once resolved.

### 2026-03-03 (Account Mode running anchor)
- `_hydrateOwnerSession` now anchors running/paused phases to
  `session.phaseStartedAt` in **Account Mode** and avoids re-publishing the
  session during hydration, preventing monotonic drift on owner screen returns.
- Validation pending (re-run Step 6).

## Urgent Pending (Do Not Skip)
1. **Single source of truth breach (Account Mode):** owner rehydrates from
   `PomodoroSession` and then applies `TaskRunGroup` timeline projection
   (`_applyGroupTimelineProjection`). This introduces a second timeline that
   ignores `accumulatedPausedSeconds`, causing timer drift after pause.
   Evidence: Step 6 drift after returning from Groups Hub (screenshots around
   03:09 and 03:12).
2. **P0-4 status:** implemented but validation failed; Firestore rules were
   rolled back due to permission errors. This remains open.
3. **P0-5 status:** not implemented yet.

### Required next steps (in order)
1. **Docs first:** update `docs/specs.md` to state that in **Account Mode** the
   Run Mode projection is **always** derived from `PomodoroSession` when a
   session exists; `TaskRunGroup` timeline projection is **Local Mode only**
   (or for previews when no session exists). **DONE 03/03/2026.**
2. **Code fix:** in `PomodoroViewModel._hydrateOwnerSession`, do not call
   `_applyGroupTimelineProjection` when `appMode == AppMode.account`. **DONE
   03/03/2026 (validation pending).**
3. **Validate Step 6:** pause → go to Groups Hub → return to Run Mode.
   Owner and mirror timers must stay aligned (<=2s drift). **DONE 03/04/2026.**
4. **Record state:** update this plan, `docs/dev_log.md`, and
   `docs/roadmap.md` with the final commit hash + validation outcome.
   **DONE 03/04/2026 — `ead72fb`.**
