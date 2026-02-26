# 📘 **Functional Specifications – Cross-Platform Pomodoro App (macOS / Windows / Linux / iOS / Android / Web)**

**Version 1.2.0 — MVP Release Document**

---

# 🧭 **1. Project overview**

The app is an advanced Pomodoro session manager built with Flutter, targeting desktop and mobile.

The main goals are:

- Create fully configurable Pomodoro tasks
- Organize tasks into TaskRunGroups (ordered execution groups)
- Plan or start a group immediately with conflict-free scheduling
- Run tasks sequentially without manual intervention
- Save and sync tasks/groups in the cloud (Firestore)
- Sync Pomodoro execution in real time across devices (single session owner, others in mirror mode)
- Play internal app sounds for state changes (notifications remain silent; web is best-effort per browser/OS)
 - Presets: reusable Pomodoro configurations (durations, breaks, sounds) usable across tasks

The app syncs with Firebase via Google Sign-In on iOS/Android/Web, email/password on macOS/Windows, and optional GitHub Sign-In where supported. A first-class Local Mode (offline, no auth) is available on all platforms and can be toggled at any time.

---

# 🖥️ **2. Target platforms**

- macOS (Intel & Apple Silicon)
- Windows 10/11 Desktop
- Linux GTK-based distros (Ubuntu, Fedora, etc.)
- iOS
- Android
- Web (Chrome)

---

# 🔥 **3. Core technologies**

| Area                   | Technology                                                                        |
| ---------------------- | --------------------------------------------------------------------------------- |
| UI Framework           | Flutter 3.x                                                                       |
| Auth                   | Firebase Authentication (Google Sign-In, optional GitHub Sign-In, email/password) |
| Backend                | Firestore                                                                         |
| Local Cache (optional) | SharedPreferences (Local Mode storage); Hive (v1.2)                               |
| State Management       | Riverpod                                                                          |
| Navigation             | GoRouter                                                                          |
| Audio                  | just_audio                                                                        |
| Notifications          | flutter_local_notifications                                                       |
| Logging                | debugPrint (MVP); logger (post-MVP)                                               |
| Architecture           | MVVM (Model–View–ViewModel)                                                       |

---

# 📦 **4. General architecture**

```
lib/
├─ app/
│   ├─ router.dart
│   ├─ theme.dart
│   └─ app.dart
├─ data/
│   ├─ models/
│   │   ├─ pomodoro_task.dart
│   │   ├─ task_run_group.dart
│   │   └─ pomodoro_session.dart
│   ├─ repositories/
│   │   ├─ task_repository.dart
│   │   ├─ task_run_group_repository.dart
│   │   └─ pomodoro_session_repository.dart
│   └─ services/
│       ├─ firebase_auth_service.dart
│       ├─ firestore_service.dart
│       ├─ notification_service.dart
│       └─ sound_service.dart
├─ domain/
│   ├─ pomodoro_machine.dart
│   └─ validators.dart
├─ presentation/
│   ├─ screens/
│   │   ├─ login_screen.dart
│   │   ├─ task_list_screen.dart
│   │   ├─ task_editor_screen.dart
│   │   ├─ timer_screen.dart
│   │   └─ planned_groups_screen.dart
│   ├─ viewmodels/
│   │   ├─ pomodoro_view_model.dart
│   │   ├─ task_editor_view_model.dart
│   │   ├─ task_list_view_model.dart
│   │   └─ scheduled_group_coordinator.dart
│   ├─ providers.dart
│   └─ flutter_riverpod.dart
├─ widgets/
│   ├─ linux_dependency_gate.dart
│   ├─ timer_display.dart
│   ├─ task_card.dart
│   └─ sound_selector.dart
└─ main.dart
```

---

# 🧩 **5. Data model**

## **5.1. PomodoroTask model**

```dart
class PomodoroTask {
  String id;
  String name;
  int dataVersion; // schema version (integer)
  String? colorId; // palette id; auto-assigned when missing

  int pomodoroMinutes; // minutes (legacy key: pomodoroDuration)
  int shortBreakMinutes; // legacy key: shortBreakDuration
  int longBreakMinutes; // legacy key: longBreakDuration

  int totalPomodoros;
  int longBreakInterval; // how many pomodoros between long breaks

  String startSound;
  String startBreakSound;
  String finishTaskSound;

  DateTime createdAt;
  DateTime updatedAt;

  PomodoroTask({
    required this.id,
    required this.name,
    required this.dataVersion,
    this.colorId,
    required this.pomodoroMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.totalPomodoros,
    required this.longBreakInterval,
    required this.startSound,
    required this.startBreakSound,
    required this.finishTaskSound,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

## **5.2. TaskRunGroup model (snapshot execution group)**

A TaskRunGroup is an immutable snapshot generated when the user confirms a set of tasks to run. It is independent from the editable task list.

```dart
class TaskRunGroup {
  String id;
  String ownerUid;
  int dataVersion; // schema version (integer)
  String name; // user-visible group name (max 40 chars)
  String integrityMode; // shared | individual (Mode A / Mode B)

  List<TaskRunItem> tasks; // ordered snapshots
  DateTime createdAt;

  DateTime? scheduledStartTime; // null when "Start now"
  String? scheduledByDeviceId; // device that initiated schedule or start
  String? postponedAfterGroupId; // when set, schedule follows another group
  DateTime? lateStartAnchorAt; // server anchor for late-start queue projections
  String? lateStartQueueId; // shared id for the late-start queue (conflict set)
  int? lateStartQueueOrder; // order index within the late-start queue
  String? lateStartOwnerDeviceId; // device that owns the late-start queue
  DateTime? lateStartOwnerHeartbeatAt; // heartbeat for stale owner detection
  String? lateStartClaimRequestId; // pending ownership request id
  String? lateStartClaimRequestedByDeviceId; // device requesting ownership
  DateTime? lateStartClaimRequestedAt; // when ownership was requested
  DateTime theoreticalEndTime;  // required for overlap checks

  String status; // scheduled | running | completed | canceled
  String? canceledReason; // user | conflict | interrupted | missedSchedule
  int? noticeMinutes; // per-group pre-alert override

  // Optional derived fields (for list rendering):
  int? totalTasks;
  int? totalPomodoros;
  int? totalDurationSeconds;

  DateTime updatedAt;
}
```

```dart
class TaskRunItem {
  String sourceTaskId; // reference to original task
  String name;
  String? colorId; // palette id snapshot (for stable visuals in the group)
  String? presetId; // optional reference to the preset used for structure

  int pomodoroMinutes;
  int shortBreakMinutes;
  int longBreakMinutes;
  int totalPomodoros;
  int longBreakInterval;

  String startSound;
  String startBreakSound;
  String finishTaskSound;
}
```

Notes:

- theoreticalEndTime is calculated when the group is scheduled or started, using scheduledStartTime (if set) or now (for immediate start). Recalculate if the start time changes.
- postponedAfterGroupId marks a scheduled group as following another group. While the anchor group is running/paused, the effective scheduledStartTime is derived as anchorEnd + noticeMinutes, and pre-run begins at anchorEnd. When the anchor group ends, the schedule is locked in and postponedAfterGroupId is cleared.
- lateStartAnchorAt is a server timestamp written when the late-start overlap queue is triggered. It is used to anchor projected ranges across devices (consistent projections). It should be cleared when the queue is resolved (confirmed or canceled).
- lateStartQueueId is a shared identifier for the conflict set (same for all queued groups).
- lateStartQueueOrder defines the current ordering for queued groups (used for display and chain-postpone).
- lateStartOwnerDeviceId + lateStartOwnerHeartbeatAt define the queue owner and allow stale detection (>=45s).
- lateStartClaimRequestId / lateStartClaimRequestedByDeviceId / lateStartClaimRequestedAt define a pending ownership request while the owner is active.
- During execution, theoreticalEndTime must be extended by **total pause offsets**
  (cumulative paused time). The owner updates this on resume so all devices share
  the same projected end.
- Expected lifecycle: scheduled -> running -> completed (or canceled).
- Conceptual pre-run state: scheduled -> preparing -> running (preparing is UI-only and does not change the model).
- A scheduled group must transition to running at scheduledStartTime.
- When a group transitions to running (scheduled auto-start or start now),
  set `scheduledByDeviceId` to the initiating device.
  `scheduledByDeviceId` is metadata only and must not block auto-start or ownership.
- Run Mode must start through a single, unified pipeline regardless of entry
  (Start now, Run again, scheduled auto-start). The pipeline must provide
  the new group snapshot to Run Mode to avoid read-race bounces on immediate
  navigation.
- Editing a PomodoroTask after group creation does not affect a running or scheduled group.
- TaskRunGroup names:
  - New groups must have a name. If the user leaves the name empty, auto-generate one at confirm time using local date/time in English (e.g., "Jan 1 00:00", 24h).
  - Names are **not** required to be unique. If the final name matches an existing group name, append a short date/time suffix to the new group name: " — dd-MM-YYYY HH:mm".
  - Enforce a max length of 40 characters. If a suffix is added and the name exceeds 40, truncate the base name and add an ellipsis so the suffix still fits.
  - Groups created before this feature may have no stored name. In that case, display a derived name built from task names and truncate to 40 characters (with ellipsis).
- integrityMode:
  - Stored on the TaskRunGroup at creation time based on the Pomodoro Integrity selection.
  - **shared** = Mode A (Shared structure, global pomodoro counter across the group).
  - **individual** = Mode B (Keep individual configurations, per-task counters).

## **5.3. PomodoroSession model (live sync)**

```dart
class PomodoroSession {
  String id; // sessionId
  String groupId;        // TaskRunGroup in execution
  String currentTaskId;  // TaskRunItem.sourceTaskId
  int currentTaskIndex;
  int totalTasks;
  int dataVersion; // schema version (integer)

  String ownerDeviceId; // device that writes in real time
  String? ownerDevicePlatform; // presentation-only label (e.g., "Web", "macOS")

  PomodoroStatus status; // pomodoroRunning, shortBreakRunning, longBreakRunning, paused, finished, idle
  PomodoroPhase? phase;
  int currentPomodoro;
  int totalPomodoros;

  int phaseDurationSeconds; // duration of the current phase
  int remainingSeconds;     // required for paused; running is projected from phaseStartedAt
  DateTime phaseStartedAt;  // serverTimestamp on start/resume (phase progress only)
  DateTime? currentTaskStartedAt; // actual start of the current task (for time ranges)
  DateTime? pausedAt;       // serverTimestamp when pause begins (status == paused)
  DateTime lastUpdatedAt;   // serverTimestamp of the last event
  DateTime? finishedAt;     // serverTimestamp when the group reaches completed
  String? pauseReason;      // optional; "user" when paused manually

  OwnershipRequest? ownershipRequest; // optional transfer request (mirror -> owner)
}

class OwnershipRequest {
  String? requestId; // unique id to reconcile optimistic vs remote (optional for legacy)
  String requesterDeviceId;
  DateTime requestedAt;
  String status; // pending | rejected
  DateTime? respondedAt;
  String? respondedByDeviceId;
}
```

Notes:

- `requestId` is **required for new requests** and is used to reconcile optimistic
  pending UI with remote snapshots. A rejected request with a **different**
  `requestId` must **not** clear a newer pending request from the same device.
- `phaseStartedAt` is **only** for phase progress/projection; it must never anchor
  task/group time ranges.
- `currentTaskStartedAt` is authoritative for the active task start and must be
  published by the owner whenever the task changes.
- `pausedAt` is required to compute cross-device pause offsets when any device resumes.

## **5.4. UserProfile model (Account Mode only)**

```dart
class UserProfile {
  String uid;
  String? displayName; // optional user-provided name
  String? avatarUrl;   // Firebase Storage download URL (optional)
  DateTime updatedAt;
}
```

Notes:

- displayName is optional; empty values are treated as unset.
- UserProfile is presentation-only and must never drive ownership, permissions, or state transitions.
- Full owner label is derived as "{displayName or Account} (Platform)" where Platform is the owner device platform label.
- Local Mode has no profile document; the UI hides profile controls when not logged in.

## **5.5. Schema versioning (dataVersion)**

- All persisted documents must include an integer `dataVersion`.
- Applicable models: PomodoroTask, TaskRunGroup, PomodoroSession, PomodoroPreset.
- Clients must tolerate missing `dataVersion` and default to version 1.
- Migrations are additive and use dual-read/dual-write + backfill (see `docs/release_safety.md`).

---

# 🧠 **6. Pomodoro logic (state machine)**

## **6.1. States**

- pomodoroRunning
- shortBreakRunning
- longBreakRunning
- paused
- finished
- idle

## **6.2. Transitions (within a single task)**

1. Start pomodoro → pomodoroRunning
2. Finish pomodoro:
   - If current number % longBreakInterval == 0 → longBreakRunning
   - Otherwise → shortBreakRunning
3. Finish break → next pomodoro
4. Finish the last pomodoro of the task → task completes (the group continues if there is a next task)
5. User can:
   - Pause
   - Resume
   - Cancel

## **6.3. TaskRunGroup execution flow**

- A group starts with the first TaskRunItem.
- When a task completes:
  - If there is a next task: auto-transition to the first pomodoro of the next task.
  - No modal/popup is shown between tasks.
- Mode-specific break behavior:
  - **Mode A (Shared structure):** the group behaves as a **single continuous Pomodoro sequence**.
    - Breaks occur **between all pomodoros** using the shared configuration.
    - The long-break interval is counted **globally across tasks**.
    - Task boundaries do **not** add extra breaks; they just switch the active task label.
  - **Mode B (Keep individual configurations):** each task keeps its own break structure.
    - If another task follows, execute a break after the task ends:
      - Short break by default.
      - Long break if that task’s pomodoro count reaches its long-break interval.
- When the last task completes:
  - The group ends (status = completed).
  - Final modal + final animation are shown (see section 12).
  - After the user explicitly dismisses the completion modal, auto-navigate to the Groups Hub screen (no time-based auto-navigation).
  - If a new group auto-opens (pre-run or run) while the completion modal is visible, the modal auto-dismisses and must not block the new run.
- If the user cancels a running group:
  - The group ends immediately (status = canceled, canceledReason = user).
  - The active session is cleared.
  - The app must not remain in an idle Run Mode state.
  - Navigate to Groups Hub after confirmation (see section 10.4.6).

## **6.4. Scheduling and conflict rules**

Overlap definition

Two groups conflict if:

```
[newStart, newEnd) ∩ [existingStart, existingEnd) ≠ ∅
```

Where end = theoreticalEndTime.

Rules

- If a group is running:
  - Cannot schedule another group
  - Cannot start another group
  - Options: cancel the running group, or cancel the new action
- If a group is scheduled:
  - Show conflict
  - Options: delete the existing schedule, or cancel the new schedule

These conflict checks apply to both Start now and Schedule start.

Scheduled start behavior

- Send the pre-alert noticeMinutes before scheduledStartTime.
- On supported platforms, schedule the pre-alert notification at planning time
  so it can fire even when the app is closed.
- Windows/Linux/Web: no background pre-alert scheduling in MVP; pre-alerts are best-effort and require the app to be open.
- Android uses AlarmManager to schedule the pre-alert so it can fire with the app closed.
- If the app is open during the pre-alert window, show the Pre-Run Countdown Mode (see section 10.4.1.a).
- If the app is closed during the pre-alert window, send a silent notification on platforms with background scheduling (Android/iOS/macOS).
  On Windows/Linux/Web, no system notification is sent while closed.
- Auto-start requires at least one device for the account to be active/open at or after scheduledStartTime.
- If all devices are closed at scheduledStartTime, the group does not start until the next launch/resume
  on any signed-in device for that account (scheduledStartTime remains unchanged).
- At scheduledStartTime:
  - Set status = running.
  - Set actualStartTime = now.
  - Recalculate theoreticalEndTime = actualStartTime + totalDurationSeconds.
  - Automatically open the execution screen and start the group.
  - Ownership is claimed by the first active device that starts the session (if multiple devices are open).
- If the app was inactive at scheduledStartTime:
  - On next launch/resume of any signed-in device, if scheduledStartTime <= now and there is no active conflict,
    auto-start immediately using actualStartTime = now.
  - scheduledStartTime remains as historical data and is not overwritten unless the user explicitly
    reschedules the group via conflict resolution.

Late-start and overlap resolution (Account Mode)

Purpose: make delayed auto-start and long pauses deterministic, with explicit user control.

- Owner decision only. If no owner is active, the first active device auto-claims ownership
  before presenting any decision UI (mirrors remain view-only).
  - "Owner active" is defined by a recent `lateStartOwnerHeartbeatAt`. If the heartbeat is missing,
    treat the owner as active for a short grace window based on `lateStartAnchorAt` before allowing auto-claim.

Late-start overlap resolution (no running group)

- Trigger: app launch/resume with **one or more** overdue scheduled groups
  (scheduledStartTime <= now) and no running group.
- Overdue scheduled groups **do not expire**; they must be resolved explicitly by the user.
- If there is exactly **one** overdue group and starting it now does **not**
  overlap any other scheduled group, auto-start proceeds as usual.
- If starting an overdue group now would overlap any other scheduled group
  (overdue or future), open the **late-start overlap queue** (see section 10.4.1.b).
- In the queue flow, the user may select any subset (including none) and define
  their order. The first selected group starts immediately (no pre-run); the
  remaining selected groups are rescheduled sequentially with their pre-run
  windows preserved.
- Any unselected groups are canceled:
  - If scheduledStartTime <= now → canceledReason = missedSchedule.
  - If scheduledStartTime > now → canceledReason = conflict.
- If none are selected and confirmed, cancel all groups in the conflict set
  using the same reason rules.

Conflict-resolution write safety

- Any multi-group cancel/reschedule operation must be applied via a single
  Firestore batch/transaction.
- If the batch fails, show a blocking error and keep the flow open for retry;
  do not start or resume any group until the intended updates succeed.
- If a partial update is detected on re-open (e.g., some groups updated and
  others not), re-enter the queue flow and require the owner to reconcile
  before continuing.

Long-pause overlap (running/paused group vs next scheduled)

- Trigger: a group is running or paused, and the next scheduled group's pre-run window
  begins while the current group is still projected to be active.
- Immediately present a conflict modal (see section 10.4.1.c). The modal **pauses**
  the current group and counts as a normal user pause (affects pause offsets).
- Options:
  - End current group now → mark current group canceled (canceledReason = interrupted),
    then proceed with the scheduled group's pre-run/start.
  - Postpone the scheduled group → reschedule it to start after the current group ends,
    preserving its pre-run window (noticeMinutes). Update scheduledStartTime and
    theoreticalEndTime, then revalidate conflicts (repeat if necessary).
  - Cancel the scheduled group → mark it canceled (canceledReason = conflict) and
    continue the current group.

---

# 🔊 **7. Sound system**

Configurable sound events in the current MVP:

| Event            | Sound                          |
| ---------------- | ------------------------------ |
| Pomodoro start   | startSound                     |
| Break start      | startBreakSound                |
| End of each task | finishTaskSound                |
| End of group     | finishTaskSound (same for now) |

Behavior notes:

- The end-of-task sound plays on each task completion and must not pause or block the automatic transition.
- Only the final task of the group triggers the stop behavior (see section 12).
- To avoid overlapping audio, there are no separate sounds for pomodoro end or break end in this MVP.
- Post-MVP: add distinct sounds for pomodoro end and break end.

Allowed formats:

- .mp3
- .wav

Sounds can be:

- Included in the app (assets)
- Or loaded by the user (local file picker)

Note:

- In this MVP, custom local picks are supported for **Pomodoro start** and
  **Break start** only; **Task finish** uses built-in choices.

Platform notes:

- Windows audio uses an `audioplayers` adapter via SoundService.
- Other platforms use `just_audio`.

---

# 💾 **8. Persistence and sync**

## **8.1. Firestore (primary)**

- users/{uid} (profile doc)
  - displayName (optional)
  - avatarUrl (optional)
  - updatedAt
- users/{uid}/tasks/{taskId}
- users/{uid}/taskRunGroups/{groupId}
- users/{uid}/pomodoroPresets/{presetId}
- Linux: Firebase Auth/Firestore sync is unavailable; tasks and TaskRunGroups are stored locally (no cloud sync).
  - Rationale: FlutterFire plugins (`firebase_auth`, `cloud_firestore`) do not officially support Linux desktop,
    so Account Mode is disabled to avoid unstable behavior. Use Web (Chrome) on Linux for Account Mode.

## **8.1.1. Firebase Storage (account avatars)**

- Path: user_avatars/{uid}/avatar.jpg (single object; overwrite on update).
- Client must resize/compress to <= 200 KB before upload (target max 512px).
- Store the download URL in users/{uid}.avatarUrl.
- Removing the avatar clears avatarUrl and deletes the storage object (best-effort).
- Account Mode only; hide avatar controls in Local Mode.

## **8.2. Local Mode (offline / no auth)**

- Local Mode is a first-class backend available on all platforms.
- Users can explicitly choose between Local Mode (offline, no login) and Account Mode (synced).
- Local data uses the exact same models (tasks, TaskRunGroups, sessions) for future compatibility.
- Presets are stored locally alongside tasks (SharedPreferences in MVP; Hive planned for v1.2).
- MVP note: Local Mode does not persist active PomodoroSession yet. If the app relaunches while a group is running, the UI projects progress from TaskRunGroup.actualStartTime (no pause reconstruction).
- UX note: In Local Mode, pressing Pause immediately pauses and shows a lightweight, translucent informational dialog (single acknowledgement) explaining that closing the app while paused will not preserve the pause; on reopen the timer resumes from the original start time. The dialog is informational only and does not change pause behavior.
- While paused in Local Mode, provide a discreet info affordance near Pause/Resume that can re-open the same explanation on demand. Do not add persistent banners or vertical layout shifts on the Execution screen.
- Local Mode scope is strictly device-local; Account Mode scope is strictly user:{uid}.
- There is no implicit sync between scopes.
- Switching to Account Mode can offer a one-time import of local data (tasks, groups, presets)
  only after explicit user confirmation.
- Import targets the currently signed-in UID and overwrites by ID (no merge) in MVP 1.2.
- Switching back to Local Mode keeps local data separate and usable regardless of login state.
- Logout returns to Local Mode without auto-import or auto-sync.
- Logout while a group is running or paused must always land on a valid Local Mode screen
  (Task List). Never leave a blank/black screen; clear any Run Mode routes first.

## **8.3. Local cache (optional)**

- Current: SharedPreferences-backed storage for Local Mode tasks and TaskRunGroups.
- Planned (v1.2): Hive-based cache for cross-platform offline storage.

## **8.4. Active Pomodoro session (real-time sync)**

users/{uid}/activeSession

- Single document per user with the active session.
- Must include groupId, currentTaskId, currentTaskIndex, and totalTasks.
- ownerDevicePlatform is optional display metadata (presentation-only); it must not affect ownership logic.
- Only the owner device writes authoritative execution fields; others subscribe in real time and
  render progress by calculating remaining time from phaseStartedAt + phaseDurationSeconds using
  a server-time offset derived from lastUpdatedAt (do not rely on raw local clock).
  - Compute `serverTimeOffset = lastUpdatedAt - localNow` when a snapshot arrives.
  - Project with `serverNow = localNow + serverTimeOffset`, `elapsed = serverNow - phaseStartedAt`.
  - Update the offset on each new snapshot; keep the last offset between ticks.
  - If `lastUpdatedAt` is missing, keep the prior offset and do not rebase from local time alone.
- Mirror devices may write a non-authoritative ownershipRequest field to request a transfer.
  - `requestOwnership` only creates/updates ownershipRequest; it never changes ownerDeviceId.
    Ownership changes caused by staleness must use the auto-claim transaction.
  - If the owner is active (lastUpdatedAt within the stale threshold), the owner must
    explicitly accept or reject.
  - If the owner is inactive (lastUpdatedAt older than the stale threshold):
    - **Running:** any mirror device may auto-claim ownership **without** a manual request.
      If an ownershipRequest exists, the requester has priority; otherwise the first
      mirror to detect staleness claims ownership atomically and clears ownershipRequest.
    - **Paused:** no automatic takeover without a manual request. If the requester has a
      pending ownershipRequest and the owner is stale, the requester auto-claims immediately.
- When resuming from a paused session, the owner must extend the TaskRunGroup
  theoreticalEndTime by the pause duration (`now - pausedAt`) before continuing.
- Resume must update **both** the TaskRunGroup and activeSession in a single
  atomic operation (batch/transaction). If the update fails, keep the session
  paused and show a blocking error; do not resume locally until the write succeeds.
- The owner device must publish heartbeats (lastUpdatedAt) at least every 30s while
  a session is active (running or paused) to signal liveness.
- Android: keep the ForegroundService active while paused (owner only) so heartbeats
  continue even when the app is backgrounded.
- activeSession represents only an in-progress execution and must be cleared when the group reaches a terminal state (completed or canceled).
- If a group is **running or paused locally** but `activeSession` is missing (no doc
  or stream gap), the **owner device** must attempt to republish the session
  (owner-only, no overwrite). Use `tryClaimSession` to create the doc if missing,
  then publish normally. Rate-limit recovery attempts (e.g., >=5s between tries).
  Mirror devices must never publish during this recovery path.
- If a device observes an activeSession referencing a group that is not running (or missing), it must treat the session as stale and clear it.
- If a running group has passed its theoreticalEndTime and the activeSession has not updated within the stale threshold, any device may clear the session and complete the group to prevent zombie runs.
- Do not expire/complete running groups while the activeSession stream is still loading
  (unknown session state). Expiry checks may only run after at least one session snapshot
  has been observed.
- Expiry/cleanup is only allowed when the activeSession exists, is **running**, and
  its groupId matches the running group being evaluated. If the session is missing,
  paused, or belongs to a different group, do not complete.
- Repositories must **never** auto-complete groups based on time during reads/streams.
  Status changes only occur through the coordinator/viewmodel expiry rules above.
- Stale threshold definition (activeSession + ownership): 45 seconds without
  lastUpdatedAt updates (≈1-2 heartbeats).
- If `lastUpdatedAt` is temporarily missing (e.g., server timestamp not yet
  materialized), treat the session as **not stale**. Do not auto-claim or clear
  the session until a concrete timestamp is available.
- On app launch or after login, if an active session is running (pomodoroRunning/shortBreakRunning/longBreakRunning), auto-open the execution screen for that group.
- Auto-open must apply on the owner device and on mirror devices (mirror mode with ownership requests).
- If auto-open cannot occur (missing group data, blocked navigation, or explicit suppression), the user must see a clear entry point to the running group from the initial screen and from Groups Hub.

## **8.5. TaskRunGroup retention**

- Keep:
  - All scheduled
  - The current running
  - The last N completed
- Canceled groups are retained **separately** and must **never** count against
  completed retention.
  - They must remain visible in Groups Hub to allow re-planning.
  - Keep a separate cap for canceled groups (default = same N as completed).
- N is finite and configurable.
- Default: 7 completed groups (last week).
- User-configurable up to 30.

---

# 🔐 **9. Authentication**

Account Mode (by platform)

- iOS / Android / Web:
  - Button: “Continue with Google”
  - Opens browser or WebView
  - Gets uid, email, displayName, photoURL
  - Optional: “Continue with GitHub” (OAuth in browser/WebView)
  - If GitHub is unavailable on a given platform, do not show the option
- macOS / Windows:
  - Email/password login (no Google Sign-In)
  - Gets uid, email (and optionally name)
  - Optional: GitHub sign-in via browser-based OAuth (if supported)
  - If not supported, omit GitHub and keep email/password only
- Linux:
  - Firebase Auth is unavailable; Account Mode is disabled
  - Local Mode is the default

GitHub Sign-In platform constraints

- Web: OAuth in browser (supported)
- iOS / Android: OAuth in browser or WebView (supported)
- macOS / Windows: browser-based OAuth requires a backend code exchange (manual GitHub OAuth flow)
- Linux: unavailable (Account Mode disabled)

Mode selection

- Users can choose Local Mode without login on any platform.
- Users can switch between Local Mode and Account Mode at any time.
- GitHub login is an optional Account Mode provider that yields the same uid identity as other providers (not a separate account system).
  - If GitHub is not supported on a platform, fall back to existing providers without changing Local Mode.
- If the user tries to sign in with a provider and the email already exists under a different provider, the app must guide the user to sign in with the original provider and then link the new provider (account linking).

Desktop GitHub OAuth (device flow)

- Required on macOS/Windows because FirebaseAuth `signInWithProvider` is not supported on macOS and is not reliable on Windows.
- Flow:
  1) App requests a device code from GitHub.
  2) App opens the verification URL in the system browser and shows the user code.
  3) User enters the code in GitHub.
  4) App polls GitHub until an access token is issued.
  5) App signs in to Firebase with `GithubAuthProvider.credential(accessToken)`.
- No backend is required (device flow does not need a client secret).
- Desktop app configuration:
  - `GITHUB_OAUTH_CLIENT_ID` (dart-define)

Persistence

- Account sessions remain active on all devices with Firebase Auth support.
- Web uses Firebase Auth local persistence (LOCAL) to restore sessions across reloads.
- Development note: when running via `flutter run -d chrome`, a stable Chrome
  user-data directory is required to keep sessions between runs.

Email verification (email/password)

- Require email verification to confirm ownership of the address before enabling sync.
- Unverified accounts must not block real owners from registering later.

Account profile metadata

- Account display name and avatar are stored in users/{uid} (Firestore) and Firebase Storage.
- Display name is optional and managed in Settings (Account Mode only).
- Provider displayName may be used as an initial suggestion, but it is not authoritative.

---

# 🖼️ **10. User interface**

## **10.1. Login screen**

- Logo
- Google button (iOS/Android/Web)
- GitHub button only where supported (same screen, secondary action; keep UI complexity flat)
- Email/password form (macOS/Windows)
- Login entry hidden on Linux (Account Mode unavailable)
- Text: “Sync your tasks in the cloud”
- If a provider conflict occurs (account exists with different credential), prompt the user to sign in with the original provider and link the new provider.

---

## **10.2. Task List screen (group preparation)**

### **10.2.0. Group header (visible when tasks are selected)**

- As soon as at least one task is selected, show a compact header above the list:
  - **Group name input** (max 40 characters).
    - Optional to fill; if left empty, the system auto-generates the name on confirm (see TaskRunGroup naming rules).
  - **Group summary bar** with:
    - Total group time (work + breaks, using the same logic as execution).
    - Estimated start time (local "now" captured at the moment of selection).
    - Estimated end time (start + total group time).
- The summary is recalculated only when the selection changes (select/deselect).
  Reordering tasks does not change the summary because it uses only the total duration.
- If selected tasks mix Pomodoro structural configurations, the summary is provisional.
  After the Integrity Warning choice (Mode A or Mode B), all planning totals must
  use the chosen mode's timing rules.
- After a group is started or scheduled, **clear all selections** and collapse the header.

### **10.2.1. Task list**

- Manual ordering via drag & drop
- Order is persisted after reordering
- Selection by tapping the item (no checkbox)
- Selected state: subtle brighter card background + light border highlight
- Long-press on a task shows a contextual menu:
  - Edit
  - Delete (requires confirmation)
- Edit/Delete icons are not visible in the list row
- Reorder handle (≡) is the only draggable area

Item layout (top → bottom):

1. **Title row**
   - Task name (up to 2 lines, ellipsized) inside a **color-accent chip**
     (outline or side accent only; no solid fill).
   - The chip uses the task's assigned palette color (see Task colors section).
   - Derived task weight percentage in the top-right corner (does not alter the rest of the layout)
   - No time range in this row

2. **Stats row (three cards, equal width when possible)**
   - All cards have the same height and rounded corners
   - If space is tight, the card that shrinks is the **dot grid card**
   - **Card 1 (Pomodoros + Pomodoro minutes):**
     - Total pomodoros (number)
     - Red outlined circle showing **pomodoro minutes**
   - **Card 2 (Break minutes):**
     - Short break minutes in a blue **thin** ring
     - Long break minutes in a blue **thick** ring
     - Order: short → long
   - **Card 3 (Long-break interval dots):**
     - Red dots = number of consecutive pomodoros before a long break
     - Blue dot = the long break
     - Dots are arranged in **columns** to fit narrow widths
     - Dot size may shrink to ensure all dots fit inside the card
     - If the interval is **1**, the red and blue dots are centered at the same height
     - Otherwise, the blue dot is aligned with the **lowest** red dot (bottom row)
       and uses its own column if there is space; if not, it sits below the last red column

3. **Context row (time)**
   - **When selected**:
     - Label: **Time range**
     - Two chips: start time and end time (theoretical schedule preview)
     - Per-task total time is hidden (the group summary already shows totals)
   - **When not selected**:
     - Label: **Total time**
     - One chip: total task duration
    - Formula: `total = (pomodoros × pomodoroMinutes) + breaks`
       where breaks include short/long breaks between pomodoros and **exclude** the final break.

4. **Sounds row**
   - Two entries: **Pomodoro start** and **Break start**
   - Each entry shows a sound icon tinted:
     - Red for pomodoro start
     - Blue for break start
   - Show the custom filename (with extension) when available
   - If no custom sound is set, show a default label:
     - "Default chime"
     - "Default break chime"
   - Default labels use a muted (low-contrast) text color

### **10.2.2. Theoretical schedule preview**

- Calculated assuming “Start now” using the **anchor time** captured at the moment
  of selection (local "now").
- For each selected task, show:
  - Estimated start time
  - Estimated end time
- Only selected tasks show theoretical times.
- Recalculate when:
  - Selection changes (select/deselect)
  - A scheduled start time is chosen in planning (planned start)
  - Tasks are reordered (update per-task ranges only; the anchor time remains the same)
- The total duration and per-task ranges must follow the **same** timing logic as execution:
  - **Mode A (Shared structure)**:
    - The group behaves as a single continuous Pomodoro sequence.
    - Long breaks are inserted using a **global** pomodoro counter across tasks.
    - Task boundaries do **not** add extra breaks; they only switch labels.
  - **Mode B (Keep individual configurations)**:
    - Each task keeps its own structure.
    - If another task follows, include a break after the task:
      - Short by default.
      - Long if that task’s long-break interval is reached.

### **10.2.3. Confirm action**

- Bottom button: **“Next”**
- Enabled only if at least 1 task is selected
- On press (sequence):
  1. **Integrity Warning (if needed)**  
     If selected tasks use mixed Pomodoro structural configurations
     (pomodoro duration, short/long break duration, long break interval),
     show the Pomodoro Integrity Warning before any planning decisions:
     - Dialog style: pure black background with amber/orange border
     - Icon: Icons.info_outline (educational warning)
     - Intro text must include a clear instruction, e.g.:
       “This group mixes Pomodoro structures. Mixed durations can reduce the
       benefits of the technique. Choose the configuration to apply to this
       group.”
     - After the intro text, show a **scrollable list of visual options**. Each
       option is a selectable card (button-style):
       1. **One option per distinct structure** among the selected tasks.
          - Structure uniqueness is based on: pomodoro duration, short break,
            long break, long-break interval (sounds are ignored for grouping).
          - The option displays the **same three mini-cards** as a Task List item:
            pomodoro duration (no pomodoro count), break durations (short/long),
            and the interval dots. Sizes can be reduced to avoid overflow.
          - Show **"Used by:"** with task-name chips (wrapping to multiple lines).
          - Selecting this option forces Mode A using that structure (durations,
            interval; sounds follow the chosen task/preset per current logic),
            while keeping each task’s totalPomodoros unchanged.
       2. **Default preset option** (only if a Default Preset exists):
          - Shows the same three mini-cards using the preset values.
          - Includes a **badge with a star** and text “Default preset”.
          - The badge appears **below** the mini-cards (cards first, badge second).
          - Selecting it forces Mode A using the Default Preset (durations,
            interval, sounds) and propagates its presetId.
          - If the option is shown but the Default Preset is missing at tap time,
            show a SnackBar and keep the dialog open.
       3. **Keep individual configurations**:
         - Presented as a visual card in the same list.
         - Selecting it keeps Mode B (each task preserves its own structure).
  2. **Navigate to the full-screen planning screen**  
     The planning screen is where the group is reviewed and finally confirmed
     (see section 10.4.1). The group is created only after the user confirms
     on that screen.

### **10.2.4. Mode indicator (always visible)**

- The UI must clearly show whether the app is in Local Mode or Account Mode.
- This indicator must be persistent and unambiguous (e.g., app bar badge + icon).
- Avoid any wording that could imply cloud sync when Local Mode is active.

### **10.2.5. Running group entry point**

- If a TaskRunGroup is running or paused, show a persistent banner/CTA on the Task List screen:
  - Label includes the running group name and status.
  - Primary action: "Open Run Mode" (Execution Screen).
  - Secondary action: "View in Groups Hub".
- This entry point is required when auto-open is suppressed or cannot occur.
- If a scheduled group is within the Pre-Run Countdown window (noticeMinutes),
  show a similar banner on Task List:
  - Label indicates the group is starting soon and shows a countdown or start time.
  - Primary action: "Open Pre-Run" (Run Mode in Pre-Run state).
  - Secondary action: "View in Groups Hub".
- Any countdown shown in this banner must update in real time while visible
  (at least once per second). This is a **projection** only and must never
  drive authoritative state transitions.
- These entry points must not add new AppBar actions or change the AppBar layout.
  The header stays as-is; access is provided through existing screen content.

---

## **10.3. Task Editor**

Inputs:

- Name (with color picker)
- Preset selector (Custom or saved preset)
- Total pomodoros
- Task weight (%)
- Pomodoro duration (minutes)
- Short break duration
- Long break duration
- Long break interval
- Select sounds for each event (Pomodoro start, Break start, Task finish)

Buttons:

- Save
- Cancel
- Apply settings to remaining tasks
- Save as new preset (only when in Custom mode)

Behavior:

- Preset selector sits above duration/sound inputs (selecting a preset overrides the fields below).
- The Task name row includes a color-palette icon on the right. Tapping it opens the
  fixed task color palette (see Task colors section).
- When a preset is selected:
  - Task links to the presetId and adopts its structural values + sounds.
  - Editing any structural field switches the task to **Custom** (detaches from preset).
- Preset selector must be responsive on narrow screens; long preset names truncate
  (ellipsis) without causing horizontal overflow, and preset action icons remain visible.
- If the user attempts to leave **Edit task** with unsaved changes, show a confirmation
  dialog with options to **Save**, **Discard**, or **Cancel**. Only show this dialog
  when there are actual form differences from the original state.
- Inline preset actions are visible next to the selector when a preset is selected:
  - Edit (pencil) opens the preset editor
  - Delete removes the preset (tasks keep their current values and become Custom)
  - Default toggle (star) marks the preset as the global default (only one default at a time)
- "Save as new preset" appears only in **Custom** mode and saves the current configuration as a new preset.
- "Apply settings to remaining tasks" copies the current task configuration to all remaining tasks in the list (after the current task).
- Applies to all task settings except Name (pomodoro duration, short break duration, long break duration, total pomodoros, long break interval, sound selections).
- If the current task uses a preset, Apply Settings propagates the **presetId** to remaining tasks (not just raw values).
- If the current task is Custom, Apply Settings copies raw values as-is (no preset required).
- Task names are always unique within the list after normalization:
  - Trim leading/trailing whitespace.
  - Compare case-insensitively.
  - When editing, allow the task to keep its own normalized name; check duplicates against other tasks only.
  - Block Save/Apply and show a validation error if a normalized duplicate exists.
- Task name is required and must be non-empty after trimming; whitespace-only names are invalid.
- Break durations must be shorter than the pomodoro duration; block Save/Apply and show a clear error if they are equal or longer.
- Short break duration must be strictly less than long break duration; block Save/Apply and show errors on both fields if violated.
- When the pomodoro duration changes to a **valid** value (15–60), if current break
  values become invalid (break >= pomodoro or short >= long), auto-adjust them to
  the nearest valid values. Keep the existing inline helper text visible and add a
  brief note that the values were adjusted automatically for consistency.
- When the user edits **short break** or **long break**, auto-adjust the other break
  as needed to keep short < long and both < pomodoro (when pomodoro is valid).
  Keep the values as close as possible to the user’s input and show the same
  helper text with an automatic-adjustment note. Apply the adjustment when the
  user finishes editing the field (e.g., on focus loss), not on each keystroke.
  Do not auto-adjust if pomodoro is invalid.
- If the pomodoro value is invalid, do **not** auto-adjust break durations.
- When a blocking break validation error is present, suppress optimization guidance/helper text until resolved.
- Numeric inputs use tabular figures (fixed-width digits) to avoid value jitter while typing.
- Show dynamic guidance for break durations based on the pomodoro length:
  - Short break optimal range: 15–25% of pomodoro duration.
  - Long break optimal range: 40–60% of pomodoro duration.
- If break durations are outside the optimal range but still valid, show a warning with recommended ranges and allow the user to continue or adjust.
- Display helper text and visual cues (green = optimal, amber = outside range, red = invalid) on break inputs.
- Pomodoro duration guidance:
  - Hard range: 15–60 minutes (block outside this range).
  - Optimal: 25 minutes (green).
  - Creative range: 20–30 minutes (light green).
  - General range: 31–34 minutes (light green).
  - Deep work range: 35–45 minutes (amber).
  - Warning: 15–19 or 46–60 minutes (orange).
  - Provide an info tooltip explaining recommended ranges and trade-offs.
- Long break interval guidance:
  - Optimal value: 4 pomodoros (green).
  - Acceptable range: 3–6 pomodoros (amber).
  - Outside range: 1–2 or 7–12 pomodoros (orange) with a warning message.
  - Hard max: 12 pomodoros (block save above this value).
  - Allow values >= 1 up to 12; if the interval exceeds total pomodoros, show a note that only short breaks will occur.
  - Provide an info tooltip explaining how the long break interval works.
- If a custom local sound is selected, show the file name (with extension) in the selector.
- Task weight shows both total pomodoros and a derived percentage of the **selected group** total (work time).
- The Task weight (%) field appears **only** when the task is selected for the current group preparation.
- Directly below **Total pomodoros**, show a **non-editable total time chip** with
  the task's full duration (work + breaks). This chip is always visible and updates live.
- Editing the percentage updates totalPomodoros to the closest integer (pomodoros are never fractional),
  and redistributes the remaining tasks to preserve their relative proportions.
- Display Total pomodoros and Task weight (%) on the same row directly below the task name to emphasize task weight.
- Visually separate **Task weight** from **Pomodoro configuration** with section headers.
  Pomodoro configuration sits below Task weight and above Sounds.

### **10.3.x. Pomodoro integrity + task weight (planned, documentation-first)**

Goal: preserve Pomodoro technique integrity across consecutive tasks while keeping flexibility for mixed configurations.

Definitions:

- **Pomodoro structural configuration**: pomodoro duration, short break duration, long break duration, long break interval.
- **Task weight**: totalPomodoros (authoritative integer) and derived percentage of the group total.
- **Work time**: `totalPomodoros * pomodoroMinutes` (breaks are excluded).

Execution modes for TaskRunGroups:

- **Mode A — Shared Pomodoro Structure (recommended)**
  - The group defines the structural configuration.
  - All tasks share the same pomodoro/break durations and long-break interval.
  - Tasks differ only by `totalPomodoros` (weight).
  - The long-break interval is counted **globally across tasks**.
- **Mode B — Per-task Pomodoro Configuration (current behavior)**
  - Each task keeps its own structural configuration.
  - The app shows an informational warning that Pomodoro benefits may be reduced.
  - The user may continue without restrictions.
  - For timeline calculations, if another task follows, include a break after the task:
    - Short by default.
    - Long if that task’s long-break interval is reached.

Timing integrity

- All planning totals (Task List summary, time ranges, scheduling) must use the **same**
  break-insertion logic as execution for the chosen mode.
- **Time range formatting (global):** whenever a **scheduled** or **projected**
  time range is displayed (planning preview, late-start queue, Task List / Groups Hub
  banners, conflict screens, contextual lists), show **HH:mm–HH:mm** when the date
  is today, and show **date + time** when the date is not today
  (e.g., “Feb 21, 17:55–18:10”). This applies to both **Scheduled** and **Projected**
  labels.

Task weight rules:

- Task weight is **contextual to the selected group** and never a global absolute percentage.
- Each task has an authoritative integer `totalPomodoros` and a derived percentage.
- Percentage is computed from **work time** and rounded for display.
- Group total for the percentage (work time):
  - Task List: sum of work time for the **selected** tasks only; if none are selected, do not show percentages.
  - Task Editor: sum of work time for the **selected** tasks only (including the task being edited).
  - If the task is **not selected**, the Task weight (%) field is hidden.
- When a user edits the percentage of a task:
  - The edited task is adjusted so its work time matches the requested percentage
    of the group's total work time (closest possible).
  - Other **selected** tasks are automatically redistributed to fill the remaining percentage,
    preserving their **relative proportions** to each other.
  - Unselected tasks are never affected by weight edits.
  - Redistribution adjusts `totalPomodoros` only (integer), never splitting pomodoros.
  - `roundHalfUp` means .5 ties always round up.
  - Exact percentages are not guaranteed due to integer constraints.
  - If the closest achievable result deviates by **≥ 10 percentage points**, or if
    no redistribution change is possible, show a lightweight (non-modal) notice:
    - Pomodoros are indivisible.
    - Few total pomodoros limits precision.
    - Suggest adding pomodoros, selecting more tasks, or trying another percentage.

UI implications (documentation only):

- Task List should display both totalPomodoros and derived percentage of the group total.
- Percentages are shown only when tasks are selected; unselected tasks do not show percentages.
- Task Editor should display totalPomodoros and derived percentage **only** when the task is selected.
  If the task is not selected, hide the Task weight (%) field entirely.
- On first exposure, show an informational modal explaining that task weight is
  relative to the selected group only, with a “Don’t show again” checkbox.
  Provide an info icon next to Task weight (%) to reopen the explanation later.
- Task Editor should place Total pomodoros + Task weight (%) together, above Pomodoro structural configuration and sounds.
- If a TaskRunGroup mixes structural configurations, show a clear integrity warning (education-only).

### **10.3.z. Task colors (visual accent, documentation-first)**

Purpose: provide a lightweight visual identifier for tasks across the flow without relying on color as the only signal.

Rules

- Each task has a `colorId` from a **fixed, cross-platform palette** (12 colors).
- Users can choose a color in the Task Editor via the palette icon next to the Task name.
- If the user does not choose a color, the system **auto-assigns** one on first save:
  - Choose the **least-used** color among existing tasks in the current list.
  - If there is a tie, pick the earliest color in the palette order.
  - Never auto-reassign a task that already has a color.
- The color is **accent-only**:
  - Use it for outlines, chips, or small indicators.
  - Do **not** use it as a solid background behind text.
  - Task name text always uses the standard theme color for readability.
- The color must never be the only means of conveying information.
- Ensure legibility on both dark and light themes:
  - No neon/high-saturation extremes.
  - Contrast must remain WCAG AA–equivalent for text proximity.
  - If necessary, adjust stroke opacity (not hue) for theme balance.

Palette (fixed order)

1. Red — `#E53935`
2. Blue — `#1E88E5`
3. Green — `#43A047`
4. Amber — `#FFB300`
5. Purple — `#8E24AA`
6. Cyan — `#00ACC1`
7. Teal — `#00897B`
8. Indigo — `#3949AB`
9. Pink — `#D81B60`
10. Lime — `#AFB42B`
11. Orange — `#FB8C00`
12. Neutral Gray — `#757575`

Usage locations

- Task List (task name chip).
- Run Mode group progress bar.
- Run Mode contextual task list (below the circle).
- Any screen where a task name is displayed in a list or summary.
- When a TaskRunGroup snapshot is created, copy `colorId` into each TaskRunItem
  so group visuals remain stable even if the task is later edited.

### **10.3.y. Reusable Pomodoro configurations (Task Presets) (planned, documentation-first)**

Goal: separate “what I do” (task) from “how it runs” (Pomodoro configuration) while keeping full flexibility.

Preset definition:

- A **Pomodoro configuration preset** is a named, reusable bundle of:
  - pomodoro duration
  - short break duration
  - long break duration
  - long break interval
  - sound selections

Behavior:

- The app ships with a built-in default preset named **Classic Pomodoro**.
- The system guarantees at least one preset always exists; users cannot end up with zero presets.
- Presets are seeded on first read:
  - If no presets exist, auto-create **Classic Pomodoro** and mark it as default.
- Presets are selectable from the Task Editor when creating or editing a task.
- Presets can be created, renamed, edited, and deleted from within the Task Editor context.
- One preset is always marked as **default** and applied automatically to new tasks.
- Editing a preset updates all tasks that reference that preset (durations, intervals, sounds).
  This can change derived values such as task weight (%) and planning estimates.
- Preset names are **unique per scope**:
  - Account Mode: unique per account.
  - Local Mode: unique per local device scope.
  - Comparison is case-insensitive after trimming whitespace.
  - Saves with duplicate names are blocked with an explicit error message.
- Presets are also considered duplicates if their **configuration** is identical
  (durations, interval, and sound selections), regardless of name:
  - On **save** (new or edit), detect configuration duplicates and present options:
    - **Use existing / Discard changes** → cancel the save; keep the existing preset unchanged.
    - **Rename existing** → apply the new name to the existing preset; no new preset created.
    - **Save anyway** → explicitly keep/create a duplicate.
    - **Cancel** → return to editing without changes.
  - After **Use existing** or **Rename existing**, exit to **Manage Presets** to avoid
    returning to a stale editor state (applies to both new and edit flows).
  - No duplicate is created without explicit confirmation.
- If multiple defaults are detected (legacy data or sync conflicts), the app
  auto-resolves to a **single** default (most recently updated; fallback to
  Classic Pomodoro if none) and persists the correction.
- If duplicate preset names are detected (legacy data or sync conflicts), the app
  auto-renames duplicates with a numeric suffix (e.g., "Focus", "Focus (2)") and
  persists the correction.
- The built-in **Classic Pomodoro** preset must remain unique per scope
  (Local or Account) and must never duplicate across provider linking or
  account-local preset pushes.
  - When pushing account-local presets to Firestore, skip Classic Pomodoro if
    the account already has a Classic Pomodoro preset.
- A task may either:
  - reference a saved preset, or
  - use a custom, task-specific configuration.
- Backward compatibility: tasks without a preset behave as custom tasks using their stored values.

Preset UI (Task Editor)

- Preset selector (dropdown) sits above structural fields; the first option is **Custom**.
- When a preset is selected, show inline actions:
  - Edit (pencil) → opens preset editor
  - Delete (trash) → removes preset; affected tasks keep values and become Custom
  - Default toggle (star) → marks as global default (only one default at a time)
- "Save as new preset" appears only in Custom mode after changes.
- Selecting a preset overrides the fields below; editing any structural field detaches to Custom.
- Preset save failures must show explicit user feedback (no silent failures), including
  sync-disabled and permission errors.
- When a preset save updates existing tasks, show a lightweight confirmation message
  (no modal) to avoid silent behavior.
- If deleting a preset would leave zero presets, automatically recreate **Classic Pomodoro**
  and mark it as the default.

Preset UI (Settings)

- Settings includes a **Manage Presets** screen:
  - List all presets as cards (high contrast on dark background)
  - Show default marker (star) on the default preset
  - Quick actions: edit, delete, set default
  - Bulk delete is allowed
- In **Edit preset**, if the preset is already the default, the default toggle is
  **disabled** and shown as informational (to change default, pick another preset).
- If the user attempts to leave **Edit preset** with unsaved changes, show a confirmation
  dialog with options to **Save**, **Discard**, or **Cancel**. Only show this dialog
  when there are actual form differences from the original state.
- When the pomodoro duration changes to a **valid** value (15–60) in Edit Preset,
  auto-adjust short/long breaks if they become invalid (break >= pomodoro or
  short >= long), keeping the values as close as possible and showing the same
  inline helper text with an automatic-adjustment note.
- When the user edits **short break** or **long break** in Edit Preset, auto-adjust
  the other break as needed to keep short < long and both < pomodoro (when pomodoro
  is valid). Keep values close to the user’s input and show the same helper text
  with the automatic-adjustment note. Apply the adjustment when the user finishes
  editing the field (e.g., on focus loss), not on each keystroke. Do not auto-adjust
  if pomodoro is invalid.
- If the pomodoro value is invalid, do **not** auto-adjust break durations.

Storage & sync

- Account Mode: `users/{uid}/pomodoroPresets/{presetId}` in Firestore.
- Local Mode: presets stored locally (SharedPreferences in MVP; Hive planned).
- Account Mode + sync disabled: presets stored in an account-scoped local cache (keyed by uid).
- When sync becomes enabled (email verified), automatically push account-local presets to
  Firestore once (no user prompt).
- Custom sound selections remain local-only:
  - Firestore stores built-in references for presets
  - Local overrides store the custom file path + display name per preset

---

## **10.4. Execution Screen (Run Mode)**

The execution screen shows an analog-style circular timer with a dynamic layout tailored for TaskRunGroups.
Run Mode is group-only: TimerScreen loads a TaskRunGroup by groupId; there is no single-task execution path.

### **10.4.1. Pre-start planning (before the timer begins)**

- The user chooses when and how to run the group after tapping **“Next”** in Task List.
- The planning step is a **full-screen page** (not a modal) with:
  - AppBar + back button (returns to Task List for edits).
  - Clear title (e.g., “Plan group” / “Plan start”).
  - Primary CTA: **“Confirm”** (this is when the group is created).
  - Secondary action: **“Cancel”**.
- Planning options (single selection; **Start now** is default):
  - **Start now**
  - **Schedule by start time**
  - **Schedule by total range time**
  - **Schedule by total time**
- A single **info icon** near the options opens an informational modal that explains
  all options. The modal:
  - Appears the first time the user opens this screen.
  - Includes a “Don’t show again” toggle (saved per-device).
  - Remains accessible via the info icon at any time.
  - When opened via the info icon, **do not** show the “Don’t show again” toggle.
  - The content must clearly explain what each option does and how it affects
    the group start and timing.
- Conflicts are validated for all actions (see section 6.4).

- The planning screen must display a **full preview** of the resulting group:
  - **Group start and end time** near the top (based on the selected option).
  - **Total duration (work + breaks)** near the top (same timing logic as execution).
  - A **task list preview** using the **same card visuals** as Task List
    when tasks are selected.
  - Each task card shows:
    - Task name + **weight %** on the right
    - The three stat cards (pomodoros + minutes, breaks, interval dots)
    - Time range for the task (start → end)
    - Sounds row in the same format as Task List
  - The preview must reflect the **Integrity Warning** choice (Mode A vs Mode B),
    so durations, breaks, and sounds match the final group configuration.

Start now

- Starts immediately using the current TaskRunGroup snapshot (no reweighting).

Schedule by total range time

- The user selects **start time** and **end time** (date + time).
- The system recalculates the group to fit within the requested time range by
  **redistributing totalPomodoros per task**, preserving relative **work-time**
  proportions (same algorithm as Task weight in section 10.3.x).
- Pomodoro and break durations are **never** changed.
- Pomodoros are indivisible integers; minimum 1 per task.
- If the requested range cannot be satisfied without breaking these rules, block scheduling
  and show a clear warning.
- If the closest valid distribution ends earlier than the requested end time due to integer
  constraints, show the actual end time as the planned end.
  - Show a lightweight notice explaining why the end time shifted.
  - Include a “Don’t show again” checkbox; remember the preference per device.

Schedule by total time

- The user selects **start time** and **total duration** (e.g., 8h).
- The system derives the end time and applies the **same** redistribution rules as above.
- If the requested duration cannot be satisfied without breaking the rules, block scheduling.
- Adjustments apply only to the TaskRunGroup snapshot; the underlying PomodoroTask values are never modified.
 - If the derived end time is earlier than the user’s requested end time due to integer
   constraints, show the same lightweight notice (with “Don’t show again”).

Redistribution rules (shared)

- Use the **same** rounding and proportional logic as Task weight:
  - `roundHalfUp` for integer pomodoros.
  - Minimum 1 pomodoro per task.
  - Preserve relative proportions between tasks.
- If the closest achievable distribution deviates excessively (≥ 10 percentage points)
  or no redistribution is possible, show a blocking warning and do not schedule.
- Scheduling must reserve the full Pre-Run Countdown window when noticeMinutes > 0:
  - The window from scheduledStartTime - noticeMinutes to scheduledStartTime
    is treated as blocked time.
  - It must not overlap any running group or any previously scheduled group’s
    execution window.
  - If the full Pre-Run window cannot be reserved (including when it would
    start in the past), scheduling is blocked and the user is shown a clear,
    non-technical explanation (e.g., “That time doesn’t leave enough pre‑run
    time. Choose a later start or reduce the pre‑run notice.”).
- If a schedule is set:
  - Recalculate theoretical start/end times using the selected start time
  - Save as scheduled and add to Groups Hub
  - Send the pre-alert noticeMinutes before the scheduled start
  - Auto-start requires at least one device for the account to be open at or after the scheduled time;
    if all devices are closed, the group waits until the next app launch/resume on any signed-in device
  - If the app is open during the pre-alert window, automatically open Run Mode in Pre-Run Countdown Mode
  - If the app is closed during the pre-alert window, send a silent system notification on platforms with background scheduling (Android/iOS/macOS).
    On Windows/Linux/Web, no system notification is sent while closed.
  - If the app is open during the pre-alert window, suppress any system notification to avoid duplicate alerts
  - At the scheduled time:
    - Set status = running
    - Set actualStartTime = now
    - Recalculate theoreticalEndTime = actualStartTime + totalDurationSeconds
    - Auto-open the execution screen and auto-start the group
    - Ownership is claimed by the first active device that starts the session (if multiple devices are open)
    - Auto-start requires **no user action**; if multiple devices are open, exactly one
      device must claim ownership and others enter mirror mode automatically.
  - If the app was inactive at scheduledStartTime:
    - On next launch/resume of any signed-in device, if scheduledStartTime <= now and there is no active conflict,
      auto-start immediately using actualStartTime = now (scheduledStartTime remains unchanged)
  - The timer remains stopped until the scheduled start

### **10.4.1.a. Pre-Run Countdown Mode (scheduled groups only)**

Purpose: reduce anxiety and provide context before a scheduled group starts.

Trigger

- Active only within the pre-alert window:
  - from scheduledStartTime - noticeMinutes
  - until scheduledStartTime
- If noticeMinutes = 0, Pre-Run Countdown Mode is skipped entirely.
- If the app opens after scheduledStartTime, it goes directly to standard Run Mode.
- If the user leaves the Pre-Run screen, they must be able to return via Task List
  or Groups Hub entry points while the pre-run window is active.
- When the pre-run window begins, auto-open the TimerScreen in Pre-Run mode
  from **any** screen (Task List, Groups Hub, etc.) and **do not** bounce back to
  the previous screen. If the user navigates away manually, the entry points above
  must remain available until the pre-run window ends.
- Auto-open applies on **all signed-in devices** (owner or mirror) so Pre-Run is
  visible everywhere with the same behavior.
- Auto-open is **idempotent**: if the correct group is already visible in
  Pre-Run or Run Mode, do not push or replace routes, and never stack duplicate
  screens.
- If the user leaves Pre-Run, Run Mode must still auto-open at scheduledStartTime
  from any screen on **all** devices (same idempotent guard).

UI (reuses Run Mode layout)

- Same large circle and layout as Run Mode.
- Neutral/amber color (not red or blue).
- Center content (vertical order):
  1. Current time (HH:mm)
  2. Countdown label: "Group starts in"
  3. Countdown value: "04:32" (last 60 seconds use SS only)
  4. Current status box: "Preparing session" (amber, no range)
  5. Next status box: "Starts at HH:mm" (red, no range)

Contextual list

- Shows the same list component as Run Mode.
- Do not show a "Preparing session" item here.
- Show upcoming tasks with their planned time ranges.
- All items are rendered in a neutral/muted visual state to reinforce that execution has not started.
- Once the group starts, the list transitions automatically to standard Run Mode with no layout changes.

Interactions

- Cancel schedule is available.
- Pause is visible but disabled (group has not started yet).
- Start now is not available in this mode.
- Pre-Run has no authoritative owner; all signed-in devices are equivalent and may cancel.
  Exception: if a conflict-resolution decision is required (sections 10.4.1.b–c),
  an owner must be established and only the owner can act.
- When the countdown reaches zero, the group must auto-start without user action.

Transition at scheduled start

- Countdown reaches zero -> smooth color shift (amber -> red).
- Standard Run Mode begins immediately.
- Normal start sound plays.

Last 60 seconds

- Countdown switches from MM:SS to SS only.
- Subtle visual pulse on the circle (no sound).
- Ring pulse uses a visible but gentle “breathing” stroke-width change, synced to a 1Hz rhythm.

Last 10 seconds

- Countdown number scales up quickly (≈1–1.5s) to a large, near-full-circle size.
- The scale completes early and stays stable until it reaches 0.

### **10.4.1.b. Late-start overlap queue (overdue vs scheduled)**

Purpose: resolve overlaps caused by late starts, including multiple overdue groups.

Trigger

- On launch/resume, if there is **no running group** and at least one scheduled
  group is overdue (scheduledStartTime <= now) **and** starting now would
  overlap another scheduled group window (overdue or future).
- On **mode switch (Local → Account)** with the app open, re-evaluate the same
  criteria immediately; if the queue should appear, show it without requiring
  an app restart.
- Do **not** trigger this queue during the Pre-Run -> Running transition if the
  overdue group can start without overlapping any other scheduled group.

Anchor & timebase

- When this queue is triggered, the **owner** writes `lateStartAnchorAt` using
  a **server timestamp** on all groups in the conflict set.
- The owner also writes `lateStartQueueId`, `lateStartQueueOrder`,
  `lateStartOwnerDeviceId`, and `lateStartOwnerHeartbeatAt`.
- All devices derive a **queue timebase** from `lateStartAnchorAt` to keep
  projections consistent across devices (do **not** use local `DateTime.now()`
  directly for projections).
- The timebase is **anchored** to `lateStartAnchorAt` once set. Owner heartbeat is
  for **liveness/staleness checks only** and must **not** shift the projection
  base. If `lateStartAnchorAt` is missing (legacy), fall back to the latest
  heartbeat **only until** the anchor is materialized.
- On app resume/reopen, if `lateStartAnchorAt` exists, recompute projections
  from the anchor + now; never revert to `scheduledStartTime` while the queue
  is active.
- `lateStartAnchorAt` is cleared on confirm/cancel so it does not linger.
- If there is **no owner** yet, the first active device auto-claims ownership
  for the queue (before it is shown).
- Owner label: show **"Owner: <device>"** using `lateStartOwnerDeviceId`.

UI (full-screen flow, same visual language as Plan group)

- Show a clear explanation of the late-start overlap situation and options.
- Show **total time** to run the selected queue, including pre-run windows.
- If total time > 8 hours, show a clear warning under the total.
- List **conflicting groups** with:
  - Group name
  - Scheduled time range (HH:mm–HH:mm)
    - If the scheduled date is **not today** (local), include the date
      before the time range (e.g., "Feb 21, 17:55–18:10").
  - Projected time range (HH:mm–HH:mm)
    - If the projected start date is **not today**, include the date
      before the time range (same format as Scheduled).
- Owner-only: allow **multi-select** and **drag reorder** of selected groups.
- Mirror: read-only list + CTA “Request ownership to resolve”.
  - The CTA writes `lateStartClaimRequestId`, `lateStartClaimRequestedByDeviceId`,
    and `lateStartClaimRequestedAt` if the owner is active.
  - If the owner heartbeat is stale (>=45s), the mirror can **auto-claim** and become owner.
  - If the heartbeat is missing, do **not** auto-claim until the grace window
    (>=45s since `lateStartAnchorAt`) has elapsed.
- Show up to **5 groups** by default; include a **“Show more”** control to
  expand the full list.
- As the user reorders selections, update the **projected ranges** in the list
  to reflect the new sequential order.
- Projected ranges **update in real time** (e.g., every second) based on the
  queue timebase so the preview matches the actual start on confirm.
- The **first** selected group starts immediately (**no pre-run**), so its
  projected start **equals the queue timebase** (no extra minute added).

Actions

- Primary: **Continue**
- Secondary: **Cancel all**
- On **Cancel all**: show a confirmation modal stating that **all listed groups
  will be canceled** and that they can be re-planned from Groups Hub. On
  confirm, cancel each group using the reason rules below, clear all late-start
  queue fields (`lateStartAnchorAt`, owner/claim metadata, queue id/order), and
  return to Groups Hub. Never leave a blank/black screen.
- If the owner **resolves or cancels** the queue while a mirror is viewing it
  (lateStart* cleared or all groups canceled), the mirror must:
  - Disable actions immediately.
  - Show a modal: **“Owner resolved”** with a single **OK** action.
  - On OK, navigate to Groups Hub. Never remain on a blank screen.
- If **no groups** are selected and the user taps Continue, treat it exactly
  like **Cancel all** (same modal, same cancel reason rules, same cleanup).
- If **one or more** groups are selected:
  - Show a **preview step** (same task list preview style as Plan group)
    summarizing the selected groups in order.
  - On confirm:
    - Start the **first** group immediately (no pre-run).
    - Set `scheduledStartTime = queueNow` and `actualStartTime = queueNow`
      for the first group to keep the schedule coherent.
    - Create/publish the **activeSession** as owner so Run Mode does not
      stall in “syncing session”.
    - Schedule the remaining groups **sequentially**, preserving pre-run windows:
      scheduledStartTime = previousEnd + noticeMinutes.
    - When deriving scheduledStartTime from queue sequencing, **round up to the
      next full minute** (seconds = 00) to match minute-only UI display. Never
      round backwards into the past.
    - Update scheduledStartTime and theoreticalEndTime for rescheduled groups.
    - Cancel all **unselected** groups using the reason rules above.
    - Clear `lateStartAnchorAt`, `lateStartOwnerDeviceId`,
      `lateStartOwnerHeartbeatAt`, `lateStartClaimRequestId`,
      `lateStartClaimRequestedByDeviceId`, `lateStartClaimRequestedAt`
      for all groups in the queue.
    - Keep `lateStartQueueId` and `lateStartQueueOrder` on the **selected**
      groups so later postpones can drag the remaining queued groups.
    - Clear `lateStartQueueId` and `lateStartQueueOrder` on **unselected**
      (canceled) groups.
    - Revalidate overlaps against any other scheduled groups not in the selection.
      If conflicts exist, reopen this queue flow.

Permissions

- Only the **owner** device can act. If no owner is active, the first active device
  auto-claims ownership before this flow appears.
- If the owner is active, mirrors must request ownership and wait for
  explicit approval before acting.
- Manual “Start now” must not bypass this queue when overdue conflicts exist.

### **10.4.1.c. Running overlap decision (pause drift vs scheduled)**

Purpose: resolve overlaps when a running/paused group reaches another group’s
scheduled pre-run window.

Trigger

- A scheduled group’s **pre-run window begins** while another group is still
  running or paused (see section 6.4).
- If the running group’s **theoreticalEndTime** is pushed (e.g., by pauses)
  so it now overlaps the next scheduled group’s **pre-run window**, the
  conflict is detected immediately **even before** the pre-run window begins.
- While paused, use the **projected end** (theoreticalEndTime + elapsed pause)
  for overlap detection. Trigger as soon as the projected end reaches the
  pre-run overlap threshold (pre-run start + 1 minute grace); do **not** wait
  for resume.

Timing of the decision UI

- The moment an overlap becomes possible (runningEnd >= preRunStart + 1 minute
  grace), begin conflict notification timing. Do **not** wait for the pre-run
  to start.
- Because schedules are minute-based, a running end that lands within the same
  minute as the pre-run start is **not** considered a conflict.
- The decision modal should appear **during a break** when possible to avoid
  interrupting focus time.
- If the overlap is detected while the user is already in a **break** (short
  or long), show the modal **immediately**.
- If the overlap is detected during a **pomodoro**, defer the modal to the
  **next break**.
- Exception: if the overlap is detected during the **final pomodoro of the
  group** (no breaks remain), show the modal **immediately** even during the
  pomodoro.
- If the group is **paused**, show the modal **immediately** (no deferral).

Flow

- Show a **blocking decision modal** on the owner device.
- The modal must include **context** about the conflicting scheduled group:
  group name and its scheduled time range (and pre-run start time if different).
- The modal **pauses** the current group immediately and counts as a normal pause.
- Options:
  1. **End current group** → cancel current group (canceledReason = interrupted),
     then proceed with the scheduled group’s pre-run/start.
  2. **Postpone scheduled group** →
    - Set `scheduledStartTime = projectedEnd + noticeMinutes`, and set
      `postponedAfterGroupId = currentGroupId`.
    - When deriving scheduledStartTime from a projected end, **round up to the
      next full minute** (seconds = 00) to match minute-only UI display. Never
      round backwards into the past.
     - While the current group is running/paused, the scheduled group’s
       **effective** start tracks the current group’s projected end in real
       time (no repeat modal for the same pair).
     - Task List and Groups Hub must render that **effective** schedule in real
       time on all devices (owner and mirror), without requiring manual refresh.
     - When the current group ends, **lock in** the schedule (update
       `scheduledStartTime` + `theoreticalEndTime`) and clear
       `postponedAfterGroupId`.
     - Show a confirmation SnackBar with the **new start time** and the
       **pre-run time**.
     - If the scheduled group is part of a resolved late-start queue
       (`lateStartQueueId` is set) and has **later groups in the same queue**,
       drag the remaining queued groups forward in sequence:
       - nextStart = projectedEnd + noticeMinutes
       - each following group starts at previousEnd + noticeMinutes
       - this avoids repeated conflict modals for each queued group.
       - Show a one-time SnackBar:
         “Postponed. The remaining queued groups will shift sequentially.”
     - Revalidate conflicts against other scheduled groups; if new overlaps
       exist outside the queue, reopen the appropriate conflict flow immediately.
  3. **Cancel scheduled group** → cancel it (canceledReason = conflict) and
     continue the current group.

Permissions

- Only the **owner** device can act. Mirrors show a read-only state until the
  owner resolves the decision.
- If the owner is **stale**, mirrors may auto-claim ownership; otherwise,
  ownership requires explicit owner approval.
- Mirrors must show a **persistent CTA** in Groups Hub and Task List:
  - If the owner is **stale**: “Owner seems unavailable. **Claim** ownership to resolve this conflict.”
  - If the owner is **active**: “Owner is resolving this conflict. Request ownership if needed.”
  (Use the appropriate CTA label: **Claim** when stale, **Request** when active.)
- Show the mirror CTA **only while the overlap is still valid**. If the conflict
  resolves or the session is missing, hide the CTA and clear any related banners.
- Do **not** show duplicate conflict messaging. If the banner is visible, do not
  also show a conflict SnackBar on the same screen.
- Mirrors must **not** navigate away from Run Mode when showing this CTA/banner.

### **10.4.2. Header**

- Back button + title (Focus Interval)
- Access to Groups Hub screen (show a visual indicator when pending groups exist)
- If the Groups Hub screen is not yet available, the indicator can be a non-interactive placeholder until Phase 19.

### **10.4.2.a. Group progress bar (above the circle)**

- Add a horizontal **group progress bar** directly above the timer circle.
- The bar is segmented by task. Each segment’s width is proportional to that task’s
  **total duration** in the group timeline (work + breaks), using the **active integrity mode**:
  - **Mode A (Shared structure)**: breaks are inserted across the entire group and
    attributed to the task that just completed a pomodoro.
  - **Mode B (Keep individual configurations)**: each task’s own break structure
    is preserved; include the final break when another task follows.
- Each segment uses the task’s palette color as an **accent** (outline or subtle fill).
- Each segment is rendered as a **chip** with the task name label.
- The label truncates to the available width (ellipsis or hard-cut); no overflow or
  overlap is allowed. If the chip is too narrow, hide the label.
- Not started: gray outline (neutral).
- Active task: outline uses the task color and runs a subtle **color-only** pulse
  synced to the Pre-Run 1Hz rhythm (no stroke-width changes).
- Completed task: outline uses the task color, no animation.
- The fill represents **effective executed time** only:
  - Progress **does not advance while paused**.
  - For running sessions, derive elapsed time from `phaseStartedAt` + `phaseDurationSeconds`.
  - For paused sessions, use the stored `remainingSeconds` to keep progress frozen.
  - Mirror devices compute the same value from the shared session + group snapshot.
  - Local Mode: if a pause is lost on app close (per spec), progress recalculates from
    `actualStartTime` and will jump accordingly on reopen.
- In Pre-Run Countdown Mode, the bar is visible but empty (0% fill).

### **10.4.3. Circle core elements**

1. Large circular clock (progress ring style with a visible progress segment)
2. Progress ring marker (no hand/needle)
   - A white circular marker at the leading edge of the ring
   - Subtle inner gray core + soft shadow (matches the current approved visual)
   - The marker and ring are the countdown indicator; do not add an analog hand/needle
   - Countdown is rendered counterclockwise by the shrinking progress segment
3. Colors by state
   - Red (#E53935) → Pomodoro
   - Blue (#1E88E5) → Break
   - Amber (#FFB300) → Pre-Run Countdown (neutral)
   - Completion uses green or gold (see section 12)
   - Progress segment uses the active state color
4. Base ring (visual invariant)
   - Dark gray base ring (#222222) with soft depth
   - Ring thickness, shadows, and marker styling are locked; only minor polish in Phase 23 with explicit approval

### **10.4.4. Content inside the circle (strict vertical order)**

1. Current time (HH:mm)
   - Black background, thin white border, white text
   - Updates every 60s
   - Independent from pomodoro/break state (no color changes)
2. Remaining time (MM:SS) — main countdown
3. Current status box (what is executing now)
4. Next status box

Pomodoro running

- Current status:
  - Red border/text, black background
  - Text: Pomodoro Y de X
  - Time range: HH:mm–HH:mm
- Next status:
  - If this is the last pomodoro of the **last task** in the group:
    - Golden-green border/text, black background
    - Text: Fin de grupo
    - End time: HH:mm
  - Otherwise (the task continues after a break):
    - Blue border/text, black background
    - Text: Descanso: N min
    - Time range: HH:mm–HH:mm

Break running

- Current status:
  - Blue border/text, black background
  - Text: Descanso: N min
  - Time range: HH:mm–HH:mm
- Next status:
  - If this is the last break of a task **and there are more tasks**:
    - Golden-green border/text, black background
    - Text: Fin de tarea
    - End time: HH:mm
  - Otherwise:
    - Red border/text, black background
    - Text: Siguiente: Pomodoro Y de X
    - Time range: HH:mm–HH:mm

Note (mode-specific):

- **Mode A (Shared structure):** 
   - The group behaves as a single continuous Pomodoro sequence.
   - Pomodoro and break durations, as well as the long-break interval, are shared across the entire group.
   - The pomodoro counter is global to the group and does not reset when tasks change.
   - Breaks are always executed between pomodoros according to the shared configuration.
   - There is no additional or special break caused by task boundaries.
   - When a task finishes and there are more tasks, execution continues with the next task’s pomodoro after the appropriate break.
   - Two pomodoros must never be executed consecutively without an intervening break.
- **Mode B (Keep individual configurations):** 
   - Each task preserves its own pomodoro and break structure.
   - When a task finishes and another task follows, a break is always executed before starting the next task.
   - The break between tasks is a short break, unless the task’s own long-break interval is reached, in which case a long break is executed.
   - No break is executed after the final pomodoro of the last task in the group.


Rule: the upper box always matches the current executing phase.
Rule: time ranges shown in the status boxes are derived from
`TaskRunGroup.actualStartTime` + accumulated durations + pause offsets.
Once a group is running, never use `scheduledStartTime` for these ranges.
Rule: status-box ranges and contextual list ranges must be consistent and derived
from the same authoritative timeline; never leave stale ranges after pause/resume.

### **10.4.5. Contextual task list (below circle)**

Location: below the circle and above Pause/Cancel buttons.

- Max 3 items:
  - Previous task (completed)
  - Current task (in progress)
  - Next task (upcoming)
- No placeholders, no empty slots.
- Each item shows its time range (HH:mm–HH:mm).
- Task name is shown with the same color-accent chip used in the Task List.
- Current task item uses the task color outline.
- Previous/next items use a neutral gray outline.
- Completed task item is slightly narrower (≈92–96% width), centered, and must
  keep full legibility without shifting the overall layout.
- Completed tasks keep their actual time range; current/upcoming tasks are projected.
- **Authoritative time range anchoring (task list):**
  - Start = `TaskRunGroup.actualStartTime + accumulated previous task durations +
    pause offsets before the task`.
  - End = start + task duration (**plus** pause time since task start for the current task).
  - **Do not** use `activeSession.phaseStartedAt` to anchor task/group starts; it is
    only for phase progress.

Cases

1. First task in group
   - Show current + next (2 items)
2. Middle of group
   - Show previous + current + next (3 items)
3. Last task
   - Show previous + current (2 items)
4. Single-task group
   - Show current only (1 item)

The list rebuilds automatically when tasks change.

### **10.4.5.a. Run Mode controls (below the list)**

- Primary controls: Start/Resume, Pause, and Cancel (depending on state).
- Controls must share a full-size button style (no compact sizing tied to owner/mirror state).
- The layout must remain stable without overlap or clipping.

### **10.4.6. Transitions**

- Task completion -> auto-transition to next task
- No modal between tasks
- Group completion -> modal + final animation (see section 12)
- Completion modal includes summary totals when available (total tasks, pomodoros, total time)
- Completion modal must show on both owner and mirror devices while Run Mode is visible.
- If the app is not active and the modal cannot be shown, show it on next foreground;
  if it still cannot be presented, auto-navigate to Groups Hub to avoid an idle Run Mode state.
- If the owner is offline, mirror devices must still show the completion modal when the
  projected timeline reaches the final task completion (derived state; no sync write).
- After the user explicitly dismisses the completion modal, auto-navigate to the Groups Hub screen (do not remain in an idle Execution screen)
- Cancel running group -> confirmation dialog + cancel group + navigate to Groups Hub
- Status boxes and contextual list update automatically (including time ranges after pause/resume); no extra confirmations or animations in the MVP

Cancel running group (Run Mode)

- Action requires confirmation before canceling.
- Confirmation copy must warn that the group will end and cannot be resumed.
- On confirm:
  - Stop the session immediately.
  - Mark the group as canceled (canceledReason = user).
  - Navigate to Groups Hub (do not remain in Run Mode).
- If a canceled status is observed while Run Mode is visible (local or remote),
  auto-exit to Groups Hub and never remain in an idle Run Mode state.
- The Groups Hub provides the next decision path (open Task List / start or plan a new group).
- Canceled groups remain visible in Groups Hub with a **Re-plan group** action; they never auto-start.

### **10.4.7. Mandatory visual improvements for the timer**

1. Fixed-width digital time (avoid jitter)

The MM:SS timer must not shift horizontally:

- Use FontFeature.tabularFigures() or a monospaced font
- Or fix each digit width with SizedBox

2. Current system time (inside the circle)

- Shown inside the circle (top of vertical stack)
- Format: HH:mm
- Updates every 60s
- Visible regardless of state or window size

### **10.4.8. Multi-device sync in TimerScreen**

- If an activeSession exists, the screen connects in mirror mode and reflects the remote state.
- Only the ownerDeviceId can start/pause/resume/cancel in **Run Mode**; mirror devices can request ownership.
  - **Exception (Pre-Run Countdown):** there is no owner and any device may cancel while the Pre-Run window is active.
- activeSession includes: groupId, currentTaskId, currentTaskIndex, totalTasks.
- Remaining time is projected from phaseStartedAt + phaseDurationSeconds using the
  server-time offset from lastUpdatedAt (same rule as activeSession); never project
  from raw local clock alone.
- Mirror devices render task names/durations from the TaskRunGroup snapshot (by groupId), not from the editable task list.
- **Single source of truth:** owner/mirror state and control gating must be derived from the same activeSession snapshot
  (groupId must match). Local flags may project state but must never override the snapshot.
- When auto-open is triggered from launch/resume, open TimerScreen in mirror mode if the session belongs to another device.
- On `AppLifecycleState.resumed`, force an immediate sync (activeSession + group)
  before enabling controls. While resyncing, the UI must not show a transient
  **Ready** state; show a loader or keep the last snapshot until the stream updates.
- Desktop sleep/wake (macOS/Windows/Linux): invalidate any local owner assumption
  and re-verify Firestore before enabling owner controls.
- Desktop inactive keepalive: while a group is running and the window is inactive,
  periodically re-sync activeSession (≈15s) to surface ownership requests and avoid
  stale controls. Stop when the window is active.
- If a group is **running** but `activeSession` is temporarily missing (stream
  reconnecting), show **Syncing session...** instead of rendering potentially
  stale state. Keep the ownership indicator visible (neutral/last-known) but
  disable controls and hide task ranges until the session arrives.
- After a scheduled auto-start, the **first device that starts the session** becomes the owner.
  Other devices open in mirror mode and remain there until ownership is approved.
- Conflict-resolution flows (late-start overlap queue, running overlap decision)
  are owner-only. If no owner is active, the first active device auto-claims
  ownership before presenting any decision UI.
- When ownership changes, mirror devices must discard any local projection and
  re-anchor exclusively to the activeSession timestamps (recompute server-time offset)
  so pause/resume stays globally consistent.
- Initial ownership is deterministic: the device that **initiates the run**
  (Start now or auto-start) must be the first owner.
- For scheduled runs, `scheduledByDeviceId` is **metadata only** and must not block
  auto-start or ownership; any device can claim at the scheduled time.
- For Start now, only the initiating device (`scheduledByDeviceId`) should claim
  the initial session; other devices wait for the activeSession.
- Ownership transfer is explicit:
  - Mirror devices send a request (ownershipRequest) and remain in mirror while pending.
  - The current owner must explicitly accept or reject.
  - The requester must switch to a **pending** UI state immediately on tap
    (optimistic), and this pending state must not be cleared by transient
    snapshot gaps.
  - Rejected requests show a brief rejection state on the requester and a small
    rejection indicator near the request control (tap for time/details). The
    requester can re-submit at any time.
- Ownership changes only after approval when the owner is active. If the owner is
  inactive (stale lastUpdatedAt):
  - **Running:** any mirror device may auto-claim even without a manual request.
  - **Paused:** only a requester with a pending ownershipRequest may auto-claim.
  This is based on session liveness (heartbeat), not app focus.

### **10.4.9. Ownership visibility in Run Mode**

- The owner/mirror rule must be visible and understandable without banners.
- Show a persistent, compact indicator in the Run Mode header:
  - Owner: green icon (e.g., shield/check).
  - Mirror: eye icon (e.g., visibility).
- The ownership indicator is **always visible** in Run Mode (including while syncing).
  If the session is temporarily missing, keep the last known state or show a neutral
  syncing variant, but never hide the indicator.
- The indicator itself is tappable and opens a small sheet/popover explaining:
  - Whether this device is Owner or Mirror.
  - Which actions are allowed or blocked.
  - Which device currently owns the session, using the account display name + platform label when available
    (e.g., "Marcos (Web)"); if no display name exists, fall back to "Account (Platform)" or platform-only.
- When the device is in mirror mode, provide an explicit “Request ownership” action
  **inside the ownership sheet** (AppBar indicator). The current owner must accept or reject.
- The request action is only exposed inside the ownership sheet to keep the main
  control row consistent and avoid transient UI states.
- **Hard requirement (do not change):** the Request action must not appear in the
  main control row. Any change to this rule requires an explicit specs update.
- On compact layouts, the request label inside the sheet may be shortened
  (e.g., “Request”) to avoid overflow.
- The request button may include the owner icon (same as the header indicator) to
  improve clarity; keep it compact on narrow screens.
- Rejection feedback should be non-intrusive: show a snackbar with the rejection time,
  a subtle rejection icon/accent (muted red/orange) for immediate clarity, and require
  an explicit “OK” dismiss; also include the last rejection time inside the ownership
  info sheet. Do not add persistent inline icons that force the control row to overflow.
- If the requester later **obtains ownership** or **submits a new request**, any
  prior rejection snackbar must auto-dismiss to avoid stale/confusing feedback.
- The owner-side ownership request prompt should render as a floating overlay
  (light modal/banner) that does not push or reflow the existing layout. It must
  avoid overflow and should not collide with the AppBar or top widgets. The
  background must be opaque (no transparency) for clear legibility.
- If the owner is **not** in Run Mode when a request arrives, surface the same
  approve/reject prompt in **Groups Hub** and **Task List** (banner or modal),
  so the owner can respond without navigating to Run Mode.
- Tapping **Accept** or **Reject** must dismiss the owner-side request prompt
  immediately (optimistic UI), without waiting for remote snapshot latency.
- When a mirror device has a pending ownership request, show the pending state
  only via the AppBar ownership indicator (e.g., amber/orange). Do not render
  inline or overlayed body text; the ownership info sheet should include the
  "Waiting for owner approval..." message.
- When the requester taps **Request ownership**, the pending (amber) indicator
  must appear immediately (optimistic UI) without waiting for a remote snapshot.
  Clear the optimistic state once the stream confirms the request (pending,
  rejected, or approved), or if the request fails.
- If the remote snapshot still contains a **previous rejection** for the same
  requester, the UI must **not** drop the new pending state. Reconcile by
  `requestId` (or timestamps for legacy requests) so new requests are always
  reflected immediately.
- A rejection is scoped to the **same requestId** only. It must **never**
  suppress a newer request from the same device.
- If a pending ownership request exceeds the stale threshold, surface a **Retry**
  action and allow the requester to re-send the request.
- Show a one-time, non-blocking education message on the first owner start
  (Start now or auto-start) per device:
  - “This device controls the execution. Other devices will connect in view-only mode.”
  - Include “Don’t show again” (stored locally on the device).

---

## **10.5. Groups Hub screen**

Purpose: central view to track scheduled, running, and completed TaskRunGroups. It is the default landing screen after group completion. Note: this screen is independent from the task list/editor, but it provides a direct path to the Task List screen.

Entry points

- Run Mode header
- Auto-navigation after group completion (see sections 10.4.6 and 12)
- Task List banner when a group is running or paused (see section 10.2.5)
- Task List always exposes a direct “View Groups Hub” CTA in the content area,
  even when no group is running or in pre-run. Do not add AppBar actions.

List fields per group

- **Group name** (primary title on the card)
- If status = canceled and canceledReason is present, show a short reason label:
  - interrupted → "Interrupted"
  - conflict → "Conflict"
  - missedSchedule → "Missed schedule"
  - user → "Canceled"
- If canceledReason is missing, default to "Canceled".
- The reason label is **tappable**. On tap, show a modal explaining the
  cancellation circumstance in plain language (e.g., conflict due to overlap,
  missed schedule because the start time already passed, user-canceled, or
  interrupted by ending a running group early). Include a note that canceled
  groups can be re-planned from Groups Hub.
- Scheduled start time (only for scheduled groups; omit when scheduledStartTime is null)
- Scheduled start time is the **run start** time (not the pre-run start).
- If `postponedAfterGroupId` is set and the anchor group is running/paused, show
  the **effective scheduled start** derived from the anchor’s projected end +
  noticeMinutes, and update it in real time.
- Theoretical end time
- Number of tasks
- Total duration
- Pre-Run start time (scheduled groups only):
  - Show **“Pre-Run X min starts at HH:mm”** when noticeMinutes > 0.
  - Omit this row when noticeMinutes = 0 or scheduledStartTime is null.
  - Do not show a separate “Notice” row; the Pre-Run row is the notice display.
- For any time field shown on the card, display **only HH:mm** when the date is
  today, and show **date + time** when the date is not today (scheduled or completed).
- If a card shows a countdown or projected start (e.g., "Starts in"), it must
  update in real time while visible (projection only; never authoritative).

Actions

- Tap -> light detail view (summary)
  - Rename group (pencil/edit action)
  - Cancel planning → mark the group as canceled (canceledReason = user)
  - Start now (only if no conflicts)
  - Open Run Mode for running/paused groups
  - Run again (completed groups): duplicate the group snapshot into a new TaskRunGroup and open the pre-start planning flow
  - Re-plan group (canceled groups): duplicate the group snapshot into a new TaskRunGroup and open the pre-start planning flow
  - Go to Task List screen (Task Library) to create/edit tasks and build new groups
    - The "Go to Task List" CTA is a **sticky header** outside the scrollable
      list, so it is always visible while scrolling.

Summary (tap on a group)

- Present a compact **summary modal or sheet** with a black background and clear
  section labels. The content must be scrollable.
- Content (no redundancy with the card; focus on extra clarity):
  - **Group name** (primary title inside the modal)
  - **Status** (chip or label)
  - **Timing**: scheduled start (if any), actual start (if available), end time,
    total duration, notice minutes (scheduled groups only). If the group has no
    scheduledStartTime, omit the Scheduled start row entirely (no placeholder).
  - **Totals**: total tasks, total pomodoros (if available)
  - **Tasks list**: each task shown as a compact card with:
    - Task name
    - Task color accent (chip/outline)
    - Pomodoro count + duration
    - Short/long break durations
    - Long-break interval dots
  - The layout must be legible, professional, and easy to scan on mobile.

History

- Show scheduled + running + last N completed groups + last N canceled groups
- Keep history short and finite
- When a scheduled group is within the Pre-Run window, the card must expose a clear
  "Open Pre-Run" action (instead of “Start now”), so the user can always return to
  the Pre-Run view.
- Canceled groups never auto-start; they are reference-only for re-planning.

---

## **10.6. Advanced window, responsiveness, and visual accessibility requirements**

A. Resizable window (mandatory)

1. Allow horizontal and vertical resizing.
2. Content must adapt automatically.
3. The circle and all UI components scale proportionally as the window grows (no max scale).

B. Minimum window size

- Enforce a minimum size that keeps the full vertical stack inside the circle visible, aligned, and legible.
- The app should open at this minimum optimal size.
- Avoid shrinking UI elements below a minimum legibility/usability threshold.

C. Responsive clock

- Always centered

---

## **10.7. Transient feedback (SnackBars)**

- SnackBars must not cover bottom-aligned actions or primary controls.
- Keep SnackBars standard (default behavior/animation).
- Place bottom actions in `Scaffold.bottomNavigationBar` or `persistentFooterButtons` so SnackBars appear above them.
- Never clipped or distorted
- Text remains legible at minimum size
- Internal vertical stack (current time, countdown, status boxes) stays inside the circle

D. Pause and resume

- Pause freezes the ring progress (marker) and countdown
- Pause also freezes the **group progress bar** (no fill advance)
- Resume continues from exact point
- On resume, recalculate projected start/end times used in the status boxes and contextual task list
- No sound on pause/resume

E. Black background

- Dark theme background must be pure black (#000000)
- No gradients or transparency
- Light theme uses a light background with strong contrast for readability.

F. Guaranteed clock visibility

- Buttons and list must not overlap the circle
- The contextual list sits below the circle (portrait layouts)
- The list scales proportionally with the rest of the UI

G. Mobile landscape layout

When isMobile && isLandscape (iOS / Android):

- Move the status boxes and contextual list to the right of the circle
- Keep the circle unobstructed
- Preserve the vertical order of the status boxes

H. Clear labeling and icon support

- UI labels and names must be unambiguous.
- If a label could still be unclear, add a supporting icon.

I. Button clarity and usability

- Buttons must look modern, be clearly defined, and be immediately discoverable as interactive elements.

---

# ⚙️ **10.8. Settings / Preferences**

Entry point

- A standard Settings/Preferences entry must be discoverable without guidance.
- Primary access: a top-right gear icon on the Task List screen.
- Desktop: also expose Settings/Preferences in the app menu.
- Settings must remain accessible in Local Mode (at least Manage Presets and Preferences).

Content

- Language selector with system auto-detect by default (user can override).
- Theme selector lives here; dark and light modes are both available in MVP.
- All app-wide configuration options are centralized in this menu.
- Account profile (Account Mode only):
  - Display name (optional). Empty values clear the name.
  - Avatar image (optional): pick, crop if needed, then compress to <= 200 KB
    (target max 512px) before upload.
  - Upload to Firebase Storage at user_avatars/{uid}/avatar.jpg and store the
    download URL in users/{uid}.avatarUrl.
  - Provide a Remove avatar action (clears avatarUrl; deletes storage object best-effort).
  - Hide this section in Local Mode.
- **Global sound configuration** (Pomodoro start, Break start, Task finish):
  - Settings store the selected global sounds but do **not** apply them unless the
    **Apply globally** switch is turned **ON**.
  - When the switch turns ON, apply the global sounds to **all existing tasks** in the
    current scope (Local or Account). Show a clear confirmation/warning before applying.
  - Presets are **never** modified.
  - After applying:
    - If a task’s resulting sounds match its preset exactly, it keeps the preset link.
    - If they differ, the task switches to **Custom** due to sound changes.
  - New tasks:
    - Switch ON → default to global sounds.
    - Switch OFF → follow preset/default behavior.
  - Provide a **Revert to previous sounds** action:
    - Restores the sound configuration that existed **before the last switch activation**.
    - Applies only to tasks that still exist.
    - Tasks created after the last activation are not reverted.
    - After revert, the switch turns OFF and a brief notice explains how to reapply.
- **Pre-Run notice minutes** (scheduled groups):
  - Default: **5 min**.
  - Range: **0–15 min** (0 disables Pre-Run Countdown Mode entirely).
  - Account Mode: stored **per account** and synced across devices.
  - Local Mode: stored **per device** (local only).
  - Applies to **new scheduled groups**; each TaskRunGroup stores the noticeMinutes
    snapshot at scheduling time.
  - If a legacy scheduled group is missing noticeMinutes, resolve it from the
    current settings at evaluation time and treat that value as the group notice
    (UI should display the resolved notice to avoid confusion).

---

# 🔔 **11. Notifications**

- Notification when each pomodoro ends
- Notification when the group ends
- Scheduled groups:
  - Send a pre-alert based on noticeMinutes
  - If the app is open, Pre-Run Countdown Mode is shown and the system notification is suppressed to avoid duplicate alerts
- Notifications are intended to be silent; audio comes from the app sounds
  - Web: use the browser Notifications API (permission required; app must be open)
  - Web: request silent notifications when supported, but actual sound behavior follows browser/OS rules
- Desktop adapters: Windows/Linux use `local_notifier`; other platforms use `flutter_local_notifications`.

---

# 🚨 **12. Mandatory key behavior (expanded and definitive version)**

✔ Strict group completion behavior

When the timer completes the last pomodoro of the last task:

1. The app must stop automatically.
2. It must play the final sound (same as task finish for now).
3. It must show a modal popup with:
   - "Tasks Group completed"
   - Optional summary: total tasks, pomodoros, total time
   - The modal must appear on both owner and mirror devices while Run Mode is visible.
   - If the app is not active and the modal cannot be shown, show it on next foreground;
     if it still cannot be presented, auto-navigate to Groups Hub to avoid an idle Run Mode state.
4. It must send a system notification.
5. The state machine transitions to finished.
6. The clock screen must:
   - Stop animation
   - Keep the ring fully closed with the marker at the final position (12 o'clock)
   - Change the circle color to green or gold
   - Show "TASKS GROUP COMPLETED" in the center
7. After the user explicitly dismisses the completion modal, navigate to the Groups Hub screen (do not remain in an idle Execution screen and do not use a time-based auto-dismiss).
8. If a new group auto-opens (pre-run or run) while the completion modal is visible, auto-dismiss the modal and skip the Groups Hub navigation so the new run can proceed.

✔ No popup between tasks

- Completing a task inside a group must not stop the timer.
- The next task starts automatically.

---

# 🔄 **13. Real-time multi-device sync (MVP)**

- Single writer (owner device) publishes events.
- Mirror devices calculate time locally.
- If a group is running, other devices:
  - Enter mirror mode
  - May auto-take over when the owner session is stale (>= 45s without heartbeat)
- Group execution uses groupId + currentTaskIndex to maintain full context.

---

# 📈 **14. Roadmap**

Release order is fixed: v1.0 → v1.1 → v1.2 (MVP store release).
v1.0 and v1.1 are internal milestones that must be completed before the v1.2 release.

v1.0 (internal milestone)

- Implement all requirements in sections 1-13 inclusive.
- Email verification for email/password before enabling sync.
- Theme: dark and light modes (selector in Settings).
- Language selector with system auto-detect + override.
- Task editing quality: apply settings to remaining tasks, unique task names validation.
- Execution UX: status boxes and contextual task list show time ranges, recalculated after pause/resume.
- Session continuity: auto-open the execution screen on launch/login when a session is running.
- UI clarity: unambiguous labeling with icon support; modern, clearly defined, discoverable buttons.

v1.1 (internal milestone)

- Statistics (chart of tasks completed per day/week).
- Export tasks as a file.

v1.2 (MVP release)

- Floating widgets "always on top".
- Global keyboard shortcuts.
- Minimal mode.
- Cross-platform offline cache (Hive-based).
