# 📍 **Official Development Roadmap — Focus Interval (MVP store release v1.2)**

**Updated version — 100% synchronized with `/docs/specs.md` (v1.2.0)**

This document defines the development plan **step by step**, in chronological order, to fully implement the Focus Interval app according to the official MVP 1.2 specifications.

The AI (ChatGPT) must consult this document **ALWAYS** before continuing development, to keep technical and progress coherence.

This project includes an official team roles document at:
[docs/team_roles.md](team_roles.md)

---

# 🟦 **Global Project Status**

```
CURRENT PHASE: 18 — Run Mode Redesign for TaskRunGroups (in progress; Phase 17 reopen still pending)
NOTE: TimerScreen already depends on the ViewModel (no local timer/demo config).
      PomodoroViewModel exposed as Notifier auto-dispose and subscribed to the machine.
      Auth strategy: Google Sign-In on iOS/Android/Web (web verified; People API enabled); email/password on macOS/Windows; Linux auth disabled (local-only).
      Firestore integrated per authenticated user; tasks isolated by uid.
      Phase 7 (Firestore integrated) completed on 24/11/2025.
      Phase 8 (CRUD + reactive stream) completed on 17/12/2025.
      Phase 9 (Reactive list) completed on 17/12/2025. Windows test pending.
      Phase 10 (Editor with basic sounds) completed on 17/12/2025.
      Phase 11 (Event audio) completed on 17/12/2025.
      Phase 12 (Connect Editor → List → Execution) completed on 17/12/2025.
      Phase 13 completed on 06/01/2026: real-device sync validated (<1s), deviceId persistence added, take over implemented, reopen transitions verified.
      Phase 14 completed on 18/01/2026: sounds/notifications + custom picker aligned with MVP policy.
      Phase 15 completed on 18/01/2026: TaskRunGroup model/repo + retention settings added.
      15/01/2026: Execution guardrails prevent concurrent runs and block editing active tasks.
      17/01/2026: Specs updated to v1.2.0 (TaskRunGroups, scheduling, Run Mode redesign).
      17/01/2026: Local custom sound picker added (Pomodoro start/Break start); custom sounds stored per-device only; built-in options aligned to available assets; web (Chrome) local pick disabled; macOS/iOS/Android verified.
      19/01/2026: Windows validation completed for the latest implementations (no changes required).
      19/01/2026: Implemented TaskRunGroup auto-complete when running groups exceed theoreticalEndTime; device verification pending.
      19/01/2026: Phase 17 planning flow + conflict management implemented and validated on iOS/macOS/Android/Web; Windows/Linux pending.
      Scheduled auto-start lifecycle (scheduled -> running -> completed) and resume/launch catch-up pending.
      20/01/2026: Local vs Account scope guard implemented with explicit import dialog (no implicit sync).
      20/01/2026: Run Mode time ranges anchored to actualStartTime with final breaks and pause offsets; task transitions stabilized.
      24/01/2026: Documentation-first specs for Task Presets, Pomodoro integrity modes, and task weight (%) UI refinements added.
      24/01/2026: Documentation-first specs for optional GitHub Sign-In provider added.
      28/01/2026: Desktop GitHub OAuth (manual backend exchange) documented for macOS/Windows.
      29/01/2026: Desktop GitHub OAuth switched to GitHub Device Flow (no backend).
      24/01/2026: Task Editor enforces short break < long break validation to prevent invalid configs.
      24/01/2026: Task Editor prioritizes blocking break validation over guidance (cross-field errors shown).
      24/01/2026: Email verification gating + reclaim flow implemented (sync locked until verified).
      25/01/2026: Windows validation completed for email verification + reclaim flow (Account Mode).
      25/01/2026: Phase 6.6 completed with persistent Local/Account mode indicator across screens.
      25/01/2026: Phase 10 reopened items completed (unique-name validation + apply settings).
      25/01/2026: Phase 10 validation completed on Android/iOS/Web/macOS; Windows/Linux pending.
      25/01/2026: Phase 13 reopen item completed (auto-open running session on launch/login).
      25/01/2026: Active-session auto-open listener moved to app root (covers Task Editor/macOS).
      25/01/2026: macOS auto-open stabilized with navigator-ready retry (release build edge case).
      26/01/2026: Scheduled auto-start + resume/launch catch-up implemented (validation pending).
      26/01/2026: Scheduled auto-start allows any device to claim immediately at scheduled time.
      26/01/2026: Release validation — scheduled by Android (app closed), macOS open claimed owner; Android opened later in mirror mode.
      29/01/2026: Desktop GitHub device flow validated on macOS/Windows.
      29/01/2026: Local Mode running-group resume projects from actualStartTime when no session (no pause reconstruction).
      29/01/2026: Local Mode pause warning refined to contextual dialog + info affordance (no layout shift).
      29/01/2026: Android Gradle Plugin bumped to 8.9.1 (Gradle wrapper 8.12.1) to satisfy androidx metadata requirements.
      Hive planned for v1.2; logger deferred post-MVP; SharedPreferences used for Local Mode storage.
```

    ## 🔄 Reopened phases (must complete before moving on)

    - Phase 10.4 — Presets + weight UI + integrity warnings.
    - Phase 17 — Scheduled auto-start lifecycle + resume/launch catch-up.

Update this on each commit if needed.

---

# 🧩 **Roadmap Structure**

Development is divided into **24 main phases**, ordered to avoid blockers, errors, and rewrites.

Each phase contains:

- ✔ **Objective**
- ⚙️ **Tasks**
- 📌 **Exit conditions**
- 📁 **Files to create or modify**

---

# [✔] **PHASE 1 — Create Flutter project and folder structure (Complete)**

### ✔ Objective

Initialize the project with the base repository structure.

### ⚙️ Tasks

- `flutter create focus_interval`
- Create structure:

```
lib/
  app/
  data/
  domain/
  presentation/
  widgets/
docs/
assets/sounds/
```

### 📌 Exit conditions

- Project compiles on macOS
- Routes created correctly
- Initial README created

---

# [✔] **PHASE 2 — Implement the Pomodoro State Machine (Complete)**

_(Core of the app)_

### ⚙️ Tasks

- Create: `domain/pomodoro_machine.dart`
- Implement states:
  - idle
  - pomodoroRunning
  - shortBreakRunning
  - longBreakRunning
  - paused
  - finished

- Implement exact transitions per document ()
- Internal timer

### 📌 Exit conditions

- Basic tests working
- State machine stable and predictable

---

# [✔] **PHASE 3 — Premium Circular Clock (Complete)**

_(Main UI of the MVP)_

### ⚙️ Tasks

- Create `widgets/timer_display.dart`
- Implement:
  - Main circle
  - Animated progress
  - Rotating hand (–90° → 360°)
  - Smooth clock-like movement

- Dynamic colors per state:
  - Red for pomodoro
  - Blue for break

### 📌 Exit conditions

- Stable 60 fps animation
- Adapts to different window sizes
- Pixel-perfect rendering

---

# [✔] **PHASE 4 — Execution Screen (UI + partial integration) (Complete)**

### ⚙️ Tasks

- Create `presentation/screens/timer_screen.dart`
- Place `timer_display` inside
- Minimum buttons:
  - Pause
  - Resume
  - Cancel

### 📌 Exit conditions

- Functional screen
- Timer not yet connected to Firestore

---

# **PHASE 5 — Riverpod Integration (MVVM) (detailed in subphases)**

### [✔] **5.1 — Create Pomodoro ViewModel (Partially complete)**

- Create `PomodoroViewModel` extending `AutoDisposeNotifier<PomodoroState>`.
- Define initial state using `PomodoroState.idle()`.
- Include a single internal instance of `PomodoroMachine`.
- Expose public methods:
  - `configureTask(...)`

- `start()`
- `pause()`
- `resume()`
- `cancel()`

- Migration to AutoDisposeNotifier completed in Phase 5.3.

### [✔] **5.2 — Connect the state machine stream (Complete)**

- Subscribe to the stream that emits Pomodoro states.
- Map each event → update `state = s`.
- Handle `dispose()` correctly to close the stream.
- Ensure:
  - Pause → keeps current progress
  - Resume → continues from progress
  - Cancel → returns to idle state

### [✔] **5.3 — Unify all timer logic inside the ViewModel (Complete)**

- Remove manual `Timer.periodic` from `TimerScreen`.
- Control time exclusively from `PomodoroMachine`.
- Any change (remaining seconds, progress, phase) must come from the stream.
- Ensure the UI:
  - Does not calculate time
  - Does not manage timers
  - Updates only via `ref.watch(...)`

### 🟦 Actual status on 22/11/2025

- Main providers (machine, vm, repos, list, editor) are created and compiling.
- `TaskListViewModel`, `TaskEditorViewModel`, and related screens work correctly.
- `uuid` dependency added for task IDs.
- PomodoroViewModel exposed with `NotifierProvider.autoDispose`, subscribed to `PomodoroMachine.stream`.
- TimerScreen without demo config; loads the real task via `taskId` and uses the VM for states.
- Subphase 5.3 completed; current phase 8 (CRUD in progress).
- PHASE 5.5 completed: TimerScreen connected to tasks and final popup with completion color.
- Auth configured: Google on iOS/Android/Web; email/password on macOS/Windows; Linux auth disabled (local-only). `firebase_options.dart` generated and bundles unified (`com.marcdevelopez.focusinterval`).
- PHASE 7 completed: Firestore repository active per authenticated user, switching to InMemory without session; login/logout refresh tasks by uid.

### [✔] **5.4 — Create global providers**

- `pomodoroViewModelProvider`
- `taskRepositoryProvider` (placeholder)
- `firebaseAuthProvider` and `firestoreProvider` (placeholders for Phase 6)
- Export them all from `providers.dart`

### 🔄 Updated status:

Placeholder providers created (Phase 5.4 completed):

- firebaseAuthProvider
- firestoreProvider

Real integration pending for Phases 6–7.

### [✔] **5.5 — Refactor TimerScreen (Complete)**

- Consume state exclusively from Riverpod.
- Detect transition to `PomodoroStatus.finished` via `ref.listen`.
- Remove demo config entirely.
- Prepare the screen to receive a real `PomodoroTask` via `taskId`.
- Align dynamic buttons (Start/Pause/Resume/Cancel) to real ViewModel methods.
- Sync the UI with the final state:
  - Circle color change
  - “Task completed” message
  - Final popup

### ✔ Exit conditions

- The UI **contains no local Timer**.
- All time comes from the ViewModel.
- `TimerDisplay` updates exclusively via Riverpod.
- `TimerScreen` works entirely with MVVM logic.
- The state machine controls the full Pomodoro/Break cycle.
- Ready for PHASE 6 (Firebase Auth email/password on desktop).
- Clock responds to state changes
- Pause/resume works correctly

These subphases should also appear in **dev_log.md** as they are completed.

---

# [✔] **PHASE 6 — Configure Firebase Auth (Google on iOS/Android/Web; Email/Password on macOS/Windows; Linux auth disabled)**

### ⚙️ Tasks

- Integrate:
  - firebase_core
  - firebase_auth
  - google_sign_in (iOS/Android/Web only)
  - email/password flow for macOS/Windows (Linux auth disabled)

- Configure:
  - macOS App ID
  - Windows config
  - Linux config (Firebase Core only; auth disabled)
  - Web OAuth client ID + authorized domains for Google Sign-In
  - Android debug SHA-1/SHA-256 when Google Sign-In fails (see `docs/android_setup.md`)

- Add email verification flow for email/password accounts and block sync until verified.
- Ensure unverified accounts do not block real owners: allow re-registration or reclaim flow if the email remains unverified.

### 📌 Exit conditions

- Google login working on iOS/Android/Web
- Email/password login working on macOS/Windows
- Email/password users must verify email before enabling sync.
- Linux runs without auth and uses local-only tasks
- Persistent UID in the app

### 📝 Pending improvements (post-MVP)

- Remember the last email used on each device (stored locally) and allow autofill/password managers; never store the password in plain text.
- macOS: add Google Sign-In via OAuth web flow (browser + PKCE) if the project expands beyond MVP.

---

# [✔] **PHASE 6.6 — Local Mode (Offline / No Auth) (completed 25/01/2026)**

### ⚙️ Tasks

- Treat local storage as a first-class backend on all platforms (not Linux-only).
- Add explicit mode selection: Local Mode vs Account Mode.
- Persist the selected mode locally and allow switching at any time.
- Keep Local Mode data isolated from account data unless the user opts to import/sync.
- When switching to Account Mode, offer a one-time import of local tasks/groups.
- Add a persistent, unambiguous UI indicator showing the active mode across all screens.

### 📌 Exit conditions

- Users can work fully offline with tasks and TaskRunGroups on any platform.
- Mode can be switched at runtime without data loss.
- Local data can optionally be imported to the account when online.
- UI always makes the active mode explicit on every screen (no ambiguity about sync).

---

# [✔] **PHASE 6.7 — Optional GitHub Sign-In (Device Flow implemented) (completed 29/01/2026)**

### ⚙️ Tasks

- Document GitHub Sign-In as an optional Account Mode provider.
- Document platform constraints (OAuth flows and unsupported platforms).
- Implement desktop GitHub Device Flow (no backend) for macOS/Windows.
- Keep Local Mode and existing providers unchanged.
- Mark as non-blocking and platform-dependent.

### 📌 Exit conditions

- Specs updated with GitHub Sign-In option and platform fallbacks.
- Desktop GitHub Device Flow implemented and validated on macOS/Windows.

---

# [✔] **PHASE 7 — Integrate Firestore (completed 24/11/2025)**

### ⚙️ Tasks

- Create `data/services/firestore_service.dart`
- Configure paths:

  ```
  users/{uid}/tasks/{taskId}
  ```

### 📌 Exit conditions

- Firestore accessible
- Create/read tests OK

---

# [✔] **PHASE 8 — Implement Task CRUD (completed 17/12/2025)**

### ⚙️ Tasks

- Create:
  - `task_repository.dart`

- Functions:
  - addTask
  - updateTask
  - deleteTask
  - streamTasks

### 📌 Exit conditions

- CRUD working
- Data persists correctly
- Task list updates in real time via the active repo stream (Firestore or InMemory)

---

# [✔] **PHASE 9 — Task List Screen (completed 17/12/2025)**

### ⚙️ Tasks

- Create:
  - `task_list_screen.dart`
  - `task_card.dart` widget

- Show:
  - Name
  - Durations
  - Total pomodoros

### 📌 Exit conditions

- List updates in real time

---

# [✔] **PHASE 10 — Task Editor (completed 17/12/2025; reopened items completed 25/01/2026)**

### ⚙️ Tasks

- Create form:
  - Name
  - Durations
  - Total pomodoros
  - Long break interval
  - Sounds (pomodoro start, break start; final sound fixed by default in this MVP)

- Save to Firestore
- Validate unique task names in the list; block save and show a clear error when duplicated.
- Add "Apply settings to remaining tasks" to copy durations, intervals, and sounds to all subsequent tasks.

### 📌 Exit conditions

- Tasks fully editable
- Basic sound selector connected (no playback yet) and plan to implement real audio in a later phase
- Unique name validation blocks duplicates and shows a validation error.
- Apply settings copies the current task configuration to all remaining tasks.

---

# [✔] **PHASE 10.4 — UX/Product refinements (documentation-first) (completed 24/01/2026)**

### ⚙️ Tasks

- Define reusable Pomodoro configuration presets (create/edit/delete/default) in specs.
- Define task weight (%) placement in Task List and Task Editor (pomodoros + % grouped).
- Define Pomodoro integrity modes (shared structure vs per-task) and warning requirements in specs.
- Keep behavior unchanged; documentation-first only.

### 📌 Exit conditions

- Specs updated with presets + weight UI guidance.
- No code changes required yet.

---

# [✔] **PHASE 11 — Event audio (completed 17/12/2025)**

### ⚙️ Tasks

- Add default sound assets (pomodoro start, break start, task finish).
- Integrate an audio service and trigger sounds on Pomodoro events.
- Configure silent fallback on platforms that do not support playback.

### 📌 Exit conditions

- Sounds play on macOS/Android/Web for key events.
- Task configuration respects selected sounds.

# [✔] **PHASE 12 — Connect Editor → List → Execution (completed 17/12/2025)**

### ⚙️ Tasks

- Pass the selected task to `timer_screen`
- Load values into the ViewModel

### 📌 Exit conditions

- Full cycle working

---

# [✔] **PHASE 13 — Real-time Pomodoro sync (multi-device) (completed 06/01/2026; reopen item completed 25/01/2026)**

### ⚙️ Tasks

- Create `PomodoroSession` (model + serialization) and `pomodoro_session_repository.dart` on Firestore (`users/{uid}/activeSession`).
- Expose `pomodoroSessionRepositoryProvider` and required dependencies (deviceId, serverTimestamp helper).
- Extend `PomodoroViewModel` to publish start/pause/resume/cancel/phase change/finish events in `activeSession` (single writer by `ownerDeviceId`).
- In TimerScreen, mirror mode: subscribe to `activeSession` when not the owner and mirror state by computing remaining time from `phaseStartedAt` + `phaseDurationSeconds`.
- Handle conflicts: if an active session exists, allow “Take over” (overwrite `ownerDeviceId`) or respect the remote session.
- Clear `activeSession` on finish or cancel.
- On app launch/login, auto-open TimerScreen if an active session is running.
- If auto-open cannot occur, a fallback entry point must exist (implemented in Phase 19).

### 📌 Exit conditions

- Two devices with the same `uid` see the same pomodoro in real time (<1–2 s delay).
- Only the owner writes; others show live changes.
- Phase transitions, pause/resume, and finish are persisted and visible when reopening the app.
- Reopening the app with a running session opens the execution screen automatically.
- If auto-open is suppressed or blocked, the user can reach the running group via the Task List banner or Groups Hub (implemented in Phase 19).

# [✔] **PHASE 14 — Sounds and Notifications (completed 18/01/2026)**

### ⚙️ Tasks

- Integrate `just_audio` and `flutter_local_notifications` (done).
- Windows desktop: implement audio with `audioplayers` and notifications with `local_notifier`
  via adapters in `SoundService`/`NotificationService` (done).
- Migrate `PomodoroTask` schema: add `createdAt`/`updatedAt`
  with backfill for Firestore + local repositories.
- Send a system notification when each pomodoro ends (Pomodoro → Break).
- Add optional local file picker for custom sounds (persist file path or asset id).
- Auto-dismiss the "Task completed" modal when the same task restarts on another device (done).
- Fix macOS notification banner visibility for owner sessions (done).
- Android: keep pomodoro advancing in background (foreground service; done).

### Status notes (13/01/2026)

- Audio verified on macOS/Windows/iOS/Android/Web (Chrome) and Linux.
- Notifications verified on macOS/Windows/iOS/Android/Linux; web notifications enabled via Notifications API (permission + app open, including minimized).

### Status notes (15/01/2026)

- Completion notifications are silent across platforms; app audio remains the only audible signal.
- iOS notifications now display in foreground by assigning the notification center delegate.

### Status notes (17/01/2026)

- Local custom sound picker added for Pomodoro start/Break start with per-device overrides only.
- Web (Chrome) local sound picking remains disabled.
- Verified on macOS/iOS/Android; Windows/Linux pending.

### Status notes (18/01/2026)

- Windows audioplayers asset path normalized to avoid assets/assets lookup; built-in sounds play again.
- Skipped just_audio duration probe on Windows/Linux to avoid MissingPluginException during custom sound pick.
- Linux custom sound selection and playback verified without code changes.
- Confirmed sound policy: only pomodoro start, break start, and task finish play to avoid overlap.
- PomodoroTask timestamps (createdAt/updatedAt) added with backfill in Firestore/local repositories.

### 📌 Exit conditions

- Start sounds are configurable (pomodoro start, break start). Task finish uses the default sound in this MVP.
- Post-MVP: make the task finish sound configurable.
- PomodoroTask migration (timestamps) complete across repos.
- Custom sound selection (local file picker) works on supported platforms.
- Final notification works on macOS/Win/Linux
- "Task completed" modal auto-dismisses when the same task restarts remotely

---

# [✔] **PHASE 15 — TaskRunGroup Model & Repository (completed 18/01/2026)**

### ⚙️ Tasks

- Create `TaskRunGroup` / `TaskRunItem` models with snapshot semantics.
- Implement Firestore repository at `users/{uid}/taskRunGroups/{groupId}`.
- Add retention policy for scheduled/running/last N completed.
- Persist user-configurable retention N (default 7, max 30) and apply it when pruning.
- Extend `PomodoroSession` with group context fields (`groupId`, `currentTaskId`,
  `currentTaskIndex`, `totalTasks`) and update activeSession read/write paths.

### 📌 Exit conditions

- TaskRunGroups can be created, persisted, streamed, and pruned.
- Active session includes group/task context.
- Retention policy honors the user-configured N value.

---

# [✔] **PHASE 16 — Task List Redesign + Group Creation (completed 19/01/2026)**

### ⚙️ Tasks

- Replace per-task “Run” button with checkboxes and a single “Confirmar” action.
- Implement reorder handle-only drag and drop.
- Show theoretical start/end times per selected task (recalc on time/reorder/selection).
- Build snapshot creation flow for TaskRunGroup.

### 📌 Exit conditions

- Task selection + ordering + confirm flow works and creates a group snapshot.

---

# 🚀 **PHASE 17 — Planning Flow + Conflict Management**

### ⚙️ Tasks

- Add “Start now” vs “Schedule start” flow with date/time picker.
- Compute and persist `scheduledStartTime` + `theoreticalEndTime`.
- Enforce overlap rules and resolution choices (delete existing vs cancel new).
- Add per-group `noticeMinutes` with global/default fallback.
- Auto-start scheduled groups at scheduledStartTime (status -> running, actualStartTime set, theoreticalEndTime recalculated).
- If the app was inactive at scheduledStartTime, auto-start on next launch/resume when no conflict exists.

### 📌 Exit conditions

- Scheduled groups can be created without conflicts; conflicts are resolved via UI.
- Scheduled groups auto-start and transition to running at the scheduled time (or on next resume if missed).

---

# 🚀 **PHASE 18 — Run Mode Redesign for TaskRunGroups (In progress)**

### ⚙️ Tasks

- Prerequisite: complete Phases 15–17 (TaskRunGroup + PomodoroSession group context)
  before starting the TimerScreen redesign.
- Redesign timer UI: current time inside circle, status boxes, next box, contextual list.
- Show time ranges in status boxes and in each contextual task list item.
- Apply golden-green color for the "Next" status box only when the current pomodoro is the last in the **last task** (end of group).
- During a break, if this is the last break of a task and more tasks remain, "Next" must show End of task (no next-task details).
- Rotate needle counterclockwise for countdown and keep idle preview consistent.
- Define idle preview needle behavior (consistent position or motion) for pre-start planning state.
- Implement automatic transitions between tasks with no modal.
- Update group completion modal and final animation, including an optional summary
  (total tasks, pomodoros, total time).
- Add a Groups Hub indicator in the Run Mode header when pending groups exist.
- On resume, recalculate projected start/end times for status boxes and the contextual task list.

### 📌 Exit conditions

- Full group execution works end-to-end with correct UI and transitions.
- Completion modal includes the optional summary data.
- Header shows a visual indicator when pending groups exist (Groups Hub).
- Status boxes and contextual task list show time ranges.

---

# 🚀 **PHASE 19 — Groups Hub Screen**

### ⚙️ Tasks

- Create Groups Hub screen accessible from Run Mode header.
- List scheduled/running/last N completed groups with required fields.
- Actions: view summary, cancel schedule, start now (if no conflict).
- Add running-group entry points (Task List banner + Groups Hub "Open Run Mode" action).
- Add "Run again" for completed groups to duplicate the snapshot into a new TaskRunGroup and open planning.
- Provide direct navigation to the Task List screen (Task Library).
- Auto-navigate to Groups Hub after group completion (only after the user dismisses the completion modal).

### 📌 Exit conditions

- Groups Hub screen manages group lifecycle reliably and serves as the post-completion landing view.

---

# 🚀 **PHASE 20 — Responsive Updates for New Run Mode**

### ⚙️ Tasks

- Implement a dynamically calculated minimum size.
- Proportional clock scaling.
- Re-layout buttons to keep the circle unobstructed.
- Mobile landscape layout: move status boxes and contextual list to the right.
- Ensure desktop resizing still keeps the circle and text readable.
- Validate minimum size constraints with the new layout.
- Dark theme background must be pure black (#000000); light theme uses a light background with strong contrast.
- Enforce fixed-width timer digits (FontFeature.tabularFigures() or monospaced font) to avoid jitter.
- Set the initial window size to the computed minimum optimal size on app launch.

### 📌 Exit conditions

- Run Mode remains legible and stable across mobile landscape and desktop resizing.
- App usable at 1/4 of the screen.

---

# 🚀 **PHASE 21 — Mandatory Final Animation**

### ⚙️ Tasks

- Implement:
  - Full green/gold circle
  - Large “TASK COMPLETED” text
  - Hand stopped at 360°

- Smooth animation

### 📌 Exit conditions

- Fully faithful to specs ()

---

# 🚀 **PHASE 22 — Unit and Integration Tests**

### ⚙️ Tasks

- Tests for the state machine
- Tests for pause/resume logic
- Tests for strict completion
- Tests for TaskRunGroup transitions and scheduling conflicts

### 📌 Exit conditions

- Stable test suite

---

# 🚀 **PHASE 23 — UI / UX Polish**

### ⚙️ Tasks

- Refactor widgets
- Adjust shadows, padding, borders
- Keep a minimal, high-contrast style in both dark and light themes.
- Remember the last email used on the device (stored locally) and enable autofill/password managers; never store the password in plain text.
- Audit ambiguous labels and add supporting icons where clarity needs reinforcement.
- Ensure buttons are modern, clearly defined, and immediately discoverable.
- Add Settings/Preferences entry points (gear on Task List, app menu on desktop).
- Add language selector with system auto-detect + user override.
- Add theme selector (dark/light).
- Add retention N selector (default 7, max 30).

---

# 🚀 **PHASE 24 — Internal Release Preparation**

### ⚙️ Tasks

- Package the app for:
  - macOS `.app`
  - Windows `.exe`
  - Linux `.AppImage`

- Create installation instructions
- Run the app on all platforms

### 📌 Exit conditions

- MVP 1.2 milestone complete (historical)

---

# 🧾 **Final Notes**

- This document **controls the mandatory development order**.
- The AI must use it **to progress step by step without skipping phases**.
- Any future changes must be recorded here and in `docs/dev_log.md`.

---
