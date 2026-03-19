# Bug Log — Focus Interval (MVP 1.2)

Central log of observed bugs. Keep entries in chronological order with newest
at the end.

Entry format:
- ID:
- Date (with UTC offset):
- Platforms:
- Context:
- Repro steps:
- Symptom:
- Observed behavior:
- Expected behavior:
- Evidence:
- Workaround:
- Hypothesis:
- Fix applied:
- Status:

Optional details (use when available):
- Device roles (owner/mirror) and mode (Account/Local).
- Group type (planned range/total-time vs start now).
- Snapshot timeline (timestamp -> key Firestore fields).

---

## BUG-001 — Mirror shows Ready with active session (intermittent)

ID: BUG-001
Date: 13/02/2026 (UTC+1)
Platforms: macOS owner + Android mirror
Context: Group started from range planning. macOS becomes owner. Android open in mirror.

Symptom:
Android mirror shows Ready as if no session while Firestore stays in pomodoroRunning.
It later auto-syncs back to the timer after a short gap or when foregrounded.

Additional scenario:
After ownership handoff (macOS becomes mirror) and accepting an ownership request,
the new mirror showed Ready for several seconds (up to ~1 minute) before resyncing.

Additional scenario (16/02/2026):
Planned group scheduled 16:35–20:10. Android was mirror, macOS owner. After the
break into Pomodoro 2, Android went to background and later showed Ready in Run
Mode while the session was running. No ownership changes occurred. Sync only
returned after entering Groups Hub and coming back to Run Mode.

Additional scenario (17/02/2026):
Planned group scheduled by total time. macOS became owner at pre-run with both
apps open. During the first break, Android requested ownership and macOS accepted.
Later (Pomodoro 2 or its break), macOS (mirror) switched to Ready and stayed
there while the run continued into Pomodoro 3. It did not resync until the
macOS app was tapped (sometimes tap was insufficient and required leaving to
Groups Hub and returning). Returning to Run Mode often shows Ready briefly
before syncing.

Additional scenario (20/02/2026):
Mirror frequently shows Ready at the start of breaks while the group is running.
On macOS, clicking inside the app window re-syncs. On Android, a tap may not
recover; navigation to Groups Hub and back is required to resync Run Mode.

Observed moment: Pomodoro 2, ~13 minutes remaining.

Evidence (Firestore state at failure):
- status: pomodoroRunning
- phase: pomodoro
- ownerDeviceId: macOS
- remainingSeconds: ~624
- lastUpdatedAt: 13/02/2026 15:08:36 (UTC+1)

Evidence (16/02/2026, planned range group):
- Firestore snapshot 17:25:02 (UTC+1): status pomodoroRunning, phase pomodoro,
  phaseStartedAt 17:05:00, remainingSeconds 298, ownerDeviceId macOS.
- Android screenshot at ~17:26 shows Ready with Start disabled while the group
  was active; resync after Groups Hub navigation.

Evidence (after foreground):
- remainingSeconds: ~470
- lastUpdatedAt: 13/02/2026 15:11:10 (UTC+1)

Expected behavior:
Never show Ready if activeSession is running. During stream gaps, show
"Syncing session..." and provide a clear refresh path if the session is still
running.

Hypothesis:
Temporary activeSession stream gaps on Android are interpreted as missing
sessions. Gaps exceeding the 45s stale threshold can drop to Ready.

Fix applied:
Branch: bug-mirror-ready-screen (merged main, PR #78).
Change: Guard in PomodoroViewModel keeps Syncing based on last session +
lastUpdatedAt (45s).
Superseded by Fix 26 rewrite: _shouldTreatMissingSessionAsRunning removed;
TimerService now drives countdown independently and SSS debounces stream nulls
(3s) before entering hold → mirror shows "Syncing session..." instead of Ready.

Status:
Closed/OK (17/03/2026). Not reproduced in 10+ hours of device use post Fix 26
rewrite, and confirmed again in the 17/03/2026 BUG-001/002 validation run
(Android RMX3771 mirror + macOS owner). No Ready state was observed on either
device during mirror stream gaps or ownership transfers throughout a sustained
multi-ownership-transfer session. Mirror showed Syncing state (SSS hold) as
expected and returned to the running timer without navigation. Formally closed
with logs:
  docs/bugs/validation_bug001_bug002_2026_03_17/logs/2026-03-17_bug001_bug002_android_RMX3771_debug.log
  docs/bugs/validation_bug001_bug002_2026_03_17/logs/2026-03-17_bug001_bug002_macos_debug.log

---

## BUG-002 — Ownership rejection desync after background/resume

ID: BUG-002
Date: 13/02/2026 (UTC+1)
Platforms: Android + macOS
Context: Planned group scheduled by time range. Initial state Android mirror,
macOS owner. During a break, Android is backgrounded (app kept running), then
foregrounded. Android issues ownership requests; macOS rejects at least once.

Repro steps:
- Start a planned group (range scheduling). macOS = owner, Android = mirror.
- Pause on macOS; Android is backgrounded (app running), then foregrounded.
- Accept ownership on macOS; observe Android UI state and control availability.
- Repeat with Retry from Android when the amber owner-requested indicator remains.

Symptom:
- Android mirror can remain in requested/Ready after ownership rejection and
  become visually desynced from activeSession; requires navigation to Groups Hub
  and back to resync.
- After acceptance, Android can stay in amber "requested" state with Pause/Cancel
  disabled even when Firestore shows Android as owner.
- Owner can flip back to macOS seconds after acceptance; Android still shows
  pending/requested UI even with no active ownershipRequest in Firestore.

Observed behavior:
- Condensed sequence:
  - Android backgrounded during break (app not closed), then foregrounded.
  - Android requests ownership; macOS rejects; Android requests again.
  - After rejection(s), Android UI shows Ready or stale requested state while
    Firestore reports an active running session.
  - Ownership request can appear on macOS only after Android taps Retry
    (delayed delivery).
- After ownership request rejection, Firestore shows
  `ownershipRequest.status = rejected` with `respondedByDeviceId = macOS...`,
  but Android stays in Ready or shows stale requested state.
- During desync, Firestore still shows `activeSession.status = pomodoroRunning`
  and `remainingSeconds` continues to decrease.
- Android only resyncs after leaving Run Mode to Groups Hub and returning; then
  the rejection snackbar appears and mirror view updates.
- After macOS accepts a request and Firestore shows Android as owner, Android UI
  can remain amber (requested) with Pause/Cancel disabled; seconds later ownership
  flips back to macOS while Android still shows pending/requested state.
- After returning from Groups Hub, UI can look correct but Firestore still
  contains a rejected ownershipRequest from the delayed Retry flow.
- Additional scenario (16/02/2026): After Android (mirror) went Ready following
  background usage (WhatsApp), it stayed in mirror and requested ownership.
  macOS accepted, Firestore showed Android owner, but Android remained requested
  and ownership flipped back to macOS unless Run Mode was refreshed quickly.
- Follow-up (same day): After ownership stabilized with Android as owner and
  macOS as mirror, macOS showed ~5 seconds less remaining than Android (mirror
  ahead), indicating a small but persistent offset.
- Continuation: The offset continued to increase over time during the break,
  not staying constant.
- While interacting with the macOS app, the Run Mode UI pulsed each second,
  alternating between the synced timer and the offset timer (as if swapping
  between owner and stale mirror projections).
- After navigating to Groups Hub and back to Run Mode, the mirror re-synced and
  matched the owner/Firebase again.

Expected behavior:
- Ownership rejection should immediately clear pending/requested UI and return
  to normal mirror without blocking Run Mode.
- If `activeSession.status` is running or paused, Android must never sit in
  Ready beyond a brief sync state.

Evidence:
- Firestore snapshot after rejection showed `ownershipRequest.status = rejected`
  and `respondedByDeviceId = macOS...` while Android UI remained Ready or
  requested.
- Example snapshots (UTC+1):
  - 21:06:58 requestedAt (requestId `8f06d01c-...`, requester android);
    21:07:02 respondedAt, status `rejected`, respondedBy macOS.
  - 21:07:25 pausedAt with `status = paused`, `ownerDeviceId = macOS`, yet
    Android UI showed Ready/mirror mismatch.
  - 21:13:21 `status = pomodoroRunning`, `remainingSeconds = 516`,
    `ownerDeviceId = macOS`, but Android stayed in Ready for >1 minute.
  - 21:14:54 after navigating to Groups Hub and back, Android re-synced and
    showed the rejection snackbar; Firestore still `pomodoroRunning`.
- Additional snapshots (UTC+1, long break, Pomodoro 4/7):
  - 23:38:53 `ownerDeviceId = macOS`, `status = longBreakRunning`,
    `remainingSeconds = 658` while Android showed Ready earlier.
  - 23:44:01 requestId `d4834ac2-...` pending (requestedAt 23:43:54) while
    Android showed amber requested sheet.
  - 23:44:32 `ownerDeviceId = android` after macOS accepted, yet Android stayed
    amber with Pause/Cancel disabled.
  - 23:46:03 `ownerDeviceId = macOS` (ownership flipped back) while Android
    still showed requested UI.
  - 23:47:04 requestId `341cc0e1-...` pending (requestedAt 23:47:21) after Retry.
  - 23:48:36 `ownerDeviceId = android` after accept; Android still amber.
  - 23:49:32 `ownerDeviceId = macOS` while Android continued to show requested.
- 14/02/2026 00:04:46 snapshot shows `ownershipRequest.status = rejected`
  (requestId `3cfac1a5-...`, requestedAt 00:00:26, respondedAt 00:00:28 by
  macOS) while `status = pomodoroRunning` and `remainingSeconds = 629`
  (Pomodoro 5/7).
- Screenshots show Android in amber requested state with Pause/Cancel disabled
  while macOS shows owner controls and the ownership modal.
- User report (16/02/2026): after Ready screen on mirror, ownership acceptance
  still reverted unless Run Mode was refreshed within ~20–30s.
- User report (16/02/2026): once Android remained owner, macOS mirror showed
  ~5 seconds less remaining (mirror ahead).
- User report (16/02/2026): during the following break, the drift grew over
  time and macOS UI flickered between the synced and offset timers on a
  per-second pulse.
- User report (18/02/2026): Start Now with macOS owner. Android app was open
  on Task List and did not auto-open Run Mode. After requesting ownership and
  accepting on macOS, Firestore briefly showed Android as owner but Android
  froze in requested state; within ~5 seconds ownership reverted to macOS.

Workaround:
- Navigate Android to Groups Hub and back to force re-sync.
- Use Retry in the ownership sheet to re-issue the request.
- After ownership acceptance, exit to Groups Hub and return within ~20–30s to
  prevent the owner from reverting back to the previous device.

Additional scenario (17/02/2026, UTC+1):
Long background ownership loop. Android owner accepted requests but ownership
reverted to macOS within seconds; Android stayed in requested/retry until
Groups Hub navigation.

Evidence (Firestore snapshots, UTC+1):
- 23:41:51 ownerDeviceId = android after macOS accepted (shortBreakRunning).
- 23:44:13 ownerDeviceId = macOS shortly after (auto-claim).
- 23:46:15 ownerDeviceId = android after accept (requestId 7c73a503...).
- 23:47:17 ownerDeviceId = macOS again; Android stuck pending/retry.

Observed behavior:
- Ownership flips back to macOS shortly after accept, even without a new manual
  request; Android remains in requested/retry UI.
- Only navigating to Groups Hub and back resets the state.

Hypothesis:
- Ownership accept does not refresh lastUpdatedAt, so the new owner appears stale
  immediately and macOS auto-claims; requester UI remains stale without a
  forced resubscribe.

Hypothesis:
- Ownership request UI state is not cleared/overridden after rejection when the
  requester resumes from background; local pending state or session-gap handling
  may mask the latest snapshot.
- Ownership revert may be triggered by a stale snapshot or delayed resubscribe;
  immediate Run Mode refresh appears to stabilize the accepted owner.

Fix applied:
Branch: bug-ownership-sync-stabilization (merged main, PR #121).
Change: respondToOwnershipRequest sets lastUpdatedAt = serverTimestamp() on
both approve and reject; sessionRevision incremented in both paths.

Current state (17/03/2026, post Fix 26 rewrite, BUG-001/002 validation run):

Devices: Android RMX3771 (mirror initially, then owner-swap) + macOS (owner initially).
Group was already started before the run; multiple consecutive ownership transfers performed.
Logs:
  docs/bugs/validation_bug001_bug002_2026_03_17/logs/2026-03-17_bug001_bug002_android_RMX3771_debug.log
  docs/bugs/validation_bug001_bug002_2026_03_17/logs/2026-03-17_bug001_bug002_macos_debug.log

Confirmed resolved:
- Ownership revert after accept: ✅ not reproduced.
  lastUpdatedAt fresh after respondToOwnershipRequest; auto-claim does not fire
  within 45s window.
- Mirror Ready after rejection: ✅ not reproduced.
  Fix 26 SSS debounce prevents drop to Ready on stream gaps.

Residual symptom confirmed (rejection banner on owner):
- After owner (macOS) rejects a request, the ownership request banner does NOT
  clear immediately on the owner device.
- First rejection (~20:06): banner cleared at ~20:06:52 — coinciding with the
  next Firestore lastUpdatedAt heartbeat write (approximately one Firestore
  propagation cycle delay).
- Third rejection (~20:07:59): banner required a second Reject press to clear
  (first press did not clear it; second press cleared it immediately).
- Fourth rejection (~20:08:27+): same banner persistence observed.
- Root cause: the owner's local rejection UI state is not cleared optimistically;
  it waits for the Firestore snapshot to round-trip. When the snapshot arrives
  with `ownershipRequest.status = rejected`, the owner clears the banner — but
  this is one cycle later than expected. In some cases an intermediate snapshot
  (e.g., from the lastUpdatedAt heartbeat) arrives before the rejection snapshot,
  leaving the banner visible until the rejection snapshot catches up.
- Additional observation: at the second rejection (~20:07), macOS owner briefly
  showed `00:00` with a stale phase overlay before self-correcting. This is
  likely a consequence of BUG-F26-001 (stale Firestore cursor with
  `remainingSeconds: 0`) causing the owner to briefly apply the stale snapshot
  before re-projecting from TimerService.

Status:
Partially open. Primary symptoms (revert, Ready state) resolved by Fix 26.
Residual: rejection banner persistence on owner device (~1 Firestore cycle delay;
occasionally requires second Reject press). Root cause is lack of optimistic
banner clear on the owner side after respondToOwnershipRequest returns. See also
BUG-F26-001 for the secondary 00:00 flash symptom.

Code area: likely `lib/presentation/viewmodels/pomodoro_view_model.dart`
`rejectOwnershipRequest()` / `approveOwnershipRequest()` — add optimistic local
clear of the ownershipRequest banner state immediately after the Firestore write
succeeds, without waiting for the next stream snapshot.

Implementation update (17/03/2026):
- Implemented on branch `fix-ownership-cursor-stamp`:
  `rejectOwnershipRequest()` now applies immediate local ownership-request clear
  on owner side and triggers `_notifySessionMetaChanged()` before Firestore
  round-trip.
- Status moved to **In validation** pending device re-run evidence.

---

## BUG-003 — Mirror pulse refresh (~15s) after Android pause/resume

ID: BUG-003
Date: 13/02/2026 (UTC+1)
Platforms: macOS mirror + Android owner
Context: Planned group scheduled by time range. Initial state Android mirror,
macOS owner. During a break, Android is backgrounded, then foregrounded and
eventually becomes owner. Android pauses ~1 minute and then resumes; macOS moves
to mirror.

Symptom:
- macOS mirror flicks/rebuilds UI after Android pause/resume.

Observed behavior:
- After Android pause (~1 minute) and resume while Android is owner, macOS mirror
  shows periodic full UI refresh (timer circle, status boxes, task items) every
  ~15s though data appears unchanged.
- Only observed in mirror mode on macOS.
- Later observation: macOS in owner mode can also show a similar effect but less
  frequent (~30-45s) or as a brief pause (~0.5-1s) instead of a full flicker.
  Seen after macOS received ownership from Android that had been backgrounded
  before handoff.

Expected behavior:
- Mirror UI should stay visually stable; periodic refresh should not cause full
  rebuilds or visible flicker.

Evidence:
- Visual flick on macOS mirror observed repeatedly post-resume while
  `activeSession.status = pomodoroRunning` and values remain stable.
- Example snapshot near flick (UTC+1):
  - 21:01:44 `ownerDeviceId = android`, `status = pomodoroRunning`,
    `remainingSeconds = 1035`, `phaseStartedAt = 20:53:59`, yet UI rebuilds
    every ~15s on macOS mirror.
- User report (18/02/2026 ~13:53 UTC+1): after ownership transfer (Android
  owner, macOS mirror), macOS alternated between the correct owner timer and a
  stale timer offset by ~17–28 seconds. The mismatch persisted across pause/
  resume and carried into break; macOS break sounds fired ~20s late. Sample
  readings:
  - 13:53:17 (running): Android 19:04 vs macOS 18:47.
  - 13:53:23 (pause): Android 18:58 vs macOS 18:41.
  - 13:53:34 (resume): Android 18:58 vs macOS 18:30.
  - 13:53:43 (pause): Android 18:50 vs macOS 18:22.
  - 13:53:52 (resume): Android 18:50 vs macOS 18:12.

Hypothesis:
- Periodic resubscribe/refresh may trigger a full Run Mode rebuild even when
  derived values are unchanged.
- macOS mirror may keep a local timer running after ownership transfer or miss
  pause/resume snapshots, causing alternating projections (local vs remote).

Status:
Open. Low priority; cosmetic unless it escalates.

---

## BUG-009 — Mirror swaps between two timers every second (ownership handoff)

ID: BUG-009
Date: 18/02/2026 (UTC+1)
Platforms: macOS mirror + Android owner
Context: Ownership transfer completed. Android is owner, macOS is mirror. A pause
occurred earlier (exact device uncertain), then the mirror began alternating
between two timer values.

Symptom:
- macOS mirror alternates every second between the correct owner timer and a
  stale timer offset by ~17–28 seconds.
- Break sounds fire late on macOS (~20s late), matching the stale timer.

Observed behavior:
- Per-second swap visible in Run Mode (timer circle and status boxes), while
  Firestore remains consistent with the owner timer.
- The swap persists across pause/resume and can continue into breaks.

Evidence:
- 13:53:17 (running): Android 19:04 vs macOS 18:47.
- 13:53:23 (pause): Android 18:58 vs macOS 18:41.
- 13:53:34 (resume): Android 18:58 vs macOS 18:30.
- 13:53:43 (pause): Android 18:50 vs macOS 18:22.
- 13:53:52 (resume): Android 18:50 vs macOS 18:12.

Hypothesis:
- macOS mirror kept the local PomodoroMachine timer running after ownership
  transfer, causing per-second swaps between local ticks and session projection.

Fix applied:
- Attempted: suppress local PomodoroMachine timer while in mirror mode so the
  mirror projects solely from activeSession snapshots (merge #122).
  Regression reported (18/02/2026): after ownership accept, the new owner
  freezes and ownership reverts to the previous owner within seconds. Rollback
  pending.

Status:
Open. Fix attempt regressed ownership stability; rollback pending.

---

## BUG-004 — Mirror timer drift grows during long break

ID: BUG-004
Date: 13/02/2026 (UTC+1)
Platforms: macOS owner + Android mirror
Context: Planned group scheduled by time range. Ownership churn occurred earlier
in the session. During long break (Pomodoro 4/7), macOS remained owner and
Android stayed in mirror.

Repro steps:
- Run a planned group with macOS as owner and Android in mirror.
- After ownership requests/accepts, enter a long break.
- Compare remaining time shown on macOS vs Android over several minutes.

Symptom:
- Mirror timer lags behind owner and the drift increases over time.

Observed behavior:
- At the start of the long break, Android showed ~4s less remaining than macOS.
- The gap grew over time; by ~8 minutes remaining the difference was ~10s.
- Additional scenario (approx 16/02/2026 20:00 UTC+1):
  - Mirror went to Ready during an active run, then resynced after entering and
    leaving Groups Hub.
  - Ownership was requested and accepted; after the next phase change the mirror
    timer lagged by several seconds and did not auto-correct.
  - Pausing on the owner temporarily aligned the mirror, but resuming restored
    the same offset.
  - The desync persisted until another device opened in mirror, after which the
    original mirror re-synced.

Expected behavior:
- Mirror projection should stay within a small, stable tolerance from the owner
  (no accumulating drift over time).

Evidence:
- Screenshots around 23:42 show Android at 07:41 while macOS shows 07:47
  (same wall clock), indicating ~6s delta.
- Firestore snapshot (UTC+1) 23:41:28 shows `status = longBreakRunning`,
  `remainingSeconds = 507` while Android displayed fewer seconds than macOS.
- User report (16/02/2026 ~20:00 UTC+1): mirror desync appears after phase
  change following a Ready->Run recovery and ownership acceptance; pause/resume
  preserves the offset; new mirror device forces resync.
- User report (17/02/2026 ~23:52 UTC+1): owner macOS showed the correct timer
  after Groups Hub resync; Android displayed fewer seconds and the gap grew over
  time. Firestore snapshot 23:52:53 shows `remainingSeconds = 1060` with
  `ownerDeviceId = macOS` while Android showed less remaining.
- User report (18/02/2026 00:43:58 to 00:55:09 UTC+1): system clocks matched
  on Android and macOS, yet timers diverged and the gap grew:
  - 00:43:58: macOS 05:56 vs Android 05:14 (delta 42s).
  - 00:55:09: macOS 19:55 vs Android 19:02 (delta 53s).
  Gap increased ~11s in ~11 minutes during a long break.
- User report (18/02/2026 ~02:03–02:05 UTC+1): opening Groups Hub while running
  can **add seconds** on the device that navigated away and back. After return,
  the timer jumped forward (more remaining) and re-synced once a fresh
  lastUpdatedAt heartbeat arrived or ownership was accepted.
- Supporting snapshots (18/02/2026 UTC+1, macOS owner):
  - 02:03:54: remainingSeconds = 150 (before Groups Hub).
  - 02:04:24: remainingSeconds = 120 (2–5s after return).
  - 02:05:26: remainingSeconds = 60 (≈30s later).
  UI on the returning device briefly increased remaining time despite the
  Firestore countdown continuing normally.

Hypothesis:
- Mirror projection may be using a local clock without correction for snapshot
  cadence or server time offset, causing accumulating drift during long phases.
 - Phase-change projection may reuse a stale offset after resubscribe/ownership
   changes, and pause/resume re-applies the same offset instead of re-basing.
- Device clock skew between Android and macOS may compound projection drift;
  use a server time offset derived from Firestore timestamps.
- Since system clocks matched during the drift, projection logic itself is the
  likely root cause (local tick offset or re-base error).
- Opening Groups Hub may dispose the Run Mode VM and reset the offset, causing
  projection from a stale lastUpdatedAt until the next heartbeat arrives.

Fix applied:
- Implemented server-time offset projection in `PomodoroViewModel` so mirrors
  project from lastUpdatedAt-derived server time (pending validation).
- Added Run Mode keep-alive while active sessions exist to prevent offset reset
  on navigation (pending validation).

Status:
Open. Medium priority (visible correctness issue).

---

## BUG-010 — Mirror desync after Local → Account switch (short-lived)

ID: BUG-010
Date: 27/02/2026 (UTC+1)
Platforms: iOS owner + Web (Chrome) mirror
Context: User switched Chrome from Local Mode back to Account Mode while a group
was running on iOS (owner). Mirror was previously in Local Mode.

Repro steps:
- Start a running group on iOS (owner) in Account Mode.
- On Chrome, switch to Local Mode and interact (create a task/group).
- Cancel the Local Mode run and switch back to Account Mode.
- Observe the Run Mode timer on Chrome vs iOS immediately after the switch.

Symptom:
Mirror shows a different remaining time for several seconds, then re-syncs.

Observed behavior:
Chrome showed ~25s more remaining than iOS (e.g., 10:53 vs 10:28) right after
switching back to Account Mode; within seconds it corrected to match the owner.

Expected behavior:
Mirror should re-anchor immediately from activeSession without a visible
timer mismatch after a mode switch.

Evidence:
- Screenshots 13–14 show the temporary mismatch and subsequent sync.

Workaround:
Wait a few seconds; it auto-corrects.

Hypothesis:
Mode switch triggers a brief local projection using stale anchors before the
activeSession snapshot is re-applied.

Fix applied:
None.

Status:
Open. Low priority (brief visual inconsistency).

---

## BUG-011 — Pause offset drifts after background/foreground

ID: BUG-011
Date: 27/02/2026 (UTC+1)
Platforms: macOS + Android (real devices)
Context: Group paused and resumed, then owner device backgrounded for ~4 minutes
and returned to foreground.

Repro steps:
- Pause a running group, resume it.
- Background the owner device for ~4 minutes (app not killed).
- Return to foreground and observe remaining time vs expected.

Symptom:
Paused time offset appears incorrect after returning to foreground.

Observed behavior:
Remaining time reflects an incorrect pause offset until an ownership change
occurs; switching owner re-syncs and fixes the offset.

Expected behavior:
Pause offset should remain accurate across background/foreground transitions
without requiring ownership changes.

Evidence:
- User report from real devices (macOS + Android), 27/02/2026.

Workaround:
Trigger ownership change or force a resubscribe (navigate away and back).

Hypothesis:
Resume path reuses stale pause anchors or misses pause offset recomputation
after backgrounding.

Fix applied:
None.

Status:
Open. Medium priority (time correctness).

---

## BUG-012 — Mirror stuck on "Syncing session" until interaction

ID: BUG-012
Date: 27/02/2026 (UTC+1)
Platforms: macOS mirror + Android/macOS owners (reports)
Context: Mirror device shows "Syncing session" indefinitely while a group is
running; timer does not appear until user interacts.

Repro steps:
- Start a running group on an owner device.
- Open Run Mode on a mirror (macOS or Android).
- Observe the mirror state without interacting.

Symptom:
Mirror remains in "Syncing session" indefinitely and does not return to the
timer view.

Observed behavior:
Run Mode stays in Syncing until user clicks inside the app window or navigates
to Groups Hub and back. This happens repeatedly, especially on macOS mirrors.
On Android, tapping the screen does **not** recover; navigation to Groups Hub
and back is required.

Expected behavior:
Mirror should exit Syncing automatically once activeSession snapshots resume,
without requiring user interaction.

Evidence:
- User report: macOS mirror stuck multiple times; click inside the window
restores the timer. Android mirror also stuck once with macOS owner.

Workaround:
macOS: click the app window or enter Groups Hub and return to Run Mode.
Android: enter Groups Hub and return to Run Mode (tap does not recover).

Hypothesis:
Session stream subscriptions pause or debounce while the window is inactive,
and the UI never rebinds until a user event triggers a resubscribe.

Fix applied:
None.

Status:
Open. Medium priority (mirror usability).

---

## BUG-009 — Late-start queue desync + ownership gaps in Account Mode

ID: BUG-009  
Date: 20/02/2026 (UTC+1)  
Platforms: macOS owner + Android mirror  
Context: Account Mode late-open with multiple overdue scheduled groups.

Symptom:
- Late-start projections differed across devices (minute drift).
- Queue projections froze; confirm time did not match actual Run Mode start.
- Ownership unclear; mirrors could act or got stuck.
- Postpone did not drag remaining queued groups, causing repeated overlaps.

Expected behavior:
Deterministic late-start queue with a single owner, consistent projections, and
chained postpone for queued groups.

Fix applied:
- Server-anchored queue timebase + owner heartbeat.
- Owner-only queue with request/auto-claim.
- Live projected ranges, confirm sets scheduledStartTime to queueNow.
- ActiveSession bootstrap on confirm.
- Chained postpone for queued groups.

Status:
Pending validation on macOS/Android.

---

## BUG-008 — Overdue scheduled groups not resolved on late open (Account Mode)

ID: BUG-008
Date: 20/02/2026 (UTC+1)
Platforms: Android (Account Mode)
Context: No running group. Multiple scheduled groups already overdue when
opening the app late.

Repro steps:
- Plan 3 scheduled groups starting at 06:00 (15m each, 1m notice), consecutive.
- Close the app.
- Open at ~09:59 (all scheduled windows already in the past).

Symptom:
Late-start overlap queue does not appear. UI shows a running banner and a
completion modal with totals 0/0/0, then Groups Hub still shows all groups as
scheduled. Manual “Start now” bypasses overdue resolution. Confirm flow can
trigger duplicate navigation.

Observed behavior:
- Task List shows “Group running” banner despite no real running group.
- Completion modal “Tasks group completed” appears with 0 tasks/pomodoros/time.
- Groups Hub shows the 3 groups still scheduled.
- “Start now” starts one group directly (no overdue queue).
- Resolve overlaps appears only after canceling the running group.
- Confirm can cause Groups Hub double-load and a brief Timer flash.

Expected behavior:
- When opening late with overdue scheduled groups (no running), the late-start
  overlap queue should appear immediately.
- Manual “Start now” should not bypass overdue resolution.
- Confirm queue should navigate cleanly (single transition to Run Mode).
- Completion modal should not show with empty totals.

Evidence:
- User reproduction + screenshots (20/02/2026).

Workaround:
- Manually start/cancel to force the queue (not acceptable long-term).

Hypothesis:
- Stale activeSession clearing returned early, skipping overdue evaluation.
- “Start now” path bypassed late-start queue.
- Queue confirm and coordinator both navigated, causing duplicate transitions.
- Completion dialog allowed empty summaries.

Fix applied:
- ScheduledGroupCoordinator continues after clearing stale activeSession and
  re-evaluates overdue queue immediately.
- Late-start conflict detection moved to shared utility; Groups Hub “Start now”
  redirects to the late-start queue when conflicts exist.
- LateStartOverlapQueueScreen uses delayed fallback navigation to avoid double
  navigation on confirm.
- TimerScreen skips completion dialog when totals are empty.
- Added unit test for 3 overdue groups emitting late-start queue.

Status:
Fixed; validation pending on Android.

---

## Mitigation candidate — Run Mode resync overlay (Groups Hub equivalent)

Date: 18/02/2026 (UTC+1)
Scope: Run Mode (Account Mode)

Problem / Goal:
Multiple ownership/sync issues are temporarily resolved by entering and exiting
Groups Hub, which forces a resubscribe and state rehydration. Provide a
non-navigational fallback to achieve the same re-sync without leaving Run Mode.

Summary:
Add a lightweight "Syncing..." overlay in Run Mode that triggers:
- `syncWithRemoteSession(preferServer: true)`
- a controlled resubscribe to the activeSession stream
This should be used only when an inconsistency is detected (or via a manual
user action), to avoid unnecessary UI jumps.
Note:
Do not reuse the ActiveSession auto-opener for this mitigation. It only
navigates to `/timer/:id` and does not force a resubscribe; it cannot recover
from a frozen Syncing state.

Interaction options (pick one or combine):
- Tap anywhere on the Syncing screen to trigger the resync.
- Pull-to-refresh gesture on the Syncing state (if feasible in the layout).
- Explicit "Sync now" CTA or sync icon in the header while syncing.
Android: prefer an explicit "Sync now" CTA (tap-anywhere is unreliable).

When to use:
- Release fallback if ownership/sync bugs persist near MVP launch.
- Manual user action when timer state appears frozen or out of sync.

Risks:
- May mask underlying ownership bugs if overused.
- Can introduce visible jumps if the projection re-anchors.

Status:
Not implemented. Documented as a release mitigation if root cause is not fully
resolved.

---

## BUG-008 — Owner becomes stale while foreground (unexpected auto-claim)

ID: BUG-008
Date: 17/02/2026 (UTC+1)
Platforms: Android owner + macOS mirror
Context: Account Mode. Android in foreground with app open. Session running.
No manual ownership request/accept during the window.

Symptom:
Owner flips from Android to macOS without a manual request, while Android is
foreground and should be heartbeating.

Observed behavior (Firestore snapshots, UTC+1):
- 20:43:09 ownerDeviceId = android, status pomodoroRunning.
- 20:46:00 ownerDeviceId = macOS, status pomodoroRunning.

Expected behavior:
If the owner device is active/foreground, it must keep heartbeating and should
not become stale. Auto-claim should not occur in this case.

Workaround:
None (manual resync via Groups Hub may stabilize UI).

Hypothesis:
During session stream gaps, owner heartbeat is suppressed (controls disabled),
so lastUpdatedAt becomes stale even while owner is active.

Fix applied:
Pending (allow owner heartbeats while session is missing).

Status:
Open. High priority (ownership correctness).

## BUG-002 — Ownership rejection desync after background/resume

Additional scenario (17/02/2026, UTC+1):
Long pause/background test. Android was owner; both devices backgrounded. On
resume, ownership flipped to macOS and repeated request/accept cycles did not
stick on Android (owner reverted back to macOS). Only Groups Hub navigation
restored a stable state.

Evidence (Firestore snapshots, UTC+1):
- 20:09:03 ownerDeviceId = android, status pomodoroRunning, remainingSeconds 1023.
- 20:09:50 ownerDeviceId = macOS, status pomodoroRunning, remainingSeconds 972.
- 20:11:13 ownershipRequest pending (requestId d714b521... requester android).
- 20:11:53 ownerDeviceId = android after accept, remainingSeconds 851.
- 20:12:40 ownerDeviceId = macOS, remainingSeconds 805.
- 20:12:47 ownershipRequest pending (requestId 23e60ce8... requester android).
- 20:13:28 ownerDeviceId = macOS, remainingSeconds 758 (Android stuck pending/retry).

Observed behavior:
- Android request accepted on macOS (Firestore shows Android owner), but owner
  reverted to macOS shortly after.
- Android remained in requested/retry state and could not retain ownership.
- Sync timing itself stayed aligned (no timer drift), but ownership stability
  failed.
- Entering Groups Hub and returning re-synced the UI and cleared the stuck state.

Expected behavior:
- After owner accepts, ownership must remain stable on the requester until a new
  explicit transfer or auto-claim rule applies.

Additional scenario (17/02/2026, UTC+1, late test):
Context: Running session with macOS as owner. Android mirror requested
ownership after a background window (macOS lid closed during the wait).

Evidence (Firestore snapshots, UTC+1):
- 23:41:51 ownerDeviceId = android after macOS accept (shortBreakRunning).
- 23:44:13 ownerDeviceId = macOS (ownership reverted).
- 23:46:22 ownershipRequest pending (requestId 7c73a503..., requester Android).
- 23:46:15 ownerDeviceId = android after accept (pomodoroRunning).
- 23:47:17 ownerDeviceId = macOS (ownership reverted again).
Note: timestamps come from Firestore; capture order may differ slightly from
the request/accept sequence.

Observed behavior:
- After accept, Android briefly becomes owner, then flips back to macOS within
  ~15–20 seconds.
- Android UI remains in requested/retry; repeated retry/accept cycles loop.
- Only navigating to Groups Hub and returning stabilizes the session.

Expected behavior:
- Accepting an ownership request should stabilize ownership until a new
  explicit transfer or a documented auto-claim condition applies.

Additional scenario (18/02/2026, UTC+1, long break loop):
Repeated ownership flips during long break despite accept:

Evidence (Firestore snapshots, UTC+1):
- 00:38:05 ownerDeviceId = android (longBreakRunning).
- 00:39:06 ownerDeviceId = macOS (auto flip).
- 00:39:06 ownerDeviceId = android after retry/accept.
- 00:40:32 ownerDeviceId = macOS (auto flip).
- 00:41:32 ownerDeviceId = android after retry/accept.
- 00:42:32 ownerDeviceId = macOS (auto flip).
- 00:43:06 paused by macOS (pausedAt 00:43:06) while Android remained mirror.

Observed behavior:
- Android can obtain ownership via accept, but macOS reclaims within ~1 minute.
- Loop repeats without stabilizing on the requester.

## BUG-005 — Ownership request not surfaced until focus or resubscribe

ID: BUG-005
Date: 13/02/2026 (UTC+1)
Platforms: macOS owner + Android mirror
Context: Planned group scheduled by time range. Ownership requests can fail to
surface on the receiving device until focus or a manual resubscribe.

Repro steps:
- Variant A (macOS inactive): Keep macOS as owner and move focus to another app
  (window inactive).
- Variant A: From Android mirror, request ownership.
- Variant A: Observe macOS UI; then click/focus the macOS window.
- Variant B (Android receiver): Start a planned group; macOS owner pauses for
  ~5 minutes, then transfers ownership to Android (no background).
- Variant B: macOS is now mirror; if Run Mode shows Ready, tap to restore the
  running timer.
- Variant B: Request ownership from macOS (mirror) to Android (owner).
- Variant B: Observe Android; then navigate to Groups Hub and back to Run Mode.

Symptom:
- Ownership request does not appear on the receiving device until focus or a
  manual resubscribe.

Observed behavior:
- Variant A: Android shows a pending request, but macOS displays no modal/banner
  until the window is focused.
- Variant B: Android shows no incoming request; after navigating to Groups Hub
  and back, the request appears and can be accepted.
- Variant B: macOS (mirror) briefly showed Ready as if the run had not started;
  tapping the screen returned it to the correct running timer, then the
  ownership request failed to surface on Android.
- Variant B: After the Ready -> tap recovery, backgrounding the owner
  (Android) and returning also surfaced the pending request.
- Variant B: Another occurrence showed macOS mirror stuck on Ready shortly
  after a Pomodoro started; clicking inside the app restored the running timer,
  and the subsequent ownership request to Android surfaced immediately and was
  accepted (no delay).
- Variant E (18/02/2026): macOS mirror went Ready, click restored the running
  timer, then a new ownership request (macOS -> Android owner) stayed pending
  in Firestore and did not surface on Android until Groups Hub navigation.

Expected behavior:
- Ownership requests should surface immediately on the receiving device without
  requiring focus changes or navigation.

Evidence:
- Variant A: 23:44:01 requestId `d4834ac2-...` pending while Android showed the
  request; macOS only displayed the modal after window focus.
- Variant B: User report — macOS request only appeared on Android after entering
  Groups Hub and returning to Run Mode.
- Variant B: User report — background/foreground on Android owner also revealed
  the pending request.
- Variant B: User report — Ready screen can recover on click and still allow
  immediate ownership request delivery, indicating the Ready state is not
  always tied to request delay.
- Variant C (18/02/2026): after multiple ownership changes and an owner pause,
  a mirror ownership request did not reach the owner until Groups Hub was opened
  and Run Mode was re-entered.
- Variant D (18/02/2026): while paused, macOS requested ownership from Android.
  Firestore showed `ownershipRequest = pending` (17:47:24 UTC+1), but Android
  did not surface the request until ~30s later (17:48:15 UTC+1). After that,
  subsequent requests/accepts succeeded without issues.
- Variant E (18/02/2026):
  - 18:40:45 Firestore shows `ownershipRequest` pending (requestId
    `b7d214e4-...`, requestedAt 18:38:15) with `ownerDeviceId = android` and
    `status = pomodoroRunning` (remainingSeconds 102).
  - 18:41:17 Firestore shows a new pending request (requestId
    `40aa8974-...`, requestedAt 18:41:24); Android still showed no request UI.
  - 18:43:17 Groups Hub snapshot shows the request still pending during
    shortBreak; returning to Run Mode (18:43:38) finally surfaced the request.
  - 18:44:04 after acceptance, `ownerDeviceId = macOS...` and the request
    cleared.

Workaround:
- Click/focus the macOS window to surface pending requests.
- Navigate Android to Groups Hub and back to force resubscribe.
- Background/foreground the Android owner to force resubscribe.

Hypothesis:
- Ownership request stream is missed by the receiver until a resubscribe
  trigger (window focus or navigation).
- Ready->Run recovery on the requester may not refresh the owner-side listener,
  leaving pending requests invisible until a manual resubscribe.

Fix applied:
None.

Status:
Open. Medium priority (blocks timely ownership handoff).

---

## BUG-006 — Status box time ranges ignore pause anchoring

ID: BUG-006
Date: 14/02/2026 (UTC+1)
Platforms: Not specified (Run Mode UI)
Context: In Run Mode, the contextual task list below the circle correctly
anchors time ranges on pause/resume (start stays fixed; end extends; future
ranges shift forward). The timer status boxes (Current/Next) also show
HH:mm–HH:mm ranges for Pomodoro/Break and should follow the same rule.

Repro steps:
- Start any group and enter Run Mode.
- Pause during a Pomodoro or Break phase, then resume.
- Compare time ranges shown in the status boxes vs the contextual task list.

Symptom:
- Status box HH:mm–HH:mm ranges update inconsistently on pause/resume, as if the
  pause impacts the current range start or rewrites past segments.

Observed behavior:
- On pause/resume, status box ranges do not follow the same anchoring behavior
  as the contextual task list; the current phase range can shift in a way that
  looks retroactive rather than forward-only.

Expected behavior:
- Current status box keeps its original start time and only extends its end
  time by the pause duration.
- Next status box (and later phases) shift forward by the accumulated pause
  offset.
- Past ranges already elapsed are not modified.
- Behavior matches the contextual task list logic exactly, per spec note:
  "Status boxes and contextual list update automatically (including time ranges
  after pause/resume)."

Evidence:
- Visual observation: task list time ranges behave correctly; status box ranges
  shift differently during pause/resume.

Workaround:
- None.

Hypothesis:
- Status boxes are computed from a re-based timeline (e.g., now or phase start)
  without applying the same pause-offset anchoring used by the task list.

Fix applied:
None.

Status:
Open. Medium priority (UX consistency).

---

## BUG-007 — Owner resumes behind mirror after background crash

ID: BUG-007
Date: 17/02/2026 (UTC+1)
Platforms: Android owner + macOS mirror
Context: Account Mode. Break after Pomodoro 6/19. Android owner. Group had been
paused earlier (~2.5–3h) with Android as owner, no ownership changes after.
Android went to background for ~90s (sending a WhatsApp audio); system showed
"app has stopped working". On returning to foreground, Android resumed as owner
but appeared ~5s behind the macOS mirror.

Symptom:
Owner device resumes a few seconds behind mirror after background crash.

Observed behavior:
- Android owner displayed ~5s less remaining than macOS mirror after resume.
- The difference resolved after entering and leaving Groups Hub (and clicking
  the macOS app), which re-synced the session.

Expected behavior:
Owner should re-anchor from the activeSession snapshot on resume so owner and
mirror show the same remaining time immediately.

Evidence:
- User report (17/02/2026): break after Pomodoro 6/19, ~90s background, Android
  system "app has stopped working" banner, owner returned behind mirror by ~5s.

Workaround:
Enter Groups Hub and return to Run Mode; click/focus the macOS app to force a
resubscribe.

Hypothesis:
Resume after crash/suspend reuses a stale local phase anchor instead of
re-anchoring from activeSession (server snapshot), causing a short owner lag
until a manual resubscribe occurs.

Fix applied:
None.

Status:
Open. Medium priority (visible correctness issue).

---

## BUG-F25-A — Firestore transaction read-write ordering violation in requestLateStartOwnership

ID: BUG-F25-A
Date: 16/03/2026 (UTC+1)
Platforms: iOS (confirmed), all platforms with multiple conflict groups
Context: Fix 25 re-validation run (post Fix-26 rewrite, main branch). iOS
simulator iPhone 17 Pro as owner, Chrome as mirror. Two scheduled groups with
overlap; iOS triggered requestLateStartOwnership for both groups.

Repro steps:
- Run Account Mode with 2+ overlapping scheduled groups.
- On the mirror device, let it trigger requestLateStartOwnership (when owner is
  stale or absent).
- Observe console for Firestore transaction assertion error.

Symptom:
All ownership request attempts silently fail. Chrome never receives any request.
Mirror stays blocked in the queue screen without an owner.

Observed behavior:
- iOS logged 4 consecutive requestLateStartOwnership failures at lines 50742,
  50775, 50796, 50819 of the re-validation log.
- Each failure is a Firestore SDK assertion: `_commands.isEmpty` — the SDK
  rejects a read that follows a write within the same transaction.
- In firestore_task_run_group_repository.dart:285, the loop interleaves reads
  and writes:
  Iteration 1: tx.get(group[0]) → tx.set(group[0])
  Iteration 2: tx.get(group[1]) → FAILS (_commands.isEmpty: write already issued)
- Chrome received zero ownership claim requests across the entire session.

Expected behavior:
All groups are read first (Phase 1), then all writes are issued (Phase 2),
so the Firestore transaction invariant is respected.

Evidence:
- iOS re-validation log:
  docs/bugs/validation_fix_2026_03_05/logs/2026-03-16_fix25_reval_ios_iPhone17Pro_debug.log
  Lines 50742, 50775, 50796, 50819 (repeated transaction assertion failures).
- Chrome re-validation log:
  docs/bugs/validation_fix_2026_03_05/logs/2026-03-16_fix25_reval_chrome_debug.log
  No ownership request arrival logged.

Workaround:
None. Ownership requests cannot be delivered while >1 group is in conflict.

Hypothesis:
Firestore Client SDK enforces that all reads precede all writes within a
transaction. The current loop structure (read-write per group) violates this
when groups.length > 1.

Fix applied:
- Implemented 16/03/2026 on branch `fix-f25-transaction-order-and-owner-dialog`.
- `requestLateStartOwnership` now executes in 2 phases inside one transaction:
  1. Read all conflict group documents first (`tx.get` only).
  2. Apply all writes (`tx.set`) after reads complete.
- File updated: `lib/data/repositories/firestore_task_run_group_repository.dart`.
- Local verification:
  - `flutter analyze` PASS
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` PASS
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS
  - `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` PASS

Status:
Closed/OK. P0 fixed and validated on 17/03/2026 re-validation #2
(`2026-03-17_fix25_reval2_fd788e6_*`): ownership requests were delivered and
accepted repeatedly with no transaction-order assertion.

---

## BUG-F25-B — context-after-dispose in _showOwnerResolvedDialog OK button

ID: BUG-F25-B
Date: 16/03/2026 (UTC+1)
Platforms: All (widget lifecycle issue)
Context: Fix 25 re-validation run. iOS simulator as owner, Chrome as mirror.
After the owner resolved the queue, Chrome's LateStartOverlapQueueScreen
transitioned to the "Owner resolved" state and showed the dialog. The state
was disposed before the user tapped OK.

Repro steps:
- Open the late-start overlap queue screen on a mirror device.
- Have the owner resolve the conflict on their device.
- The mirror screen transitions to "Owner resolved" and shows the dialog.
- Navigate away from the mirror screen (e.g., tap outside the dialog while
  the underlying screen is being disposed) before tapping OK.
- Tap OK in the dialog.

Symptom:
Cascade of exceptions; dialog cannot be dismissed cleanly; app may show errors.

Observed behavior:
- _showOwnerResolvedDialog (late_start_overlap_queue_screen.dart:549) shows
  an AlertDialog whose OK button captures the outer BuildContext:
    onPressed: () =>
        Navigator.of(context, rootNavigator: true).pop()  // line 563-564
- If _LateStartOverlapQueueScreenState is disposed before OK is tapped,
  accessing `context` here causes an "Element not mounted" assertion.
- The mounted guard at line 570 (`if (!mounted) return;`) protects the
  `context.go('/groups')` call AFTER the await, but does NOT protect the
  button callback itself.

Expected behavior:
OK button navigation always uses a captured Navigator reference, safe even
if the parent state disposes during the dialog lifetime.

Evidence:
- Chrome re-validation log:
  docs/bugs/validation_fix_2026_03_05/logs/2026-03-16_fix25_reval_chrome_debug.log
  Exception cascade on dialog dismiss attempt.
- Code location: late_start_overlap_queue_screen.dart:563-564.

Workaround:
None. Modal cannot be dismissed without exceptions on the affected device.

Hypothesis:
The dialog builder captures the State's BuildContext directly. The fix is to
capture the Navigator before the await showDialog call so the callback does
not depend on a mounted context.

Fix applied:
- Implemented 16/03/2026 on branch `fix-f25-transaction-order-and-owner-dialog`.
- `_showOwnerResolvedDialog` now captures root navigator before `await showDialog`
  and uses that captured navigator in the OK button callback.
- Added mounted pre-check (`if (!mounted || _ownerResolvedDialogShown) return;`)
  before opening the dialog.
- File updated: `lib/presentation/screens/late_start_overlap_queue_screen.dart`.
- Local verification:
  - `flutter analyze` PASS
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` PASS
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS
  - `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` PASS

Status:
Closed/OK. P0 fixed and validated on 17/03/2026 re-validation #2
(`2026-03-17_fix25_reval2_fd788e6_*`): no context-after-dispose/Navigator
exceptions were observed while closing owner-resolved dialog flows.

---

## BUG-F25-C — "Owner resolved" modal shown on owner device after conflict resolution

ID: BUG-F25-C
Date: 16/03/2026 (UTC+1)
Platforms: All (Account Mode, late-start overlap queue)
Context: Fix 25 re-validation run. iOS simulator as owner. After iOS resolved
the conflict (canceled groups or confirmed selection), the "Owner resolved"
modal appeared on the iOS device itself — the one that performed the resolution.

Repro steps:
- Open the late-start overlap queue as the owner device (Account Mode).
- Cancel all groups or confirm a selection to resolve the conflict.
- Observe: the "Owner resolved" dialog appears on the resolving device.

Symptom:
The owner device sees "This overlap was resolved on another device" — a message
intended only for mirror devices.

Observed behavior:
After the owner resolves the conflict, Firestore writes clear lateStartOwnerDeviceId
(set to null when isCancelAll is false, line 736) or the state transitions so that
ownerDeviceId is null in the next snapshot. Then:
  isOwner = !isAccountMode || ownerDeviceId == deviceId
          = false  (Account Mode, null != deviceId)
  !isOwner && allCanceled → true
→ _showOwnerResolvedDialog() fires on the owner's own device.

Expected behavior:
"Owner resolved" dialog must appear ONLY on devices that did not initiate
the resolution. The resolving device should navigate directly to Groups Hub
(or remain on a completion state) without seeing the mirror-targeted dialog.

Evidence:
- iOS re-validation log:
  docs/bugs/validation_fix_2026_03_05/logs/2026-03-16_fix25_reval_ios_iPhone17Pro_debug.log
  "Owner resolved" dialog trigger logged on iOS (owner) immediately after
  conflict resolution write completed.
- Code location: late_start_overlap_queue_screen.dart:176-189.
- Root cause confirmed by user during architectural review 2026-03-16.

Workaround:
None. Owner must dismiss a confusing dialog after completing a valid action.

Hypothesis:
isOwner is derived solely from Firestore state (ownerDeviceId == deviceId).
After the owner resolves, ownerDeviceId is cleared → isOwner evaluates false
on the resolving device, incorrectly triggering the mirror-only dialog.

Fix applied:
- First attempt (16/03/2026, commit `fd788e6`):
  - Added local state flag `_resolved` in `_LateStartOverlapQueueScreenState`.
  - Added gate `!isOwner && !_resolved` for owner-resolved mirror dialog.
- Re-validation #2 result (17/03/2026): still FAIL in `Continue` path due race.
  Firestore snapshot updates arrived before `_resolved` was set (it was updated
  after awaited persistence), so owner briefly matched `!isOwner && !_resolved`
  and showed mirror-only modal.
- Follow-up patch (17/03/2026):
  - Moved `_resolved = true` into the initial `setState` before the first await
    in `_applySelection` (pre-`repo.saveAll`), removing the race window.
  - `Cancel all` path remains correct: modal is mirror-only by design.
- File updated: `lib/presentation/screens/late_start_overlap_queue_screen.dart`.
- Local verification after follow-up patch:
  - `flutter analyze` PASS
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` PASS
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS
  - `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` PASS

Status:
Closed/OK. P1 — validated in re-validation #3 (17/03/2026, commit `95494ab`,
logs `2026-03-17_fix25_reval3_95494ab_*`). Owner (Chrome) confirmed Resolve
overlaps via "Continue" path; no "Owner resolved" modal appeared on owner.

---

## BUG-F25-D — Riverpod StateController<RunningOverlapDecision?> modified during widget build

ID: BUG-F25-D
Date: 17/03/2026 (UTC+1)
Platforms: Chrome (observed); likely all platforms
Context: Fix 25 re-validation #3. iOS (owner) pressed Resume on a paused
running group with a conflict imminent. At that moment Chrome (mirror) received
a `runningOverlap` event that tried to update `StateController<RunningOverlapDecision?>`
during the widget tree build phase.

Repro steps:
- Two devices in Account Mode with one group running/paused (owner iOS) and a
  second group scheduled that overlaps if the paused group resumes.
- Mirror device (Chrome) is on any screen that listens to the overlap provider.
- Owner presses Resume → overlap is detected → mirror tries to update
  `runningOverlapDecision` provider during widget build.

Symptom:
Chrome shows a red full-screen error overlay for <1 second:
"At least one listener of the StateNotifier Instance of
'StateController<RunningOverlapDecision?>' threw an exception when the notifier
tried to update its state.
Tried to modify a provider while the widget tree was building."
Stack trace includes:
  - `debugCanModifyProviders` in `flutter_riverpod/src/core/provider_scope.dart:333`
  - `notifyListeners` in `riverpod/src/core/element.dart:768`
The overlay disappears in <1 second and the app returns to its previous state.

Expected behavior:
Provider state updates must never be triggered synchronously during a build phase.
The overlap detection logic that writes to `runningOverlapDecision` must be
deferred (e.g., via `Future.microtask` or `WidgetsBinding.addPostFrameCallback`)
when called from a context that may be inside a build cycle.

Evidence:
- Chrome reval3 log: `docs/bugs/validation_fix_2026_03_05/logs/2026-03-17_fix25_reval3_95494ab_chrome_debug.log`
- iOS reval3 log: `docs/bugs/validation_fix_2026_03_05/logs/2026-03-17_fix25_reval3_95494ab_ios_iPhone17Pro_debug.log`
  iOS log shows `runningOverlap=true` first appearing at line 51204 immediately
  after Resume was pressed.

Fix applied:
Three-commit fix on 18/03/2026:
- `73d0f23` — coordinator: replace scheduler-phase check with `Future(() {})` in
  `_runRunningOverlapMutation`. `Future.microtask` (prior attempt) is insufficient;
  only a macrotask guarantees execution outside Riverpod's full propagation chain.
- `79c534d` — widget: move `runningOverlapDecisionProvider` clear in
  `GroupsHubScreen.build()` (line 283) and `TaskListScreen.build()` (line 561)
  to `WidgetsBinding.instance.addPostFrameCallback` with `mounted` guard and
  token guard to prevent clearing a newer decision.
- Root cause had TWO sources: coordinator mutations (fixed by macrotask deferral)
  and widget-level mutations inside `build()` (fixed by post-frame callback).

Validation:
- iOS (owner) + Chrome (mirror): Scenario A PASS — overlap modal appeared, no
  red screen on mirror at conflict detection or after Postpone action.
- Logs: `docs/bugs/validation_fix_2026_03_18-01/logs/`

Status:
Closed/OK. closed_commit_hash: 79c534d

---

## BUG-F25-E — Re-plan conflict modal does not identify the conflicting group

ID: BUG-F25-E
Date: 17/03/2026 (UTC+1)
Platforms: All (Account Mode, Re-plan flow)
Context: Fix 25 re-validation #3. After canceling a running group, user attempted
to re-plan it (Groups Hub → Re-plan group → select time). The conflict modal
appeared but gave no information about which scheduled group causes the conflict
or what its time range is.

Repro steps:
- Cancel a running group (status = canceled).
- In Groups Hub, tap "Re-plan group".
- Select a start time that overlaps an existing scheduled group.
- Confirm → modal appears: "Conflict with scheduled group / A group is already
  scheduled in that time range. Delete it to continue?"

Symptom:
The modal says "Conflict with scheduled group" without naming the group or showing
its scheduled time range. User has no context to make an informed decision.

Expected behavior:
The conflict modal must show the name and scheduled time range of every conflicting
group (e.g., "G2 — 13:21–13:36") so the user can decide whether to delete or cancel.

Evidence:
- iOS reval3 log: `docs/bugs/validation_fix_2026_03_05/logs/2026-03-17_fix25_reval3_95494ab_ios_iPhone17Pro_debug.log`
- Observed at ~13:02:32 during re-plan of G1 (canceled) that conflicted with G2 (scheduled 13:21).

Note: Phase 17 (roadmap line 440) covers the same context requirement for the
RUNNING overlap conflict modal ("Scheduling conflict" modal shown when a running
group approaches a scheduled group). This bug covers the RE-PLAN conflict modal —
a distinct flow. Both must be addressed.

Fix applied:
None yet. Pending Codex implementation.
In the re-plan conflict modal builder, pass the list of conflicting groups and
render each group's name + scheduled time range inline in the dialog content.

Status:
Open. P2 — UX clarity. Add to Phase 17 scope for implementation.

---

## BUG-F25-F — Postpone snackbar shows redundant "pre-run" info when noticeMinutes = 0

ID: BUG-F25-F
Date: 17/03/2026 (UTC+1)
Platforms: All (Account Mode, running overlap postpone)
Context: Fix 25 re-validation #3. After owner pressed "Postpone scheduled" in
the running overlap modal, a SnackBar appeared: "Scheduled start moved to 13:22
(pre-run at 13:22)." The group had noticeMinutes = 0, making "(pre-run at 13:22)"
identical to the start time and therefore meaningless.

Repro steps:
- Schedule a group with noticeMinutes = 0.
- Start a running group that will overlap it.
- In the running overlap modal, select "Postpone scheduled".
- Observe snackbar text.

Symptom:
SnackBar: "Scheduled start moved to 13:22 (pre-run at 13:22)."
When noticeMinutes = 0, pre-run time equals start time — showing both is
redundant and confusing (implies there is a pre-run window when there is none).

Expected behavior:
When noticeMinutes = 0, the snackbar should omit the pre-run clause:
"Scheduled start moved to 13:22."
When noticeMinutes > 0, show both:
"Scheduled start moved to 13:22 (pre-run at 13:21)."

Specs reference:
specs.md line 1716: "Show a confirmation SnackBar with the new start time and
the pre-run time." This rule does not address the noticeMinutes = 0 case.
A spec clarification is needed (suppress pre-run clause when noticeMinutes = 0).

Evidence:
- iOS reval3 log: `docs/bugs/validation_fix_2026_03_05/logs/2026-03-17_fix25_reval3_95494ab_ios_iPhone17Pro_debug.log`
- Snackbar text observed at ~13:06:55.

Fix applied:
timer_screen.dart `_showPostponeConfirmation`: compute `hasPreRun = preRunStart.isBefore(scheduledStart)`;
only include `(pre-run at $preRunLabel)` when `hasPreRun` is true.
commit: 68429c5

Status:
Closed/OK. 19/03/2026. closed_commit_hash: 68429c5

---

## BUG-F25-G — Groups Hub shows wrong scheduled time after postpone (ceilToMinute missing in resolver)

ID: BUG-F25-G
Date: 19/03/2026 (UTC+1)
Platforms: All (Account Mode, running overlap postpone)
Context: Identified during code review 19/03/2026. Originally observed in
validation_fix_2026_02_24/quick_pass_checklist.md at ~20:10:08 but never
formally registered. Not caused by rollback — git blame shows the write path
got ceilToMinute on 23/02/2026 but the resolver never received it.

Repro steps:
- Schedule a group with noticeMinutes = 1 (or any value).
- Start a running group that will overlap it.
- In the running overlap modal, select "Postpone scheduled".
- Note the time shown in the SnackBar (e.g. "Scheduled start moved to 20:24").
- Go to Groups Hub and observe the "Scheduled" row on the postponed group card.

Symptom:
SnackBar shows the correct rounded time (e.g. 20:24) which matches the Firestore
write. Groups Hub card shows a different time (e.g. 20:23) which is the
unrounded computation. The difference is typically ~0–59 seconds, visible as a
1-minute discrepancy at HH:mm granularity.

Root cause:
All write paths apply ceilToMinute before saving scheduledStartTime to Firestore:
  timer_screen.dart:1165 — ceilToMinute(cursor + noticeMinutes)
  scheduled_group_coordinator.dart:1146 — ceilToMinute(anchorEnd + noticeMinutes)
But the display path does not:
  scheduled_group_timing.dart:185 — anchorEnd.add(Duration(minutes: noticeMinutes))
  (missing ceilToMinute wrapper)
Groups Hub uses resolveEffectiveScheduledStart (scheduled_group_timing.dart:160)
for scheduledStartOverride (groups_hub_screen.dart:478). This produces a value
1 minute behind the stored Firestore value.

Secondary risk: when noticeMinutes=0 and anchor end falls on an exact minute,
the displayed effective start equals the running group end — violates specs rule
requiring scheduled start > projectedEnd.

Expected behavior:
Groups Hub "Scheduled" time must match the SnackBar and the stored Firestore
value at HH:mm granularity.

Fix:
In scheduled_group_timing.dart:185, wrap the return value with ceilToMinute:
  return ceilToMinute(anchorEnd.add(Duration(minutes: noticeMinutes)));
One line. No new helpers needed — ceilToMinute is already defined in the same file.

Status:
Closed/OK. closed_commit_hash: e16e389

---

## BUG-F25-H — Indefinite "Syncing session..." hold after group cancel + re-plan flow

ID: BUG-F25-H
Date: 19/03/2026 (UTC+1)
Platforms: All (Account Mode, multi-device — Chrome + iOS confirmed)
Context: Discovered during BUG-F25-G validation run (19/03/2026). Repro sequence:
G1 running → G1 canceled → re-plan → G2 starts → Chrome takes ownership of G2 →
Chrome cancels G2 → neither device navigates back to Groups Hub; both stuck in
indefinite "Syncing session..." with timer still running. Firestore activeSession/current
document no longer exists. Devices never recover without manual app restart.
Regression introduced 19/03/2026 (worked correctly in prior-day build).

Repro steps:
1. Two devices (e.g. Chrome + iOS) logged in to the same account.
2. Start group G1 in Run Mode. Both devices show timer running.
3. Cancel G1 from Chrome (menu → Cancel group → confirm).
   Expected: both devices navigate to Groups Hub. ✓
4. Immediately start G2 from the group list.
   Expected: both devices navigate to G2's timer. ✓
5. Chrome takes ownership of G2.
6. Cancel G2 from Chrome (menu → Cancel group → confirm).
   Expected: both devices navigate to Groups Hub.
   Actual (sin fix): both devices remain stuck in timer screen showing "Syncing session..."
   indefinitely with timer still counting.

Symptom:
After cancel of the second group in a G1→cancel→G2 flow, "Syncing session..."
overlay appears permanently on both devices. Timer keeps counting even though the
group is canceled and Firestore activeSession/current no longer exists. No navigation
to Groups Hub occurs. App requires manual restart to recover.

Root cause (three-component):

Component 1 — _cancelNavigationHandled permanently blocked by stale ViewModel data
(timer_screen.dart:680-682):
pomodoroViewModelProvider is NotifierProvider.autoDispose and is NOT parameterized
by group ID — it is a global singleton. When navigating from G1's timer to G2's
timer, _currentGroup in the ViewModel still holds G1's data (status=canceled) during
the first build frame of G2's TimerScreen. The build-phase cancel check at
timer_screen.dart:680 fires immediately with stale G1 data (canceled), calls
_navigateToGroupsHub('build canceled'), and throws a Flutter assertion exception
(setState()/markNeedsBuild() called during build — confirmed at Chrome log line 2238).
The navigation call fails due to the exception, but _cancelNavigationHandled is set
to true permanently beforehand. All subsequent cancel signals for G2 (stream listener
at line 512, ViewModel listener at line 541) are silently discarded via the guard.

Component 2 — _recoverFromServer() has no exit condition for terminal group
(session_sync_service.dart:_recoverFromServer):
After G2 is canceled the Firestore session document is deleted. The 3-second debounce
fires, sets holdActive=true, and _recoverFromServer() starts. On null server response
it only checks "serverSession != null" and schedules a retry every 5 seconds. It does
NOT check whether the attached group is itself in a terminal state (canceled/completed).
Since the session will never return (group is terminal), the hold never clears.
Confirmed in Chrome log: repeated "hold-extend reason=recovery-failed" every ~5s for
40+ seconds with no exit (lines 2824–2875).

Component 3 — stopTick() potentially missing in cancel acknowledgment path
(pomodoro_view_model.dart cancel handler):
If _timerService.stopTick() is not called when the group stream delivers status=canceled,
isTickingCandidate remains true. When the first session null arrives after the cancel
acknowledgment, _onSessionNull() enters the 3s debounce path instead of the quiet-clear
path. This contributes to the latch firing unnecessarily on a legitimate cancel.

Fix (three-component):

Fix 0 (pomodoro_view_model.dart — cancel acknowledgment path):
Added _timerService.stopTick() in cancel() and applyRemoteCancellation() immediately
before _resetLocalSessionState(). Ensures isTickingCandidate is false when the first
session null arrives, routing through quiet-clear path.

Fix 1 (timer_screen.dart:680-682 — stale group guard + defer out of build):
Added currentGroup?.id == widget.groupId guard and wrapped navigation in
addPostFrameCallback with !mounted check. Prevents stale G1 data from triggering
navigation during G2's first build frame and eliminates the Flutter assertion exception.

Fix 2 (session_sync_service.dart:_recoverFromServer — terminal group exit):
Added terminal-group check after serverSession == null: fetches attached group via
taskRunGroupRepositoryProvider.getById(attachedGroupId). If canceled or completed,
clears hold and returns — does not retry. Two corroborated signals (session null +
group terminal) confirm legitimate cancellation per AP-3.

Status:
Closed/OK. closed_commit_hash: ba8db6f

---

## BUG-F25-I — Postponed group start drifts to "now" after canceling the running anchor group

ID: BUG-F25-I
Date: 19/03/2026 (UTC+1)
Platforms: iOS + Chrome (Account Mode, owner + mirror confirmed)
Context: Discovered during post-F25-H validation (19/03/2026). Flow validated with
two devices and overlap resolution via "Postpone scheduled".

Repro steps (confirmed):
1. Start running group G1 on owner device.
2. Trigger scheduling conflict with G2 and choose "Postpone scheduled".
3. Verify G2 receives postponed start in the future (example observed: 22:35).
4. Cancel G1 before the postponed time is reached.
5. Observe G2 scheduled start mutates to current minute (~now + ceil), then auto-starts
   on the next minute (example observed: changed to 22:22 and started at 22:22:00).

Symptom (user-visible):
- Canceling the running group should not move postponed group's planned time.
- Instead, postponed group start is pulled forward to current time and starts almost
  immediately, violating expected scheduling behavior and surprising the user.

Expected behavior:
- A postponed group should keep its stored scheduled start after canceling the
  running anchor group.
- Canceling anchor group must break dynamic linkage for postponed groups (or freeze
  to stored schedule) so the postponed start does NOT jump to now.
- Only pause/resume drift handling should adjust anchor-follow behavior while the
  anchor is actually running.

Observed evidence (logs):
- iOS log (`docs/bugs/validation_f25i_2026_03_19/logs/2026-03-19_f25i_68429c5_ios_iPhone17Pro_9A6B6687_debug.log`):
  - line 51210: postponed sample still future (`...22:35|22:36`).
  - line 51216: running group cancel signal (`Cancel nav: group stream canceled`).
  - line 51224: postponed sample collapses to `...22:22|22:22`.
  - lines 51225/51228/51231+: start timer scheduled for 22:22:00.
  - lines 51244/51246/51253: start timer fired at 22:22:00.
- Chrome log (`docs/bugs/validation_f25i_2026_03_19/logs/2026-03-19_f25i_68429c5_chrome_debug.log`):
  - lines 2623/2632/2658: postponed sample at `...22:35|22:35/22:36`.
  - lines 2670-2686: after cancel, sample and finalized projection move to 22:22.
  - line 2687: auto-start fired at 22:22:00.

Probable root cause (pending code-level confirmation):
- `resolvePostponedAnchorEnd` in `scheduled_group_timing.dart` uses fallback to
  `anchor.updatedAt` when anchor is no longer running and no effective end can be
  resolved.
- After cancel, anchor `updatedAt` is effectively "now"; then
  `_finalizePostponedGroupsIfNeeded` in `scheduled_group_coordinator.dart` recalculates
  postponed start from that fallback and advances schedule to current minute.
- This keeps postponed group dynamically re-anchored even when anchor is canceled,
  which should not happen.

Fix direction (minimal, before broader refactor):
1. In postponed-start resolver path, treat anchor terminal states (`canceled`,
   `completed`) as linkage break for postponement timing.
2. Preserve stored postponed `scheduledStartTime` when anchor is terminal; do not
   derive from `anchor.updatedAt`.
3. Ensure `_finalizePostponedGroupsIfNeeded` only finalizes overdue if schedule is
   truly overdue by stored value, not by terminal-anchor fallback.

Targeted tests to add before closure:
- Resolver unit test: postponed group linked to anchor; anchor canceled; effective
  scheduled start remains stored postponed value (no jump to now).
- Coordinator unit/integration test: postpone then cancel anchor before postponed
  time; no auto-advance, no immediate start timer scheduling.
- Regression: pause/resume drift while anchor running still updates postponed start
  as intended.

Status:
Open. P1 — schedule correctness regression with premature auto-start side effect.

---

## BUG-F26-001 — Session cursor stale in Firestore during active run with ownership churn

ID: BUG-F26-001
Date: 17/03/2026 (UTC+1)
Platforms: Android + macOS (Account Mode)
Context: BUG-001/002 validation run (17/03/2026). Group already started before
the run began. Android RMX3771 (mirror initially, later owner via ownership
transfers); macOS (owner initially). Multiple consecutive ownership transfers
were performed over ~4 minutes.

Symptom:
Firestore `activeSession` document shows stale `phaseStartedAt` and
`remainingSeconds: 0` throughout the entire session, despite devices displaying
correct countdown timers and progressing through pomodoros normally.

Observed behavior:
- `phaseStartedAt: 7:31:07pm` (19:31:07) — unchanged throughout the entire
  session (from first screenshot at 20:04 to last at 20:08+). The field reflects
  the initial session start time and was never updated on phase transitions.
- `remainingSeconds: 0` — persisted in Firestore across all ownership transfers
  and phase boundaries. Timer countdowns visible on both devices (e.g., 18:33
  remaining) confirm the field does not reflect actual state.
- Consequence 1 — stale snapshot flash: at the second rejection (~20:07), macOS
  owner briefly showed `00:00` with a stale phase overlay. This is the stale
  Firestore snapshot (`remainingSeconds: 0`) being applied to the UI before
  TimerService re-projects the correct value.
- Consequence 2 — task shown as completed after app restart: after a device was
  restarted/re-opened, the task appeared as already completed (time=0 remaining),
  consistent with the app reading `remainingSeconds: 0` from Firestore on
  cold-start before TimerService bootstraps.
- Devices continued running via `TimerService` (Fix 26 decoupled timer), which
  correctly drove the countdown independently of the stale Firestore cursor.

Expected behavior:
On each phase transition (pomodoro→break, break→pomodoro) and on each ownership
transfer, the owner device must write the current `phaseStartedAt`, `phase`, and
`remainingSeconds` to Firestore so that:
1. Mirrors can project correctly from the snapshot.
2. Cold-starting devices can bootstrap from a valid cursor.
3. The `remainingSeconds: 0` state does not linger across phase boundaries.

Evidence:
- Validation run (17/03/2026):
  docs/bugs/validation_bug001_bug002_2026_03_17/logs/2026-03-17_bug001_bug002_android_RMX3771_debug.log
  docs/bugs/validation_bug001_bug002_2026_03_17/logs/2026-03-17_bug001_bug002_macos_debug.log
- Firestore snapshots: `phaseStartedAt: 7:31:07pm` and `remainingSeconds: 0`
  across all screenshots from 20:04 to 20:08+.
- 00:00 flash on macOS at second rejection (~20:07) — stale snapshot applied.
- Task shown as completed after app restart — `remainingSeconds: 0` used as
  cold-start cursor.

Workaround:
None. Cold-starting a device will read a stale session cursor.

Hypothesis:
In the Fix 26 architecture, `TimerService` drives the countdown independently.
The owner's write path for phase transitions may no longer update `phaseStartedAt`
and `remainingSeconds` in Firestore on each phase change — either because:
a. `PomodoroViewModel` (now a UI adapter) no longer triggers Firestore writes on
   phase transitions as it did pre-Fix-26, and `SessionSyncService` doesn't have
   a write-back path for phase transitions, OR
b. The ownership transfer path clears or resets the cursor to `remainingSeconds: 0`
   without rewriting the current phase state from `TimerService`.
Need to trace from `TimerService` phase-advance callback → owner write path in
`SessionSyncService`/`PomodoroViewModel` → Firestore update.

Fix applied:
Implemented on 17/03/2026 (branch `fix-ownership-cursor-stamp`), pending
device re-validation:
- Added `_pendingPublishAfterSync` retry path so publish writes dropped by
  `isTimeSyncReady=false` replay immediately after time sync recovers.
- Added atomic ownership approve cursor stamp by extending
  `respondToOwnershipRequest(..., cursorSnapshot:)` and passing VM snapshot
  cursor fields from `approveOwnershipRequest()`.
- Added owner hot-swap fallback publish when hydration is skipped
  (`shouldHydrate=false` and machine non-idle): bump revision + publish now.

Validation log paths (17/03/2026, commit `7ddc1e6`, Android RMX3771 + macOS):
  docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-17_ownership_cursor_7ddc1e6_android_RMX3771_debug.log
  docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-17_ownership_cursor_7ddc1e6_macos_debug.log

Status:
Closed/OK. Re-validation 18/03/2026 (Android RMX3771 + macOS, commit `92731b3`):
- `phaseStartedAt` updated correctly on phase transition: pomodoro 3→break =
  13:46:11 p.m. (exact: 3×25min from session start 12:21:11). ✓
- `remainingSeconds` coherent throughout (851→835→823→766, never 0). ✓
- No stale cursor observed after ownership transfers.
Logs: `docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-18__guard_hot-swap_92731b3_android_RMX3771_debug.log`.
Logs: `docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-18__guard_hot-swap_92731b3_android_RMX3771_debug.log`.

---

## BUG-F26-002 — Pomodoro/task counter jumps on consecutive ownership transfers

ID: BUG-F26-002
Date: 17/03/2026 (UTC+1)
Platforms: Android + macOS (Account Mode)
Context: BUG-001/002 validation run (17/03/2026). Same session as BUG-F26-001.
Consecutive ownership transfers performed in rapid succession.

Symptom:
Pomodoro counter advances (5→6, 6→7) without real phase completion on each
ownership transfer. Both devices show jumps within seconds of the handoff
without any intervening break or pomodoro completion.

Observed behavior:
- At 20:06:18 (macOS→android transfer): status boxes on both devices briefly
  flip (long break → pomodoro 5). Timer stabilizes.
- At 20:07:30 (android gets ownership again): timer on android jumps to
  18:33 remaining; pomodoro counter advances to 6 of 7.
- At 20:07:48 (macOS gets ownership): pomodoro counter advances to 7 of 7.
- Neither transfer was preceded by a completed phase (no break/pomodoro
  completion sound or transition animation observed).

Expected behavior:
Ownership transfer must not advance the pomodoro/phase counter. The new owner
should read and apply the current cursor from `TimerService` (or from the last
valid Firestore snapshot) without incrementing the phase index.

Evidence:
- Validation run (17/03/2026):
  docs/bugs/validation_bug001_bug002_2026_03_17/logs/2026-03-17_bug001_bug002_android_RMX3771_debug.log
  docs/bugs/validation_bug001_bug002_2026_03_17/logs/2026-03-17_bug001_bug002_macos_debug.log
- Timeline: pomodoro 5→6 at 20:07:30, 6→7 at 20:07:48, no phase completion
  events between transfers.

Workaround:
None. Counter advances with each ownership handoff.

Hypothesis:
Likely linked to BUG-F26-001. The stale Firestore cursor (`remainingSeconds: 0`)
may be interpreted as "phase complete" by the new owner's claim logic, causing
it to advance to the next phase and write the incremented cursor to Firestore.
Alternatively, each owner may write its own `TimerService` cursor on claim, and
if `TimerService` internal phase index is ahead of the real progression (due to
stale bootstrap from `remainingSeconds: 0`), consecutive claims increment the
stored phase.
Root cause requires tracing the ownership-claim write path to see what cursor
is committed to Firestore on each `respondToOwnershipRequest` → new owner
heartbeat cycle.

Fix applied:
Implemented together with BUG-F26-001 hardening packet on 17/03/2026 (branch
`fix-ownership-cursor-stamp`), pending device re-validation:
- Ownership transfer now carries atomic cursor snapshot at approve write.
- New owner hot-swap path now stamps live cursor immediately when hydration is
  skipped, reducing stale phase-complete interpretation windows.

Validation log paths (17/03/2026, commit `7ddc1e6`, Android RMX3771 + macOS):
  docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-17_ownership_cursor_7ddc1e6_android_RMX3771_debug.log
  docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-17_ownership_cursor_7ddc1e6_macos_debug.log

Status:
Closed/OK. Re-validation 18/03/2026 (Android RMX3771 + macOS, commit `92731b3`):
- `phaseStartedAt` updated correctly on phase transition: pomodoro 3→break =
  13:46:11 p.m. (exact: 3×25min from session start 12:21:11). ✓
- `remainingSeconds` coherent throughout (851→835→823→766, never 0). ✓
- `currentPomodoro` stable across ownership transfers (no spurious jumps). ✓
Logs: `docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-18__guard_hot-swap_92731b3_android_RMX3771_debug.log`.

---

## BUG-F26-003 — Ownership hot-swap fallback publish write loop (regression in 7ddc1e6)

ID: BUG-F26-003  
Date: 17/03/2026 (UTC+1)  
Platforms: Android RMX3771 + macOS (Account Mode)  
Context: Re-validation of ownership cursor hardening packet (`7ddc1e6`) using
newly started group (`Start now`, no pre-existing running group).

Symptom:
- `activeSession/current.sessionRevision` increased continuously in seconds
  (observed 88 → 121 between 22:27:44 and 22:27:51).
- `lastUpdatedAt` and `remainingSeconds` rewrote continuously in Firestore.
- After canceling group at 22:28:35, `activeSession/current` appeared/disappeared
  repeatedly (create/delete loop) until app closure.

Observed behavior:
- UI looked mostly correct in short run, but Firestore write rate was abnormal.
- On cancel, app marked group canceled, yet backend kept oscillating `current` doc.
- Flash samples at 22:28:36 / 22:28:38 / 22:28:39 showed `finishedAt=null` with
  active phase fields while group was already canceled in UI.

Expected behavior:
- Hot-swap fallback publish must execute once per ownership acquisition, not on
  every incoming snapshot.
- `sessionRevision` should grow monotonically with discrete ownership/phase events,
  not at near-continuous cadence.
- Cancel must settle `activeSession/current` deterministically with no recreate loop.

Root cause (confirmed in code):
- In `PomodoroViewModel._applySessionTimelineProjection`, branch:
  `else if (_machine.state.status != PomodoroStatus.idle) { _bumpSessionRevision(); _publishCurrentSession(); }`
  lacked a one-shot guard.
- Repeated snapshots while machine remained non-idle triggered repeated bump+publish,
  creating Firestore feedback loop.

Fix applied (pending device re-validation):
- Added `int _hotSwapPublishedForRevision = -1`.
- Guarded fallback publish so it runs once per ownership revision.
- Marked revision before publish and reset guard on local session reset/mode switch.
- Added regression test:
  `owner hot-swap fallback publish is one-shot for repeated snapshots`.

Evidence:
- Validation logs:
  `docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-17_ownership_cursor_7ddc1e6_android_RMX3771_debug.log`
  `docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-17_ownership_cursor_7ddc1e6_macos_debug.log`
- Validation notes in:
  `docs/bugs/validation_ownership_cursor_2026_03_17/quick_pass_checklist.md`

Status:
Closed/OK. Re-validation 18/03/2026 (Android RMX3771 + macOS, commit `92731b3`):
sessionRevision grows +1 per discrete event (5→6→7→9→10); lastUpdatedAt updates
every ~30s (heartbeat only). No high-frequency churn observed.
Logs: `docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-18__guard_hot-swap_92731b3_android_RMX3771_debug.log`.
