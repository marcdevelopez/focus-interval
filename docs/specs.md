# 📘 **Functional Specifications – Cross-Platform Pomodoro App (macOS / Windows / Linux)**

**Version 1.0 — Complete MVP Document**

---

# 🧭 **1. Project overview**

The app is an **advanced Pomodoro session manager**, designed for **desktop** on **macOS**, **Windows**, and **Linux**, built entirely with **Flutter**.

The main goal is to allow the user to:

- Create fully configurable Pomodoro tasks
- Save them in the cloud (Firestore)
- Reuse them on any device
- Run them with precision and custom sounds
- Automatically stop execution when all pomodoros are completed
- Receive system alerts and notifications
- Sync Pomodoro execution in real time across all devices logged into the same account (single session owner, others in mirror mode)

The app syncs with **Firebase** via **Google / Gmail** login.

---

# 🖥️ **2. Target platforms**

- macOS (Intel & Apple Silicon)
- Windows 10/11 Desktop
- Linux GTK-based distros (Ubuntu, Fedora, etc.)

---

# 🔥 **3. Core technologies**

| Area                   | Technology                               |
| ---------------------- | ---------------------------------------- |
| UI Framework           | Flutter 3.x                              |
| Auth                   | Firebase Authentication (Google Sign-In) |
| Backend                | Firestore                                |
| Local Cache (optional) | Hive                                     |
| State Management       | Riverpod                                 |
| Navigation             | GoRouter                                 |
| Audio                  | just_audio                               |
| Notifications          | flutter_local_notifications              |
| Logging                | logger                                   |
| Architecture           | MVVM (Model–View–ViewModel)              |

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
│   │   └─ pomodoro_task.dart
│   ├─ repositories/
│   │   └─ task_repository.dart
│   └─ services/
│       ├─ firebase_auth_service.dart
│       ├─ firestore_service.dart
│       └─ sound_service.dart
├─ domain/
│   ├─ pomodoro_machine.dart
│   └─ validators.dart
├─ presentation/
│   ├─ screens/
│   │   ├─ login_screen.dart
│   │   ├─ task_list_screen.dart
│   │   ├─ task_editor_screen.dart
│   │   └─ timer_screen.dart
│   └─ widgets/
│       ├─ timer_display.dart
│       ├─ task_card.dart
│       └─ sound_selector.dart
└─ main.dart
```

---

# 🧩 **5. Data model**

## **5.1. `PomodoroTask` model**

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
  String endPomodoroSound;
  String startBreakSound;
  String endBreakSound;
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
    required this.endPomodoroSound,
    required this.startBreakSound,
    required this.endBreakSound,
    required this.finishTaskSound,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

## **5.2. `PomodoroSession` model (live sync)**

```dart
class PomodoroSession {
  String id; // sessionId
  String taskId;
  String ownerDeviceId; // device that writes in real time

  PomodoroStatus status; // pomodoroRunning, shortBreakRunning, longBreakRunning, paused, finished, idle
  int currentPomodoro;
  int totalPomodoros;

  int phaseDurationSeconds; // duration of the current phase
  int remainingSeconds;     // only applies when paused
  DateTime phaseStartedAt;  // serverTimestamp on start/resume
  DateTime lastUpdatedAt;   // serverTimestamp of the last event
}
```

---

# 🧠 **6. Pomodoro logic (state machine)**

## **6.1. States**

- `pomodoroRunning`
- `shortBreakRunning`
- `longBreakRunning`
- `paused`
- `finished`
- `idle`

## **6.2. Transitions**

1. Start pomodoro → `pomodoroRunning`
2. Finish pomodoro:

   - If current number % `longBreakInterval` == 0 → `longBreakRunning`
   - Otherwise → `shortBreakRunning`

3. Finish break → next pomodoro
4. Finish the last pomodoro → `finished` + final sound
5. User can:

   - Pause
   - Resume
   - Cancel

---

# 🔊 **7. Sound system**

**Configurable sound events in the current MVP:**

| Event                      | Sound                             |
| -------------------------- | ---------------------------------- |
| Pomodoro start             | `startSound`                       |
| Break start                | `startBreakSound`                  |
| End of all pomodoros       | `finishTaskSound` (fixed by default) |

_Note: Pomodoro end and break start coincide; distinct sounds will be used to avoid confusion. Final sounds and real playback will be implemented in the audio phase._

Allowed formats:

- `.mp3`
- `.wav`

Sounds can be:

- Included in the app (assets)
- Or loaded by the user (local file picker)

---

# 💾 **8. Persistence and sync**

### **8.1. Firestore (primary)**

```
users/{uid}/tasks/{taskId}
```

### **8.2. Hive (optional)**

Local table `task_cache`:

- Instant load
- Background sync
- Offline mode

### **8.3. Active Pomodoro session (real-time sync)**

```
users/{uid}/activeSession
```

- Single document per user with the active session.
- Minimum fields: `taskId`, `ownerDeviceId`, `status`, `currentPomodoro`, `totalPomodoros`, `phaseDurationSeconds`, `remainingSeconds` (only when paused), `phaseStartedAt` (serverTimestamp), `lastUpdatedAt` (serverTimestamp).
- **Only** the owner device writes; others subscribe in real time and render progress by calculating remaining time from `phaseStartedAt` + `phaseDurationSeconds`.

---

# 🔐 **9. Authentication**

## **Mandatory login (by platform)**

- iOS / Android / Web / Windows / Linux:
  - Button: “Continue with Google”
  - Opens browser or WebView
  - Gets `uid`, `email`, `displayName`, `photoURL`
- macOS:
  - Email/password login (no Google Sign-In, not natively supported)
  - Gets `uid`, `email` (and optionally name)

## **Persistence**

The session remains active on all devices.

---

# 🖼️ **10. User interface**

## **10.1. Login screen**

- Logo
- Google button
- Text: “Sync your tasks in the cloud”

---

## **10.2. Task List screen**

- Card-style list
- Each task shows:

  - Name
  - Total pomodoros
  - Durations

- Buttons:

  - ▶ Run
  - ✏ Edit
  - 🗑 Delete

- Floating button **“+ New task”**

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

---

## **10.4. Execution Screen**

The execution screen will show an **analog-style circular timer**, with the following visual and functional requirements:

### 🎯 **Main elements**

1. **Large circular clock** (progress ring style).
2. **Animated hand**:

   - Rotates **clockwise**, like a real clock.
   - Represents remaining time of the current cycle (pomodoro or break).

3. **Colors by state**:

   - **Red (#E53935)** → Pomodoro
   - **Blue (#1E88E5)** → Short or long break

4. **Outer circular border** showing overall cycle progress.
5. **Clock center** shows:

   - Remaining time (MM:SS)
   - Current state (“Pomodoro”, “Short break”, “Long break”)
   - Current pomodoro / total

---

### 🎨 **Clock visual requirements**

#### **1. Main circle (progress)**

- Stroke width: 12–18 px
- Rounded ends
- Dynamic color (red/blue by state)
- Must animate smoothly with `TweenAnimationBuilder` or `AnimationController`

#### **2. Animated hand**

- Shape: thin line from center to edge
- Length: 90% of the radius
- Color: white or light gray
- Movement: **continuous rotation** based on:

```
angle = 360° * (1 - (remainingTime / totalTime))
```

- Refreshed at 60 fps (AnimationController)

---

### 🕒 **Hand movement logic**

- When a pomodoro or break starts, the hand is placed at the 12 o'clock position (–90°).
- It rotates gradually until it completes the full circle when reaching zero.
- In pomodoro → red color
- In break → blue color
- When changing state:

  - Reset hand position
  - Change color
  - Change total time

---

### 🔊 **Sounds**

(already defined in your original document, kept as-is)

---

### 🧩 **Events that affect the clock**

| Event            | Action on the clock                                                                               |
| ---------------- | ------------------------------------------------------------------------------------------------- |
| Start pomodoro   | Reset hand, red color, animate until end                                                          |
| Pomodoro end     | Switch to break (blue color), reset hand                                                          |
| Break end        | Switch to pomodoro (red color), reset hand                                                        |
| Pause            | Freeze animation                                                                                  |
| Resume           | Continue animation                                                                                |
| Cancel           | Stop animation and return to idle state                                                           |
| Finish task      | Special sound + popup + mandatory final animation (green/gold circle + “TASK COMPLETED”)          |

The final animation described in section 12 is part of the mandatory behavior and must be implemented inside the circular clock itself.

### **10.4.2. Multi-device sync in TimerScreen**

- If an `activeSession` exists in Firestore for the `uid`, the screen connects in mirror mode and reflects the remote state in real time (state, phase, remaining time).
- Only the `ownerDeviceId` can start/pause/resume/cancel; other devices show the state and offer “Take over” if the owner does not respond.
- Remaining time in mirror mode is calculated with `phaseDurationSeconds` and `phaseStartedAt` (no 1s ticks are sent).

## **10.4.1. Mandatory visual improvements for the timer**

### **1. Fixed-width digital time (avoid horizontal jitter)**

The `MM:SS` timer must be displayed without any visual shifting or "jitter."  
This is achieved using **fixed-width digits** and a fully static `:` separator.

Requirements:

- Each time digit must have an **identical width**, regardless of the number.
- The `:` separator must never move.
- Allowed solutions:
  - A font with `FontFeature.tabularFigures()`
  - Monospaced fonts
  - Or use `SizedBox` to fix each digit width
- The time must not jitter or change position during the countdown.

### **2. Show the current system time**

The execution screen must show, in a fixed corner (preferably **top-right**),  
the user's **current system time**.

Requirements:

- Recommended format: `HH:mm` or `HH:mm:ss`.
- Recommended color: `Colors.white54` or equivalent.
- It must be subtle, not visually competing with the timer.
- It must update automatically (every second or every minute depending on format).
- The time must remain visible even if the window is resized.

Purpose: allow the user to see the real time without needing another device or excessive screen space.

---

## **10.5. Extra requirements for Desktop (important)**

- Must work on large screens without pixelation (use `CustomPainter`).
- Must allow window resizing and automatically adjust clock size.
- Smooth 60fps animation on macOS / Windows / Linux.

---

# **10.6. Advanced window, responsiveness, and visual accessibility requirements**

## 🖥️ **A. Resizable window (mandatory)**

The app must allow **free window resizing** on macOS, Windows, and Linux, with these rules:

1. **Allow horizontal and vertical resizing** in real time.
2. Content must **adapt automatically** (responsive).
3. The window must not collapse or break the UI when reduced.
4. The circular timer must **scale dynamically** to the available size.

---

## 📏 **B. Minimum window size**

To ensure the clock is always visible:

- The minimum allowed size should be:

  - **1/4 of the user's screen on the shortest dimension**
  - This is approximately:

    - 480×480 minimum (if Full HD screen)
    - 640×640 minimum (if 1440p screen)

The actual minimum size must be calculated dynamically using:

```
minSize = screen.shortestSide / 4
```

And the app must **block** sizes smaller than this limit.

---

## 🎛️ **C. The clock must be fully responsive**

The circular timer must:

1. Scale proportionally based on window size.
2. Always keep:

   - The hand centered
   - The circle visible and complete
   - The center text readable

3. It must not overlap buttons or text when size is reduced.
4. Use `LayoutBuilder` or `MediaQuery` to compute sizes based on current width/height.

---

## ⏸️ **D. Pause and resume function (mandatory)**

The user must be able to:

### **1. Pause at any time**

- The hand freezes.
- The timer stops.
- The current count is not lost.
- State is stored internally in the ViewModel.

### **2. Resume whenever they want**

- The hand continues from the exact point.
- Remaining time and state are restored without jumps.

### **3. Visual indicators**

- “Pause” button → changes to “Resume”.
- Pause icon visible inside the clock (optional).

### **4. Sound/alert behavior**

- Pausing emits no sound.
- Resuming emits no sound either.
- Only natural cycle events emit audio.

---

## 🌑 **E. Fully black background (eye-saver mode)**

Default mode must be:

- **100% black background (#000000)**
- No gradients
- No transparency
- Clock text and strokes in:

  - White
  - Light gray
  - Assigned colors (red/blue)

### Motivation:

- Reduces eye strain
- Ideal for working in low light
- On OLED monitors (modern MacBook Pro, QD-OLED monitors) it saves energy
- On Linux/macOS/Windows it provides a professional productivity app feel

---

## 🎯 **F. Guaranteed clock visibility**

Regardless of window size:

- The clock must occupy at least **60% of the available width**.
- Controls (Pause, Resume, Cancel) must rearrange to avoid invading the circle.
- The center text must have a minimum size of:

  - **32 px** for time
  - **18 px** for state

If it does not fit → scale proportionally, but never disappear.

---

# 🔔 **11. Notifications**

- Notification when each pomodoro ends
- Notification when the full task ends
- Possible vibration if the system allows it (Linux no, Windows/macOS occasionally yes)

---

# 🚨 **12. Mandatory key behavior (expanded and definitive version)**

### ✔ **Strict automatic task completion**

When the timer completes the **last pomodoro** of the task:

1. **The app must stop automatically**.

   - It must not start another break.
   - It must not start a new pomodoro.
   - It must not allow the timer to keep running.

2. It must play a **special final sound**, configured by the user, different from other events.

3. It must show a **modal popup** with the message:

   - “**Task completed**”
   - Optional info: total time worked, number of pomodoros completed.

4. It must send a **system notification**:

   - macOS → Notification Center
   - Windows → Windows Notification
   - Linux → libnotify

5. The state machine must transition to:

   - `finished`

6. The clock screen must:

   - Stop animation
   - Keep the hand in its final position (360°)
   - Change the circle color to **green** or **gold** (defined in the clock spec)
   - Show “**Task Finished**” in the center of the circle

7. It must not start another session automatically.
   The user must press:

   - “Close”
   - “Back to task list”
   - “Start task again” (optional)

---

# 🔄 **13. Real-time multi-device sync (MVP)**

- **Goal**: open the app on multiple devices with the same session and see the same live pomodoro.
- **Single writer**: the device that starts the session is marked as `ownerDeviceId` and is the only one publishing events to `activeSession`.
- **Write events**: start, pause, resume, cancel, phase transition, and finish. No per-second writes.
- **Time calculation**: store `phaseStartedAt` (serverTimestamp) + `phaseDurationSeconds`; clients compute `remainingSeconds` locally and update on each snapshot.
- **Conflicts**: if an `activeSession` already exists and another device tries to start, ask whether to “Take over” (overwrite `ownerDeviceId`) or “Respect remote session” (mirror only).
- **Completion**: when the task ends, `activeSession` goes to `finished` and then is deleted or reset to `idle`.

# 📈 **14. Future features (not included in the MVP)**

- Statistics (chart of tasks completed per day/week)
- Export tasks as a file
- Floating widgets “always on top”
- Global keyboard shortcuts
- Minimal mode
- Custom dark/light mode

---
