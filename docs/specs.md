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
- Play internal app sounds for state changes (notifications remain silent)

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

  int pomodoroDuration; // minutes
  int shortBreakDuration;
  int longBreakDuration;

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
    required this.pomodoroDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
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

  List<TaskRunItem> tasks; // ordered snapshots
  DateTime createdAt;

  DateTime? scheduledStartTime; // null when "Start now"
  DateTime theoreticalEndTime;  // required for overlap checks

  String status; // scheduled | running | completed | canceled
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

  int pomodoroDuration;
  int shortBreakDuration;
  int longBreakDuration;
  int totalPomodoros;
  int longBreakInterval;

  String startSound;
  String startBreakSound;
  String finishTaskSound;
}
```

Notes:

- theoreticalEndTime is calculated when the group is scheduled or started, using scheduledStartTime (if set) or now (for immediate start). Recalculate if the start time changes.
- Expected lifecycle: scheduled -> running -> completed (or canceled).
- Conceptual pre-run state: scheduled -> preparing -> running (preparing is UI-only and does not change the model).
- A scheduled group must transition to running at scheduledStartTime.
- Editing a PomodoroTask after group creation does not affect a running or scheduled group.

## **5.3. PomodoroSession model (live sync)**

```dart
class PomodoroSession {
  String id; // sessionId
  String groupId;        // TaskRunGroup in execution
  String currentTaskId;  // TaskRunItem.sourceTaskId
  int currentTaskIndex;
  int totalTasks;

  String ownerDeviceId; // device that writes in real time

  PomodoroStatus status; // pomodoroRunning, shortBreakRunning, longBreakRunning, paused, finished, idle
  PomodoroPhase? phase;
  int currentPomodoro;
  int totalPomodoros;

  int phaseDurationSeconds; // duration of the current phase
  int remainingSeconds;     // required for paused; running is projected from phaseStartedAt
  DateTime phaseStartedAt;  // serverTimestamp on start/resume
  DateTime lastUpdatedAt;   // serverTimestamp of the last event
  DateTime? finishedAt;     // serverTimestamp when the group reaches completed
  String? pauseReason;      // optional; "user" when paused manually
}
```

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
- When the last task completes:
  - The group ends (status = completed).
  - Final modal + final animation are shown (see section 12).
  - After the user explicitly dismisses the completion modal, auto-navigate to the Groups Hub screen (no time-based auto-navigation).

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
- If the app is open during the pre-alert window, show the Pre-Run Countdown Mode (see section 10.4.1.a).
- If the app is closed during the pre-alert window, send a silent notification.
- At scheduledStartTime:
  - Set status = running.
  - Set actualStartTime = now.
  - Recalculate theoreticalEndTime = actualStartTime + totalDurationSeconds.
  - Automatically open the execution screen and start the group.
  - Ownership is claimed by the first device that starts the session.
  - If the scheduling device is not active, another signed-in device may claim and become owner immediately.
- If the app was inactive at scheduledStartTime:
  - On next launch/resume, if scheduledStartTime <= now and there is no active conflict,
    auto-start immediately using actualStartTime = now.
  - scheduledStartTime remains as historical data and is not overwritten.

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
- Post-MVP: make the task finish sound configurable.

Allowed formats:

- .mp3
- .wav

Sounds can be:

- Included in the app (assets)
- Or loaded by the user (local file picker)

Platform notes:

- Windows audio uses an `audioplayers` adapter via SoundService.
- Other platforms use `just_audio`.

---

# 💾 **8. Persistence and sync**

## **8.1. Firestore (primary)**

- users/{uid}/tasks/{taskId}
- users/{uid}/taskRunGroups/{groupId}
- Linux: Firebase Auth/Firestore sync is unavailable; tasks and TaskRunGroups are stored locally (no cloud sync).

## **8.2. Local Mode (offline / no auth)**

- Local Mode is a first-class backend available on all platforms.
- Users can explicitly choose between Local Mode (offline, no login) and Account Mode (synced).
- Local data uses the exact same models (tasks, TaskRunGroups, sessions) for future compatibility.
- Local Mode scope is strictly device-local; Account Mode scope is strictly user:{uid}.
- There is no implicit sync between scopes.
- Switching to Account Mode can offer a one-time import of local data only after explicit user confirmation.
- Import targets the currently signed-in UID and overwrites by ID (no merge) in MVP 1.2.
- Switching back to Local Mode keeps local data separate and usable regardless of login state.
- Logout returns to Local Mode without auto-import or auto-sync.

## **8.3. Local cache (optional)**

- Current: SharedPreferences-backed storage for Local Mode tasks and TaskRunGroups.
- Planned (v1.2): Hive-based cache for cross-platform offline storage.

## **8.4. Active Pomodoro session (real-time sync)**

users/{uid}/activeSession

- Single document per user with the active session.
- Must include groupId, currentTaskId, currentTaskIndex, and totalTasks.
- Only the owner device writes; others subscribe in real time and render progress by calculating remaining time from phaseStartedAt + phaseDurationSeconds.
- On app launch or after login, if an active session is running (pomodoroRunning/shortBreakRunning/longBreakRunning), auto-open the execution screen for that group.
- Auto-open must apply on the owner device and on mirror devices (mirror mode with optional take over).
- If auto-open cannot occur (missing group data, blocked navigation, or explicit suppression), the user must see a clear entry point to the running group from the initial screen and from Groups Hub.

## **8.5. TaskRunGroup retention**

- Keep:
  - All scheduled
  - The current running
  - The last N completed
- canceled groups can be removed immediately or kept in the short history.
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
- macOS / Windows: browser-based OAuth if available; otherwise deferred/unavailable
- Linux: unavailable (Account Mode disabled)

Mode selection

- Users can choose Local Mode without login on any platform.
- Users can switch between Local Mode and Account Mode at any time.
- GitHub login is an optional Account Mode provider that yields the same uid identity as other providers (not a separate account system).
  - If GitHub is not supported on a platform, fall back to existing providers without changing Local Mode.

Persistence

- Account sessions remain active on all devices with Firebase Auth support.

Email verification (email/password)

- Require email verification to confirm ownership of the address before enabling sync.
- Unverified accounts must not block real owners from registering later.

---

# 🖼️ **10. User interface**

## **10.1. Login screen**

- Logo
- Google button (iOS/Android/Web)
- GitHub button only where supported (same screen, secondary action; keep UI complexity flat)
- Email/password form (macOS/Windows)
- Login entry hidden on Linux (Account Mode unavailable)
- Text: “Sync your tasks in the cloud”

---

## **10.2. Task List screen (group preparation)**

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
   - Task name (up to 2 lines, ellipsized)
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

3. **Time range row (only when selected)**
   - Label: **Time range**
   - Two chips: start time and end time (theoretical schedule preview)

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

- Calculated assuming “Start now” (recomputed if a scheduled start is later chosen)
- For each selected task, show:
  - Estimated start time
  - Estimated end time
  - Only selected tasks show theoretical times
- Recalculate when:
  - Current time changes
  - Tasks are reordered
  - Selection changes
  - Scheduled start time changes (planned start)

### **10.2.3. Confirm action**

- Bottom button: “Confirmar”
- Enabled only if at least 1 task is selected
- On press:
  - Create a TaskRunGroup snapshot
  - Navigate to the execution screen pre-start planning (see section 10.4)

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

---

## **10.3. Task Editor**

Inputs:

- Name
- Pomodoro duration (minutes)
- Short break duration
- Long break duration
- Total pomodoros
- Task weight (%)
- Long break interval
- Select sounds for each event

Buttons:

- Save
- Cancel
- Apply settings to remaining tasks

Behavior:

- "Apply settings to remaining tasks" copies the current task configuration to all remaining tasks in the list (after the current task).
- Applies to all task settings except Name (pomodoro duration, short break duration, long break duration, total pomodoros, long break interval, sound selections).
- Task names are always unique within the list; block Save/Apply and show a validation error if the edited name duplicates another task name.
- Task name is required (non-empty). Persisting a task with an empty name is not allowed.
- Break durations must be shorter than the pomodoro duration; block Save/Apply and show a clear error if they are equal or longer.
- Short break duration must be strictly less than long break duration; block Save/Apply and show errors on both fields if violated.
- When a blocking break validation error is present, suppress optimization guidance/helper text until resolved.
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
- Planned: show task weight as both total pomodoros and a derived percentage of the group total.
- Planned: when editing the percentage, suggest the closest valid integer pomodoro count and update the displayed percentage accordingly (pomodoros are never fractional).
- Planned: display Total pomodoros and Task weight (%) on the same row directly below the task name to emphasize task weight.

### **10.3.x. Pomodoro integrity + task weight (planned, documentation-first)**

Goal: preserve Pomodoro technique integrity across consecutive tasks while keeping flexibility for mixed configurations.

Definitions:

- **Pomodoro structural configuration**: pomodoro duration, short break duration, long break duration, long break interval.
- **Task weight**: totalPomodoros (authoritative integer) and derived percentage of the group total.

Execution modes for TaskRunGroups:

- **Mode A — Shared Pomodoro Structure (recommended)**
  - The group defines the structural configuration.
  - All tasks share the same pomodoro/break durations and long-break interval.
  - Tasks differ only by `totalPomodoros` (weight).
- **Mode B — Per-task Pomodoro Configuration (current behavior)**
  - Each task keeps its own structural configuration.
  - The app shows an informational warning that Pomodoro benefits may be reduced.
  - The user may continue without restrictions.

Task weight rules:

- Each task has an authoritative integer `totalPomodoros` and a derived percentage.
- Percentage is always computed from integer pomodoros and rounded for display.
- When a user edits the percentage:
  - The system proposes the closest valid integer pomodoro counts.
  - Exact percentages are not guaranteed.
  - Pomodoros and breaks are never split.

UI implications (documentation only):

- Task List should display both totalPomodoros and derived percentage of the group total.
- Task Editor should display totalPomodoros and derived percentage, with live recalculation when either value changes.
- Task Editor should place Total pomodoros + Task weight (%) together, above Pomodoro structural configuration and sounds.
- If a TaskRunGroup mixes structural configurations, show a clear integrity warning (education-only).

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

- Presets are selectable from the Task Editor when creating or editing a task.
- Presets can be created, renamed, edited, and deleted from within the Task Editor context.
- One preset can be marked as **default** and applied automatically to new tasks.
- A task may either:
  - reference a saved preset, or
  - use a custom, task-specific configuration.
- Backward compatibility: tasks without a preset behave as custom tasks using their stored values.

---

## **10.4. Execution Screen (Run Mode)**

The execution screen shows an analog-style circular timer with a dynamic layout tailored for TaskRunGroups.

### **10.4.1. Pre-start planning (before the timer begins)**

- The user chooses when to run the group after tapping "Confirm".
- Show a date + time picker (default: current date/time).
- Two explicit actions:
  - Start now -> start immediately
  - Schedule start -> schedule the start time
- Conflicts are validated for both actions (see section 6.4)
- If a schedule is set:
  - Recalculate theoretical start/end times using the selected start time
  - Save as scheduled and add to Groups Hub
  - Send the pre-alert noticeMinutes before the scheduled start
  - If the app is open during the pre-alert window, automatically open Run Mode in Pre-Run Countdown Mode
  - If the app is closed during the pre-alert window, send a silent notification only
  - If the app is open during the pre-alert window, suppress any scheduled notification to avoid duplicate alerts
  - At the scheduled time:
    - Set status = running
    - Set actualStartTime = now
    - Recalculate theoreticalEndTime = actualStartTime + totalDurationSeconds
    - Auto-open the execution screen and auto-start the group
    - Ownership is claimed by the first device that starts the session
    - If the scheduling device is not active, another signed-in device may claim immediately
  - If the app was inactive at scheduledStartTime:
    - On next launch/resume, if scheduledStartTime <= now and there is no active conflict,
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

### **10.4.2. Header**

- Back button + title (Focus Interval)
- Access to Groups Hub screen (show a visual indicator when pending groups exist)

### **10.4.3. Circle core elements**

1. Large circular clock (progress ring style with a visible progress segment)
2. Animated hand / needle
   - Short, placed on the inner edge
   - Rotates counterclockwise (countdown)
3. Colors by state
   - Red (#E53935) → Pomodoro
   - Blue (#1E88E5) → Break
   - Progress segment uses the active state color

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

Note: There is **no break between tasks**. When a task finishes and there are more tasks in the group, the next task starts immediately.

Rule: the upper box always matches the current executing phase.

### **10.4.5. Contextual task list (below circle)**

Location: below the circle and above Pause/Cancel buttons.

- Max 3 items:
  - Previous task (completed)
  - Current task (in progress)
  - Next task (upcoming)
- No placeholders, no empty slots.
- Each item shows its time range (HH:mm–HH:mm).
- Completed tasks keep their actual time range; current/upcoming tasks are projected.

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

### **10.4.6. Transitions**

- Task completion -> auto-transition to next task
- No modal between tasks
- Group completion -> modal + final animation (see section 12)
- After the user explicitly dismisses the completion modal, auto-navigate to the Groups Hub screen (do not remain in an idle Execution screen)
- Status boxes and contextual list update automatically (including time ranges after pause/resume); no extra confirmations or animations in the MVP

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
- Only the ownerDeviceId can start/pause/resume/cancel; others show “Take over” if stale.
- activeSession includes: groupId, currentTaskId, currentTaskIndex, totalTasks.
- Remaining time is calculated from phaseStartedAt + phaseDurationSeconds.
- Mirror devices render task names/durations from the TaskRunGroup snapshot (by groupId), not from the editable task list.
- When auto-open is triggered from launch/resume, open TimerScreen in mirror mode if the session belongs to another device.
- After a scheduled auto-start, the first device that starts the session becomes the owner; other devices open in mirror mode until they take over.

---

## **10.5. Groups Hub screen**

Purpose: central view to track scheduled, running, and completed TaskRunGroups. It is the default landing screen after group completion. Note: this screen is independent from the task list/editor, but it provides a direct path to the Task List screen.

Entry points

- Run Mode header
- Auto-navigation after group completion (see sections 10.4.6 and 12)
- Task List banner when a group is running or paused (see section 10.2.5)

List fields per group

- Scheduled start time
- Theoretical end time
- Number of tasks
- Total duration
- Pre-alert setting (e.g., "Notice 5 min before")

Actions

- Tap -> light detail view (summary)
- Cancel planning
- Start now (only if no conflicts)
- Open Run Mode for running/paused groups
- Run again (completed groups): duplicate the group snapshot into a new TaskRunGroup and open the pre-start planning flow
- Go to Task List screen (Task Library) to create/edit tasks and build new groups

History

- Show scheduled + running + last N completed groups
- Keep history short and finite

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

- Pause freezes the hand and countdown
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

Content

- Language selector with system auto-detect by default (user can override).
- Theme selector lives here; dark and light modes are both available in MVP.
- All app-wide configuration options are centralized in this menu.

---

# 🔔 **11. Notifications**

- Notification when each pomodoro ends
- Notification when the group ends
- Scheduled groups:
  - Send a pre-alert based on noticeMinutes
  - If the app is open, Pre-Run Countdown Mode is shown but the notification is still sent
- Notifications are silent; audio comes from the app sounds
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
4. It must send a system notification.
5. The state machine transitions to finished.
6. The clock screen must:
   - Stop animation
   - Keep the hand in its final position (360°)
   - Change the circle color to green or gold
   - Show "TASKS GROUP COMPLETED" in the center
7. After the user explicitly dismisses the completion modal, navigate to the Groups Hub screen (do not remain in an idle Execution screen and do not use a time-based auto-dismiss).

✔ No popup between tasks

- Completing a task inside a group must not stop the timer.
- The next task starts automatically.

---

# 🔄 **13. Real-time multi-device sync (MVP)**

- Single writer (owner device) publishes events.
- Mirror devices calculate time locally.
- If a group is running, other devices:
  - Enter mirror mode
  - May “Take over” when stale
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
