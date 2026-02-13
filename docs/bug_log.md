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

Symptom:
- Android mirror can remain in requested/Ready after ownership rejection and
  become visually desynced from activeSession; requires navigation to Groups Hub
  and back to resync.

Observed behavior:
- Condensed sequence:
  - Android backgrounded during break (app not closed), then foregrounded.
  - Android requests ownership; macOS rejects; Android requests again.
  - After rejection(s), Android UI shows Ready or stale requested state while
    Firestore reports an active running session.
- After ownership request rejection, Firestore shows
  `ownershipRequest.status = rejected` with `respondedByDeviceId = macOS...`,
  but Android stays in Ready or shows stale requested state.
- During desync, Firestore still shows `activeSession.status = pomodoroRunning`
  and `remainingSeconds` continues to decrease.
- Android only resyncs after leaving Run Mode to Groups Hub and returning; then
  the rejection snackbar appears and mirror view updates.

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
