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

Observed moment: Pomodoro 2, ~13 minutes remaining.

Evidence (Firestore state at failure):
- status: pomodoroRunning
- phase: pomodoro
- ownerDeviceId: macOS
- remainingSeconds: ~624
- lastUpdatedAt: 13/02/2026 15:08:36 (UTC+1)

Evidence (after foreground):
- remainingSeconds: ~470
- lastUpdatedAt: 13/02/2026 15:11:10 (UTC+1)

Expected behavior:
Never show Ready if activeSession is running. During stream gaps, show
"Syncing session...".

Hypothesis:
Temporary activeSession stream gaps on Android are interpreted as missing
sessions. Gaps exceeding the 45s stale threshold can drop to Ready.

Fix applied:
Branch: bug-mirror-ready-screen
Change: Guard in PomodoroViewModel keeps Syncing based on last session +
lastUpdatedAt (45s).

Status:
Validation pending on Android. Reproduced intermittently.

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

Workaround:
- Navigate Android to Groups Hub and back to force re-sync.
- Use Retry in the ownership sheet to re-issue the request.

Hypothesis:
- Ownership request UI state is not cleared/overridden after rejection when the
  requester resumes from background; local pending state or session-gap handling
  may mask the latest snapshot.

Fix applied:
None.

Status:
Open. Reproduced in real device test (Android + macOS). High priority.

---

## BUG-003 — Mirror flicker every ~15s on macOS after Android pause/resume

ID: BUG-003
Date: 13/02/2026 (UTC+1)
Platforms: macOS mirror + Android owner
Context: Planned group scheduled by time range. Initial state Android mirror,
macOS owner. During a break, Android is backgrounded, then foregrounded and
eventually becomes owner. Android pauses ~1 minute and then resumes; macOS moves
to mirror.

Symptom:
- macOS mirror flicks/rebuilds UI about every ~15s after Android pause/resume.

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

Hypothesis:
- Periodic resubscribe/refresh may trigger a full Run Mode rebuild even when
  derived values are unchanged.

Fix applied:
None.

Status:
Open. Low priority unless fix can be made without regressions.

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

Expected behavior:
- Mirror projection should stay within a small, stable tolerance from the owner
  (no accumulating drift over time).

Evidence:
- Screenshots around 23:42 show Android at 07:41 while macOS shows 07:47
  (same wall clock), indicating ~6s delta.
- Firestore snapshot (UTC+1) 23:41:28 shows `status = longBreakRunning`,
  `remainingSeconds = 507` while Android displayed fewer seconds than macOS.

Hypothesis:
- Mirror projection may be using a local clock without correction for snapshot
  cadence or server time offset, causing accumulating drift during long phases.

Fix applied:
None.

Status:
Open. Medium priority (visible correctness issue).

---

## BUG-005 — Ownership request not surfaced while macOS window inactive

ID: BUG-005
Date: 13/02/2026 (UTC+1)
Platforms: macOS owner + Android mirror
Context: Planned group scheduled by time range. macOS is owner. Android requests
ownership while macOS window is inactive (other app focused).

Repro steps:
- Keep macOS as owner and move focus to another app (window inactive).
- From Android mirror, request ownership.
- Observe macOS UI; then click/focus the macOS window.

Symptom:
- Ownership request does not appear on macOS until the app window is focused.

Observed behavior:
- Android shows a pending ownership request, but macOS displays no modal/banner.
- After clicking/focusing the macOS window, the ownership request appears.

Expected behavior:
- Ownership requests should surface even when the window is inactive (or at
  least show a clear inactive-state indicator).

Evidence:
- 23:44:01 requestId `d4834ac2-...` pending while Android showed the request;
  macOS only displayed the modal after window focus.

Workaround:
- Click/focus the macOS window to surface pending requests.

Hypothesis:
- Inactive-window keepalive/resubscribe is not firing or request UI is gated
  behind an active-focus check.

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
