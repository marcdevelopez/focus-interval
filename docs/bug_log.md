# Bug Log — Focus Interval (MVP 1.2)

Central log of observed bugs. Keep entries in chronological order with newest
at the end.

Entry format:
- ID:
- Date (with UTC offset):
- Platforms:
- Context:
- Symptom:
- Observed behavior:
- Expected behavior:
- Evidence:
- Hypothesis:
- Fix applied:
- Status:

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
