# 📍 **Official Development Roadmap — Focus Interval (MVP 1.0)**

**Initial version — 100% synchronized with `/docs/specs.md`**

This document defines the development plan **step by step**, in chronological order, to fully implement the Focus Interval app according to the official MVP 1.0 specifications.

The AI (ChatGPT) must consult this document **ALWAYS** before continuing development, to keep technical and progress coherence.

This project includes an official team roles document at:
[docs/team_roles.md](team_roles.md)

---

# 🟦 **Global Project Status**

```
CURRENT PHASE: 13 — Real-time Pomodoro sync (multi-device)
NOTE: TimerScreen already depends on the ViewModel (no local timer/demo config).
      PomodoroViewModel exposed as Notifier auto-dispose and subscribed to the machine.
      Auth strategy completed: Google Sign-In on iOS/Android/Web/Win/Linux; email/password on macOS.
      Firestore integrated per authenticated user; tasks isolated by uid.
      Phase 7 (Firestore integrated) completed on 24/11/2025.
      Phase 8 (CRUD + reactive stream) completed on 17/12/2025.
      Phase 9 (Reactive list) completed on 17/12/2025. Windows test pending.
      Phase 10 (Editor with basic sounds) completed on 17/12/2025.
      Phase 11 (Event audio) completed on 17/12/2025.
      Phase 12 (Connect Editor → List → Execution) completed on 17/12/2025.
      Phase 13 in progress: validate sync with two real devices and decide deviceId persistence.
```
Update this on each commit if needed.

---

# 🧩 **Roadmap Structure**

Development is divided into **19 main phases**, ordered to avoid blockers, errors, and rewrites.

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
- Auth configured: Google on iOS/Android/Web/Win/Linux and email/password on macOS. `firebase_options.dart` generated and bundles unified (`com.marcdevelopez.focusinterval`).
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

# [✔] **PHASE 6 — Configure Firebase Auth (Google on mobile/web/Win/Linux; Email/Password on macOS)**

### ⚙️ Tasks

- Integrate:

  - firebase_core
  - firebase_auth
  - google_sign_in (iOS/Android/Web/Windows/Linux only)
  - email/password flow for macOS

- Configure:

  - macOS App ID
  - Windows config
  - Linux config

### 📌 Exit conditions

- Google login working on iOS/Android/Web/Windows/Linux
- Email/password login working on macOS
- Persistent UID in the app

### 📝 Pending improvements (post-MVP)

- Remember the last email used on each device (stored locally) and allow autofill/password managers; never store the password in plain text.

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

# [✔] **PHASE 10 — Task Editor (completed 17/12/2025)**

### ⚙️ Tasks

- Create form:

  - Name
  - Durations
  - Total pomodoros
  - Long break interval
  - Sounds (pomodoro start, break start; final sound fixed by default in this MVP)

- Save to Firestore

### 📌 Exit conditions

- Tasks fully editable
- Basic sound selector connected (no playback yet) and plan to implement real audio in a later phase

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

# 🚀 **PHASE 13 — Real-time Pomodoro sync (multi-device)**

### ⚙️ Tasks

- Create `PomodoroSession` (model + serialization) and `pomodoro_session_repository.dart` on Firestore (`users/{uid}/activeSession`).
- Expose `pomodoroSessionRepositoryProvider` and required dependencies (deviceId, serverTimestamp helper).
- Extend `PomodoroViewModel` to publish start/pause/resume/cancel/phase change/finish events in `activeSession` (single writer by `ownerDeviceId`).
- In TimerScreen, mirror mode: subscribe to `activeSession` when not the owner and mirror state by computing remaining time from `phaseStartedAt` + `phaseDurationSeconds`.
- Handle conflicts: if an active session exists, allow “Take over” (overwrite `ownerDeviceId`) or respect the remote session.
- Clear `activeSession` on finish or cancel.

### 📌 Exit conditions

- Two devices with the same `uid` see the same pomodoro in real time (<1–2 s delay).
- Only the owner writes; others show live changes.
- Phase transitions, pause/resume, and finish are persisted and visible when reopening the app.

# 🚀 **PHASE 14 — Sounds and Notifications**

### ⚙️ Tasks

- Integrate `just_audio`
- Integrate `flutter_local_notifications`
- Add:

  - Pomodoro start
  - Pomodoro end
  - Break start
  - Break end
  - Full completion (special sound)

### 📌 Exit conditions

- All sounds work
- Final notification works on macOS/Win/Linux

---

# 🚀 **PHASE 15 — Mandatory Final Animation**

### ⚙️ Tasks

- Implement:

  - Full green/gold circle
  - Large “TASK COMPLETED” text
  - Hand stopped at 360°

- Smooth animation

### 📌 Exit conditions

- Fully faithful to specs ()

---

# 🚀 **PHASE 16 — Resizing + Full Responsive**

### ⚙️ Tasks

- Implement a dynamically calculated minimum size
- Proportional clock scaling
- Re-layout buttons
- Full black background

### 📌 Exit conditions

- App usable at 1/4 of the screen

---

# 🚀 **PHASE 17 — Unit and Integration Tests**

### ⚙️ Tasks

- Tests for the state machine
- Tests for pause/resume logic
- Tests for strict completion

### 📌 Exit conditions

- Stable test suite

---

# 🚀 **PHASE 18 — UI / UX Polish**

### ⚙️ Tasks

- Refactor widgets
- Adjust shadows, padding, borders
- Keep minimal dark style
- Remember the last email used on the device (stored locally) and enable autofill/password managers; never store the password in plain text.

---

# 🚀 **PHASE 19 — Internal Release Preparation**

### ⚙️ Tasks

- Package the app for:

  - macOS `.app`
  - Windows `.exe`
  - Linux `.AppImage`

- Create installation instructions
- Run the app on all platforms

### 📌 Exit conditions

- MVP 1.0 ready and functional

---

# 🧾 **Final Notes**

- This document **controls the mandatory development order**.
- The AI must use it **to progress step by step without skipping phases**.
- Any future changes must be recorded here and in `docs/dev_log.md`.

---
