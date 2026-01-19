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

The app syncs with Firebase via Google Sign-In on iOS/Android/Web and email/password on macOS/Windows; Linux runs in local-only mode (no Firebase Auth).

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

| Area                   | Technology                                                |
| ---------------------- | --------------------------------------------------------- |
| UI Framework           | Flutter 3.x                                               |
| Auth                   | Firebase Authentication (Google Sign-In + email/password) |
| Backend                | Firestore                                                 |
| Local Cache (optional) | SharedPreferences (Linux local-only tasks/groups); Hive (v1.2) |
| State Management       | Riverpod                                                  |
| Navigation             | GoRouter                                                  |
| Audio                  | just_audio                                                |
| Notifications          | flutter_local_notifications                               |
| Logging                | debugPrint (MVP); logger (post-MVP)                       |
| Architecture           | MVVM (Model–View–ViewModel)                               |

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
│   │   └─ task_list_view_model.dart
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

These conflict checks apply to both Comenzar ahora and Planificar comienzo.

Scheduled start behavior

- Send the pre-alert noticeMinutes before scheduledStartTime.
- At scheduledStartTime, automatically start the group and open the execution screen.

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

## **8.2. Local cache (optional)**

- Current: SharedPreferences-backed storage for Linux local-only tasks and TaskRunGroups
  (local execution works without sign-in; no cross-device sync).
- Planned (v1.2): Hive-based cache for cross-platform offline storage.

## **8.3. Active Pomodoro session (real-time sync)**

users/{uid}/activeSession

- Single document per user with the active session.
- Must include groupId, currentTaskId, currentTaskIndex, and totalTasks.
- Only the owner device writes; others subscribe in real time and render progress by calculating remaining time from phaseStartedAt + phaseDurationSeconds.
- On app launch or after login, if an active session is running (pomodoroRunning/shortBreakRunning/longBreakRunning), auto-open the execution screen for that group.

## **8.4. TaskRunGroup retention**

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

Mandatory login (by platform)

- iOS / Android / Web:
  - Button: “Continue with Google”
  - Opens browser or WebView
  - Gets uid, email, displayName, photoURL
- macOS / Windows:
  - Email/password login (no Google Sign-In)
  - Gets uid, email (and optionally name)
- Linux:
  - Firebase Auth is unavailable; login entry point is hidden
  - Local-only tasks and TaskRunGroups; no cloud sync

Persistence

The session remains active on all devices with Firebase Auth support.

Email verification (email/password)

- Require email verification to confirm ownership of the address before enabling sync.
- Unverified accounts must not block real owners from registering later.

---

# 🖼️ **10. User interface**

## **10.1. Login screen**

- Logo
- Google button (iOS/Android/Web)
- Email/password form (macOS/Windows)
- Login entry hidden on Linux (local-only mode)
- Text: “Sync your tasks in the cloud”

---

## **10.2. Task List screen (group preparation)**

### **10.2.1. Task list**

- Manual ordering via drag & drop
- Order is persisted after reordering
- Selection by checkbox (tasks to include in the group)

Item layout (left → right):

1. Checkbox (no special colors)
2. Task title
3. Theoretical time (start/end) for selected tasks
4. Edit icon (pencil, light gray)
5. Delete icon (trash, red)
6. Reorder handle (≡, neutral gray) — only this area is draggable

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

---

## **10.3. Task Editor**

Inputs:

- Name
- Pomodoro duration (minutes)
- Short break duration
- Long break duration
- Total pomodoros
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

---

## **10.4. Execution Screen (Run Mode)**

The execution screen shows an analog-style circular timer with a dynamic layout tailored for TaskRunGroups.

### **10.4.1. Pre-start planning (before the timer begins)**

- The user chooses when to run the group after tapping “Confirmar”.
- Show a date + time picker (default: current date/time).
- Two explicit actions:
  - Comenzar ahora → start immediately
  - Planificar comienzo → schedule the start time
- Conflicts are validated for both actions (see section 6.4)
- If a schedule is set:
  - Recalculate theoretical start/end times using the selected start time
  - Save as scheduled and add to Planned Groups
  - Send the pre-alert noticeMinutes before the scheduled start
  - At the scheduled time, auto-open the execution screen and auto-start the group
  - The timer remains stopped until the scheduled start

### **10.4.2. Header**

- Back button + title (Focus Interval)
- Access to Planned Groups screen (show a visual indicator when pending groups exist)

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
  - If another break follows:
    - Blue border/text, black background
    - Text: Descanso: N min
    - Time range: HH:mm–HH:mm
  - If it is the last pomodoro of the task:
    - Golden-green border/text, black background
    - Text: Fin de tarea
    - End time: HH:mm

Break running

- Current status:
  - Blue border/text, black background
  - Text: Descanso: N min
  - Time range: HH:mm–HH:mm
- Next status:
  - Red border/text, black background
  - Text: Siguiente: Pomodoro Y de X
  - Time range: HH:mm–HH:mm

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

- Task completion → auto-transition to next task
- No modal between tasks
- Group completion → modal + final animation (see section 12)
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

---

## **10.5. Planned Groups screen**

Purpose: manage scheduled and running groups (not tasks). Note: this screen is independent from the task list/editor.

List fields per group

- Scheduled start time
- Theoretical end time
- Number of tasks
- Total duration
- Pre-alert setting (e.g., “Aviso 5 min antes”)

Actions

- Tap → light detail view (summary)
- Cancel planning
- Start now (only if no conflicts)

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

# ⚙️ **10.7. Settings / Preferences**

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
- Notifications are silent; audio comes from the app sounds
- Desktop adapters: Windows/Linux use `local_notifier`; other platforms use `flutter_local_notifications`.

---

# 🚨 **12. Mandatory key behavior (expanded and definitive version)**

✔ Strict group completion behavior

When the timer completes the last pomodoro of the last task:

1. The app must stop automatically.
2. It must play the final sound (same as task finish for now).
3. It must show a modal popup with:
   - “Tasks Group completed”
   - Optional summary: total tasks, pomodoros, total time
4. It must send a system notification.
5. The state machine transitions to finished.
6. The clock screen must:
   - Stop animation
   - Keep the hand in its final position (360°)
   - Change the circle color to green or gold
   - Show “TASKS GROUP COMPLETED” in the center

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
