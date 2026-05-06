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
Superseded by Fix 26 rewrite: \_shouldTreatMissingSessionAsRunning removed;
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
Closed/OK (23/03/2026).
Primary symptoms (ownership revert, Ready fallback, rejection-banner persistence)
are resolved in current builds. The owner-side optimistic clear path implemented
in `rejectOwnershipRequest()` remains stable in re-validation evidence, and the
residual brief banner re-show noted on 21/03/2026 was transient, self-correcting,
and not user-impacting.

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

Re-validation update (21/03/2026, user-run evidence):

- User repeated pause/background + reject/accept ownership cycles on Android
  and Chrome; owner-side rejection banner cleared immediately on reject.
- Residual symptom ("banner persistence on owner", second reject press) was not
  reproduced in this run.
- Shared evidence in thread includes Android + Chrome diagnostic excerpts for
  group `15e6300b-0ab9-47a4-a5f8-7e220a7c31c3`, with stable Run Mode continuity
  and no stuck rejection banner after repeated retries.
- Monitor-only note (same run, ~13:37:11): Chrome owner banner appeared to
  re-show for ~1 second after reject, then cleared without user intervention.
  Related logs show short-lived out-of-order `activeSession` snapshots
  (`ownerDeviceId` / `lastUpdatedAt` oscillation between web and android values)
  that self-corrected on the next snapshots.
- Decision: no patch now (to avoid masking a potential underlying sync-order
  issue). Keep traceability and monitor; reopen only if the symptom becomes
  persistent or user-impacting.
- Final closure decision (23/03/2026): close monitor item as non-repro after
  explicit validation confirmation. Reopen only if recurrence becomes
  deterministic/user-impacting.

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
Closed/OK (24/03/2026). Both root causes eliminated by Fix 26 architecture:
(1) AP-1 elimination — no more periodic `_sessionSub` cancel/restart in `build()`;
SSS persistent subscription removes the resubscribe cycle that caused ~15s rebuilds.
(2) Timer drift variant (macOS alternating between correct and stale timer) covered
by BUG-009 non-repro re-validation 21/03/2026. No recurrence observed in
BUG-005/006/007 device runs 24/03/2026 where macOS acted as mirror for multiple
minutes. User confirmed: "apenas se percibe en la UI ahora."

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
  was applied on 18/02/2026 (`0d2f7a4`: `Revert mirror timer suppression due to ownership freeze`).

Status:
Closed/OK.
Re-validated by owner on 21/03/2026: multiple manual runs across different
flows did not reproduce the per-second swap behavior again.
Implementation closure reference remains rollback commit `0d2f7a4`.

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
  project from lastUpdatedAt-derived server time (commit `25878cc`:
  `Stabilize ownership sync and server-time projection`).
- Added Run Mode keep-alive while active sessions exist to prevent offset reset
  on navigation (same fix packet `25878cc`).

Status:
Closed/OK.
Owner re-validation confirmation (21/03/2026): long multi-device soak runs
(`>10h` Android + macOS simultaneously) did not reproduce drift growth or
navigation-related timer jumps again.

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
Fix 26 (`cbd800a`): `appModeProvider` listener calls `_timerService.stopTick()` +
state clear on mode switch away from Account Mode, eliminating the stale local
projection that caused the ~25s mismatch. On return to Account Mode, ViewModel
is in a clean state and re-anchors immediately from the first SSS snapshot via
`loadGroup()` → `_subscribeToRemoteSession`.

Status:
Closed/OK (24/03/2026). Root cause eliminated by Fix 26 mode-switch cleanup.
User-confirmed: tested on device, bug no longer manifests.

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

- Stabilized owner hydration after pause re-entry in
  `PomodoroViewModel` by pinning phase-start from session snapshots and avoiding
  Account Mode timeline overrides that could reintroduce stale anchors
  (`abb053d`: `fix: stabilize owner hydration after pause re-entry`).

Status:
Closed/OK.
Owner re-validation confirmation (21/03/2026): no trace of the bug in current
builds; pause/resume + background/foreground no longer shows the previous offset
drift symptom.

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

- Covered by Fix 26 sync architecture rewrite (`P0-F26-006`): runtime timer
  continuity decoupled from stream nulls via app-scope `TimerService` +
  `SessionSyncService` recovery authority, including terminal-boundary hold
  suppression and lifecycle hardening (`cbd800a`:
  `fix(f26): suppress terminal-boundary hold and harden ref-after-dispose in recovery paths`).

Status:
Closed/OK.
Validated under Fix 26 closure packet and subsequent owner confirmation
(21/03/2026): mirror no longer remains stuck in `Syncing session...` waiting
for user interaction.

---

## BUG-009 — Late-start queue desync + ownership gaps in Account Mode

ID: BUG-009  
Date: 20/02/2026 (UTC+1), revalidated 23/03/2026 (UTC+1)  
Platforms: macOS + iOS simulator + web Chrome (Account Mode)  
Context: Late-open with consecutive planned groups and pre-run notice.

Symptom:

- Resolve-overlaps queue applies only a partial chain in some sequences.
- Third (or later) conflicting groups can remain outside the queue and conflict
  later during runtime.
- Queue confirmation does not reopen queue flow when new overlaps still exist
  after the selected queue is projected.

Repro (23/03/2026):

- Plan 3 groups, all with 15m duration and 1m pre-run:
  - G1 scheduled 08:51
  - G2 scheduled 09:07
  - G3 scheduled 09:23
- Open late in Account Mode while G1 must start immediately.
- Resolve-overlaps queue includes G1/G2 but leaves G3 outside queue.
- G1 starts and G2 is postponed to 09:14-09:29, but G3 remains 09:23-09:38.
- At 09:14 runtime overlap modal appears for G3, proving unresolved overlap.

Observed behavior:

- Runtime queueing resolved first two groups but not the full chain.
- G3 was not assigned `lateStartQueueId`/`lateStartQueueOrder` while G1/G2 were.
- Conflict reappeared later as `Scheduling conflict` modal in Run Mode.

Expected behavior:

- Queue formation must cascade until no overlaps remain in the projected chain.
- After queue confirmation, overlaps against scheduled groups outside selection
  must be revalidated and queue flow reopened if any conflict remains.
- A single queue flow should resolve all currently implied conflicts, avoiding
  a second runtime conflict modal for the same chain.

Evidence:

- Validation logs (23/03/2026):
  - `docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_76ee374_ios_simulator_iphone_17_pro_debug.log`
  - `docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_76ee374_web_chrome_debug.log`
- Firestore snapshots captured in validation notes show:
  - G1: `lateStartQueueOrder=0`
  - G2: `lateStartQueueOrder=1`
  - G3: `lateStartQueueId=null` (not included)
- Runtime modal at 09:14 confirms unresolved G2↔G3 overlap.

Hypothesis:

- Layer 1: `resolveLateStartConflictSet` does not cascade conflict formation
  when only one group is overdue initially.
- Layer 2: post-confirm revalidation against scheduled groups outside current
  selection is missing or incomplete (spec section 10.4.1.b).

Fix applied:
Implemented on branch `fix-bug009b-cascade-completion-overlap`:

- cascading conflict-set formation in `resolveLateStartConflictSet`,
- post-confirm overlap revalidation + queue reopen in late-start queue apply flow.
- anchored-chain timing helper applied across queue/finalize/postpone paths to
  keep pre-run strictly after previous group end when `noticeMinutes > 0`.
- Local gates PASS:
  - `flutter analyze`
  - `flutter test test/presentation/utils/scheduled_group_timing_test.dart`
  - `flutter test test/presentation/timer_screen_completion_navigation_test.dart`
  - `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
- Device validation update (`fix_v2`, 23/03/2026):
  - iOS log shows one queue opening with all 3 groups:
    `LateStartQueue overdue=3` + `Opening late-start overlap queue`.
  - No second runtime queue (`overdue=2`) appears after G1 completion.
  - G2 pre-run/start fired normally (`14:03`/`14:04`) without re-queue chain.
- User rerun update (23/03/2026 15:07, iOS owner):
  - core re-queue remains fixed,
  - but Groups Hub still showed `G3 pre-run` in the same minute as `G2 end`.
  - follow-up timing patch added; `fix_v4` device rerun pending.

Status:
Closed/OK (23/03/2026).
fix_v4 device rerun PASS:

- iOS + web logs show single late-start queue chain (`LateStartQueue overdue=3`)
  with no runtime re-queue (`overdue=2` absent).
- Timing coherence follow-up PASS: chained scheduling no longer reproduces the
  problematic same-minute pre-run/end overlap in user rerun.
  Closed under implementation commit `2fdd99b`
  (`fix(late-start, timer): BUGLOG-009B re-queue + BUG-013 modal + BUG-014 postpone`).

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
Closed/OK (23/03/2026).
Android validation PASS (`validation_bug008_2026_03_23`):

- `LateStartQueue overdue=3` emitted on late open and queue opened immediately.
- After confirmation, scheduler moved to `scheduled=2 overdue=0` and opened the
  running timer cleanly (`running-open-timer`), confirming no overdue bypass.
- Manual `Start now` on the following queued group was blocked by
  `Conflict with running group` (no bypass path).
- No `Tasks group completed` empty-summary symptom observed in this run.
  Validation log:
  `docs/bugs/validation_bug008_2026_03_23/logs/2026-03-23_bug008a_4ef7f42_android_RMX3771_debug.log`

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
Closed/OK (24/03/2026). Superseded by Fix 26 SSS architecture — persistent session
subscription (AP-1 eliminated) + `_startInactiveResync()` + `handleAppResumed()`
re-anchor eliminate the sync failure scenarios that motivated this fallback.
No implementation needed. User-confirmed 24/03/2026.

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
Commit `9916204` ("Allow owner heartbeats while awaiting session", 02/03/2026):
allowed session publish and heartbeats when owner is active but activeSession is
temporarily missing — prevents `lastUpdatedAt` freeze that caused stale ownership
auto-claim by mirror.
Architecture-level resolution: Fix 26 sync rewrite (P0-F26-006, `cbd800a`) decoupled
owner heartbeat from the session stream entirely via `SessionSyncService`.

Status:
Closed/OK (user-confirmed, 24/03/2026).
Evidence: `docs/bugs/validation_fix_2026_03_02-02/quick_pass_checklist.md` (all PASS,
02/03/2026, Chrome+macOS: `lastUpdatedAt` advancing confirmed);
P0-F26-006 Stage C pass2 soak (5h+, Android RMX3771 + macOS, 2026-03-16, no
unauthorized ownership flips observed).
closed_commit_hash: `9916204`

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

- Variant A (`b093270`): `_startInactiveResync()` in `pomodoro_view_model.dart:2863` — periodic
  15s `syncWithRemoteSession(preferServer: true, reason: 'inactive-resync')` triggered by
  `AppLifecycleState.inactive` (including macOS window focus loss) via `handleAppPaused()`.
- Variant B (`cbd800a`): Fix 26 architecture rewrite — `SessionSyncService` maintains persistent
  Firestore stream subscription independent of ViewModel lifecycle. AP-1 eliminated; stream
  delivers `ownershipRequest` changes in real-time without navigation or resubscribe.

Status:
Closed/OK. Validated 24/03/2026 — both scenarios PASS.
Escenario A: macOS log line 5850 `[ActiveSession] Resync start (inactive-resync).` at 11:43:54
(~4s after focus loss); modal appeared instantly on macOS. Escenario B: Android stream delivered
ownership request at ~11:49:28.5 (`[RunModeDiag] Active session change`, no inactive-resync);
user accepted modal at ~11:49:30.8 (~3s, <5s threshold).
Evidence: `docs/bugs/validation_bug005_2026_03_24/`.

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
Commit `34d1938` ("Fix 5: align status box ranges", 25/02/2026):
`currentPhaseStartFromGroup` / `currentPhaseEndFromGroup` in
`pomodoro_view_model.dart` apply `_pauseSecondsSincePhaseStart` to attribute
only the pause accumulated after the estimated start of the current phase,
extending the end time forward without retroactively shifting the start.
Used by `timer_screen.dart` lines 2689–2690.

Status:
Closed/OK (24/03/2026).
Evidence: Android debug run — pause at 11:02:01 (remaining=861, log line 6983),
resume at 11:03:04 (log line 7029): status box showed 11:01-11:16 → 11:01-11:17
(start fixed, end extended ~1min by pause duration). Status box and task list agree.
Log: `docs/bugs/validation_bug006_bug007_2026_03_24/logs/2026-03-24_bug006_bug007_97f6365_android_RMX3771_debug.log`
closed_commit_hash: `34d1938`

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
`handleAppResumed()` in `pomodoro_view_model.dart` (line 2871): in Account Mode
calls `_subscribeToRemoteSession(reason: 'resume-rebind')` + `syncWithRemoteSession
(preferServer: true, reason: 'resume')` + `_schedulePostResumeResync()` (2s delay).
Owner re-anchors from server snapshot immediately on foreground return.

Status:
Closed/OK (24/03/2026).
Evidence: Android background at 11:09:00 (2min), foreground at 11:11:02 — Android
showed 6:21, macOS mirror showed 6:20 (±1s). Log confirms full resume sequence:
`[SessionSub] close reason=resume-rebind` (line 10400),
`[SessionSub] open (→SSS) reason=resume-rebind` (line 10401),
`[ActiveSession] Resync start (resume).` (line 10402),
`[ActiveSession] Resync start (post-resume).` (line 10414).
No `Resync missing` after resume.
Log: `docs/bugs/validation_bug006_bug007_2026_03_24/logs/2026-03-24_bug006_bug007_97f6365_android_RMX3771_debug.log`
closed_commit_hash: `handleAppResumed` (in develop via Fix 26 rewrite)

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
  Iteration 2: tx.get(group[1]) → FAILS (\_commands.isEmpty: write already issued)
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

## BUG-F25-B — context-after-dispose in \_showOwnerResolvedDialog OK button

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

- \_showOwnerResolvedDialog (late_start_overlap_queue_screen.dart:549) shows
  an AlertDialog whose OK button captures the outer BuildContext:
  onPressed: () =>
  Navigator.of(context, rootNavigator: true).pop() // line 563-564
- If \_LateStartOverlapQueueScreenState is disposed before OK is tapped,
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
= false (Account Mode, null != deviceId)
!isOwner && allCanceled → true
→ \_showOwnerResolvedDialog() fires on the owner's own device.

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
groups_hub_screen.dart `_resolveScheduledConflict` (line 1396) and
task_list_screen.dart `_resolveScheduledConflict` (line 1850): replaced
static generic dialog content with a dynamic Column listing each conflicting
group as "• {name} — {start}–{end}" (HH:mm today, MMM d, HH:mm otherwise).
Group name derived from tasks.first.name ?? 'Task group'. Validated on Chrome.
Note: bug_log entry was stale (merge artifact from fix-f25-h branch); fix was
already applied and roadmap line 459 confirms Closed/OK.

Status:
Closed/OK (19/03/2026). closed_commit_hash: c248c91

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

Component 1 — \_cancelNavigationHandled permanently blocked by stale ViewModel data
(timer_screen.dart:680-682):
pomodoroViewModelProvider is NotifierProvider.autoDispose and is NOT parameterized
by group ID — it is a global singleton. When navigating from G1's timer to G2's
timer, \_currentGroup in the ViewModel still holds G1's data (status=canceled) during
the first build frame of G2's TimerScreen. The build-phase cancel check at
timer_screen.dart:680 fires immediately with stale G1 data (canceled), calls
\_navigateToGroupsHub('build canceled'), and throws a Flutter assertion exception
(setState()/markNeedsBuild() called during build — confirmed at Chrome log line 2238).
The navigation call fails due to the exception, but \_cancelNavigationHandled is set
to true permanently beforehand. All subsequent cancel signals for G2 (stream listener
at line 512, ViewModel listener at line 541) are silently discarded via the guard.

Component 2 — \_recoverFromServer() has no exit condition for terminal group
(session_sync_service.dart:\_recoverFromServer):
After G2 is canceled the Firestore session document is deleted. The 3-second debounce
fires, sets holdActive=true, and \_recoverFromServer() starts. On null server response
it only checks "serverSession != null" and schedules a retry every 5 seconds. It does
NOT check whether the attached group is itself in a terminal state (canceled/completed).
Since the session will never return (group is terminal), the hold never clears.
Confirmed in Chrome log: repeated "hold-extend reason=recovery-failed" every ~5s for
40+ seconds with no exit (lines 2824–2875).

Component 3 — stopTick() potentially missing in cancel acknowledgment path
(pomodoro_view_model.dart cancel handler):
If \_timerService.stopTick() is not called when the group stream delivers status=canceled,
isTickingCandidate remains true. When the first session null arrives after the cancel
acknowledgment, \_onSessionNull() enters the 3s debounce path instead of the quiet-clear
path. This contributes to the latch firing unnecessarily on a legitimate cancel.

Fix (three-component):

Fix 0 (pomodoro_view_model.dart — cancel acknowledgment path):
Added \_timerService.stopTick() in cancel() and applyRemoteCancellation() immediately
before \_resetLocalSessionState(). Ensures isTickingCandidate is false when the first
session null arrives, routing through quiet-clear path.

Fix 1 (timer_screen.dart:680-682 — stale group guard + defer out of build):
Added currentGroup?.id == widget.groupId guard and wrapped navigation in
addPostFrameCallback with !mounted check. Prevents stale G1 data from triggering
navigation during G2's first build frame and eliminates the Flutter assertion exception.

Fix 2 (session_sync_service.dart:\_recoverFromServer — terminal group exit):
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

Fix applied:
Two-commit fix on branch fix-f25-i-postponed-start-drifts-on-cancel:

1. scheduled_group_coordinator.dart `_finalizePostponedGroupsIfNeeded` (commit 51dcd2d):
   when anchor.status == canceled, sever link (postponedAfterGroupId=null) without
   touching scheduledStartTime. Mirrors the "anchor not found" pattern.
2. scheduled_group_timing.dart `resolvePostponedAnchorEnd` (commit 6c87009):
   return null for canceled anchors so resolveEffectiveScheduledStart returns stored
   scheduledStart. Prevents cascade in chained postpone scenarios (G3 linked to G2).

Status:
Closed/OK. 19/03/2026. closed_commit_hash: 6c87009

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

---

## BUG-013 — Completion modal remains over next group auto-open

ID: BUG-013
Date: 23/03/2026 (UTC+1)
Platforms: iOS simulator + web Chrome (Account Mode)
Context: Consecutive planned groups in Run Mode with pre-run enabled.

Repro steps:

- Execute consecutive planned groups (e.g., G1 -> G2 -> G3, 1m pre-run).
- Let G1 complete and keep `Tasks group completed` modal open.
- Wait for G2 pre-run/start.

Symptom:
Completion modal from previous group remains visible and blocks the next
group pre-run/run view until user presses `OK`.

Observed behavior:

- Next group starts in background, but completion modal overlays timer UI.
- On iOS, pre-run/start of the next group is hidden until manual dismissal.
- Same pattern repeats when G2 completes and G3 pre-run starts.

Expected behavior:

- If a next group auto-opens (pre-run or running), completion modal from the
  previous group must auto-dismiss immediately and not force manual `OK`.

Evidence:

- Validation logs:
  - `docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_76ee374_ios_simulator_iphone_17_pro_debug.log`
  - `docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_76ee374_web_chrome_debug.log`
- Screenshots captured in the same validation packet show completion modal
  over active next-group timer/pre-run.

Hypothesis:

- Completion modal dismissal path was still tied to group switch/running-state
  transitions.
- Pre-run announcements for a different next group (`scheduledAutoStartGroupId`
  changed to `next != widget.groupId`) did not dismiss the modal.
- Additionally, the scheduled-action bridge deferred all actions while
  `completionDialogVisibleProvider` was true, including `openTimer`; this
  blocked pre-run auto-open execution until the next start transition.

Fix applied:
Implemented on branch `fix-bug009b-cascade-completion-overlap`:

- Initial implementation covered group switch + active-state transitions.
- Follow-up patch added explicit pre-run dismissal when next-group auto-open is
  announced for a different group id.
- Additional follow-up patch in `ScheduledGroupAutoStarter` allows
  `ScheduledGroupActionType.openTimer` even when completion modal is visible,
  so pre-run auto-open is not deferred.
- Local gates PASS:
  - `flutter analyze`
  - `flutter test test/presentation/timer_screen_completion_navigation_test.dart`
  - Includes dedicated regression:
    `auto-dismisses completion modal when next group pre-run auto-open is announced`

Validation update (`fix_v2`, 23/03/2026):

- iOS log confirms partial fix:
  - pre-run started at `14:03` (`prealert-timer-fired` for G2),
  - modal auto-dismiss happened at `14:04` (`Auto-dismiss ... group switch`).
- User rerun at `15:07` still reproduced the same pattern (no dismiss at pre-run).
- Current packet adds the missing scheduled-action bridge fix; device rerun is pending.

Validation update (`fix_v4`, 23/03/2026):

- PASS on rerun:
  - iOS pre-run fires for G2 at `17:00:00` (`prealert-timer-fired`).
  - completion modal auto-dismiss is logged at `17:00:00`
    (`Auto-dismiss completion dialog: group switch`), before G2 start timer at
    `17:01:00`.
- User confirmation on rerun: modal dismissal during next-group pre-run works
  on owner/mirror flow.

Status:
Closed/OK (23/03/2026) under implementation commit `2fdd99b`
(`fix(late-start, timer): BUGLOG-009B re-queue + BUG-013 modal + BUG-014 postpone`).

---

## BUG-014 — Postpone scheduled requires double press in overlap modal

ID: BUG-014
Date: 23/03/2026 (UTC+1)
Platforms: web Chrome (Account Mode)
Context: Running overlap modal with action `Postpone scheduled`.

Repro steps:

- Trigger runtime overlap modal (`Scheduling conflict`).
- Press `Postpone scheduled`.

Symptom:
Modal may persist/reappear after first postpone action; user must press
`Postpone scheduled` a second time for final dismissal.

Observed behavior:

- SnackBar confirms postpone after first click:
  `Scheduled start moved to 09:31 (pre-run at 09:30).`
- Conflict modal remains visible (or reopens) immediately after the first click.
- Second click applies same action and finally dismisses modal.

Expected behavior:

- Single postpone action should both apply scheduling update and close modal
  deterministically (no re-open race).

Evidence:

- Validation logs:
  - `docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_76ee374_web_chrome_debug.log`
  - `docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_76ee374_ios_simulator_iphone_17_pro_debug.log`
- Timestamped user validation notes: first postpone at 09:14:43 showed success
  SnackBar while modal remained; second postpone at 09:14:52 closed it.

Hypothesis:

- Race between modal dismissal and running-overlap re-evaluation from stream
  snapshots before postponed `scheduledStartTime` is confirmed.

Fix applied:
Implemented on branch `fix-bug009b-cascade-completion-overlap`:

- deterministic postpone guard using decision key + expected scheduled start
  confirmed by repository snapshots (no time-based suppression).
- Local gates PASS:
  - `flutter analyze`
  - `flutter test test/presentation/timer_screen_completion_navigation_test.dart`
  - Includes dedicated regression:
    `suppresses immediate duplicate running-overlap modal after postpone`

Status:
Closed/OK (23/03/2026).
fix_v4 rerun/user validation confirms one-tap postpone behavior with no repeated
conflict modal in the validated flow; no `Scheduling conflict` signatures were
observed in `fix_v4` logs after overlap confirmation.
Closed under implementation commit `2fdd99b`
(`fix(late-start, timer): BUGLOG-009B re-queue + BUG-013 modal + BUG-014 postpone`).

---

## BUG-008C — Android opens stale group in Ready/Completed at startup

ID: BUG-008C
Date: 23/03/2026 (UTC+1)
Platforms: Android owner (Account Mode)
Context: Startup after previous scheduled/late-start validation flows.

Repro steps:
Scenario A (primary, stale running residue):

1. Run a late-open flow with queued groups on Android owner.
2. Leave the app and reopen after a gap while a previous group/session may still
   exist in remote state.
3. Observe first timer screen shown on startup.

Scenario B (alternative, explicit cancellation path):

1. Run late-open queue flow (3 groups) and confirm overlaps.
2. Cancel running and queued groups explicitly.
3. Close app, reopen Android owner, and observe first timer screen.

Symptom:
On app open, Android can show an old group as `Ready/Completed` with `15:00`
and `Start`, even though this group belongs to a prior run/cancel context and
should not be restored as an active startup target.

Observed behavior:

- In `BUG008B` startup log, same group id is loaded first as completed:
  `Timer load group=... result=... status=completed` (line 6763),
  then remote active session snapshots arrive as running for that same group
  seconds later (`ActiveSession][snapshot ... status=pomodoroRunning`,
  lines 6794/6819).
- User observed the ready/start flash at startup, pressed Start to inspect,
  then canceled and created a new group for the actual validation run.
- Firestore state later captured for this group includes:
  `status=canceled`, `canceledReason=user`, `actualStartTime=2026-03-23T19:41:16`,
  indicating startup restoration and subsequent manual cancel happened in the
  same time window.

Expected behavior:

- On startup, app must not restore a stale/canceled/completed group as a
  `Ready` run target.
- If a stale active session exists, startup should deterministically reconcile
  to valid running state or clear stale state before exposing run controls.
- No transient `Ready 15:00 Start` flash should appear for historical groups.

Evidence:

- Android log:
  `docs/bugs/validation_bug008_2026_03_23/logs/2026-03-23_bug008b_d400a99_android_RMX3771_debug.log`
  (notable lines: 6763, 6794, 6819).
- Prior related chain where this group was created/queued:
  `docs/bugs/validation_bug008_2026_03_23/logs/2026-03-23_bug008a_4ef7f42_android_RMX3771_debug.log`
  (group id `f58d0434-173e-4a7d-b508-de8e949fffa9` appears in queue set).
- Firestore snapshot provided during analysis:
  group id `f58d0434-173e-4a7d-b508-de8e949fffa9`,
  `status=canceled`, `canceledReason=user`, `updatedAt=2026-03-23T19:41:25`.

Workaround:
Manual cancel and restart of a new group (temporary only).

Hypothesis:
Startup hydration race/inconsistency between local group load and remote
`activeSession` snapshot application:

- startup path can load stale terminal group state (`completed`) before remote
  running snapshot settles;
- auto-open/openTimer actions still target that group id during the transient.
  Alternative path to validate:
- cancellation-cleanup may leave stale targeting metadata for the last queued
  group, causing the same startup restore artifact even after explicit cancel.

Fix applied:
Implemented on branch `fix/buglog-008c-ready-flash-validation`:

- `ScheduledGroupCoordinator` now expires running groups even when
  `activeSession == null` if `theoreticalEndTime` is already passed.
- When all running groups in that startup check are expired/completed, it emits
  a dedicated action to open `Groups Hub` (instead of opening `Timer` in stale
  ready/completed state).
- `ScheduledGroupAutoStarter` now handles `openGroupsHub` coordinator action.
- Regression test added:
  `completes expired running group without active session and routes to Groups Hub`
  in `scheduled_group_coordinator_test.dart`.
- Local verification PASS:
  - `flutter analyze`
  - `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart`

Status:
Closed/OK.
closed_commit_hash: pending (fix/buglog-008c-ready-flash-validation, pre-merge)
closed_date: 23/03/2026
Evidence:

- Android debug log: `docs/bugs/validation_bug008c_2026_03_23/logs/2026-03-23_bug008c_d400a99_android_RMX3771_debug.log`
- Scenario A PASS: stale running group on reopen → coordinator marks completed,
  routes to Groups Hub. No persistent "Ready 15:00 + Start" observed.
- Key log signals: `[ExpiryCheck][expire-running-groups]` (line 6747),
  `[ExpiryCheck][mark-running-group-completed]` (line 6751),
  `Active session cleared route=/groups` (line 6764).
- Screenshot sequence confirmed by user (6 frames: tasks open → running banner →
  tasks loaded → timer loading flash → Groups Hub with completed group).
- Residual observation (not a bug, noted for reference): brief timer-screen flash
  (frame 5) before Groups Hub when activeSession arrives before expiry check
  completes; app lands correctly on Groups Hub.
- Residual observation (not a bug, noted for reference): `Cannot use Ref after disposed`
  exception in log lines 6775–6787 during the same navigation transition;
  no functional breakage. Context documented in dev_log Block 657.

---

## BUG-015 — Running group falls into invalid Ready/finished mismatch after background

ID: BUG-015
Date: 25/03/2026 (UTC+1)
Platforms: Android + macOS (Account Mode)
Context: Cross-device running group; owner device powered off; remaining device later goes background and resumes.

Repro summary:

- Group remains in `running` lifecycle with future theoretical end.
- Owner device (macOS) is fully powered off.
- Remaining device (Android) later goes background and resumes.

Symptom:

- Run Mode can reopen in invalid terminal UI (`Ready`, amber/golden full ring,
  `Start` button) while the same group should still be in-progress by timeline.

Observed behavior:

- During the inconsistent window, session data can appear terminal (`finished`)
  while group lifecycle/context still indicates the run should continue.
- Reopening another device can republish/reconcile and return the first device
  to the correct running timeline.

Expected behavior:

- Group continuity must not depend on any device being in foreground.
- If no device is open, progression remains timeline-authoritative and resumes
  correctly on next foreground without passing through `Ready` for non-terminal groups.
- While a group is non-terminal, terminal UI (`Ready` + `Start` + amber
  complete ring) must never be rendered.
- If the group has not truly ended, `activeSession/current.status` must not be
  written as `finished` in Firestore.

Evidence:

- User-reported Android logs before owner power-off show active snapshots and
  normal progression.
- User-reported Firestore state showed temporary inconsistency (`current` with
  terminal status while group context should still progress), then recovery after
  macOS reopened and republished active timeline.

Workaround:

- Reopen a second device/session so active snapshot is republished and mirror
  re-anchors.

Hypothesis:

- Transitional/non-active session snapshots can be accepted as render authority
  during/after background resume without strict non-terminal group corroboration,
  causing temporary terminal UI fallback (`Ready`) for an active group.

Fix applied:
Implemented in ViewModel stream-ingestion path:

- Repair inconsistent active-session cursor synchronously before ingest on
  stream updates (`_repairStreamSessionForCurrentGroup` →
  `_repairInconsistentSessionCursor`) so mirror projection never captures
  invalid snapshots (`currentPomodoro > totalPomodoros`, stale task index).
- Keep owner-hydration and owner-publish guards from BUG-015 patch set:
  prevent transient non-terminal `finished` publication during resync/task
  boundary windows.

Validation update (25/03/2026):

- Exact repro PASS on Android + macOS (owner handoff + background + late resume).
- Android resumed directly in active timer state (no amber `Ready 00:00` flip).
- Firestore stayed non-terminal (`status: pomodoroRunning`) during resumed run.
- Evidence log:
  `docs/bugs/validation_bug015_2026_03_25/logs/2026-03-25_bug015_f929117_android_RMX3771_debug_2.log`

Status:
Closed/OK (25/03/2026). Validated on branch
`fix/buglog-running-without-foreground-ready-invalid`.
Closed commit: `e10a5028` (`fix(bug-015): repair stream cursor ingest and close validation`).

---

## BUG-016 — Task weight (%) redistribution produces wrong result due to reactive baseline on per-keystroke update

ID: BUG-016
Date: 25/03/2026 (UTC+1)
Platforms: All (Android, macOS, iOS — UI logic, platform-independent)
Context: Task Editor — Task weight (%) field, group planning mode.

Repro summary:

- Open Task Editor for a task that is selected in a group (Task weight % field visible).
- Task has 5 pomodoros (~53% of group total).
- Type "80" in the weight field.
- Observe: task ends up with 1 pomodoro (~19%) instead of the expected ~7 pomodoros (~78%).

Symptom:

- Editing Task weight (%) produces a result that is dramatically worse than the
  starting value and far from the requested percentage.
- The more the requested value differs from the current, the worse the result can be.
- The notice "Closest possible is X%" may not fire correctly because the algorithm
  produces a non-optimal intermediate result, not a genuine constraint limit.

Root cause:
`redistributeWeightPercent` (task_editor_view_model.dart:240) is called inside
the `onChanged` handler of the weight field (task_editor_screen.dart:2077).
`onChanged` fires per character — each keystroke triggers a full redistribution.

The baseline passed to the algorithm (`weightScopeTasks`) is built in `build()`
via `_selectedTasksForWeight` (task_editor_screen.dart:1220), which injects the
current provider state of the edited task (`edited: selectedTask`).
Each keystroke calls `_update(task.copyWith(totalPomodoros: newPomodoros))` at
line 2106, which updates `taskEditorProvider`. On the next keystroke, the widget
has rebuilt and `weightScopeTasks` now contains the task with the intermediate
pomodoro count — not the original.

Concrete trace (5 tasks x 25 min, A=5 pom, B=C=D=E=1 pom):

1. User types "8" → target=8%, totalWork=225, desiredWork=18,
   bounded=25 (floor), editedPom=1.
   Provider updated: A → 1 pom. Widget rebuilds.
2. User types "80" → weightScopeTasks now has A=1 pom.
   totalWork=125, desiredWork=100, minOthersWork=100, maxEditedWork=25,
   bounded=clamp(100,25,25)=25, editedPom=1.
   Final result: 1 pomodoro (19%) instead of ~7 (78%).

The algorithm in `task_editor_view_model.dart` is individually correct.
The bug is in how the screen calls it: there is no stable baseline snapshot
frozen at the moment the user begins editing the weight field.

Expected behavior (per specs section 10.3.x):

- Editing Task weight (%) adjusts the task's totalPomodoros to the closest
  achievable result for the requested percentage.
- The result must be coherent: if the starting value (53%) is already closer
  to the target (80%) than the result (19%), the algorithm is wrong.
- If no better allocation is achievable, the notice "Closest possible is X%"
  must fire — not silently apply a worse result.

Product decision (approved 27/03/2026):
The UX direction is now explicitly defined: **preview-first editing with two modes**.

- Mode 1 — **Fixed total** (default): preserve selected-group total work and
  redistribute other selected tasks proportionally.
- Mode 2 — **Flexible total**: keep other selected tasks unchanged and allow
  selected-group total work to change to improve approximation.
- This same preview logic must apply when editing **Task weight (%)** and when
  editing **Total pomodoros**.
- The flow must support explicit **Apply** and **Cancel** (cancel = no changes).

Fix direction (approved):

1. **Correctness patch — Patch 1 (independent, ready for Codex):**
   freeze baseline `weightScopeTasks` when weight editing starts and keep that
   snapshot stable for the entire interaction to eliminate per-keystroke
   baseline corruption. Fix blur-time overwrite by using the actual redistribution
   result instead of recomputing from mixed provider state.
   - Only file modified: `lib/presentation/screens/task_editor_screen.dart`.
   - No UI structure changes, no new widgets, no mode selector.
   - Handoff written: `docs/bugs/validation_bug016_2026_03_27/codex_handoff.md`.
   - Can be implemented and validated in device BEFORE any UX decision is made.

2. **UX complement — Patch 2 (UX decisions closed 28/03/2026 — implementation ready):**
   replace blind per-keystroke updates with a preview sheet: live preview inside sheet,
   segmented control Fixed/Flexible, three-tier results display, Apply/Cancel footer.
   Fields in editor become read-only tap targets.

Files involved (Patch 1):

- `lib/presentation/screens/task_editor_screen.dart` — baseline freeze, blur fix.

Files involved (Patch 2):

- `lib/presentation/screens/task_editor_screen.dart` — fields converted to tap targets,
  sheet integration, apply/cancel flow, per-keystroke handlers removed.
- `lib/presentation/viewmodels/task_editor_view_model.dart` — mode-aware helpers
  (fixed/flexible), new `redistributeTotalPomodoros` method.
- `test/presentation/viewmodels/task_editor_view_model_test.dart` — mode-specific
  cases and baseline-stability regression coverage.
- `test/domain/task_weighting_test.dart` — rounding/constraints coverage.

UX decisions locked (28/03/2026) — Patch 2 unblocked:

a. **Mode selector widget:** Segmented control with two mutually-exclusive options
(Fixed total | Flexible total), placed inside the preview sheet above the
results panel. Default: Fixed total on every new sheet session.

b. **Preview content:** Full list of all selected tasks. Sheet shows:
— header: field being edited + requested value + closest achievable result + active mode.
— before/after summary: selected-group total pomodoros and work time.
— mini-table: every selected task with name, pomodoros before→after, weight before→after.
— inline warning if deviation ≥ 10 pp or no improvement possible.

c. **Apply / Cancel placement:** Fixed footer bar at the bottom of the sheet.
Cancel on the left, Apply on the right. Not inline — prevents buttons from
scrolling out of view when the task list grows.

d. **Preview trigger:** Tapping Task weight (%) or Total pomodoros in the editor
opens the sheet. Preview recalculates live while the user types inside the
sheet. No blur trigger, no separate "Preview" button. Importantly: both fields
in the editor become tap targets (read-only display); all editing happens inside
the sheet. The existing per-keystroke onChanged handlers are removed in Patch 2.

e. **Mode switch with value already entered:** Switching mode immediately
recalculates the preview for the new mode using the same entered value and the
frozen baseline. The entered value is not reset.

f. **Snackbar fate:** The existing "Closest possible is X%" snackbar is removed
entirely. Precision information is shown inline inside the sheet only
(text under the header + optional warning badge if deviation ≥ 10 pp).

g. **Preview visual form:** Three-tier layout inside the sheet:
(1) Result line for the edited task: "Result: Y pomodoros · X%".
(2) Group impact block: "Group total: 11 → 11 pom · 225 → 225 min".
(3) Mini-table: one row per selected task (name | pom before→after | % before→after).

h. **Cancel semantics:** Cancel restores the pre-edit snapshot — the state the task
had when the sheet was opened, not the last DB value. Cancel does not trigger any
write or rollback to DB. It simply closes the sheet without applying.
Apply updates the local editor draft (marks dirty). Save persists. Discard from
the editor reverts all local draft including applied sheet changes.

i. **Mode selector scope:** The same sheet and the same Fixed/Flexible selector
apply to both Task weight (%) and Total pomodoros.

Additional micro-clarifications locked (28/03/2026):

j. **Flexible total — exact definition:** Only the edited task's totalPomodoros
changes. All other selected tasks remain at their exact current totalPomodoros.
No redistribution of others in Flexible mode. The selected-group total may
increase or decrease to improve approximation fidelity.

k. **Search range in Flexible total (% path):** Flexible `%` search must not use
a hard cap that can block mathematically reachable outcomes. Candidate evaluation
is unbounded (no artificial max cap), with deterministic tie-break preserved.
Resulting extreme plans are allowed and surfaced to users with a non-blocking
caution based on continuous planned time (start→end, breaks included).

l. **Closest achievable tiebreaker (deterministic, both modes):**
(1) Smallest absolute percentage-point deviation, measured against the
shown percentage (same normalization rule as the UI display).
(2) Smallest absolute change in selected-group total pomodoros.
(3) Smallest absolute change in edited task totalPomodoros.
(4) Smaller resulting group total if still tied.

m. **Apply / Save / Discard lifecycle:**
— Apply (sheet): writes to local editor draft only, marks dirty. Does not persist.
After Apply, the sheet closes. If the user reopens the sheet, the frozen baseline
is the post-Apply draft state (not the original pre-session value).
— Save (Edit Task): persists the full local draft (including all Apply'd changes).
— Discard (Edit Task exit): reverts the entire local draft, including Apply'd
changes not yet saved. Contract is unchanged from current Save/Discard semantics.

n. **1 task selected edge case:** Task weight (%) field is visible but disabled,
displays 100%, shows optional helper "Only one task selected". No sheet opens.
No redistribution logic runs.

o. **Selection change while sheet is open:** If the selected-task scope changes while
the sheet is open, the sheet closes immediately without applying and shows a
lightweight non-modal notice: "Group selection changed. Reopen to recalculate."
No live recomputation on changing selection — this would violate the frozen
baseline guarantee.

p. **VM method for Total pomodoros path:** The existing ViewModel method
`redistributeWeightPercent` takes a target percentage. For the Total pomodoros
path, a new method `redistributeTotalPomodoros` (or equivalent) is required,
taking the target integer and returning the same redistribution map. Codex must
implement this new method in `task_editor_view_model.dart` as part of Patch 2.

Fix applied:
Patch 1 — implemented on 28/03/2026 (commit `8bad479`):

- frozen weight baseline at focus-gain to avoid per-keystroke baseline contamination.
- blur/save sync now prioritizes pending redistribution/last computed result and
  avoids mixed-state overwrite while save confirmation modals are open.
- runtime file touched: `lib/presentation/screens/task_editor_screen.dart`.
  Patch 2 — implemented on 28–29/03/2026 (preview-first UX + follow-up polish):
- preview sub-screen for both Task weight (%) and Total pomodoros with
  Fixed/Flexible segmented mode selector.
- fields in editor converted to tap targets; Apply updates local draft, Save persists.
- full-screen opaque preview surface; `Back = Cancel` semantics with non-duplicated
  unapplied-change hint.
- compact non-redundant status messaging (exact/closest, warning gating after interaction).
- Flexible `%` path without hard cap; continuous-time caution/reminder levels
  (`Unusual`/`Superhuman`/`Machine`) surfaced in preview + Task List + Groups Hub.
- runtime files touched:
  - `lib/presentation/screens/task_editor_screen.dart`
  - `lib/presentation/screens/task_weight_preview_sheet.dart`
  - `lib/presentation/viewmodels/task_editor_view_model.dart`
  - `lib/domain/continuous_plan_load.dart`
  - `lib/widgets/task_card.dart`

Validation update (27/03/2026, macOS) — FAIL:

- Scenario packet executed with evidence in:
  - `docs/bugs/validation_bug016_2026_03_27/logs/2026-03-27_bug016_fa907c9_macos_debug.log`
  - `docs/bugs/validation_bug016_2026_03_27/screenshots/2026-03-27_bug016_01_macos.png` … `2026-03-27_bug016_13_macos.png`
- Reconfirmed field overwrite on blur:
  - G3: `80%` (requested) + snackbar suggests `69%`, but blur moves field to `43%`.
  - Re-entering `69%` still blurs to `43%`.
  - G1: `50%` blurs to `36%`; `80%` / suggested `45%` blurs to `35%`.
- Save-time inconsistency confirmed:
  - Editor blur-state and Task List post-save are not deterministic matches.
  - Selected-group total pomodoros dropped from `11` (`5+4+1+1`) to `6` (`3+1+1+1`) in the captured sequence.
- Additional diagnosis:
  - Current runtime log has no dedicated Task-weight instrumentation; evidence is primarily UI screenshots + reproducible steps.

Validation update (28/03/2026, owner-run packet) — PASS for Patch 1:

- Exact repro rerun from the same group baseline after Patch 1:
  - `80% -> 69%` closest result stable through blur, save, Task List, and reopen.
  - `50%` case stable and deterministic through blur, save warning modal, Task List, and reopen
    (no return to `36%`).
  - `1%` edge case correctly reports `No change possible` and keeps coherent persisted values.
- Local gate PASS on code commit `8bad479`:
  - `flutter analyze`
  - `flutter test test/domain/task_weighting_test.dart`
  - `flutter test test/presentation/viewmodels/task_editor_view_model_test.dart`
- Validation packet synchronized:
  - `docs/bugs/validation_bug016_2026_03_27/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug016_2026_03_27/quick_pass_checklist.md`

Validation update (28/03/2026 + 29/03/2026, Patch 2 packet) — PASS:

- Device packet and runtime log:
  - `docs/bugs/validation_bug016_2026_03_28/logs/2026-03-28_bug016p2_7736f7b_macos_debug.log`
- Validation docs synchronized:
  - `docs/bugs/validation_bug016_2026_03_28/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug016_2026_03_28/quick_pass_checklist.md`
- Local gate PASS on final branch state:
  - `flutter analyze`
  - `flutter test test/domain/task_weighting_test.dart`
  - `flutter test test/presentation/viewmodels/task_editor_view_model_test.dart`
  - `flutter test test/domain/continuous_plan_load_test.dart`

Status:
Closed/OK (Patch 1 + Patch 2 implemented and validated; Phase 10 follow-up closure
completed on 29/03/2026).

---

## BUG-017 — "Custom" appears as selectable item in Edit Task preset dropdown

ID: BUG-017
Date: 25/03/2026 (UTC+1)
Platforms: All (Android, macOS, iOS — UI logic, platform-independent)
Context: Edit Task screen — Preset selector dropdown field.

Repro summary:

- Open Edit Task for any existing task.
- Tap or open the Preset dropdown selector.
- Observe "Custom" listed alongside real user-defined presets (e.g., "Classic Pomodoro").

Symptom:

- "Custom" is presented as a selectable preset option in the dropdown, as if it
  were a real saved preset from Settings.

Observed behavior:

- The dropdown renders "Custom" as an option users can actively choose, mixed in
  with real presets.
- "Custom" is not a saved preset — it is a derived UI label indicating the task's
  current configuration does not match any stored preset.
- Selecting "Custom" from the dropdown creates ambiguous state (not linked to any
  real preset configuration).
- If a user has saved a real preset named "Custom", this creates a naming collision
  with the derived UI label.

Expected behavior:

- The preset dropdown must show ONLY real presets stored in Settings (including
  the default "Classic Pomodoro" if present).
- "Custom" must never appear as a selectable option inside the dropdown.
- If the task has no linked preset (config diverged or no preset selected), the
  selector must stay unlinked and show a neutral closed-field hint (`Select preset`),
  without creating a synthetic menu entry.
- The linked/unlinked state must be communicated by a dedicated inline indicator
  next to the `Preset` field label:
  - Linked: green indicator.
  - Unlinked: neutral/grey indicator.
- If the user manually edits durations while linked to a preset, preset linkage
  must be detached automatically (`presetId = null`) and the field returns to
  unlinked state.

Root cause (confirmed):

- `TaskEditorScreen._presetSelectorRow` injected a synthetic sentinel option
  (`customValue = '__custom__'`) with visible label `Custom` into the dropdown items.
- Unlinked tasks defaulted `selectedValue` to this sentinel, so `Custom` was rendered
  as if it were a real preset.
- Selecting that synthetic option triggered `onPresetSelected(null)`, introducing
  an ambiguous pseudo-choice in a menu that should contain only persisted presets.

Fix applied:

- Removed synthetic `Custom` item/sentinel from the preset dropdown.
- Dropdown now renders only persisted presets (`selectedValue = selectedPreset?.id`).
- Added unlinked closed-field hint (`Select preset`) and dedicated linked/unlinked
  indicator next to the `Preset` label.
- Preserved auto-detach behavior when linked preset values diverge after manual edits.
- Added widget regression coverage in
  `test/presentation/timer_screen_completion_navigation_test.dart`:
  - Confirms no synthetic `Custom` duplicate entry.
  - Confirms real preset named `Custom` remains selectable as a normal preset.
  - Confirms linked/unlinked indicator transitions and detach behavior.

Validation update (31/03/2026, local gate):

- `flutter analyze` PASS.
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Edit Task preset selector"` PASS.
- Validation packet synchronized:
  - `docs/bugs/validation_bug017_2026_03_31/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug017_2026_03_31/quick_pass_checklist.md`
  - `docs/bugs/validation_bug017_2026_03_31/logs/2026-03-31_bug017_pending-local_analyze.log`
  - `docs/bugs/validation_bug017_2026_03_31/logs/2026-03-31_bug017_pending-local_widget_debug.log`

Status:
Closed/OK (31/03/2026). closed_commit_hash: `pending-local`.

---

## BUG-018 — Owner background largo → running+remaining=0 → Ready inválido → recovery tardía

ID: BUG-018
Date: 27/03/2026 (UTC+1)
Platforms: All (Android, macOS — sync logic, platform-independent)
Context: Run Mode — Account Mode, owner device en background ≥25 min (ej. MacBook en reposo).
Cross-reference: Related to BUG-015 (cursor ingest/close validation, Closed/OK `e10a5028`).
Fix branch: fix/bug018-running-zero-resume

Repro summary:

- Owner device (macOS) con sesión activa en `pomodoroRunning` (25 min), restante ~1050s.
- MacBook se cierra / entra en reposo durante ≥25 min (el pomodoro expira durante el sueño).
- MacBook se reabre.
- Observar Run Mode en macOS y en dispositivo mirror (Android).

Symptom:

- Timer congelado en 00:00 con estado `Ready` y anillo ámbar completo durante ~20 minutos.
- El grupo sigue running en Firestore; la pantalla Ready no debería aparecer.
- Se recupera solo (~21 min en repro del 27/03/2026), pero el tiempo de congelación es inaceptable.

Observed behavior:

- Después de la apertura del MacBook, el old VM publica heartbeat con
  `status=pomodoroRunning + remainingSeconds=0 + phaseStartedAt=antiguo`
  (máquina local no ticked durante el sueño; `_deriveRemainingSeconds` calcula elapsed > phaseDuration → 0).
- El nuevo VM se hidrata con `overshotTaskBoundary=true` pero la reconciliación
  (`_applyGroupTimelineProjection`) tarda en completarse o necesita condiciones previas
  (TimeSync válido, snapshot disponible).
- Mientras tanto, el snapshot `running+remaining=0` en Firestore es recibido por dispositivos
  mirror que lo proyectan via `_projectStateFromSession` a `PomodoroStatus.finished` → UI muestra Ready.
- Heartbeats cada ~30s siguen publicando `running+remaining=0` (máquina local sigue en
  `pomodoroRunning` sin transición), perpetuando el estado inválido en Firestore.
- Log de Android muestra además saturación del buffer gráfico (`BLASTBufferQueue: Can't acquire
next buffer`) durante el periodo de congelación, causada por el mirror timer renderizando
  cada segundo sin avanzar.
- Firestore snapshot confirmado: `status=pomodoroRunning, remainingSeconds=0, lastUpdatedAt`
  avanzando cada 30s. Snapshot coherente restaurado a las 17:08 UTC+1 (sessionRevision=33,
  `shortBreakRunning`).

Expected behavior:

- Al volver de background largo, el owner device reconcilia la timeline del grupo ANTES de
  publicar cualquier heartbeat.
- Si el cursor/fase ya expiraron según la timeline, avanzar la máquina al estado correcto
  y publicar ese estado coherente.
- Ningún snapshot `activeExecution + remainingSeconds=0` debe publicarse sin transición previa.
- Los dispositivos mirror no deben renderizar Ready si el grupo sigue en status=running en Firestore.

Root cause (confirmed, 27/03/2026):

1. `handleAppResumed` en Account mode (pomodoro_view_model.dart:2914-2923) salta
   `_applyGroupTimelineProjection` y delega a `syncWithRemoteSession`. Si la sesión remota
   ya está corrompida (publicada por el old VM justo antes de cerrarse), el sync remoto replica
   el estado roto en lugar de corregirlo.
2. `_buildCurrentSessionSnapshot` (línea 1186) usa `_machine.state.status` (todavía
   `pomodoroRunning`, la máquina no transitó durante el sueño) con `_deriveRemainingSeconds`
   que devuelve 0 por timeline — produciendo snapshot imposible sin disparar transición.
3. `_projectStateFromSession` en mirror (línea 3581) proyecta `running+remaining=0+phaseStartedAt
antiguo` a `PomodoroStatus.finished` → renderiza Ready aunque grupo siga running.
4. La recuperación final ocurre por `_hydrateOwnerSession` → `overshotTaskBoundary=true` →
   `_applyGroupTimelineProjection(skipControlsCheck:true)`, pero depende de condiciones lentas
   (TimeSync, snapshot procesado), resultando en ~21 min de congelación.
5. Arquitectura de fondo: el avance de fase depende de que haya un device activo y en foreground.
   Sin device activo, Firestore queda en el último estado publicado indefinidamente (sin Cloud
   Function que avance la sesión server-side).

Fix applied:
Yes.

Final fix (validated):

- `b10fa02`: introdujo reconciliación de resume + hardening de mirror/repair,
  pero generó regresión de amplificación de publish en owner echo.
- `547c6f7` (`fix(bug-018): stop owner echo publish amplification in account mode`):
  elimina reconciliación del publish normal y conserva reconciliación explícita en resume,
  cortando el loop de publish/revisión y estabilizando transiciones.

Validation evidence (27/03/2026):

- Log PASS:
  `docs/bugs/validation_bug018_2026_03_27/logs/2026-03-27_bug018_547c6f7_android_RMX3771_debug.log`
- Señales clave:
  - `Reconciled owner timeline before publish reason=resume` (1 vez).
  - `TimeSync refreshed (break-start)` (1 vez) y `TimeSync refreshed (pomodoro-start)` (2 veces:
    inicio + siguiente pomodoro), sin ráfagas de transiciones.
  - `running + remaining=0`: 0 coincidencias.
  - Resume coherente en G2: snapshot `remaining=663` a `20:00:55`, alineado con UI (~11:25).

Status:
Closed/OK (27/03/2026). closed_commit_hash: `547c6f7`.

---

## BUG-019 — Android system back intermittently exits app instead of returning to root screen

ID: BUG-019
Date: 29/03/2026 (UTC+1)
Platforms: Android (confirmed), cross-platform review pending
Context: Navigation stack behavior on root routes (`/timer/:id`, `/groups`) while using
system back.

Repro summary:

- Open the app and navigate to Run Mode (`/timer/:groupId`) or Groups Hub (`/groups`).
- Press Android system back.
- Repeat after different navigation paths (Task List -> Groups Hub, Task List -> Run Mode,
  cancellation/re-entry flows).

Symptom:

- In some cases, pressing system back closes the app immediately (home/launcher),
  instead of returning to the expected root screen.

Observed behavior:

- System back is intermittent: same user flow can sometimes return, sometimes terminate.
- Expected root fallback (Task List) is not always reached before app exit.
- Behavior is more visible when navigation has been done with route replacement
  (`go`) on top-level routes.

Expected behavior:

- System back must never terminate the app unexpectedly from active product flows.
- If user is in Run Mode:
  - active execution: keep existing confirmation/cancel policy (no silent exit).
  - non-active/root state: return to app root screen instead of closing app.
- If user is in Groups Hub root route, system back should return to Task List root
  (future shared tabs host), not close app directly.
- Behavior must be deterministic across repeated back presses.

Root cause:
Not yet confirmed.

Hypothesis:

- Several top-level navigations use stack replacement (`context.go`) and can leave
  routes without a pop stack; Android system back then delegates to app exit unless
  a deterministic fallback route is handled explicitly.
- Run Mode `PopScope` currently gates exit primarily on machine status and may not
  cover all runtime ownership/session combinations that should block termination.

Fix applied:

- `d1a1f19` — GroupsHubScreen: PopScope(canPop: false) with fallback to /tasks
- `e16a692` — TimerScreen: canPop: false always; non-active path uses context.canPop()
  fallback to /tasks or /groups per mode; active path delegates to \_confirmExit unchanged
- `ed97de7` — Tests: 4 system-back regression tests covering all validation scenarios

Status:
Closed/OK. closed_commit_hash: ed97de7. Device validation PASS 29/03/2026 (Android RMX3771):
Scenario A (Groups Hub → /tasks), B (Timer non-active → /groups), C (active confirmation
guard preserved), D (Settings stack-pop unchanged). flutter analyze + flutter test PASS.

---

## BUG-020 — Task editor preview sheet: incorrect Group/Task terminology, missing break duration, and incorrect exit messages

ID: BUG-020
Date: 30/03/2026 (UTC+1)
Platforms: Android (confirmed), macOS (confirmed)
Context: Edit Task screen — Total pomodoros editor sheet and Task weight (%) editor sheet.

Repro summary:

- Open Edit Task for a task that is NOT selected for group.
- Tap Total pomodoros field to open preview sheet.
- Observe: sheet shows "Group work" label even though task is not a group.
- Observe: only work duration without breaks is shown; threshold labels (Unusual/Superhuman/Machine) base on total-with-breaks but only work time was displayed, causing confusion.
- Press Back without applying: snackbar always said "No changes applied" even when changes were applied.
- Same issue in Task weight (%) sheet when task IS selected and in a group: only work duration shown, not total with breaks.

Symptom:

- "Group work" terminology shown for individual (non-selected) tasks — misleading.
- No visibility of total duration including breaks in either sheet, hiding the real basis for extreme-duration warnings.
- Unusual/Superhuman/Machine caution was suppressed after first show within the sheet session; felt like a bug when re-entering the threshold range.
- Exit snackbar was always "No changes applied" regardless of whether Apply was pressed.
- No confirmation modal when leaving with unapplied changes.

Root cause:

- `isGroupContext` parameter was missing; sheet always used "Group" terminology regardless of selection state.
- Only `_groupMinutes` (work-only) was displayed; `continuousGroupDurationSecondsForTasks` / `continuousTaskDurationsSecondsForTasks` (total with breaks) was not surfaced in the UI.
- `showContinuousCaution` guarded by `_hasUserInteracted`, causing caution to disappear and reappear erratically.
- Exit path had no distinction between applied/unapplied/no-change states.

Fix applied:

- `78b72db` — isGroupContext passed from both call sites; \_scopeLabel resolves 'Task'/'Group' at runtime; dual duration lines (work + total with breaks); caution value-driven (no \_hasUserInteracted gate); back modal (Apply and close / Discard and close / Continue editing) when unapplied changes exist; snackbar 'Changes applied.' / 'No changes made.' per case.

Status:
Closed/OK. closed_commit_hash: 78b72db. Device validation PASS 30/03/2026 (Android + macOS):
Terminology correct per selection context, dual duration lines shown, caution always visible when threshold, back modal fires on unapplied changes, snackbar correct in all exit paths. flutter analyze PASS.

---

## BUG-021 — Run Mode ownership rejection snackbar can remain stale after ownership state changes

ID: BUG-021
Date: 30/03/2026 (UTC+2)
Platforms: Android, macOS (Run Mode; expected cross-platform behavior)
Context: Account Mode mirror/requester device with a visible ownership rejection snackbar.

Repro summary:

- Open Run Mode on a mirror/requester device.
- Trigger a rejection snackbar (`Ownership request rejected at ...`) and keep it visible.
- Change ownership context without pressing `OK`:
  - requester submits a new request (new `requestId` / pending), or
  - requester becomes owner, or
  - ownership request is cleared/replaced.

Symptom:

- The previous rejection snackbar can remain visible with obsolete information.
- UI feedback contradicts current ownership state.

Observed behavior:

- Snackbar lifetime was mostly tied to manual dismissal.
- Invalidation only covered a subset of transitions, so stale messages could survive
  request replacement/clear paths.

Expected behavior:

- Ownership snackbar feedback must always match the current ownership context.
- Obsolete rejection snackbars must auto-dismiss immediately when the requester
  becomes owner or submits a newer request (specs 10.4.11).

Root cause (confirmed):

- `TimerScreen` tracked rejection snackbar visibility as a boolean and did not bind
  the visible snackbar to an active rejected request key.
- Invalidation logic only checked partial state (`isOwnerForCurrentSession`,
  `isOwnershipRequestPendingForThisDevice`) and missed other context-invalidating
  transitions.

Fix applied:

- Branch: `fix/bug021-ownership-snackbar-autodismiss`
- Runtime patch in `lib/presentation/screens/timer_screen.dart`:
  - Added request-key-aware rejection state (`_activeOwnershipRejectionSnackKey`).
  - Added `_rejectedOwnershipRequestKeyForDevice(...)` resolver.
  - Auto-dismisses visible rejection snackbar when ownership context changes and
    the active snackbar key no longer matches the current rejected request key.
  - Covers requester owner-transition, new request submission (pending/local pending),
    request clear/replacement, and group switch invalidation.
- Regression tests:
  - `test/presentation/timer_screen_completion_navigation_test.dart`
    - `Run Mode dismisses stale rejection snackbar when requester submits a new request`
    - `Run Mode dismisses stale rejection snackbar when requester becomes owner`

Status:
Closed/OK (30/03/2026). closed_commit_hash: `pending-local`.
Closure evidence:

- `flutter analyze` PASS (30/03/2026)
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Run Mode dismisses stale rejection snackbar"` PASS (30/03/2026)
- Validation packet updated:
  - `docs/bugs/validation_bug021_2026_03_30/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug021_2026_03_30/quick_pass_checklist.md`
- User accepted closure in-thread after log review and observed stable behavior.
- Scope note: the original report described automatic owner change without explicit request; this fix closes the stale **rejection** snackbar path defined in BUG-021.

---

## BUG-022 — macOS Authentication fields stop accepting keyboard input after account switch

ID: BUG-022
Date: 30/03/2026 (UTC+2)
Platforms: macOS (confirmed)
Context: Account Mode on desktop. User signs out from one account and goes to Authentication to sign in with a different account.

Repro summary:

- Start signed in on macOS.
- Sign out to switch user.
- Open Authentication screen.
- Tap email/password fields and try typing.

Symptom:

- Keyboard input is blocked in Authentication (`Email` and `Password`).
- User cannot type credentials and cannot recover without restarting the app.

Observed behavior:

- Repeated framework exception:
  `A KeyDownEvent is dispatched, but the state shows that the physical key is already pressed`.
- Repeated stale event details point to `Backspace` with identical event identity/timestamp across retries.
- While exception loop is active, text fields do not accept normal typing.

Expected behavior:

- Authentication fields must always accept keyboard input after sign-out/account switch.
- Any stale keyboard state must self-heal automatically when opening Authentication.

Root cause:
Not fully confirmed yet.

Hypothesis:

- Flutter `HardwareKeyboard` pressed-key state can remain stale across sign-out/navigation transitions on macOS.
- When stale pressed keys are not reconciled, subsequent key events are rejected as duplicate key-down events, blocking text input.

Fix applied:

- Branch: `fix/bug022-macos-auth-keyboard-stuck`
- Runtime patch in `lib/presentation/screens/login_screen.dart`:
  - Added macOS-only keyboard-state repair on Authentication screen open and on email/password field tap.
  - Repair compares framework pressed keys vs engine-reported keyboard state (`SystemChannels.keyboard/getKeyboardState`).
  - For stale pressed keys, synthesize `KeyUpEvent` via `HardwareKeyboard.instance.handleKeyEvent` to unblock typing.
  - Added debug diagnostics `[AuthKeyboardRepair]` for evidence in runtime logs.

Status:
Closed/OK (30/03/2026). closed_commit_hash: `4e439db`.
Validation evidence:

- User manual validation confirmation in thread (30/03/2026): after account switch,
  Authentication `Email`/`Password` fields accept typing normally; no immediate recurrence.
- Local gate PASS on the same commit:
  - `flutter analyze`
  - `flutter test test/presentation/timer_screen_completion_navigation_test.dart`
- Validation packet synchronized:
  - `docs/bugs/validation_bug022_2026_03_30/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug022_2026_03_30/quick_pass_checklist.md`

---

## BUG-023 — Task Editor "Save as new preset" does not auto-link the saved preset

ID: BUG-023
Date: 31/03/2026 (UTC+2)
Platforms: All (UI/navigation integration, platform-independent)
Context: Edit Task screen -> `Save as new preset` -> Preset Editor -> return to Task Editor.

Repro summary:

- Open Edit Task with a task in Custom/unlinked state.
- Tap `Save as new preset`.
- Save the preset in Preset Editor (or resolve duplicate via `Use existing` / `Rename existing`).
- Return to Task Editor.

Symptom:

- The task remains unlinked (`Select preset`) after returning, even though the preset
  was saved or explicitly selected via duplicate resolution.

Observed behavior:

- Task Editor launches Preset Editor but does not consume a returned preset id.
- Preset Editor exits without returning a payload to the caller.
- As a result, Task Editor never applies/links the resulting preset after a successful
  save/resolution flow.

Expected behavior:

- After `Save as new preset` succeeds, Task Editor must auto-link the current task to the
  resulting preset and immediately reflect linked state.
- Duplicate-resolution mapping in this flow:
  - `Save anyway` -> link to new preset id.
  - `Use existing` -> link to existing duplicate id.
  - `Rename existing` -> link to renamed existing duplicate id.
  - `Cancel`/blocked save -> keep task unlinked.

Root cause (confirmed):

- Task Editor pushes Preset Editor route without awaiting/using a result payload.
- Preset Editor save/exit flow pops without returning a preset id.

Fix applied:

- Branch: `fix/bug023-save-as-preset-autolink`
- Runtime patch:
  - `lib/presentation/screens/preset_editor_screen.dart`
    - Save flow now returns deterministic `presetId` payloads on successful exit.
    - Duplicate-resolution mapping implemented:
      - Save anyway -> new draft preset id.
      - Use existing -> existing duplicate id.
      - Rename existing -> renamed existing duplicate id.
      - Cancel/blocked -> null.
    - Added caller-gated route payload support (`returnPresetId`) to avoid
      leaking payloads to unrelated navigations.
  - `lib/presentation/screens/task_editor_screen.dart`
    - `Save as new preset` now awaits route result from
      `/settings/presets/new?returnPresetId=1` and auto-applies returned preset.
  - `lib/presentation/viewmodels/task_editor_view_model.dart`
    - Added `applyPresetById(String id)` to fetch directly from repository and
      apply deterministically (no stream-timing race).
  - `lib/app/router.dart`
    - Preset creation route now parses `returnPresetId` query flag.
  - `test/presentation/timer_screen_completion_navigation_test.dart`
    - Added regression test: `Edit Task Save as new preset auto-links returned preset`.

Status:
Closed/OK (31/03/2026). closed_commit_hash: `pending-local`.

Validation evidence (local gate):

- `flutter analyze` PASS.
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Edit Task"` PASS.
- Validation packet created and synchronized:
  - `docs/bugs/validation_bug023_2026_03_31/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug023_2026_03_31/quick_pass_checklist.md`
  - `docs/bugs/validation_bug023_2026_03_31/logs/2026-03-31_bug023_pending-local_analyze.log`
  - `docs/bugs/validation_bug023_2026_03_31/logs/2026-03-31_bug023_pending-local_widget_debug.log`

Validation evidence (manual run):

- macOS live validation PASS (31/03/2026):
  - `Save anyway` path auto-links returned preset and hides `Save as new preset`.
  - `Use existing` path auto-links existing duplicate preset on return.
  - Evidence captured via screenshots in thread and packet notes.
- Android manual quick validation PASS (31/03/2026):
  - Scenario A (new preset save return) linked correctly in Edit Task (`preset 21 min`).
  - Scenario B (`Use existing`) linked existing duplicate in Edit Task (`preset 20 min (2)`).
  - Runtime log: `docs/bugs/validation_bug023_2026_03_31/logs/2026-03-31_bug023_pending-local_android_debug.log`.
  - Evidence captured via user screenshots in thread.

---

## BUG-024 — Owner reject banner reappears when pending request materializes `requestId`

ID: BUG-024
Date: 02/04/2026 (UTC+2)
Platforms: Account Mode multi-device (owner + mirror)
Context: Run Mode ownership request banner (`Ownership request`) on owner device.

Repro summary:

- Owner receives a pending ownership request without `requestId`.
- Owner taps `Reject` and banner dismisses.
- Backend/session snapshot re-ingests the same pending requester with materialized `requestId`.

Symptom:

- Owner `Ownership request` banner can reappear immediately after rejection even
  though it is the same requester flow, creating a visible dismiss/reopen flicker.

Observed behavior:

- Dismissal fallback tracks requester id when `requestId` is null.
- Once `requestId` appears, dismissal check switches to requestId-only path and
  no longer honors requester fallback for that same pending request.

Expected behavior:

- Once owner dismisses/rejects a pending request, materialization of `requestId`
  for the same requester pending flow must not re-open the banner.

Root cause (confirmed):

- `lib/presentation/screens/timer_screen.dart`
  - `_isDismissedOwnershipRequest(...)` returned early on non-null `requestId`,
    skipping `_dismissedOwnershipRequesterId` fallback matching.
  - This broke continuity across null->materialized `requestId` transitions.

Fix applied:

- Branch: `validation-rvp021-028-sync`
- Runtime patch:
  - `lib/presentation/screens/timer_screen.dart`
    - `_isDismissedOwnershipRequest(...)` now preserves requester fallback match
      even when `requestId` is present.
- Regression coverage added:
  - `test/presentation/timer_screen_syncing_overlay_test.dart`
    - `owner reject dismissal stays hidden when pending request gets requestId materialized`

Status:
Closed/OK (02/04/2026). Local exact-repro PASS + local regression smoke PASS +
real-device validation PASS (Android owner + macOS mirror).

Validation evidence (local):

- `flutter test ... --plain-name "owner reject dismissal stays hidden when pending request gets requestId materialized"` PASS
- `flutter test ... --plain-name "critical ownership flow stays appbar-sheet-only and pending remains stable until owner response"` PASS
- `flutter test ... --plain-name "rejection clears local pending and old rejected requestId does not suppress a new request"` PASS
- `flutter analyze` PASS
- Validation packet created:
  - `docs/bugs/validation_bug024_2026_04_02/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug024_2026_04_02/quick_pass_checklist.md`
  - `docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_widget_exact_repro_debug.log`
  - `docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_widget_regression_critical_debug.log`
  - `docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_widget_regression_requestid_debug.log`
  - `docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_analyze.log`

Validation evidence (devices):

- 02/04/2026 user-confirmed real-device PASS in thread:
  - Scenario A: Android owner + macOS mirror, reject flow validated without banner reappearance.
  - Scenario B: ownership sheet flow + pending/reject lifecycle validated.
  - Scenario C: closure criteria validated on the same device run, no regressions observed.

Device validation policy:

- If real-device validation shows regression, rollback to pre-fix state and keep
  BUG-024 open as observation (do not close).

---

## BUG-025 — Running overlap alert missed at boundary and on Run Mode re-entry

ID: BUG-025
Date: 03/04/2026 (UTC+2)
Platforms: Android, macOS (expected cross-platform behavior)
Context: Account Mode, running group paused with a following scheduled group near boundary.

Repro summary:

- Keep `G1` running and pause it.
- Configure `G2` scheduled so its pre-run/start boundary matches projected `G1` end.
- Let conflict boundary pass while checking Run Mode and re-entering TimerScreen from other routes.

Symptom:

- `Scheduling conflict` modal may appear late or fail to appear when conflict exists.
- On TimerScreen entry/re-entry, an already-active overlap decision may not surface.

Observed behavior:

- Overlap threshold used a +1 minute grace, delaying/neutralizing exact-boundary conflicts.
- TimerScreen consumed overlap decisions mainly on provider change events; pre-existing decisions at screen entry could be missed in edge timing.

Expected behavior:

- Overlap decision must trigger at exact boundary (`runningEnd >= preRunStart`).
- TimerScreen must consume already-active overlap decisions on enter/re-enter when still valid.

Root cause (confirmed):

- `lib/presentation/utils/scheduled_group_timing.dart`: overlap threshold was `preRunStart + 1 minute`.
- `lib/presentation/screens/timer_screen.dart`: initial/mount consumption path for existing `runningOverlapDecisionProvider` value was insufficient.

Fix applied:

- Branch: `fix/overlap-threshold-exact`
- Runtime/docs/tests:
  - `0a1ea3a` `fix(overlap): trigger running overlap exactly at pre-run boundary`
    - Removed +1 minute grace from overlap threshold.
    - Updated overlap timing spec wording to exact boundary.
    - Added boundary tests in timing/coordinator suites.
  - `547de2b` `fix(timer): consume existing running-overlap decision on run mode mount`
    - Added unified `_consumeRunningOverlapDecision(...)` path.
    - Called from listener + mount/re-entry post-frame flows.
    - Added widget test for decision already present on TimerScreen mount.

Status:
Closed/OK (03/04/2026). closed_commit_hash: `547de2b`.

Validation packet:

- `docs/bugs/validation_bug025_2026_04_03/plan_validacion_rapida_fix.md`
- `docs/bugs/validation_bug025_2026_04_03/quick_pass_checklist.md`
- Local gate PASS logs:
  - `docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_local_analyze.log`
  - `docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_local_targeted-tests.log`
- Device evidence PASS (scenarios A-D):
  - `docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_android_RMX3771_debug.log`
  - `docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_macos_debug.log`
  - Visual clock-based matrix + verdict in `plan_validacion_rapida_fix.md` (`Scenario A/B/C/D: PASS`).

---

## BUG-026 — Start now session publish delayed: owner stays on Groups Hub, Run Mode not auto-opened, mirror stuck in Syncing session

ID: BUG-026
Date: 03/04/2026 (UTC+2)
Platforms: Android owner + macOS mirror
Context: Account Mode, Start-now plan confirmed from Plan Group screen.

Repro summary (from device logs + screenshots, 03/04/2026 13:55 UTC+2):

1. User (Android owner) opens Plan Group for G1 and taps Confirm with Start now at 13:55:07.
2. Android returns to Task List showing `Group Running · G1 / Open Run Mode` banner + Groups Hub card
   `Status: running`, snackbar `Task group started.` fires.
3. BUT: the app does NOT auto-navigate to Run Mode (TimerScreen) — user stays on Task List / Groups Hub.
4. Android logs show `[ScheduledGroups][running-open-timer]` fires at 13:55:07, then
   `[ScheduledActionDiag] actionType=openTimer` fires, then `[RunModeDiag] Auto-start navigate … route=/tasks` —
   the openTimer action is dispatched but the navigator does not push /timer because the route is already /tasks
   and the auto-open guard (`_cancelNavigationHandled` or in-flight check) blocks the navigation.
5. At 13:55:07 Android attempts `startFromAutoStart` → calls `syncWithRemoteSession` →
   gets `Resync missing; no session snapshot` (Firestore has not yet written the session).
6. `startFromAutoStart` then proceeds to `_startInternal` (start without confirmed session), fires chime,
   publishes session to Firestore. This write arrives at Firestore at ~13:55:24 (17 seconds later).
7. macOS mirror opens TimerScreen for G1 at 13:55:07 (also triggered by `openTimer` coordinator action),
   immediately hits `Resync missing`, enters `runningWithoutSession` SyncOverlay, shows
   black screen with `Syncing session...` and an inert `Start` button (13:55:07–13:55:24).
8. At 13:55:24 Firestore delivers `pomodoroRunning` snapshot (remaining=900) to both devices.
   Android SyncOverlay goes `runningWithoutSession → awaitingSessionConfirmation`.
   macOS SyncOverlay clears and Run Mode renders normally (14:58–14:59 countdown visible by 13:55:26).

Timeline from logs:

- 13:55:07.343 Android: `[ScheduledGroups][running-open-timer]` + `openTimer` dispatched
- 13:55:07.343 Android: `Auto-start navigate … route=/tasks` (wrong: should push /timer)
- 13:55:07.891 macOS: `openTimer` received → `Auto-start navigate … route=/groups` → pushes /timer
- 13:55:08 Android: `[SessionSub] open (→SSS)` + `[ActiveSession] Resync missing`
- 13:55:08 macOS: `[ActiveSession] Resync missing` → SyncOverlay shown
- 13:55:08 Android: `startFromAutoStart` → `_startInternal` fires chime + publishes session
- 13:55:08–24 Both devices: repeated `Resync missing; no session snapshot` (Firestore write pending)
- 13:55:24 Android: Firestore snapshot arrives (remaining=900, pomodoroRunning)
- 13:55:24 macOS: Firestore snapshot arrives → SyncOverlay clears → Run Mode active

Root bugs (two independent failures):

Root bug A — Owner stays on Groups Hub after Start now; Run Mode not opened:

- `task_list_screen.dart:1601` calls `openRunModeForGroup(context, ref, group)` which does
  `context.go('/timer/${group.id}')`. This fires but the app does NOT end up in Run Mode.
- Simultaneously the ScheduledGroupCoordinator detects a running group with no active session
  (session hasn't propagated to Firestore yet at this instant) and emits `openTimer` via
  `ScheduledGroupAutoStarter`. This triggers `_openTimerForGroup` in
  `lib/widgets/scheduled_group_auto_starter.dart`.
- The collision between task_list_screen's `context.go` and the auto-starter's `router.go`
  can cause the navigation to land on `/tasks` or `/groups` instead of `/timer/`. The
  auto-starter log shows `Auto-start navigate route=/tasks` which means the auto-starter
  fires while the route is still `/tasks` (before task_list_screen's push completes), and
  then task_list_screen's push lands but is overwritten by a subsequent coordinator re-emit
  (coordinator fires again at 13:55:14 because session is still null → `running-open-timer`
  emits again, macOS log line 6184).
- The net result: Android navigates to `/timer/` then back to a hub, or `context.go` conflicts
  with the coordinator's `router.go`. User ends up in Groups Hub instead of Run Mode.
- Log evidence: macOS log shows at 13:55:18 a second `[SessionSub] open (→SSS)` + `Timer load`
  - `Auto-start attempt` — macOS re-executes the whole load-group + startFromAutoStart cycle.
    This re-execution means the coordinator fired `openTimer` multiple times (once at 13:55:07,
    again at 13:55:14, again at 13:55:18) due to the session still being null.
- Android probably had the same re-emissions but `_openTimerForGroup` suppresses if already on
  `/timer/`. The user manually opens Run Mode from Groups Hub at ~13:55:24 which coincides with
  the first Firestore snapshot arriving.
- This is the PRIMARY UX failure: Start now must always end in Run Mode for the owner
  without manual navigation.

Root bug B — Mirror shows `Syncing session...` with inert `Start` CTA for ~17s:

- Both devices enter Run Mode via coordinator `openTimer` at 13:55:07 but Firestore has not yet
  received the session write from Android's `_startInternal` (called inside `startFromAutoStart`).
- `startFromAutoStart` calls `syncWithRemoteSession` first → gets null (Firestore not written yet)
  → proceeds to call `_startInternal` which publishes the session. Firestore write propagation
  takes ~17s in this run (likely Firestore cold path or contention).
- During these 17s both devices show `runningWithoutSession` SyncOverlay (`Syncing session...`).
- macOS (mirror) shows a `Start` CTA during this hold that is visually active but does NOT work
  (mirror cannot call `startFromAutoStart` because it is not the owner). This is a UX contract
  violation: the Start button during `runningWithoutSession` hold must be disabled/hidden on mirror.
- This is SECONDARY: the 17s Firestore propagation delay is an environmental timing issue in this
  run. The structural bug is the inert `Start` on mirror during the hold.

Symptom (user perspective):

- Taps Confirm on Plan Group with Start now.
- Sees `Task group started.` snackbar and Groups Hub running card — but stays on that screen.
- Has to manually navigate to Run Mode. Timer had not started yet visually.
- macOS mirror shows black screen + `Syncing session...` + `Start` button for ~17 seconds.
- After ~17s both devices show the running timer normally.

Expected behavior:

- Owner should auto-navigate to Run Mode immediately after tapping Confirm on Start now — no manual step.
- Mirror `Start` CTA during `runningWithoutSession` hold should be disabled or hidden (mirror cannot start).
- Session should hydrate within a few seconds of the owner writing it; 17s delay is suspicious but may
  relate to Firestore write timing — requires log analysis of the write path to confirm.

Evidence:

- Screenshots: images V10-V13 in conversation thread (13:55:07–13:55:24 UTC+2 from clock widget).
- Android log: `docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_android_RMX3771_debug.log`
  lines 7384–7468 (key: lines 7388–7390 openTimer/route=/tasks, 7411 Resync missing, 7412 startFromAutoStart,
  7416 TimeSync, 7417–7418 SyncOverlay, 7468 first session snapshot).
- macOS log: `docs/bugs/validation_bug025_2026_04_03/logs/2026-04-03_bug025_547de2b_macos_debug.log`
  lines 6158–6213 (key: lines 6162 route=/groups, 6175 Resync missing, 6192/6196/6206 repeated Resync missing,
  6208 first session snapshot at 13:55:24, 6209 SyncOverlay clears).

Workaround:

- After tapping Confirm with Start now, manually tap Open Run Mode in Groups Hub.
- Mirror resolves on its own after ~17s when Firestore snapshot arrives.

Fix applied:

- TimerScreen canceled navigation now enforces strict displayed-group match before routing:
  - navigate to Groups Hub only when `currentGroup.id == widget.groupId`.
  - preserves valid cancel navigation and blocks stale-canceled cross-group rebounds.
- Added deterministic regression coverage for stale canceled mismatch during delayed load:
  - `Timer ignores stale canceled vm group when displayed group id differs`.
- Validation harness stabilized for this repro path:
  - fake session repository now exposes deterministic initial snapshot behavior for this scenario.
- Scheduling conflict expectations aligned with current planning contract:
  - pre-run-only overlap no longer blocks scheduling in Task List conflict tests.

Validation recap (24/04/2026):

- Scenario A PASS (Android owner): Start now auto-opened `/timer/:groupId` and stayed stable; no route bounce to `/tasks` or `/groups`.
- Scenario B PASS (macOS mirror): transient sync overlay recovered automatically; no inert/blocked flow reported.
- Scenario C PASS: cancel from running group returned to Groups Hub once, smoothly, with no loops.
- Scenario D PASS: stale canceled mismatch no longer triggers unexpected Groups Hub navigation; focused regression test no longer hangs.
- Local gate PASS:
  - `flutter analyze`
  - `flutter test test/presentation/timer_screen_completion_navigation_test.dart`
  - `flutter test test/presentation/timer_screen_syncing_overlay_test.dart`
  - `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Timer ignores stale canceled vm group when displayed group id differs"`

Evidence:

- Validation packet:
  - `docs/bugs/validation_bug026_2026_04_03/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug026_2026_04_03/quick_pass_checklist.md`
- Logs:
  - `docs/bugs/validation_bug026_2026_04_03/logs/2026-04-24_bug026fast_retry_018b6e6_android_RMX3771_debug.log`
  - `docs/bugs/validation_bug026_2026_04_03/logs/2026-04-24_bug026fast_018b6e6_macos_debug.log`
  - `docs/bugs/validation_bug026_2026_04_03/logs/2026-04-24_bug026fast_retry_018b6e6_local_analyze_debug.log`
  - `docs/bugs/validation_bug026_2026_04_03/logs/2026-04-24_bug026fast_retry_018b6e6_timer_completion_debug.log`
  - `docs/bugs/validation_bug026_2026_04_03/logs/2026-04-24_bug026fast_retry_018b6e6_timer_sync_overlay_debug.log`
  - `docs/bugs/validation_bug026_2026_04_03/logs/2026-04-24_bug026fast_retry_018b6e6_timer_stale_cancel_debug.log`

Status:

Closed/OK (24/04/2026, user-confirmed in thread). closed_commit_hash: `819745c`.
closed_commit_message: `fix(bug026): guard stale-cancel routing and finalize validation closure`.

---

## BUG-027 — Conflict explanations are missing critical context (groups/ranges) across planning and runtime surfaces

ID: BUG-027
Date: 03/04/2026 (UTC+2)
Platforms: Android + macOS
Context: Planning conflicts and runtime overlap conflict guidance.

Symptom:

- Conflict messages do not always identify both involved groups and full time ranges.
- User cannot clearly understand why a conflict exists or what changed after resolution.

Observed behavior:

- Planning modal `Conflict with running group` uses generic copy without blocker identity/range context (V03).
- Pre-run conflict snackbar lacks explicit blocker group + compared ranges (V05).
- Runtime conflict modal shows scheduled group range but not paused/running projection range.
- Mirror warning copy remains generic (`Owner is resolving this conflict...`) with no pair/range details (V19, V24).

Expected behavior:

- Conflict copy should consistently show:
  - current running/paused group identity + projected range,
  - scheduled/planned conflicting group identity + range,
  - selected candidate range when applicable.

Evidence:

- `docs/bugs/validation_bug025_2026_04_03/plan_validacion_rapida_fix.md` (Visual Evidence Matrix V03, V05, V19, V24; Evidence-Based Verdict F02).

Workaround:

- Manual cross-check in Groups Hub/Run Mode cards to infer timing/range context.

Hypothesis:

- Message templates are inconsistent across planning/runtime/mirror paths and do not share a single conflict-detail formatter.

Fix applied:

- Implementation completed on 01/05/2026 (`fix/bug033-foreground-service-crash`, commit `8600f44`):
  - Added centralized conflict context model/formatter in `lib/presentation/utils/scheduling_conflict_helpers.dart`:
    - `ConflictWindow` (group id/name/status + start/end + optional pre-run start),
    - `PreRunConflict` (type + blocker window),
    - `RunningOverlapContext` (running + scheduled windows),
    - shared time/range formatters.
  - Propagated contextual copy to planning/runtime/mirror surfaces:
    - Groups Hub re-plan running conflict modal now lists selected range + running blockers (name + range).
    - Groups Hub re-plan scheduled conflict modal now lists selected range + scheduled blockers (name + range).
    - Groups Hub pre-run conflict snackbar now includes blocker identity/range and candidate pre-run window.
    - Timer runtime overlap modal now includes both running and scheduled group context (+ pre-run when applicable).
    - Timer mirror conflict snackbar now includes contextual running/scheduled summary line.
    - Task List and Groups Hub mirror conflict banners now expose contextual summary via compact info tooltip.
  - Regression/local coverage:
    - `flutter analyze` PASS.
    - `flutter test test/presentation/timer_screen_completion_navigation_test.dart` PASS.
    - `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` PASS.
    - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` PASS (clean re-run).
    - `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS.
    - `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` PASS.
    - `flutter test test/presentation/utils/scheduled_group_timing_test.dart` PASS.
    - Added assertions for runtime modal context labels (`Running:` / `Scheduled:`).

Status:

In validation (01/05/2026). Validation packet opened at
`docs/bugs/validation_bug027_2026_05_01/`; device scenarios A-D pending
(V03/V05/V19/V24 closure evidence).

---

## BUG-033 — Android background crash on foreground service promotion (`ForegroundServiceStartNotAllowedException`)

ID: BUG-033
Date: 29/04/2026 (UTC-4)
Platforms: Android (owner path), with cross-device ownership side effects
Context: Account Mode runtime while Android app stays in background for several minutes during active execution.

Symptom:

- Android process crashes with system dialog (`focus_interval sigue sin funcionar`) while a run is active in background.
- After crash, ownership can shift to another device (for example macOS), creating inconsistent multi-device continuity during validation runs.

Observed behavior:

- Runtime log captures:
  - `FATAL EXCEPTION: main`
  - `android.app.ForegroundServiceStartNotAllowedException`
  - `Service.startForeground() not allowed due to mAllowStartForeground false`
- Crash stack points to:
  - `android/app/src/main/kotlin/com/marcdevelopez/focusinterval/PomodoroForegroundService.kt`
  - `onStartCommand(...)` -> `startOrUpdate()` -> `startForeground(...)`.
- The event occurred during a background interval while session snapshots kept arriving, then process shutdown (`SIG: 9`) followed.

Expected behavior:

- App must not crash when background lifecycle triggers foreground-service update/start paths.
- Active run continuity must remain stable in background without process kill.

Evidence:

- User-provided Android log excerpt dated 29/04/2026 around 11:40 (UTC-4), including full stacktrace and shutdown sequence.
- Screenshot evidence from Android system crash dialog.
- Validation packet opened:
  - `docs/bugs/validation_bug033_2026_04_29/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug033_2026_04_29/quick_pass_checklist.md`
- Follow-up non-repro session (01/05/2026, 13:05-14:35 EDT):
  - `docs/bugs/validation_bug033_2026_04_29/logs/2026-05-01_bug033_5b9d85c_android_RMX3771_debug_prod.log`
  - `docs/bugs/validation_bug033_2026_04_29/logs/2026-05-01_bug033pid_5b9d85c_android_RMX3771_debug.log`
  - No `ForegroundServiceStartNotAllowedException` or `FATAL EXCEPTION` tied to `com.marcdevelopez.focusinterval` captured in app-focused logcat.
  - Parallel signal observed: transient network/DNS failures (`Unable to resolve host firestore.googleapis.com`) during long background window.
- Deterministic repro re-captured on 05/05/2026 with dual logs:
  - `docs/bugs/validation_bug033_2026_04_29/logs/2026-05-05_bug033_android_RMX3771_debug_prod.log`
  - `docs/bugs/validation_bug033_2026_04_29/logs/2026-05-05_bug033_android_RMX3771_logcat_focus.log`
  - Same crash signature present (`ForegroundServiceStartNotAllowedException` + fatal process shutdown) while Android owner remained backgrounded.
- Patched-build closure run (05/05/2026, 19:21-20:45 EDT):
  - `docs/bugs/validation_bug033_2026_04_29/logs/2026-05-05_1921_bug033_9f01491_android_RMX3771_debug_prod.log`
  - `docs/bugs/validation_bug033_2026_04_29/logs/2026-05-05_1921_bug033_9f01491_android_RMX3771_debug_logcat_focus.log`
  - Time-scoped scan for the closure window found no new `ForegroundServiceStartNotAllowedException` / `FATAL EXCEPTION` for Focus Interval.
  - Scenario B (pause-first, multi-hour pause window) completed without crash recurrence or continuity regression.

Workaround:

- No reliable user-facing workaround. App may recover only after relaunch, with possible ownership/state side effects.

Hypothesis:

- Foreground service start/update path is invoked from a background state that Android disallows, causing runtime exception before safe fallback can execute.

Fix applied:

- Runtime fix implemented on 05/05/2026 in `android/app/src/main/kotlin/com/marcdevelopez/focusinterval/PomodoroForegroundService.kt`:
  - Guard `startForeground(...)` with disallowed-start fallback for Android S+ (`ForegroundServiceStartNotAllowedException`) to avoid process crash path and stop service safely.
  - Return `START_NOT_STICKY` from `onStartCommand` to avoid restart-crash loops after disallowed promotion events.
  - Local gate PASS on branch:
    - `flutter analyze`
    - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`

Status:

Closed/OK (05/05/2026). Initial crash evidence + deterministic repro were captured, runtime fix candidate (`9f01491`) was validated in a fresh patched-build run (Scenarios A/B PASS), and no new foreground-service crash signature recurred in the closure window.

---

## BUG-028 — Groups Hub paused card `Ends` projection stays static during pause while scheduled cards continue shifting

ID: BUG-028
Date: 03/04/2026 (UTC+2)
Platforms: Android + macOS
Context: Running group paused with overlap/postpone actions.

Symptom:

- In Groups Hub, paused running card `Ends` can remain frozen while dependent scheduled cards shift after postpone.
- Timeline appears incoherent until resume occurs.

Observed behavior:

- Matrix V20 shows `G2` shifted while paused `G1 Ends` stayed static.
- After resume (V21-V22), `G1 Ends` catches up and coherence returns.
- Same pattern reproduced in later pause/resume cycle (V27 partial).

Expected behavior:

- Timeline projection in Groups Hub should remain coherent during pause windows.
- If scheduled cards update in real time after postpone, paused running `Ends` should follow the same projection rule.

Evidence:

- `docs/bugs/validation_bug025_2026_04_03/plan_validacion_rapida_fix.md` (Visual Evidence Matrix V20-V22, V27; Evidence-Based Verdict F03).

Workaround:

- Resume the paused group and re-open Groups Hub to force projection catch-up.

Hypothesis:

- Paused-card `Ends` projection in Groups Hub is not refreshed with the same cadence/path used for scheduled cards and/or Run Mode projection.

Fix applied:

- Runtime patch on branch `fix/bug028-paused-ends-projection`:
  - `GroupsHub` running/paused card now resolves `Ends` using projected running
    end (`theoreticalEndTime + elapsed pause`) via
    `resolveProjectedRunningEnd(...)` instead of static `theoreticalEndTime`.
  - This keeps paused running cards coherent with postponed scheduled cards
    while pause is active.
- Regression coverage added:
  - `test/presentation/timer_screen_completion_navigation_test.dart`
    (`Groups Hub paused running card updates Ends projection in real time`).
- Specs synchronization:
  - `docs/specs.md` updated in section 10.5 to state projected `Ends` behavior
    for running/paused cards.
- Device validation evidence (27/04/2026, Android owner + macOS mirror):
  - Scenario A/B paused projection coherence observed (`T0` to `T+106s`) with
    moving paused timeline samples (`16:26 -> 16:27 -> 16:28 -> 16:30`).
  - Scenario C resume non-regression observed (`~16:14:57` resume, no collapse).
  - Evidence packet:
    - logs:
      - `docs/bugs/validation_bug028_2026_04_24/logs/2026-04-27_bug028_5df97ec_android_RMX3771_debug.log`
      - `docs/bugs/validation_bug028_2026_04_24/logs/2026-04-27_bug028_5df97ec_macos_debug.log`
    - screenshots:
      - `docs/bugs/validation_bug028_2026_04_24/screenshots/2026-04-27_bug028_scenarioAB_T0_paused_161302_owner_android_mirror_macos.png`
      - `docs/bugs/validation_bug028_2026_04_24/screenshots/2026-04-27_bug028_scenarioAB_Tplus106_paused_161448_owner_android_mirror_macos.png`
      - `docs/bugs/validation_bug028_2026_04_24/screenshots/2026-04-27_bug028_scenarioC_post_resume_161459_owner_android_mirror_macos.png`

Status:

Closed/OK (28/04/2026). Implementation commit: `05b1001`
(`fix(bug-028): project paused ends in Groups Hub and sync validation docs`).
Local gate PASS + device scenarios A/B/C PASS with owner/mirror evidence.

---

## BUG-029 — Scheduling conflict modal escape/navigation ergonomics are inconsistent on Android

ID: BUG-029
Date: 03/04/2026 (UTC+2)
Platforms: Android (owner path), with mirror follow-up impact
Context: Runtime scheduling-conflict modal in Run Mode.

Symptom:

- During active conflict modal, user cannot inspect broader context (Groups Hub) via an explicit in-modal action.
- Exit path observed in validation relied on physical Android back button.

Observed behavior:

- User needed hardware back to temporarily leave modal and inspect Groups Hub context before deciding.
- Modal reappears when returning while conflict remains (functional), but ergonomics are unclear/non-explicit.

Expected behavior:

- Conflict modal flow should expose an explicit, predictable path for context inspection (or a clearly documented strict blocking policy), without relying on hardware-specific escape behavior.

Evidence:

- `docs/bugs/validation_bug025_2026_04_03/plan_validacion_rapida_fix.md` (Visual Evidence Matrix V24-V25 + F04 note).

Workaround:

- Use Android physical back and then re-enter Run Mode to continue conflict resolution.

Hypothesis:

- Modal UX contract is underspecified for inspection/navigation needs during conflict resolution.

Fix applied:

- Not yet.

Status:

Open (03/04/2026), sourced from BUG-025 device validation evidence.

---

## BUG-030 — Mirror auto-opens Run Mode on resume, interrupting Groups Hub/Task List workflow

ID: BUG-030
Date: 27/04/2026 (UTC-4)
Platforms: macOS mirror + Android owner
Context: Account Mode, BUG-028 device validation run with active `G1` running on Android owner while mirror user navigates Groups Hub and Task List.

Classification:

- Regression (Fix 15 auto-open gating, 27/02/2026; dev_log Blocks 485-486).
- Not a planned behavior.

Symptom:

- Mirror is forced back to Run Mode without user intent while navigating planning surfaces.
- User cannot stay in Groups Hub/Task List to complete normal workflow actions.

Observed behavior:

- Repeated auto-open attempts from non-timer routes (`/groups` and `/tasks`) during focus/resume churn while owner session stayed active.
- Flow matched user report: mirror was redirected to Run Mode while trying to plan in Task List / inspect Groups Hub.

Expected behavior:

- If user leaves Run Mode while session is active, auto-open must stay suppressed for that group until a valid new trigger (or explicit user open action).
- Focus/resume events must not override user intent and force route changes from `/groups` or `/tasks`.

Evidence:

- Discovery logs from BUG-028 validation:
  - `docs/bugs/validation_bug028_2026_04_24/logs/2026-04-27_bug028_5df97ec_macos_debug.log`
  - `docs/bugs/validation_bug028_2026_04_24/logs/2026-04-27_bug028_5df97ec_android_RMX3771_debug.log`
- Closure packet logs:
  - `docs/bugs/validation_bug030_2026_04_27/logs/2026-04-28_bug030_24b3667_chrome_debug.log`
  - `docs/bugs/validation_bug030_2026_04_27/logs/2026-04-28_bug030_24b3667_ios_iPhone17Pro_debug.log`

Workaround:

- Re-enter Groups Hub/Task List repeatedly and navigate quickly before next auto-open cycle.
- Not reliable; workflow remains interrupted.

Root cause hypothesis (regression detail):

- `ActiveSessionAutoOpener` defeated user-intent suppression for the same group in three paths:
  1. VM disposal recovery path (`_autoOpenedGroupId == groupId && !vmExists && vmWasAlive`) cleared suppression and set `forceTimerRefresh=true`. This was primary because `PomodoroViewModel` is `autoDispose` when leaving `/timer/:id`.
  2. Resume path (`_resumeAutoOpenPending`) cleared `_autoOpenSuppressedGroupId`.
  3. Bounce-reset path (`_shouldResetAutoOpenForBounce`) could also clear suppression during fast user exits from `/timer/:id`.

Fix applied:

- Runtime fix restored on `develop` via cherry-pick:
  - `30be006` `fix(bug030): preserve intentional-departure suppression and add regression test`.
- Companion test hardening restored on `develop`:
  - `825c09c` `test(bug030): make vmSub close idempotent in BUG-030 case`.
- Validation closure packet completed (28/04/2026):
  - no `Attempting auto-open to TimerScreen` matches in Chrome validation log,
  - suppression retained on planning routes with `departed=...`,
  - explicit timer re-entry from Groups Hub remained functional.

Status:

Closed/OK (28/04/2026). Runtime restored and documented on `develop`; local gate PASS + iOS/Chrome device scenarios A-D PASS.

---

## BUG-031 — Mirror conflict snackbar can remain stale after conflict is resolved

ID: BUG-031
Date: 27/04/2026 (UTC-4)
Platforms: macOS mirror + Android owner
Context: Same BUG-028 validation run. Mirror received conflict warning while owner resolved scheduling conflict.

Classification:

- New bug (not tracked as an open item before 27/04/2026).
- Related domain to BUG-021 (snackbar lifecycle), but different surface
  (running-overlap mirror conflict snackbar).

Symptom:

- Mirror keeps showing the old conflict snackbar (`Owner is resolving this conflict...`) after conflict is already resolved on owner.
- Warning persists across route changes and no longer reflects real conflict state.

Observed behavior:

- After owner resolves/cancels scheduled conflict, mirror continues showing stale snackbar while user navigates Groups Hub and Task List.
- User reports stale snackbar still visible around 16:10:29-16:14:48 despite conflict resolution and scheduled updates.
- Pressing/interacting while stale snackbar is visible can coincide with forced navigation back to Run Mode (see BUG-030), worsening workflow interruption.

Expected behavior:

- Conflict snackbar must auto-dismiss when overlap is no longer valid, decision is cleared/replaced, or user leaves Run Mode.
- Mirror should not keep stale conflict messaging on unrelated screens.

Evidence:

- `docs/bugs/validation_bug028_2026_04_24/logs/2026-04-27_bug028_5df97ec_macos_debug.log` (conflict-flow window 16:10-16:15 UTC-4 + route churn evidence).
- User screenshots in thread show stale snackbar visible while scheduled timeline has already shifted/resolved.
- Closure validation evidence (30/04/2026):
  - `docs/bugs/validation_bug031_2026_04_28/logs/2026-04-30_bug031_f2005cc_ios_iPhone17Pro_debug.log`
  - `docs/bugs/validation_bug031_2026_04_28/logs/2026-04-30_bug031_f2005cc_chrome_debug.log`
  - `docs/bugs/validation_bug031_2026_04_28/screenshots/Captura de pantalla 2026-04-30 a las 15.56.54.png`
  - `docs/bugs/validation_bug031_2026_04_28/screenshots/Captura de pantalla 2026-04-30 a las 15.57.55.png`

Workaround:

- Manual `OK` dismissal or waiting for long snackbar timeout.

Hypothesis:

- Mirror conflict snackbar lifecycle is managed in `TimerScreen` local state only; dismissal synchronization is incomplete when overlap state changes off-screen or when TimerScreen is exited/disposed.

Fix applied:

- Runtime patch in `lib/presentation/screens/timer_screen.dart`:
  - centralized mirror conflict snackbar teardown in `_hideMirrorConflictSnack(...)`,
  - explicit teardown when overlap decision becomes `null`,
  - explicit teardown + decision reset when overlap becomes invalid for current session/groups,
  - mirror snackbar controller/messenger lifecycle hardened to avoid stale local state.
- Regression coverage added in `test/presentation/timer_screen_completion_navigation_test.dart`:
  - `Timer mirror dismisses conflict snackbar when overlap decision clears`.
- Local gate PASS (28/04/2026):
  - `flutter analyze lib/presentation/screens/timer_screen.dart test/presentation/timer_screen_completion_navigation_test.dart`,
  - `flutter test ... --plain-name "Timer mirror shows persistent conflict snackbar until explicit OK"`,
  - `flutter test ... --plain-name "Timer mirror dismisses conflict snackbar when overlap decision clears"`.
- Runtime fix integrated on validation branch: `fix/bug031-validate-on-develop`, commit `f2005cc` (cherry-pick of source patch `f16341f`).
- Device validation PASS (30/04/2026):
  - Scenario A: conflict UX triggered as expected after owner pause.
  - Scenario B: owner `Postpone` cleared mirror stale warning and shifted schedule to `16:03` (pre-run `16:02`).
  - Scenario C: mirror navigation (`Run Mode -> Groups Hub -> Task List -> Run Mode`) stayed clean with no stale conflict warning.

Status:

Closed/OK (30/04/2026). Local gate + iOS/Chrome device scenarios A/B/C PASS. Validation packet synchronized in `docs/bugs/validation_bug031_2026_04_28/`.

---

## BUG-032 — Paused run can be auto-completed after ownership/sleep null-session reconciliation

ID: BUG-032
Date: 28/04/2026 (UTC-4)
Platforms: Android + macOS
Context: Account Mode; ownership transfer after owner sleep/background; paused run reopened after `theoreticalEndTime`.

Symptom:

- A group paused on the new owner device can later appear as `completed` after reopen, even though pause should freeze progression.

Observed behavior:

- Initial owner macOS went to sleep; Android took ownership.
- Android pause action entered a long `Syncing session...` window.
- After background/reopen, the group was shown as completed.
- Firestore evidence reported:
  - `groupId = b21ec7ed-0dc6-40fc-96e6-d7c889f67863`
  - `theoreticalEndTime = 2026-04-28T17:28:36.505348`
  - final `status = completed`
  - `updatedAt = 2026-04-28T17:39:25.578819`

Expected behavior:

- If session is paused, elapsed time must not advance and the group must not auto-complete by expiry checks.
- Reopen must preserve paused state.
- Zombie-run expiry logic must not apply when a relevant active/paused server session exists.

Evidence:

- User-provided runtime logs around reopen/resync (`Resync missing; no session snapshot`, repeated inactive resync loops).
- Firestore snapshot timeline and state metadata for the affected group.
- Validation packet: `docs/bugs/validation_bug032_2026_04_28/plan_validacion_rapida_fix.md`.

Workaround:

- None reliable; once completed is persisted, session resumes as terminal history state.

Hypothesis:

- Coordinator null-session expiry path could complete expired `running` groups without server corroboration, allowing paused executions (or transiently hidden active sessions) to be treated as zombie-run completion candidates.

Fix applied:

- Phase 1 implemented in `scheduled_group_coordinator.dart`:
  - In `activeSession == null` expiry path, fetch server session (`preferServer: true`) before completing.
  - Suppress completion when server reports active execution for the same running group (`session != null`, `status.isActiveExecution`, matching `groupId`).
  - Preserve legitimate zombie-run completion when no relevant server session exists.
- Tests added/updated in `scheduled_group_coordinator_test.dart` for:
  - paused server session guard,
  - foreign-group server session (must not block legitimate completion),
  - existing no-session zombie-run completion behavior.
- Local gate:
  - `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` PASS.
  - `flutter analyze` PASS.
- Device single-run repro PASS (29/04/2026):
  - Test group `a4d46289-18b7-45d1-b8e2-486036a5daff` remained paused after crossing `theoreticalEndTime=2026-04-29T12:23:22.709404`.
  - macOS post-wake logs repeatedly emitted paused expiry guards (`skip-expiry-session-not-running`, `skip-complete`) and no completion write for the group.
  - Firestore post-wake `activeSession` snapshot stayed non-terminal: `status=paused`, `remainingSeconds=722`, `lastUpdatedAt=2026-04-29 12:43:52` (UTC-4), owner `android-029abc12-52ba-4d42-bcca-eda2aaaf257e`.

Status:

Closed/OK (29/04/2026). Phase 1 guard validated on Android + macOS single-run repro with post-wake Firestore corroboration; paused state no longer auto-completes after theoretical end.

## BUG-034 — Shared-mode break/timeline desync between status boxes and contextual task ranges

ID: BUG-034
Date: 01/05/2026 (UTC-4)
Platforms: macOS (primary evidence), Android scope check pending
Context: Run Mode, running group timeline coherence (`integrityMode = shared`).

Symptom:

- In the same transition window, `Next status` predicts `Break: 15 min` but runtime executes `Break: 5 min`.
- After that transition, contextual task-item ranges appear misaligned against status-box ranges and executed phase timeline.

Observed behavior:

- Evidence captures show:
  - pre-transition `Next status` as `Break: 15 min` (`16:21-16:36`),
  - executed break as `Break: 5 min` (`16:21-16:26`),
  - subsequent task timeline (`Curso Develop Flutter`) and contextual ranges not describing one single coherent timeline together with status boxes.
- Reported group metadata:
  - `id=da943ceb-31f9-42b5-b994-235bee6586d0`
  - `integrityMode=shared`
  - `actualStartTime=2026-05-01T10:35:58.957245`
  - `theoreticalEndTime=2026-05-01T17:30:58.957245`
  - `totalPomodoros=13`
  - `noticeMinutes=5`
  - task mix: `3 + 8 + 1 + 1` pomodoros.

Expected behavior:

- In `shared` mode, break insertion must follow a single global pomodoro counter (`longBreakInterval`) across tasks.
- `Next status`, executed phase transitions, status-box ranges, and contextual task-item ranges must all derive from the same authoritative timeline.
- No task-boundary exception may silently switch break logic in one surface but not others.

Evidence:

- User report packet source: `bug.md` (ingested into canonical docs on 01/05/2026).
- Screenshots moved to validation packet:
  - `docs/bugs/validation_bug034_2026_05_01/screenshots/2026-05-01_bug034_next_status_predicts_long_break_161714.png`
  - `docs/bugs/validation_bug034_2026_05_01/screenshots/2026-05-01_bug034_runtime_executes_short_break_162539.png`
  - `docs/bugs/validation_bug034_2026_05_01/screenshots/2026-05-01_bug034_contextual_ranges_desync_163327.png`
- Validation packet opened:
  - `docs/bugs/validation_bug034_2026_05_01/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug034_2026_05_01/quick_pass_checklist.md`
- Fresh closure run evidence (05/05/2026):
  - `docs/bugs/validation_bug034_2026_05_01/logs/2026-05-05_bug034_a636b0f_macos_debug_prod.log`
  - User visual validation confirmed coherent status-box behavior through final task transition in shared mode (no recurrence of original desync).

Workaround:

- No reliable workaround. User can only manually cross-check runtime phase vs contextual list to avoid trusting a single surface.

Hypothesis:

- Break/timeline projection logic is split across runtime/status/contextual-list paths and at least one path is not using shared-mode global break insertion rules.

Fix applied:

- Implemented on 01/05/2026 (`a636b0f`):
  - `TimerScreen` next-status break prediction now uses shared-mode global pomodoro cadence (`usesLongBreakForNextStatus(...)`) instead of per-task-only cadence.
  - `PomodoroViewModel` exposes `currentGlobalPomodoroOffset` for projection parity with runtime logic.
  - Targeted local regression PASS:
    - `flutter test test/presentation/timer_screen_break_prediction_test.dart`
    - `flutter test test/data/models/task_run_group_mode_a_breaks_test.dart`

Status:

Closed/OK (05/05/2026). Fresh long-run visual validation in shared mode completed without desync recurrence, with local regression guardrails still passing.

---

## BUG-035 — macOS keyboard input lock outside Authentication after focus/resume

ID: BUG-035
Date: 04/05/2026 (UTC-4)
Platforms: macOS
Context: Account Mode while already authenticated (for example Google sign-in); user navigates normal app screens and edits text fields (Task Editor, Preset Editor, list flows).

Symptom:

- Keyboard input can become blocked across app screens (not limited to Authentication).
- Pressed characters stop being inserted in text fields until app restart.

Observed behavior:

- Runtime repeatedly emits:
  `A KeyDownEvent is dispatched, but the state shows that the physical key is already pressed`.
- The repeated event often points to a single key (for example `Key P`) with identical event identity/timestamp.
- LoginScreen stale-key repair logic is not involved when the user is already logged in and never visits `/login`.
- Closing and reopening the app restores normal typing (temporary recovery).

Expected behavior:

- Keyboard input must stay usable across all app screens on macOS.
- Focus/resume churn must not leave the app in a stuck-key state requiring restart.

Evidence:

- User runtime log excerpt (04/05/2026) showing repeated duplicate key-down exceptions while typing fails in non-login screens.
- Existing implementation inspection:
  - `lib/presentation/screens/login_screen.dart` stale-key repair currently scoped to Authentication lifecycle/taps.
- Validation packet opened:
  - `docs/bugs/validation_bug035_2026_05_04/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug035_2026_05_04/quick_pass_checklist.md`

Workaround:

- Restart the macOS app.

Hypothesis:

- Flutter `HardwareKeyboard` pressed-key map can remain stale after macOS focus transitions.
- Because repair is currently scoped to LoginScreen only, authenticated flows never run the repair and stale keys remain latched globally.

Fix applied:

- Branch: `fix/bug035-macos-global-keyboard-repair`
- Runtime patch:
  - Added app-level macOS keyboard repair wrapper (`MacOsKeyboardStateRepair`) in `MaterialApp.builder` chain.
  - Repair runs on app bootstrap and on `AppLifecycleState.resumed`.
  - Wrapper has its own in-instance concurrency guard and synthesizes `KeyUpEvent` for stale pressed keys by reconciling `HardwareKeyboard` vs `SystemChannels.keyboard/getKeyboardState`.
  - Existing LoginScreen repair remains in place as local defense in depth.

Status:

Closed/OK (04/05/2026). Implementation commit `88e0bb1` validated with:
- local gate PASS (`flutter analyze`, `flutter test test/presentation/timer_screen_completion_navigation_test.dart`);
- macOS quick execution PASS log (`docs/bugs/validation_bug035_2026_05_04/logs/2026-05-04_bug035_4b1c94a_macos_debug.log`) without stuck-key signature matches;
- explicit user acceptance in thread under the documented non-deterministic repro waiver.
