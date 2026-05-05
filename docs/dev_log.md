# 📝 Focus Interval — Dev Log (MVP 1.2)

---

Chronological history of the MVP 1.2 development using work blocks.
Each block represents significant progress within the same day or sprint.

This document is used to:

- Preserve real progress traceability
- Align architecture with the roadmap
- Inform the AI of the exact project state
- Serve as professional evidence of collaborative AI work
- Show how the MVP 1.2 was built at an accelerated pace

Formatting rules:

- Append new blocks at the end of this file (chronological order).
- Block numbers must be strictly increasing and continue from the last block.
- Never insert new blocks above existing ones.
- Always verify the current date (e.g., `date`) before writing any date in docs; use the verified date.

---

# 📍 Current status

Active phase: **20 — Group Naming & Task Visual Identity**
Last closed bug fix: **BUG-035 — macOS global keyboard stale-key repair (`88e0bb1`, closed 04/05/2026)**
Current focus: **BUG-033 deterministic repro recapture + BUGLOG-034/027 in validation + BUGLOG-029 pending + process no-loss checklist hardening**
Last update: **05/05/2026**

---

# 📅 Development log

# 🔹 Block 1 — Initial setup (21/11/2025)

### ✔ Work completed:

- Initial `/docs` structure created
- Added full `specs.md`
- Added full `roadmap.md`

### 🧠 Decisions made:

- The final clock animation will be **mandatory** in the MVP 1.2
- The background will be **100% black**
- Resizable window with a dynamic minimum size

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Create the Flutter project
- Create the base project structure (`lib/app`, `lib/data`, etc.)

---

# 🔹 Block 2 — Pomodoro state machine (21/11/2025)

### ✔ Work completed:

- Created the full state machine (`pomodoro_machine.dart`)
- Manually tested with a quick check in `main.dart`
- Confirmed: states, transitions, and strict completion follow the specs
- Validated the machine rejects invalid configs (values <= 0)

### 🧠 Decisions made:

- Run lightweight tests directly in the console for now
- Logic remains completely independent from UI and Firebase, per architecture

### ⚠️ Issues found:

- Initial config with 0 values threw an exception, as expected

### 🎯 Next steps:

- Create the circular clock widget (PHASE 3)
- Prepare the `timer_display.dart` structure
- Define painter + base animations

---

# 🔹 Block 3 — Premium circular clock (TimerDisplay) (21/11/2025)

### ✔ Work completed:

- Implemented the full circular clock (TimerDisplay)
- Continuous 60fps animation with AnimationController
- Clockwise analog-style hand
- Dynamic colors: red, blue, and green/gold on finish
- Responsive design based on window size
- CustomPainter optimized for desktop
- Visual demo working with Start/Pause/Resume/Cancel controls

### 🧠 Decisions made:

- Prioritize premium continuous animation per specs (not tick-based)
- Keep TimerDisplay independent from the main UI
- Validate the final clock UI within the MVVM structure

### 🎯 Next steps:

- Create the base navigation and screen structure
- Implement TimerScreen with TimerDisplay + real logic

# 🔹 Block 4 — TimerScreen + Navigation (21/11/2025)

### ✔ Work completed:

- Integrated `TimerScreen` with `TimerDisplay`
- Added a working premium clock with animated hand
- Added a top digital time display without duplicates
- Added dynamic controls bar (Start / Pause / Resume / Cancel)
- Partial Riverpod sync achieved
- Navigation to execution screen via GoRouter
- Final behavior on task completion working with popup

### 🧠 Decisions made:

- Pomodoro ViewModel will be managed with Riverpod (PHASE 5)
- Execution logic now depends on `pomodoro_view_model.dart`, not local demos
- Execution screen replaces the provisional demo

### ⚠️ Issues found:

- Duplicate time display on screen (fixed)
- Missing import and invalid `style:` param inside `_CenterContent` (fixed)

### 🎯 Next steps:

- Start PHASE 5: full Riverpod MVVM
- Create global state structure for tasks
- Prepare providers for Firebase Auth and Firestore (not connected yet)

# 🔹 Block 5 — Roles documentation (22/11/2025)

### ✔ Work completed:

- Created `docs/team_roles.md` with:
  - Lead Flutter Engineer (Marcos)
  - Staff AI Engineer (ChatGPT)
  - AI Implementation Engineer (Codex)
- Updated README to link it
- Added a professional structure for recruiters

### 🧠 Decisions made:

- Keep this file as the official AI+Human team document
- Use it as a professional reference in interviews

### 🎯 Next steps:

- Finish PHASE 5 (full Riverpod integration)
- Prepare PHASE 6 (Firebase Auth)

# 🔹 Block 6 — Riverpod MVVM (Subphases 5.1 and 5.2) — 22/11/2025

### ✔ Work completed:

- Created PomodoroViewModel with an initial `Notifier` implementation
  (migration to `AutoDisposeNotifier` pending for Phase 5.3).
- Connected the main PomodoroMachine stream.
- States synced correctly with the UI via Riverpod.
- First stable integration version without crashes.
- Fixed “Tried to modify a provider while the widget tree was building”
  by moving calls outside lifecycle.

### ❗ Updated actual status:

- **TimerScreen still contains:**
  - local `_clockTimer`
  - temporary `configureTask(...)` in `initState`
- This will be removed in **Phase 5.3** when all logic moves to the ViewModel.

### 🧠 Decisions made:

- Keep `Notifier` temporarily to avoid breaking TimerScreen
  before completing the full migration.
- Delay removing local timers until the VM fully manages
  progress, remaining seconds, and phases.

### 🎯 Next steps:

- Complete **Phase 5.3**, moving ALL time logic into the ViewModel.
- Migrate PomodoroViewModel to `AutoDisposeNotifier`.
- Remove `_clockTimer` and TimerScreen demo config completely.

---

## 🔹 Block 7 — Real sync of project state (22/11/2025)

### ✔ Work completed:

- Structural fixes in `providers.dart`:
  - Added missing `pomodoro_task.dart` import
  - Fixed type errors in `taskListProvider` and `taskEditorProvider`

- Aligned code state with Riverpod 2.x:
  - `TaskListViewModel` as `AsyncNotifier<List<PomodoroTask>>`
  - `TaskEditorViewModel` as `Notifier<PomodoroTask?>`

- Confirmed the build is stable again after fixes
- Reviewed global providers structure in the MVVM architecture

### 🧠 Decisions made:

- Keep `PomodoroViewModel` as `Notifier` temporarily while subphase 5.3 completes
- Postpone migration to `AutoDisposeNotifier` until TimerScreen is fully unified with the ViewModel
- Prioritize consistency between roadmap and REAL code instead of blindly following prior planning

### ⚠️ Issues found:

- Several inconsistencies between code and roadmap caused:
  - Unrecognized generic types
  - Out-of-sync providers
  - Cascading compilation errors

### 🎯 Next steps:

- Complete PHASE 5.3: unify clock + timer + stream in the ViewModel
- Remove TimerScreen demo config completely
- Update PomodoroViewModel → `AutoDisposeNotifier` per roadmap

### 🔄 Important documentation adjustments:

- Discrepancies between roadmap and real code were found.
- dev_log.md was updated to reflect that:
  - PomodoroViewModel is still `Notifier` (not AutoDispose yet).
  - TimerScreen kept temporal logic (local timer + demo config).
- This will be corrected during Phase 5.3.

# 🔹 Block 8 — Phase 5.3 (TimerScreen + ViewModel unification) — 22/11/2025

### ✔ Work completed:

- `pomodoroMachineProvider` is now `Provider.autoDispose` with cleanup in `onDispose`.
- `PomodoroViewModel` exposed via `NotifierProvider.autoDispose`, subscribed to `PomodoroMachine.stream` and cleaning subscriptions in `onDispose`.
- `TimerScreen` loads the real task via `loadTask(taskId)` and removes demo config.
- System time restored with `_clockTimer` and `FontFeature` for tabular digits in the appbar.

### 🧠 Decisions:

- Keep `_clockTimer` exclusively for system time; all Pomodoro logic lives in ViewModel/Machine.
- `loadTask` maps `PomodoroTask` → `configureFromTask` to initialize the machine.

### 🎯 Next steps:

- Add placeholder providers `firebaseAuthProvider` and `firestoreProvider` (Phase 5.4).
- Connect TimerScreen with real task selection from list/editor and final states (Phase 5.5).

---

# 🔹 Block 9 — Phase 5.4 (Firebase placeholders) — 22/11/2025

### ✔ Work completed:

- Added placeholder providers `firebaseAuthProvider` and `firestoreProvider` in `providers.dart` (null references, no real integration).
- Added `firebase_auth` and `cloud_firestore` dependencies to `pubspec.yaml` (real integration pending in phases 6–7).
- Preserved import compatibility with Riverpod (hiding `Provider` in Firebase imports).

### 🎯 Next steps:

- Implement real Auth/Firestore services in `data/services` (Phases 6–7).
- Connect TaskRepository to Firestore once real services are integrated.

---

# 🔹 Block 10 — Phase 5.5 (TimerScreen refactor + task connection) — 22/11/2025

### ✔ Work completed:

- TimerScreen loads the real task by `taskId`, shows a loader until configured, and disables Start if it fails.
- Handles missing task with snackbar + automatic back.
- `ref.listen` integrated in build to detect `PomodoroStatus.finished` and show final popup.
- TimerDisplay forces 100% progress and final color (green/gold) in `finished` state.

### 🧠 Decisions:

- Keep InMemoryTaskRepository as local data source until Firestore arrives (Phases 6–7).
- Final popup closes to the list; final animation will be shown on the circle.

### 🎯 Next steps:

- Start Phase 6: configure Firebase Auth (Google Sign-In) and real providers.
- Connect TaskRepository to Firestore once services are ready.

---

# 🔹 Block 11 — Phase 6 (Auth start) — 23/11/2025

### ✔ Work completed:

- Added override to disable `google_sign_in` on macOS (kept on Win/Linux/iOS/Android/Web).
- Created `FirebaseAuthService` skeleton (Google + email/password) and `FirestoreService` with safety stubs.
- Exposed providers for services (`firebaseAuthServiceProvider`, `firestoreServiceProvider`) using a default stub until real credentials are set.
- Updated macOS bundle ID to `com.marcdevelopez.focusinterval` (unified namespace).

### 🧠 Decisions:

- Keep stub to avoid local crashes until Firebase is configured (in this initial block).
- Auth strategy: Google Sign-In for iOS/Android/Web/Win/Linux; email/password for macOS.
- Firebase is not initialized yet; real integration will be done with credentials in phases 6–7.

### 🎯 Next steps:

- Configure Firebase Core/Auth with real credentials; use email/password on macOS and Google elsewhere.
- Replace stub providers with real instances once Firebase is configured.
- Adjust bundle IDs on other platforms to the unified namespace when needed.

---

# 🔹 Block 12 — Phase 6 (Auth configured) — 23/11/2025

### ✔ Work completed:

- Ran FlutterFire with unified bundles `com.marcdevelopez.focusinterval` (android/ios/macos/windows/web) and generated `firebase_options.dart`.
- Added the correct `GoogleService-Info.plist` to the macOS target (Build Phases → Copy Bundle Resources) and removed duplicates.
- Providers point to real services (`FirebaseAuthService`, `FirebaseFirestoreService`); Firebase initializes in `main.dart`.
- Auth strategy active: Google on iOS/Android/Web/Windows, email/password on macOS.
- Console config enabled: Google + Email/Password.

### 🧠 Decisions:

- Reuse the web config for Linux until a specific app is generated; no UnsupportedError in `DefaultFirebaseOptions`.
- Keep a single namespace `com.marcdevelopez.focusinterval` across all platforms.

### 🎯 Next steps:

- Phase 7: integrate real Firestore and connect repositories to remote data.
- Add login UI (email/password on macOS, Google elsewhere) to validate flows.

---

# 🔹 Block 13 — Phase 7 (Firestore integrated) — 24/11/2025

### ✔ Work completed:

- Created `FirestoreTaskRepository` implementing `TaskRepository` on `users/{uid}/tasks`.
- `taskRepositoryProvider` switches Firestore/InMemory based on session; list refreshes on user change.
- Login/register refresh tasks and logout invalidates state; tasks isolated by uid.
- UI shows email and logout button; Firestore repo active when a user is authenticated.

### 🧠 Decisions:

- Keep InMemory as fallback without session.
- Firestore rules to isolate data by `uid` (apply in console).

### 🎯 Next steps:

- Phase 8: polish CRUD/streams and fully connect UI to Firestore.

---

# 🔹 Block 14 — Phase 8 (Reactive repo auth bugfix) — 28/11/2025

### ✔ Work completed:

- `AuthService` exposes `authStateChanges` and `authStateProvider` listens to login/logout.
- `taskRepositoryProvider` rebuilds on user change and uses `FirestoreTaskRepository` when logged in.
- `TaskListViewModel` refreshes the list on `uid` change; tasks now sync across devices with the same email/password.

### ⚠️ Issues found:

- The repo was instantiated before login and stayed in local memory; tasks were not saved to Firestore or shared across platforms.

### 🎯 Next steps:

- Continue Phase 8: full CRUD and streams over Firestore.
- Re-create test tasks after login to persist them in `users/{uid}/tasks`.

# 🔹 Block 15 — Phase 8 (Reactive CRUD with streams) — 17/12/2025

### ✔ Work completed:

- `TaskRepository` now exposes `watchAll()`; InMemory and Firestore emit real-time changes.
- `TaskListViewModel` subscribes to the active repo stream and updates the UI without manual `refresh`.
- Removed forced refreshes from `LoginScreen` and `TaskEditorViewModel`; the list depends only on the stream.

### 🧠 Decisions made:

- Keep InMemory as fallback without session, but also stream-based for coherence and local testing.
- Centralize the source of truth in `watchAll()` to reduce point reads and avoid inconsistent states.

### 🎯 Next steps:

- Validate Firestore stream latency and errors; consider optimistic handling for edits/deletes.
- Review editor validations and list loading/error states.

# 🔹 Block 16 — Phase 9 (Reactive list and login UX) — 17/12/2025

### ✔ Work completed:

- `InMemoryTaskRepository.watchAll()` now emits immediately on subscription; avoids infinite loaders without a session.
- Adjusted `LoginScreen` with dynamic `SafeArea + SingleChildScrollView + padding` to remove the Android keyboard overflow rectangle.
- Verified on macOS, iOS, Android, and Web: reactive task list; loader disappears without session. Windows pending.

### 🧠 Decisions made:

- Keep reactive behavior across all repos (InMemory/Firestore) as the single source of truth.
- Login remains email/password on macOS/Android/web; Google on web/desktop Win/Linux pending test.

### 🎯 Next steps:

- Test on Windows (Google Sign-In) and validate CRUD/streams.
- Start Phase 10: review the editor form per roadmap (full fields, sounds) and polish validations.

# 🔹 Block 17 — Phase 10 (Editor validations) — 17/12/2025

### ✔ Work completed:

- `TaskEditorViewModel.load` returns `bool` and edit flows show a snackbar/close if the task does not exist.
- Business validation: long break interval cannot exceed total pomodoros; save is blocked and the user is informed.
- UX handling: when editing from the list, if loading fails, it notifies and does not navigate to the editor.
- Added per-event sound selector in the editor (placeholder options, real assets pending) and persisted strings in model/repo.

### 🧠 Decisions made:

- Prioritize editor validations and UX before adding new fields (e.g., sounds) in this phase.
- Keep the editor reactive to the active repo (Firestore/InMemory) without extra changes.
- Reduce sound configuration to essentials (pomodoro start, break start) and keep the final sound as a default to avoid confusion.

### 🎯 Next steps:

- Add sound selection (once assets/definitions are ready) and persist it in the model.
- Windows test pending; if it passes, update roadmap/dev_log with date.

# 🔹 Block 18 — Phase 10 (Editor completed) — 17/12/2025

### ✔ Work completed:

- Full editor with minimal configurable sounds (pomodoro start, break start) and a fixed final sound by default.
- Business validations active and error handling when loading/editing missing tasks.
- Roadmap updated: Phase 10 marked as completed; current phase → 11 (event audio).

### 🎯 Next steps:

- Implement audio playback (Phase 11) with default assets.
- Windows test pending and update docs when validated.

# 🔹 Block 19 — Phase 11 (Event audio, setup) — 17/12/2025

### ✔ Work completed:

- Added `just_audio` and `SoundService` with an id→asset map and silent fallback if the file is missing.
- Integrated the service via provider and PomodoroMachine callbacks to trigger sounds on pomodoro start, break start, and task finish.
- Created `assets/sounds/` with README and included it in `pubspec.yaml`; pub get executed.
- Added default audio files: `default_chime.mp3`, `default_chime_break.mp3`, `default_chime_finish.mp3`.

### 🧠 Decisions made:

- Keep three sounds in the MVP 1.2: pomodoro start, break start, and task finish (fixed), avoiding duplication with break end.
- If an asset is missing or fails to load, ignore it and log in debug; do not show an error to the user.
- Some selector ids had no mapped asset, causing silence on pomodoro start; resolved by mapping aliases to existing assets.

### 🎯 Next steps:

- Test playback on macOS/Android/Web with the added audios. ✔ (completed)
- Update dev_log/roadmap with the date once playback is confirmed on platforms. ✔ (completed)

# 🔹 Block 20 — Phase 11 (Event audio completed) — 17/12/2025

### ✔ Work completed:

- Sound playback confirmed at pomodoro start, break start, and task finish (Android/Web/macOS).
- Sound selector aliases mapped to assets to avoid ids without paths.
- Audio code simplified without temporary logs or unused fields.

### 🎯 Next steps:

- Test on Windows when possible and note the date if it passes.
- Continue with Phase 12 (Connect Editor → List → Execution).

# 🔹 Block 21 — Phase 12 (Connect Editor → List → Execution) — 17/12/2025

### ✔ Work completed:

- TimerScreen loads the real task from the list and uses the ViewModel for all execution.
- Changes in the editor (durations, sounds) are reflected when opening execution; missing task handling shows a snackbar and returns.
- Editor → List → Execution flow working on macOS/Android/Web (Windows pending).

### 🎯 Next steps:

- Test the full cycle on Windows when possible and record the date.
- Move to Phase 13 (real-time Pomodoro sync).

# 🔹 Block 22 — Phase 13 (Real-time sync, setup) — 17/12/2025

### ✔ Work completed:

- Created `PomodoroSession` model and Firestore repository (`users/{uid}/activeSession/current`) with publish/watch/clear.
- `PomodoroViewModel` publishes state on key events (pomodoro start, break start, pause, resume, finish/cancel) with `ownerDeviceId`.
- Basic mirror mode: if the session belongs to another device, the VM mirrors the remote state (remaining time derived from `phaseStartedAt` when available).
- Basic deviceId generated per app session; persistence between runs pending.

### 🎯 Next steps:

- Test with two real devices (same account) and validate delay <2s; adjust if ticks or timestamps need publishing.
- Decide whether to persist `deviceId` locally to keep ownership across restarts.

---

# 🔹 Block 23 — Phase 13 (Validation + ownership) — 06/01/2026

### ✔ Work completed:

- Real-device sync validated (2 devices, same account) with worst-case latency <1s.
- Confirmed mirror device cannot control owner, per specs.
- Persisted `deviceId` locally (SharedPreferences) to keep ownership after restarts.
- Added "Take over" action to claim ownership when the remote owner is unresponsive.
- Fixed macOS task editor input by using controllers and syncing state on load.
- Re-tested restart/reopen flow: owner can resume/pause/cancel consistently; take over validated when owner is down.

### 🧠 Decisions made:

- Persist `deviceId` once per install and inject via ProviderScope override.
- Allow take over when a running phase is overdue or a non-running session is stale.
- Take over thresholds: running phase overdue by 10s; paused/idle stale after 5 minutes.

### 🎯 Next steps:

- Start Phase 14: integrate notifications for pomodoro end + task finish.

---

# 🔹 Block 24 — Phase 14 (Notifications, setup) — 07/01/2026

### ✔ Work completed:

- Added NotificationService using `flutter_local_notifications`.
- Initialized notifications in `main.dart` and injected via provider.
- Triggered notifications on pomodoro end and task finish.
- Deferred permission prompts to avoid blocking app launch and request on TimerScreen.
- Enabled Android core library desugaring for notifications.

### 🎯 Next steps:

- Run `flutter pub get` and validate notifications on macOS/Android.
- Confirm Windows/Linux behavior and adjust platform settings if needed.
- Re-test Android build after desugaring change.

---

# 🔹 Block 25 — Phase 14 (Notifications + UX polish) — 07/01/2026

### ✔ Work completed:

- Auto-dismissed the "Task completed" modal when the session moves out of finished state.
- Scoped auto-dismiss to mirror sessions so local completion still requires confirmation.
- Added a macOS notification center delegate to show banners/lists in foreground.
- Reset finished state on owner acknowledgement (OK) and expose "Start again".
- Allow immediate take over when a session is already finished.

### 🎯 Next steps:

- Validate macOS banner delivery in foreground/background.
- Decide whether mirrors should fire notifications for remote-owned sessions.

---

# 🔹 Block 26 — Phase 14 (Background catch-up) — 07/01/2026

### ✔ Work completed:

- Added app resume handling to fast-forward the owner state using timestamps.
- Projected mirror state from `phaseStartedAt` to avoid frozen 00:00 when the owner is backgrounded.
- Allowed the timer to catch up and publish the updated session on resume.
- Validated Android resumes in sync with real time across devices.

### 🎯 Next steps:

- Implement true Android background ticking (foreground service) to avoid relying on resume.
- Confirm macOS banner delivery (foreground/background).

---

# 🔹 Block 27 — Phase 14 (Android foreground service) — 07/01/2026

### ✔ Work completed:

- Added a native Android foreground service with wake lock to keep the app process alive.
- Wired a Flutter method channel to start/stop/update the foreground notification.
- Hooked the service lifecycle into the pomodoro state (start on run, stop on pause/cancel/finish).
- Validated Android background timing against iOS/macOS with sub-second drift.

### 🎯 Next steps:

- Confirm macOS/iOS banner delivery (foreground/background).

---

# 🔹 Block 28 — Phase 14 (macOS notifications) — 07/01/2026

### ✔ Work completed:

- Added a macOS native notification channel to schedule notifications via UserNotifications.
- Requested permissions and delivered banners in foreground and background for owner sessions.
- Validated macOS notifications after task completion on device.

### 🎯 Next steps:

- Validate Windows/Linux notification delivery if required for MVP 1.2.

---

# 🔹 Block 29 — Phase 6 (Android Google Sign-In debug keystore) — 08/01/2026

### ✔ Work completed:

- Identified Google Sign-In failure caused by a new macOS user generating a new debug keystore.
- Updated SHA-1/SHA-256 in Firebase and replaced `android/app/google-services.json`.
- Confirmed Google Sign-In works and session persists after rebuild.

---

# 🔹 Block 30 — Phase 6 (Auth roadmap note: macOS OAuth) — 08/01/2026

### ✔ Work completed:

- Logged a post-MVP note to add macOS Google Sign-In via OAuth web flow (PKCE + browser).

---

# 🔹 Block 31 — Phase 6 (iOS Google Sign-In fix) — 08/01/2026

### ✔ Work completed:

- Fixed iOS Google Sign-In crash by adding the REVERSED_CLIENT_ID URL scheme to `ios/Runner/Info.plist`.
- Verified Google Sign-In works on iOS and the session persists.

---

# 🔹 Block 32 — Phase 6 (Windows desktop validation and auth stubs) — 08/01/2026

### Work completed:

- Validated Windows desktop build and runtime.
- Added a CMake policy minimum and install prefix override to avoid Firebase C++ SDK build/install failures.
- Guarded Google Sign-In, audio, and notifications on Windows with safe stubs/logs.
- Documented Windows desktop audio/notification follow-up in the roadmap.

### Issues found:

- Firebase C++ SDK emits a CMake minimum version warning on newer CMake.
- Windows build failed installing to Program Files without admin permissions.
- Legacy Firebase accounts created before provider linking return `firebase_auth/unknown-error` on Windows (C++ SDK).

### Decisions made:

- Keep Windows desktop running with email/password only; Google Sign-In stays disabled where unsupported.
- Disable audio and local notifications on Windows until a supported plugin or native implementation is selected.
- Keep generated plugin registrants and build artifacts out of commits when building on Windows.

### Next steps:

- Evaluate Windows-capable audio and notification plugins or native Windows integration.
- Optionally add a migration hint for legacy accounts on Windows.
- Before pushing from Windows, restore generated plugin registrants and remove `android/build` to avoid cross-platform churn.

---

# 🔹 Block 33 — Phase 14 (Windows audio/notifications via adapters) — 08/01/2026

### Work completed:

- Added `audioplayers` and `local_notifier` dependencies for Windows desktop.
- Implemented a Windows audio backend using `audioplayers` while keeping `just_audio` for other platforms.
- Implemented a Windows notification backend using `local_notifier` while keeping `flutter_local_notifications` for other platforms.
- Kept `SoundService` and `NotificationService` as the only public APIs with internal platform adapters.
- Normalized Windows audio asset paths for `audioplayers`.
- Verified Windows audio + notifications and confirmed sync with Android after updating the Android build.
- Spot-checked macOS/Android/iOS/Web for regressions.
- Verified macOS behavior after switching back from Windows.
- Confirmed owner notifications are visible.
- Verified web audio in Chrome (macOS).
- Added Web Google Sign-In client ID meta tag.
- Enabled web notifications via the Notifications API (permission required).
- Enabled Google People API and verified Web Google Sign-In in Chrome.
- Verified web notifications while the app is open (including minimized).
- Confirmed the “Task completed” modal auto-dismisses when another device restarts the same task.

### Issues found:

- Resolved: Windows start/break sounds play correctly while notifications fire (re-tested after path normalization).
- Resolved: Mirror Android device phase mismatch cleared after updating to the latest build.
- Resolved: Web Google Sign-In works after enabling Google People API.
- Resolved: Web notifications enabled (requires browser permission and app open).
- Open: Linux audio/notifications still not verified.

### Decisions made:

- Notifications on Windows are now working correctly, including proper triggering and sound playback
- Keep platform branching inside services and fail silently with debug logs.

### Next steps:

- Verify Linux audio/notifications.

---

# 🔹 Block 34 — Phase 14 (Linux dependency checks and docs) — 13/01/2026

### Work completed:

- Documented Linux desktop dependencies per distro (GTK, libnotify, GStreamer).
- Added a Linux startup dependency check with a warning dialog for missing audio
  or notification libraries.
- Included copy-to-clipboard support for install commands.
- Linked the Linux dependency guide from the README.

### Issues found:

- None.

### Decisions made:

- Keep the Linux dependency check best-effort and non-blocking.

### Next steps:

- Verify the Linux startup dialog with missing dependencies and after installing
  packages.

---

# 🔹 Block 35 — Phase 6 (Linux auth guard on task list/login) — 13/01/2026

### Work completed:

- Hid the login entry point on Linux where Firebase Auth is not supported.
- Added a safe fallback in the login screen to return to the task list when
  authentication is unavailable.

### Issues found:

- None.

### Decisions made:

- Keep authentication flows unchanged on supported platforms.

### Next steps:

- Validate the Linux task list UX now that login is disabled.

---

# 🔹 Block 36 — Phase 14 (Linux dependency debug override) — 13/01/2026

### Work completed:

- Added a debug-only dart-define to force missing Linux dependencies for UI
  testing without changing release behavior.

### Issues found:

- None.

### Decisions made:

- Keep the override inactive by default and only evaluated in debug mode.

### Next steps:

- Validate the dependency dialog using the forced flag.

---

# 🔹 Block 37 — Phase 14 (Linux dependency dialog navigator fix) — 13/01/2026

### Work completed:

- Fixed the Linux dependency dialog to use the app navigator context to avoid
  crashes at startup.

### Issues found:

- Dependency dialog crashed when shown from a context without a Navigator.

### Decisions made:

- Route dialog presentation through the root navigator key.

### Next steps:

- Re-test the forced dependency dialog on Linux.

---

# 🔹 Block 38 — Phase 14 (Remove Linux dependency debug override) — 13/01/2026

### Work completed:

- Removed the temporary debug-only dependency override after validation.

### Issues found:

- None.

### Decisions made:

- Keep Linux dependency checks clean and production-only.

### Next steps:

- None.

---

# 🔹 Block 39 — Phase 14 (Linux notifications via local_notifier) — 13/01/2026

### Work completed:

- Switched Linux notifications to use `local_notifier` for better reliability.
- Kept other platforms unchanged.
- Verified Linux notifications when completing a task.

### Issues found:

- Linux notifications were not appearing with the previous backend.

### Decisions made:

- Reuse the desktop notification backend used on Windows for Linux as well.

### Next steps:

- None.

---

# 🔹 Block 40 — Phase 6 (Linux local task persistence) — 13/01/2026

### Work completed:

- Added a local disk-backed task repository for Linux when auth is unavailable.
- Kept task behavior unchanged on platforms with Firebase Auth support.
- Verified task persistence across app restarts on Linux.

### Issues found:

- None.

### Decisions made:

- Use shared_preferences for low-friction local persistence on Linux.

### Next steps:

- None.

---

# 🔹 Block 41 — Phase 6 (Linux sync notice) — 13/01/2026

### Work completed:

- Added a Linux-only sync notice dialog explaining web sync availability.
- Added an info action on the task list for Linux to reopen the notice.
- Verified the sync notice on Android and web (Chrome).
- Verified the sync notice does not appear on macOS/iOS/Windows.

### Issues found:

- None.

### Decisions made:

- Show the notice once on first launch and allow manual access from the app bar.

### Next steps:

- None.

---

# 🔹 Block 42 — Phase 14 (Windows/macOS/iOS verification) — 14/01/2026

### Work completed:

- Verified Windows sound playback after the latest updates.
- Verified macOS and iOS behavior after the Windows changes.

### Issues found:

- None.

### Decisions made:

- None.

### Next steps:

- None.

---

# 🔹 Block 43 — Reopen flow stabilization — 14/01/2026

### Work completed:

- Persisted `finishedAt` and `pauseReason` in session state and Firestore publish.
- Normalized owner rehydrate to use projected state without background auto-pause.
- Disabled resume prompt flow to avoid inconsistent cross-platform behavior.
- Added macOS startup guards for SharedPreferences/notification init.

### Issues found:

- Resume prompt not reliable across platforms; disabled for now.

### Decisions made:

- Prefer consistent continuation on reopen over prompting until mirror detection is stable.

### Next steps:

- Revisit resume prompt once mirror presence is reliable.
- Validate Windows lifecycle behavior.

---

# 🔹 Block 44 — Local stash (14/01/2026)

### Work completed:

- Stashed local iOS/macOS build artifacts as `git stash` entry: `wip pods`.

### Issues found:

- None.

### Decisions made:

- Keep Podfile/lock and Xcode project changes out of feature commits.

### Next steps:

- Apply the stash only if those build artifacts are needed later.

---

# 🔹 Block 45 — Notification silence + resume prompt cleanup — 15/01/2026

### Work completed:

- Silenced completion notifications across platforms while keeping app audio intact.
- Added the iOS notification center delegate to ensure foreground banners display.
- Removed the unused resume prompt flow from the ViewModel and TimerScreen.

### Issues found:

- iOS completion notifications were not showing; fixed by setting the delegate.

### Decisions made:

- Keep app sounds as the only audible signal; completion notifications remain silent.

### Next steps:

- None.

---

# 🔹 Block 46 — Execution guardrails — 15/01/2026

### Work completed:

- Prevented starting a new task while another execution is active.
- Added exit confirmation on the timer screen to cancel or continue the active run.
- Blocked editing/deleting tasks while they are currently running.
- Centralized active-session checks in ViewModels and providers to avoid invalid states.

### Issues found:

- Users could start/edit tasks while a session was running, causing inconsistent states.

### Decisions made:

- Treat running and paused states as active executions; finished is allowed to exit.

### Next steps:

- None.

---

# 🔹 Block 47 — Phase 14 (Local custom sounds + per-device overrides) — 17/01/2026

### ✔ Work completed:

- Added typed `SelectedSound` and local custom sound picker for Pomodoro start and Break start.
- Custom sounds are stored per-device only via SharedPreferences overrides (not synced to Firestore).
- Built-in options aligned to the three available assets to ensure selection always maps to real files.
- Added validation for local imports (format/size/duration) and fallback to built-in on failure.
- Verified local sound selection on macOS/iOS/Android; web picker disabled on Chrome.

### ⚠️ Issues found:

- Sound selection appeared unchanged because built-in options mapped to the same asset; fixed by aligning selectors to the three available assets.
- Initial analyzer errors after refactor (duplicate `save()`, missing helper methods, and async context checks) were resolved.
- macOS file picker required Xcode sandbox user-selected file access to open the dialog.

### 🧠 Decisions made:

- Firestore stores only built-in sounds; custom sounds remain local to the device.
- Resolve local overrides before playback to avoid silent failures.

### 🎯 Next steps:

- Test custom sound picker and playback on Windows and Linux.

# 🔹 Block 48 — Phase 14 (Windows audio fix) — 18/01/2026

### ✔ Work completed:

- Normalized audioplayers asset paths on Windows to stop assets/assets lookup and restore built-in sound playback.
- Skipped just_audio duration probing on Windows/Linux to prevent MissingPluginException when picking custom sounds.

### 🧠 Decisions made:

- Keep just_audio for duration validation on platforms where it is supported; fall back to accepting files on Windows/Linux until a native duration check is available.

### 🎯 Next steps:

- Re-validate custom sound selection and playback on Windows and Linux with the new guards.

---

# 🔹 Block 49 — Phase 14 (macOS custom sound picker fix) — 18/01/2026

### ✔ Work completed:

- Restored macOS sandbox permission for user-selected files so the local sound picker works again.
- Added read-only access to Debug and Release entitlements to allow file selection.

### ⚠️ Issues found:

- macOS file picker failed after pulling changes because the user-selected file entitlement was missing.

### 🧠 Decisions made:

- Keep read-only access only (no write access) for security.

### 🎯 Next steps:

- Re-test custom sound pick + playback on macOS.

---

# 🔹 Block 50 — Phase 14 (Linux custom sound validation) — 18/01/2026

### ✔ Work completed:

- Verified custom sound selection and playback on Linux with no code changes.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- None.

### 🎯 Next steps:

- None.

# 🔹 Block 438 — Phase 17 conflict resolution + planning total duration (18/02/2026)

### ✔ Work completed:

- Added Plan Group total duration (work + breaks) to the planning preview.
- Implemented late-start overlap queue flow with selection, reorder, preview,
  and batch updates for cancel/reschedule.
- Added running overlap decision modal with pause, postpone, cancel, or end
  current group handling.
- Added TaskRunGroup canceledReason field and repository batch save support.
- Updated ScheduledGroupCoordinator to detect overdue overlaps and pre-run
  conflicts and trigger the appropriate UI flows.

### 🧠 Decisions made:

- Use Firestore batch writes for multi-group conflict resolution updates.
- Keep conflict resolution UI in-app with full-screen queue + blocking modal.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Validate Phase 17 conflict resolution flows on devices (Account + Local).

# 🔹 Block 437 — Close Phase 17 validation items (18/02/2026)

### ✔ Work completed:

- Confirmed Phase 17 validation for pre-run reservation messaging, planning
  redesign with range/total-time scheduling, and scheduled pre-run auto-start.
- Removed the three validated Phase 17 items from the reopened phases list in
  `docs/roadmap.md`.

### 🧠 Decisions made:

- Treat these Phase 17 items as closed; keep remaining Phase 17 reopen items
  limited to conflict resolution and total-duration display.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Implement Phase 17 conflict resolution rules and Plan Group total duration.

---

# 🔹 Block 51 — Phase 14 (Task timestamps migration) — 18/01/2026

### ✔ Work completed:

- Added `createdAt`/`updatedAt` to `PomodoroTask` with ISO serialization and safe parsing.
- Updated task editor to initialize and refresh timestamps on save.
- Backfilled missing timestamps in Firestore reads and Linux local storage.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Store timestamps as ISO strings for cross-platform persistence and JSON storage.

### 🎯 Next steps:

- None.

---

# 🔹 Block 52 — Phase 15 (TaskRunGroup model/repo kickoff) — 18/01/2026

### ✔ Work completed:

- Added `TaskRunGroup`/`TaskRunItem` models with serialization and derived totals.
- Implemented Firestore repository for task run groups with retention pruning.
- Added retention settings service (default 7, max 30) and providers.
- Extended `PomodoroSession` with optional group context fields and default values in active session publish.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep group context fields optional until the run mode redesign consumes them.

### 🎯 Next steps:

- Wire TaskRunGroup creation flow in the Task List redesign (Phase 16).
- Extend active session publish to include group context when available.

---

# 🔹 Block 53 — Phase 16 (Task List redesign kickoff) — 18/01/2026

### ✔ Work completed:

- Added task ordering via `order` field with persistence/backfill in repos.
- Implemented selection checkboxes, reorder handle-only drag, and Confirm flow.
- Added theoretical start/end time ranges for selected tasks (Start now).
- Snapshot creation saves a `TaskRunGroup` draft and clears selection.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep task finish sound fixed in MVP; post-MVP configurability tracked in docs.

### 🎯 Next steps:

- Build pre-start planning UI (Phase 17).
- Wire group execution to the redesigned Run Mode (Phase 18).

---

# 🔹 Block 54 — Phase 16 (Task List redesign completed) — 19/01/2026

### ✔ Work completed:

- Validated selection, reorder, and multi-device sync across macOS, iOS, Android, and Web.
- Fixed task run group creation by updating Firestore rules for `taskRunGroups`.
- Added error surfacing on confirm to detect permission issues.

### ⚠️ Issues found:

- Firestore rules initially blocked group creation (`permission-denied`).

### 🧠 Decisions made:

- Phase 16 is complete once confirm creates a `TaskRunGroup` and syncs across devices.

### 🎯 Next steps:

- Start Phase 17: planning flow and conflict management.
- Smoke test Phase 16 on Windows and Linux.

# 🔹 Block 55 — Phase 16 (Linux local TaskRunGroups) — 19/01/2026

### ✔ Work completed:

- Added a SharedPreferences-backed TaskRunGroup repository for Linux local-only mode.
- Allowed task group creation without sign-in when auth is unavailable.
- Updated specs to document local TaskRunGroups on Linux.

### 🧠 Decisions made:

- Keep sign-in required on platforms that support Firebase; Linux uses local-only groups.

### 🎯 Next steps:

- Continue Phase 17 planning flow.

# 🔹 Block 56 — Windows validation (latest implementations) — 19/01/2026

### ✔ Work completed:

- Verified the latest implementations on Windows with no additional changes required.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep the Windows configuration unchanged after validation.

### 🎯 Next steps:

- Continue Phase 17 planning flow.

# 🔹 Block 57 — TaskRunGroup status normalization pending — 19/01/2026

### ✔ Work completed:

- Recorded the need to normalize TaskRunGroup status when running groups exceed their theoreticalEndTime.

### ⚠️ Issues found:

- Multiple groups can remain in `running` while their theoreticalEndTime is in the past.

### 🧠 Decisions made:

- Add auto-complete or reconciliation logic and verify on-device before updating specs.

### 🎯 Next steps:

- Implement the status normalization and confirm it on a real device.

# 🔹 Block 58 — TaskRunGroup status normalization implemented — 19/01/2026

### ✔ Work completed:

- Implemented auto-complete normalization when running groups exceed their theoreticalEndTime (Firestore + local repo).

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep normalization server-agnostic and rely on device verification before updating specs.

### 🎯 Next steps:

- Verify on device and update specs/roadmap status when confirmed.

# 🔹 Block 59 — Phase 17 planning flow validated — 19/01/2026

### ✔ Work completed:

- Planning flow + conflict management validated on iOS, macOS, Android, and Web.
- Running groups block start-now; scheduled groups allow non-overlapping plans.
- Overlaps prompt to cancel running or delete scheduled; timing calculations verified.

### ⚠️ Issues found:

- Windows and Linux validation pending for this implementation.

### 🧠 Decisions made:

- Keep Windows/Linux as pending validation before closing Phase 17.

### 🎯 Next steps:

- Validate Phase 17 behavior on Windows and Linux and update docs.

# 🔹 Block 60 — TaskRunGroup actual start tracking — 19/01/2026

### ✔ Work completed:

- Added `actualStartTime` to TaskRunGroup and persisted it for running groups.
- Recalculated `theoreticalEndTime` from the real start moment after conflict dialogs.
- Conflict checks and end-time normalization now prefer `actualStartTime` over `createdAt`.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep `createdAt` as the flow-start timestamp, and use `actualStartTime` for execution timing.

### 🎯 Next steps:

- None.

# 🔹 Block 61 — Specs/Roadmap Local Mode update — 19/01/2026

### ✔ Work completed:

- Updated specs to define Local Mode as a first-class backend across all platforms.
- Added explicit mode selection and persistent UI indicator requirements.
- Added a roadmap phase for Local Mode (offline/no auth) with import/sync expectations.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep Local Mode data isolated unless the user explicitly imports it into Account Mode.

### 🎯 Next steps:

- Implement Local Mode toggle and cross-platform local repositories per Phase 6.6.

# 🔹 Block 62 — Local/Account scope guard + explicit import — 20/01/2026

### ✔ Work completed:

- Added AppMode persistence (Local vs Account) and enforced repository scoping by mode.
- Prevented implicit sync by requiring an explicit post-login choice (use account vs import local data).
- Implemented a one-time import flow for local tasks and task groups into the current UID.
- Updated Task List UI with a mode indicator and explicit mode switch action.
- Ensured logout returns to Local Mode without auto-import or auto-sync.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Local Mode is device-scoped only; Account Mode is UID-scoped only.
- Import is user-confirmed and targeted to the current UID (no implicit merge).

### 🎯 Next steps:

- Finish Phase 6.6 UX: mode selector entry in Settings and import conflict options.

# 🔹 Block 63 — Phase 18 (Run Mode redesign kickoff) — 20/01/2026

### ✔ Work completed:

- TimerScreen now loads TaskRunGroups (groupId) and removes single-task loading.
- Added Run Mode center stack (current time, remaining time, status/next boxes) inside the circle.
- Added contextual task list (prev/current/next) with projected time ranges.
- Added planned-groups indicator placeholder in Run Mode header.
- Updated group completion modal with summary totals.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Run Mode remains group-only; no single-task execution path.
- Planned Groups screen is deferred (indicator only) until Phase 19.

### 🎯 Next steps:

- Finish Phase 18: align visuals to specs (golden-green next box, idle preview), refine ranges on pause/resume.

# 🔹 Block 64 — Run Mode status clarification — 20/01/2026

### ✔ Work completed:

- Clarified Run Mode "Next" status rules in specs: end-of-group only on last pomodoro of last task.
- Added explicit rule for last pomodoro of a task with remaining tasks: show next task's first pomodoro (no break between tasks).

### ⚠️ Issues found:

- App closed during the transition after the last pomodoro of a task when more tasks remain (repro on Android).

### 🎯 Next steps:

- Align TimerScreen logic with the clarified spec and fix the crash during task transitions.

# 🔹 Block 65 — Run Mode next-box wording — 20/01/2026

### ✔ Work completed:

- Updated specs to show "End of task" during the last break of a task when more tasks remain.

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Update TimerScreen logic to match the new wording rule.

# 🔹 Block 66 — Run Mode timing consistency fix — 20/01/2026

### ✔ Work completed:

- Anchored all HH:mm ranges to TaskRunGroup.actualStartTime + accumulated durations + pause offsets.
- Included final breaks in task/group duration calculations and end-of-task projections.
- Unified TimerScreen/TaskList ranges with the group timeline (placeholders before actual start).
- Stabilized task transitions by publishing completed sessions only at group end.
- Repository normalization now derives theoreticalEndTime from actualStartTime + totalDurationSeconds only.

### ⚠️ Issues found:

- Task ranges were recalculated from per-task starts and missed final breaks, causing drift and flicker at task boundaries.

### 🧠 Decisions made:

- Single source of truth for ranges is group.actualStartTime with accumulated durations and pause offsets.
- Pre-start states show placeholders instead of inferred timestamps.

### 🎯 Next steps:

- Re-run multi-task scenarios on device to validate timing consistency end-to-end.

# 🔹 Block 67 — Groups Hub documentation update — 21/01/2026

### ✔ Work completed:

- Renamed "Planned Groups" to "Groups Hub" across specs and roadmap for the canonical screen name.
- Defined post-completion navigation to Groups Hub after the user dismisses the completion modal.
- Added Groups Hub actions for running completed groups again and direct access to the Task List screen.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- "Groups Hub" is the final screen name.
- Post-completion navigation is only triggered after explicit modal dismissal (no time-based auto-navigation).

### 🎯 Next steps:

- None.

# 🔹 Block 68 — macOS run failed (signing) — 21/01/2026

### ⚠️ Issues found:

- `flutter run` failed on macOS: no Mac App Development provisioning profiles found for `com.marcdevelopez.focusinterval` and automatic signing is disabled.

### 🧠 Notes:

- Xcodebuild suggests enabling automatic signing or passing `-allowProvisioningUpdates`.

### 🎯 Next steps:

- Configure signing for the macOS Runner target (or enable automatic signing) before running on macOS.

# 🔹 Block 69 — macOS signing resolved — 22/01/2026

### ✔ Work completed:

- Apple Developer Program activated for the team and the Bundle ID `com.marcdevelopez.focusinterval` is now owned by the team.
- Automatic signing can now register the Bundle ID and generate the macOS development profile.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep `com.marcdevelopez.focusinterval` as the canonical Bundle ID for macOS.

### 🎯 Next steps:

- Re-run `flutter run -d macos` to confirm the build now succeeds. (Completed 22/01/2026)

# 🔹 Block 70 — Pause/Resume timeline fix — 22/01/2026

### ✔ Work completed:

- Fixed TaskRunGroup time ranges so Pause/Resume only affects the current and future tasks.
- Preserved historical ranges for completed tasks by freezing their recorded time ranges.
- Updated Run Mode contextual list to use stable per-task ranges.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Do not shift completed task ranges after a pause; only the active task and future tasks are extended.

### 🎯 Next steps:

- Re-test the Pause/Resume scenario to confirm time ranges stay stable for completed tasks. (Completed 22/01/2026)

# 🔹 Block 71 — Pause/Resume timeline fix validated — 22/01/2026

### ✔ Work completed:

- Verified Pause/Resume timeline behavior on macOS, iOS, Android, and Chrome.
- Confirmed completed task ranges remain stable while the active task and future tasks extend with pause time.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep the per-task range freezing behavior as the canonical rule for group timelines.

### 🎯 Next steps:

- None.

# 🔹 Block 72 — Desktop clock update when out of focus — 22/01/2026

### ✔ Work completed:

- Kept the Run Mode system clock timer active on desktop and web when the app loses focus.
- Preserved the existing pause behavior for mobile background states.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Desktop/web should keep updating the HH:mm clock while out of focus; mobile can pause in background.

### 🎯 Next steps:

- Verify the clock continues updating while the window is unfocused on Windows and Linux when possible.

### ✅ Validation (22/01/2026)

- Verified on macOS and Chrome.
- Windows and Linux pending.

# 🔹 Block 73 — Scheduled group lifecycle clarified — 22/01/2026

### ✔ Work completed:

- Clarified the scheduled group lifecycle in specs and roadmap (scheduled -> running -> completed).
- Documented auto-start requirements at scheduledStartTime and catch-up on next launch/resume.
- Added Phase 17 reminder for scheduled auto-start and resume/launch catch-up.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- ScheduledStartTime remains historical; actualStartTime is set when the group actually starts.

### 🎯 Next steps:

- Implement the scheduled auto-start + resume/launch catch-up behavior.

# 🔹 Block 74 — Active group discovery clarified — 22/01/2026

### ✔ Work completed:

- Clarified that running sessions auto-open Run Mode on launch/login (owner or mirror).
- Added fallback UX: Task List banner + Groups Hub entry point when auto-open is blocked.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Auto-open remains the default for running sessions; fallback entry points are mandatory for discoverability.

### 🎯 Next steps:

- Implement the Task List banner and Groups Hub "Open Run Mode" action.

# 🔹 Block 75 — Roadmap order clarified for active group entry points — 22/01/2026

### ✔ Work completed:

- Moved the running-group entry point implementation to Phase 19 (Groups Hub) for clearer sequencing.
- Kept auto-open on launch/login in Phase 13 and documented the fallback entry point as Phase 19 work.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Entry points for running groups are implemented alongside Groups Hub to keep navigation scalable.

### 🎯 Next steps:

- Implement the Phase 19 entry points when the Groups Hub screen is built.

# 🔹 Block 76 — SnackBar layout safety — 22/01/2026

### ✔ Work completed:

- Moved bottom action controls to `bottomNavigationBar` so SnackBars no longer cover them.
- Reverted to standard SnackBar behavior and animation (no custom floating margin).

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- SnackBars must never cover bottom-aligned actions; solve via layout, not custom margins.

### 🎯 Next steps:

- Validate SnackBar positioning on desktop and mobile screens with bottom actions.

# 🔹 Block 77 — Custom sound path visibility — 22/01/2026

### ✔ Work completed:

- Updated the sound selector to show custom file name (with extension) and full local path/URI.
- Kept the dropdown selection concise while exposing the full path below the field.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Display full local path/URI for custom sounds to improve transparency and debugging.

### 🎯 Next steps:

- Verify on macOS/iOS/Android that the displayed path matches the selected file.

# 🔹 Block 78 — Android custom sound path corrected — 22/01/2026

### ✔ Work completed:

- Persisted the original selected path/URI alongside the copied playback path.
- Persisted the original picker file name for reliable display labels.
- On Android, displayPath now uses the picker identifier (content://) and never falls back to the cache path.
- Updated the sound selector to control the selected value and hide the path line when no original path/URI is available.
- Applied local sound overrides when building TaskRunGroup items so custom audio plays.

### ⚠️ Issues found:

- Android previously showed the app sandbox copy path instead of the user-selected file path.

### 🧠 Decisions made:

- Keep playback using the imported app-local file, but always display the original selection path/URI.

### 🎯 Next steps:

- Re-verify on Android and confirm behavior for content URI selections.

# 🔹 Block 79 — Revert custom sound display to filename-only — 23/01/2026

### ✔ Work completed:

- Removed custom path/URI display from the Task Editor sound selector.
- Restored custom sound label to filename-only (“Custom: <file>”).
- Rolled back display-path persistence to avoid showing incorrect paths.

### ⚠️ Issues found:

- Displaying original Android paths was unreliable and caused confusing labels.

### 🧠 Decisions made:

- Keep the UI to filename-only to preserve correctness and avoid exposing cache paths.

### 🎯 Next steps:

- Re-test custom sound selection on Android to confirm name and playback are correct.

# 🔹 Block 80 — Restore custom filename display + playback — 23/01/2026

### ✔ Work completed:

- Persisted the original file name (displayName) for custom sounds.
- Updated the selector to prefer the stored filename while keeping filename-only UI.
- Applied local sound overrides when creating TaskRunGroup items so custom audio plays.

### ⚠️ Issues found:

- Filename display requires re-selecting the custom file to capture displayName.

### 🧠 Decisions made:

- Keep filename-only UI, but store original file name for correct labeling.

### 🎯 Next steps:

- Re-select a custom sound on Android and verify the filename and playback.

# 🔹 Block 81 — Task list item UX overhaul — 23/01/2026

### ✔ Work completed:

- Replaced checkbox selection with a highlighted card style and long-press context menu (edit/delete + confirm).
- Redesign task list items with three stat cards, dot-grid interval visualization, and a dedicated time-range row.
- Restored custom sound filenames in the list using local sound overrides; default labels rendered in muted text.
- Added a note in the editor clarifying custom sounds are stored locally.
- Updated specs to document the new task item layout and behavior.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep selection feedback via subtle background/border instead of checkboxes.
- Use dot-grid columns that scale to fit narrow widths.

### 🎯 Next steps:

- Validate the new layout on narrow mobile screens.

# 🔹 Block 82 — Task List AppBar layout fix — 23/01/2026

### ✔ Work completed:

- Reworked Task List AppBar to avoid overflow and keep logout visible on mobile.
- Made Account/Local mode chip and email act as the mode switch trigger.
- Moved account email + logout to the right of the “Your tasks” line.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Remove the dedicated switch icon to reduce header width on narrow screens.

### 🎯 Next steps:

- Re-check header layout on the smallest device widths.

# 🔹 Block 83 — Untitled tasks observed — 23/01/2026

### ✔ Work completed:

- Noted that some tasks appeared with empty names ("Untitled") without user action.
- Decided to monitor before adding stricter validation or migration.

### ⚠️ Issues found:

- Tasks with empty names can appear in the list (source unclear).

### 🧠 Decisions made:

- Leave current behavior for now; if it reappears, enforce non-empty names at save/repo level.

### 🎯 Next steps:

- If the issue reoccurs, add hard validation to block empty task names and consider cleanup.

# 🔹 Block 84 — Local mode task group guard fix (Android) — 23/01/2026

### ✔ Work completed:

- Fixed task group creation guard to only require sign-in in Account mode.
- Restored Local mode task group creation on Android while keeping Account mode checks.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep Local mode fully functional regardless of auth availability on the platform.

### 🎯 Next steps:

- Re-verify task group creation in Local and Account modes on Android.

# 🔹 Block 85 — Web Local mode data-loss warning — 23/01/2026

### ✔ Work completed:

- Added a one-time web-only warning dialog for Local mode storage limitations.
- Included a direct Sign in action to switch to Account mode and sync.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Warn users that Local mode persists only in the current browser and can be cleared.

### 🎯 Next steps:

- Verify the warning shows once per browser and only in Local mode on web.

# 🔹 Block 86 — Break duration validation + guidance — 23/01/2026

### ✔ Work completed:

- Added shared break-duration guidance logic (optimal ranges + hard limit checks).
- Integrated hard validation (breaks cannot exceed pomodoro duration).
- Added soft warnings for suboptimal ranges with a confirm dialog.
- Added helper text and color cues on break inputs.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Use a hybrid validation approach: hard block for invalid breaks, soft warning for suboptimal ranges.

### 🎯 Next steps:

- Validate the new warnings on create/edit flows and during Apply settings (when implemented).

# 🔹 Block 87 — Break validation tests — 23/01/2026

### ✔ Work completed:

- Added unit tests for break-duration guidance and ranges.
- Added TaskEditorViewModel tests for guidance and status flags.
- Ran full `flutter test` suite successfully.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep tests focused on validation logic; widget/integration tests can follow once editor keys are added.

### 🎯 Next steps:

- Add widget tests after adding stable editor field keys (if needed).

# 🔹 Block 88 — Long break interval validation loosened — 23/01/2026

### ✔ Work completed:

- Removed the Task Editor validation that blocked longBreakInterval > totalPomodoros.
- Kept the minimum constraint (>= 1) via numeric field validation.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Treat longBreakInterval as an independent cadence; tasks may never reach a long break if the interval is larger than the total.

### 🎯 Next steps:

- None.

# 🔹 Block 89 — Long break interval guidance — 23/01/2026

### ✔ Work completed:

- Added research-based helper guidance and color cues for longBreakInterval.
- Added info dialog explaining the long break interval behavior.
- Added a note when the interval exceeds total pomodoros.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep long break interval fully flexible while educating users with guidance.

### 🎯 Next steps:

- Verify helper text and info dialog on mobile and web.

# 🔹 Block 90 — Long break interval tests — 23/01/2026

### ✔ Work completed:

- Added validator tests for long break interval guidance and edge cases.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep interval guidance logic in shared validators for testability.

### 🎯 Next steps:

- Run `flutter test` after any UI copy changes.

# 🔹 Block 91 — Long break interval copy shortened — 23/01/2026

### ✔ Work completed:

- Shortened longBreakInterval helper copy to fit small screens.
- Kept warnings and notes while reducing line length.
- Updated related validator tests.
- Ran `flutter test` successfully.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep helper copy concise and rely on the info dialog for full context.

### 🎯 Next steps:

- Re-check the helper text on the smallest mobile widths.

# 🔹 Block 92 — Pomodoro integrity + task weight specs — 23/01/2026

### ✔ Work completed:

- Documented Pomodoro integrity modes (shared structure vs per-task).
- Defined task weight as integer pomodoros + derived percentage with rounding rules.
- Added planned UI implications and warning requirements to specs.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep this as documentation-first with no behavior change yet.

### 🎯 Next steps:

- Implement group mode selection, integrity warning, and percentage editing when scheduled.

# 🔹 Block 93 — Pomodoro duration guidance — 23/01/2026

### ✔ Work completed:

- Added pomodoro duration guidance with color cues and info dialog.
- Enforced hard validation for 15–60 minutes.
- Added validator tests for pomodoro duration guidance.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Add a general 31–34 minute range to avoid gaps between creative and deep ranges.

### 🎯 Next steps:

- Verify pomodoro helper text fits on smallest devices.

# 🔹 Block 94 — Task presets + task weight UI docs — 24/01/2026

### ✔ Work completed:

- Documented reusable Pomodoro configuration presets (Task Presets) in specs.
- Documented task weight (%) placement in Task List and Task Editor.
- Added a documentation-first roadmap subphase for these UX refinements.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep these changes documentation-only to avoid behavior changes.

### 🎯 Next steps:

- Implement presets and weight UI placement when scheduled.

# 🔹 Block 95 — GitHub Sign-In docs — 24/01/2026

### ✔ Work completed:

- Documented GitHub as an optional Account Mode provider.
- Added platform constraints and fallback behavior in specs.
- Added a documentation-first roadmap subphase for GitHub Sign-In.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep GitHub Sign-In non-blocking and platform-dependent.

### 🎯 Next steps:

- Revisit once platform OAuth constraints are fully validated.

# 🔹 Block 96 — Roadmap alignment for Pomodoro integrity docs — 24/01/2026

### ✔ Work completed:

- Ensured roadmap explicitly includes Pomodoro integrity modes as documentation-first scope.
- Updated global roadmap status note to reflect the added specs coverage.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep Pomodoro integrity coverage in Phase 10.4 (documentation-first) to avoid blocking MVP.

### 🎯 Next steps:

- None.

# 🔹 Block 97 — Phase 6.6 status clarification — 24/01/2026

### ✔ Work completed:

- Marked Phase 6.6 as partially complete with a remaining requirement.

### ⚠️ Issues found:

- Persistent mode indicator is still missing on some screens.

### 🧠 Decisions made:

- Keep Phase 6.6 reopened until the mode indicator is visible on all screens.

### 🎯 Next steps:

- Implement a global, always-visible mode indicator and close Phase 6.6.

# 🔹 Block 98 — Long break interval cap + Task List overflow fix — 24/01/2026

### ✔ Work completed:

- Added a hard maximum for long break interval (8) in the Task Editor validator.
- Clamped long break interval dots in Task List and Task Editor to avoid layout overflow.
- Updated specs to document the new upper bound.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Enforce an upper bound aligned with Pomodoro practice to prevent UI breaks.

### 🎯 Next steps:

- Re-check task cards on small screens with the capped interval display.

# 🔹 Block 99 — Long break interval max raised to 12 — 24/01/2026

### ✔ Work completed:

- Increased the hard max long break interval to 12 pomodoros.
- Updated Task Editor validation copy to explain fatigue risk.
- Updated specs to align with the 12-pomodoro cap.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Allow a wider upper bound (12) while keeping guidance ranges unchanged.

### 🎯 Next steps:

- Verify the dots layout still fits at the 12-pomodoro cap on small screens.

# 🔹 Block 100 — Live interval guidance while typing — 24/01/2026

### ✔ Work completed:

- Added live validation + color feedback for long break interval as users type.
- Wired interval guidance and dots to the current input value.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Trigger interval validation on user interaction for immediate UX feedback.

### 🎯 Next steps:

- Verify interval warnings and error text on mobile and web keyboards.

# 🔹 Block 101 — Task List dots height tuning — 24/01/2026

### ✔ Work completed:

- Increased Task List long-break dots height to fit 3 rows per column.
- Reduced dot column count to avoid horizontal overflow on small cards.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep stat card height unchanged; adjust dot layout height only.

### 🎯 Next steps:

- Confirm no overflow on the smallest supported widths.

# 🔹 Block 102 — Editor dots height aligned with Task List — 24/01/2026

### ✔ Work completed:

- Aligned Task Editor interval dots height with Task List (3 rows per column).
- Adjusted editor dots card padding to keep the layout consistent.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Match editor dots layout to the Task List for visual consistency.

### 🎯 Next steps:

- Verify the interval suffix still fits on the smallest field widths.

# 🔹 Block 103 — Clamp interval dots to 3 rows — 24/01/2026

### ✔ Work completed:

- Capped long-break dots layout to a maximum of 3 rows per column.
- Applied the same row cap in Task Editor and Task List for consistency.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Prefer a stable 3-row grid to prevent vertical overflow while keeping density.

### 🎯 Next steps:

- Re-check dots layout at the 12-pomodoro cap on the smallest widths.

# 🔹 Block 104 — Live pomodoro validation state — 24/01/2026

### ✔ Work completed:

- Enabled live autovalidation for the pomodoro duration field.
- Ensured error state clears as soon as the input returns to valid range.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Use on-user-interaction validation for immediate feedback.

### 🎯 Next steps:

- Verify pomodoro field behavior on mobile keyboards.

# 🔹 Block 105 — Break duration relationship validation — 24/01/2026

### ✔ Work completed:

- Enforced short break < long break validation in the Task Editor.
- Added immediate field-level errors for short/long break conflicts.
- Added validator tests for break-duration ordering.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Treat short >= long as a hard validation error with field-specific messaging.

### 🎯 Next steps:

- Re-check break fields on mobile and web keyboards for immediate feedback.

# 🔹 Block 106 — Validation priority for blocking vs guidance — 24/01/2026

### ✔ Work completed:

- Ensured break-order conflicts trigger validation on both short/long fields immediately.
- Suppressed optimization helper text when a blocking break validation is active.
- Aligned break validation visuals to prioritize blocking errors over guidance.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Once a hard rule is violated, optimization guidance is hidden until resolved.

### 🎯 Next steps:

- Verify break field validation priorities on mobile and web layouts.

# 🔹 Block 107 — Break validation error reset + specs alignment — 24/01/2026

### ✔ Work completed:

- Added explicit spec bullets for break order validation and blocking error priority.
- Fixed break field validation to revalidate on change after a failed save attempt.
- Allowed long break error messages to wrap to two lines to avoid truncation.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Treat break validation as fully reactive and ensure errors clear immediately.

### 🎯 Next steps:

- Re-check break validation on the smallest supported widths.

# 🔹 Block 108 — Task Editor info tooltips — 24/01/2026

### ✔ Work completed:

- Added info tooltips for short break, long break, and total pomodoros fields.
- Reused the info icon styling to keep the editor consistent.
- Added neutral guidance text aligned with Pomodoro best practices.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep info tooltips educational only; validation remains unchanged.

### 🎯 Next steps:

- Visual QA on mobile widths for the new suffix icon layouts.

# 🔹 Block 109 — macOS debug freeze tracking — 24/01/2026

### ✔ Work completed:

- Logged recurrent macOS debug freezes (flutter run -d macos -v) where the app becomes unresponsive.
- Captured that SIGQUIT/kill -QUIT generates a crash report but does not explain the root freeze cause.

### ⚠️ Issues found:

- In debug runs, the app can become unresponsive on macOS (sometimes immediately after launch).

### 🧠 Decisions made:

- Use DevTools pause/stack capture or flutter attach to collect Dart stacks without terminating the process.
- Validate if the freeze reproduces in profile/release builds to rule out debug-only overhead.

### 🎯 Next steps:

- Capture Dart stack from DevTools when the freeze occurs and compare against profile/release runs.

# 🔹 Block 110 — Phase 6 (Email verification gating + reclaim flow) — 24/01/2026

### ✔ Work completed:

- Added email verification gating for Account Mode; sync is disabled until verified.
- Switched auth stream to `userChanges` so verification refreshes after reload.
- Added verification UI in Login + Task List (resend email, verify, switch to Local Mode, sign out).
- Added reclaim flow for email/password accounts (email-already-in-use handling + password reset).

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep unverified users in Local Mode and block Account Mode until verification.
- Use explicit verification actions instead of implicit sync for unverified users.

### 🎯 Next steps:

- QA email verification flow on macOS/Windows (email/password) and confirm sync unlocks after verification.

# 🔹 Block 111 — Fix Riverpod listen assertion on Task List — 24/01/2026

### ✔ Work completed:

- Moved email verification listener to `build` to satisfy Riverpod `ref.listen` constraints.
- Restored app boot on macOS/iOS/Android/Web without the ConsumerWidget assertion.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep `ref.listen` only inside widget build for Riverpod consumer safety.

### 🎯 Next steps:

- Re-run app on macOS/iOS/Android/Web to confirm the Task List opens without assertions.

# 🔹 Block 112 — Verification spam reminder copy — 24/01/2026

### ✔ Work completed:

- Added a spam-folder reminder after verification emails are sent.
- Updated verification dialogs to mention spam if the email is delayed.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep reminders concise and only after a send action or in the verification dialog.

### 🎯 Next steps:

- None.

# 🔹 Block 113 — Windows validation (email verification flow) — 25/01/2026

### ✔ Work completed:

- Verified email verification gating + reclaim flow on Windows (Account Mode).
- Confirmed Linux cannot validate Firebase auth because platform support is disabled.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Treat Linux as Local Mode only until Firebase auth support is added.

### 🎯 Next steps:

- None.

# 🔹 Block 114 — Phase 6.6 completion (mode indicator across screens) — 25/01/2026

### ✔ Work completed:

- Added a persistent Local/Account mode indicator to Login, Task Editor, and Run Mode.
- Confirmed mode selector + explicit import flow remain unchanged (Account Mode import on sign-in only).

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep the import prompt only when switching into Account Mode to avoid confusing Local Mode users.

### 🎯 Next steps:

- None.

# 🔹 Block 115 — Break duration validation fixes — 25/01/2026

### ✔ Work completed:

- Fixed break validation messaging to use the current pomodoro input value.
- Enforced breaks to be strictly shorter than the pomodoro duration.
- Updated validator tests and specs wording to reflect the stricter rule.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Treat equal-duration breaks as invalid to preserve Pomodoro rhythm.

### 🎯 Next steps:

- QA Task Editor break validation on macOS/iOS/Android/Web.

# 🔹 Block 116 — Password visibility toggle (Login) — 25/01/2026

### ✔ Work completed:

- Added a show/hide password toggle to the Login screen password field.
- Kept behavior consistent across platforms with standard eye/eye-off icons.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep visibility user-controlled with a persistent toggle, not time-based.

### 🎯 Next steps:

- None.

# 🔹 Block 117 — Non-blocking bootstrap + safe init fallbacks — 25/01/2026

### ✔ Work completed:

- Avoided blocking the first frame by moving startup initialization into a bootstrap widget.
- Added timeouts and safe fallbacks for Firebase, notifications, device info, and app mode init.
- Falls back to stub auth/firestore when Firebase init fails or times out.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Prefer a visible boot screen over a black pre-frame hang on slow or broken devices.

### 🎯 Next steps:

- Re-test the Android physical device startup loop and confirm the app reaches the boot screen/app.

# 🔹 Block 118 — Hide debug banner on boot screen — 25/01/2026

### ✔ Work completed:

- Disabled the debug banner on the bootstrap screen to avoid a brief debug tag flash.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep boot screen visuals consistent with the main app theme.

### 🎯 Next steps:

- None.

# 🔹 Block 119 — Mode chip account identity visibility — 25/01/2026

### ✔ Work completed:

- Shortened mode chip labels to “Local” / “Account”.
- Aligned active account email with the mode chip in the Task List AppBar.
- Added an AppBar action variant that reveals the account when space is limited.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep identity visible in AppBar when possible and discoverable via chip tap otherwise.

### 🎯 Next steps:

- Quick visual QA on narrow mobile widths.

# 🔹 Block 120 — Task List AppBar identity grouping — 25/01/2026

### ✔ Work completed:

- Grouped account email and logout icon in the AppBar next to the mode chip.
- Kept the “Your tasks” line free of account/session icons.
- Added overflow-safe truncation to keep the logout icon visible on narrow screens.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Surface the active account in the mode switch dialog when email is hidden.

### 🎯 Next steps:

- QA Task List header on small screens with long emails.

# 🔹 Block 121 — Task List AppBar right alignment fix — 25/01/2026

### ✔ Work completed:

- Forced the Task List AppBar title to take full width so account identity aligns to the right edge.
- Prevented the email/logout group from drifting toward the center on wide screens.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep AppBar content left-aligned and span full width for predictable alignment.

### 🎯 Next steps:

- Re-check alignment on desktop and web with very wide windows.

# 🔹 Block 122 — Task List AppBar actions alignment — 25/01/2026

### ✔ Work completed:

- Moved account email + logout into AppBar actions to lock them to the right edge.
- Kept the mode chip on the left and “Your tasks” line clean.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Prefer AppBar actions for reliable right alignment on wide screens.

### 🎯 Next steps:

- Re-validate on macOS and web with wide windows.

# 🔹 Block 123 — Account email always visible (truncate only) — 25/01/2026

### ✔ Work completed:

- Kept the account email visible in the AppBar actions across screen sizes.
- Added responsive max widths so long emails truncate without hiding the logout icon.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Always show identity when signed in; rely on truncation rather than hiding.

### 🎯 Next steps:

- Visual QA on the narrowest widths to confirm truncation looks clean.

# 🔹 Block 124 — Task List AppBar top alignment — 25/01/2026

### ✔ Work completed:

- Anchored the account email + logout actions to the top-right of the AppBar.
- Matched the vertical placement with the mode chip row for a cleaner header.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Keep identity controls grouped at the AppBar’s top edge across platforms.

### 🎯 Next steps:

- Verify the header alignment on macOS, web, and mobile.

# 🔹 Block 125 — Phase 10 reopen: unique names + apply settings — 25/01/2026

### ✔ Work completed:

- Added unique task name validation (trim + case-insensitive) to block Save/Apply on duplicates.
- Implemented “Apply settings to remaining tasks” button (only when editing and there are tasks after the current one).
- Apply settings copies: pomodoro duration, short/long breaks, total pomodoros, long break interval, and sound selections.
- Propagates local custom sound overrides to remaining tasks; clears overrides when built-in sounds are selected.
- Applies changes in list order and shows a result snackbar with the number of tasks updated.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Apply settings uses the current editor state and respects break validation rules + warnings.

### 🎯 Next steps:

- Validate Apply settings UX on desktop and mobile.

# 🔹 Block 126 — Phase 10 validation (Android/iOS/Web/macOS) — 25/01/2026

### ✔ Work completed:

- Validated Phase 10 changes on Android, iOS, Web (Chrome), and macOS: duplicate name blocking + apply settings copy.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Remaining platforms (Windows/Linux) to be validated later.

### 🎯 Next steps:

- Run Phase 10 checks on remaining platforms when available.

# 🔹 Block 127 — Auth mode chip exit to Local — 25/01/2026

### ✔ Work completed:

- Made the mode chip on the Authentication screen return to Local tasks when no account session exists.
- Kept the chip behavior unchanged when a session is active.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Use an explicit route change to `/tasks` instead of `Navigator.pop()`.

### 🎯 Next steps:

- QA the Auth exit path on mobile and desktop form factors.

# 🔹 Block 128 — Phase 13 reopen: auto-open active session — 25/01/2026

### ✔ Work completed:

- Auto-opened the running/paused task group when an active session is detected on launch/login.
- Cleared stale active sessions that reference missing or non-running groups.

### ⚠️ Issues found:

- None.

### 🧠 Decisions made:

- Route directly to the Timer screen from the Task List when a valid active session is present.

### 🎯 Next steps:

- QA the auto-open path on desktop and mobile (account mode).

# 🔹 Block 129 — Global auto-open listener (macOS editor fix) — 25/01/2026

### ✔ Work completed:

- Moved active-session auto-open logic to a root-level listener so it triggers from any screen.
- Added debug logging and dedupe guards to prevent timer re-entry loops.

### ⚠️ Issues found:

- macOS did not auto-open when the user was in Task Editor because the listener was scoped to Task List.

### 🧠 Decisions made:

- Use a global auto-opener widget wrapping the app content to avoid per-screen listeners.

### 🎯 Next steps:

- Validate auto-open from Task Editor on macOS and confirm behavior on other platforms.

# 🔹 Block 130 — macOS auto-open verification + retry guard — 25/01/2026

### ✔ Work completed:

- Verified auto-open works on macOS when launching with `flutter run` (Account Mode, remote active session).
- Added a safe retry when the navigator context is not yet ready, preventing missed auto-open in Task Editor.
- Confirmed auto-open now triggers from Task Editor and Task List without regressions.

### ⚠️ Issues found:

- Auto-open could fail in macOS release builds when the navigator context was not ready in the editor flow.
- Mixed build modes (owner on `flutter run`, macOS on release build) can still show inconsistent auto-open; matching build types (debug/debug or release/release) behaves consistently.

### 🧠 Decisions made:

- Keep a short, capped retry to wait for navigator readiness instead of adding more per-screen listeners.

### 🎯 Next steps:

- Verify the same behavior on a macOS release build when possible.

# 🔹 Block 131 — macOS debug vs profile/release behavior — 26/01/2026

### ✔ Work completed:

- Verified macOS profile build runs correctly without the freeze seen in debug.
- Documented that the freeze only reproduces in macOS debug (`flutter run`) when a remote session is active.

### ⚠️ Issues found:

- macOS debug (flutter run) can freeze with a remote session; release/profile builds do not.

### 🎯 Next steps:

- Monitor the debug-only freeze; no release impact observed.

# 🔹 Block 132 — Android release build split config fix — 26/01/2026

### ✔ Work completed:

- Scoped ABI split configuration to `--split-per-abi` builds to avoid release build conflicts.

### ⚠️ Issues found:

- `flutter build apk --release` failed when ABI splits were always enabled alongside ABI filters.

### 🎯 Next steps:

- Verify `flutter build apk --release` and `flutter build apk --split-per-abi` both succeed.

# 🔹 Block 133 — Scheduled auto-start implementation (Phase 17 reopen) — 26/01/2026

### ✔ Work completed:

- Added a global scheduled-group auto-starter to promote due groups to running and open TimerScreen.
- Added a scheduled auto-start handshake so TimerScreen starts the session when a scheduled group kicks in.
- Added catch-up checks on app resume to trigger missed scheduled starts.

### ⚠️ Issues found:

- `flutter analyze` failed locally due to Flutter cache permission errors; needs rerun.

### 🎯 Next steps:

- Validate scheduled auto-start on desktop/mobile (debug/profile/release).

# 🔹 Block 134 — Scheduled auto-start ownership fix — 26/01/2026

### ✔ Work completed:

- Added `scheduledByDeviceId` to TaskRunGroup and persisted it in storage.
- Scheduled auto-start now allows any device to claim immediately at scheduled time.
- Recorded the scheduling device when creating scheduled groups.

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Re-test scheduled auto-start ownership on two devices with the same account.

# 🔹 Block 135 — Scheduled auto-start validation (release) — 26/01/2026

### ✔ Work completed:

- Validated scheduled auto-start in release on macOS and Android.
- Scheduling device: Android (app closed). Claim device: macOS (app open, signed in).
- macOS became owner immediately with Pause/Cancel enabled.
- Android opened later in mirror mode with controls disabled until take over.

### ⚠️ Issues found:

- None.

# 🔹 Block 136 — Pre-alert + Pre-Run Countdown Mode — 26/01/2026

### ✔ Work completed:

- Added Pre-Run Countdown Mode behavior to specs (scheduled -> preparing -> running).
- Implemented pre-alert notifications with de-duplication across devices.
- Auto-opened Run Mode during the pre-alert window when the app is open.
- Added Pre-Run UI (amber circle, countdown, preparing/next boxes, contextual list).
- Disabled pause and start controls during pre-run; kept cancel available.
- Added subtle pulse in the last 60 seconds of pre-run countdown.

### ⚠️ Issues found:

- None.

# 🔹 Block 137 — Pre-Run visual refinements — 26/01/2026

### ✔ Work completed:

- Strengthened the Pre-Run ring pulse for the last 60 seconds (visible breathing stroke).
- Synced pulse cadence to ~1Hz to match the per-second color rhythm.
- Updated the last-10-seconds countdown scale to complete quickly and hold at full size.

### ⚠️ Issues found:

- None.

# 🔹 Block 138 — Debug-only macOS freeze (multi-run) — 27/01/2026

### ✔ Work completed:

- Confirmed the Pre-Run idempotent auto-start fix resolves the UI flicker.
- Removed temporary debug traces after verification.

### ⚠️ Issues found:

- macOS debug can freeze when multiple `flutter run` sessions are active (e.g., macOS + Android). UI only repaints after window resize.
- Not reproducible in release/profile; treated as Flutter desktop debug/tooling limitation.

### 🎯 Next steps:

- None (monitor only).

# 🔹 Block 139 — macOS debug frame ping (local) — 27/01/2026

### ✔ Work completed:

- Added a debug-only frame ping on macOS to force scheduled frames once per second.
- Intended to mitigate intermittent UI freeze in debug desktop runs.

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Validate in macOS debug with no other devices running.

# 🔹 Block 140 — Enforce take over on missing session — 27/01/2026

### ✔ Work completed:

- Require an active session before auto-starting a running group.
- Prevent silent ownership changes when a running group lacks `activeSession`.

### ⚠️ Issues found:

- None.

# 🔹 Block 141 — Pre-Run notification remaining time fix — 28/01/2026

### ✔ Work completed:

- Updated Pre-Run notification text to use the real remaining time to start.
- Preserved minute-only wording when the remaining time is an exact minute.
- Added seconds formatting for late pre-alerts inside the notice window.

### ⚠️ Issues found:

- Pre-Run notification body showed the static noticeMinutes value instead of actual remaining time.

# 🔹 Block 142 — English-only code comments + AGENTS clarification — 28/01/2026

### ✔ Work completed:

- Translated remaining Spanish code comments to English in TimerScreen and Router.
- Clarified AGENTS rules for app-level orchestration access to repositories.
- Updated AGENTS authority wording for Account vs Local Mode sessions.

### ⚠️ Issues found:

- None.

# 🔹 Block 143 — AGENTS main-branch safeguard — 28/01/2026

### ✔ Work completed:

- Added an explicit rule: never work directly on `main`; always branch first.

### ⚠️ Issues found:

- None.

# 🔹 Block 144 — Scheduled group coordinator refactor — 28/01/2026

### ✔ Work completed:

- Moved scheduled-group auto-start orchestration into a dedicated ViewModel coordinator.
- Reduced ScheduledGroupAutoStarter to a navigation-only host.
- Updated specs architecture tree to include the coordinator file.

### ⚠️ Issues found:

- None.

# 🔹 Block 145 — Native pre-alert scheduling (best-effort) — 28/01/2026

### ✔ Work completed:

- Added native scheduling for pre-alert notifications on Android/iOS/macOS.
- Kept Windows/Linux/Web as best-effort (in-app) only.
- Added timezone dependency for UTC-based scheduled notifications.
- Added Android exact alarm permission + exact schedule mode request.
- Fallback to inexact scheduling when exact alarms are not granted on Android.

### ⚠️ Issues found:

- None.

# 🔹 Block 146 — Schedule pre-alert at planning time — 28/01/2026

### ✔ Work completed:

- Schedule pre-alert notifications immediately after saving a scheduled group.
- Suppress in-app pre-alert notifications when the app is open and mark noticeSentAt instead.

### ⚠️ Issues found:

- None.

# 🔹 Block 147 — Android scheduling without POST_NOTIFICATIONS gating — 28/01/2026

### ✔ Work completed:

- Allow Android pre-alert scheduling even when notification permission is not yet granted.

### ⚠️ Issues found:

- None.

# 🔹 Block 148 — Pre-run auto-start listener fix — 28/01/2026

### ✔ Work completed:

- Listen for scheduled auto-start id changes while TimerScreen is open.
- Ensure pre-run transitions to running without requiring a reopen.

### ⚠️ Issues found:

- None.

# 🔹 Block 149 — Android AlarmManager pre-alert scheduling — 28/01/2026

### ✔ Work completed:

- Added Android AlarmManager scheduling for pre-alert notifications.
- Added background callback to display notifications when the app is closed.
- Initialized AlarmManager on Android startup and added boot permission.

### ⚠️ Issues found:

- None.

# 🔹 Block 150 — Alarm callback + async context fixes — 28/01/2026

### ✔ Work completed:

- Removed invalid DartPluginRegistrant call in the Android alarm callback.
- Added a mounted check after pre-alert scheduling to satisfy analyzer guidance.

### ⚠️ Issues found:

- None.

# 🔹 Block 151 — Android AlarmManager manifest wiring — 28/01/2026

### ✔ Work completed:

- Added AlarmManager service and receivers to Android manifest.
- Wired BOOT_COMPLETED receiver for rescheduling.

### ⚠️ Issues found:

- None.

# 🔹 Block 152 — Android pre-alert timing observation — 28/01/2026

### ✔ Work completed:

- Verified pre-alert notification fires on Android emulator and physical device.

### ⚠️ Issues found:

- Alarm delivery can be delayed by tens of seconds on Android (device-dependent).

# 🔹 Block 153 — Reopened phases recorded — 28/01/2026

### ✔ Work completed:

- Reopened Phase 10.4 (Presets + weight UI + integrity warnings).
- Reopened Phase 6.7 (GitHub Sign-In, optional).

### ⚠️ Issues found:

- None.

# 🔹 Block 154 — GitHub Sign-In (Phase 6.7) implementation — 28/01/2026

### ✔ Work completed:

- Added GitHub sign-in support via FirebaseAuth (web popup, Android/iOS provider).
- Hid GitHub button on unsupported platforms (macOS/Windows/Linux).

### ⚠️ Issues found:

- None.

# 🔹 Block 155 — Desktop GitHub OAuth docs (Phase 6.7b) — 28/01/2026

### ✔ Work completed:

- Documented manual GitHub OAuth flow for macOS/Windows with backend code exchange.
- Added roadmap reopened subphase 6.7b for desktop GitHub OAuth.

### ⚠️ Issues found:

- None.

# 🔹 Block 156 — GitHub OAuth deep link guard — 28/01/2026

### ✔ Work completed:

- Added a GoRouter redirect guard for Firebase Auth deep links on iOS.

### ⚠️ Issues found:

- None.

# 🔹 Block 157 — iOS bundle ID alignment — 28/01/2026

### ✔ Work completed:

- Updated iOS bundle identifier to match Firebase GoogleService-Info.plist.

### ⚠️ Issues found:

- None.

# 🔹 Block 158 — GitHub account linking flow — 29/01/2026

### ✔ Work completed:

- Added provider-conflict handling for GitHub sign-in.
- Implemented linking flow for Google and email/password accounts.

### ⚠️ Issues found:

- None.

# 🔹 Block 159 — GitHub linking fallback without pending credential — 29/01/2026

### ✔ Work completed:

- Added linkWithProvider flow for GitHub when pending credential is unavailable.
- Added guard for empty sign-in methods and clearer guidance.

### ⚠️ Issues found:

- None.

# 🔹 Block 160 — Linking provider chooser — 29/01/2026

### ✔ Work completed:

- Added explicit provider selection when sign-in methods are unavailable.
- Added email entry prompt for linking when the email is not provided.

### ⚠️ Issues found:

- None.

# 🔹 Block 161 — Remove deprecated email method lookup — 29/01/2026

### ✔ Work completed:

- Removed fetchSignInMethodsForEmail usage to avoid deprecated API and email enumeration risk.
- Linking flow now relies on explicit user choice of original provider.

### ⚠️ Issues found:

- None.

# 🔹 Block 162 — Desktop GitHub OAuth (loopback + Cloud Functions) spec update — 29/01/2026

### ✔ Work completed:

- Specified desktop loopback redirect for GitHub OAuth.
- Selected Firebase Cloud Functions as the backend exchange service.

### ⚠️ Issues found:

- None.

# 🔹 Block 163 — GitHub OAuth backend + desktop loopback flow — 29/01/2026

### ✔ Work completed:

- Added Firebase Cloud Function to exchange GitHub OAuth code for access token.
- Added desktop loopback OAuth flow for macOS/Windows.
- Added GitHub OAuth config via dart-define for desktop client id and exchange endpoint.

### ⚠️ Issues found:

- None.

# 🔹 Block 164 — Desktop loopback fixed port + dedicated OAuth app — 29/01/2026

### ✔ Work completed:

- Fixed the desktop loopback port to 51289 to match a GitHub OAuth callback.
- Documented need for a dedicated GitHub OAuth app for desktop.

### ⚠️ Issues found:

- None.

# 🔹 Block 165 — Desktop GitHub OAuth setup notes — 29/01/2026

### ✔ Work completed:

- Documented desktop GitHub OAuth runtime flags and function config in README.

### ⚠️ Issues found:

- None.

# 🔹 Block 166 — Update Functions runtime to Node 20 — 29/01/2026

### ✔ Work completed:

- Updated Firebase Functions runtime to Node.js 20.

### ⚠️ Issues found:

- None.

# 🔹 Block 167 — Functions config deprecation reminder — 29/01/2026

### ✔ Work completed:

- Recorded March 2026 deprecation of `functions.config()` and need to migrate to `.env`.

### ⚠️ Issues found:

- None.

# 🔹 Block 168 — Desktop run scripts — 29/01/2026

### ✔ Work completed:

- Added macOS and Windows run scripts for GitHub desktop OAuth.
- Clarified `.env.local` usage per machine in README.

### ⚠️ Issues found:

- None.

# 🔹 Block 169 — Switch desktop GitHub OAuth to device flow — 29/01/2026

### ✔ Work completed:

- Replaced loopback + Cloud Functions plan with GitHub Device Flow.
- Removed backend requirement from desktop GitHub OAuth.

### ⚠️ Issues found:

- None.

# 🔹 Block 170 — Remove desktop backend artifacts — 29/01/2026

### ✔ Work completed:

- Removed Cloud Functions backend files and deployment notes.
- Simplified desktop run scripts to require only GitHub client id.

### ⚠️ Issues found:

- None.

# 🔹 Block 171 — Desktop linking guidance for Google-only accounts — 29/01/2026

### ✔ Work completed:

- Added desktop guidance when Google linking is required but unsupported on macOS/Windows.

### ⚠️ Issues found:

- None.

# 🔹 Block 172 — Clarified desktop linking instructions — 29/01/2026

### ✔ Work completed:

- Expanded the Google linking dialog with explicit step-by-step instructions.

### ⚠️ Issues found:

- None.

# 🔹 Block 173 — Desktop GitHub device flow validation — 29/01/2026

### ✔ Work completed:

- Confirmed GitHub Device Flow works on macOS and Windows.

### ⚠️ Issues found:

- None.

# 🔹 Block 174 — Local Mode running resume projection — 29/01/2026

### ✔ Work completed:

- Documented Local Mode resume projection from actualStartTime (no pause reconstruction).
- Hydrated running group state on launch when no session exists to prevent timer resets.

### ⚠️ Issues found:

- None.

# 🔹 Block 175 — Local Mode pause warning — 29/01/2026

### ✔ Work completed:

- Added an explicit pause warning on the Execution screen for Local Mode.
- Documented the Local Mode pause warning behavior in specs.

### ⚠️ Issues found:

- None.

# 🔹 Block 176 — Local Mode pause warning UX refinement — 29/01/2026

### ✔ Work completed:

- Updated specs to require a contextual pause info dialog and discreet info affordance (no layout shift).
- Replaced the persistent pause banner with a lightweight dialog + on-demand info entry point.

### ⚠️ Issues found:

- None.

# 🔹 Block 177 — Android Gradle toolchain bump — 29/01/2026

### ✔ Work completed:

- Updated Android Gradle Plugin to 8.9.1 to satisfy androidx AAR metadata requirements.
- Bumped Gradle wrapper to 8.12.1.

### ⚠️ Issues found:

- None.

# 🔹 Block 178 — Web notification policy clarification — 31/01/2026

### ✔ Work completed:

- Clarified web notification behavior and silent best-effort policy in specs.
- Aligned pre-alert notification rules with background scheduling limits (Android/iOS/macOS only) and open-app suppression.

### ⚠️ Issues found:

- None.

# 🔹 Block 179 — Task Editor validation rules clarified — 31/01/2026

### ✔ Work completed:

- Documented Task Editor unique-name normalization (trim + case-insensitive) and whitespace-only invalid names in specs.

### ⚠️ Issues found:

- None.

# 🔹 Block 180 — Phase 18 status + Run Mode visual spec sync — 31/01/2026

### ✔ Work completed:

- Marked Phase 18 as in progress in the roadmap.
- Synced Run Mode visuals in specs with Block 63 achievements (group-only Run Mode, header indicator placeholder, completion summary totals).

### ⚠️ Issues found:

- None.

# 🔹 Block 181 — Scheduled auto-start conditions clarified — 31/01/2026

### ✔ Work completed:

- Documented that scheduled auto-start requires at least one active/open device for the account.
- Clarified that if all devices are closed, the group starts on the next launch/resume by any signed-in device.

### ⚠️ Issues found:

- None.

# 🔹 Block 182 — Phase 6.7 roadmap updated for Device Flow — 31/01/2026

### ✔ Work completed:

- Updated Phase 6.7 in the roadmap to reflect the implemented GitHub Device Flow and completion date.

### ⚠️ Issues found:

- None.

# 🔹 Block 183 — Phase 17 Windows/Linux validation — 31/01/2026

### ✔ Work completed:

- Validated scheduled planning flow, conflict handling, auto-start, and catch-up on Windows/Linux.
- Marked Phase 17 as completed in the roadmap and removed it from reopened phases.

### ⚠️ Issues found:

- None.

# 🔹 Block 184 — Phase 10.4 implementation (presets + weight + integrity) — 31/01/2026

### ✔ Work completed:

- Implemented Pomodoro presets (model, local + Firestore storage, default handling).
- Added Settings → Manage Presets UI (list, edit, delete, default, bulk delete).
- Added Task Editor preset selector + save-as-new preset; apply settings now propagates presetId.
- Implemented task weight (%) UI with editable percentage and round-half-up conversion.
- Added Pomodoro integrity warning on confirm with “Ajustar grupo” shared-structure snapshot.

### ⚠️ Issues found:

- None.

# 🔹 Block 185 — Specs update for “Ajustar grupo” preset fallback — 31/01/2026

### ✔ Work completed:

- Updated specs to propagate presetId in TaskRunGroup snapshots when “Ajustar grupo” is used.
- Added Default Preset fallback rule for Pomodoro integrity unification.
- Reopened Phase 10.4 tasks in the roadmap to capture the new behavior.

### ⚠️ Issues found:

- None.

# 🔹 Block 186 — Adjust “Ajustar grupo” resolution rules — 31/01/2026

### ✔ Work completed:

- Clarified “Ajustar grupo” resolution rules (master task structure, presetId propagation, Default Preset fallback).
- Updated Phase 10.4 exit condition wording to reflect the integrity resolution mechanism.

### ⚠️ Issues found:

- None.

# 🔹 Block 187 — Implement “Ajustar grupo” preset fallback — 31/01/2026

### ✔ Work completed:

- Added presetId to TaskRunItem snapshots for traceability.
- “Ajustar grupo” now propagates presetId and applies Default Preset fallback when needed.
- Closed the Phase 10.4 reopen item in the roadmap.

### ⚠️ Issues found:

- None.

# 🔹 Block 188 — Integrity warning adds “Usar Predeterminado” — 31/01/2026

### ✔ Work completed:

- Updated specs to include three Integrity Warning actions, including “Usar Predeterminado”.
- Added dialog action to apply the Default Preset directly.
- Ensured invalid master structure falls back to Default Preset automatically.

### ⚠️ Issues found:

- None.

# 🔹 Block 189 — Default preset option gated by availability — 31/01/2026

### ✔ Work completed:

- Hid “Usar Predeterminado” when no Default Preset exists.
- Added dialog failsafe: if Default Preset is missing at tap time, show a SnackBar and keep the dialog open.
- Updated specs to document conditional visibility and fallback behavior.

### ⚠️ Issues found:

- None.

# 🔹 Block 190 — Preset save errors + Settings visibility fixes — 31/01/2026

### ✔ Work completed:

- Added Firestore rules for `users/{uid}/pomodoroPresets` to unblock Account Mode preset CRUD.
- Exposed Settings gear in Local Mode to keep Settings accessible across modes.
- Added explicit error feedback for preset save failures (sync disabled, permission errors).

### ⚠️ Issues found:

- None.

# 🔹 Block 191 — Built-in default preset decision — 31/01/2026

### ✔ Work completed:

- Defined built-in default preset (Classic Pomodoro) and invariant that at least one preset always exists.
- Added seeding rules for Local Mode, Account Mode, and Account Mode with sync disabled.
- Documented account-local preset cache and one-time auto-push on sync enable.

### ⚠️ Issues found:

- None.

# 🔹 Block 192 — Implement Classic Pomodoro default seeding — 31/01/2026

### ✔ Work completed:

- Implemented Classic Pomodoro built-in default preset seeding across Local, Account, and sync-disabled scopes.
- Enforced “at least one preset” invariant on delete and ensured a default always exists.
- Added account-local preset cache for sync-disabled Account Mode and auto-push to Firestore on sync enable.
- New tasks now default to the preset instead of implicit custom values.

### ⚠️ Issues found:

- None.

# 🔹 Block 193 — Task weight redistribution (work time) — 31/01/2026

### ✔ Work completed:

- Documented task weight (%) based on work time with proportional redistribution of other tasks.
- Added rule to hide % badges when no tasks are selected.
- Reopened Phase 10.4 to track the fix.

### ⚠️ Issues found:

- None.

# 🔹 Block 194 — Task weight redistribution implemented — 31/01/2026

### ✔ Work completed:

- Implemented work-time-based weight redistribution when editing task %.
- Preserved relative proportions of non-edited tasks and kept integer pomodoros.
- Hid task weight % badges when no selection exists.

### ⚠️ Issues found:

- None.

# 🔹 Block 195 — Task weight preserves total work time — 31/01/2026

### ✔ Work completed:

- Adjusted redistribution to keep total work time constant after % edits.
- Diff correction now targets total work time, not remaining work.

### ⚠️ Issues found:

- None.

# 🔹 Block 196 — Task weight uses baseline work time — 31/01/2026

### ✔ Work completed:

- Redistribution now uses baseline task list work time (pre-edit) to avoid shrinking totals while typing.
- Edited task is no longer merged into the baseline for total work calculations.

### ⚠️ Issues found:

- None.

# 🔹 Block 197 — Preset integrity + delete crash fix — 01/02/2026

### ✔ Work completed:

- Documented preset name uniqueness per scope and auto-correction rules.
- Normalized presets to enforce a single default and unique names (local + Firestore).
- Added unique-name validation on preset save (explicit error on duplicates).
- Deferred preset list state updates and delete actions to avoid build-time provider mutations.

### ⚠️ Issues found:

- None.

# 🔹 Block 198 — Preset editor init fix — 01/02/2026

### ✔ Work completed:

- Deferred preset editor initialization to post-frame to avoid build-time provider mutations.
- Always create a fresh preset on the new-preset route to avoid overwriting existing presets.

### ⚠️ Issues found:

- None.

# 🔹 Block 199 — Task Editor focus + validation refresh — 01/02/2026

### ✔ Work completed:

- Added a stable key to Pomodoro duration field to keep focus when preset detaches.
- Revalidated break fields after preset selection to clear stale error states.

### ⚠️ Issues found:

- None.

# 🔹 Block 200 — Task Editor syncs preset edits — 01/02/2026

### ✔ Work completed:

- Synced Task Editor state to updated preset values after preset edits.
- Prevented stale preset values from overwriting propagated task updates.

### ⚠️ Issues found:

- None.

# 🔹 Block 201 — Preset edit feedback — 01/02/2026

### ✔ Work completed:

- Documented that preset edits propagate to tasks and can affect derived metrics.
- Added a lightweight confirmation message when preset saves update tasks.

### ⚠️ Issues found:

- None.

# 🔹 Block 202 — Task weight precision notice — 01/02/2026

### ✔ Work completed:

- Documented precision limits for task weight redistribution.
- Added a lightweight notice when requested % cannot be matched closely or no change is possible.

### ⚠️ Issues found:

- None.

# 🔹 Block 203 — Task list AppBar title overflow fix — 01/02/2026

### ✔ Work completed:

- Reserved title space in the Task List AppBar to keep “Your tasks” fully visible.
- Dynamically constrained account label width to prevent right-side overflow.

### ⚠️ Issues found:

- None.

# 🔹 Block 204 — Preset auth reset cache refresh — 01/02/2026

### ✔ Work completed:

- Invalidated preset/task providers on account login/logout to prevent stale preset access after auth changes.
- Ensured preset list refreshes cleanly after password reset flows.

### ⚠️ Issues found:

- None.

# 🔹 Block 205 — Finish sound edit consistency — 01/02/2026

### ✔ Work completed:

- Updated specs to allow task-level finish sound selection (aligns with presets).
- Added Task Editor finish sound selector to match preset capabilities.

### ⚠️ Issues found:

- None.

# 🔹 Block 206 — Task Editor section grouping — 01/02/2026

### ✔ Work completed:

- Added section headers to separate Task weight from Pomodoro configuration in Task Editor.
- Documented the visual grouping in specs for clarity.

### ⚠️ Issues found:

- None.

# 🔹 Block 207 — Preset selector overflow fix — 01/02/2026

### ✔ Work completed:

- Made preset selector responsive with ellipsis truncation to avoid horizontal overflow.
- Kept preset action icons visible on narrow screens.

### ⚠️ Issues found:

- None.

# 🔹 Block 208 — Unsaved changes confirmation — 01/02/2026

### ✔ Work completed:

- Added unsaved-changes confirmation dialogs for Task Editor and Preset Editor.
- Restored local sound overrides when discarding edits to avoid leaking changes.

### ⚠️ Issues found:

- None.

# 🔹 Block 209 — Preset duplicate configuration detection — 01/02/2026

### ✔ Work completed:

- Detect duplicate preset configurations on new preset creation (durations, interval, sounds).
- Added a decision dialog to use existing, rename existing, save anyway, or cancel.
- Implemented rename flow without creating additional presets.

### ⚠️ Issues found:

- None.

# 🔹 Block 210 — Preset duplicate detection on edit — 01/02/2026

### ✔ Work completed:

- Extended duplicate-configuration detection to preset edits (warns if another preset matches).
- Adjusted dialog options to avoid duplicates without forcing extra presets.

### ⚠️ Issues found:

- None.

# 🔹 Block 211 — Rename option on edit duplicates — 01/02/2026

### ✔ Work completed:

- Enabled “Rename existing” option when duplicate configurations are detected while editing.

### ⚠️ Issues found:

- None.

# 🔹 Block 212 — Rename dialog prompt fix — 01/02/2026

### ✔ Work completed:

- Rename action now prompts for a new name when editing duplicates, avoiding self-name conflicts.
- Dialog label references the duplicate preset being renamed.

### ⚠️ Issues found:

- None.

# 🔹 Block 213 — Dialog exit stability — 01/02/2026

### ✔ Work completed:

- Added a short delay after duplicate dialogs before exiting to avoid framework assertions.

### ⚠️ Issues found:

- None.

# 🔹 Block 214 — Default preset toggling stability — 01/02/2026

### ✔ Work completed:

- Default preset changes now update the target first to avoid transient no-default states.
- Default toggle is disabled when editing the current default preset (informational only).

### ⚠️ Issues found:

- None.

# 🔹 Block 215 — Duplicate rename exit guard — 01/02/2026

### ✔ Work completed:

- Duplicate rename/use-existing flows no longer auto-exit the editor to avoid Android navigation assertions.
- Save exits only on actual saves; duplicate-resolution actions keep the editor open.

### ⚠️ Issues found:

- None.

# 🔹 Block 216 — Dialog transition guard — 01/02/2026

### ✔ Work completed:

- Added a short transition delay before opening the rename dialog to avoid Android dialog/navigation assertions.

### ⚠️ Issues found:

- None.

# 🔹 Block 217 — Single-dialog rename flow — 01/02/2026

### ✔ Work completed:

- Merged duplicate detection and rename input into a single dialog to avoid nested route assertions on Android.

### ⚠️ Issues found:

- None.

# 🔹 Block 218 — Duplicate dialog overflow fix — 01/02/2026

### ✔ Work completed:

- Made the duplicate dialog scrollable to avoid content overflow on smaller screens.

### ⚠️ Issues found:

- None.

# 🔹 Block 219 — Duplicate rename stability (Android) — 02/02/2026

### ✔ Work completed:

- Rename action now unfocuses input before closing the duplicate dialog.
- Post-dialog processing waits a frame to avoid Android dependency assertions.
- Rename CTA references the existing preset name to avoid label confusion on new presets.

### ⚠️ Issues found:

- None.

# 🔹 Block 220 — Duplicate rename flow hardening — 02/02/2026

### ✔ Work completed:

- Moved rename input into a dedicated full-screen prompt to avoid dialog/TextField teardown issues on Android.
- Duplicate dialog now only selects the action; rename collects the new name on its own route.

### ⚠️ Issues found:

- None.

# 🔹 Block 221 — Exit after duplicate resolution (new preset) — 02/02/2026

### ✔ Work completed:

- After “Use existing” or “Rename existing” during new preset creation, exit to Manage Presets.
- Prevented looping back into the New Preset screen after duplicate resolution.

### ⚠️ Issues found:

- None.

# 🔹 Block 222 — Exit after rename on edit — 02/02/2026

### ✔ Work completed:

- Duplicate rename in edit mode now exits to Manage Presets after completing the rename.
- Avoids returning to the edit screen after resolving the duplicate.

### ⚠️ Issues found:

- None.

# 🔹 Block 223 — Rename exits editor (all cases) — 02/02/2026

### ✔ Work completed:

- Duplicate “Rename existing” now exits to Manage Presets for both new and edit flows.

### ⚠️ Issues found:

- None.

# 🔹 Block 224 — Duplicate rename flow validated — 02/02/2026

### ✔ Work completed:

- Confirmed the duplicate rename flow returns directly to Manage Presets without loops.

### ⚠️ Issues found:

- None.

# 🔹 Block 225 — Docs lock-in clarifications (Phase alignment) — 02/02/2026

### ✔ Work completed:

- Updated specs to lock TimerDisplay visuals (ring + marker, no hand/needle) and clarify color usage.
- Updated roadmap to mark Run Mode time ranges and transitions as implemented/locked and clarify remaining items.
- Aligned Copilot instructions with AGENTS.md, adding workflow + UI lock-ins.
- Clarified reopened-phase rule and noted outstanding items tracked in Phases 18/19/21 (not reopened).

### 🧠 Decisions made:

- TimerDisplay visuals are locked; any changes require explicit approval and belong to Phase 23 polish.
- Outstanding items in specs 10.4.2 / 10.4.6 / 12 / 10.5 map to Phases 18/19/21, not reopened phases.

### 🎯 Next steps:

- Finish Phase 18 group completion flow (modal + final state + navigate to Groups Hub).
- Implement Groups Hub (Phase 19) and final animation (Phase 21).

### ⚠️ Issues found:

- None.

# 🔹 Block 226 — Group completion navigation scaffold (Phase 18)— 02/02/2026

### ✔ Work completed:

- Added a Groups Hub placeholder screen and `/groups` route.
- Completion modal now navigates to Groups Hub after dismiss (no cancel on completion).

### 🎯 Next steps:

- Validate the completion flow end-to-end (modal + final state + Groups Hub landing).

### ⚠️ Issues found:

- None.

# 🔹 Block 227 — Cancel flow spec clarification (Phase 18) — 02/02/2026

### ✔ Work completed:

- Documented cancel-running-group behavior: confirmation required, group marked canceled, session cleared.
- Clarified navigation after cancel (go to Groups Hub; do not remain in Run Mode).
- Added roadmap reminder to implement the cancel flow in Phase 18.

### ⚠️ Issues found:

- None.

# 🔹 Block 228 — Cancel flow implementation (Phase 18) — 02/02/2026

### ✔ Work completed:

- Cancel now requires confirmation and warns that the group cannot be resumed.
- On cancel, the group is marked canceled, session is cleared, and navigation goes to Groups Hub.
- Back/exit flow uses the same cancel behavior (no idle Run Mode state).

### ⚠️ Issues found:

- None.

# 🔹 Block 229 — Phase 19 kickoff — 02/02/2026

### ✔ Work completed:

- Transitioned active work to Phase 19 (Groups Hub screen).

### 🎯 Next steps:

- Implement Groups Hub list + actions + entry points per specs (section 10.5).

### ⚠️ Issues found:

- None.

# 🔹 Block 230 — Phase 19 Groups Hub core UI — 02/02/2026

### ✔ Work completed:

- Implemented Groups Hub screen with sections for running, scheduled, and completed groups.
- Added actions: Open Run Mode, Start now, Cancel schedule, Run again.
- Added Task List entry point from Groups Hub and wired Run Mode header indicator to open Groups Hub.
- Added Task List banner for running/paused group entry point.

### ⚠️ Issues found:

- None.

# 🔹 Block 231 — Task List banner stale-session handling — 02/02/2026

### ✔ Work completed:

- Task List banner now disappears when the group is completed/canceled and clears stale sessions.
- Shows a brief SnackBar to confirm the group ended.

### ⚠️ Issues found:

- None.

# 🔹 Block 232 — Scheduled auto-start recheck after group completion — 02/02/2026

### ✔ Work completed:

- Scheduled auto-start re-evaluates when the active session ends (no active session -> re-run coordinator logic).
- When a running group has no active session, expired running groups are auto-completed to unblock scheduled starts.

### ⚠️ Issues found:

- None.

# 🔹 Block 233 — Running group expiry clears stale Task List banner — 02/02/2026

### ✔ Work completed:

- ScheduledGroupCoordinator now schedules expiry checks for running groups.
- If the active running group has passed its theoretical end and is locally owned (not paused), it is auto-completed and the active session is cleared.
- This removes stale “running” banners when the user remains on Task List.

### ⚠️ Issues found:

- None.

# 🔹 Block 234 — Pre-Run window scheduling validation — 02/02/2026

### ✔ Work completed:

- Scheduling now reserves the full Pre-Run window (noticeMinutes) and blocks invalid times.
- If the Pre-Run window would start in the past or overlaps a running/earlier scheduled group, scheduling is blocked with a clear user message.
- Applied to both Task List planning flow and Groups Hub “Run again”.

### ⚠️ Issues found:

- None.

# 🔹 Block 235 — Pre-Run access entry points — 02/02/2026

### ✔ Work completed:

- Task List now shows a Pre-Run banner when a scheduled group is within the notice window, with “Open Pre-Run”.
- Groups Hub scheduled cards switch to “Open Pre-Run” when the pre-run window is active.
- No AppBar changes; access is provided via existing screen content.

### ⚠️ Issues found:

- None.

# 🔹 Block 236 — Persistent Groups Hub CTA on Task List — 02/02/2026

### ✔ Work completed:

- Task List now exposes a direct “View Groups Hub” CTA even when no group is running or in pre-run.
- Access remains in content area; AppBar stays unchanged.

### ⚠️ Issues found:

- None.

# 🔹 Block 237 — Task List running banner (Local Mode fallback) — 02/02/2026

### ✔ Work completed:

- Task List now shows the running-group banner even when no active session is available (Local Mode).
- Uses latest running TaskRunGroup as fallback so users can always return to Run Mode.

### ⚠️ Issues found:

- None.

# 🔹 Block 238 — Groups Hub notice visibility guard — 02/02/2026

### ✔ Work completed:

- Notice / pre-run info is shown only for scheduled groups (scheduledStartTime != null).
- “Start now” groups no longer display notice fields in Groups Hub cards or summary.

### ⚠️ Issues found:

- None.

# 🔹 Block 239 — Auto-adjust breaks on pomodoro + break edits — 03/02/2026

### ✔ Work completed:

- Task Editor and Edit Preset now auto-adjust short/long breaks when a valid pomodoro change makes them invalid.
- Editing short/long breaks now auto-adjusts the other break to keep short < long and both < pomodoro (when valid).
- Adjustments keep values as close as possible and add an inline note (helper text) explaining the automatic change.
- No auto-adjust when pomodoro duration is invalid.

### ⚠️ Issues found:

- None.

# 🔹 Block 240 — Break auto-adjust deferred to edit completion — 03/02/2026

### ✔ Work completed:

- Break-to-break auto-adjust now applies on focus loss (edit completion) to avoid mid-typing adjustments in Task Editor and Edit Preset.
- Added focus listeners and guards to prevent auto-adjust while typing; inline auto-adjust note remains.

### ⚠️ Issues found:

- None.

# 🔹 Block 241 — Pomodoro Integrity Warning clarity — 03/02/2026

### ✔ Work completed:

- Integrity Warning actions now spell out the exact configuration source (first task name, default preset name, or per-task configs).
- Button labels updated to remove ambiguous wording without changing logic.

### ⚠️ Issues found:

- None.

# 🔹 Block 242 — Integrity Warning visual options list — 03/02/2026

### ✔ Work completed:

- Integrity Warning now shows one selectable visual option per distinct structure (mini task cards + “Used by” chips).
- Default preset option is visual with a star badge; “Keep individual configurations” is a visual card in the same list.
- Option selection applies the chosen structure (or keeps individual configs) without changing execution logic.

### ⚠️ Issues found:

- None.

# 🔹 Block 243 — Integrity Warning iOS layout fix — 03/02/2026

### ✔ Work completed:

- Constrained dialog content width to avoid IntrinsicWidth layout failures on iOS.

### ⚠️ Issues found:

- None.

# 🔹 Block 244 — Cancel navigation fallback — 03/02/2026

### ✔ Work completed:

- Run Mode now auto-exits to Groups Hub when a group becomes canceled (local or remote), preventing idle state after cancel.

### ⚠️ Issues found:

- None.

# 🔹 Block 245 — Integrity Warning copy + default badge placement — 03/02/2026

### ✔ Work completed:

- Added an explicit instruction in the Integrity Warning intro text.
- Default preset option now shows mini-cards first and the star badge below.

### ⚠️ Issues found:

- None.

# 🔹 Block 246 — Integrity Warning interval dots alignment — 03/02/2026

### ✔ Work completed:

- Mini interval dots now align from the bottom to match Task List card styling.

### ⚠️ Issues found:

- None.

# 🔹 Block 247 — Retention preserves completed history — 03/02/2026

### ✔ Work completed:

- Completed groups now retain their own history cap; canceled groups are pruned separately and never evict completed history.

### ⚠️ Issues found:

- None.

# 🔹 Block 248 — Classic Pomodoro uniqueness on account sync — 03/02/2026

### ✔ Work completed:

- Account-local preset push now skips Classic Pomodoro if the account already has it, preventing duplicate defaults across provider linking.

### ⚠️ Issues found:

- None.

# 🔹 Block 249 — Run Mode cancel navigation hardening — 03/02/2026

### ✔ Work completed:

- Added a secondary cancel-navigation guard (on state updates) to ensure Run Mode always exits after cancellation, even in profile timing edge cases.

### ⚠️ Issues found:

- None.

# 🔹 Block 250 — Cancel navigation fallback in build — 03/02/2026

### ✔ Work completed:

- Added a build-time cancel fallback that auto-exits to Groups Hub when the current group is already canceled.

### ⚠️ Issues found:

- None.

# 🔹 Block 251 — Groups Hub summary modal expansion — 03/02/2026

### ✔ Work completed:

- Expanded the Groups Hub summary modal with timing, totals, and a task-level breakdown using compact visual cards.

### ⚠️ Issues found:

- None.

# 🔹 Block 252 — Groups Hub summary hides non-applicable timing rows — 03/02/2026

### ✔ Work completed:

- Scheduled start now appears only for scheduled groups; non-planned runs omit the row to avoid placeholder noise.

### ⚠️ Issues found:

- None.

# 🔹 Block 253 — Groups Hub cards hide non-planned scheduled row — 03/02/2026

### ✔ Work completed:

- Scheduled row is omitted on Groups Hub cards when scheduledStartTime is null.

### ⚠️ Issues found:

- None.

# 🔹 Block 254 — Run Mode navigation reset on group switch — 03/02/2026

### ✔ Work completed:

- TimerScreen now reloads when the groupId changes and resets cancel/auto-start flags; /timer routes use a unique page key to avoid stale state reuse.

### ⚠️ Issues found:

- None.

# 🔹 Block 255 — Run Mode cancel navigation retry — 03/02/2026

### ✔ Work completed:

- Cancel navigation now uses the root navigator when available and retries briefly if the app remains in /timer after cancellation.

### ⚠️ Issues found:

- None.

# 🔹 Block 256 — Cancel now marks group before clearing session — 03/02/2026

### ✔ Work completed:

- Cancel flow now persists the group as canceled before clearing activeSession to prevent auto-open races.

### ⭐ Impact highlight:

- Resolved the long-running multi-platform bug where Run Mode stayed open after canceling a group (including Run again) due to auto-open races. This fix restores reliable post-cancel navigation and sync behavior across devices.

### ⚠️ Issues found:

- None.

# 🔹 Block 257 — Groups Hub CTA moved to top — 03/02/2026

### ✔ Work completed:

- Moved the "Go to Task List" CTA to the top of Groups Hub content for immediate visibility.

### ⚠️ Issues found:

- None.

# 🔹 Block 258 — Phase 19 validation + close — 04/02/2026

### ✔ Work completed:

- Completed multi-platform validation for Phase 19 (Groups Hub + navigation entry points).
- Confirmed Run Mode cancel/finish returns to Groups Hub and Groups Hub shows expected sections/actions.
- Phase 19 marked complete in roadmap.

### ⚠️ Issues found:

- None.

# 🔹 Block 259 — Specs + roadmap enhancements (04/02/2026)

### ✔ Work completed:

- Updated specs for group naming rules and TaskRunGroup `name`.
- Documented task color palette, auto-assignment, and usage across UI.
- Added Task List summary header and per-task total time display rules.
- Added Task Editor total time chip and color picker requirements.
- Documented Run Mode group progress bar behavior (pause-aware).
- Updated planning flow: Start now vs Schedule cards, total range/time scheduling with proportional redistribution.
- Documented global sound settings (apply switch + revert behavior).
- Clarified Mode A/B break sequencing (global long-break counter) and added integrityMode to TaskRunGroup specs.
- Task List time row corrected: time range only for selected tasks; unselected shows total time only.
- Scheduling by total range/time: if the planned end is earlier than requested, show a lightweight notice with “Don’t show again”.
- Updated roadmap with new phases and reopened phase list.

### 🧠 Decisions made:

- Default group names use English date/time format (e.g., "Jan 1 00:00", 24h).
- Duplicate group names auto-append a short date/time suffix.
- Scheduling redistribution reuses task weight algorithm (roundHalfUp, min 1 pomodoro).

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Implement Phase 20 items in code after review.

# 🔹 Block 260 — Mode A global breaks (04/02/2026)

### ✔ Work completed:

- Added `integrityMode` to TaskRunGroup with serialization and default handling.
- Implemented Mode A global long-break sequencing (PomodoroMachine offset + ViewModel timeline math).
- Added mode-aware group/task duration utilities and updated scheduling/end-time calculations.
- Updated Task List selected preview and TimerScreen planned ranges to respect integrity mode.

### ⚠️ Issues found:

Mode A global long-break sequencing not fully validated (time constraints).

### 🎯 Next steps:

- Validate multi-task runs with shared structure (global long-breaks) across devices.
- Other changes in this block were verified locally.

# 🔹 Block 261 — Run Mode task transition catch-up (05/02/2026)

### ✔ Work completed:

- Added owner-side group timeline projection on resume/hydrate to advance across tasks after background time.
- Reused the group timeline projection helper outside Local Mode when safe.
- Ensured corrected state publishes back to the active session after projection.

### ⚠️ Issues found:

- Task transitions could stall at `finished` after app suspension, leaving the next task unstarted.

### 🎯 Next steps:

- Validate task-to-task auto-advance after background/resume on Android/iOS/Web.

# 🔹 Block 262 — Completion modal on owner/mirror + fallback nav (05/02/2026)

### ✔ Work completed:

- Ensured completion modal is triggered for both owner and mirror when group finishes.
- Added pending modal handling on resume and fallback navigation to Groups Hub if the modal cannot be shown.
- Synced ViewModel group completion flag with repo updates for mirror devices.

### ⚠️ Issues found:

- Completion modal/navigation could fail to show on mirror devices in foreground.

### 🎯 Next steps:

- Validate completion modal + Groups Hub navigation on owner and mirror devices.

# 🔹 Block 263 — Mirror completion modal without owner (05/02/2026)

### ✔ Work completed:

- Showed completion modal on mirror when the last task finishes, even if the owner is offline.
- Guarded against false positives on non-last tasks.

### ⚠️ Issues found:

- Mirror devices could stay on the green finished timer until the owner reconnected.

### 🎯 Next steps:

- Validate single-task completion on mirror with owner closed (modal + Groups Hub).

# 🔹 Block 264 — ActiveSession ownership + cleanup (06/02/2026)

### ✔ Work completed:

- Documented activeSession cleanup rules in specs (terminal states + stale sessions).
- Added owner-side activeSession clearing on group completion.
- Added stale activeSession cleanup when groups are not running (global + load guard).

### ⚠️ Issues found:

- Stale activeSession could block ownership for new executions and persist after completion.

### 🎯 Next steps:

- Validate Run again/Start now ownership transfer across macOS/Android.
- Confirm activeSession clears on completion/cancel and Groups Hub no longer shows a running card.

# 🔹 Block 265 — Stale session completion (06/02/2026)

### ✔ Work completed:

- Allowed auto-completion when an activeSession is stale and the group has passed theoreticalEndTime.
- Cleared stale activeSession for expired running groups (including remote owner cases).
- Added load-time sanitization for expired + stale sessions.

### 🧠 Decisions made:

- Permit non-owner cleanup only when the session is stale and the group has clearly expired, to preserve single-writer rules while eliminating zombie runs.
- Treat activeSession as strictly ephemeral; clearing it on expired groups is required to keep Groups Hub consistent across devices.

### ⚠️ Issues found:

- Remote-owned sessions could block auto-complete even after the group end time passed.

### 🎯 Next steps:

- Validate owner-offline completion across macOS/Android with Groups Hub consistency.

# 🔹 Block 266 — Run Mode ownership visibility (06/02/2026)

### ✔ Work completed:

- Documented Run Mode ownership indicator, info sheet, and one-time education message in specs.
- Added owner/mirror indicator in TimerScreen with on-demand ownership details.
- Added explicit “Take ownership” action (no confirmation) for mirror devices.
- Showed a one-time owner education SnackBar on first owner start per device.

### ⚠️ Issues found:

- None observed during implementation (validation pending).

### 🎯 Next steps:

- Validate ownership indicator + take ownership on Android/macOS.
- Confirm the education banner shows once per device and never in Local Mode.

# 🔹 Block 267 — Mirror realignment on ownership change (06/02/2026)

### ✔ Work completed:

- Stopped local execution state when a device becomes mirror after ownership changes.
- Ensured mirror devices re-anchor to activeSession on owner change so pause/resume syncs globally.
- Documented the ownership-change realignment rule in specs.

### ⚠️ Issues found:

- None observed during implementation (validation pending).

### 🎯 Next steps:

- Reproduce the original multi-owner pause/resume test across Android/Web/iOS.
- Confirm no dual timers or jitter after ownership changes.

# 🔹 Block 268 — Deterministic initial ownership (06/02/2026)

### ✔ Work completed:

- Set `scheduledByDeviceId` for all start-now runs to record the initiating device.
- Updated scheduled auto-start to set `scheduledByDeviceId` when claiming a run.
- Restricted auto-start when activeSession is null to the initiating device (Account Mode).
- Documented the deterministic owner rule in specs and roadmap.

### ⚠️ Issues found:

- Ownership could previously jump because multiple devices auto-started before activeSession existed.

### 🎯 Next steps:

- Re-run the multi-device start scenario with Android/iOS/Web open and confirm ownership stays on the initiator.

# 🔹 Block 269 — Ownership requests + approval (06/02/2026)

### ✔ Work completed:

- Replaced immediate “take ownership” with a request/approval flow.
- Added owner-side request banner with Accept/Reject actions.
- Added mirror-side pending and rejection states, including a rejection indicator.
- Removed the redundant info icon (ownership icon is now the single entry point).
- Documented the ownership request rules in specs and roadmap.

### 🧠 Decisions made:

- Ownership transfer is always explicit: no automatic takeover based on app focus or presence.
- The owner updates ownerDeviceId on approval; mirrors never mutate execution state.

### 🎯 Next steps:

- Validate multi-device request → approve/reject flows on Android/iOS/Web.
- Re-test pause/resume after approval to confirm no timer reset on ex-owner.

# 🔹 Block 270 — Compact ownership controls (06/02/2026)

### ✔ Work completed:

- Shortened the ownership request label on compact widths to prevent control overflow.
- Reduced control padding/font size on narrow screens.
- Removed the inline rejection icon; rejection feedback is now snackbar + info sheet.
- Updated specs with compact-label + rejection feedback rules.

### ⚠️ Issues found:

- None observed (layout regression fix).

### 🎯 Next steps:

- Validate on narrow Android/iOS devices: Request/Pause/Cancel row fits with no overflow.

# 🔹 Block 271 — Ownership request icon (06/02/2026)

### ✔ Work completed:

- Added the owner icon to the Request ownership control for clarity and consistency.
- Kept the compact label + spacing to avoid overflow on narrow screens.
- Documented the button icon guidance in specs.

### 🎯 Next steps:

- Quick visual pass on narrow Android/iOS to confirm no overflow regression.

# 🔹 Block 272 — Ownership rejection snackbar (06/02/2026)

### ✔ Work completed:

- Snackbar now shows the rejection time and waits for explicit “OK” dismissal.
- Updated specs to reflect the persistent snackbar requirement.

### 🎯 Next steps:

- Validate that repeated rejections replace the snackbar cleanly without UI shifts.

# 🔹 Block 273 — Ownership request overlay (07/02/2026)

### ✔ Work completed:

- Moved the ownership request prompt into a floating overlay on TimerScreen.
- Kept the pending-request status as an overlay to avoid reflowing the Run Mode layout.
- Updated specs to require the ownership request banner to be overlayed and non-disruptive.

### 🎯 Next steps:

- Quick visual pass on narrow screens to confirm the overlay does not collide with controls.

# 🔹 Block 274 — Analyzer cleanup (07/02/2026)

### ✔ Work completed:

- Removed unnecessary non-null assertions in `TimerScreen`.
- Deleted the unused `_isStale` helper in `PomodoroViewModel`.

### 🎯 Next steps:

- Re-run `flutter analyze` when Flutter is available.

# 🔹 Block 275 — Pending ownership AppBar indicator (07/02/2026)

### ✔ Work completed:

- Removed the inline pending-ownership text from Run Mode to avoid overlaying task content.
- Added a pending-request state to the AppBar ownership indicator (amber icon).
- Updated specs to require AppBar-only pending status and keep the waiting message in the info sheet.

### 🎯 Next steps:

- Quick visual check on mirror devices to confirm the AppBar indicator reads clearly.

# 🔹 Block 276 — Run Mode control sizing (07/02/2026)

### ✔ Work completed:

- Restored full-size Run Mode control buttons for Pause/Cancel/Request across owner and mirror.
- Removed compact sizing logic to keep button height and typography consistent.
- Standardized the shared Run Mode button style and short ownership labels.
- Updated specs to document the shared full-size control style.

### 🎯 Next steps:

- Quick visual pass on narrow screens to confirm the 2-button and 3-button layouts remain stable.

# 🔹 Block 277 — Mirror initial state sync (07/02/2026)

### ✔ Work completed:

- Primed mirror state from the active session during group load to avoid idle flashes.
- Ensured mirror controls and timer render from the remote session before the first frame.

### 🎯 Next steps:

- Validate on mirror devices by opening Run Mode while a group is already running.

# 🔹 Block 278 — Owner pause restoration (07/02/2026)

### ✔ Work completed:

- Primed owner Run Mode state from the active session on load to avoid idle flashes.
- Adjusted group timeline projection to respect accumulated pause offsets.
- Ensured owner hydration applies session state before any projection.

### 🎯 Next steps:

- Validate owner pause/resume flow when reopening Run Mode from Groups Hub.

# 🔹 Block 279 — Ownership sheet actions copy (07/02/2026)

### ✔ Work completed:

- Removed “Start” from the owner allowed-actions copy in the ownership info sheet.
- Aligned the copy with the rule that ownership applies only after a session is running.

### 🎯 Next steps:

- Quick visual pass to confirm the ownership sheet reads correctly in owner and mirror modes.

# 🔹 Block 280 — Groups Hub AppBar cleanup (07/02/2026)

### ✔ Work completed:

- Removed the duplicate Task List icon action from the Groups Hub AppBar.
- Added the compact mode indicator to the AppBar for global context.

### 🎯 Next steps:

- Quick visual pass to confirm the AppBar layout remains balanced on narrow screens.

# 🔹 Block 281 — DevTools memory profiling guide (07/02/2026)

### ✔ Work completed:

- Added a DevTools memory profiling guide with a repeatable workflow and checklist.
- Documented expected behavior and red flags for memory regression checks.

### 🎯 Next steps:

- Fill the exact Flutter version the next time the checklist is executed.

# 🔹 Block 282 — Memory profiling platforms (07/02/2026)

### ✔ Work completed:

- Added profile-mode launch commands for Windows, Linux, iOS, and Web.

### 🎯 Next steps:

- Confirm the iOS device requirement during the next profiling run.

# 🔹 Block 283 — Chrome profiling port (07/02/2026)

### ✔ Work completed:

- Set the Chrome profiling command to use the standard `--web-port=5001`.

# 🔹 Block 284 — Task List drag boundary (07/02/2026)

### ✔ Work completed:

- Constrained the Task List reorder drag proxy to the list viewport using DragBoundary.
- Preserved handle-only reordering and existing task list behavior.

### 🎯 Next steps:

- Validate drag behavior on Android/iOS/Web to confirm no overdraw above the AppBar.

# 🔹 Block 285 — Task List auto-scroll (07/02/2026)

### ✔ Work completed:

- Added manual auto-scroll during reorder drags to allow long-list reordering.
- Preserved the drag boundary and selection behavior.

### 🎯 Next steps:

- Validate auto-scroll at both edges on Android/iOS/Web.

# 🔹 Block 286 — Task List auto-scroll boundary fix (07/02/2026)

### ✔ Work completed:

- Anchored auto-scroll edge detection to the list viewport size via a keyed listener.

### 🎯 Next steps:

- Re-test long-list reordering to confirm bottom-edge scroll activates.

# 🔹 Block 287 — Groups Hub date-aware times (08/02/2026)

### ✔ Work completed:

- Displayed date + time on Groups Hub cards when the group day is not today.
- Kept time-only formatting for groups occurring today to preserve a clean layout.

### 🎯 Next steps:

- Quick visual pass on groups across different days to confirm formatting clarity.

# 🔹 Block 288 — Ownership rejection snackbar clarity (08/02/2026)

### ✔ Work completed:

- Added a subtle rejection icon/accent to the ownership rejection snackbar.
- Kept the existing dismissal flow and message while improving clarity.

### 🎯 Next steps:

- Confirm the snackbar remains legible on narrow layouts.

# 🔹 Block 289 — Ownership request banner opacity (08/02/2026)

### ✔ Work completed:

- Switched the owner-side ownership request banner to an opaque background.
- Preserved the existing banner layout and actions.

### 🎯 Next steps:

- Quick visual pass to confirm the banner remains readable over active timers.

# 🔹 Block 290 — Planning flow screen (phase 1) (08/02/2026)

### ✔ Work completed:

- Replaced the Task List “Confirm” step with a full-screen planning screen.
- Added a single info modal (with “Don’t show again”) and an info icon for options.
- Implemented Start now + Schedule by start time, with range/total-time options shown as “Coming soon”.
- Added a full preview list matching Task List selected cards, plus group start/end timing.
- Updated the Task List CTA label to “Next”.

### 🎯 Next steps:

- Implement redistribution scheduling for total range/time (phase 2).

# 🔹 Block 291 — Plan Group info modal clarity (08/02/2026)

### ✔ Work completed:

- Clarified the Plan Group info modal copy with per-option explanations.
- Removed the “Don’t show again” checkbox from the manual info icon flow.
- Fixed the async context lint in Task List by guarding mounted before navigation.

### 🎯 Next steps:

- Run full manual validation after phase 2 scheduling is added.

# 🔹 Block 292 — Planning flow scheduling redistribution (08/02/2026)

### ✔ Work completed:

- Enabled schedule by total range and total time with pomodoro redistribution.
- Added shift notice when the computed end time is earlier than requested.
- Returned redistributed items from the planning screen for group creation.

### 🎯 Next steps:

- Multi-platform validation for range/time scheduling (Android/iOS/Web).

# 🔹 Block 293 — Planning redistribution validation fix (08/02/2026)

### ✔ Work completed:

- Adjusted redistribution to search for a fit within the requested time range.
- Avoided false “too short” errors by fitting durations before blocking.

### 🎯 Next steps:

- Re-test schedule by total range/time with wide and tight windows.

# 🔹 Block 294 — Planning redistribution deviation guard (08/02/2026)

### ✔ Work completed:

- Updated redistribution search to track time-fit and deviation-safe candidates.
- Ensured “too short” only appears when no time-fit exists; otherwise surface skew warning.

### 🎯 Next steps:

- Re-test schedule by total range/time for valid windows to confirm no false blocks.

# 🔹 Block 295 — Planning redistribution stabilization (08/02/2026)

### ✔ Work completed:

- Removed the diff-adjustment loop in redistribution to avoid skewed allocations.
- Kept proportional rounding so binary search can find valid, deviation-safe fits.

### 🎯 Next steps:

- Re-test total range/time scheduling on the reported config to confirm the skew error is gone.

# 🔹 Block 296 — Planning redistribution max-fit pass (08/02/2026)

### ✔ Work completed:

- Added a refinement pass to maximize end time within the requested range.
- Allows safe pomodoro swaps/increments while respecting deviation rules.

### 🎯 Next steps:

- Re-test total range/time for the 05:00 → 11:00 case to confirm the end time is closer to the max.

# 🔹 Block 297 — Redistribution tests + domain helper (08/02/2026)

### ✔ Work completed:

- Moved redistribution logic into a domain helper for testability.
- Added unit tests for range/total scheduling in individual and shared modes.

### 🎯 Next steps:

- Run `flutter test` to verify redistribution coverage.

# 🔹 Block 298 — Additional planner coverage (08/02/2026)

### ✔ Work completed:

- Added start-time validation helper and tests for past/future timestamps.
- Expanded redistribution tests to cover 3+ tasks and max-fit checks.

### 🎯 Next steps:

- Re-run `flutter test test/domain/task_group_planner_test.dart`.

# 🔹 Block 299 — Inline adjusted-end notice (08/02/2026)

### ✔ Work completed:

- Replaced the adjusted-end dialog with an inline notice in Plan Group.
- Added an inline “Don’t show again” toggle stored per device.

### 🎯 Next steps:

- Quick visual pass to confirm the notice stays lightweight on narrow screens.

# 🔹 Block 300 — Plan Group time picker copy (08/02/2026)

### ✔ Work completed:

- Added explicit help text for Plan Group start/end time pickers and duration picker.
- Clarified date and time selection intent across schedule options.

### 🎯 Next steps:

- Quick pass to confirm picker titles read correctly on Android/iOS/Web.

# 🧾 General notes

- Update this document at the **end of each development session**
- Use short bullet points, not long narrative
- This allows the AI to jump in on any day and continue directly

# 🔹 Block 301 — GitHub sign-in conflict code (08/02/2026)

### ✔ Work completed:

- Accepted both `account-exists-with-different-credential` and `account-exists-with-different-credentials` codes for GitHub linking on desktop.
- Restored the provider-linking flow when Firebase returns the pluralized Windows error code.

### ⚠️ Issues found:

- Windows Firebase Auth returns the pluralized error code, which bypassed the linking flow.

### 🎯 Next steps:

- Validate GitHub sign-in on Windows when the email already exists for another provider.

# 🔹 Block 302 — macOS profile run + GitHub validation (08/02/2026)

### ✔ Work completed:

- Updated `scripts/run_macos.sh` to run in `--profile` with `--devtools` and write logs to `macos-log.txt` for performance checks.
- Documented the macOS run behavior in `README.md`.
- Validated the GitHub sign-in conflict fix on macOS.

# 🔹 Block 303 — Account profile metadata (docs) (08/02/2026)

### ✔ Work completed:

- Documented account display name + avatar metadata (presentation-only) and Firebase Storage usage with 200 KB client-side compression.
- Updated roadmap to track the new Account Profile requirement and ownership label format.

# 🔹 Block 304 — Plan Group total duration + Pre-Run auto-start (docs) (08/02/2026)

### ✔ Work completed:

- Documented Plan Group total duration visibility (work + breaks).
- Clarified Pre-Run behavior: no owner, any device can cancel, and auto-start requires no user action.
- Updated roadmap to track the new Plan Group total duration requirement and the Pre-Run auto-start bug.

### ⚠️ Issues found:

- Scheduled Pre-Run sometimes waits for a manual Start instead of auto-starting at the scheduled time when multiple devices are open.

# 🔹 Block 305 — Pre-Run auto-start fix (08/02/2026)

### ✔ Work completed:

- Removed scheduledByDeviceId gating so any open device can auto-start a scheduled group.
- Increased scheduled auto-start retry window to reduce timing races.
- Updated specs to mark scheduledByDeviceId as metadata only for auto-start/ownership.

### 🎯 Next steps:

- Validate scheduled auto-start across Web + Android + iOS with multiple devices open.

# 🔹 Block 306 — Pre-Run auto-start robustness (08/02/2026)

### ✔ Work completed:

- Added a TimerScreen fallback to mark scheduled groups as running when the countdown ends.
- Preserved scheduled actualStartTime when Start is pressed after a scheduled run begins.
- Avoided overwriting scheduledByDeviceId when auto-starting a scheduled group.

### 🎯 Next steps:

- Re-test multi-device scheduled start (Web/iOS/Android) and verify no timeline reset.

# 🔹 Block 307 — Auto-start owner claim (08/02/2026)

### ✔ Work completed:

- Added a transactional session claim to ensure only one device becomes owner at start.
- Allowed TimerScreen to auto-start on running groups without requiring an existing activeSession.

### 🎯 Next steps:

- Re-test scheduled auto-start across Web + Android + iOS; verify only one owner and no Start prompt.

# 🔹 Block 308 — Owner education snackbar scope (08/02/2026)

### ✔ Work completed:

- Guarded the owner-education snackbar so it only appears on the true owner device.

# 🔹 Block 309 — Canceled groups re-plan (09/02/2026)

### ✔ Work completed:

- Documented canceled-group retention and re-plan behavior in specs and roadmap.
- Added Groups Hub support to surface canceled groups with a re-plan action.

---

# 🔹 Block 310 — Start-now owner determinism (09/02/2026)

### ✔ Work completed:

- Clarified deterministic ownership rules for Start now vs scheduled auto-start.
- Ensured only the initiating device claims the initial activeSession for Start now groups.

---

# 🔹 Block 311 — Auto-takeover on inactive owner (09/02/2026)

### ✔ Work completed:

- Documented ownership auto-takeover rules based on stale heartbeats.
- Added paused-session heartbeats and auto-claim logic when the owner is inactive.

---

# 🔹 Block 312 — Ownership analyzer fix (09/02/2026)

### ✔ Work completed:

- Fixed request-status variable naming in the ownership auto-takeover transaction.

---

# 🔹 Block 313 — Ownership auto-takeover retry (09/02/2026)

### ✔ Work completed:

- Enabled stale-owner auto-takeover even when a pending request already exists for the same device.
- Added a mirror-side retry when a pending request becomes stale.

---

# 🔹 Block 314 — Ownership takeover mirror timer (09/02/2026)

### ✔ Work completed:

- Ensured mirror takeover checks run for paused sessions by keeping the mirror timer active during any active execution.

---

# 🔹 Block 315 — macOS mirror repaint guard (09/02/2026)

### ✔ Work completed:

- Added a macOS-only inactive repaint timer to keep mirror-mode timers updating when the app window lacks focus.
- Limited the repaint guard to active execution in mirror mode (no logic changes).

---

# 🔹 Block 316 — macOS mirror repaint analyzer fix (09/02/2026)

### ✔ Work completed:

- Fixed a nullable state inference issue in the inactive repaint guard.

---

# 🔹 Block 317 — Web auth persistence (09/02/2026)

### ✔ Work completed:

- Enforced Firebase Auth local persistence on web after Firebase init.
- Documented the need for a stable Chrome user-data directory in web dev runs.

---

# 🔹 Block 318 — Run Mode progress visuals (docs) (09/02/2026)

### ✔ Work completed:

- Specified chip-based group progress bar labeling, states, and pulse behavior.
- Clarified contextual task list outline rules and completed-item sizing.

---

# 🔹 Block 319 — Release safety policy (09/02/2026)

### ✔ Work completed:

- Added `docs/release_safety.md` with production compatibility, migration, and rollout rules.
- Updated `AGENTS.md` with mandatory production safety and data evolution requirements.
- Updated `.github/copilot-instructions.md` to enforce the release safety policy.

### 🎯 Next steps:

- Define the concrete DEV/STAGING/PROD Firebase mapping and environment switch strategy.
- Validate emulator and staging workflows before the first production release.

---

# 🔹 Block 320 — Environment safety + schema versioning (09/02/2026)

### ✔ Work completed:

- Added AppConfig with `APP_ENV` enforcement, emulator defaults, and staging placeholders.
- Updated Firebase init to select env-specific options and connect emulators in DEV.
- Added `dataVersion` support to critical models and a dual-read/dual-write migration template.
- Documented DEV/STAGING/PROD setup and added a release checklist.
- Added a release-safety script to require specs/dev log updates on schema changes.

### 🎯 Next steps:

- Create the STAGING Firebase project and generate real `firebase_options_staging.dart`.
- Validate emulator and staging runs across target platforms.

# 🔹 Block 321 — Firebase macOS app registration (09/02/2026)

### ✔ Work completed:

- Registered a dedicated macOS Firebase app and regenerated `firebase_options.dart`.
- Updated macOS bundle id to `com.marcdevelopez.focusinterval.macos`.
- Updated iOS/macOS GoogleService-Info.plist files and firebase.json via FlutterFire CLI.

### 🎯 Next steps:

- Validate macOS/iOS auth + Firestore in debug and release builds.

# 🔹 Block 322 — Test updates for dataVersion (09/02/2026)

### ✔ Work completed:

- Updated task-related tests to include `dataVersion` after schema versioning changes.

# 🔹 Block 323 — Emulator usage docs (09/02/2026)

### ✔ Work completed:

- Documented emulator start commands and the Emulator UI URL in `docs/environments.md`.

# 🔹 Block 324 — Release GitHub OAuth command (09/02/2026)

### ✔ Work completed:

- Added a release build command with `GITHUB_OAUTH_CLIENT_ID` to `docs/environments.md`.

# 🔹 Block 325 — README release OAuth command (09/02/2026)

### ✔ Work completed:

- Added the release + GitHub OAuth command to `README.md` for quick reference.

# 🔹 Block 326 — Groups Hub empty-state CTA (09/02/2026)

### ✔ Work completed:

- Ensured the "Go to Task List" CTA remains visible in Groups Hub even when no groups exist.

# 🔹 Block 327 — Linux Account Mode rationale (09/02/2026)

### ✔ Work completed:

- Documented why Linux desktop runs Local Mode only and how to use Web for Account Mode.

# 🔹 Block 328 — Staging setup checklist (10/02/2026)

### ✔ Work completed:

- Added `docs/staging_checklist.md` with a step-by-step STAGING project setup path.
- Clarified DEV/STAGING/PROD project mapping in `docs/environments.md`.

# 🔹 Block 329 — Staging billing plan note (10/02/2026)

### ✔ Work completed:

- Documented that STAGING currently uses Spark and should be upgraded to Blaze only if needed.

# 🔹 Block 330 — Sync + lifecycle stabilization (10/02/2026)

### ✔ Work completed:

- Updated specs with activeSession fields (`currentTaskStartedAt`, `pausedAt`), time-range anchoring rules, pause offset persistence, resume resync, and ownership retry.
- Reopened Phase 18 items for lifecycle resync, task range anchoring, pause-offset persistence, and ownership retry.
- Added session schema fields (`currentTaskStartedAt`, `pausedAt`) and propagation in PomodoroViewModel + Firestore sync.
- Run Mode now persists pause offsets by extending TaskRunGroup.theoreticalEndTime on resume.
- Run Mode resyncs on AppLifecycleState.resumed and gates controls while syncing; TimerScreen avoids transient Ready by showing a sync loader.
- Ownership request UI allows retry when a pending request exceeds the stale threshold.

### 🧠 Decisions made:

- Use TaskRunGroup.theoreticalEndTime as the authoritative pause-offset accumulator for task ranges.
- Keep phaseStartedAt for progress only; task ranges anchor to actualStartTime + accumulated offsets.

### ⚠️ Issues found:

- `tools/check_release_safety.sh` failed before the dev log update (expected); passed after adding this block.

### 🎯 Next steps:

- Re-run `tools/check_release_safety.sh` after dev log update.
- Validate sync + ownership transfer scenarios on macOS/Android (release builds).

# 🔹 Block 331 — Run Mode sync UI safeguards (10/02/2026)

### ✔ Work completed:

- Added a Syncing state in Run Mode when `activeSession` is temporarily missing while a group is running.
- Added manual refresh in Run Mode (AppBar sync icon) to trigger `syncWithRemoteSession()`.
- Hid ownership indicator and contextual task list while syncing to avoid showing stale ranges.

### 🎯 Next steps:

- Re-test macOS sleep/wake + Android mirror to confirm no duplicate owner state appears.

# 🔹 Block 332 — Firestore rules deploy requirement (11/02/2026)

### ✔ Work completed:

- Documented that any new Firestore collection/path requires updating `firestore.rules`
  and redeploying rules/indexes (AGENTS, release safety, Copilot instructions).

# 🔹 Block 333 — Ownership sync guard + UI refresh (11/02/2026)

### ✔ Work completed:

- Guarded activeSession publishes to prevent non-owners from overwriting `ownerDeviceId`.
- Triggered UI refresh when ownership metadata changes (owner/device or request) even if state is unchanged.

### 🎯 Next steps:

- Re-test ownership transfer while the prior owner is backgrounded/asleep on macOS + Android mirror.

# 🔹 Block 334 — Desktop inactive resync keepalive (11/02/2026)

### ✔ Work completed:

- Added a periodic inactive resync in Account Mode to surface ownership requests and avoid stale controls on desktop.
- Documented the inactive resync keepalive behavior in the Run Mode sync specs.

# 🔹 Block 335 — Ownership auto-claim + resync hardening (11/02/2026)

### ✔ Work completed:

- Lowered the stale ownership threshold to 45s and documented the new rule.
- Enabled auto-claim on stale owner without requiring a manual request.
- Added post-request resync after approve/reject/request to remove transient control mismatches.
- Updated scheduled session staleness checks to align with the new threshold.

# 🔹 Block 336 — Paused ownership stability + Android paused heartbeats (11/02/2026)

### ✔ Work completed:

- Limited auto-claim to running sessions; paused sessions only auto-claim when a pending requester is stale.
- Added Android owner heartbeats during paused state via ForegroundService.
- Documented paused ownership stability rules in specs.

# 🔹 Block 337 — Ownership API hardening (11/02/2026)

### ✔ Work completed:

- Split ownership request vs auto-claim responsibilities (request never changes owner).
- Made auto-claim status-aware inside the transaction (running vs paused).
- Added owner-only clearSession path plus explicit stale/invalid cleanup helpers.

# 🔹 Block 338 — Stale null guard for ownership (11/02/2026)

### ✔ Work completed:

- Treated missing `lastUpdatedAt` as **not stale** to avoid auto-claim/cleanup
  during server-timestamp propagation.
- Applied the guard consistently in auto-claim and stale-cleanup paths.

# 🔹 Block 339 — Paused expiry guard + verification (11/02/2026)

### ✔ Work completed:

- Deferred running-group expiry until the activeSession stream has emitted at least once
  to prevent paused sessions from being completed on resume.
- Added debug logs at the expiry decision points (sanitize + coordinator).
- Added coordinator tests to assert paused sessions never complete and to cover the
  stream-loading race.

# 🔹 Block 340 — Active-session expiry guards (11/02/2026)

### ✔ Work completed:

- Prevented running-group expiry when `activeSession` is missing or not running.
- Required groupId match between activeSession and the running group to allow expiry.
- Expanded expiry logs with session/group ids, running/stale flags, and end delta.
- Added tests for `null -> paused` session snapshots and cross-group running sessions.

# 🔹 Block 341 — Repo auto-complete removal (11/02/2026)

### ✔ Work completed:

- Removed repository-level auto-complete-on-read for expired running groups.
- Confirmed expiry is enforced only by coordinator/viewmodel guards.
- Added repo-level debug logs for expired running groups without mutating status.
- Added tests ensuring repos do not auto-complete without session context.

# 🔹 Block 342 — Ownership request resync on resume (12/02/2026)

### ✔ Work completed:

- Forced session stream re-subscription on resume to surface pending ownership
  requests after background/sleep.
- Added a short post-resume resync to catch delayed Firestore snapshots.
- Ensured resync updates trigger UI refresh when ownership metadata changes.

# 🔹 Block 343 — Optimistic ownership pending indicator (12/02/2026)

### ✔ Work completed:

- Added optimistic pending state for ownership requests so the requester sees
  the amber indicator immediately after tapping Request.
- Cleared optimistic state once the stream confirms the request or ownership
  changes, keeping UI derived from the activeSession snapshot.
- Documented the optimistic pending indicator behavior in specs.

# 🔹 Block 344 — Ownership reject prompt dismiss (12/02/2026)

### ✔ Work completed:

- Dismissed the owner-side ownership request prompt immediately on reject
  to match accept behavior (optimistic UI).
- Added a per-request dismissal key to avoid waiting for remote snapshot latency.
- Documented immediate dismiss behavior in specs.

# 🔹 Block 345 — Ownership reject flicker guard (12/02/2026)

### ✔ Work completed:

- Prevented the reject prompt from reappearing due to transient `activeSession`
  gaps by keeping the dismissal until the request resolves.
- Cleared the dismissal only when the same requester’s request is no longer pending.

# 🚀 End of file

# 🔹 Block 346 — Ownership stream unification + gating (12/02/2026)

### ✔ Work completed:

- Clarified specs for scheduled auto-start ownership (first device wins),
  Pre-Run cancel exception, always-visible ownership indicator (syncing variant),
  and removed manual sync from Run Mode.
- PomodoroViewModel now listens to the shared activeSession stream
  (`pomodoroSessionStreamProvider`) to keep VM/UI snapshots aligned.
- Added session-missing tracking while a group is running, preserving last-known
  session state while disabling controls during sync gaps.
- Hardened control gating in Account Mode: requires a valid session snapshot,
  disables during sync gaps, allows initial start when no session exists yet,
  and allows Pre-Run cancel on all devices.
- TimerScreen now uses VM session snapshots for ownership UI, shows a syncing
  ownership indicator when needed, disables request actions while syncing, and
  removed the AppBar manual sync button.

# 🔹 Block 347 — Session-missing gating + neutral indicator (12/02/2026)

### ✔ Work completed:

- Treat `group running + session null` as syncing unconditionally to avoid
  enabling controls before activeSession arrives.
- Added auto-start path that syncs first and only starts when no session exists,
  preventing duplicate starts while keeping scheduled/start-now flows working.
- Ownership indicator now distinguishes real syncing vs "no session yet" (neutral),
  and disables ownership actions when there is no session.

# 🔹 Block 348 — Sync-gap neutralization (12/02/2026)

### ✔ Work completed:

- Removed unreachable duplicate branch in session-null handling.
- Neutralized `activeSessionForCurrentGroup` during sync gaps so mirror/owner
  derivations do not rely on stale snapshots while syncing.

# 🔹 Block 349 — Pending indicator priority (12/02/2026)

### ✔ Work completed:

- Made the ownership pending indicator override syncing/no-session visuals so
  the requester stays amber immediately after tapping Request.
- Kept request button disabled during sync gaps while preserving the
  "Request sent" status text.

# 🔹 Block 350 — Preserve optimistic request on mirror switch (12/02/2026)

### ✔ Work completed:

- Prevented \_resetLocalSessionState from clearing optimistic ownership when
  switching from owner to mirror while a local request is pending.
- This keeps the requester indicator amber without flicker until the owner
  approves or rejects.

# 🔹 Block 351 — Optimistic request precedence over stale rejection (12/02/2026)

### ✔ Work completed:

- Prevented optimistic pending state from being cleared by an older rejected
  ownershipRequest snapshot (keeps requester indicator amber until confirmed).
- OwnershipRequest getter now prefers optimistic pending when the remote request
  is older than the local request.

# 🔹 Block 352 — Optimistic request kept over stale rejected (other requester) (12/02/2026)

### ✔ Work completed:

- Stopped clearing optimistic pending when the remote ownershipRequest is a
  rejected request from another device (stale rejection should not override
  a fresh local request).
- Prefers optimistic pending when a rejected request lacks timestamps,
  avoiding flicker before Firestore writes the new pending request.

# 🔹 Block 353 — Local pending gating for request UI (12/02/2026)

### ✔ Work completed:

- Added an explicit local pending flag for ownership requests so the requester
  stays in "Request sent" immediately after tapping, even if snapshots lag.
- Request button gating now respects local pending to prevent double taps while
  the request is in-flight.

# 🔹 Block 354 — Ownership requestId for optimistic reconciliation (12/02/2026)

### ✔ Work completed:

- Added `requestId` to ownership requests and propagated it through the
  Firestore request + rejection flow.
- Optimistic pending now matches by requestId to ignore stale rejected requests,
  preventing the request indicator from flashing back to mirror.

# 🔹 Block 355 — Pending UI held until owner responds (12/02/2026)

### ✔ Work completed:

- Requester pending UI no longer clears due to intermediate snapshots.
- Local pending is cleared only when the owner responds (accepted or rejected)
  or when another device has a pending request.

# 🔹 Block 356 — Request action moved into ownership sheet (12/02/2026)

### ✔ Work completed:

- Removed the mirror-side “Request” button from the main control row.
- Ownership requests are now initiated only from the AppBar ownership sheet
  to reduce inconsistent UI states and simplify the flow.

# 🔹 Block 357 — Retry CTA moved to ownership sheet (12/02/2026)

### ✔ Work completed:

- Added the **Retry** label to the ownership sheet action when a pending request
  exceeds the stale threshold.
- Keeps the retry path available without reintroducing a main control-row button.

# 🔹 Block 358 — CRITICAL: Ownership request UI locked + stable (12/02/2026)

### ✔ Work completed:

- Ownership request action moved to the AppBar ownership sheet only; mirror
  control row no longer shows a Request button.
- Requester pending UI now stays stable (no revert) until the owner responds.
- This UX flow is now a **locked requirement** in specs to prevent regressions.

# 🔹 Block 359 — Fix reject + retry state reset (12/02/2026)

### ✔ Work completed:

- Cleared local pending when a rejection arrives for the same requester.
- Ownership request keys now use requestId when available, so new requests
  are not suppressed after a prior rejection.

# 🔹 Block 360 — Reject modal dismissal stabilized (12/02/2026)

### ✔ Work completed:

- Prevented the owner-side reject modal from reappearing due to requestId
  materializing after the initial tap by dismissing via requesterId as well.
- Dismissal now clears only when the request resolves, avoiding flicker.

# 🔹 Block 361 — Reject modal source unified (13/02/2026)

### ✔ Work completed:

- Ownership request dismissal + rejection snackbar now derive from the
  ViewModel session only (removed mixed stream source).
- This prevents the owner-side reject modal from reappearing after a reject
  due to stale stream/Vm timing mismatches.

# 🔹 Block 362 — Allow repeat requests after reject (13/02/2026)

### ✔ Work completed:

- Dismiss suppression now keys off requestId when available; requesterId is
  only used for legacy requests without requestId.
- This ensures a new request from the same mirror is visible to the owner
  and is not blocked by a previous dismissal.

# 🔹 Block 363 — Preserve new pending over old rejection (13/02/2026)

### ✔ Work completed:

- A new ownership request no longer loses its pending state when a previous
  rejection still exists in the remote session.
- Reconciliation now compares requestId (or timestamps for legacy requests),
  so the mirror indicator stays amber immediately after re-requesting.

# 🔹 Block 364 — Ownership request UX postmortem & lock-in (13/02/2026)

### ✔ Work completed:

- Final root cause identified: **optimistic pending was cleared by an older
  rejection** because requestId was not used to reconcile snapshots.
- Reinforced reconciliation rules in ViewModel and specs:
  - Rejections apply **only** to the same requestId.
  - New requests from the same device must remain pending immediately.
- Earlier failed attempts (documented for future maintenance):
  - Dismiss-by-requesterId blocked future requests (fixed by requestId scoping).
  - Mixed stream vs VM dismissal caused the owner modal to reappear (unified to VM).
  - Removing the control-row Request button reduced transient UI divergence.
- Tests added to lock the expected behavior and prevent regressions.

### 🧠 Lessons captured:

- Ownership UI must derive from **one source of truth** (VM) to avoid flicker.
- `requestId` is mandatory for reliable optimistic sync; legacy timestamps are
  only a fallback.

# 🔹 Block 365 — Auto-dismiss rejection snackbar on state change (13/02/2026)

### ✔ Work completed:

- Rejection snackbar now auto-clears when the requester either becomes owner
  or sends a new pending request, preventing stale UI.
- Kept snackbar non-blocking with OK, but ensured it never lingers over a
  successful ownership transition.

# 🔹 Block 366 — Selection-scoped task weight (13/02/2026)

### ✔ Work completed:

- Updated specs to make task weight selection-scoped and hide Task weight (%)
  when the task is not selected.
- Added a domain helper + unit tests for normalized task weight percentages.
- Added selection-scoped weight providers and wired Task List to them.
- Updated Task Editor to show Task weight (%) only for selected tasks,
  redistribute within the selected set, and add an info modal + info icon.

### 🧠 Decisions made:

- Task weight percentages are derived only from the selected task group;
  unselected tasks are never impacted by weight edits.
- The educational modal follows the existing “Don’t show again” pattern and
  remains accessible via the info icon.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Validate weight behavior across selection scenarios (1 task = 100%, 2 tasks = 50/50),
  plus Edit Task visibility and redistribution boundaries.

# 🔹 Block 367 — Hold mirror state during session gaps (13/02/2026)

### ✔ Work completed:

- Added a session-gap guard in PomodoroViewModel so recent active sessions keep
  Run Mode in a syncing state instead of dropping to Ready.
- Missing activeSession now checks the previous session + lastUpdatedAt before
  clearing mirror state, preventing transient gaps from resetting the timer.

### 🧠 Decisions made:

- Treat a missing activeSession as a **sync gap** when the last known session is
  active and within the stale threshold; prefer Syncing UI over Ready.

### ⚠️ Issues found:

- Android mirror briefly rendered Ready while activeSession was still running
  on the owner (session snapshot gap).

### 🎯 Next steps:

- Validate on Android mirror that session gaps show Syncing instead of Ready,
  including background/foreground and app-switch scenarios.

# 🔹 Block 368 — Allow Local Mode switch from login (13/02/2026)

### ✔ Work completed:

- Enabled the Account/Local mode chip on the Login screen to switch into
  Local Mode and return to the Task List when Account Mode is active.

### 🧠 Decisions made:

- Login should honor “switch between Local and Account at any time” by allowing
  a direct Local Mode exit even before sign-in.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Verify on Chrome and iOS that tapping the mode chip exits to Local Mode.

# 🔹 Block 369 — Noop streams emit empty lists (13/02/2026)

### ✔ Work completed:

- Updated Noop task, task run group, and preset repositories to emit an empty
  list immediately instead of never emitting.
- Unblocked Task List / Groups Hub / Preset screens from staying in a perpetual
  loading state when Account Mode has no signed-in user or sync disabled.

### 🧠 Decisions made:

- Noop repositories must always emit an initial empty list so empty-state UI
  renders instead of a stuck syncing indicator.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Validate on macOS that fresh installs show the empty states + sign-in CTA
  instead of loading spinners in Account Mode with no user.

# 🔹 Block 370 — Add centralized bug log (13/02/2026)

### ✔ Work completed:

- Added docs/bugs/bug_log.md to centralize bug tracking.
- Seeded the log with BUG-001 (mirror Ready with active session) and marked it intermittent.

### 🧠 Decisions made:

- Bug notes live in docs/bugs/bug_log.md; dev log references them only when tied to code changes.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Add new bug reports to docs/bugs/bug_log.md in chronological order.

# 🔹 Block 371 — Add feature backlog (13/02/2026)

### ✔ Work completed:

- Added docs/features/feature_backlog.md to centralize feature ideas.
- Seeded IDEA-001 (circular group progress ring around the timer).

### 🧠 Decisions made:

- Feature ideas live in docs/features/feature_backlog.md with a consistent template.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Add the remaining feature ideas using the same template.

# 🔹 Block 372 — Document ownership desync + mirror flicker bugs (13/02/2026)

### ✔ Work completed:

- Added BUG-002 and BUG-003 to docs/bugs/bug_log.md, splitting ownership rejection
  desync from macOS mirror flicker.
- Expanded evidence with key Firestore timestamps and observed sequences.
- Updated bug log template to include Repro steps, Workaround, and optional
  device/role/snapshot details.

### 🧠 Decisions made:

- Separate root-cause candidates into distinct bug entries for targeted fixes.

### ⚠️ Issues found:

- Ownership rejection can leave Android in Ready despite activeSession running.

### 🎯 Next steps:

- Validate BUG-002 on Android after any ownership UI changes.

# 🔹 Block 373 — Split ownership bugs and add timer drift/inactive window issues (13/02/2026)

### ✔ Work completed:

- Refined BUG-002 with clearer ownership-requested UI symptoms and evidence.
- Added BUG-004 (mirror timer drift during long breaks).
- Added BUG-005 (macOS inactive window hides ownership requests).

### 🧠 Decisions made:

- Separate ownership-handling failures from time-drift and desktop-focus issues
  to isolate root causes.

### ⚠️ Issues found:

- Mirror time drift can grow over long phases.
- macOS may miss ownership requests while inactive.

### 🎯 Next steps:

- Validate BUG-004 and BUG-005 after ownership resync changes.

# 🔹 Block 374 — Add delayed-retry rejection evidence to BUG-002 (14/02/2026)

### ✔ Work completed:

- Expanded BUG-002 with delayed Retry delivery and post-Groups Hub snapshot
  showing rejected ownershipRequest while session runs.

### 🧠 Decisions made:

- Keep delayed-retry evidence under BUG-002 to avoid fragmenting ownership
  desync root-cause analysis.

### ⚠️ Issues found:

- Firestore can retain rejected ownershipRequest after UI resync.

### 🎯 Next steps:

- Re-validate BUG-002 after ownership-request handling changes.

# 🔹 Block 375 — Define scheduling conflict resolution rules (14/02/2026)

### ✔ Work completed:

- Documented late-start overlap handling, overdue scheduled group queue, and
  long-pause conflict resolution in `docs/specs.md`.
- Added owner-only decision rules with auto-claim on conflict flows.
- Introduced `canceledReason` for canceled groups (interrupted/conflict/missed)
  and Groups Hub labeling guidance.

### 🧠 Decisions made:

- Conflicts caused by delayed starts or long pauses always require explicit user
  choice; no silent auto-cancellation.
- Overdue scheduled groups are queued by user-selected order; the first starts
  immediately while subsequent groups preserve pre-run windows.
- Paused/running overlap decisions count as normal pauses and must be resolved
  by the owner.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Implement and validate the new conflict-resolution flows in Run Mode and
  planning/Groups Hub surfaces.

# 🔹 Block 376 — Refine late-start conflict chooser behavior (14/02/2026)

### ✔ Work completed:

- Updated the late-start conflict chooser to allow selecting one group or
  selecting none, with explicit confirmation for canceling all conflicts.
- Clarified single-selection behavior in the chooser flow.

### 🧠 Decisions made:

- Late-start conflicts remain owner-only; user can explicitly choose to cancel
  all conflicting groups instead of being forced to pick one.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Verify the conflict chooser UX aligns with the catch-up queue expectations.

# 🔹 Block 377 — Allow multi-select ordering in late-start conflicts (14/02/2026)

### ✔ Work completed:

- Updated the late-start conflict chooser to allow multi-select + reordering
  of conflicting groups, with sequential execution and preserved pre-run windows.
- Clarified that unselected conflicting groups are canceled with reason
  `conflict`.

### 🧠 Decisions made:

- Late-start conflicts use a queue-like selection: the first starts immediately
  (no pre-run), subsequent selections keep their pre-run windows.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Ensure the conflict chooser preview reflects updated projected ranges and
  revalidation rules.

# 🔹 Block 378 — Unify late-start overlap flows (14/02/2026)

### ✔ Work completed:

- Unified late-start overlap handling into a single full-screen queue flow.
- Removed the separate late-start chooser variant; the queue now covers one or
  more overdue overlaps with the same multi-select + reorder logic.
- Clarified cancel-reason rules for overdue vs future-scheduled groups.

### 🧠 Decisions made:

- Late-start overlap resolution uses one consistent UX path to reduce logic
  branches and bug surface area.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Validate the unified flow against all late-start overlap cases.

# 🔹 Block 379 — Add write-safety rules for conflict resolution (14/02/2026)

### ✔ Work completed:

- Added atomic write requirements for multi-group cancel/reschedule flows.
- Required resume to update TaskRunGroup + activeSession atomically, blocking
  resume on failure to prevent time drift.

### 🧠 Decisions made:

- Conflict-resolution flows must not proceed on partial writes; retries are
  mandatory before starting or resuming groups.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Ensure implementation uses batch/transaction writes for conflict resolution
  and resume updates.

# 🔹 Block 380 — Log status box pause anchoring bug (14/02/2026)

### ✔ Work completed:

- Added BUG-006 to docs/bugs/bug_log.md for status-box time ranges that ignore pause
  anchoring, to align with contextual task list behavior.

### 🧠 Decisions made:

- Treat status-box time range inconsistency as a bug (not a feature request).

### ⚠️ Issues found:

- Pause/resume can shift status-box ranges retroactively instead of forward-only.

### 🎯 Next steps:

- Validate BUG-006 once Run Mode time-range calculations are reviewed.

# 🔹 Block 381 — Merge Android request delay into BUG-005 (14/02/2026)

### ✔ Work completed:

- Expanded BUG-005 to include the Android receiver variant where ownership
  requests only surface after navigating to Groups Hub.
- Removed the duplicate BUG-007 entry to keep ownership request issues unified.

### 🧠 Decisions made:

- Keep ownership request delays under a single bug with platform variants.

### ⚠️ Issues found:

- Android can miss ownership requests until a manual navigation refresh.

### 🎯 Next steps:

- Validate BUG-005 variants alongside other ownership-request resync fixes.

# 🔹 Block 382 — Add Ready->Run context to BUG-005 (14/02/2026)

### ✔ Work completed:

- Added context to BUG-005 noting a brief Ready screen on macOS mirror before
  the ownership request (macOS -> Android) failed to surface, then a tap
  restored the running timer.

### 🧠 Decisions made:

- Keep the Ready->Run context under BUG-005 Variant B to preserve the full
  ownership-request timeline.

### ⚠️ Issues found:

- macOS mirror can show Ready briefly before an ownership request is missed on
  Android.

### 🎯 Next steps:

- Validate whether the Ready->Run flicker correlates with missed requests.

# 🔹 Block 383 — Add owner background resubscribe detail (14/02/2026)

### ✔ Work completed:

- Added BUG-005 Variant B detail: background/foreground on the Android owner
  surfaces the pending ownership request after the Ready->Run recovery.

### 🧠 Decisions made:

- Treat background/foreground as another resubscribe trigger for the same bug.

### ⚠️ Issues found:

- Ownership requests can remain hidden until the owner app resubscribes.

### 🎯 Next steps:

- Validate whether resume listeners consistently surface pending requests.

# 🔹 Block 384 — Note Ready recovery without request delay (14/02/2026)

### ✔ Work completed:

- Added BUG-005 Variant B context where macOS mirror showed Ready briefly, then
  recovered on click and the ownership request to Android surfaced immediately.

### 🧠 Decisions made:

- Document that Ready-state flicker does not always correlate with request delay.

### ⚠️ Issues found:

- Ready-state recovery can still coexist with correct request delivery.

### 🎯 Next steps:

- Validate if Ready-state flicker and request delay have separate triggers.

# 🔹 Block 385 — Clarify plan group auto-rebase wording (15/02/2026)

### ✔ Work completed:

- Updated IDEA-016 in `docs/features/feature_backlog.md` to state that scheduled previews
  auto-rebase to the nearest valid start when pre-run becomes stale, with a
  warning and conflict gating.

### 🧠 Decisions made:

- Scheduled plan previews must remain confirmable by auto-updating stale start
  times (now + noticeMinutes) and warning the user.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-016/017 once wording is approved.

# 🔹 Block 386 — Add paused task range live update idea (15/02/2026)

### ✔ Work completed:

- Added IDEA-018 to `docs/features/feature_backlog.md` for live pause updates of task
  time ranges in Run Mode (task list under the timer).

### 🧠 Decisions made:

- Treat pause-time range updates as a UI consistency improvement (no business
  logic changes).

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-018 on its own branch.

# 🔹 Block 387 — Add break tasks list idea (15/02/2026)

### ✔ Work completed:

- Added IDEA-019 to `docs/features/feature_backlog.md` for a Break tasks list in Run Mode
  with break-only completion and local per-user persistence.

### 🧠 Decisions made:

- Keep Break tasks as a UI/UX feature without changes to TaskRunGroup logic.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-019 on its own branch.

# 🔹 Block 388 — Add break-only quick chip behavior (15/02/2026)

### ✔ Work completed:

- Expanded IDEA-019 to surface the next break task as a chip during breaks,
  with a quick Yes/Not yet completion modal.

### 🧠 Decisions made:

- Keep the quick chip visible only in break phases; pomodoros show the icon only.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push the updated IDEA-019.

# 🔹 Block 389 — Add optional break tasks sharing notes (15/02/2026)

### ✔ Work completed:

- Expanded IDEA-019 to clarify device-only visibility by default and an optional
  share-to-active-devices flow with recipient acceptance and id-based dedupe.

### 🧠 Decisions made:

- Keep sharing explicit and opt-in; no background sync for break tasks.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push the updated IDEA-019 if approved.

# 🔹 Block 390 — Clarify pomodoro completion restriction rationale (15/02/2026)

### ✔ Work completed:

- Updated IDEA-019 to explain that break-task completion is disabled during
  pomodoros to protect focus time.

### 🧠 Decisions made:

- Completion gating rationale must be explicit in the visual states section.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-019 once approved.

# 🔹 Block 391 — Clarify break tasks sharing scope (15/02/2026)

### ✔ Work completed:

- Updated IDEA-019 to allow sharing either the full break-task list or selected
  items when sending to active devices.

### 🧠 Decisions made:

- Share flow must support subset sharing, not just full list transfer.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-019 once approved.

# 🔹 Block 392 — Add scheduled-by field idea (15/02/2026)

### ✔ Work completed:

- Added IDEA-020 to `docs/features/feature_backlog.md` for showing scheduledByDeviceId
  in Group Summary with a legacy fallback.

### 🧠 Decisions made:

- Treat scheduled-by visibility as a UI-only traceability improvement.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-020 on its own branch.

# 🔹 Block 393 — Add account deletion idea (16/02/2026)

### ✔ Work completed:

- Added IDEA-021 to `docs/features/feature_backlog.md` for an Account Mode "Delete account"
  action with explicit destructive confirmation.

### 🧠 Decisions made:

- Keep deletion flow as a UI/UX entry that must align with provider and backend
  deletion rules (no behavior change beyond exposure and safe flow).

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-021 on its own branch.

# 🔹 Block 394 — Add verified presence + heatmap idea (16/02/2026)

### ✔ Work completed:

- Added IDEA-022 to `docs/features/feature_backlog.md` for pomodoro presence verification
  and a GitHub-style activity heatmap (personal vs workspace).

### 🧠 Decisions made:

- Presence confirmation is a lightweight banner at pomodoro boundaries and only
  verified pomodoros count toward the heatmap.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-022 on its own branch.

# 🔹 Block 395 — Clarify backlog scope/priority legend (16/02/2026)

### ✔ Work completed:

- Updated the feature backlog template to document Scope (S/M/L) and Priority
  (P0/P1/P2) meanings.

### 🧠 Decisions made:

- Keep the legend inline with the template for quick reference.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push along with IDEA-022 if approved.

# 🔹 Block 396 — Add resume canceled groups idea (16/02/2026)

### ✔ Work completed:

- Added IDEA-023 to `docs/features/feature_backlog.md` for resuming canceled groups while
  keeping Re-plan as an alternative.

### 🧠 Decisions made:

- Treat Resume as a behavior change that requires a spec update before any
  implementation.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-023 on its own branch.

# 🔹 Block 394 — Add mirror desync after resync/phase change (16/02/2026)

### ✔ Work completed:

- Expanded BUG-004 with a new scenario: mirror desync after Ready->Run recovery,
  ownership acceptance, and a phase change; pause/resume preserves the offset
  until another mirror device resubscribes.

### 🧠 Decisions made:

- Treat this as additional evidence for mirror timer drift rather than a new bug.

### ⚠️ Issues found:

- Mirror offset can persist across phase changes and survive pause/resume.

### 🎯 Next steps:

- Validate whether resubscribe or phase-change handling re-bases mirror timers.

# 🔹 Block 395 — Add Ready screen recurrence to BUG-001 (16/02/2026)

### ✔ Work completed:

- Expanded BUG-001 with a 16/02/2026 occurrence: Android mirror showed Ready
  during Pomodoro 2 after backgrounding; resynced only after Groups Hub
  navigation, despite macOS owner running.

### 🧠 Decisions made:

- Treat this as additional evidence for the mirror Ready-with-session bug.

### ⚠️ Issues found:

- Mirror Ready screen can recur after background/resume without ownership changes.

### 🎯 Next steps:

- Re-validate BUG-001 after any session-gap handling changes.

# 🔹 Block 396 — Add ownership revert workaround to BUG-002 (16/02/2026)

### ✔ Work completed:

- Expanded BUG-002 with a 16/02/2026 scenario: mirror Ready after background,
  ownership accepted but reverted unless Run Mode was refreshed quickly.
- Documented the short-window Groups Hub refresh workaround (~20–30s) that
  stabilizes ownership.

### 🧠 Decisions made:

- Treat the ownership revert as part of the existing desync bug.

### ⚠️ Issues found:

- Ownership can revert to the previous owner unless a fast resubscribe occurs.

### 🎯 Next steps:

- Validate whether resubscribe timing prevents ownership rollback.

# 🔹 Block 397 — Add post-ownership timer offset detail (16/02/2026)

### ✔ Work completed:

- Added BUG-002 follow-up: after ownership stabilized on Android, macOS mirror
  showed ~5 seconds less remaining (mirror ahead).

### 🧠 Decisions made:

- Track small post-ownership offsets under the same desync bug.

### ⚠️ Issues found:

- Mirror can remain a few seconds behind even after ownership stabilizes.

### 🎯 Next steps:

- Verify whether ownership stabilization also re-bases mirror timers.

# 🔹 Block 398 — Add mirror pulsing + growing drift detail (16/02/2026)

### ✔ Work completed:

- Added BUG-002 follow-up: mirror drift grows over time and macOS UI pulses
  between synced and offset timers once per second during the break.

### 🧠 Decisions made:

- Track pulsing UI and growing drift under the same ownership desync bug.

### ⚠️ Issues found:

- Mirror can oscillate between two timer projections while drifting.

### 🎯 Next steps:

- Check for competing projections or duplicate timer sources on mirror.

# 🔹 Block 399 — Note Groups Hub resync after pulsing (16/02/2026)

### ✔ Work completed:

- Added BUG-002 detail: navigating to Groups Hub and back re-synchronizes the
  mirror with the owner/Firebase after pulsing/drift.

### 🧠 Decisions made:

- Keep resync behavior documented under the same desync bug.

### ⚠️ Issues found:

- Manual navigation remains the reliable recovery path.

### 🎯 Next steps:

- Verify if automatic resubscribe can replace manual Groups Hub refresh.

# 🔹 Block 400 — Add workspace shared groups idea (17/02/2026)

### ✔ Work completed:

- Added IDEA-024 to `docs/features/feature_backlog.md` for Workspaces with shared
  TaskRunGroups, ownership rules, and personal-overlap conflict gating.

### 🧠 Decisions made:

- Treat Workspaces as a large-scope product/architecture feature that depends
  on new Firestore collections and explicit conflict-resolution rules.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-024 on its own branch.

# 🔹 Block 401 — Add workspace owner-request option (17/02/2026)

### ✔ Work completed:

- Updated IDEA-024 to allow an optional setting where members can request
  workspace run ownership if the owner enables it.

### 🧠 Decisions made:

- Keep ownership requests opt-in per workspace and require explicit approval.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-024 update.

# 🔹 Block 402 — Switch to auto-ownership option (17/02/2026)

### ✔ Work completed:

- Updated IDEA-024 to specify an optional setting for automatic member
  ownership (no approval) when the workspace owner enables it.

### 🧠 Decisions made:

- Auto-ownership is opt-in per workspace and replaces approval-based requests.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-024 update.

# 🔹 Block 403 — Clarify workspace shared group scheduling (17/02/2026)

### ✔ Work completed:

- Updated IDEA-024 to state that shared workspace groups have no start time
  until the owner schedules them, so conflicts only apply after scheduling.

### 🧠 Decisions made:

- Keep multiple shared groups unscheduled until the owner assigns exact starts.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-024 update.

# 🔹 Block 404 — Add workspace break chat idea (17/02/2026)

### ✔ Work completed:

- Added IDEA-025 to `docs/features/feature_backlog.md` for break-focused workspace chat,
  including deferred DM delivery and data-efficient sync rules.

### 🧠 Decisions made:

- Chat is text-only in this phase; delivery and visibility are gated by run
  break phases to avoid focus disruption.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-025 on its own branch.

# 🔹 Block 405 — Clarify workspace chat vs DM scope (17/02/2026)

### ✔ Work completed:

- Updated IDEA-025 to explicitly call out a workspace-wide group chat plus
  member-to-member direct messages.

### 🧠 Decisions made:

- Keep both chat modes text-only and break-focused in this phase.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push the IDEA-025 clarification.

# 🔹 Block 406 — Clarify out-of-run chat access (17/02/2026)

### ✔ Work completed:

- Updated IDEA-025 to allow workspace chat and DMs outside runs, with no inbound
  delivery/notifications during pomodoro focus time.

### 🧠 Decisions made:

- Keep pomodoro focus time free of incoming chat delivery; queue until break.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push the IDEA-025 update.

# 🔹 Block 407 — Clarify pomodoro vs break delivery semantics (17/02/2026)

### ✔ Work completed:

- Tightened IDEA-025 to state that inbound messages are not visible during
  pomodoros and become visible at the next break; out-of-run behaves normally.

### 🧠 Decisions made:

- "Receive" explicitly means "becomes visible" to avoid focus disruption.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push the IDEA-025 clarification.

# 🔹 Block 408 — Add total-time Ready recurrence to BUG-001 (17/02/2026)

### ✔ Work completed:

- Expanded BUG-001 with a total-time planning scenario where macOS mirror shows
  Ready during a running group and only resyncs after tap or Groups Hub navigation.

### 🧠 Decisions made:

- Keep this under the mirror Ready-with-session bug as additional evidence.

### ⚠️ Issues found:

- Mirror can remain in Ready across multiple phases without auto-resync.

### 🎯 Next steps:

- Re-validate mirror Ready recovery paths in Run Mode.

# 🔹 Block 409 — Add Manage Presets item UX idea (17/02/2026)

### ✔ Work completed:

- Added IDEA-026 to `docs/features/feature_backlog.md` for consistent Manage Presets item
  preview, star placement, and tap/long-press behavior.

### 🧠 Decisions made:

- Align preset item gestures with Task List: tap edits, long-press selects.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-026 on its own branch.

# 🔹 Block 410 — Add unified mode indicator idea (17/02/2026)

### ✔ Work completed:

- Added IDEA-027 to `docs/features/feature_backlog.md` for consistent mode indicator
  placement and a single session-context sheet across screens.

### 🧠 Decisions made:

- Keep logout and account context inside the mode sheet/Settings to clean
  AppBars.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-027 on its own branch.

# 🔹 Block 411 — Add verified activity summary idea (17/02/2026)

### ✔ Work completed:

- Added IDEA-028 to `docs/features/feature_backlog.md` for verified weekly/monthly totals,
  task breakdowns, and a Week-start setting aligned with IDEA-022.

### 🧠 Decisions made:

- Only verified pomodoros count toward totals and breakdowns.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-028 on its own branch.

# 🔹 Block 412 — Add live pause time ranges idea (17/02/2026)

### ✔ Work completed:

- Added IDEA-029 to `docs/features/feature_backlog.md` for live pause time ranges that
  update forward-only during paused state.

### 🧠 Decisions made:

- Pause offsets must never rewrite past start times; only forward ranges move.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-029 on its own branch.

# 🔹 Block 413 — Log owner resume drift after background crash (17/02/2026)

### ✔ Work completed:

- Logged BUG-007 in `docs/bugs/bug_log.md` for owner resume drift after an Android
  background crash (owner behind mirror by ~5s) and manual resync recovery.

### 🧠 Decisions made:

- Track this as a distinct sync/ownership correctness issue with resume
  re-anchoring as the likely root cause.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Investigate resume re-anchoring and add instrumentation/tests before fix.

# 🔹 Block 414 — Ownership sync hardening (server fetch + gap handling) (17/02/2026)

### ✔ Work completed:

- Added server-preferred activeSession fetch and used it on resume/inactive resync.
- Added session snapshot tracking to hold “Syncing session...” during gaps.
- Added debug instrumentation for activeSession snapshots and missing holds.
- Added unit test covering session-gap hold when lastUpdatedAt is missing.

### 🧠 Decisions made:

- Prefer server snapshots for resume and inactive keepalive to surface ownership
  changes promptly and avoid stale cached reads.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Validate on Android + macOS with real devices (owner background/resume, request
  flows, mirror drift scenarios).

# 🔹 Block 415 — Short ownership request validation (17/02/2026)

### ✔ Work completed:

- Ran a short manual test: Android mirror requested ownership while macOS owner
  was in background (app hidden). On bringing macOS to foreground, the request
  appeared immediately and was accepted; Android obtained ownership correctly
  (UI + Firestore).

### 🧠 Decisions made:

- Treat this as a positive short-session validation only; longer/pause-heavy
  scenarios still need coverage before closing BUG-005/BUG-002.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Run a long-pause test (2–3h) with both devices backgrounded; report any
  desync or ownership regressions.

# 🔹 Block 416 — Background auto-claim validation (17/02/2026)

### ✔ Work completed:

- Ran a manual test with both devices backgrounded during a scheduled run:
  Android requested and obtained ownership, then both devices went to
  background. On resume, macOS auto-claimed as owner (stale owner rule) and
  Firestore reflected the same ownerDeviceId and running state.
- Verified Firestore snapshot during resume showed consistent fields:
  ownerDeviceId = macOS, status = shortBreakRunning, phaseStartedAt and
  lastUpdatedAt populated, remainingSeconds aligned.

### 🧠 Decisions made:

- Treat this as a positive validation of auto-claim rules when owner is stale.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Capture precise timestamps (owner before/after, lastUpdatedAt, status) on
  long-pause tests to confirm no regressions.

# 🔹 Block 417 — Pause resume snapshot validation (17/02/2026)

### ✔ Work completed:

- Captured Firestore snapshot before resume with both devices backgrounded:
  ownerDeviceId = android, status = paused, pausedAt = 20:20:03, remainingSeconds = 360.
- Captured snapshot after resume (≈15s later): ownerDeviceId = android,
  status = pomodoroRunning, lastUpdatedAt = 20:43:09, phaseStartedAt = 20:24:08,
  remainingSeconds = 359.
- Ownership remained on Android; session resumed without drift.

### 🧠 Decisions made:

- Treat this as a positive validation for owner stability after a backgrounded
  pause (no auto-flip to macOS in this scenario).

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Re-test with a longer pause window if any regression appears.

# 🔹 Block 418 — Clarify pause duration (17/02/2026)

### ✔ Work completed:

- Clarification: the previous validation pause lasted ~20 minutes (approx).

### 🧠 Decisions made:

- Treat the pause duration as approximate; use Firestore timestamps for exact
  deltas in future logs.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- None.

# 🔹 Block 419 — Owner heartbeat during session gaps (17/02/2026)

### ✔ Work completed:

- Logged BUG-008 for unexpected owner auto-claim while Android owner was in
  foreground (owner became stale and macOS auto-claimed).
- Updated PomodoroViewModel to allow owner heartbeats while the session stream
  is missing (syncing) to prevent stale ownership during gaps.

### 🧠 Decisions made:

- Treat missing-session gaps as a UI-sync state only; owner heartbeats must
  continue when the last known snapshot says this device is owner.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Re-test foreground owner stability during stream gaps (no auto-claim).

# 🔹 Block 420 — Add macOS local reset commands to README (17/02/2026)

### ✔ Work completed:

- Added a dedicated "Local reset (macOS)" section to `README.md` with clean
  test commands and Keychain cleanup guidance.

### 🧠 Decisions made:

- Keep reset steps in README for quick access during device sync testing.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- None.

# 🔹 Block 421 — Foreground owner stability validation (alt account) (17/02/2026)

### ✔ Work completed:

- Ran the foreground owner stability test on a different account:
  - Android started the run and remained owner.
  - macOS opened for observation only (no request).
  - After 2–3 minutes with Android in foreground, Firestore still showed
    ownerDeviceId = android and lastUpdatedAt advancing.

### 🧠 Decisions made:

- Treat this as a positive validation for the foreground owner heartbeat path.

### ⚠️ Issues found:

- Failures still appear after long pauses or backgrounding; those scenarios
  remain the priority for reproductions.

### 🎯 Next steps:

- Continue long-pause/background tests on the original account to reproduce
  ownership flips or retry/accept loops.

# 🔹 Block 422 — Long background validations + ownership loop (17/02/2026)

### ✔ Work completed:

- Ran long pause + both background test (60–90 min): owner stayed Android after
  resume; activeSession remained consistent.
- Ran running session + both background test (30–45 min): owner stayed Android
  after reopening; no ownership flip.
- Ran ownership request after long background (macOS owner, Android requester):
  accept briefly flipped owner to Android, then reverted to macOS within
  ~15–20 seconds; retry/accept loop persisted until Groups Hub navigation.
- Captured drift observation: macOS owner matched Firestore snapshot
  (`remainingSeconds = 1060` at 23:52:53 UTC+1), while Android showed fewer
  seconds and the gap appeared to grow until Groups Hub resync.

### 🧠 Decisions made:

- Treat the long-pause and running-background scenarios as positive
  validations for owner stability.
- Log the ownership loop as additional evidence for BUG-002.
- Log the growing drift observation under BUG-004 (possible clock skew /
  projection offset issue).

### ⚠️ Issues found:

- Ownership accept loops after long background; Android remains in requested/
  retry state and cannot retain ownership.
- Mirror drift grows over time with macOS owner; Android displays fewer seconds
  until a Groups Hub resync.

### 🎯 Next steps:

- Re-test the ownership loop after the next build to confirm if fixes reduce
  reversion behavior.
- Capture system clock times on both devices during drift to confirm
  clock-skew vs projection error.

# 🔹 Block 423 — Drift growth confirmed with matched system clocks (18/02/2026)

### ✔ Work completed:

- Captured drift evidence during long break with system clocks aligned:
  - 00:43:58 UTC+1: macOS 05:56 vs Android 05:14 (delta 42s).
  - 00:55:09 UTC+1: macOS 19:55 vs Android 19:02 (delta 53s).
- Confirmed the drift increased (~11s in ~11 minutes) while macOS remained
  owner, indicating a projection issue rather than clock skew.

### 🧠 Decisions made:

- Treat this as strong evidence for BUG-004 (growing mirror drift).

### ⚠️ Issues found:

- Drift grows over time even when device clocks match; Android shows fewer
  seconds than macOS.

### 🎯 Next steps:

- Document a spec change for server-time offset projection before code changes.

# 🔹 Block 424 — Specs: server-time offset projection (18/02/2026)

### ✔ Work completed:

- Updated `docs/specs.md` to require server-time offset projection for
  activeSession timers (derived from lastUpdatedAt).
- Clarified that projection must not use raw local clock alone and must
  rebase on ownership changes or new snapshots.

### 🧠 Decisions made:

- Treat the drift as a projection/rebase issue; fix via spec-first changes
  before any code updates.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Implement server-time offset projection in Run Mode after confirming the
  spec change is acceptable.

# 🔹 Block 425 — Implement server-time offset projection (18/02/2026)

### ✔ Work completed:

- Added server-time offset projection in `PomodoroViewModel` for activeSession
  timers (derived from lastUpdatedAt).
- Ensured projection reuses the last known offset when lastUpdatedAt is missing.
- Applied projection anchor consistently when rehydrating sessions and mirror
  updates.

### 🧠 Decisions made:

- Keep local-time projection only for Local Mode; Account Mode uses server
  offset when available.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Validate on device that mirror drift no longer grows during long breaks.

# 🔹 Block 426 — Keep Run Mode alive during active sessions (18/02/2026)

### ✔ Work completed:

- Added a keep-alive link for `PomodoroViewModel` while an active session exists
  to avoid offset resets when navigating to Groups Hub.
- Tied keep-alive state to active execution or missing-session sync gaps.

### 🧠 Decisions made:

- Preserve the Run Mode VM in Account Mode during active sessions to keep
  heartbeat cadence and projection offsets stable across navigation.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Re-test Groups Hub navigation to confirm timers no longer gain seconds on
  return.

# 🔹 Block 427 — Groups Hub jump evidence captured (18/02/2026)

### ✔ Work completed:

- Captured Firestore snapshots around Groups Hub navigation while running
  (macOS owner):
  - 02:03:54: remainingSeconds = 150 (before Groups Hub).
  - 02:04:24: remainingSeconds = 120 (2–5s after return).
  - 02:05:26: remainingSeconds = 60 (≈30s later).
- Reported that the returning device briefly showed more remaining seconds
  (timer jumped forward) despite Firestore continuing to count down.

### 🧠 Decisions made:

- Treat the jump as a navigation-induced offset reset; validate the keep-alive
  fix against this exact flow.

### ⚠️ Issues found:

- UI jump on return from Groups Hub while running (pending fix validation).

### 🎯 Next steps:

- Re-test the jump after the keep-alive change; confirm if the timer no longer
  adds seconds on return.

# 🔹 Block 428 — Suppress local machine timer in mirror mode (18/02/2026)

### ✔ Work completed:

- Added a mirror-safe restore path that updates the session state without
  starting the local PomodoroMachine timer.
- Updated mirror projection to apply state via the new restore mode so the
  mirror relies exclusively on activeSession snapshots.

### 🧠 Decisions made:

- Mirror devices must not run the local PomodoroMachine timer; they only
  project from Firestore-derived session data.

### ⚠️ Issues found:

- Ownership request delivery can still require a Groups Hub resubscribe after
  multiple ownership changes and an owner pause (BUG-005).

### 🎯 Next steps:

- Validate that mirror timer flicker and late sounds no longer occur after
  ownership handoff.

# 🔹 Block 429 — Split mirror flicker vs timer swap (18/02/2026)

### ✔ Work completed:

- Separated the ~15s mirror pulse (BUG-003) from the per-second timer swap
  (BUG-009) to avoid conflating cosmetic refresh with the timer swap bug.

### 🧠 Decisions made:

- Track the per-second swap as a distinct bug with its own fix/validation path.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Re-test after the mirror timer suppression to confirm BUG-009 no longer appears.

# 🔹 Block 430 — Regression found: owner freezes after accept (18/02/2026)

### ✔ Work completed:

- Logged a regression where ownership acceptance briefly flips to the requester,
  then reverts to the previous owner within seconds; requester UI freezes in
  requested state.
- Captured the Start Now scenario where Android did not auto-open Run Mode while
  macOS started the session.

### 🧠 Decisions made:

- Roll back the mirror timer suppression change and reassess ownership flow.

### ⚠️ Issues found:

- Ownership accept still reverts after a few seconds; requester remains stuck.
- Auto-open to Run Mode did not trigger for Android on Task List.

### 🎯 Next steps:

- Revert the mirror suppression change on a dedicated branch.
- Re-test ownership acceptance and auto-open flow after rollback.

# 🔹 Block 431 — Ownership request delay (first delivery) validated (18/02/2026)

### ✔ Work completed:

- Captured a delayed ownership request delivery on Android while paused:
  Firestore showed `ownershipRequest = pending` ~30s before Android surfaced it.
- Subsequent ownership requests and accepts succeeded without regressions in the
  same session.

### 🧠 Decisions made:

- Treat this as additional evidence for BUG-005 (request not surfaced until
  resubscribe/focus) rather than a new bug.

### ⚠️ Issues found:

- Initial ownership request delivery can lag even when both devices are active.

### 🎯 Next steps:

- Continue testing background + long pause scenarios to isolate the trigger for
  delayed ownership delivery.

# 🔹 Block 432 — Add feature execution order list (18/02/2026)

### ✔ Work completed:

- Added a "Recommended execution order" section to `docs/features/feature_backlog.md`
  while keeping idea entries in chronological order.

### 🧠 Decisions made:

- New ideas remain appended at the end; the recommended order list will be
  updated as new ideas are added.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Revisit the order after ownership/sync bugs and Phase 17 validation close.

# 🔹 Block 433 — Document resync overlay mitigation (18/02/2026)

### ✔ Work completed:

- Added a mitigation note to `docs/bugs/bug_log.md` proposing a Run Mode "Syncing..."
  overlay that mimics the Groups Hub resubscribe without navigation.

### 🧠 Decisions made:

- Treat this as a release fallback if ownership/sync bugs persist near MVP
  launch, while continuing to pursue root-cause fixes.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Implement only if needed for release stability and after specs approval.

# 🔹 Block 434 — Add pending request evidence after Ready (18/02/2026)

### ✔ Work completed:

- Expanded BUG-005 with an 18/02/2026 case: macOS mirror recovered from Ready,
  but ownership requests remained pending in Firestore and did not surface on
  Android until Groups Hub navigation.

### 🧠 Decisions made:

- Keep this under ownership request surfacing failures (BUG-005).

### ⚠️ Issues found:

- Owner UI can miss pending requests even after mirror resync.

### 🎯 Next steps:

- Validate whether owner-side listeners refresh on incoming requests.

# 🔹 Block 435 — Merge IDEA-018 into IDEA-029 (18/02/2026)

### ✔ Work completed:

- Marked IDEA-018 as merged into IDEA-029 to avoid duplicate pause-range
  features in the backlog.

### 🧠 Decisions made:

- Keep IDEA-029 as the single source for live pause range updates (task list
  - status boxes).

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Update the recommended execution order if needed after Phase 17 closes.

# 🔹 Block 436 — Restore IDEA-018 details while merged (18/02/2026)

### ✔ Work completed:

- Restored IDEA-018 details while keeping it merged into IDEA-029.
- Expanded IDEA-029 with task-list cadence and batch-update details from
  IDEA-018 to preserve the full spec.

### 🧠 Decisions made:

- Keep IDEA-018 as a traceable sub-scope while IDEA-029 remains the unified
  source for pause-range behavior.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- None.

# 🔹 Block 437 — Phase 17 test coverage + workflow rule (18/02/2026)

### ✔ Work completed:

- Added a mandatory pre-implementation high-level plan + risk review rule to
  `AGENTS.md` and `.github/copilot-instructions.md`.
- Added ScheduledGroupCoordinator tests for late-start queue + running overlap
  decision; introduced a `@visibleForTesting` helper to evaluate overlap logic
  deterministically.
- Updated ownership/session-gap tests to wait for session readiness before
  asserting pending/missing states.
- `flutter analyze` and `flutter test` now pass.

### 🧠 Decisions made:

- Use a `@visibleForTesting` helper to validate overlap decision logic without
  relying on stream timing.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- None.

# 🔹 Block 438 — Account-scoped pre-run notice setting (18/02/2026)

### ✔ Work completed:

- Documented account-scoped Pre-Run notice minutes in `docs/specs.md` and
  added the requirement to Phase 14; Phase 17 reopened items removed and
  formally closed in `docs/roadmap.md`.
- Added Settings UI for Pre-Run notice minutes and a small viewmodel to load
  and persist the value.
- Implemented Firestore-backed notice preference (per account) with local
  fallback; updated `firestore.rules` for `/users/{uid}/settings/*`.
- Added tests for the notice settings viewmodel.
- `flutter analyze` and `flutter test` pass.

### 🧠 Decisions made:

- Notice minutes are **per account** in Account Mode and **per device** in
  Local Mode; range capped at 0–15 minutes with default 5.
- Firestore settings document is additive; no backfill required (per
  `docs/release_safety.md`).

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Validate cross-device sync of notice minutes on two signed-in devices.

# 🔹 Block 439 — Phase 17 reopen: early overlap warning + mirror CTA (18/02/2026)

### ✔ Work completed:

- Updated specs for early running-overlap detection (pause drift) with break-based
  deferral rules and an explicit last-pomodoro exception.
- Added mirror UX requirements: persistent CTA in Groups Hub/Task List and a
  persistent conflict SnackBar requiring OK to dismiss.
- Reopened Phase 17 in the roadmap to track the new conflict-resolution scope.

### 🧠 Decisions made:

- Detect running overlap as soon as theoreticalEndTime crosses the next
  scheduled pre-run window (even before the pre-run starts).
- Defer the decision modal to breaks when possible; show immediately only on
  the final pomodoro.
- Mirror CTA copy uses “Owner seems unavailable…” and always allows a request.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Implement the early overlap warning + mirror CTA + persistent SnackBar.
- Add tests for the updated overlap detection timing and deferral rules.

# 🔹 Block 440 — Clarify overlap notification timing (18/02/2026)

### ✔ Work completed:

- Refined the running-overlap timing rules to trigger the decision as soon as
  overlap becomes possible (runningEnd >= preRunStart), without waiting for
  a pomodoro-count threshold.
- Clarified break-first behavior with an explicit last-pomodoro exception.

### 🧠 Decisions made:

- Overlap detection starts at the moment it becomes possible; the UI only
  defers to the nearest allowed break unless there is no break left.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Implement the updated timing logic in the coordinator and TimerScreen.

# 🔹 Block 441 — Implement early overlap warning + mirror CTA (18/02/2026)

### ✔ Work completed:

- Scheduled overlap detection now triggers as soon as runningEnd crosses the
  next pre-run start (no pre-run window gating), and mirrors receive the
  overlap signal for CTA/snackbar use.
- TimerScreen now defers the conflict modal to breaks, with an immediate
  exception for the final pomodoro.
- Added mirror conflict CTA + persistent SnackBar to Groups Hub and Task List.
- Added an ownership-request helper on the PomodoroViewModel for mirror CTAs.
- Updated overlap tests to cover pre-run-future detection and mirror devices.
- Ran `flutter analyze`.
- Ran `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart`.

### 🧠 Decisions made:

- Use the existing overlap decision provider for mirror UX signals, while
  keeping the modal owner-only via TimerScreen checks.
- SnackBars are persistent (no swipe dismissal) and require explicit OK.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Validate the new overlap timing and mirror CTA behavior on device.

# 🔹 Block 442 — Phase 17: auto-follow postpone + paused overlap timing (19/02/2026)

### ✔ Work completed:

- Updated specs for postponed scheduling (postponedAfterGroupId), paused overlap
  projection, and postpone confirmation SnackBar copy.
- Implemented auto-follow postpone: scheduled groups track the running group’s
  projected end in real time and lock in the schedule when the anchor ends.
- Added paused overlap recheck scheduling so conflicts surface without waiting
  for resume.
- Updated Groups Hub and Task List to display effective scheduled timing and
  pre-run status for postponed groups.
- Postpone now confirms the new start time and pre-run time via SnackBar.
- Added overlap tests for paused projection and postponed-follow suppression.
- Ran `flutter analyze`.
- Ran `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart`.

### 🧠 Decisions made:

- Paused overlap decisions show immediately (no deferral).
- Effective schedule derives from anchor end + notice until it is finalized.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Run the full test suite.
- Validate postpone flow on device (no repeat modal; schedule updates during
  pauses).

# 🔹 Block 443 — Phase 17: paused overlap recheck + cancel postponed schedule fix (19/02/2026)

### ✔ Work completed:

- ScheduledGroupCoordinator now re-evaluates overlaps on paused session heartbeats
  (no resume required) and avoids overriding canceled postponed groups.
- Cancel scheduled group now clears postponedAfterGroupId to prevent re-apply.
- Ran `flutter analyze`.
- Ran `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart`.

### 🧠 Decisions made:

- Use paused-session heartbeats (pausedAt/lastUpdatedAt) to trigger conflict
  evaluation while in foreground.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Validate pause-overlap and cancel-postponed flows on device.

# 🔹 Block 444 — Add break-start Ready recurrence (20/02/2026)

### ✔ Work completed:

- Expanded BUG-001 with a 20/02/2026 recurrence: mirror shows Ready at break
  start and only re-syncs after tap on macOS or Groups Hub navigation on Android.

### 🧠 Decisions made:

- Treat break-start Ready as another recurrence of the mirror Ready bug.

### ⚠️ Issues found:

- Android mirror often requires Groups Hub navigation to recover.

### 🎯 Next steps:

- Validate whether break transitions trigger session-gap handling.

# 🔹 Block 445 — Fix overdue late-start queue + navigation stability (20/02/2026)

### ✔ Work completed:

- Late-start conflict detection moved to shared timing utilities.
- Coordinator now re-evaluates overdue queues immediately after clearing stale
  active sessions.
- Groups Hub “Start now” now redirects to late-start queue when overdue
  conflicts exist.
- Late-start confirm navigation now uses a delayed fallback to avoid duplicate
  transitions.
- Completion dialog suppressed when totals are empty (prevents 0/0/0 modal).
- Added unit test for 3 overdue scheduled groups.
- Updated bug log (BUG-008).

### 🧠 Decisions made:

- Prioritize late-start resolution over manual “Start now” when overdue
  conflicts exist and no running group is active.
- Avoid double navigation by letting the coordinator own the main transition.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Validate overdue late-start flow on Android (late-open scenario).
- Verify confirm flow navigates directly to Run Mode (no carousel).

# 🔹 Block 446 — Late-start queue ownership + live projections + chained postpone (20/02/2026)

### ✔ Work completed:

- Added late-start queue metadata fields (anchor, queue id/order, owner, claim).
- Implemented queue ownership claim/auto-claim and owner heartbeat updates.
- Late-start queue UI is now owner-only; mirrors are read-only with request CTA.
- Projections update live using a shared server timebase.
- Confirm queue now sets scheduledStartTime to queueNow, bootstraps activeSession,
  and clears queue owner/claim fields while keeping queue id/order for chaining.
- Postpone now chains queued groups sequentially and preserves notice/pre-run.
- copyWith now supports explicit null clearing for optional fields.

### 🧠 Decisions made:

- Use server heartbeat timebase for cross-device queue projections.
- Preserve lateStartQueueId/order on selected groups for chained postpone.

### ⚠️ Issues found:

_(not yet validated on devices)_

### 🎯 Next steps:

- Validate late-start owner flow + request/approve on macOS/Android.
- Confirm live projections align across devices.
- Exercise chained postpone with multiple queued groups.

# 🔹 Block 447 — Late-start auto-claim determinism + dispose guards (21/02/2026)

### ✔ Work completed:

- Made late-start auto-claim deterministic when heartbeat is missing and anchor is stale.
- Added guard rails against ref use after dispose in coordinator async flow.
- Ensured late-start anchor is materialized when owner already has the queue.
- Extended coordinator tests with claim tracking + async wait to avoid race flakiness.
- Ran `flutter analyze` and `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart`.

### 🧠 Decisions made:

- Auto-claim is allowed when no owner exists or when owner heartbeat/anchor is stale.
- If owner is current device but anchor is missing, claim to seed the anchor.

### ⚠️ Issues found:

_(none in automated tests)_

### 🎯 Next steps:

- Resume manual multi-device validation on macOS/Android (owner request / approve / no bounce).

# 🔹 Block 448 — Restore sticky Groups Hub CTA + regression guard (21/02/2026)

### ✔ Work completed:

- Specs updated to require a sticky “Go to Task List” CTA outside the scrollable list.
- Roadmap reopened item added for the Groups Hub sticky CTA regression.
- Groups Hub now renders the CTA as a fixed header (always visible).
- Added AGENTS rule: do not degrade implemented UX without explicit owner approval.
- Ran `flutter analyze`.

### 🧠 Decisions made:

- Keep the mirror conflict banner inside the scrollable list; only the CTA is sticky.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Validate Groups Hub CTA remains visible while scrolling long lists.

# 🔹 Block 449 — Late-start ownership stability + overlap validity guards (22/02/2026)

### ✔ Work completed:

- Specs: late-start queue scheduled range now shows date when not today.
- Late-start queue ownership: server-validated claim + heartbeat + request guards to prevent owner bounce.
- Late-start queue UI: auto-claim blocked when another requester is pending.
- Running overlap UI: added validity checks to suppress stale conflict banners/snackbars.
- Running overlap detection: treat end == pre-run start as non-overlap to avoid false conflicts.

### 🧠 Decisions made:

- Guard late-start ownership changes against pending requests and stale-owner checks using server state when possible.
- Validate overlap decisions at render time to avoid persistent UI after conflicts resolve.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Re-validate late-start ownership on macOS + Android with queued conflicts.
- Verify no stale overlap banners remain after rescheduling or completion.

# 🔹 Block 450 — ActiveSession missing recovery (22/02/2026)

### ✔ Work completed:

- Specs: documented owner-only recovery when `activeSession` is missing during running/paused.
- PomodoroViewModel: added missing-session recovery (tryClaim + publish) with cooldown.
- Enabled heartbeats while syncing when the local machine is actively executing.
- Triggered recovery on stream/resync missing snapshots.

### 🧠 Decisions made:

- Recovery is allowed only when the local machine is running/paused and the group is running.
- Mirrors never publish during missing-session recovery.

### ⚠️ Issues found:

_(not yet validated on devices)_

### 🎯 Next steps:

- Validate activeSession recovery during late-start queue confirm + running/paused flows.

# 🔹 Block 451 — Timer ranges + pre-run load guards + overlap validity (22/02/2026)

### ✔ Work completed:

- TimerScreen contextual task ranges now include date when the range is not today (scheduled/projection formatting rule).
- Task List planning preview ranges now include date when not today.
- TimerScreen now suppresses stale running-overlap UI by validating decision still matches current schedule.
- TimerScreen no longer shows transient “Ready” during running idle gaps (syncing loader held when needed).
- PomodoroViewModel now allows loading **scheduled** groups even if another active session exists, so Pre-Run/overlap flows can open without bouncing back.

### 🧠 Decisions made:

- Scheduled-group loads are permitted under active-session conflict to unblock Pre-Run and overlap resolution; controls remain gated by conflict rules.
- Running-overlap validity is checked in TimerScreen to prevent persistent mirror conflict messaging after reschedule.

### ⚠️ Issues found:

_(not yet validated on devices)_

### 🎯 Next steps:

- Validate Pre-Run auto-open no longer bounces back to Groups Hub.
- Confirm “Ready” interstitial does not appear during ownership transitions.
- Re-test mirror conflict banners/snackbar suppression after overlaps resolve.

# 🔹 Block 452 — Late-start validation docs + countdown accuracy (23/02/2026)

### ✔ Work completed:

- Specs updated: Pre-Run auto-open idempotency, late-start queue cancel behavior,
  anchored projections on resume, conflict modal context, status box ranges anchored
  to actualStartTime, and real-time countdown requirements for Task List/Groups Hub.
- Roadmap reopened items added for late-start cancel behavior, conflict modal context,
  pre-run auto-open idempotency, and real-time countdowns.
- AGENTS rule added: user-visible countdowns must update in real time (projection-only).

### 🧠 Decisions made:

- Treat all user-visible countdowns as projection-only but **always live-updated**.
- Clarify timebase responsibilities to avoid mixing scheduled/actual/anchor ranges.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Implement code fixes for late-start queue stability, pre-run auto-open navigation,
  countdown updates, conflict modal context, and run-mode range consistency.

# 🔹 Block 453 — Late-start queue fixes + live countdowns (23/02/2026)

### ✔ Work completed:

- Task List pre-run banner now updates countdown every second via a local ticker.
- Late-start queue timebase now projects from `lateStartAnchorAt` on reopen
  (anchor-captured time fixed).
- Late-start queue Cancel clears queue metadata and navigates safely to Groups Hub.
- Late-start queue auto-exit now navigates to Groups Hub (no blank/black screen).
- Running conflict modal now includes the scheduled group's name and time range.
- Cancel-navigation retries no longer override a different timer route.

### 🧠 Decisions made:

- Pre-run countdowns are projection-only but must be live-updated while visible.
- Late-start queue cancel is treated as a cleanup action (clear queue fields).

### ⚠️ Issues found:

_(not yet validated on devices)_

### 🎯 Next steps:

- Re-validate late-start queue projections on macOS/Android after reopen.
- Verify pre-run auto-open is not overridden by Groups Hub navigation.
- Confirm conflict modal timing + context during running overlap scenarios.

# 🔹 Block 454 — Late-start anchor gating + Groups Hub live timing (23/02/2026)

### ✔ Work completed:

- Late-start queue: navigation now requires a real anchor (no `DateTime.now()` fallback).
- Late-start queue cancel-all now exits to Groups Hub (no blank screen).
- Groups Hub adds a 1s ticker for live timing (effective schedule + pre-run state).
- Groups Hub hides Scheduled row for non-scheduled groups to avoid stale ranges.

### 🧠 Decisions made:

- When the late-start anchor is missing, wait for it to materialize before opening the queue.
- Running/paused groups should not show scheduled-only rows.

### ⚠️ Issues found:

_(not yet validated on devices)_

### 🎯 Next steps:

- Validate queue open timing when the anchor is written on the owner device.
- Verify Groups Hub reflects postponed/anchored schedules in real time.

# 🔹 Block 455 — Late-start cancel-all + canceled reason labels (23/02/2026)

### ✔ Work completed:

- Late-start queue Cancel now cancels all listed groups with confirmation and a
  re-plan note, then returns to Groups Hub.
- Continue with no selection now explains that canceled groups can be re-planned
  from Groups Hub.
- Groups Hub cards now show a canceled-reason label (Conflict / Missed schedule /
  Interrupted / Canceled).

### 🧠 Decisions made:

- Cancel in late-start queue resolves the conflict by canceling all groups to
  avoid re-open loops.
- Canceled reason labels are shown on the group card for clear context.

### ⚠️ Issues found:

_(not yet validated on devices)_

### 🎯 Next steps:

- Validate late-start Cancel all flow on macOS + Android.
- Verify canceled-reason labels in Groups Hub across canceled sources.

# 🔹 Block 456 — Canceled reason details + manual cancel doc (23/02/2026)

### ✔ Work completed:

- Specs: explicit cancel-planning reason (user) added to Groups Hub actions.
- Specs: canceled reason label is now tappable with a details modal requirement.
- Groups Hub: reason row is tappable and opens a modal explaining the
  cancellation circumstance with a re-plan reminder.

### 🧠 Decisions made:

- The reason modal uses a short, user-facing explanation per reason to avoid
  confusion and preserve trust.

### ⚠️ Issues found:

_(not yet validated on devices)_

### 🎯 Next steps:

- Validate the reason modal on macOS + Android (tap the reason label).

# 🔹 Block 457 — Validation plan + spec alignment (24/02/2026)

### ✔ Work completed:

- Added a dedicated plan file for the validation fixes:
  `docs/bugs/plan_validacion_rapida_fix.md`.
- Specs updated to cover:
  - Pre-Run auto-open on owner + mirror and Run Mode auto-open at scheduled start.
  - Late-start queue mirror resolution (Owner resolved modal) and
    zero-selection = Cancel all behavior.
  - Groups Hub scheduled vs Pre-Run start labeling (“Pre-Run X min starts at …”).
  - Logout while running/paused must not produce a black screen.
  - Effective schedule must render live on mirrors during postpone.
  - Status boxes and contextual list ranges must remain consistent.
- Roadmap reopened items updated to track the new validation bugs explicitly.

### 🧠 Decisions made:

- Mirror devices must show an explicit “Owner resolved” modal before exiting a
  resolved late-start queue.
- Pre-Run and Run Mode auto-open must be idempotent on **all** signed-in devices.

### ⚠️ Issues found:

- Validation still reports: Pre-Run bounce/duplicate nav, Resolve overlaps
  without conflict, stale schedule on mirrors, +1 minute gaps, and logout
  black screen.

### 🎯 Next steps:

- Implement the fixes in viewmodels/coordinators and UI per the updated specs.
- Re-run the checklist in `docs/bugs/validacion_rapida.md` on macOS + Android.

# 🔹 Block 458 — Validation fixes implementation (24/02/2026)

### ✔ Work completed:

- Late-start queue: mirror “Owner resolved” modal + action lock when all groups
  are canceled; auto-claim suppressed once resolved.
- ScheduledGroupCoordinator: reset on app mode changes; late-start grace window
  added to avoid Pre-Run -> Running overlap queue races.
- Groups Hub: scheduled row now shows run start; Pre-Run row shows
  “Pre-Run X min starts at …” (cards + summary).
- TimerScreen: missing group now routes to Task List (Local Mode) or Groups Hub
  to avoid black screens.
- PomodoroViewModel: clear timeline phase anchor on resume to keep status boxes
  aligned with contextual ranges after pauses.
- Task List logout: clears pending auto-start state and resets coordinator.

### 🧠 Decisions made:

- Use a short grace window to prevent late-start queue from pre-empting the
  scheduled auto-start at the Pre-Run boundary.
- Favor navigation to Task List on Local Mode fallbacks to avoid empty routes.

### ⚠️ Issues found:

_(not yet validated on devices)_

### 🎯 Next steps:

- Re-run the validation checklist on macOS + Android.
- Verify Pre-Run auto-open idempotency, mirror cancel behavior, and logout flow.

# 🔹 Block 459 — Validation workflow + new validation folder (25/02/2026)

### ✔ Work completed:

- AGENTS.md updated to formalize the bug validation workflow and folder structure.
- Created `docs/bugs/validation_fix_2026_02_25/` with a new plan file.
- Initialized an empty `quick_pass_checklist.md` for the next validation cycle.

### 🧠 Decisions made:

- Validation folders are date-based; multiple validations in one day use a `-01`, `-02` suffix.
- Quick pass checklists are created only after implementation is complete.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Implement fixes listed in the 2026-02-25 plan before generating a new checklist.

# 🔹 Block 460 — Screenshot review + plan update (25/02/2026)

### ✔ Work completed:

- Reviewed screenshots 01–20 in `docs/bugs/validation_fix_2026_02_24/screenshots`.
- Updated the 2026-02-25 validation plan with additional issues from the report.
- AGENTS.md updated to require screenshot review before fixes.

### 🧠 Decisions made:

- Treat the pre-run boundary conflict and range drift as separate fixes.
- Android logout black screen is now explicit scope.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Implement fixes for the updated 2026-02-25 plan.

# 🔹 Block 461 — Validation plan fix order (25/02/2026)

### ✔ Work completed:

- Added explicit fix order to the 2026-02-25 validation plan.
- Documented one-fix-per-commit sequencing to preserve traceability.

### 🧠 Decisions made:

- Fixes will be implemented in the plan-defined order.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Start fix #1 in the defined order.

# 🔹 Block 462 — Fix workflow enforcement (25/02/2026)

### ✔ Work completed:

- AGENTS.md updated to require plan updates, tests, and commit sequencing after each fix.
- Validation plan now includes a fix-tracking section for per-fix status updates.

### 🧠 Decisions made:

- Each fix must update the plan before moving to the next fix.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Begin fix #1 per the plan and update tracking after completion.

# 🔹 Block 463 — Fix 1: late-start owner resolved gating (25/02/2026)

### ✔ Work completed:

- Late-start cancel-all now preserves the resolving owner ID to prevent owner-side "Owner resolved" modal.
- Mirror-only "Owner resolved" modal now dismisses via OK using the root navigator.

### 🧠 Decisions made:

- Preserve `lateStartOwnerDeviceId`/heartbeat on cancel-all so mirrors can show resolution while owners are exempt.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Proceed to Fix 2 (Android logout black screen).

# 🔹 Block 464 — Fix commit traceability rule (25/02/2026)

### ✔ Work completed:

- AGENTS.md updated to require recording commit hash + message in the plan after each fix.
- Fix 1 entry updated with commit metadata in the 2026-02-25 plan.

### 🧠 Decisions made:

- Commit metadata lives in the validation plan for per-fix traceability.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Continue with Fix 2 using the new commit-tracking rule.

# 🔹 Block 465 — Fix 2: Android logout black screen (25/02/2026)

### ✔ Work completed:

- Reordered logout flow to navigate to Task List before signing out.
- Cleared scheduled/overlap state on logout to avoid stale navigation.
- Used root router for logout navigation to avoid context loss.

### 🧠 Decisions made:

- Logout now prioritizes stable navigation to `/tasks` before sign-out.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Proceed to Fix 3 (completion must navigate to Groups Hub).

# 🔹 Block 466 — Fix 3: completion navigation to Groups Hub (25/02/2026)

### ✔ Work completed:

- Added a completion-dialog visibility guard to defer scheduled auto-open navigation.
- TimerScreen now tracks completion dialog visibility and no longer auto-dismisses due to scheduled open-timer actions.
- ScheduledGroupAutoStarter defers navigation actions while the completion dialog is visible.

### 🧠 Decisions made:

- Completion dialog now gates scheduled auto-open navigation to ensure Groups Hub is the post-completion landing.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Proceed to Fix 4 (false conflict at pre-run boundary).

# 🔹 Block 467 — Fix 4: pre-run boundary overlap grace (25/02/2026)

### ✔ Work completed:

- Updated specs to treat pre-run overlap only after a 1-minute grace beyond pre-run start.
- Added a shared overlap-grace threshold helper for running overlap detection.
- Running overlap decisions now respect the grace window and recheck timing uses the same threshold.

### 🧠 Decisions made:

- Use a 1-minute grace window to avoid false conflict modals when the running end lands in the same minute as pre-run start.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Proceed to Fix 5 (task item time ranges vs status boxes).

# 🔹 Block 468 — Fix 5: status box ranges align with task ranges (25/02/2026)

### ✔ Work completed:

- Status box ranges now anchor to the phase start timestamp instead of shifting with total pause offsets.
- Phase end now accounts for pauses after the phase starts, keeping end times accurate without moving starts.

### 🧠 Decisions made:

- Use phase-start time as the authoritative start for status boxes; only the end time absorbs pause offsets.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Proceed to Fix 6 (scheduled rows match on owner/mirror).

# 🔹 Block 469 — Fix 6: scheduled rows pre-run alignment (25/02/2026)

### ✔ Work completed:

- Scheduled cards now derive Pre-Run rows from the effective pre-run start instead of raw notice minutes.
- Pre-Run visibility uses a shared effective pre-run helper, keeping owner/mirror rows consistent.

### 🧠 Decisions made:

- Pre-Run rows are shown only when an effective pre-run start exists (notice > 0).

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Proceed to Fix 7 (re-plan "Start now" must always open Run Mode).

# 🔹 Block 470 — Fix 7: re-plan Start now opens Run Mode (25/02/2026)

### ✔ Work completed:

- Groups Hub conflict cancellation now clears the active session when it references the canceled running group.
- Owner devices clear the session authoritatively to avoid the Start now flow being blocked by a stale activeSession.

### 🧠 Decisions made:

- When canceling a running group from Groups Hub, clear the active session if it matches the canceled group to prevent blocked loadGroup navigation.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Update the 2026-02-25 validation checklist and run validation for Fix 1–7.

# 🔹 Block 471 — Feature backlog workflow prep (25/02/2026)

### ✔ Work completed:

- Added explicit In progress/Done workflow sections to `docs/features/feature_backlog.md`.
- Documented feature tracking rules in `AGENTS.md` to keep backlog items linked to feature folders and commits.

### 🧠 Decisions made:

- Backlog remains canonical; items move to In progress/Done instead of being deleted.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Use the new feature workflow when a backlog item moves to implementation.

# 🔹 Block 472 — Versioning bug/feature docs (25/02/2026)

### ✔ Work completed:

- Updated `.gitignore` to version `docs/bugs` and `docs/features` while ignoring screenshots.
- Clarified in `AGENTS.md` that screenshots stay local but are not tracked in git.

### 🧠 Decisions made:

- Keep bug/feature docs in git for traceability; exclude screenshots to avoid repo bloat.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Commit the doc workflow updates and proceed with validation.

# 🔹 Block 473 — Fix 8: analyzer warnings cleanup (25/02/2026)

### ✔ Work completed:

- Removed unnecessary non-null assertions in Groups Hub card pre-run calculations.
- Avoided using BuildContext across async gaps in Task List logout flow.

### 🧠 Decisions made:

- Keep pre-run calculations explicit to satisfy analyzer and avoid null assertions.
- Capture router before awaits and guard with `mounted` to avoid stale context.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Record the Fix 8 commit hash in the validation plan.

# 🔹 Block 474 — Fix 9 planning: Timer Run Mode bounce (26/02/2026)

### ✔ Work completed:

- Added Fix 9 scope to `docs/bugs/validation_fix_2026_02_25/plan_validacion_rapida_fix.md`.
- Updated `docs/specs.md` to document the short retry window when a just-created group is not found.

### 🧠 Decisions made:

- Treat "group not found" immediately after Start now / Run again / scheduled start as a transient read delay; retry briefly before navigating away.

### ⚠️ Issues found:

- Timer Run Mode can flash briefly then return to Groups Hub; user must tap "Open Run Mode" manually.

### 🎯 Next steps:

- Implement Fix 9 (short retry on group load), run `flutter analyze`, and record commit hash in the plan.

# 🔹 Block 475 — Fix 9: retry group load before leaving Run Mode (26/02/2026)

### ✔ Work completed:

- Added a short retry window when loading a just-created group in Run Mode.
- Cleared scheduled auto-start intent if the group truly does not exist after retries.
- Ran `flutter analyze` (no issues).

### 🧠 Decisions made:

- Treat immediate "group not found" after Start now / Run again / scheduled start as a transient read delay; retry briefly before navigating away.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Record the Fix 9 commit hash in the validation plan and prepare validation steps.

# 🔹 Block 476 — Fix 9 rework: unified Run Mode start pipeline (26/02/2026)

### ✔ Work completed:

- Updated the Fix 9 plan to replace retry-based handling with a unified start pipeline.
- Updated `docs/specs.md` to require a single Run Mode start path with an in-memory snapshot.

### 🧠 Decisions made:

- Remove retry-based behavior in favor of a single authoritative start flow to avoid divergent entry paths.

### ⚠️ Issues found:

- Start now / Run again / scheduled auto-start can bounce back to Groups Hub due to inconsistent entry timing.

### 🎯 Next steps:

- Implement the unified Run Mode start pipeline and remove the retry logic.

# 🔹 Block 477 — Fix 9: unified Run Mode start pipeline implemented (26/02/2026)

### ✔ Work completed:

- Removed retry-based group load handling in Run Mode.
- Added a shared Run Mode launcher to prime the group snapshot and navigate via one entry path.
- Added an in-memory pending group override in the ViewModel to avoid immediate read races.
- Updated Start now / Run again / Open Run Mode / Pre-Run / auto-start to use the shared launcher.
- Adjusted scheduled auto-start navigation to avoid BuildContext async-gap warnings.
- Ran `flutter analyze` (no issues).

### 🧠 Decisions made:

- Use an in-memory snapshot to keep Run Mode entry deterministic across all entry points.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Commit Fix 9 and then record the commit hash in the validation plan.

# 🔹 Block 478 — Fix 10 diagnostics: scheduled auto-start bounce (26/02/2026)

### ✔ Work completed:

- Added targeted Run Mode diagnostic logs for scheduled auto-start flows.
- Instrumented auto-open, scheduled auto-start, and TimerScreen load outcomes to capture route + status.
- Updated validation plan to track the scheduled notice 0 bounce as Fix 10.

### 🧠 Decisions made:

- Use minimal structured logs (`[RunModeDiag]`) to pinpoint route churn without changing behavior.

### ⚠️ Issues found:

- Validation shows scheduled notice 0 still bounces to Groups Hub on Android and macOS.

### 🎯 Next steps:

- Re-run the scheduled notice 0 validation with the new logs and confirm the exact exit path.

# 🔹 Block 479 — Fix 10: stabilize auto-open after scheduled start (26/02/2026)

### ✔ Work completed:

- Adjusted auto-open to mark a group as opened only after confirming `/timer/:id`.
- Reset auto-open state when the route is not `/timer` to allow re-open after a bounce.
- Kept structured diagnostics (`[RunModeDiag]`) for validation.
- Ran `flutter analyze` (no issues).

### 🧠 Decisions made:

- Prevent suppression of auto-open unless the timer route is actually active.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Re-validate Run again (Android) and scheduled notice 0 with the new auto-open gating.

# 🔹 Block 480 — Fix 11: scheduled auto-start navigates before prefetch (26/02/2026)

### ✔ Work completed:

- Moved scheduled auto-start navigation to `/timer/:id` before `getById` to remove the 1–2s Groups Hub delay.
- Kept prefetch/prime after navigation to preserve the in-memory snapshot when available.
- Ran `flutter analyze` (no issues).

### 🧠 Decisions made:

- Navigation must not be blocked by prefetch during scheduled auto-start.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Re-validate scheduled notice 0 on Android and macOS to confirm no Groups Hub flash.

# 🔹 Block 481 — Fix 12: ensure running groups auto-start on initial load (26/02/2026)

### ✔ Work completed:

- Added a running-group auto-start check on initial TimerScreen load (covers Start now / Run again when the stream does not re-emit).
- Centralized running auto-start logic and reused it for stream updates.
- Marked scheduled auto-starts as handled to avoid duplicate start attempts.

### 🧠 Decisions made:

- In Account Mode with a missing activeSession, only the initiating device (scheduledByDeviceId) is allowed to auto-start the running group.
- Avoid relying solely on stream emissions for Start now / Run again auto-start.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Run `flutter analyze`.
- Validate Account Mode Start now / Run again creates `activeSession/current` and stays in Run Mode.

# 🔹 Block 482 — Fix 13: late-start queue claim resilience (26/02/2026)

### ✔ Work completed:

- Hardened late-start queue claim parsing for mixed timestamp formats.
- Added claim failure handling so the queue can still be shown.
- Allowed late-start queue projection to fall back to heartbeat or local time when the anchor is missing.

### 🧠 Decisions made:

- If anchor is missing but conflicts exist, prefer showing the queue (with a fallback timebase) rather than suppressing the flow.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Run `flutter analyze`.
- Re-validate late-start queue cancel-all on macOS + Android.

# 🔹 Block 483 — Fix 14: re-evaluate late-start queue on mode switch (26/02/2026)

### ✔ Work completed:

- Re-evaluated scheduled groups immediately after Local → Account mode switches.
- Removed the late-start queue grace delay so overdue overlaps are always evaluated.

### 🧠 Decisions made:

- Align the mode-switch behavior with the late-start queue trigger rules in `docs/specs.md`.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Run `flutter analyze`.
- Validate late-start queue appears after switching Local → Account without restarting the app.

# 🔹 Block 484 — Temporary iOS debug prod override for simulator validation (27/02/2026)

### ✔ Work completed:

- Documented a temporary iOS debug override in `docs/specs.md` to allow `APP_ENV=prod` with an explicit flag while staging is unavailable.
- Implemented `ALLOW_PROD_IN_DEBUG` (iOS debug only) to permit production Firebase use in debug builds for simulator validation.
- Updated `docs/bugs/README.md` with the iOS simulator debug command and override note.

### 🧠 Decisions made:

- The override is opt-in, iOS-only, and must be removed once staging is configured.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Re-validate iOS simulator login with real accounts using `--debug` + `ALLOW_PROD_IN_DEBUG=true`.

# 🔹 Block 485 — Plan: auto-open trigger gating (27/02/2026)

### ✔ Work completed:

- Updated `docs/specs.md` to define trigger-based auto-open rules and suppression while planning/editing/settings.
- Updated `docs/bugs/validation_fix_2026_02_25/plan_validacion_rapida_fix.md` to add Scope 16 and acceptance criteria for auto-open gating.

### 🧠 Decisions made:

- Auto-open is allowed only on explicit triggers (launch/resume, pre-run start, scheduled start, resolve overlaps, or user action).
- Leaving Run Mode suppresses auto-open until a new trigger occurs.
- Auto-open must never interrupt planning/editing/settings flows.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Implement auto-open gating in `lib/widgets/active_session_auto_opener.dart`.
- Run `flutter analyze`.
- Validate on iOS + Web + Android (no rebound while planning, auto-open still fires on triggers).

# 🔹 Block 486 — Fix 15: auto-open trigger gating (27/02/2026)

### ✔ Work completed:

- Updated `ActiveSessionAutoOpener` to stop re-opening Run Mode on every session tick.
- Added route-sensitive suppression for planning/editing/settings/late-start flows.
- Allowed auto-open again on app resume (explicit trigger).
- Ran `flutter analyze` (no issues).

### 🧠 Decisions made:

- Leaving Run Mode while a session is active suppresses auto-open until a new trigger occurs.
- Auto-open is suppressed on sensitive routes and relies on explicit CTAs there.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Validate auto-open triggers (launch/resume, pre-run start, scheduled start) across iOS/Web/Android.
- Confirm no re-open while planning or editing.

# 🔹 Block 487 — Plan: iOS scheduled notice 0 black screen (28/02/2026)

### ✔ Work completed:

- Updated `docs/bugs/validation_fix_2026_02_25/plan_validacion_rapida_fix.md` to add Scope 17 and fix order for the iOS black screen issue.

### 🧠 Decisions made:

- Address the iOS black screen before Local Mode fixes to minimize regressions and keep changes localized.
- Treat the fix as a navigation stability issue: always land on Run Mode or a valid hub route after confirm.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Review iOS/Chrome logs for the black screen repro path.
- Implement the minimal navigation fallback to prevent black screens.
- Run `flutter analyze` and validate on iOS + Web.

# 🔹 Block 488 — Fix 16: avoid iOS black screen on scheduled notice 0 (28/02/2026)

### ✔ Work completed:

- Guarded `TimerScreen` timers and async loads against dispose to prevent setState/ref usage after unmount.
- Moved completion-dialog visibility reset to `deactivate` and removed ref usage in `dispose`.
- Ran `flutter analyze` (no issues).

### 🧠 Decisions made:

- Treat the iOS black screen as a lifecycle/navigation safety issue (avoid async work on unmounted state).
- Prefer minimal guards and lifecycle-safe cleanup over navigation rewrites.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Reproduce scheduled notice 0 on iOS to confirm no black screen and no console exceptions.

# 🔹 Block 489 — Plan: Local Mode isolation + Run Mode stability (28/02/2026)

### ✔ Work completed:

- Updated `docs/specs.md` to require clearing Run Mode and returning to Task List on mode switch.
- Updated `docs/bugs/validation_fix_2026_02_25/plan_validacion_rapida_fix.md` with Fix 17 scope, repro, and acceptance criteria.

### 🧠 Decisions made:

- Local Mode Start now must persist `actualStartTime` to enable correct projection and avoid Run Mode restarts.
- Scheduled auto-open must not navigate to `/timer/:id` in Local Mode if the group is missing.
- Mode switching should reset Run Mode state and land on Task List to prevent cross-mode UI/data bleed.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Implement Local Mode fixes (Start now `actualStartTime`, mode-switch guard, local auto-open gating).
- Run `flutter analyze`.
- Validate Local Mode repro steps and update checklist.

# 🔹 Block 490 — Fix 17: Local Mode isolation + Run Mode stability (28/02/2026)

### ✔ Work completed:

- Set `actualStartTime` for Start now groups created from Task List to preserve Local Mode projections.
- Added `AppModeChangeGuard` to reset Run Mode state and return to Task List on mode switch.
- Guarded scheduled auto-open in Local Mode by skipping navigation when the group is missing.
- Ran `flutter analyze` (no issues).

### 🧠 Decisions made:

- Mode switches must hard-reset Run Mode to prevent cross-mode UI/data bleed.
- Local scheduled auto-open should be a no-op when the group is missing to avoid false snackbars.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Validate Local Mode repro steps and update the checklist.

# 🔹 Block 491 — Fix 17 validation results (28/02/2026)

### ✔ Work completed:

- Ran Local Mode validation using the exact repro steps.
- Logged results in `docs/bugs/validation_fix_2026_02_25/quick_pass_checklist.md`.

### 🧠 Decisions made:

- Treat remaining Local Mode issues as follow-up fixes (Open Run Mode restarts group; Run Mode vs Groups Hub ranges mismatch).

### ⚠️ Issues found:

- Local Mode (Chrome): "Open Run Mode" restarts the running group each time.
- Local Mode (Chrome): Run Mode task ranges do not match Groups Hub "Ends" after the restart.

### 🎯 Next steps:

- Fix Local Mode Run Mode restart on open (ensure re-open does not reset task start).
- Align Run Mode ranges with Groups Hub after re-open.

# 🔹 Block 492 — Plan: Local Mode Run Mode re-open stability (28/02/2026)

### ✔ Work completed:

- Updated `docs/bugs/validation_fix_2026_02_25/plan_validacion_rapida_fix.md` with Fix 18 scope, repro, and acceptance criteria.

### 🧠 Decisions made:

- In Local Mode, re-opening a running group must never auto-start if `actualStartTime` already exists; use projection instead.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Implement the Local Mode auto-start guard in Run Mode.
- Run `flutter analyze`.
- Validate Fix 18 repro steps.

# 🔹 Block 493 — Fix 18: Local Mode Run Mode re-open stability (28/02/2026)

### ✔ Work completed:

- Prevented Local Mode auto-start when a running group already has `actualStartTime` to avoid restart on re-open.
- Ran `flutter analyze` (no issues).

### 🧠 Decisions made:

- Local Mode re-open should always project from `actualStartTime` rather than re-creating the timer state.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Validate Fix 18 repro steps (Open Run Mode does not restart; ranges match).

# 🔹 Block 494 — Fix 18 validation results (28/02/2026)

### ✔ Work completed:

- Validated Fix 18 with Local Mode re-open repro; Open Run Mode no longer restarts the group.
- Updated `docs/bugs/validation_fix_2026_02_25/quick_pass_checklist.md` with results.

### 🧠 Decisions made:

- Confirmed Local Mode re-open should always project from `actualStartTime`.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Continue with the next remaining validation items in the plan.

# 🔹 Block 495 — Regression smoke checks requirement (28/02/2026)

### ✔ Work completed:

- Added a mandatory regression smoke check requirement to `AGENTS.md`.
- Added a fixed regression checklist to `docs/bugs/validation_fix_2026_02_25/plan_validacion_rapida_fix.md` and `quick_pass_checklist.md`.

### 🧠 Decisions made:

- Each fix must re-validate the most recent critical fixes to prevent silent regressions.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Apply the regression checklist after every subsequent fix in this validation track.

# 🔹 Block 496 — Regression checks validated (28/02/2026)

### ✔ Work completed:

- Executed regression smoke checks after Fix 18.
- Logged results in `docs/bugs/validation_fix_2026_02_25/quick_pass_checklist.md`.

### 🧠 Decisions made:

- Regression checks are required for every fix and must be recorded.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Continue with the next fix in the plan.

# 🔹 Block 497 — Plan: Fix 19 status box ranges after pause (28/02/2026)

### ✔ Work completed:

- Updated `docs/bugs/validation_fix_2026_02_25/plan_validacion_rapida_fix.md` with Fix 19 scope and exact repro.

### 🧠 Decisions made:

- Preserve `phaseStartedAt` across pause/resume so status boxes keep the original phase start and extend the end by the pause duration.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Implement the pause/resume guard in `PomodoroViewModel.resume()`.
- Run `flutter analyze`.
- Validate Fix 19 repro steps and regression checks.

# 🔹 Block 498 — Fix 19: preserve phase start on resume (28/02/2026)

### ✔ Work completed:

- Kept `phaseStartedAt` stable across pause/resume to avoid shifting status box ranges.
- Ran `flutter analyze` (no issues).

### 🧠 Decisions made:

- Pause/resume must extend phase end time without moving its original start.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Validate Fix 19 repro steps and regression checks.

# 🔹 Block 499 — Plan: Fix 20 mirror initial sync drift (28/02/2026)

### ✔ Work completed:

- Updated `docs/specs.md` with a fallback offset rule when `lastUpdatedAt` is missing.
- Added Fix 20 scope + exact repro to `docs/bugs/validation_fix_2026_02_25/plan_validacion_rapida_fix.md`.

### 🧠 Decisions made:

- When `lastUpdatedAt` is missing, derive an initial anchor using
  `phaseStartedAt + (phaseDurationSeconds - remainingSeconds)` to avoid a stale mirror start.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Implement fallback offset derivation in `PomodoroViewModel`.
- Run `flutter analyze`.
- Validate Fix 20 repro steps and regression checks.

# 🔹 Block 500 — Fix 20: mirror initial sync (28/02/2026)

### ✔ Work completed:

- Added a fallback offset derivation when `lastUpdatedAt` is missing to avoid mirror drift.
- Ran `flutter analyze` (no issues).

### 🧠 Decisions made:

- Use `phaseStartedAt + (phaseDurationSeconds - remainingSeconds)` as the initial anchor when no offset exists.

### ⚠️ Issues found:

_(pending validation)_

### 🎯 Next steps:

- Validate Fix 20 repro steps and regression checks.

# 🔹 Block 501 — Fix 20 validation failed; plan Fix 21 (28/02/2026)

### ✔ Work completed:

- Confirmed Fix 20 still fails when `lastUpdatedAt` is stale after mirror resume.
- Updated validation plan/checklist to track the failed Fix 20 and a new Fix 21.
- Updated specs/roadmap to include stale snapshot compensation for mirror projections.

### 🧠 Decisions made:

- Mirror devices must compensate stale `lastUpdatedAt` **only when running** by
  advancing the projection with the local delta, then re-anchor on the next snapshot.
- No compensation when paused or non-running to avoid time drift.

### ⚠️ Issues found:

- Mirror still starts behind after resume/Local→Account until the next heartbeat.

### 🎯 Next steps:

- Implement Fix 21 in `PomodoroViewModel`.
- Run `flutter analyze`.
- Re-validate Fix 21 repro steps and regression checks.

# 🔹 Block 502 — Fix 21 attempt regressed; revise compensation strategy (28/02/2026)

### ✔ Work completed:

- Captured Fix 21 validation failure (mirror countdown accelerates; >1s per tick).
- Updated checklist/plan with the regression details.
- Revised the approach: rebase the offset once instead of adding delta per tick.

### 🧠 Decisions made:

- Stale mirror compensation must **not** add a delta each tick.
- When the snapshot is stale and mirror is running, hold the existing offset
  (or set it to zero if missing) and wait for the next snapshot to re-anchor.

### ⚠️ Issues found:

- Attempted compensation caused mirror to tick ~2s per second until next snapshot.

### 🎯 Next steps:

- Apply the revised offset-rebase logic.
- Run `flutter analyze`.
- Re-validate Fix 21 + regression checks.

# 🔹 Block 503 — Fix 21 attempt 2 failed; switch to fresh-snapshot gating (28/02/2026)

### ✔ Work completed:

- Logged the new failure: owner/mirror desync persists after Local ↔ Account switches.
- Updated plan/checklist/specs to pivot to fresh-snapshot gating.
- Implemented fresh-snapshot gating in `PomodoroViewModel`.
- Ran `flutter analyze` (no issues).

### 🧠 Decisions made:

- Stop using age-based compensation; instead gate projections on a **new**
  `lastUpdatedAt` after resume/mode switch.
- While waiting for a new snapshot, project from local time (no server offset).

### ⚠️ Issues found:

- Owner returned from Local with ~24s lag; drift persisted despite `lastUpdatedAt` updates.
- First cancel action forced a resync but did not cancel (second cancel required).

# 🔹 Block 504 — Fix 21 attempt 3 failed (28/02/2026)

### ✔ Work completed:

- Logged the latest validation: iOS owner + Chrome mirror still desync after Local ↔ Account.
- Noted that Chrome logs remain incomplete post-launch.

### ⚠️ Issues found:

- Fresh-snapshot gating did not prevent desync on iOS owner resume.
- Chrome mirror still fails after Local → Account.

### 🎯 Next steps:

- Revisit the sync/offset strategy with explicit server timestamp anchoring.

# 🔹 Block 505 — P0 plan: single source of truth for Run Mode (28/02/2026)

### ✔ Work completed:

- Documented the P0 plan to enforce a single authoritative timeline for Run Mode.
- Updated specs/roadmap/validation plan to add time sync, sessionRevision, and paused offsets.

### 🧠 Decisions made:

- Account Mode projection must derive **only** from the authoritative timeline
  (`phaseStartedAt`, `phaseDurationSeconds`, `pausedAt`, `accumulatedPausedSeconds`)
  and a real server time offset (timeSync).
- `lastUpdatedAt` is liveness-only; it must not drive projection.
- Snapshots must be ordered by `sessionRevision` (ignore stale updates).

### ⚠️ Issues found:

- Existing offset-based approaches (lastUpdatedAt derived) continue to diverge.

### 🎯 Next steps:

- Draft the implementation plan for Fix 22 (single source of truth).

# 🔹 Block 506 — Fix 22 implementation plan drafted (28/02/2026)

### ✔ Work completed:

- Added the Fix 22 implementation plan (time sync + sessionRevision + paused offsets) to the validation plan.

### 🎯 Next steps:

- Review the Fix 22 plan and confirm before code changes.

### 🎯 Next steps:

- Re-validate Fix 21 + regression checks.

# 🔹 Block 507 — Fix 22 implementation started (28/02/2026)

### ✔ Work completed:

- Implemented TimeSyncService (server timestamp offset) + provider wiring.
- Added `sessionRevision` and `accumulatedPausedSeconds` to PomodoroSession.
- Updated Firestore rules for `users/{uid}/timeSync`.
- Refactored PomodoroViewModel projection to use server time + revision ordering
  (lastUpdatedAt is ordering-only).
- Updated scheduled auto-start + late-start queue initial session fields.
- Updated VM tests to include new session fields and disable time sync in tests.
- Ran `flutter test` (pause expiry, ownership request, session gap, scheduled coordinator) and `flutter analyze`.
- Commit: 5289922 "Fix 22: time sync single-source projection".

### 🧠 Decisions made:

- Projections must derive only from `serverNow`, `phaseStartedAt`,
  `pausedAt`, and `accumulatedPausedSeconds`.
- Accept snapshots by `sessionRevision`; use `lastUpdatedAt` only as a
  secondary order tie-breaker.

### ⚠️ Issues found:

- None during implementation (validation still pending).

### 🎯 Next steps:

- Run `tools/check_release_safety.sh` (Firestore schema/rules touched).
- Complete validation scenarios for Fix 22 (owner/mirror, pause/resume,
  background, Local → Account).
- Commit Fix 22 after validation + plan updates.

# 🔹 Block 508 — Firestore rules deployed + TimerScreen spec alignment (28/02/2026)

### ✔ Work completed:

- Deployed updated Firestore rules (timeSync path) to PROD project `focus-interval`.
- Updated `docs/specs.md` 10.4.8 to reference timeSync-based projection and Syncing session fallback.

### 🧠 Decisions made:

- Keep `lastUpdatedAt` as liveness only; TimerScreen spec now aligns with timeSync.

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Validate Fix 22 scenarios (owner/mirror, pause/resume, background, Local → Account).

# 🔹 Block 509 — Fix 22 P0-1: stale snapshot guard (01/03/2026)

### ✔ Work completed:

- Prevented stale activeSession snapshots from updating session counters when the
  timeline should not be applied (ignore outdated revision updates).
- Logged Fix 22 P0-1 in the validation plan.

### 🧪 Tests:

- Not run (Flutter test requires sandbox approval).

### ⚠️ Issues found:

- None during implementation (validation pending).

### 🎯 Next steps:

- Implement P0-2: timeSync gating + intent queue + non-blocking syncing overlay.

# 🔹 Block 510 — Fix 22 P0-2: timeSync gating + intent queue (01/03/2026)

### ✔ Work completed:

- Added timeSync gating for Start/Resume/Auto-start in Account Mode with a
  pending intent queue.
- Added a non-blocking Syncing overlay (timer stays visible) and retry state
  when time sync stalls.
- Auto-start now waits for server time; no local fallback when time sync is
  unavailable.

### 🧪 Tests:

- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/viewmodels/scheduled_group_coordinator_test.dart` (passed)

### ⚠️ Issues found:

- None during implementation (validation pending).

### 🎯 Next steps:

- Implement P0-3: render Run Mode from activeSession projection for owner and mirror.

# 🔹 Block 511 — Fix 22 P0-2b: block publish without timeSync (01/03/2026)

### ✔ Work completed:

- Blocked session publish (including heartbeats) in Account Mode when timeSync is
  unavailable; trigger refresh and mark syncing instead of writing local time.
- Overlay now appears **only** when a snapshot exists; otherwise a full loader is
  shown even if there is a pending intent.

### 🧪 Tests:

- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/viewmodels/scheduled_group_coordinator_test.dart` (passed)

### ⚠️ Issues found:

- None during implementation (validation pending).

### 🎯 Next steps:

- Implement P0-3: render Run Mode from activeSession projection for owner and mirror.

# 🔹 Block 512 — Fix 22 P0-2b: add guardrail tests (01/03/2026)

### ✔ Work completed:

- Added widget test to enforce UI rule: pending intent + no snapshot shows full
  loader (no timer visible).
- Added VM test to ensure Account Mode with missing timeSync does not publish
  activeSession and forces a refresh.

### 🧪 Tests:

- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart` (passed)

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Implement P0-3: render Run Mode from activeSession projection for owner and mirror.

# 🔹 Block 513 — Spec clarification: no writes without timeSync (01/03/2026)

### ✔ Work completed:

- Clarified in specs that, in Account Mode, **no** authoritative writes are
  allowed when server-time offset is unavailable (includes start/resume/auto-start,
  heartbeats, and republish/recovery writes).
- Clarified that heartbeat requirements apply only when time sync is ready.

### 🧪 Tests:

- Not applicable (documentation update).

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Implement P0-3: render Run Mode from activeSession projection for owner and mirror.

# 🔹 Block 514 — Fix 22 P0-3: render from activeSession (owner + mirror) (01/03/2026)

### ✔ Work completed:

- In Account Mode, ignored PomodoroMachine stream updates when an activeSession
  is present, missing, or awaiting confirmation (preventing local render drift).
- Unified owner + mirror rendering from activeSession projection with a shared
  projection timer (no machine-driven UI in Account Mode).
- Added “awaiting session confirmation” gating after owner start/pause/resume
  (syncing hold until snapshot arrives; controls disabled).
- TimerScreen now treats “awaiting session confirmation” as syncing (overlay
  only when a snapshot exists).
- Added regression test to ensure machine stream does not override state when
  an activeSession is present.

### 🧪 Tests:

- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart` (passed)

### ⚠️ Issues found:

- None during implementation (validation pending).

### 🎯 Next steps:

- P0-3 validation (multi-device scenarios).
- Continue with P0-4: monotonic guard in repo/rules + write ordering.

# 🔹 Block 515 — Fix 22 P0-4: monotonic guard + write serialization (01/03/2026)

### ✔ Work completed:

- Added monotonic sessionRevision guard in Firestore session repository
  (incoming < current ignored; equal treated as idempotent heartbeat).
- Added session write serialization in VM; queued publishes drop obsolete
  writes by revision/context/ownership before sending.
- Added Firestore rules enforcing monotonic sessionRevision (legacy allowed only
  when the stored document lacks the field).
- Added unit tests for the session write decision logic.

### 🧪 Tests:

- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart test/data/repositories/firestore_pomodoro_session_repository_test.dart` (passed)

### ⚠️ Issues found:

- None during implementation (validation pending).

### 🎯 Next steps:

- P0-4 validation (multi-device).
- Continue with P0-5: discard obsolete queued writes on session/context changes.

# 🔹 Block 516 — Firestore rules deployed (prod) (01/03/2026)

### ✔ Work completed:

- Deployed `firestore.rules` to production via `firebase deploy --only firestore:rules`.

### 🧪 Tests:

- Not applicable.

### ⚠️ Issues found:

- CLI warning: `firebase.json` contains unknown property `flutter` (non-blocking).

### 🎯 Next steps:

- Validate P0-4 on prod rules.

# \ud83d\udd39 Block 517 — Roll back activeSession rules to pre-P0-4 (01/03/2026)

### \u2714 Work completed:

- Reverted `activeSession` Firestore rules to pre-P0-4 permissive version
  (same as commit `2c788c3`) after permission-denied errors in validation.
- Redeployed rules to prod (`firebase deploy --only firestore:rules`).

### \ud83e\uddea Tests:

- Not applicable.

### \u26a0\ufe0f Issues found:

- Validation logs showed `[cloud_firestore/permission-denied]` on auto-start
  (`2026_03_01_ios_simulator_iphone_17_pro_diag.log`).

### \ud83c\udfaf Next steps:

- Re-run P0-4 validation after rules rollback.
- Design a backward-compatible monotonic rules variant before reintroducing it.

# 🔹 Block 518 — Fix 22g: auto-open bounce guard + pause persistence + safe nav (01/03/2026)

### ✔ Work completed:

- Added a short auto-open bounce window to re-open TimerScreen only when a
  session falls back to `/groups` shortly after auto-open, without re-enabling
  intrusive auto-open on sensitive routes.
- Made TimerScreen navigation to Groups Hub post-frame to avoid
  `setState/markNeedsBuild during build` Router errors.
- Resume now falls back to `session.pausedAt` when local `_pauseStartedAt`
  is missing, and awaits pause offset persistence to prevent early end.
- Group timeline projection no longer shifts task start by pause offset.
- Enriched activeSession debug snapshot log with pause fields.

### 🧪 Tests:

- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart` (passed)

### ⚠️ Issues found:

- Validation pending (P0-4 regressions: bounce to Groups Hub, pause not applied,
  status box start shift, iOS setState during build).

### 🎯 Next steps:

- Run targeted tests (timer screen + viewmodel) and revalidate multi-device.

# 🔹 Block 519 — Fix 22g validation failed (01/03/2026)

### ✔ Work completed:

- Validation run started for Fix 22g using Android + iOS logs.

### 🧪 Tests:

- Not applicable.

### ⚠️ Issues found:

- Scheduled auto-start (notice 0) fails: iOS stuck on “Syncing session…” with black background; Run Mode never opens.
- Firestore `activeSession/current` ends in `status=finished` with `remainingSeconds=0` and `phaseStartedAt=null`.
- Remaining checklist steps could not be validated due to the block.

### 🎯 Next steps:

- Investigate why scheduled auto-start produces a finished activeSession.
- Validate auto-start path against timeSync/sessionRevision gating.

# 🔹 Block 520 — Fix 22h: clear inactive activeSession in VM + repo (01/03/2026)

### ✔ Work completed:

- Treat non-active activeSession snapshots (finished/canceled/idle) as null in
  PomodoroViewModel; avoid storing them as `_latestSession`.
- Added Firestore repository cleanup: `clearSessionIfInactive` deletes the doc
  only when server status is not active (transactional guard).
- Completion/cancel now clear activeSession regardless of control gating and
  also trigger inactive cleanup for the current group.
- Updated PomodoroSessionRepository fakes in tests to match the new interface.

### 🧪 Tests:

- Not run (pending validation).

### ⚠️ Issues found:

- Validation pending.

### 🎯 Next steps:

- Re-run the validation checklist (owner/mirror + auto-start).
- If passed, record commit hash and update plan/checklist.

# 🔹 Block 521 — Fix 22h validation (01/03/2026)

### ✔ Work completed:

- Validation run on Android + iOS with logs:
  `2026_03_01_android_RMX3771_diag-0.log`,
  `2026_03_01_ios_simulator_iphone_17_pro_diag-0.log`.

### 🧪 Tests:

- Not applicable.

### ⚠️ Issues found:

- A `current` session reappears on app open and starts running without user action; it finishes unexpectedly and does not appear in Groups Hub.
- Pre-run does not auto-open; stays in Groups Hub with banner until user taps “Open Pre-Run”.
- Owner stays in “Syncing session…” after auto-start for minutes; only resolves after navigating away (Groups Hub) and returning.
- Auto-start succeeds on second attempt; cancel clears `activeSession/current`; mirror sync is OK.

### 🎯 Next steps:

- Investigate phantom auto-start on app open (stale group rehydration vs auto-start trigger).
- Fix pre-run auto-open behavior and eliminate long “Syncing session…” holds for owner.

# 🔹 Block 522 — Fix 22i: auto-start throttle + missing-session recovery + nav retry (01/03/2026)

### ✔ Work completed:

- Added auto-start throttling in PomodoroViewModel to prevent duplicate
  `startFromAutoStart` calls for the same group in a short window.
- When activeSession goes missing, keep a projected state from the last known
  session and force a server resync to reduce prolonged “Syncing session…”.
- Scheduled auto-start navigation now verifies route change and retries if the
  app fails to land on `/timer/:groupId`.

### 🧪 Tests:

- Not run.

### ⚠️ Issues found:

- None during validation.

### ✅ Validation (Fix 22i)

- Logs: `2026_03_01_android_RMX3771_diag-1.log`,
  `2026_03_01_ios_simulator_iphone_17_pro_diag-1.log`.
- Auto-start duplicate (phantom running): OK.
- Pre-run auto-open: OK.
- Auto-start to Run Mode: OK (no bounce to Groups Hub).
- Syncing session: only brief flicker, no prolonged hold.
- Cancel cleanup: OK (current cleared).
- Mirror: OK (no permanent syncing on open).

### 🎯 Next steps:

- Commit: fb582f6 "Fix 22i: auto-start throttle + missing-session recovery".

# 🔹 Block 523 — Allow prod debug override on all platforms (02/03/2026)

### ✔ Work completed:

- Updated specs to allow a temporary `ALLOW_PROD_IN_DEBUG=true` override for
  `APP_ENV=prod` in debug on all platforms (temporary until staging exists).
- Removed platform restriction in `AppConfig` so the override works on web,
  macOS, and other targets in debug.
- Updated bug validation docs and added a new validation folder for this fix.
- Cleaned a test analyzer lint (prefer_final_fields).

### 🧪 Tests:

- `flutter analyze` (passed).

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Validate debug + prod boot on Chrome and macOS with
  `ALLOW_PROD_IN_DEBUG=true`.
- Revert the override once staging is configured and in use.

# 🔹 Block 524 — Update bug log commands for debug prod override (02/03/2026)

### ✔ Work completed:

- Expanded `docs/bugs/README.md` with debug + prod commands (override) for all
  supported platforms, keeping release commands available.
- Added explicit "temporal" labeling for the override in the command sections.

### 🧪 Tests:

- Not applicable (docs-only change).

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Use the debug + prod commands with `ALLOW_PROD_IN_DEBUG=true` until staging exists.
- Revert the override commands once staging is configured.

# 🔹 Block 525 — Reset to P0-3 baseline + re-apply notice features (05/03/2026)

### ✔ Work completed:

- Reset the branch to `2c788c3` (Fix 22 P0-3 validation baseline) to remove
  post‑P0‑3 regressions.
- Cherry-picked the Plan Group notice control features:
  - `7bb19a3` (notice picker flow)
  - `856c356` (re-plan notice coherence)
  - `ddcf0ba` (auto-clamp SnackBar)
- Cherry-picked debug-prod override support:
  - `d5e08ae` (allow prod in debug)
  - `cf2e722` (debug prod log commands)
- Resolved cherry-pick conflicts by taking incoming feature versions of
  `groups_hub_screen.dart` and `task_group_planning_screen.dart`.
- Updated Task List planning flow to pass `initialNoticeMinutes`.

### 🧪 Tests:

- `flutter analyze`

### ⚠️ Issues found:

- Validation pending after rollback (pause syncing and other regressions to
  be re-checked under the restored baseline).

### 🎯 Next steps:

- Re-run the pause repro on the restored baseline and confirm whether the
  prolonged "Syncing session" still occurs.

# 🔹 Block 526 — Pause syncing regression resolved after rollback (05/03/2026)

### ✔ Work completed:

- Validated the pause flow after the rollback to `2c788c3` baseline with the
  re-applied Plan Group notice features + debug prod override.
- User confirmed the prolonged "Syncing session" no longer reproduces.

### 🧪 Tests:

- Manual validation (no logs captured for this pass).

### ⚠️ Issues found:

- None reported in the pause flow after rollback.

### 🎯 Next steps:

- Continue remaining validations on this restored baseline.

# 🔹 Block 527 — Keep backup branch for reference (05/03/2026)

### ✔ Work completed:

- Kept `backup_pre_reset_2026_03_05` as a reference branch to preserve prior
  implementations during the next validation cycle.

### 🧪 Tests:

- Not applicable.

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Remove the backup branch once the next validation pass is fully closed.

# 🔹 Block 528 — Revalidation post-rollback findings (05/03/2026)

### ✔ Work completed:

- Re-validated key items after rollback to `2c788c3` baseline.
- Organized new screenshots into per-bug folders under
  `docs/bugs/validation_fix_2026_02_25/screenshots/`.

### 🧪 Tests:

- Manual validation (iOS owner, Chrome mirror).

### ⚠️ Issues found:

- Pre-run notice clamp does not apply to the planned group: snackbar reduces the
  notice but confirm still fails with “That start time is too soon...”.
- Owner adds paused time once after leaving and re-entering Timer Run
  (timer jumps backward on first return).
- Resolve overlaps appears without a real conflict after Local → Account;
  Request ownership does not reach the owner and ownership flips automatically.

### 🎯 Next steps:

- Document and prioritize reintroduced issues in the 2026-02-25 validation plan.
- Re-run targeted repros with logs for additional observations reported today.

# 🔹 Block 529 — Move 05/03 revalidation evidence into new validation folder (05/03/2026)

### ✔ Work completed:

- Created `docs/bugs/validation_fix_2026_03_05/plan_validacion_rapida_fix.md` and
  `docs/bugs/validation_fix_2026_03_05/quick_pass_checklist.md`.
- Moved 05/03 screenshots into `docs/bugs/validation_fix_2026_03_05/screenshots/`
  (notice clamp, owner pause jump, overlaps false conflict, other observations).
- Moved 05/03 logs into `docs/bugs/validation_fix_2026_03_05/logs/`.
- Removed the 05/03 revalidation sections from the 02/25 plan and checklist to
  keep validations isolated by date.

### 🧪 Tests:

- Not applicable (docs organization only).

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Proceed with Fixes 23–25 under the 2026-03-05 validation folder.

# 🔹 Block 530 — Specs update for notice auto-clamp + global action (05/03/2026)

### ✔ Work completed:

- Updated `docs/specs.md` to define notice auto-clamp behavior when the scheduled
  start is too soon, including the snackbar with an action to apply the effective
  notice to the global default.
- Added the +1 minute rule between a group’s end and the next group’s pre-run start.
- Clarified global vs per-group notice behavior in the Pre-Run notice section.
- Updated `docs/bugs/validation_fix_2026_03_05/plan_validacion_rapida_fix.md`
  with the snackbar + global action requirement.

### 🧪 Tests:

- Not applicable (docs-only update).

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Implement Fix 23 in code using `planningResult.noticeMinutes` for validation and
  group creation, and wire the snackbar action to optionally update the global notice.

# 🔹 Block 531 — Fix 23 notice clamp + global action (code) (05/03/2026)

### ✔ Work completed:

- Task List: use `planningResult.noticeMinutes` for validation and group creation.
- Added clamp snackbar with “Apply globally” action and global notice explanation.
- Groups Hub re-plan: fetch global notice once, keep clamped notice, and show
  the same clamp snackbar with global action.
- Global notice action now updates the Pre-run notice provider so Settings
  reflects the new value immediately.

### 🧪 Tests:

- `flutter analyze`

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Run Fix 23 validation in `docs/bugs/validation_fix_2026_03_05/quick_pass_checklist.md`.
- Update the plan with commit hash once validation passes.

# 🔹 Block 532 — Notice clamp UX refinement + log alignment (05/03/2026)

### ✔ Work completed:

- Made the notice auto-clamp snackbar non-dismissible until OK; “Don’t show again” remains available and the info line persists in the card.
- Moved pause-syncing logs into the 2026-03-05 validation folder to keep evidence aligned with the correct date.

### 🧪 Tests:

- `flutter analyze`

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Re-run Fix 23 validation in `docs/bugs/validation_fix_2026_03_05/quick_pass_checklist.md`.
- Update the plan with the new commit hash once validation passes.

# 🔹 Block 533 — Fix notice clamp snackbar controls + live text (05/03/2026)

### ✔ Work completed:

- Notice clamp snackbar now renders checkbox + OK, is non-dismissible, and updates its message live while visible.
- Snackbar hides properly on OK and respects “Don’t show again”.

### 🧪 Tests:

- `flutter analyze`

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Re-run the Fix 23 validation flow (auto-clamp + apply global) and record results in the 2026-03-05 checklist.

# 🔹 Block 534 — Notice clamp snackbar visibility fix (05/03/2026)

### ✔ Work completed:

- Ensured the notice clamp snackbar renders its checkbox + OK controls visibly on web/mobile.
- Snackbar text now stops showing when the scheduled start is in the past.
- Updated checkbox styling to use WidgetStateProperty and current Flutter color APIs.

### 🧪 Tests:

- `flutter analyze`

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Re-validate the notice clamp flow in Plan group (Chrome + iOS) and confirm controls are visible.

# 🔹 Block 535 — Auto-update passed schedule + responsive notice clamp banner (06/03/2026)

### ✔ Work completed:

- Added auto-update for past scheduled starts: shifts start to now (minute floor) and forces pre-run to 0m.
- Added a clear “start auto-adjusted” message in Plan group when the schedule is corrected.
- Made the notice clamp snackbar responsive (floating + margin/padding) so checkbox/OK are always visible.

### 🧪 Tests:

- `flutter analyze`

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Re-validate Fix 23 with the new auto-update behavior and snackbar visibility on iOS + Chrome.

# 🔹 Block 536 — SnackBar color alignment + AGENTS hygiene updates (06/03/2026)

### ✔ Work completed:

- Aligned the notice clamp snackbar to the app’s light snackbar style (white background, dark text).
- Added a Feature Backlog idea for global SnackBar theming and unified UI messaging.
- Updated AGENTS.md with daily specs hygiene and code quality / UI consistency rules.

### 🧪 Tests:

- Not run (UI styling change + doc updates only).

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Re-validate the notice clamp snackbar visuals and controls on iOS + Chrome.

# 🔹 Block 537 — Feature backlog entry for i18n foundation (06/03/2026)

### ✔ Work completed:

- Added `IDEA-036 — Runtime Internationalization (l10n) Foundation` to
  `docs/features/feature_backlog.md`.
- Updated the recommended execution order with IDEA-036.

### 🧪 Tests:

- Not applicable (documentation update only).

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Start docs-first implementation planning for IDEA-036 (l10n infrastructure and phased migration).

# 🔹 Block 538 — Reprioritize IDEA-036 to execution slot #1 (06/03/2026)

### ✔ Work completed:

- Reordered `docs/features/feature_backlog.md` recommended execution list to place
  `IDEA-036 — Runtime Internationalization (l10n) Foundation` at position #1.
- Updated the section header date for recommended execution order to `06/03/2026`.

### 🧪 Tests:

- Not applicable (documentation update only).

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Keep fixes in progress on the active bug-validation branch.
- Start `IDEA-036` only after current critical sync fixes are validated and closed.

# 🔹 Block 539 — Fix notice clamp banner action visibility (06/03/2026)

### ✔ Work completed:

- Fixed the persistent notice-clamp snackbar layout so `OK` is always visible.
- Kept `Don't show again` interactive across web/mobile by making the whole row tappable.
- Preserved current behavior: snackbar auto-hides when the selected start is no longer valid.

### 🧪 Tests:

- `flutter analyze`

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Re-validate Fix 23 UX flow (notice clamp + global apply + persistent banner controls).

# 🔹 Block 540 — Set execution gate before new feature work (06/03/2026)

### ✔ Work completed:

- Added an explicit execution gate to
  `docs/bugs/validation_fix_2026_03_05/plan_validacion_rapida_fix.md`:
  no new feature work until Fix 24 + Fix 25 are validated and regression checks pass.
- Added the same gate note to
  `docs/bugs/validation_fix_2026_03_05/quick_pass_checklist.md`.
- Updated `docs/roadmap.md` global status notes to reflect the active gate.

### 🧪 Tests:

- Not applicable (documentation update only).

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Implement Fix 24 next (owner pause re-entry jump), then run required regression checks.

# 🔹 Block 541 — Enforce automatic fix closure policy (06/03/2026)

### ✔ Work completed:

- Added a mandatory rule in `AGENTS.md`:
  if a fix has Exact Repro PASS + Regression checks PASS + evidence recorded,
  it must be marked `Closed/OK` automatically (no extra confirmation request).
- Added the same closure rule to `docs/bugs/README.md`.
- Added the closure rule to:
  - `docs/bugs/validation_fix_2026_03_05/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_fix_2026_03_05/quick_pass_checklist.md`

### 🧪 Tests:

- Not applicable (documentation/policy updates only).

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Apply this rule consistently while closing Fix 23/24/25 validations.

# 🔹 Block 542 — Close Fix 23 (notice clamp) in validation docs (06/03/2026)

### ✔ Work completed:

- Closed Fix 23 as **OK** in:
  - `docs/bugs/validation_fix_2026_03_05/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_fix_2026_03_05/quick_pass_checklist.md`
- Updated Fix 23 status with:
  - code commit reference (`a884c94`),
  - PASS result,
  - regression smoke checks PASS.
- Updated `docs/roadmap.md` with explicit note that Fix 23 is validated/closed.

### 🧪 Tests:

- Not run (documentation closure update based on completed validation evidence).

### ⚠️ Issues found:

- Fix 24 and Fix 25 remain open and keep the feature execution gate active.

### 🎯 Next steps:

- Implement and validate Fix 24.

# 🔹 Block 543 — Fix 24 candidate in isolated branch (06/03/2026)

### ✔ Work completed:

- Created isolated branch `fix24-owner-pause-reentry-jump` to test Fix 24
  without risking the active branch.
- Implemented two guarded changes in
  `lib/presentation/viewmodels/pomodoro_view_model.dart`:
  - Owner hydration now pins `_localPhaseStartedAt` from
    `session.phaseStartedAt` for running and paused session states.
  - Owner hydration skips `_applyGroupTimelineProjection(...)` in Account Mode.
- Updated `docs/bugs/validation_fix_2026_03_05/plan_validacion_rapida_fix.md`
  with Fix 24 code status (validation pending).

### 🧪 Tests:

- `flutter analyze` (pass).

### ⚠️ Issues found:

- Behavior validation still pending (Exact Repro + regression smoke checks).

### 🎯 Next steps:

- Run Fix 24 validation on owner iOS + mirror Chrome.

# 🔹 Block 544 — Fix 26 validated and closed (06/03/2026)

### ✔ Work completed:

- Commit: `bdb89ad` — `fix: harden missing-session recovery and close fix26 validation`.
- Closed Fix 26 in `docs/bugs/validation_fix_2026_03_05` after PASS validation.
- Updated:
  - `docs/bugs/validation_fix_2026_03_05/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_fix_2026_03_05/quick_pass_checklist.md`
  - `docs/roadmap.md`
- Validation outcome recorded:
  - Exact repro (iOS owner + Chrome mirror) PASS:
    `start -> pause -> resume -> Groups Hub -> back to Run Mode -> cancel`,
    owner/mirror return correctly to Groups Hub without indefinite syncing.
  - Extended run (Android + macOS, background/foreground + pause/resume/cancel) PASS.
- Reviewed new logs for critical errors and confirmed no unhandled exceptions in the Fix 26 validation run:
  - `docs/bugs/validation_fix_2026_03_05/logs/2026_03_06_fix26_ios_debug.log`
  - `docs/bugs/validation_fix_2026_03_05/logs/2026_03_06_fix26_chrome_debug.log`

### 🧪 Tests:

- `flutter analyze` (pass).

### ⚠️ Issues found:

- None in Fix 26 validation scope.

### 🎯 Next steps:

- Continue with Fix 25 (`overlaps falsos + ownership erratico`), keeping the feature gate active until Fix 25 and regression checks are closed.

# 🔹 Block 545 — Fix 26 reopened hardening (07/03/2026)

### ✔ Work completed:

- Reopened Fix 26 after recurrent `Syncing session...` reports with active
  snapshots still updating.
- Documentation-first updates:
  - `docs/specs.md`: added non-destructive missing-session cleanup rules
    (no clear on single transient `groupId` lookup miss; require corroborated
    non-running/stale evidence).
  - `docs/bugs/validation_fix_2026_03_05/plan_validacion_rapida_fix.md`:
    Fix 26 marked **Reopened** with new evidence references.
  - `docs/roadmap.md`: added Fix 26 reopen note and reopened-phase item.
- Implemented P0 hardening:
  - `lib/data/repositories/firestore_pomodoro_session_repository.dart`
    - `clearSessionIfGroupNotRunning()` now validates session/group status
      before delete.
      - Deletes only if:
        - session is non-active, or
        - linked group exists and is explicitly non-running.
      - Does not delete on transient missing group linkage/lookup.
  - `lib/presentation/viewmodels/pomodoro_view_model.dart`
    - Rebinds machine/session subscriptions on `build()` reruns to avoid stale
      listeners after provider refreshes.
    - Preserves existing `_serverTimeOffset` when the time-sync provider
      rebuilds without an offset.
    - `_sanitizeActiveSession()` no longer clears session when group lookup is
      transiently null; clears only when stale-grace is exceeded or non-running
      group is confirmed.

### 🧪 Tests:

- `flutter analyze` (pass).

### ⚠️ Issues found:

- Validation run pending for reopened Fix 26 exact repro + regression smoke checks.
- Local workspace still contains unrelated `ios/Flutter/AppFrameworkInfo.plist`
  modification (not part of this fix).

### 🎯 Next steps:

- Run exact repro on owner/mirror with logs (iOS+Chrome and Android+macOS path).
- If PASS without regressions, close reopened Fix 26 in validation docs.

# 🔹 Block 546 — Fix 26 second-cycle implementation (07/03/2026)

### ✔ Work completed:

- Code analysis post-reopen identified three concrete gaps in the previous implementation:
  1. `applyRemoteCancellation()` did not clear `_sessionMissingWhileRunning` or
     `_lastActiveSessionSnapshotAt`, leaving the VM inconsistent when the owner
     cancels while the mirror is in a syncing hold.
  2. No foreground auto-resync for mirror devices during the syncing hold:
     `_inactiveResyncTimer` only starts on `handleAppPaused()`; in the foreground
     the mirror had no automatic escape path if the stream was slow to recover.
  3. `clearSessionIfGroupNotRunning` returned without deleting when the linked group
     was not found in Firestore, leaving orphaned sessions beyond stale-grace.
- Implemented three targeted fixes:
  - `applyRemoteCancellation()` now clears `_sessionMissingWhileRunning` and
    calls `_clearSessionSnapshotTracking()` before `_resetLocalSessionState()`.
  - Added `_foregroundMissingResyncTimer` (one-shot, 5 s): scheduled on the
    first entry into hold (both stream-listener and resync paths); fires
    `syncWithRemoteSession(refreshGroup: true, preferServer: true)` to give
    mirrors an automatic foreground escape without relying solely on the stream.
    Cancelled when hold clears (session received, explicit clear, or dispose).
  - `clearSessionIfGroupNotRunning`: when group is not found in Firestore, now
    deletes the session only if `lastUpdatedAt` exceeds the 45 s stale-grace
    (orphaned session confirmed); preserves it otherwise (transient window).
- Updated:
  - `docs/bugs/validation_fix_2026_03_05/plan_validacion_rapida_fix.md`
  - `docs/roadmap.md`
  - `lib/presentation/viewmodels/pomodoro_view_model.dart`
  - `lib/data/repositories/firestore_pomodoro_session_repository.dart`

### 🧪 Tests:

- `flutter analyze` (pass, no issues).

### ⚠️ Issues found:

- Validation run pending for reopened Fix 26 exact repro + regression smoke checks.

### 🎯 Next steps:

- Run exact repro: owner cancels → mirror must exit syncing hold within ≤5 s.
- Run regression smoke checks (4 items).
- If PASS: close Fix 26 in validation docs and roadmap.

---

# 🔹 Block 547 — Fix 26 regression fixes third cycle (07/03/2026)

**Date:** 07/03/2026
**Branch:** `fix26-reopen-syncing-session-hold`
**Scope:** Fix three regressions introduced by the second-cycle implementation (Block 546 / commit `4f55010`).

## Context

Validation logs from `docs/bugs/validation_fix_2026_03_07-01/logs/` confirmed the second-cycle
implementation made things **worse** than before:

1. **New error — `setState() or markNeedsBuild() called during build`** (iOS lines 51006, 51153;
   Chrome lines 2117, 2247):
   - Root cause: `timer_screen.dart:682` called `_navigateToGroupsHub()` directly inside
     `build()`, which synchronously invoked `GoRouter.go('/groups')` → GoRouter notifications
     → `setState` on `Router` during Flutter's build phase.

2. **New error — `Cannot use the Ref after it has been disposed`** (iOS lines 51175, 51187):
   - Root cause: `_publishCurrentSession()` and `_refreshTimeSyncIfNeeded()` call `ref.read()`
     synchronously. When Riverpod re-runs `build()` due to a watched-provider change
     (e.g., auth token refresh), it disposes the previous build lifecycle. Any callback from
     the previous lifecycle that still fires (machine callbacks registered in `configureFromItem`)
     hits a disposed `ref`.

3. **Increased spurious "Missing snapshot; clearing session" events** (iOS 3× vs 2×,
   Chrome 2× vs 0×):
   - Root cause: `build()` closes and immediately reopens the session `ref.listen`. On each
     `build()` re-run the new listener may receive a null event before the Firestore stream
     re-delivers the active session, triggering an extra missing-session clear.

## Fixes applied

### Fix A — `timer_screen.dart`: defer build-time navigation

- Lines 680-683: replaced direct `_navigateToGroupsHub(reason: 'build canceled')` call with:
  1. Set `_cancelNavigationHandled = true`, `_cancelNavRetryAttempts = 0`,
     `_cancelNavTargetGroupId` immediately (prevents re-queuing on subsequent builds).
  2. `WidgetsBinding.instance.addPostFrameCallback` → calls `_attemptNavigateToGroupsHub`
     after the build frame completes.

### Fix B — `pomodoro_view_model.dart`: ref.mounted guards

- `_publishCurrentSession()`: added `if (!ref.mounted) return;` as first line.
- `_refreshTimeSyncIfNeeded()`: added `if (!ref.mounted) return;` before the synchronous
  `ref.read()` and again after `await _timeSyncService.refresh()` before using instance state.

### Fix C — `pomodoro_view_model.dart`: defer build() re-subscription

- `build()` (line ~163): replaced synchronous `_subscribeToRemoteSession()` with a
  `Future.microtask` that guards on `ref.mounted && _sessionSub == null`. This ensures
  the re-subscription happens after build completes and only if no other path (loadGroup,
  handleAppResumed) has already established a subscription.

## Tests

- `flutter analyze` → no issues.

## Commit

- Pending (this block recorded before commit).

---

# 🔹 Block 548 — Fix 26 moved to monitoring window (07/03/2026)

### ✔ Work completed:

- Updated validation docs to keep Fix 26 open in **Monitoring** state instead of closing it immediately.
- Added/updated cycle4 validation artifacts:
  - `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md`
- Updated Fix 26 status in:
  - `docs/bugs/validation_fix_2026_03_05/plan_validacion_rapida_fix.md`
  - `docs/roadmap.md`
- Recorded commit reference for third-cycle implementation: `26f0c7e`.
- Recorded decision:
  - Monitoring window active: **07/03/2026 → 09/03/2026**.
  - Initial practical tests show no indefinite `Syncing session...` hold.

### 🧪 Tests:

- No new code/test execution in this block (documentation/status update only).

### ⚠️ Issues found:

- Related open bug observed during cycle4:
  - Account scheduled group -> switch to Local -> pass start time -> return to Account:
    Run Mode does not auto-open until app restart.

### 🎯 Next steps:

- Continue 2-day monitoring for Fix 26.
- Triage and isolate the Local->Account late auto-open bug as separate follow-up fix.

---

# 🔹 Block 549 — Fix 27 implementation (Local -> Account overdue auto-start) (07/03/2026)

### ✔ Work completed:

- Opened dedicated branch: `fix27-local-account-reentry-autostart`.
- Documentation-first updates:
  - `docs/specs.md`: added explicit requirement that Local -> Account re-entry
    must re-evaluate overdue scheduled groups and auto-open Run Mode without
    app restart when no active conflict exists.
  - `docs/roadmap.md`: added reopened item for this bug under Phase 17.
  - `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md`:
    added Fix 27 scope/objective and exact repro target.
  - `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md`:
    added Fix 27 validation and regression checks.
- Implementation:
  - `lib/widgets/app_mode_change_guard.dart`
    - mode change handler now receives `previous/next` mode.
    - added invalidation of account session stream providers
      (`pomodoroSessionStreamProvider`, `activePomodoroSessionProvider`).
    - switched from `clearAction()` to invalidating
      `scheduledGroupCoordinatorProvider` to emulate cold re-entry.
    - on Local -> Account transition, added deterministic post-switch
      reevaluation calls (`post-frame` + delayed recheck) via coordinator.
  - `lib/presentation/viewmodels/scheduled_group_coordinator.dart`
    - added `forceReevaluate()` to process current group stream snapshot on demand.
- Commit: `5ac3d6b` (`fix: restore Local->Account overdue auto-start reentry`).

### 🧪 Tests:

- `flutter analyze` (pass, no issues).

### ⚠️ Issues found:

- Behavioral validation pending (exact repro + regression smoke in
  `validation_fix_2026_03_07-01`).

### 🎯 Next steps:

- Run Fix 27 exact repro on iOS + Chrome with logs.
- Verify no regression on Fix 24/Fix 26 and overlap resolution flow.

---

# 🔹 Block 550 — Fix 27 closed: Local -> Account overdue auto-start (07/03/2026)

### ✔ Work completed:

- Diagnosed root cause of Fix 27 first-attempt failure (`5ac3d6b`):
  - `ref.invalidate(scheduledGroupCoordinatorProvider)` in `_handleModeChange`
    disposed the coordinator and tore down all its `ref.listen` subscriptions.
  - `taskRunGroupStreamProvider` (auto-rebuilt by `appModeProvider` watch) started
    delivering Firestore data during the race window before the new coordinator
    instance rebuilt and re-registered its stream listener.
  - The coordinator's own `ref.listen<AppMode>` already calls `_resetForModeChange()`
    - `_handleGroups()` on every mode change — invalidating it bypassed this natural
      mechanism without providing an equivalent guarantee.
- Applied second-attempt fix (`lib/widgets/app_mode_change_guard.dart`):
  - Removed `ref.invalidate(scheduledGroupCoordinatorProvider)` from `_handleModeChange`.
  - Coordinator now keeps its listeners alive across mode switches; `ref.listen<AppMode>`
    fires synchronously on mode change, resets state, and the coordinator's
    `ref.listen<taskRunGroupStreamProvider>` fires when Firestore data arrives.
  - `forceReevaluate()` calls (postFrameCallback + 600ms delay) kept as backup triggers
    for slow-network / time-sync retry scenarios.
- Updated docs:
  - `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md`
  - `docs/roadmap.md`

### 🧪 Tests:

- `flutter analyze` (pass, no issues).
- Exact repro PASS (iOS + Chrome, 2026-03-07 22:49):
  - Group scheduled at 22:48, user switched to Local Mode before start.
  - Start time passed while in Local Mode.
  - User switched back to Account Mode at 22:49.
  - Auto-start fired immediately; Timer Run Mode opened without app restart.
- iOS evidence: `2026_03_07_fix27v2_ios_debug.log` line 51016 — `Auto-start opening TimerScreen` at 22:49:03.
- Chrome evidence: `2026_03_07_fix27v2_chrome_debug.log` lines 2086–2090 — `Auto-open confirmed in timer route=/timer/c2b7f11d`.
- Regression smoke: no Fix 24/Fix 26 regressions in v2 logs.

### ⚠️ Issues found:

- None.

### 🎯 Next steps:

- Continue Fix 26 two-day monitoring window (closes 2026-03-09).
- Resume planned roadmap work.

---

# 🔹 Block 551 — Fix 26 reopened hardening v4 implementation (09/03/2026)

**Date:** 09/03/2026  
**Branch:** `fix26-reopen-black-syncing-2026-03-09`  
**Scope:** Harden missing-session recovery for the single-device background/offline scenario reported on 2026-03-08.

### ✔ Work completed:

- Documentation-first updates:
  - `docs/specs.md`: added explicit requirements for:
    - periodic foreground missing-session retries with bounded backoff,
    - repo-backed group recheck before destructive clear,
    - resume listener stability (no forced close/recreate on every resume).
- Implemented VM/session hardening:
  - `lib/presentation/viewmodels/pomodoro_view_model.dart`
    - Replaced one-shot foreground hold resync with periodic bounded-backoff retry loop (`5s -> 10s -> 20s -> max 30s`).
    - Added asynchronous missing-session handling with decision token guard to avoid stale clear races.
    - Added repo recheck (`_groupRepo.getById`) before destructive missing-session clear; keep hold when running state cannot be safely ruled out.
    - Added non-destructive clear helper that avoids forcing idle when group remains running.
    - Added session listener rebind guard on resume (rebind only when absent or stalled, with cooldown).
    - Added `isSessionGapStalled` + `retrySessionGapRecovery()` for manual recovery path.
  - `lib/presentation/screens/timer_screen.dart`
    - Sync overlay retry now supports both time-sync stalls and session-gap stalls.
- Test hygiene update:
  - `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
    - Corrected assertion to match existing spec rule: Account Mode without timeSync must block authoritative publish and force sync refresh.
- Updated tracking docs for reopened Fix 26 status:
  - `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md`
  - `docs/validation/validation_ledger.md`
  - `docs/roadmap.md`

### 🧪 Tests:

- `flutter analyze` (pass, no issues).
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart` (pass).
- Commit: `418c75f` — `fix: guard timesync offset against reconnect poisoning`.
- Commit: `3ad6c98` — `fix: harden fix26 missing-session recovery and resume sync`.

### ⚠️ Issues found:

- Fix 26 remains open until exact repro + regression smoke are re-run with evidence on the single-device degraded-network scenario.

### 🎯 Next steps:

- Run exact repro validation on Android + macOS sleep/background path with logs.
- Run regression smoke checks (Fix 24 / Fix 25 / Fix 27 + overlap flow).
- If all pass, close Fix 26 in validation docs + roadmap + ledger with commit traceability.

---

# 🔹 Block 552 — Fix 26 cancellation race guard (09/03/2026)

**Date:** 09/03/2026
**Branch:** `fix26-reopen-black-syncing-2026-03-09`
**Scope:** Surgical follow-up to Block 551: guard against stale async missing-session hold after remote cancellation.

### ✔ Work completed:

- `lib/presentation/viewmodels/pomodoro_view_model.dart`
  - `applyRemoteCancellation()`: added `_missingSessionDecisionToken += 1` and `_cancelForegroundMissingResync()` before resetting `_sessionMissingWhileRunning`.
  - This prevents an in-flight `_handleMissingSessionFromStream()` (awaiting group repo recheck) from overriding the cancellation state when the token check runs after the async gap.
- Updated tracking docs:
  - `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md`
  - `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md`
  - `docs/dev_log.md`

### 🧪 Tests:

- `flutter analyze` (pass, no issues).

### ⚠️ Issues found:

- None. Change is additive and does not alter any existing path; it only closes a stale-decision race window that was low-severity but logically incorrect.

---

# 🔹 Block 553 — Fix 26 reconnect desync guard in TimeSyncService (09/03/2026)

**Date:** 09/03/2026  
**Branch:** `fix26-reopen-black-syncing-2026-03-09`  
**Scope:** Prevent transient wrong timer projection after offline/background reconnect in iOS+Chrome quick packet.

### ✔ Work completed:

- Root-cause confirmed from quick packet logs:
  - Chrome accepted a poisoned time-sync sample on reconnect (`offset=+45550ms`)
    and projected timer with a transient ~45s skew before the next sync corrected it.
- Documentation-first update:
  - `docs/specs.md`: added explicit rules for invalid time-sync measurement
    handling (roundtrip validity, offset-jump guard, reject cooldown behavior).
- Implemented surgical guard in:
  - `lib/data/services/time_sync_service.dart`
    - Added reject cooldown (`3s`) to avoid tight retry loops after rejected samples.
    - Rejects measurement if reconnect roundtrip is too large (`>3s`).
    - Rejects abrupt offset jumps (`>5s`) when a previous valid offset exists.
    - On rejection: keeps previous valid offset and does not update
      `lastSyncAt` so a new valid measurement can happen soon.
- Updated validation tracking docs:
  - `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md`
  - `docs/validation/validation_ledger.md`
  - `docs/roadmap.md`

### 🧪 Tests:

- `flutter analyze` (pass, no issues).
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart` (pass).

### ⚠️ Issues found:

- Fix 26 remains open until the quick packet is re-run after this guard and
  confirms no transient reconnect desync.

### 🎯 Next steps:

- Re-run iOS+Chrome quick packet using existing log commands.
- If reconnect desync is gone and no regressions appear, close Fix 26 in
  checklist/plan/ledger/roadmap with commit traceability.

---

# 🔹 Block 554 — Fix 26 re-validation PASS and closure (09/03/2026)

**Date:** 09/03/2026  
**Branch:** `fix26-reopen-black-syncing-2026-03-09`  
**Scope:** Close reopened Fix 26 after rerun of the degraded-network quick packet.

### ✔ Work completed:

- Re-checked quick packet logs after `418c75f`:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_chrome_debug.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_09_fix26_quick_ios_debug.log`
- Confirmed `TimeSync` guard behavior in Chrome:
  - invalid reconnect samples were rejected (`rejected measurement` events at lines 2255, 2466, 2506),
  - no large positive `offset` projection was accepted in the rerun.
- User-run validation outcome:
  - `Syncing session...` duration matched only the real offline interval,
  - previous reconnect timer drift was not reproduced in the same scenario.
- Updated closure traceability docs:
  - `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md`
  - `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md`
  - `docs/validation/validation_ledger.md`
  - `docs/roadmap.md`

### 🧪 Tests:

- No new code changes in this block; validation evidence is log-based on the rerun.

### ⚠️ Issues found:

- None. Fix 26 closure criteria met for current scope.

### 🎯 Next steps:

- Continue normal roadmap order with remaining P0 validation blocker (`P0-F25-001`).

---

# 🔹 Block 555 — Fix 26 regression detected + rollback to 961f7eb baseline (10/03/2026)

**Date:** 10/03/2026
**Branch:** `fix26-reopen-black-syncing-2026-03-09`
**Scope:** Regression in "Syncing session..." hold reintroduced by second/third-cycle hardening; rolled back to last known-good baseline.

### ✔ Work completed:

- Regression confirmed from Android + macOS logs (`2026_03_10_fix26_observation_partial_android_d03c150.log`):
  - At ~12:15 CET, a Firebase Auth token refresh caused a brief `runningExpiry=true`
    false-positive (56ms spike) in `ScheduledGroups`.
  - The spike silently disconnected the Firestore session listener on Android.
  - With the session stream dead, `_sessionMissingWhileRunning = true` was set and
    never cleared — Android stuck in `Syncing session...` for 40+ minutes despite
    Firestore showing a healthy `pomodoroRunning` session.
  - Root cause traced to commit `9bab880` (second-cycle hardening):
    `PomodoroViewModel.build()` was modified to unconditionally cancel `_sessionSub`
    at start (`_sessionSub?.close(); _sessionSub = null`) to prevent duplicate
    subscriptions on Riverpod re-runs. This is fundamentally incorrect because
    `Notifier.build()` re-runs for **any** watched-provider change — not only
    session-related events. A Firebase Auth token refresh causes
    `pomodoroSessionRepositoryProvider` to re-emit, which triggers a `build()` re-run,
    which kills the Firestore session stream. Re-subscription at the end of `build()`
    is conditional (`if (appMode == account && hasLoadedContext)`); even when the
    condition is met, the new Firestore stream emits `null` during the auth-reconnect
    window → `_sessionMissingWhileRunning = true` latches. The foreground retry (also
    from this second-cycle) then sees `group=running` and keeps the hold indefinitely.
    At `961f7eb`, `_sessionSub` was a `ProviderSubscription` (`ref.listen`) managed
    by Riverpod — `build()` re-runs left it completely untouched, only
    `ref.onDispose()` closed it. **Rule for future implementations:** never cancel
    a `ref.listen` subscription inside `build()`; let Riverpod own its lifecycle.
  - `418c75f` (TimeSync guard) confirmed **not involved** — no rejected measurements
    appear in the logs; all offsets were clean (-136ms to -214ms) throughout the incident.
- Rollback performed to `961f7eb` baseline for the affected code files:
  - `lib/presentation/viewmodels/pomodoro_view_model.dart`
  - `lib/presentation/screens/timer_screen.dart`
  - `lib/data/repositories/firestore_pomodoro_session_repository.dart`
  - `lib/data/repositories/pomodoro_session_repository.dart`
  - `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
  - `test/data/repositories/firestore_pomodoro_session_repository_test.dart` (deleted — tested rolled-back symbols)
- Preserved (not rolled back):
  - Fix 27 (`app_mode_change_guard.dart`, `scheduled_group_coordinator.dart`) — confirmed no overlap with rolled-back files.
  - `418c75f` (`lib/data/services/time_sync_service.dart`) — TimeSync guard is independent and valid.

### 🧪 Tests:

- `flutter analyze` (pass — 4 test-mock warnings only, no errors).

### ⚠️ Issues found:

- Fix 26 is **reopened**. The 961f7eb baseline was previously validated (06/03/2026) but
  was then reopened on 07/03/2026 for recurrent edge-case scenarios. A fresh validation
  run is required to confirm the baseline still holds under current conditions.

### 🎯 Next steps:

- Rebuild and redeploy on all devices with commit `4195ef1`.
- Re-validate Fix 26 exact repro (single-device background + reconnect scenario).
- If validation passes, close P0-F26-001 with new commit hash.

---

# 🔹 Block 556 — Fix 26 rollback partial re-validation kept open (10/03/2026)

**Date:** 10/03/2026  
**Branch:** `fix26-reopen-black-syncing-2026-03-09`  
**Scope:** Review new rollback logs and keep closure blocked until longer validation.

### ✔ Work completed:

- Reviewed new rollback logs generated on commit `4195ef1`:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_10_fix26_observation_partial_android_4195ef1.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026_03_10_fix26_observation_partial_macos_4195ef1.log`
- Observed in the sampled window (~13:19–13:46 CET):
  - Android resumed with `Resync start (resume)` and `Resync start (post-resume)`.
  - Active session snapshots kept advancing (no destructive `Missing snapshot; clearing session` signal in this partial run).
  - No irrecoverable `Syncing session...` hold reproduced in this short window.
- Updated validation docs to keep strict caution status:
  - `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md`
  - `docs/validation/validation_ledger.md`
  - `docs/roadmap.md`

### 🧪 Tests:

- No code changes in this block; validation work is log/documentation based.

### ⚠️ Issues found:

- Validation window is still too short (<1h). Regression cannot be considered resolved yet.

### 🎯 Next steps:

- Complete exact degraded-network repro packet end-to-end on rollback commit `4195ef1`.
- Complete extended soak window (>=4h) before any closure attempt.

---

# 🔹 Block 557 — Fix 26 regression-cause review + mandatory guardrails (10/03/2026)

**Date:** 10/03/2026  
**Branch:** `fix26-reopen-black-syncing-2026-03-09`  
**Scope:** Validate documented root cause and lock prevention rules for next implementations.

### ✔ Work completed:

- Reviewed the documented root cause against:
  - `2026_03_10_fix26_observation_partial_android_d03c150.log`
  - commits `9bab880`, `4f55010`, `26f0c7e`, `3ad6c98`
- Confirmed the main mechanism is consistent:
  - `9bab880` added unconditional `_sessionSub?.close(); _sessionSub = null;`
    at `build()` start.
  - `build()` can re-run on auth/token-driven provider refreshes.
  - re-open after build may see transient `null`; hold latch then persists in bad paths.
- Added precision note:
  - `26f0c7e` microtask guard (`if (_sessionSub != null) return`) was ineffective
    because `_sessionSub` had already been nulled at build start.
- Added mandatory prevention guardrails in:
  - `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md`

### 🧪 Tests:

- No production code changes in this block; review + process hardening only.

### ⚠️ Issues found:

- Regression risk remains high for any future listener-lifecycle edits unless
  guardrails and validation gates are followed strictly.

### 🎯 Next steps:

- Apply guardrails as a merge gate on the next Fix 26 implementation attempt.
- Keep Fix 26 open until exact repro + >=4h soak pass on the same commit.

---

# 🔹 Block 558 — Root-cause analysis + fix: transient AsyncData<null> latch (10/03/2026)

**Date:** 10/03/2026
**Branch:** `fix26-reopen-black-syncing-2026-03-09`
**Scope:** Reproduce and permanently fix the "Syncing session..." infinite freeze triggered by a brief network cut on the session owner device.

### Root cause (confirmed from 10/03 incident logs):

The "Syncing session..." freeze is triggered by a two-step failure:

**Step 1 — Spurious latch via `AsyncData<null>`:**
When the owner device (macOS) experiences a brief internet cut, the Firestore SDK begins reconnecting. During this window the `snapshots()` stream listener (backing `pomodoroSessionStreamProvider`) can emit `AsyncData<null>` — either from a cache miss or a transient SDK state. `_resolveSessionSnapshot` treats `AsyncData<null>` the same as a genuine deletion and returns `null`. With a valid recent `_latestSession` present, `_shouldTreatMissingSessionAsRunning` returns `true` and `_sessionMissingWhileRunning` latches **immediately** — before any real session data is lost.

**Step 2 — Auto-recovery fails silently:**
`_recoverMissingSession` calls `tryClaimSession` (returns `false` — Android's document exists) then `publishSession` (transaction reads Android as owner → returns without writing). Both calls fail silently. Nothing clears the latch. Heartbeats stop (`_controlsEnabled = false`). macOS freezes indefinitely in "Syncing session...".

The latch could self-clear if the Firestore stream later delivers the Android-owned session (line 1347), but if the SDK does not re-emit after reconnect (or takes too long), the device stays frozen until `handleAppResumed()` (macOS window click) or `loadGroup()` (Android re-navigation) runs.

### Fix (two-part, both defensive layers):

**Part 1 — 3-second debounce before latching (stream path only):**
Added `_sessionMissingLatchTimer`. When `_subscribeToRemoteSession` detects a potentially missing session from the stream, it starts a 3-second timer via `_onSessionMissingLatchDebounced()` instead of latching immediately. If a valid session arrives within 3 seconds (normal reconnect), the timer is cancelled and no latch ever fires. Only if the stream remains silent for >3 seconds does `_onSessionMissingLatchDebounced()` fire and set the latch. The `syncWithRemoteSession` resync path (explicit fetch on resume) bypasses the debounce and sets the latch synchronously as before.

**Part 2 — Server fetch fallback in `_recoverMissingSession`:**
After `tryClaimSession` fails and `publishSession` is blocked, immediately fetch from the server (`preferServer: true`). If the response shows another device owns an active session for the current context, clear the latch, apply the remote session via `_primeMirrorSession`, and return. This means even if the debounce is bypassed (e.g. >3s reconnect), the first recovery attempt at `t+5s` will discover the remote owner via server fetch and self-heal automatically — no manual intervention required.

### Files changed:

- `lib/presentation/viewmodels/pomodoro_view_model.dart`:
  - Added `Timer? _sessionMissingLatchTimer` field (line ~87).
  - Added `_sessionMissingLatchTimer?.cancel()` in `ref.onDispose` and `loadGroup`.
  - `_subscribeToRemoteSession` null-latch branch: replaced immediate latch with 3-second debounce timer.
  - Added `_sessionMissingLatchTimer` cancel in the clear-session and non-null session paths.
  - Added `_onSessionMissingLatchDebounced()` method after `_subscribeToRemoteSession`.
  - `_recoverMissingSession`: after `publishSession` fails, fetch from server; if remote-owned active session found, clear latch and enter mirror mode immediately.

### 🧪 Tests:

- Dart analyzer: no issues.
- Manual validation required (same degraded-network repro scenario from 10/03 incident).

### ⚠️ Issues found:

- The stream-based debounce only protects the `_subscribeToRemoteSession` path. The `syncWithRemoteSession` resync path still latches immediately when it fetches null — this is intentional (explicit server fetch is authoritative).
- The server fetch in `_recoverMissingSession` adds one extra Firestore read per recovery attempt when another device owns the session. Recovery cooldown is 5 seconds; this is acceptable.

### 🎯 Next steps:

- Deploy and run the same degraded-network repro (macOS brief network cut during Android ownership takeover).
- Verify macOS auto-recovers within ~5–8 seconds without any manual intervention.
- If stable: close P0-F26-001 and P0-F26-002.

---

# 🔹 Block 559 — Fix 26 follow-up: cursor repair on reopen/owner switch (10/03/2026)

**Date:** 10/03/2026  
**Branch:** `fix26-reopen-black-syncing-2026-03-09`  
**Scope:** Prevent reopening Run Mode in the wrong task/time when `activeSession/current`
persists an invalid cursor (e.g. `currentPomodoro > totalPomodoros`).

### ✔ Work completed:

- Implemented active-session cursor repair in
  `lib/presentation/viewmodels/pomodoro_view_model.dart`:
  - Added repair path in `_sanitizeActiveSession(...)`.
  - Added repair path in `_subscribeToRemoteSession(...)` stream callback.
  - New helpers:
    - `_repairInconsistentSessionCursor(...)`
    - `_projectFromGroupTimelineWithPauseOffset(...)`
    - `_phaseDurationForItemPhase(...)`
    - `_isSameSessionSnapshot(...)`
- Repair behavior:
  - Detects invalid session cursor (taskId/index mismatch, task total mismatch,
    out-of-range pomodoro such as `2/1`).
  - Reprojects against the running group timeline anchor and rebuilds a coherent
    session snapshot for hydration.
  - If local device is owner in Account Mode, republishes repaired snapshot to
    Firestore to converge remote state.
- Added regression test:
  - `loadGroup repairs invalid task cursor and lands on expected running task`
  - file:
    `test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart`

### 🧪 Tests:

- `dart analyze lib/presentation/viewmodels/pomodoro_view_model.dart test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → PASS
- `flutter analyze` → PASS

### ⚠️ Issues found:

- Manual multi-device validation is still pending for the exact owner-switch reopen
  path on Android RMX3771 + macOS.

### 🎯 Next steps:

- Execute post-fix release logs on Android RMX3771 and macOS.
- Confirm reopen lands on the correct task (`Trading`) and no `Pomodoro 2 of 1`
  reappears.
- If pass, close `P0-F26-003` in validation ledger and checklist.

---

# 🔹 Block 560 — Fix 26 follow-up v2: recover `running` group + `finished` session mismatch (10/03/2026)

**Date:** 10/03/2026  
**Branch:** `fix26-reopen-black-syncing-2026-03-09`  
**Scope:** Prevent `00:00 Syncing session...` loop when Firestore keeps `TaskRunGroup.status=running`
but `activeSession/current.status=finished` with stale cursor data.

### ✔ Work completed:

- Extended the active-session reconciliation path in
  `lib/presentation/viewmodels/pomodoro_view_model.dart`:
  - `_sanitizeActiveSession(...)` no longer exits early for non-active statuses.
  - `_repairInconsistentSessionCursor(...)` now treats
    `!session.status.isActiveExecution && group.status == running` as a repair trigger.
  - For that case, it reprojects from running-group timeline anchor (with pause-offset model),
    and rebuilds a coherent active snapshot instead of preserving stale `finished` payload.
- Added dedicated regression coverage in
  `test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart`:
  - `loadGroup repairs finished invalid cursor when group is still running`
  - Simulates exact inconsistent payload observed in production:
    `status=finished`, `phase=null`, `remainingSeconds=0`, `currentPomodoro=2`, `totalPomodoros=1`
    while group remains `running`.

### 🧪 Tests:

- `dart analyze lib/presentation/viewmodels/pomodoro_view_model.dart test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → PASS

### ⚠️ Issues found:

- Device validation is still pending for this exact scenario on Android RMX3771 + macOS.
- `ios/Flutter/AppFrameworkInfo.plist` remains locally modified and was intentionally excluded.

### 🎯 Next steps:

- Run clean reopen/install packet with release logs on macOS + RMX3771.
- Confirm no repeated `Auto-start abort (state not idle) state=finished`.
- Confirm timer lands on projected running segment (`Trading`) and no indefinite syncing hold.

---

# 🔹 Block 561 — Fix 26 follow-up v3: stale finished owner recovery + expiry safety (10/03/2026)

**Date:** 10/03/2026  
**Branch:** `fix26-reopen-black-syncing-2026-03-09`  
**Scope:** Close the no-owner gap when Firestore keeps a stale `finished` activeSession while group remains `running`, without forcing running if timeline is already expired.

### ✔ Work completed:

- Added stale non-active ownership recovery in
  `lib/presentation/viewmodels/pomodoro_view_model.dart`:
  - During sanitize, after cursor repair, when original snapshot is non-active/stale
    and repaired snapshot is active:
    - clear stale session (`clearSessionIfStale`)
    - attempt `tryClaimSession` with rebuilt active snapshot and bumped revision.
  - If claim loses race, fetch server snapshot and continue safely.
- Added expiry safety guard:
  - if group is already expired by timeline (`actualStartTime` + duration + pause offset via `theoreticalEndTime`), sanitize **does not reclaim** owner;
    it completes the group + clears stale session.
- Added helper:
  - `_buildOwnedRecoveredSession(...)`

### 🧪 Tests:

- Updated regression test file:
  `test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart`
  - existing: `loadGroup repairs finished invalid cursor when group is still running`
    now asserts recovered owner is current device.
  - new: `expired running-group + stale finished session is completed instead of re-claimed`
- Validation:
  - `dart analyze lib/presentation/viewmodels/pomodoro_view_model.dart test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → PASS
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → PASS
  - `flutter analyze` → PASS

### ⚠️ Issues found:

- Device validation still pending for this v3 behavior on Android RMX3771 + macOS.
- `ios/Flutter/AppFrameworkInfo.plist` remains locally modified and intentionally excluded.

### 🎯 Next steps:

- Run new release logs on RMX3771 + macOS with this commit.
- Confirm:
  1. stale `finished` session is replaced by an active owned session when group is still running;
  2. no-owner gap is gone;
  3. if group is truly expired, it completes (no forced running reclaim).

---

# 🔹 Block 562 — Fix 26 `P0-F26-003` closure validation PASS (10/03/2026)

**Date:** 10/03/2026  
**Branch:** `fix26-reopen-black-syncing-2026-03-09`  
**Scope:** Close validation item `P0-F26-003` (reopen/owner-switch cursor mismatch + stale finished/no-owner recovery) with real-device evidence.

### ✔ Work completed:

- Reviewed closure logs from release runs:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-10_fix26_postfix_250c24d_macos_diag.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-10_fix26_postfix_250c24d_android_RMX3771_diag.log`
- Confirmed both clients auto-opened Run Mode correctly for the running group.
- Confirmed no recurrence of the reopened bug signatures:
  - no `Pomodoro 2 of 1`
  - no indefinite `00:00 Syncing session...`
  - no stale mirror/no-owner dead state.
- Verified deterministic ownership behavior from logs:
  - stable owner snapshots while running,
  - clean owner handoff (`macOS -> Android`) without sync latch.
- Verified timer coherence against phase window + wall-clock (second-level rounding only).
- Updated closure docs:
  - `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md`
  - `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md`
  - `docs/validation/validation_ledger.md`
  - `docs/roadmap.md`

### 🧪 Validation result:

- `P0-F26-003`: **Closed/OK**
  - closed implementation commit: `250c24d`
  - message: `fix(f26): recover stale finished session ownership with expiry-safe guard`
- `P0-F26-001`: remains open (`In validation`) pending exact degraded-network repro + extended soak criteria.

### ⚠️ Notes:

- `ios/Flutter/AppFrameworkInfo.plist` remains locally modified and intentionally excluded from all staging/commits.

# 🔹 Block 563 — Fix 26 reopen: owner-handoff timestamp regression gate (10/03/2026)

**Date:** 10/03/2026  
**Branch:** `fix26-reopen-black-syncing-2026-03-09`  
**Scope:** Address mirror `Syncing session...` latch when stream is alive but ViewModel timeline gate skips remote snapshots after owner handoff.

### ✔ Work completed:

- Reviewed incident logs reported as current:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-10_fix26_postfix_250c24d_macos_diag.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-10_fix26_postfix_250c24d_android_RMX3771_diag.log`
- Confirmed stream stayed alive (`[RunModeDiag] Active session change` every ~30s, owner Android), while UI still showed `Syncing session...`.
- Added owner-handoff safeguard in timeline gate:
  - `lib/presentation/viewmodels/pomodoro_view_model.dart`
  - `_shouldApplySessionTimeline(...)` now accepts `previousSession` and always applies first snapshot when `ownerDeviceId` changes (prevents lockout when `lastUpdatedAt` regresses across devices).
  - Applied in both stream listener path and explicit resync path.
- Added regression test scenario with dynamic stream:
  - `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
  - New test: `owner handoff applies timeline even when updatedAt regresses`.
- Updated existing debounce-aware expectation:
  - `missing session holds sync when lastUpdatedAt is null` now waits for debounce before asserting latch.

### 🧪 Validation run (local):

- `dart analyze lib/presentation/viewmodels/pomodoro_view_model.dart test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → PASS

### 🔖 Tracking:

- Implementation commit: `cb31ddf`
- Message: `fix(f26): rebase timeline on owner handoff with regressed timestamps`

### ⚠️ Notes:

- `ios/Flutter/AppFrameworkInfo.plist` remains locally modified and intentionally excluded.
- Device validation pending on release logs after this patch.

---

# 🔹 Block 564 — Fix 26 reopen: missing-session latch not clearing on UI after timeline skip (10/03/2026)

**Date:** 10/03/2026
**Branch:** `fix26-reopen-black-syncing-2026-03-09`
**Scope:** Root-cause and fix the persistent `Syncing session...` overlay on mirror (macOS) and frozen timer/gray circle on owner (Android) that reappeared after commit `250c24d`.

### ✔ Work completed:

- Analysed incident logs (same log files as Block 563):
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-10_fix26_postfix_250c24d_macos_diag.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-10_fix26_postfix_250c24d_android_RMX3771_diag.log`
- Confirmed Block 563 fix (`cb31ddf`) targeted a different failure mode (owner-handoff with regressed `lastUpdatedAt`) that was **not** the actual root cause for this incident (Android remained owner throughout, no handoff).
- Identified true root cause:

  **Bug sequence:**
  1. `loadGroup` fetches session with `preferServer: true` → sets `_lastAppliedSessionUpdatedAt = T_server_fresh`.
  2. `_primeMirrorSession` starts the mirror timer; UI shows running state.
  3. `_subscribeToRemoteSession(fireImmediately: true)` fires `AsyncLoading` → null → 3 s debounce starts.
  4. After 3 s: `_sessionMissingWhileRunning = true`, mirror timer cancelled, `_notifySessionMetaChanged()` → UI shows `Syncing session...`.
  5. Real Firestore snapshot arrives: `lastUpdatedAt = T_cached ≤ T_server_fresh` → `shouldApplyTimeline = false`.
  6. `wasMissing = true` was captured before the clear at step 4, but the `!shouldApplyTimeline` early-return block only called `_notifySessionMetaChanged()` when `ownershipMetaChanged`, **not** when `wasMissing`.
  7. Result: no rebuild triggered → UI permanently stuck at `Syncing session...`.
  8. Additionally, `_lastAppliedSessionUpdatedAt` is only updated inside the `shouldApplyTimeline=true` block, so all subsequent stream events also fail the gate → indefinite lock.

- Applied fix in `lib/presentation/viewmodels/pomodoro_view_model.dart`:
  - In `_subscribeToRemoteSession` listener, at the `!shouldApplyTimeline` early-return (line ~1408):
  - **Before:** `if (ownershipMetaChanged) { _notifySessionMetaChanged(); }`
  - **After:** `if (ownershipMetaChanged || wasMissing) { _notifySessionMetaChanged(); }`
  - This ensures a UI rebuild fires when the missing-session latch clears, even when the stream snapshot doesn't pass the timeline gate.

### 🧪 Validation run (local):

- `dart analyze lib/presentation/viewmodels/pomodoro_view_model.dart` → PASS
- `flutter analyze` → PASS

### 🔖 Tracking:

- Implementation commit: `b085ea6`
- Message: `fix(f26): notify UI when missing-session latch clears but timeline skips`

### ⚠️ Notes:

- **Partial limitation**: The fix clears the `Syncing session...` overlay immediately. The mirror timer position (frozen seconds) will unfreeze on the next Firestore write where `lastUpdatedAt > T_server_fresh` (~30 s max). A full immediate unfreeze would require calling `_setMirrorSession(session)` inside the `wasMissing` branch — deferred to device validation.
- `ios/Flutter/AppFrameworkInfo.plist` remains locally modified and intentionally excluded.
- Device validation in progress (release logs running on Android RMX3771 + macOS as of 10/03/2026).

---

# 🔹 Block 565 — Fix 26 Phase 2: unified session snapshot pipeline (11/03/2026)

**Date:** 11/03/2026  
**Branch:** `refactor-run-mode-sync-core`  
**Scope:** Apply the specs 10.4.8.b contract in runtime by centralizing
snapshot application (`stream` + `fetch/resync` + `recovery`) and enforcing the
single-shot missing-session bypass with atomic watermark reset.

### ✔ Work completed:

- Refactored `lib/presentation/viewmodels/pomodoro_view_model.dart`:
  - Added `_applySessionSnapshot(...)` as the single gate/application entry:
    - computes `shouldBypassGate = wasMissing && _isValidHoldExitSnapshot(session)`
    - applies single-shot bypass
    - resets applied watermarks atomically on bypass
    - resumes normal gate path immediately after exit event.
  - Added `_isValidHoldExitSnapshot(...)` with spec-aligned validity checks:
    `groupId` match + active execution status (or terminal+terminal reconciliation).
  - Added `_ingestResolvedSession(...)` so stream/fetch/recovery all delegate to
    the same ingest + gate + projection path.
  - Added `_applySessionTimelineProjection(...)` and
    `_clearRemoteSessionForContextMismatch(...)` to keep projection behavior
    centralized and deterministic.
- Rewired all three session paths to the shared pipeline:
  - `_subscribeToRemoteSession(...)` now delegates non-null snapshots to
    `_ingestResolvedSession(...)`.
  - `syncWithRemoteSession(...)` now delegates non-null snapshots to
    `_ingestResolvedSession(...)`.
  - `_recoverMissingSession(...)` (server-session branch) now delegates to
    `_ingestResolvedSession(...)` instead of applying state through a parallel path.

### 🧪 Validation run (local):

- `dart analyze lib/presentation/viewmodels/pomodoro_view_model.dart test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` → PASS (infos only).
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` → PASS (7/7).
- Contract-focused tests confirmed:
  - `[REFACTOR] missing-session exit resets watermark... (AP-4 full fix)` → PASS.
  - `stream null within debounce window... (AP-2)` → PASS.
  - `recovery clears latch when server session is active... (AP-3)` → PASS.

### ⚠️ Notes:

- Full repository test suite still has pre-existing failures in
  `scheduled_group_coordinator_test.dart` (AppModeService initialization path);
  these failures are outside this refactor scope.
- Device validation for Fix 26 degraded-network repro remains pending.

---

# 🔹 Block 566 — Fix 26 Phase 3 contract draft: single exit point + diagnostics (11/03/2026)

**Date:** 11/03/2026  
**Branch:** `refactor-run-mode-sync-core`  
**Scope:** Documentation-first Phase 3 delta before runtime implementation:
formalize latch-exit invariants and add contract tests reproducing field
validation failures from Android/macOS/iOS/Chrome runs.

### ✔ Work completed:

- Updated `docs/specs.md` section **10.4.8.b** with Phase 3 contracts:
  - single latch exit-point invariant (`true -> false` only via shared ingest),
  - non-owner recovery reads allowed (`preferServer: true`) with write ownership
    kept owner-scoped,
  - transitional-state hold extension rule (`null`/`idle`/`finished` at
    phase boundaries cannot clear hold without terminal corroboration),
  - mandatory diagnostics with lifecycle events
    (`hold-enter`/`hold-extend`/`hold-exit`/`hold-timeout`),
  - mandatory `projectionSource` field:
    `serverOffset | localFallback | snapshotRemaining | none`,
    including required behavior for `projectionSource=none`
    (do not render-resolve hold; extend with `projection-unavailable`).
- Updated contract tests in
  `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`:
  - strengthened AP-4 assertion to verify hold-exit projection is timeline-based
    (not stale `session.remainingSeconds`),
  - added `projection_uses_phase_start_not_snapshot_remaining_on_hold_exit`,
  - added `[PHASE3] transitional non-active snapshot must not clear hold...`,
  - added `[PHASE3] non-owner recovery may read server and exit hold...`,
  - added `[PHASE3] hold diagnostics must emit enter/extend/exit with projectionSource`.

### 🧪 Validation run (local):

- `dart analyze test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` → PASS (infos only).
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart --reporter compact`
  → expected contract failures (pre-implementation):
  - `[PHASE3] transitional non-active snapshot must not clear hold...`
  - `[PHASE3] non-owner recovery may read server and exit hold...`
  - `[PHASE3] hold diagnostics must emit enter/extend/exit with projectionSource`

### ⚠️ Notes:

- No runtime implementation changes were made in this block.
- This block is review-only (specs + contract tests) before coding Phase 3
  runtime changes.

---

# 🔹 Block 567 — Fix 26 Phase 3 runtime: single-exit hold + non-owner read recovery + diagnostics (11/03/2026)

**Date:** 11/03/2026  
**Branch:** `refactor-run-mode-sync-core`  
**Scope:** Implement runtime behavior to satisfy Phase 3 contracts added in
Block 566, without introducing patch-only side paths.

### ✔ Work completed:

- Updated `lib/presentation/viewmodels/pomodoro_view_model.dart`:
  - **Gap 1 (transitional hold safety):**
    - Added transitional guard so non-valid hold-exit snapshots while
      `wasMissing=true` extend hold instead of clearing it.
    - Prevented direct hold clear on `null` stream/resync while already in hold
      unless terminality is corroborated.
  - **Gap 2 (non-owner read recovery):**
    - Missing-session recovery now allows server reads for non-owner devices.
    - Ownership checks remain write-scoped (`tryClaimSession` / publish path).
    - If server fetch returns active same-context session, it is ingested through
      the shared pipeline and can clear hold.
  - **Gap 3 (diagnostics):**
    - Added hold lifecycle diagnostics events:
      `hold-enter`, `hold-extend`, `hold-exit`.
    - Added projection source classification in diagnostics:
      `serverOffset | localFallback | snapshotRemaining | none`.

### 🧪 Validation run (local):

- `dart analyze lib/presentation/viewmodels/pomodoro_view_model.dart test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
  → PASS (2 info-level style hints in test helper only).
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart --reporter compact`
  → PASS (`11/11`).
  - Includes previously failing Phase 3 contracts:
    - transitional non-active snapshot must not clear hold,
    - non-owner recovery via server read,
    - hold diagnostics with projection source.

### ⚠️ Notes:

- Device validation is still pending for this runtime phase.
- Existing unrelated local modifications were preserved
  (`docs/bugs/...`, `ios/Flutter/AppFrameworkInfo.plist`).

---

# 🔹 Block 568 — Fix 26 Phase 4 contract draft: render/sync decoupling + overlay-trigger diagnostics (12/03/2026)

**Date:** 12/03/2026  
**Branch:** `refactor-run-mode-sync-core`  
**Scope:** Documentation-first Phase 4 delta after validation evidence showed
freeze reproduction outside the Phase 3 hold path.

### ✔ Work completed:

- Updated `docs/specs.md` section **10.4.8.b** with Phase 4 contracts:
  - render/sync decoupling invariant (active countdown projection from
    `phaseStartedAt` + elapsed; `session.remainingSeconds` seed-only),
  - non-blocking overlay invariant (`Syncing session...` must not freeze active
    countdown rendering),
  - mandatory overlay-trigger diagnostics with explicit reason taxonomy:
    `sessionMissingHold | runningWithoutSession | timeSyncUnready |
awaitingSessionConfirmation`,
  - deterministic `primaryReason` priority and required transition payload.
- Added Phase 4 contract tests (no runtime implementation) in:
  - `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
    - `[PHASE4] active projection must continue with local fallback when timeSync is unavailable`
  - `test/presentation/timer_screen_syncing_overlay_test.dart`
    - `[PHASE4] sync overlay diagnostics must emit explicit trigger reason (timeSyncUnready)`

### 🧪 Validation run (local):

- `dart analyze test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart`
  → PASS (2 info-level style hints in existing test helper only).
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart --reporter compact`
  → FAIL (expected contract-first failure):
  - `[PHASE4] active projection must continue with local fallback when timeSync is unavailable`
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --reporter compact`
  → FAIL (expected contract-first failure):
  - `[PHASE4] sync overlay diagnostics must emit explicit trigger reason (timeSyncUnready)`

### ⚠️ Notes:

- No runtime changes were made in this block.
- This block formalizes Phase 4 target behavior before implementation.

---

# 🔹 Block 569 — Fix 26 Phase 4 runtime: local-fallback projection + sync-overlay diagnostics (12/03/2026)

**Date:** 12/03/2026  
**Branch:** `refactor-run-mode-sync-core`  
**Scope:** Implement Phase 4 runtime contracts to decouple countdown rendering
from sync/offset availability and to expose deterministic diagnostics for
`Syncing session...` transitions.

### ✔ Work completed:

- Updated `lib/presentation/viewmodels/pomodoro_view_model.dart`:
  - projection fallback:
    - `_projectionNowForSession(...)` now falls back to local time when server
      offset is unavailable (while still triggering async TimeSync refresh),
    - active render projection no longer returns `null` anchor in account mode
      during offset gaps.
  - hold diagnostics projection source:
    - `_projectionSourceForSession(...)` now reports `localFallback` (instead of
      `snapshotRemaining`) when timeline anchors exist but offset is unavailable.
  - sync-overlay diagnostics:
    - added deterministic trigger derivation in ViewModel for:
      `sessionMissingHold`, `runningWithoutSession`,
      `awaitingSessionConfirmation`, `timeSyncUnready`,
    - added `[SyncOverlay]` transition log emission with:
      `overlayVisibleBefore/After`, `activeReasons`, `primaryReason`, `groupId`,
    - diagnostics are emitted from ViewModel state/meta transitions, not inline
      in widget build logic.
  - state/meta hooks:
    - `_notifySessionMetaChanged()` and `_applyProjectedState(...)` now reconcile
      and emit sync-overlay transition diagnostics on change.

- Updated test coverage:
  - `test/presentation/timer_screen_syncing_overlay_test.dart`:
    - stabilized debug-print restoration ordering in the new Phase 4 diagnostics
      test to avoid widget-test foundation invariant violations.

### 🧪 Validation run (local):

- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart --reporter compact`
  → PASS (`14/14`).
- `dart analyze lib/presentation/viewmodels/pomodoro_view_model.dart test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart`
  → PASS (2 pre-existing info-level style hints in test helper).

### ⚠️ Notes:

- Device validation remains pending for this runtime phase.
- Existing unrelated local modifications were preserved
  (`docs/bugs/...`, `ios/Flutter/AppFrameworkInfo.plist`).

---

# 🔹 Block 570 — Fix 26 Phase 5 docs-first: VM/session lifecycle observability contract (13/03/2026)

**Date:** 13/03/2026  
**Branch:** `refactor-run-mode-sync-core`  
**Scope:** Documentation-first diagnostic phase to pinpoint the `_sessionSub`
loss trigger observed in device logs, without changing runtime behavior.

### ✔ Work completed:

- Updated `docs/specs.md` section **10.4.8.b** with a Phase 5
  observability-only contract:
  - mandatory stable `vmToken` per `PomodoroViewModel` instance,
  - mandatory `[VMLifecycle]` init/dispose logs with token correlation,
  - mandatory `[SessionSub]` open/close logs with explicit `reason`,
  - mandatory scheduled-action bridge diagnostics with action metadata +
    token correlation,
  - mandatory `_clearStaleActiveSessionIfNeeded` decision diagnostics with
    structured fields (`sessionGroupId`, lookup status, clear/keep decision).
- Added Phase 5 smoke tests (contract-first, expected to fail before runtime):
  - `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
    - `[PHASE5] VM lifecycle/session-sub diagnostics must include vmToken and lifecycle reasons`
  - `test/presentation/timer_screen_syncing_overlay_test.dart`
    - `[PHASE5] sync overlay diagnostics must include vmToken for lifecycle correlation`
  - `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
    - `[PHASE5] scheduled-action diagnostics must include vmToken and action metadata`
    - `[PHASE5] stale-clear diagnostics must include instance token and clear decision metadata`
- Updated project tracking docs to mark Phase 5 as opened in docs-first mode:
  - `docs/roadmap.md` (global status + reopened phases),
  - `docs/validation/validation_ledger.md` (new Fix 26 Phase 5 pending item).

### 🧪 Validation run (local):

- `dart analyze` on updated docs/tests target set → PASS (or info-only).
- Phase 5 smoke tests are intentionally contract-first and expected to fail
  until runtime instrumentation is implemented in the next phase.

### ⚠️ Notes:

- No runtime behavior changes were made in this block.
- Phase 6 scope remains blocked on Phase 5 diagnostic evidence from device logs.

---

# 🔹 Block 571 — Fix 26 Phase 5 runtime: vmToken lifecycle instrumentation (13/03/2026)

**Date:** 13/03/2026  
**Branch:** `refactor-run-mode-sync-core`  
**Scope:** Implement runtime diagnostics required by the Phase 5 observability
contract (no business-behavior changes).

### ✔ Work completed:

- Updated `lib/presentation/viewmodels/pomodoro_view_model.dart`:
  - added stable `vmToken` per `PomodoroViewModel` instance (`Uuid.v4()`),
  - added `[VMLifecycle] init|dispose` diagnostics,
  - added `[SessionSub] open|close` diagnostics with explicit `reason`,
  - replaced raw subscription close calls with reasoned helper paths:
    `load-group`, `resume-rebind`, `mode-switch`, `provider-dispose`,
  - extended `[SyncOverlay]` diagnostics payload with `vmToken`.
- Updated `lib/presentation/viewmodels/scheduled_group_coordinator.dart`:
  - added stable coordinator instance token (`vmToken` field in diagnostics),
  - added `[ScheduledActionDiag]` on `openTimer`/`lateStartQueue` emission with
    action type/token and payload metadata,
  - added `[StaleClearDiag]` on `_clearStaleActiveSessionIfNeeded` evaluations
    with `sessionGroupId`, lookup source/status, decision (`clear|keep`), and reason.

### 🧪 Validation run (local):

- `dart analyze lib/presentation/viewmodels/pomodoro_view_model.dart lib/presentation/viewmodels/scheduled_group_coordinator.dart test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
  → PASS (2 pre-existing info-level style hints in test helper only).
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart --reporter compact`
  → PASS (`16/16`).
- Phase 5 smoke tests:
  - `flutter test ...pomodoro_view_model_session_gap_test.dart --plain-name "[PHASE5]"`
    → PASS,
  - `flutter test ...timer_screen_syncing_overlay_test.dart --plain-name "[PHASE5]"`
    → PASS,
  - `flutter test ...scheduled_group_coordinator_test.dart --plain-name "[PHASE5]"`
    → PASS.

### ⚠️ Notes:

- Full `scheduled_group_coordinator_test.dart` still contains pre-existing
  `AppModeService` harness failures outside Phase 5 scope.
- Phase 6 remains blocked until device validation captures the new diagnostics
  and identifies the exact `_sessionSub` loss trigger path.

---

# 🔹 Block 572 — Fix 26 Phase 5 device validation: root cause confirmed (13/03/2026)

## 📋 Context

Phase 5 device run on commit `7daf636` with 4 devices (Android RMX3771 release, macOS
release, iOS iPhone17Pro debug, Chrome debug). Group `aa8794d0`, scheduled 14:43, owner
macOS. All devices froze with `Syncing session...` / `Ready + 25:00` between 15:30 and
15:35. macOS crashed at 15:48 (SIGSEGV).

## 🔍 Key findings from Phase 5 logs

### Chrome (debug log — full trace available)

Last event sequence before freeze:

```
15:30:08.572  [ActiveSession][snapshot] remaining=773  ← last Firestore snapshot
15:30:24.996  [ActiveSession][snapshot] remaining=773  ← stale resync (unchanged)
+10017 ms gap (no Firestore events)
[SessionSub] close vmToken=b2ce33ee reason=provider-dispose
[VMLifecycle] dispose vmToken=b2ce33ee
[ScheduledGroups] timer-state runningExpiry=true        ← coordinator still alive
[RunModeDiag] Auto-open suppressed (opened=aa8794d0 route=/timer/aa8794d0)
```

- `provider-dispose` fired while the timer screen was still on `/timer/aa8794d0`
- No `[VMLifecycle] init` appeared after dispose → no VM recovery
- Coordinator saw `decision=keep reason=group-running` continuously — session was NOT deleted

### iOS (debug log)

Identical pattern: `provider-dispose` 18.6s after last Firestore activity. Same
`Auto-open suppressed` guard block.

### Android / macOS (release logs)

Phase 5 diagnostic events absent in `--release` mode (need debug for next run).
macOS showed frozen RUNNING timer (not Ready) — consistent with owner's
`_machine.state.status.isActiveExecution` keeping keepAlive alive longer.
macOS crash at 15:48:18 (SIGSEGV `EXC_BAD_ACCESS`) — Firestore transaction path, unrelated to Fix 26.

### Codex corrections on the diagnosis

1. `pomodoroViewModelProvider` confirmed `autoDispose` at `providers.dart:325` ✓
2. `[StaleClearDiag]` events have coordinator `vmToken` (not VM token) — separate instance ✓
3. `runningExpiry=true` = `_runningExpiryTimer` was armed at time of `_handleGroupsAsync` entry, NOT that the group expired ✓
4. macOS crash thread is Firestore transaction, not Flutter build recursion ✓

## 🐛 Two confirmed sub-bugs

### B1 — autoDispose keepAlive race condition

`pomodoroViewModelProvider` is `NotifierProvider.autoDispose`. The `_keepAliveLink`
can close during a Firestore quiet window (10–18s between snapshots) if
`_syncKeepAliveState()` is called at a moment where all of:

- `_machine.state.status.isActiveExecution` → false
- `_latestSession?.status.isActiveExecution` → false/null
- `_remoteSession?.status.isActiveExecution` → false/null

Then Riverpod disposes the VM even though the session is still running in Firestore.

### B2 — Auto-open guard blocks recovery navigation

`ActiveSessionAutoOpener._autoOpenedGroupId == groupId` suppresses re-navigation
without checking if the VM was disposed. After a `provider-dispose`, the screen stays
on `/timer/groupId` with a dead ViewModel showing `Ready + 25:00`.
`ref.exists(pomodoroViewModelProvider)` is not checked.

## 📐 Phase 6 plan (docs-first, contracts in specs.md section 10.4.9)

### B1 fix

Add `DateTime? _lastActiveSessionTimestamp` to `PomodoroViewModel`. Update it whenever
`_ingestResolvedSession` processes a snapshot with `isActiveExecution == true`. In
`_shouldKeepAlive()`, add:

```dart
final lastActive = _lastActiveSessionTimestamp;
if (lastActive != null &&
    DateTime.now().difference(lastActive) < const Duration(minutes: 2)) return true;
```

2-minute grace window > Firestore reconnect window (≤ 30s) and < stale threshold.

### B2 fix

In `active_session_auto_opener.dart` at the suppression block (line ~147):

```dart
if (_autoOpenedGroupId == groupId && !ref.exists(pomodoroViewModelProvider)) {
  // VM was disposed while screen still showed timer — allow recovery
  _autoOpenedGroupId = null;
  // fall through to navigation
} else {
  return; // normal suppression
}
```

### Android/iOS validation note

For the next run, use `--debug` on ALL devices to capture Phase 5 diagnostic events.
Release mode strips them.

## ✅ Status

- Root cause confirmed. Phase 6 plan written. Implementation pending.

---

# 🔹 Block 573 — Fix 26 Phase 6 runtime: B1 keepAlive grace + B2 auto-open recovery (13/03/2026)

## 📋 Context

Phase 5 validation confirmed two runtime bugs:

- **B1**: `autoDispose` race disposed `PomodoroViewModel` during Firestore quiet windows.
- **B2**: `ActiveSessionAutoOpener` suppressed re-navigation for an already-opened
  group without verifying whether the VM had already been disposed.

Implementation commit:

- `2fc65e4` — `fix(f26): implement phase 6 runtime keepalive grace + auto-open recovery`

Phase 6 contract was defined in `docs/specs.md` section **10.4.9** before coding.

## ✔ Work completed

- Updated `lib/presentation/viewmodels/pomodoro_view_model.dart`:
  - added `_lastActiveSessionTimestamp` (local processing time stamp),
  - added keepAlive grace policy (`_defaultKeepAliveGraceWindow = 2 min`),
  - added grace timer re-check (`_keepAliveGraceTimer`) to release keepAlive
    once grace expires when no active execution signal remains,
  - extended `_syncKeepAliveState()` / `_shouldKeepAlive()` with explicit
    active-signal and grace-window logic,
  - synchronized keepAlive state after stream-null handling and after resolved
    session ingestion to avoid stale keepAlive decisions.
- Updated `lib/widgets/active_session_auto_opener.dart`:
  - added VM existence transition tracking via
    `ref.exists(pomodoroViewModelProvider)`,
  - added recovery branch that clears stale `_autoOpenedGroupId` when VM was
    disposed while session remains active,
  - added forced timer refresh navigation path (`/timer/:id?refresh=...`) under
    recovery mode, while preserving in-flight and bounce-window protections.
- Added Phase 6 contract tests:
  - `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
    (`[PHASE6]` keepAlive grace behavior),
  - `test/presentation/timer_screen_syncing_overlay_test.dart`
    (`[PHASE6]` auto-open guard recovery after VM disposal).

## 🧪 Validation run (local)

- `dart analyze lib/presentation/viewmodels/pomodoro_view_model.dart lib/widgets/active_session_auto_opener.dart test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/timer_screen_syncing_overlay_test.dart`
  - PASS (2 pre-existing info-level hints in existing test helper).
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart --plain-name "[PHASE6]" --reporter compact`
  - PASS.
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "[PHASE6]" --reporter compact`
  - PASS.

## ⚠️ Notes

- Phase 6 is **not closed** yet: device exact repro + regression smoke packet is
  still required before marking Closed/OK in validation docs.
- Ledger updated:
  - `P0-F26-004` moved to Closed/OK (Phase 5 diagnostics objective completed),
  - `P0-F26-005` opened In validation for Phase 6 runtime closure criteria.

---

# 🔹 Block 574 — Phase 6 device validation runbook registration (13/03/2026)

## 📋 Context

After Phase 6 runtime commit (`2fc65e4`), device validation needed explicit and
unambiguous log destinations for the two execution windows:

- pass 1 (1h, same day),
- pass 2 (4h30 soak, next day).

## ✔ Work completed

- Updated `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md`:
  - added fixed-device run commands in `--debug` for:
    - `RMX3771`,
    - `iPhone 17 Pro`,
    - `macOS`,
    - `Chrome`;
  - registered definitive log filenames for:
    - `2026-03-13 ... pass1_1h ...`,
    - `2026-03-14 ... pass2_4h30 ...`;
  - added grep patterns for Phase 6 diagnostic verification
    (`[VMLifecycle]`, `[SessionSub]`, `[SyncOverlay]`, `[HoldDiag]`,
    `Auto-open recovery`, crash/error signatures).
- Updated `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md`:
  - added planned packet A/B sections with exact log paths for both passes,
  - aligned closure gate text for `P0-F26-005`.

## ⚠️ Notes

- No runtime code changes in this block (docs-only validation logistics).
- Phase 6 remains **In validation** until exact repro + regression smoke + soak
  evidence are captured in the registered logs.

---

# 🔹 Block 575 — Phase 6 device validation FAILED + architecture rewrite decision (14/03/2026)

## 📋 Context

Phase 6 (commit `2fc65e4`) was a focalized fix for two root causes confirmed in Phase 5
device validation (2026-03-13):

- **B1**: `pomodoroViewModelProvider` disposed during Firestore quiet window (10s gap) →
  `_sessionSub` torn down → new listener emits `null` → 3s debounce → latch.
  Fix: 2-minute `keepAlive` grace window via `_lastActiveSessionTimestamp`.
- **B2**: `_autoOpenedGroupId == groupId` guard in `ActiveSessionAutoOpener` blocks
  re-navigation after VM disposal.
  Fix: `ref.exists()` check to detect disposed VM and clear guard.

## ❌ Validation result — FAILED

**Pass 1 (2026-03-13, ~1h, 4 devices RMX3771 / iPhone 17 Pro / macOS / Chrome):**

- 22:10:00 — 10s manual network cut on iOS/Chrome/macOS → **no Syncing session** (B1 working)
- 22:21:37 — Android (owner) entered `Syncing session...` **spontaneously** (no user cut)
  - Last session write: `lastUpdatedAt=22:21:20`, `remainingSeconds=521`, `sessionRevision=7`
  - Stream emitted null for ≥3s → debounce fired → latch engaged
  - 22:22:01: Syncing cleared but timer **frozen at 08:25**
- 22:23:14 — macOS: `Syncing session...`, showing "ready" 15:00 (iOS now owner)
- 22:23:26 — Chrome: same as macOS
- 22:25:44 — iOS: `Syncing session...`, timer 04:22 frozen
- 22:26:01 — iOS cleared Syncing but timer remained frozen
- 22:37:50 — validation ended; Android recovered on wake from screen-off (owner = iOS)

**Pass 2 (4h30 soak) cancelled** — exact repro already reproduced in pass 1.

## 🔍 Root cause of failure

B1 fixed the **VM-disposal trigger path**. The spontaneous Android freeze at 22:21:37
was caused by a **different path**: Firebase SDK internal event (auth token refresh /
Firestore reconnect / cache miss) caused the session stream to emit `null` for ≥3s
**while the VM was still alive**. The 3-second debounce then latched
`_sessionMissingWhileRunning = true` → freeze.

This trigger path has always existed (AP-2). The 3s debounce was the only protection.
It is insufficient for SDK-internal reconnect cycles.

## 🏛️ Architecture decision — rewrite required

All focalized hardenings (Phases 2–6) have been exhausted without eliminating the bug.
The problem is **structural**:

1. **Timer and session sync are tightly coupled** in an autoDisposable ViewModel.
   Any stream null → timer freeze. No separation between "I have no data" and "timer must stop".

2. **`_sessionMissingWhileRunning` latch** activates on any transient null (3s debounce)
   and has complex, multi-path recovery that fails silently when ownership changes.

3. **Ephemeral ViewModel for critical state** — `autoDispose` was the wrong choice for
   the most critical runtime state in the app.

**Decision (agreed by Claude + Codex, 2026-03-14):** no more focalized hardenings.
Next step is a sync architecture rewrite with these principles:

- `TimerService` — persistent (non-autoDispose), never interrupted by network events
- `SessionSyncService` — background reconciler; adjusts timer drift without blocking it
- **Optimistic rendering**: always show last known good state; escalate to error only after
  N seconds with zero signal from all sources (stream + fetch + group state)
- **No freeze on stream null**: "Syncing session..." overlay = informational, timer keeps running
- **Deterministic recovery state machine**: explicit states, explicit transitions, no implicit latches

## 📁 Updated docs

- `docs/validation/validation_ledger.md`: P0-F26-005 → Failed — exact repro FAIL 2026-03-14
- `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md`: Phase 6 → FAILED
- `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md`: packets → FAILED + cancelled
- `docs/roadmap.md`: Phase 6 entry replaced with "Sync architecture rewrite required"

---

# 🔹 Block 576 — iOS plist normalization confirmed + Git safety runbook finalized (14/03/2026)

## 📋 Context

After repeated iOS runs, `ios/Flutter/AppFrameworkInfo.plist` kept appearing as modified.
In parallel, branch safety guidance needed a deterministic, low-risk sequence to avoid
progress loss while moving toward the sync rewrite branch.

## ✔ Work completed

- Verified and confirmed `AppFrameworkInfo.plist` is now aligned to Flutter-generated output
  (`MinimumOSVersion` removed) under commit `1b1dc33`.
- Verified the branch graph state:
  - `fix26-reopen-black-syncing-2026-03-09` is fully contained in
    `refactor-run-mode-sync-core`.
  - `refactor-run-mode-sync-core` is synced with `origin` at `51ccf0a`.
- Finalized `docs/git_strategy.md` for executable, safe Git operations:
  - corrected stale commit references,
  - corrected failed-state tag target hash to `b1cb17e`,
  - standardized policy for no merge to `main` with P0 bug open,
  - documented rewrite branch creation flow from current refactor head.

## 📁 Updated docs

- `docs/git_strategy.md`
- `docs/dev_log.md`

## ⚠️ Notes

- No runtime code changes in this block (docs/process only).
- Next implementation branch remains pending: `rewrite-sync-architecture`.

---

# 🔹 Block 577 — Rewrite docs-first contract opened (14/03/2026)

## 📋 Context

After Phase 6 failure (`P0-F26-005`), rewrite work moved to branch
`rewrite-sync-architecture` with a strict docs-first gate: no runtime code and no
`[REWRITE-CORE]` tests before contract review approval.

## ✔ Work completed

- Updated roadmap to mark rewrite branch opening and the explicit review gate
  before tests/runtime edits.
- Added rewrite architecture contract draft in `docs/specs.md` section 10.4.10,
  including these mandatory invariants:
  1. **TimerService persistence model:** app-scope Riverpod `NotifierProvider`
     (non-autoDispose), lifecycle bound to `ProviderContainer`.
  2. **Stream-null policy:** exact thresholds and behavior (`<3s` no visual change,
     `>=3s` non-blocking syncing overlay, `>=45s` recovery mode with timer still running).
  3. **Ownership stale timeout policy:** keep 45s unchanged in rewrite v1.
  4. **Cutover strategy:** staged dual-path migration (services first, adapter switch,
     then legacy-path cleanup after parity validation).
- Updated validation ledger with new P0 item `P0-F26-006` (rewrite contract)
  and explicit block on tests until contract approval.

## 📁 Updated docs

- `docs/specs.md`
- `docs/roadmap.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## ⚠️ Notes

- No `lib/` edits in this block.
- No test changes in this block.
- Next step is contract review/approval; only after approval can `[REWRITE-CORE]`
  tests be introduced.

---

# 🔹 Block 578 — Rewrite contract refinement: interfaces required for test design (14/03/2026)

## 📋 Context

Contract review feedback approved rewrite direction in principle but blocked
`[REWRITE-CORE]` test authoring until concrete interfaces were defined.

## ✔ Work completed

- Refined `docs/specs.md` section 10.4.10 with concrete interface contracts:
  - `TimerRuntimeState` minimal required fields (group/task/status/phase/remaining/
    counters/phase anchor/owner/sync health).
  - `SessionSyncService` API contract and strict one-way integration
    (`SessionSyncService` -> `TimerService`) for runtime updates.
  - `PomodoroViewModel` adapter contract for Stage A/B compatibility
    (`Notifier<PomodoroState>` remains UI-facing while runtime authority lives
    in persistent `TimerService`).
- Kept ownership stale timeout policy at 45s and reaffirmed stream-null
  non-freeze semantics.
- Updated roadmap and validation ledger to reflect the refined contract and
  continued review gate before tests/runtime edits.

## 📁 Updated docs

- `docs/specs.md`
- `docs/roadmap.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## ⚠️ Notes

- No runtime code changes in this block.
- No tests added in this block.
- Next step remains contract approval; only then `[REWRITE-CORE]` tests can start.

---

# 🔹 Block 579 — REWRITE-CORE tests authored (red-first baseline, no runtime edits) (14/03/2026)

## 📋 Context

With contract section 10.4.10 approved in principle, next step was to author
`[REWRITE-CORE]` tests before runtime changes.

## ✔ Work completed

- Added 5 rewrite contract tests to:
  - `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
- Coverage target: invariants from specs 10.4.10.7:
  1. stream null must not freeze countdown progression,
  2. syncing state is informational (active execution preserved),
  3. authoritative transitions originate from `TimerService`,
  4. ownership recovery is deterministic via explicit state machine,
  5. VM dispose/rebuild must not reset runtime continuity.
- Executed targeted subset:
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart --plain-name "[REWRITE-CORE]" --reporter compact`
- Result: **1 pass / 4 fail** (expected red-first baseline).
  - Invariant 1 failed (countdown froze during stream-null hold).
  - Invariants 3/4/5 are contract-gate failures pending rewrite runtime.

## 📁 Updated docs/code

- `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
- `docs/roadmap.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## ⚠️ Notes

- No runtime `lib/` edits in this block.
- Red baseline confirmed; next step is runtime implementation to make
  `[REWRITE-CORE]` green.

---

# 🔹 Block 580 — Rewrite Stage A runtime partial: TimerService gap projection (14/03/2026)

## 📋 Context

`[REWRITE-CORE]` red-first baseline (`11d3866`) confirmed Invariant 1 regression:
countdown froze after stream-null latch (`_sessionMissingWhileRunning`).

Stage A target was to decouple countdown continuity from latch freeze without
changing ownership/handoff contracts yet.

## ✔ Work completed

- Added new runtime service:
  - `lib/data/services/timer_service.dart`
  - app-scope `Notifier<TimerRuntimeState>` with non-autoDispose provider
    contract fields (`groupId`, `currentTaskId`, `status`, `phase`,
    `remainingSeconds`, `totalSeconds`, pomodoro counters, `phaseStartedAt`,
    `ownerDeviceId`, `syncHealth`).
- Registered `timerServiceProvider` in `lib/presentation/providers.dart` as
  `NotifierProvider<TimerService, TimerRuntimeState>` (non-autoDispose).
- Wired `PomodoroViewModel` to Stage A runtime path:
  - ingests active snapshots into `TimerService` (`applyOwnerSnapshot`),
  - on debounce latch fire, signals `notifySessionGap(...)`,
  - projects countdown from `TimerService` while `sessionMissingHold` is active,
    preventing freeze in the null-stream hold window,
  - clears service tick when session is authoritatively cleared.
- Preserved legacy ownership/request/handoff behavior (no Stage B/C migration in this block).

## 🧪 Validation run (local)

- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart --plain-name "[REWRITE-CORE]" --reporter compact`
  - Result: **2 pass / 3 fail**
  - PASS: Invariant 1 (`stream null must not freeze countdown progression`)
  - PASS: Invariant 2 (`syncing state remains informational`)
  - FAIL (intentional contract gates): Invariants 3/4/5
- Regression smoke:
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart --plain-name "[PHASE" --reporter compact` → PASS
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart test/presentation/timer_screen_syncing_overlay_test.dart --reporter compact` → PASS
- `flutter analyze` (touched scope) → PASS with 2 pre-existing info hints in test code (`use_super_parameters`).

## 📁 Updated files

- `lib/data/services/timer_service.dart` (new)
- `lib/presentation/providers.dart`
- `lib/presentation/viewmodels/pomodoro_view_model.dart`
- `docs/roadmap.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## ⚠️ Notes

- Stage A is intentionally partial: Invariants 3/4/5 remain pending until
  TimerService-authoritative command delegation, deterministic recovery state machine,
  and VM continuity contract tests are implemented.
- No merge/closure yet for `P0-F26-006`.

---

# 🔹 Block 581 — Rewrite Invariant 5 promoted to executable test (14/03/2026)

## 📋 Context

After Stage A runtime bridge (`248d963`), `[REWRITE-CORE]` still had three pending
contract-gate failures (Invariants 3/4/5). Invariant 5 became testable because
`TimerService` is now app-scope and non-autoDispose.

## ✔ Work completed

- Replaced Invariant 5 `fail()` gate in:
  - `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
- New test behavior for Invariant 5:
  - load active group/session,
  - force stream-null hold (debounce expiry) so runtime countdown is controlled by
    `TimerService` degraded projection,
  - dispose the VM boundary (`vmSub.close()` + `container.invalidate(pomodoroViewModelProvider)`),
  - verify `timerServiceProvider.remainingSeconds` keeps decrementing while VM is disposed,
  - rebuild VM listener and verify runtime was not reset.

## 🧪 Validation run (local)

- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart --plain-name "[REWRITE-CORE]" --reporter compact`
  - Result: **3 pass / 2 fail**
  - PASS: Invariants 1, 2, 5
  - FAIL (intentional contract gates): Invariants 3, 4
- Full rewrite-related suite:
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart test/presentation/timer_screen_syncing_overlay_test.dart --reporter compact`
  - Result: **26 pass / 2 fail**
  - Only fails are intentional gates for Invariants 3 and 4.
- `flutter analyze` (touched scope) → PASS with 2 pre-existing info hints in test code (`use_super_parameters`).

## 📁 Updated files

- `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
- `docs/roadmap.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## ⚠️ Notes

- No new runtime `lib/` edits in this block.
- Next runtime milestones remain Invariant 3 (authoritative TimerService command path)
  and Invariant 4 (deterministic ownership recovery state machine).

---

# 🔹 Block 582 — Stage B docs/test gate activated (14/03/2026)

## 📋 Context

After Stage A, rewrite baseline was `3 PASS / 2 FAIL`, but Invariants 3/4 still needed
executable (non-placeholder) red tests tied to explicit Stage B contracts.

## ✔ Work completed

- Updated `docs/specs.md` with Stage B contracts:
  - `10.4.10.8` command delegation contract (`_startInternal/_pauseInternal/_resumeInternal/cancel` -> `TimerService` APIs),
  - `10.4.10.9` deterministic ownership recovery state machine contract
    (`OwnershipSyncState`: `unloaded|owned|mirroring|degraded|recovery`).
- Replaced Stage B contract gates in
  `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`:
  - Invariant 3 is now an executable red assertion (no `fail()` stub),
  - Invariant 4 is now an executable red assertion (no `fail()` stub).
- Stabilized Invariant 3 failure mode to avoid timeout/lifecycle race:
  - switched from `vm.start()` timeout-prone path to deterministic `vm.pause()`
    delegation check,
  - kept failure focused on missing `TimerService` authoritative transition.

## 🧪 Validation run (local)

- Rewrite-only gate:
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart --plain-name "[REWRITE-CORE]" --reporter compact`
  - Result: **3 PASS / 2 FAIL**
  - PASS: Invariants 1, 2, 5
  - FAIL (expected Stage B runtime pending):
    - Invariant 3: `TimerService` status does not reflect `vm.pause()` authoritative command path yet
    - Invariant 4: `ownershipSyncState` observable contract not exposed yet
- Full smoke set:
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart test/presentation/timer_screen_syncing_overlay_test.dart --reporter compact`
  - Result: **26 PASS / 2 FAIL**
  - Only failing tests are the two expected Stage B rewrite invariants (3/4).

## 📁 Updated files

- `docs/specs.md`
- `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
- `docs/roadmap.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## ⚠️ Notes

- No new runtime `lib/` edits in this block (docs/tests only).
- Next step remains Stage B runtime implementation for Invariants 3/4.

---

# 🔹 Block 583 — Stage B runtime green (Invariants 3/4) (14/03/2026)

## 📋 Context

After Block 582, Stage B had executable red tests for Invariants 3/4:

- Invariant 3 failed because VM command intent (`pause`) did not update `TimerService` runtime status.
- Invariant 4 failed because `PomodoroViewModel` did not expose observable `ownershipSyncState`.

## ✔ Work completed

### Commit A — `4112408`

`refactor(f26): delegate vm start/pause/resume commands to timer service`

- `PomodoroViewModel` now delegates command path to `TimerService`:
  - `_startInternal` -> `_timerService.startTick(...)`
  - `_pauseInternal` -> `_timerService.pauseTick()`
  - `_resumeInternal` -> `_timerService.resumeTick()`
- `TimerService` start/resume now respect health mode for ticker activation:
  - ticker runs only when `syncHealth != healthy` (prevents reintroducing pending-timer regressions in healthy UI/widget scenarios).

### Commit B — `617cae4`

`refactor(f26): expose deterministic ownership sync state in vm`

- Added `OwnershipSyncState` enum:
  - `unloaded`, `owned`, `mirroring`, `degraded`, `recovery`
- Added `PomodoroViewModel.ownershipSyncState` getter:
  - returns deterministic stable states from current ownership snapshot,
  - transitions to `degraded/recovery` while missing-session hold is active based on gap duration (`<45s` / `>=45s`).

## 🧪 Validation run (local)

- Rewrite gate:
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart --plain-name "[REWRITE-CORE]" --reporter compact`
  - Result: **5 PASS / 0 FAIL**
  - Invariants 1–5 all green.

- Smoke suite:
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart test/presentation/timer_screen_syncing_overlay_test.dart --reporter compact`
  - Result: **28 PASS / 0 FAIL**

## 📁 Updated files

- `lib/data/services/timer_service.dart`
- `lib/presentation/viewmodels/pomodoro_view_model.dart`
- `lib/presentation/viewmodels/ownership_sync_state.dart`
- `docs/roadmap.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## ⚠️ Notes

- Stage B contract is now green locally.
- Stage C (cleanup/removal of obsolete latch/freeze paths) and multi-device validation remain pending before closure.

---

# 🔹 Block 584 — Device validation runbook registered with exact IDs (14/03/2026)

## 📋 Context

After Stage B local green, next mandatory gate is real-device exact repro packet for `P0-F26-006`.
User provided exact current selectors/IDs for all 4 targets.

## ✔ Work completed

- Updated validation docs with exact device selectors:
  - Android USB `HYGUT4GMJJOFVWSS` (RMX3771)
  - iOS `9A6B6687-8DE2-4573-A939-E4FFD0190E1A` (iPhone 17 Pro)
  - macOS `macos`
  - Chrome `chrome`
- Added command blocks for pass1 (1h) on current rewrite baseline `3b11847`.
- Added explicit log URLs/paths for each device output file.
- Registered this packet in global ledger (`P0-F26-006`) as next active validation gate.

## 📁 Updated files

- `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md`
- `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## ⚠️ Notes

- Run protocol for exact repro packet remains: no manual network cut, no manual pause/resume.
- Stage C remains blocked until this device packet is executed and analyzed.

---

# 🔹 Block 585 — Claude/Codex role contract formalized (14/03/2026)

## 📋 Context

Collaboration needed explicit, non-ambiguous role boundaries between Claude
(architecture/review) and Codex (implementation/tests), plus a mandatory
handoff format to avoid drift during the sync rewrite.

## ✔ Work completed

- Updated `AGENTS.md` with an authoritative "Role Operating Model" section:
  - Canonical source pointer to `docs/team_roles.md`
  - Operational split (Claude vs Codex)
  - Mandatory handoff payload
  - Conflict-resolution rule against specs and guardrails
- Replaced `docs/team_roles.md` with an operational contract:
  - Role A (Claude) responsibilities and constraints
  - Role B (Codex) responsibilities and constraints
  - Mandatory handoff format
  - Full-cutover enforcement rules ("no dual-path authority")
  - Quick responsibility matrix

## 📁 Updated files

- `AGENTS.md`
- `docs/team_roles.md`
- `docs/dev_log.md`

## ⚠️ Notes

- Process/documentation change only (no runtime logic change).
- Existing uncommitted runtime work on rewrite branch remains untouched.

---

# 🔹 Block 586 — SSS authority cutover completed (14/03/2026)

## 📋 Context

After Stage B runtime green, the remaining architectural blockers were:

- VM still owning missing-session recovery paths,
- dual-path hold mutations (VM + SessionSyncService),
- keepAlive coupling to `_sessionMissingWhileRunning`,
- stream loading/error states being interpreted as missing-session null events.

Goal of this block: complete the cutover so `SessionSyncService` + `TimerService`
are the sole runtime/sync authority and keep VM as UI adapter.

## ✔ Work completed

- `SessionSyncService` now owns missing-session recovery:
  - introduced `RecoveryStatus` (`idle | attempting | failed`),
  - added internal recovery loop (`_attemptRecovery`, `_recoverFromServer`,
    cooldown + retry scheduling),
  - recovery updates are emitted through SSS state (VM no longer recovers).
- Removed VM hold/recovery authority:
  - deleted VM recovery methods (`_attemptMissingSessionRecovery`,
    `_recoverMissingSession*`),
  - removed all VM calls to `extendHold/clearHold`.
- Hardened stream semantics in SSS:
  - `_handleStreamEvent` now ignores non-`AsyncData` states
    (`AsyncLoading`/`AsyncError`) explicitly.
- KeepAlive authority aligned to runtime:
  - `_hasKeepAliveActiveExecutionSignal` now uses
    `timer.isTickingCandidate || recoveryStatus == attempting`,
  - `_shouldKeepAlive` no longer gates directly on `_sessionMissingWhileRunning`.
- Added regression tests:
  - `stream AsyncError does not trigger missing-session hold latch`,
  - `stream AsyncLoading does not trigger missing-session hold latch`.

## 🧪 Validation run (local)

- `flutter analyze` → **No issues found**.
- Mandatory suite:
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart test/presentation/timer_screen_syncing_overlay_test.dart`
  - Result: **30/30 PASS**.

## 📁 Updated files

- `lib/presentation/viewmodels/session_sync_service.dart`
- `lib/presentation/viewmodels/pomodoro_view_model.dart`
- `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
- `docs/dev_log.md`

## ⚠️ Notes

- Architectural cutover is locally green and ready to be used as baseline for
  the 4-device validation packet.
- Open low-priority observation:
  transient race windows around remote pause propagation may require follow-up
  hardening in a later block if observed in device logs.

---

# 🔹 Block 587 — GAP-1 + GAP-2 closed before Stage C validation (14/03/2026)

## 📋 Context

Full architectural review of all docs (specs, bug_log, dev_log, roadmap, validation
plans) against the Stage C baseline (`aa2d09b`) identified two code gaps that had to
be closed before device validation could produce a valid result.

## ✔ Work completed

### GAP-1 — `_stopForegroundService()` removed from `_onHoldStarted()`

- **Root cause:** `_onHoldStarted()` was calling `ForegroundService.stop()`, killing the
  Android foreground service exactly when a network cut triggers the hold. Without the
  foreground service, the OS is free to kill the process; `TimerService` and
  `SessionSyncService` recovery disappear.
- **Connection to bug log:** BUG-008 (owner stale while foreground / auto-claim loop) and
  the original Fix 26 vector (background + red cortada → irrecoverable Syncing session).
- **Fix:** Removed `_stopForegroundService()` from `_onHoldStarted()`. The foreground
  service now survives hold. It is only stopped on group completion, explicit user stop,
  VM dispose, or mode switch.

### GAP-2 — `_isValidHoldExitSnapshot()` corroboration added (Guardrail G-6)

- **Root cause:** `if (session.status.isActiveExecution) return true` allowed hold exit
  without verifying `group.status == TaskRunStatus.running`. In a race window where
  another device canceled the group but this device hadn't received that update yet,
  the hold would clear on a false active-session signal.
- **Connection to docs:** Guardrail G-6 in CLAUDE.md explicitly requires corroboration
  from group state before clearing running-state latch.
- **Fix:** Added `return group.status == TaskRunStatus.running;` inside the
  `isActiveExecution` branch.

## 🧪 Validation run (local)

- `flutter analyze` → **No issues found**.
- Mandatory suite:
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart test/presentation/timer_screen_syncing_overlay_test.dart`
  - Result: **30/30 PASS**.

## 📁 Updated files

- `lib/presentation/viewmodels/pomodoro_view_model.dart`
- `docs/dev_log.md`

## ⚠️ Notes

- Both changes are in `pomodoro_view_model.dart` only. No other files touched.
- Stage C device validation can now proceed against this updated baseline.
- Open bugs out of scope for this rewrite (BUG-002, 003, 004, 005, 006, 009) remain
  tracked in bug_log.md and are not blocked by Stage C.

---

# 🔹 Block 588 — Stage C pass1 review follow-up (`O-1` + `O-2`) implemented (16/03/2026)

## 📋 Context

Stage C pass1 logs (`c0add32`) were reviewed and accepted for the target P0 vectors
(`AP-1`/`AP-2` not reproduced). The review produced two implementation follow-ups:

- `O-1`: avoid hold-loop at natural session boundary (`finished -> null`) when
  group terminality is already corroborated.
- `O-2`: eliminate delayed async/timer callback paths that can use `Ref` after VM
  disposal.

## ✔ Work completed

- `SessionSyncService` terminal-boundary reconciliation:
  - non-active terminal snapshots can now be reconciled against
    `TaskRunGroup.status` (`completed`/`canceled`) before hold escalation.
  - when corroborated terminal, the terminal snapshot is applied to
    `TimerService`, hold/retry loop is cleared, and recovery state returns to idle.
  - added in-flight dedupe guards to prevent duplicate terminal reconciliation.
- `PomodoroViewModel` dispose safety hardening:
  - added `ref.mounted` guards in delayed callbacks and async recovery/resync paths
    before any `ref.read` or state mutation.
  - hardened post-resume and periodic callbacks so they self-cancel/no-op after
    provider disposal.
- Regression tests extended:
  - terminal snapshot + terminal group corroboration does not enter hold loop.
  - post-resume delayed resync callback does not use disposed ref.

## 🧪 Validation run (local)

- `dart format lib/presentation/viewmodels/session_sync_service.dart lib/presentation/viewmodels/pomodoro_view_model.dart test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
- `flutter analyze` → **No issues found**.
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart test/presentation/timer_screen_syncing_overlay_test.dart` → **PASS**.

## 📁 Updated files

- `lib/presentation/viewmodels/session_sync_service.dart`
- `lib/presentation/viewmodels/pomodoro_view_model.dart`
- `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
- `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md`
- `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## ⚠️ Notes

- `P0-F26-006` remains **In validation** until Stage C pass2 soak logs are
  reviewed (`android` + `macOS`) against hold/overlay closure criteria.

---

# 🔹 Block 589 — Stage C pass2 soak validated; `P0-F26-006` closed (16/03/2026)

## 📋 Context

After Block 588, the remaining closure gate for Fix 26 rewrite was Stage C pass2
soak evidence (`android` + `macOS`, target >=4h). User completed a 5h+ stress soak
with backgrounding, network failures, Wi-Fi/mobile switches, and pause/resume.
Claude reviewed both pass2 logs and approved closure.

## ✔ Work completed

- Recorded Stage C pass2 verdict as PASS in validation docs.
- Closed validation item `P0-F26-006` as **Closed/OK** in the global ledger
  with implementation traceability:
  - `closed_commit_hash`: `cbd800a`
  - `closed_commit_message`:
    `fix(f26): suppress terminal-boundary hold and harden ref-after-dispose in recovery paths`
- Updated roadmap timeline with Stage C pass2 soak approval and closure state.
- Marked the Fix 26 rewrite reopened-phase line as closed in roadmap.

## 🧪 Closure evidence (from pass2 review)

- Logs:
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-16_fix26_rewrite_stageC_c0add32_pass2_4h_android_RMX3771_debug.log`
  - `docs/bugs/validation_fix_2026_03_07-01/logs/2026-03-16_fix26_rewrite_stageC_c0add32_pass2_4h_macos_debug.log`
- Critical checks:
  - no `hold-enter` without `hold-exit`,
  - no `provider-dispose` during active session,
  - no irrecoverable `Syncing session...`,
  - ownership handoff stable; AP-1/AP-2 non-repro in soak window.

## 📁 Updated files

- `docs/bugs/validation_fix_2026_03_07-01/quick_pass_checklist.md`
- `docs/bugs/validation_fix_2026_03_07-01/plan_validacion_rapida_fix.md`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## ⚠️ Notes

- `P0-F26-006` is closed. Any future changes in sync/timer ownership behavior must
  be treated as a new validation item with fresh exact repro + soak evidence.

---

# 🔹 Block 590 — Fix 25 re-validation architectural review; BUG-F25-A/B/C documented (16/03/2026)

## 📋 Context

Fix 25 re-validation run completed (2026-03-16, main branch post Fix-26 rewrite).
Devices: iOS simulator iPhone 17 Pro (owner) + Chrome (mirror).
Protocol: 2 groups 1 min apart; Chrome switches to Local Mode during Grupo A;
returns to Account after Grupo B start time.

Logs:

- `docs/bugs/validation_fix_2026_03_05/logs/2026-03-16_fix25_reval_ios_iPhone17Pro_debug.log`
- `docs/bugs/validation_fix_2026_03_05/logs/2026-03-16_fix25_reval_chrome_debug.log`

## ✔ Work completed

Architectural review of re-validation logs identified three blocking bugs:

**BUG-F25-A** — `requestLateStartOwnership` Firestore transaction order violation

- File: `lib/data/repositories/firestore_task_run_group_repository.dart:292`
- Root cause: per-group loop interleaves tx.get() and tx.set() across iterations.
  When groups.length > 1, tx.get(group[1]) is issued AFTER tx.set(group[0]),
  which violates the Firestore SDK invariant that all reads must precede all writes.
  The SDK throws `_commands.isEmpty` assertion.
- Evidence: 4 consecutive failures in iOS log (lines 50742/50775/50796/50819);
  Chrome received zero ownership requests during the entire session.
- Fix: split into Phase 1 (all reads, collect results) + Phase 2 (all writes).

**BUG-F25-B** — `_showOwnerResolvedDialog` OK button context-after-dispose

- File: `lib/presentation/screens/late_start_overlap_queue_screen.dart:563`
- Root cause: OK button closure captures the outer `BuildContext`. If
  `_LateStartOverlapQueueScreenState` is disposed before the user taps OK
  (e.g., stream update navigates away), `Navigator.of(context)` throws.
  The `if (!mounted) return` guard at line 570 protects only the post-await
  `context.go('/groups')` call, not the button callback itself.
- Evidence: Chrome re-validation log: exception cascade on dialog dismiss.
- Fix: capture `final nav = Navigator.of(context, rootNavigator: true)` before
  `await showDialog(...)` and use `nav.pop()` in the button `onPressed`.

**BUG-F25-C** — "Owner resolved" modal incorrectly shown on owner device

- File: `lib/presentation/screens/late_start_overlap_queue_screen.dart:176`
- Root cause: `isOwner` is derived from `ownerDeviceId == deviceId`. After
  the owner resolves the conflict, Firestore clears/nulls `ownerDeviceId`
  in the next snapshot → `isOwner` evaluates false on the resolving device
  → `!isOwner && allCanceled` fires → mirror-only dialog shown on owner.
- Evidence: iOS re-validation log (dialog triggered on owner after successful
  resolution); confirmed by user architectural review 2026-03-16.
- Fix: add `bool _resolved = false` flag in `_LateStartOverlapQueueScreenState`;
  set `_resolved = true` on successful completion of `_confirmSelection()` /
  `_cancelAllQueue()`; add `&& !_resolved` to the condition at line 176.

## 📁 Updated files

- `docs/bugs/bug_log.md` — BUG-F25-A, BUG-F25-B, BUG-F25-C entries added
- `docs/validation/validation_ledger.md` — BUG-F25-A (P0), BUG-F25-B (P0),
  BUG-F25-C (P1) entries added; P0-F25-001 evidence field updated
- `docs/dev_log.md` — this block

## ⚠️ Notes

- P0-F25-001 remains open — re-validation confirmed bugs prevent Fix 25 closure.
- BUG-F25-A and BUG-F25-B are P0: ownership delivery is broken and the
  "Owner resolved" dialog is unresponsive when affected.
- BUG-F25-C is P1: UX confusion for owner; dialog content is incorrect.
- All three must be fixed and re-validated before Fix 25 can close.
- Codex handoff: implementation spec is in bug_log.md entries BUG-F25-A/B/C.

---

# 🔹 Block 591 — Fix 25 implementation packet (BUG-F25-A/B/C) ready for re-validation (16/03/2026)

## 📋 Context

User approved implementation after Block 590 handoff. Work executed on branch
`fix-f25-transaction-order-and-owner-dialog` (not on `main`).

Scope:

- BUG-F25-A: Firestore transaction order violation in
  `requestLateStartOwnership`.
- BUG-F25-B: `Owner resolved` dialog OK callback used disposed context.
- BUG-F25-C: owner device incorrectly saw mirror-only `Owner resolved` dialog.

## ✔ Work completed

Code implementation:

1. BUG-F25-A (`lib/data/repositories/firestore_task_run_group_repository.dart`)
   - Refactored `requestLateStartOwnership` transaction to two explicit phases:
     - Phase 1: read all group documents (`tx.get`) and cache payloads.
     - Phase 2: write ownership claim fields (`tx.set`) after reads complete.
   - This removes read-write interleaving across loop iterations and aligns with
     Firestore transaction invariants.

2. BUG-F25-B (`lib/presentation/screens/late_start_overlap_queue_screen.dart`)
   - Hardened `_showOwnerResolvedDialog`:
     - early mounted guard before opening dialog,
     - captured root navigator before `await showDialog(...)`,
     - OK button now calls captured `nav.pop()` instead of
       `Navigator.of(context, ...)` inside callback closure.

3. BUG-F25-C (`lib/presentation/screens/late_start_overlap_queue_screen.dart`)
   - Added local resolver flag `bool _resolved = false`.
   - Set `_resolved = true` after successful `_applySelection` completion.
   - Updated mirror dialog gate to require `!isOwner && !_resolved` before
     showing `Owner resolved`.

Docs synchronization:

- Updated `quick_pass_checklist.md` (Fix 25 row) with failed re-validation
  review + implementation packet + local verification results.
- Updated `plan_validacion_rapida_fix.md` with reopened Fix 25 status,
  blocker list, implementation notes, and closure criteria.
- Updated `validation_ledger.md`:
  - `P0-F25-001` moved to `In validation`,
  - `BUG-F25-A/B/C` moved to `In validation`.
- Updated `bug_log.md` entries BUG-F25-A/B/C from "pending implementation"
  to "implemented, pending device re-validation".
- Updated `roadmap.md` timeline with Fix 25 reopen + implementation packet.

## 🧪 Validation run (local)

- `flutter analyze` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → PASS
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` → PASS

## 📁 Updated files

- `lib/data/repositories/firestore_task_run_group_repository.dart`
- `lib/presentation/screens/late_start_overlap_queue_screen.dart`
- `docs/bugs/bug_log.md`
- `docs/bugs/validation_fix_2026_03_05/quick_pass_checklist.md`
- `docs/bugs/validation_fix_2026_03_05/plan_validacion_rapida_fix.md`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## ⚠️ Notes

- This packet is implementation-complete but not closure-complete.
- Device exact repro re-validation is still required before marking
  `P0-F25-001` and BUG-F25-A/B/C as `Closed/OK`.

---

# 🔹 Block 592 — Fix 25 re-validation #2 reviewed; BUG-F25-C race follow-up applied (17/03/2026)

## 📋 Context

User provided re-validation #2 logs for Fix 25 implementation commit `fd788e6`:

- `docs/bugs/validation_fix_2026_03_05/logs/2026-03-17_fix25_reval2_fd788e6_chrome_debug.log`
- `docs/bugs/validation_fix_2026_03_05/logs/2026-03-17_fix25_reval2_fd788e6_ios_iPhone17Pro_debug.log`

Scenario validated:

- Local -> Account overlap queue trigger after overdue schedule,
- mirror ownership request delivery/acceptance flow,
- resolve overlaps completion path.

## ✔ Work completed

Validation outcome recorded:

1. BUG-F25-A: PASS in re-validation #2.
   - Ownership request delivery/acceptance worked repeatedly.
   - No Firestore transaction ordering assertion recurrence.

2. BUG-F25-B: PASS in re-validation #2.
   - No context-after-dispose / Navigator exception detected in run logs.

3. BUG-F25-C: FAIL in re-validation #2 (commit `fd788e6`).
   - Owner still saw mirror-only `Owner resolved` modal in `Continue` path.
   - Root cause: race window; `_resolved` was set after awaited persistence,
     but stream snapshots could flip `isOwner` before that set.

Follow-up implementation applied (same branch):

- `lib/presentation/screens/late_start_overlap_queue_screen.dart`
  - moved `_resolved = true` into initial `setState` before first await in
    `_applySelection` to close owner-side race window.
  - removed delayed `_resolved` set after persistence.

Docs synchronization:

- `quick_pass_checklist.md`: re-validation #2 outcome updated (A/B PASS, C FAIL)
  and follow-up patch noted.
- `plan_validacion_rapida_fix.md`: re-validation #2 + race root cause + follow-up
  patch added.
- `validation_ledger.md`: BUG-F25-A/B moved to `Closed/OK`; BUG-F25-C remains
  `In validation`; `P0-F25-001` remains `In validation`.
- `bug_log.md`: BUG-F25-A/B statuses updated to closed; BUG-F25-C now includes
  race diagnosis and follow-up patch details.

## 🧪 Validation run (local)

- `flutter analyze` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → PASS
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` → PASS

## ⚠️ Notes

- Remaining blocker for full Fix 25 closure is only BUG-F25-C device re-run
  after this race patch.

---

# 🔹 Block 593 — Fix 25 fully closed; BUG-F25-D/E/F documented as Phase 17 scope (17/03/2026)

## 📋 Context

User provided re-validation #3 logs (commit `95494ab`, iOS iPhone17Pro owner + Chrome mirror):

- `docs/bugs/validation_fix_2026_03_05/logs/2026-03-17_fix25_reval3_95494ab_ios_iPhone17Pro_debug.log`
- `docs/bugs/validation_fix_2026_03_05/logs/2026-03-17_fix25_reval3_95494ab_chrome_debug.log`

## ✔ Work completed

Validation outcome:

- BUG-F25-C: PASS. Chrome (owner) confirmed "Continue" in Resolve overlaps at 13:01:01;
  no "Owner resolved" modal appeared on owner. Race condition fix (`_resolved=true`
  pre-armed in initial setState) confirmed working.
- P0-F25-001: Closed/OK. All three blockers (A/B/C) now validated across reval #2 and #3.

Timing verification (user request):

- First trigger (13:00:00): G1 overdue 60s; projected end 13:15:00; G2 starts 13:15:00
  → exact overlap → Resolve overlaps correct ✅
- Second trigger (13:05:12): G1 overdue 12s; projected end 13:20:12; G2 starts 13:21:00
  → 48s gap → no overlap → auto-start without Resolve overlaps correct ✅

New findings documented:

1. BUG-F25-D (P1, open): Riverpod `StateController<RunningOverlapDecision?>` modified
   during widget build on mirror when overlap fires on Resume. Red error screen <1s.
   Added to Phase 17 scope in roadmap.

2. BUG-F25-E (P2, open): Re-plan conflict modal shows no group name/time range.
   Distinct from Phase 17 running overlap modal (line 440). Added to Phase 17 scope.

3. BUG-F25-F (P2, open): Postpone snackbar shows "(pre-run at X)" when noticeMinutes=0
   — redundant when pre-run equals start time. Requires spec clarification at specs.md:1716.
   Added to Phase 17 scope.

Additional findings (already documented in Phase 17 — no new entry needed):

- Running overlap not detected during pause (paused overlap alerts, Phase 17 line 437).
- Chrome Groups Hub stale after postpone (Phase 17 line 443).

## 📁 Updated files

- `docs/bugs/bug_log.md` — BUG-F25-C closed; BUG-F25-D/E/F added
- `docs/validation/validation_ledger.md` — P0-F25-001 + BUG-F25-C closed; BUG-F25-D/E/F added
- `docs/bugs/validation_fix_2026_03_05/quick_pass_checklist.md` — reval #3 result + item 3 closed
- `docs/roadmap.md` — BUG-F25-D/E/F added to Phase 17 scope

---

# 🔹 Block 594 — BUG-001/002 validation run analyzed; BUG-F26-001/002 documented (17/03/2026)

## 📋 Context

User provided BUG-001/002 validation run (Android RMX3771 + macOS, 17/03/2026).
Group was already running from a previous session. Multiple consecutive ownership
transfers were performed over ~4 minutes (20:04–20:08+). Log paths registered:

- `docs/bugs/validation_bug001_bug002_2026_03_17/logs/2026-03-17_bug001_bug002_android_RMX3771_debug.log`
- `docs/bugs/validation_bug001_bug002_2026_03_17/logs/2026-03-17_bug001_bug002_macos_debug.log`

## ✔ Work completed

**BUG-001 formally closed:**

- No Ready state observed on either device at any point during the session.
- Mirror showed Syncing state (SSS hold) during stream gaps and returned to the
  running timer without navigation. BUG-001 Closed/OK with this run as final evidence.

**BUG-002 residual confirmed and characterized:**

- Primary symptoms (ownership revert, mirror Ready after rejection): ✅ not reproduced.
- Residual confirmed: rejection banner on owner device does not clear immediately.
  - Observed at all 4 rejection events during the run.
  - First rejection: cleared at ~20:06:52 (next Firestore lastUpdatedAt heartbeat, ~1 cycle delay).
  - Third rejection (~20:07:59): required second Reject press to clear.
  - Fourth rejection (~20:08:27): same second-press pattern.
  - Root cause: no optimistic banner clear on owner after `respondToOwnershipRequest`
    returns; owner waits for Firestore snapshot round-trip.
  - Code area: `rejectOwnershipRequest()` in `pomodoro_view_model.dart`.

**New bugs documented:**

1. BUG-F26-001 (P1, open): Session cursor stale in Firestore during active run.
   - `phaseStartedAt: 7:31:07pm` (19:31:07) unchanged throughout entire run.
   - `remainingSeconds: 0` persisted in Firestore despite devices counting down normally.
   - TimerService drove the countdown correctly (Fix 26 decoupled architecture).
   - Consequence: brief `00:00` flash on macOS at second rejection (stale snapshot
     applied before TimerService re-projects); task shown as completed after app
     restart (cold-start reads `remainingSeconds: 0`).
   - Hypothesis: Fix 26 owner write path for phase transitions may no longer write
     `phaseStartedAt`/`remainingSeconds` to Firestore on phase changes.

2. BUG-F26-002 (P1, open): Pomodoro counter jumps on consecutive ownership transfers.
   - Pomodoro 5→6 at 20:07:30 (android gets ownership); 6→7 at 20:07:48 (macOS gets
     ownership). No phase completion events between transfers.
   - Likely linked to BUG-F26-001: stale `remainingSeconds: 0` may be interpreted
     as "phase complete" on each new owner claim, causing the phase index to advance.

## 📁 Updated files

- `docs/bugs/bug_log.md` — BUG-001 closed (final evidence); BUG-002 residual expanded with
  validation evidence; BUG-F26-001 + BUG-F26-002 added
- `docs/validation/validation_ledger.md` — BUG-001 closed; BUG-002 partially open entry added;
  BUG-F26-001/002 open entries added
- `docs/roadmap.md` — BUG-F26-001/002 added to Phase 18 scope
- `docs/dev_log.md` — header updated

---

# 🔹 Block 595 — Ownership sync hardening packet implemented (17/03/2026)

## 📋 Context

User requested Codex implementation of the architectural handoff for intermittent
ownership churn issues:

- BUG-002 residual (owner rejection banner delayed clear),
- BUG-F26-001 (stale Firestore cursor on churn),
- BUG-F26-002 (phase/pomodoro jumps on consecutive handoffs).

Implementation done on branch `fix-ownership-cursor-stamp` (not `main`).

## ✔ Work completed

Code changes:

1. **Fix 1 — publish retry after timeSync recovery**
   - Added `_pendingPublishAfterSync` flag in `PomodoroViewModel`.
   - `_publishCurrentSession()` now marks pending when `isTimeSyncReady=false`.
   - `_refreshTimeSyncIfNeeded()` now replays pending publish immediately after
     successful offset refresh.
   - Pending flag is cleared on session reset / mode change.

2. **Fix 2 — atomic cursor stamp in ownership approve path**
   - Added `PomodoroSession.toCursorMap()` (cursor payload only).
   - Extended `respondToOwnershipRequest(...)` signature with optional
     `cursorSnapshot`.
   - Firestore approve transaction now merges `cursorSnapshot` in the same
     ownership transfer write (`ownerDeviceId` switch + revision/timestamp).
   - `approveOwnershipRequest()` now builds current session snapshot and passes
     `cursorSnapshot` to the repository call.

3. **Fix 3 — fallback publish on owner hot-swap without hydration**
   - In owner timeline projection branch, when `shouldHydrate == false` and
     machine is already non-idle, VM now executes:
     `_bumpSessionRevision()` + `_publishCurrentSession()`.
   - This stamps live cursor immediately on mirror→owner hot-swap.

4. **Fix 4 — optimistic clear for owner-side rejection banner**
   - `rejectOwnershipRequest()` now clears pending ownership request locally
     right after successful repository response (before Firestore round-trip).
   - Added helper `_clearOwnershipRequestLocallyForOwner(...)` and immediate
     `_notifySessionMetaChanged()` to remove banner without delay.

Test scaffold updates:

- Updated test fakes implementing `PomodoroSessionRepository` to include the new
  optional `cursorSnapshot` parameter in `respondToOwnershipRequest(...)`.

## 🧪 Validation run (local)

- `flutter analyze` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → PASS
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart` → PASS

## 📁 Updated files

- `lib/presentation/viewmodels/pomodoro_view_model.dart`
- `lib/data/repositories/firestore_pomodoro_session_repository.dart`
- `lib/data/repositories/pomodoro_session_repository.dart`
- `lib/data/models/pomodoro_session.dart`
- `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
- `test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart`
- `test/presentation/timer_screen_syncing_overlay_test.dart`
- `test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart`
- `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`

## ⚠️ Notes

- This packet is **implementation complete** but not closure-complete.
- Device re-validation is still required to close BUG-002 residual and
  BUG-F26-001/002.

---

# 🔹 Block 596 — Re-validation FAIL on `7ddc1e6`; one-shot guard patch added (17/03/2026)

## 📋 Context

User executed ownership churn validation on Android RMX3771 + macOS using logs:

- `docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-17_ownership_cursor_7ddc1e6_android_RMX3771_debug.log`
- `docs/bugs/validation_ownership_cursor_2026_03_17/logs/2026-03-17_ownership_cursor_7ddc1e6_macos_debug.log`

Run details:

- Group started at ~22:27:30 (`Start now`, newly created group).
- On UI, ownership looked mostly correct.
- In Firestore, `sessionRevision` increased abnormally fast and `current` doc
  oscillated after cancel.

## ❌ Validation failure observed

- `sessionRevision` jump: 88 → 121 between 22:27:44 and 22:27:51.
- `lastUpdatedAt` + `remainingSeconds` rewritten continuously.
- After cancel (~22:28:35), `activeSession/current` recreated/deleted in loop
  until app close.

Conclusion: commit `7ddc1e6` introduced regression (write feedback loop).

## 🔍 Root cause (code-level)

In `PomodoroViewModel._applySessionTimelineProjection`, fallback branch for
non-idle owner hot-swap executed on repeated snapshots without one-shot guard:

- `_bumpSessionRevision()`
- `_publishCurrentSession()`

This created Firestore feedback loop (snapshot → write → snapshot → write).

## ✔ Follow-up patch implemented

File:

- `lib/presentation/viewmodels/pomodoro_view_model.dart`

Changes:

- Added `int _hotSwapPublishedForRevision = -1`.
- Reset guard on mode switch and `_resetLocalSessionState()`.
- Guarded fallback publish to one-shot per ownership revision:
  execute only when `session.sessionRevision` was not already published by this
  hot-swap path.
- Mark revision before publish to prevent re-entry loop.

Regression test added:

- `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
  - `owner hot-swap fallback publish is one-shot for repeated snapshots`

## 🧪 Local verification

- `flutter analyze` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → PASS
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` → PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart` → PASS

## 📁 Updated files

- `lib/presentation/viewmodels/pomodoro_view_model.dart`
- `test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
- `docs/bugs/validation_ownership_cursor_2026_03_17/quick_pass_checklist.md`
- `docs/bugs/validation_ownership_cursor_2026_03_17/plan_validacion_rapida_fix.md`
- `docs/bugs/bug_log.md`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

---

# 🔹 Block 597 — BUG-F25-D runtime patch implemented (18/03/2026)

## 📋 Context

Claude handoff requested Codex implementation for `BUG-F25-D`:
mirror red error flash (`Tried to modify a provider while the widget tree was building`)
when running overlap is detected on Resume.

## ✔ Work completed

Runtime fix implemented in:

- `lib/presentation/viewmodels/scheduled_group_coordinator.dart`

Changes:

1. Added scheduler-aware overlap mutation helper.
2. Deferred `runningOverlapDecisionProvider` set/clear to post-frame only when
   scheduler is in build-phase callbacks.
3. Added stale/dispose guards to prevent deferred stale writes.
4. Added safe fallback for environments where scheduler binding is not initialized
   (keeps provider-container tests stable).

Validation artifacts created:

- `docs/bugs/validation_fix_2026_03_18-01/plan_validacion_rapida_fix.md`
- `docs/bugs/validation_fix_2026_03_18-01/quick_pass_checklist.md`
- `docs/bugs/validation_fix_2026_03_18-01/screenshots/`

Documentation synchronization:

- `docs/bugs/bug_log.md` (BUG-F25-D moved to "In validation", runtime fix noted)
- `docs/validation/validation_ledger.md` (BUG-F25-D status updated to `In validation`)
- `docs/roadmap.md` (18/03 entry added under active status timeline)
- `docs/dev_log.md` (this block + header status update)
- Implementation commit: `07ac0cb` (`fix(f25-d): defer running-overlap provider mutation out of build phase`)

## 🧪 Verification run

PASS:

- `flutter analyze`
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "running overlap decision"`
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart`
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart`

Global suite status:

- `flutter test` → FAIL (`+90 -8`), with existing failures concentrated in
  `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
  (missing `appModeServiceProvider` test override in multiple cases + one
  `auto-claims late-start queue` timeout). Not introduced by BUG-F25-D patch.

## ⚠️ Notes

- BUG-F25-D is not closed yet: exact owner+mirror repro still pending in
  `validation_fix_2026_03_18-01`.
- Closure requires device evidence + regression smoke checks.

---

# 🔹 Block 598 — BUG-F25-D closed/OK (18/03/2026)

## 📋 Context

First fix (`07ac0cb`) failed: `SchedulerBinding.schedulerPhase` check insufficient —
Riverpod's `_debugCurrentBuildingElement` is internal and not tied to Flutter's scheduler
phase. Fix v2 (`f5b1d2c`) also failed: `Future.microtask` queues in the microtask queue,
which can fire mid-Riverpod-propagation.

Device logs revealed **two independent sources** of the same build-phase mutation error:

1. **Coordinator** (`_runRunningOverlapMutation`): timer/Firestore callbacks mutating
   `runningOverlapDecisionProvider` during Riverpod propagation.
2. **Widgets** (`GroupsHubScreen.build():283`, `TaskListScreen.build():561`): direct
   `ref.read(...).state = null` calls inside `build()` after discovering a stale overlap
   decision (running group no longer in scope).

## ✔ Work completed

**Commit `73d0f23`** — Coordinator fix:

- `_runRunningOverlapMutation` replaced with `Future(() { mutation(); })` (macrotask).
  Macrotask runs after all pending microtasks, including Riverpod's full propagation chain.
- Removed `SchedulerBinding` import (no longer used).
- Tests updated: 4 tests in `'running overlap decision'` group now `await Future(() {})`
  between coordinator call and provider read.

**Commit `79c534d`** — Widget fix:

- `GroupsHubScreen.build():283` and `TaskListScreen.build():561`: stale-decision clear
  moved to `WidgetsBinding.instance.addPostFrameCallback` with `mounted` guard and token
  guard. Token is captured before scheduling; callback checks `currentDecision.token !=
staleDecisionToken` to avoid clearing a newer decision written after the defer.

**Protocol update** (same session):

- `CLAUDE.md` section 8: Codex now reviews fix specs before implementing; reports
  errors to Claude before writing code.
- `AGENTS.md` + `docs/team_roles.md` updated with the same spec-review rule.

## 🧪 Validation result

Device: iOS iPhone 17 Pro (owner) + Chrome (mirror).

- Overlap modal appeared correctly during pause.
- No red screen on mirror at conflict detection.
- No red screen on mirror after owner Postpone action.
- Timer resumed normally after owner Resume.
- Regression smoke (BUG-F25-C): owner did not see "Owner resolved" modal. PASS.
- `flutter analyze` PASS.
- All targeted tests PASS.

## 📁 Updated files

- `lib/presentation/viewmodels/scheduled_group_coordinator.dart`
- `lib/presentation/screens/groups_hub_screen.dart`
- `lib/presentation/screens/task_list_screen.dart`
- `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
- `docs/bugs/bug_log.md` (BUG-F25-D → Closed/OK, `closed_commit_hash: 79c534d`)
- `docs/validation/validation_ledger.md` (BUG-F25-D → [x] Closed/OK)
- `docs/bugs/validation_fix_2026_03_18-01/plan_validacion_rapida_fix.md` (result in-place)
- `docs/bugs/validation_fix_2026_03_18-01/quick_pass_checklist.md` (all boxes checked)
- `CLAUDE.md`, `AGENTS.md`, `docs/team_roles.md` (Codex spec-review rule added)
- `docs/dev_log.md` (this block)

---

# 🔹 Block 600 — BUG-F25-G closed/OK (19/03/2026)

## 📋 Context

`resolveEffectiveScheduledStart` in `scheduled_group_timing.dart` returned
`anchorEnd.add(Duration(minutes: noticeMinutes))` without `ceilToMinute`.
All write paths (`timer_screen.dart:1165`, `scheduled_group_coordinator.dart:1146`)
use `ceilToMinute`. Inconsistency introduced 23/02/2026 when write got `ceilToMinute`
but the resolver was never updated. Produces ~1-min discrepancy between postpone
snackbar and Groups Hub "Scheduled" display.

## ✔ Work completed

**Commit: `e16e389`**

- `scheduled_group_timing.dart:185`: wrapped return with `ceilToMinute`.
- `test/presentation/utils/scheduled_group_timing_test.dart` (new): two directed
  unit tests — main case (anchor with sub-second residual rounds up) and documented
  edge case (noticeMinutes=0 + exact minute = equality, tracked separately).

## ✅ Validation result

`flutter analyze` PASS. All targeted tests + new unit tests PASS.
Chrome+iOS device validation PASS 19/03/2026:

- Postpone snackbar: "Scheduled start moved to 18:32 (pre-run at 18:31)."
- Groups Hub G2 Scheduled: 18:32 / Pre-Run: 1 min starts at 18:31.
- Values match exactly.

## 📁 Updated files

- `lib/presentation/utils/scheduled_group_timing.dart`
- `test/presentation/utils/scheduled_group_timing_test.dart` (new)
- `docs/bugs/bug_log.md` (BUG-F25-G → Closed/OK)
- `docs/validation/validation_ledger.md` (BUG-F25-G → [x] Closed/OK)
- `docs/roadmap.md` (BUG-F25-G → tachado Closed/OK)
- `docs/dev_log.md` (this block)

---

# 🔹 Block 599 — BUG-F25-E closed/OK (19/03/2026)

## 📋 Context

Re-plan conflict modal showed a generic message ("A group is already scheduled in
that time range. Delete it to continue?") with no identifying information about
the conflicting group. User could not make an informed decision about whether to
delete the conflicting group (no name, no time range shown).

The modal already received `List<TaskRunGroup>` — the fix was purely UI: replace
the static `const Text(...)` content with a dynamic `Column` listing each conflict.

## ✔ Work completed

**Commit: `c248c91`**

- `groups_hub_screen.dart` `_resolveScheduledConflict` (line 1396): replaced
  static content with `Column` listing each conflicting group as
  `"• {name} — {start}–{end}"` using top-level `_formatGroupDateTime`.
- `task_list_screen.dart` `_resolveScheduledConflict` (line 1850): same change,
  using local `fmtTime()` helper (captures `_timeFormat` / `_dateFormat` instance fields).
- Group name derived as `tasks.first.name ?? 'Task group'` (consistent with
  `_showSummaryDialog` convention).
- `docs/specs.md` line 2633: added explicit rule requiring name + time range in
  Re-plan conflict modal.
- `docs/roadmap.md` line 458: BUG-F25-E marked Closed/OK.
- `docs/bugs/bug_log.md`: BUG-F25-E → Closed/OK.
- `docs/validation/validation_ledger.md`: BUG-F25-E → [x] Closed/OK.

## ✅ Validation result

`flutter analyze` PASS. All targeted tests PASS.
Chrome device validation PASS 19/03/2026:

- Conflict modal shows bullet list with group name + HH:mm–HH:mm range.
- Cancel action: no groups deleted, planning cancelled.
- Delete scheduled group: conflicting group deleted, re-plan continues.

## 📁 Updated files

- `lib/presentation/screens/groups_hub_screen.dart`
- `lib/presentation/screens/task_list_screen.dart`
- `docs/specs.md`
- `docs/roadmap.md`
- `docs/bugs/bug_log.md` (BUG-F25-E → Closed/OK)
- `docs/validation/validation_ledger.md` (BUG-F25-E → [x] Closed/OK)
- `docs/dev_log.md` (this block)

---

# 🔹 Block 601 — BUG-F25-H registered; fix plan defined (19/03/2026)

## 📋 Context

BUG-F25-H discovered during BUG-F25-G validation run (19/03/2026). Repro:
G1 running → G1 canceled → re-plan → G2 starts → Chrome takes ownership →
Chrome cancels G2 → both devices stuck in indefinite "Syncing session..." with timer
running. Firestore `activeSession/current` deleted; no recovery; manual restart required.
Regression introduced 19/03/2026 (confirmed working in prior-day build).

Log evidence:

- `docs/bugs/validation_f25h_2026_03_19/logs/2026-03-19_f25h_3cb2f6c_chrome_debug.log`
- `docs/bugs/validation_f25h_2026_03_19/logs/2026-03-19_f25h_3cb2f6c_ios_iPhone17Pro_debug.log`

## ✔ Work completed

- Full root cause analysis from Chrome + iOS device logs (commit 3cb2f6c baseline).
- Identified three-component root cause:
  1. `_cancelNavigationHandled` permanently blocked by stale ViewModel data in `build()`
     — `pomodoroViewModelProvider` is a global singleton (not parameterized by groupId);
     G1's canceled status fires the build-phase check during G2's first frame;
     Flutter assertion exception confirmed at Chrome log line 2238
     (`timer_screen.dart:682`, `setState()/markNeedsBuild() called during build`).
  2. `_recoverFromServer()` has no exit for terminal group state
     — session_sync_service.dart retries every 5s forever; 40+ seconds of
     `hold-extend reason=recovery-failed` confirmed in Chrome log lines 2824–2875.
  3. `stopTick()` potentially missing in cancel handler — timer keeps
     `isTickingCandidate = true` → latch fires on session null instead of quiet-clear.
- Registered BUG-F25-H as P1 Open in all project docs.
- Created validation folder and plan/checklist documents.

## 📁 Updated files

- `docs/bugs/bug_log.md` (BUG-F25-H added — Open, P1)
- `docs/validation/validation_ledger.md` (BUG-F25-H P1 Open added)
- `docs/roadmap.md` (Phase 17 BUG-F25-H line added)
- `docs/bugs/validation_f25h_2026_03_19/plan_validacion_rapida_fix.md` (new)
- `docs/bugs/validation_f25h_2026_03_19/quick_pass_checklist.md` (new)
- `docs/dev_log.md` (this block)

---

# 🔹 Block 602 — BUG-F25-H closed/OK (19/03/2026)

## 📋 Context

Regression introduced 19/03/2026 during F25-G/E development. Repro: G1 running →
G1 canceled → re-plan → G2 starts → Chrome cancels G2 → both devices stuck in
indefinite "Syncing session..." with timer running; manual restart required.

Three-component root cause confirmed from Chrome + iOS logs (baseline 3cb2f6c):

1. `_cancelNavigationHandled` permanently blocked by stale G1 data in first build frame
   of G2's TimerScreen — Flutter assertion exception at timer_screen.dart:682.
2. `_recoverFromServer()` infinite 5s retry on terminal group — no exit condition.
3. `stopTick()` missing in `cancel()` and `applyRemoteCancellation()` — timer kept
   ticking, routing session null through hold path instead of quiet-clear.

## ✔ Work completed

**Commit 9a52405** — `fix(f25-h): add stopTick() to cancel and applyRemoteCancellation paths`

- `pomodoro_view_model.dart` `cancel()` and `applyRemoteCancellation()`: added
  `_timerService.stopTick()` before `_resetLocalSessionState()`.

**Commit e2a69b3** — `fix(f25-h): guard build-phase cancel check with groupId + defer to post-frame`

- `timer_screen.dart:680`: added `currentGroup?.id == widget.groupId` guard; wrapped
  `_navigateToGroupsHub()` in `addPostFrameCallback` with `!mounted` check.

**Commit ba8db6f** — `fix(f25-h): add terminal-group exit to _recoverFromServer()`

- `session_sync_service.dart` `_recoverFromServer()`: after `serverSession == null`,
  fetches group via `taskRunGroupRepositoryProvider.getById(attachedGroupId)`. If
  `canceled` or `completed`, clears hold (`holdActive: false`) and returns — no retry.

## ✅ Validation result

`flutter analyze` PASS. All 3 targeted tests PASS.
Chrome + iOS device validation PASS 19/03/2026:

- Escenario A: G1→cancel→G2→cancel → both devices navigate to Groups Hub in ≤5s.
  No `hold-extend reason=recovery-failed` / no setState/build exception in any log.
- Escenario B: simple G1 cancel → correct navigation (no regression).
- Escenario C: Chrome offline ~5s → auto-recovery without permanent hold.

Log evidence:

- `docs/bugs/validation_f25h_2026_03_19/logs/2026-03-19_f25h_ba8db6f_chrome_debug.log`
- `docs/bugs/validation_f25h_2026_03_19/logs/2026-03-19_f25h_ba8db6f_ios_iPhone17Pro_9A6B6687_debug.log`

## 📁 Updated files

- `lib/presentation/viewmodels/pomodoro_view_model.dart`
- `lib/presentation/screens/timer_screen.dart`
- `lib/presentation/viewmodels/session_sync_service.dart`
- `docs/bugs/bug_log.md` (BUG-F25-H → Closed/OK)
- `docs/validation/validation_ledger.md` (BUG-F25-H → [x] Closed/OK)
- `docs/roadmap.md` (BUG-F25-H → tachado Closed/OK)
- `docs/bugs/validation_f25h_2026_03_19/plan_validacion_rapida_fix.md` (status → Closed/OK)
- `docs/bugs/validation_f25h_2026_03_19/quick_pass_checklist.md` (all boxes checked)
- `docs/dev_log.md` (this block)

# 🔹 Block 603 — BUG-F25-F closed/OK (19/03/2026)

**Bug:** BUG-F25-F — Postpone snackbar shows redundant "(pre-run at X)" when noticeMinutes=0.
**Symptom:** After pressing Postpone in the running overlap modal, the snackbar showed
"Scheduled start moved to 13:22 (pre-run at 13:22)." — pre-run time identical to start time,
meaningless to the user.
**Root cause:** `_showPostponeConfirmation` (timer_screen.dart) always appended the pre-run
clause regardless of whether `preRunStart` differed from `scheduledStart`. The caller
(line 1199) already computed `preRunStart = scheduledStartTime` when `noticeMinutes=0`,
but the formatter had no guard.
**Fix:** Added `hasPreRun = preRunStart.isBefore(scheduledStart)` check. Pre-run clause
only included when `hasPreRun` is true. Single-line change, no invariant risk.
**Commit:** 68429c5 — fix(f25-f): suppress pre-run clause in postpone snackbar when noticeMinutes=0
**Tests:** flutter analyze PASS · regression suite PASS (33 tests).
**Docs updated:**

- `docs/bugs/bug_log.md` (BUG-F25-F → Closed/OK)
- `docs/validation/validation_ledger.md` (BUG-F25-F → [x] Closed/OK)
- `docs/dev_log.md` (this block)

---

# 🔹 Block 604 — BUG-F25-I registered with full evidence packet (19/03/2026)

## 📋 Context

During post-F25-H validation, a new regression was observed in postpone/cancel flow:
after selecting **Postpone scheduled** for G2 while G1 is running, canceling G1
re-anchors G2 to current time and starts it on the next minute.

Expected product behavior: canceling running anchor must **not** rewrite postponed
start time; postponed group should keep stored planned start.

## ✔ Work completed

- Created validation folder:
  - `docs/bugs/validation_f25i_2026_03_19/`
  - `logs/` + `screenshots/`
- Preserved baseline evidence logs:
  - `docs/bugs/validation_f25i_2026_03_19/logs/2026-03-19_f25i_68429c5_ios_iPhone17Pro_9A6B6687_debug.log`
  - `docs/bugs/validation_f25i_2026_03_19/logs/2026-03-19_f25i_68429c5_chrome_debug.log`
- Registered BUG-F25-I in `docs/bugs/bug_log.md` with:
  - full repro steps
  - user-facing symptom
  - expected behavior
  - probable root cause at file/method level
  - targeted fix direction + tests
- Added BUG-F25-I to `docs/validation/validation_ledger.md` as **Open / P1**.
- Added Phase 17 roadmap line for BUG-F25-I in `docs/roadmap.md`.
- Created:
  - `docs/bugs/validation_f25i_2026_03_19/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_f25i_2026_03_19/quick_pass_checklist.md`

## 🔎 Key evidence extracted for Claude review

iOS log (`...ios_iPhone17Pro_9A6B6687_debug.log`):

- line 51210: postponed sample still future (`...22:35|22:36`)
- line 51216: cancel event (`Cancel nav: group stream canceled`)
- line 51224: sample collapses to `...22:22|22:22`
- lines 51225+ / 51228+ / 51231+: `schedule-start-timer` for `22:22:00`
- lines 51244+ / 51246+ / 51253: `start-timer-fired` at `22:22:00`

Chrome log (`...chrome_debug.log`):

- lines 2623/2632/2658: postponed sample at `...22:35|22:35/22:36`
- lines 2670+ and 2684-2686: sample/postpone-finalized changed to `22:22`
- line 2687: auto-start fired at `22:22:00`

## 🧠 Root-cause hypothesis recorded (pending fix confirmation)

`resolvePostponedAnchorEnd` fallback to `anchor.updatedAt` on non-running anchor
can leak terminal anchor timestamp (`now`) into postponed schedule resolution.
Then `_finalizePostponedGroupsIfNeeded` consumes that derived value and advances
postponed start to current minute, which triggers premature start timer.

## 📁 Updated files

- `docs/bugs/bug_log.md` (BUG-F25-I added, Open/P1)
- `docs/validation/validation_ledger.md` (BUG-F25-I Open entry added)
- `docs/roadmap.md` (Phase 17 BUG-F25-I line added)
- `docs/bugs/validation_f25i_2026_03_19/plan_validacion_rapida_fix.md` (new)
- `docs/bugs/validation_f25i_2026_03_19/quick_pass_checklist.md` (new)
- `docs/dev_log.md` (this block)

# 🔹 Block 605 — BUG-F25-I closed/OK (19/03/2026)

**Bug:** BUG-F25-I — Postponed group start drifts to "now" after canceling the running anchor group.
**Symptom:** After pressing "Postpone scheduled" in the running overlap modal, canceling the
running anchor group caused the postponed group's scheduledStart to jump from the future
(e.g., 22:35) to the current minute (e.g., 22:22), triggering an immediate auto-start.
**Root cause:** `_finalizePostponedGroupsIfNeeded` (scheduled_group_coordinator.dart) did
not guard against canceled anchors — fell through to `resolvePostponedAnchorEnd` which
had no guard for `canceled` status and returned `anchor.updatedAt = now` as fallback.
G2 then got `scheduledStartTime = ceilToMinute(now)` written to DB and auto-started.
The bug also cascaded in chained postpone chains (G1→G2→G3) via `resolveEffectiveScheduledEnd`.
**Fix — two commits:**

- `51dcd2d`: `_finalizePostponedGroupsIfNeeded` — sever link (postponedAfterGroupId=null)
  without touching scheduledStartTime when anchor is canceled. Mirrors "anchor not found" pattern.
- `6c87009`: `resolvePostponedAnchorEnd` — return null for canceled anchors. Prevents
  fallback to updatedAt; also protects chained groups (G3→G2→canceled G1).
  **Tests:** 2 new unit tests in scheduled_group_timing_test.dart. flutter analyze PASS.
  **Device validation:** Chrome + iOS PASS 19/03/2026. G2 held Scheduled: 23:29 after G1
  canceled at 23:14. No premature auto-start. Screenshots confirmed.
  **Docs updated:**
- `docs/bugs/bug_log.md` (BUG-F25-I → Closed/OK)
- `docs/validation/validation_ledger.md` (BUG-F25-I → [x] Closed/OK)
- `docs/bugs/validation_f25i_2026_03_19/plan_validacion_rapida_fix.md` (status → Closed/OK)
- `docs/bugs/validation_f25i_2026_03_19/quick_pass_checklist.md` (all boxes checked)
- `docs/dev_log.md` (this block)

# 🔹 Block 606 — Roadmap/ledger closure sync for BUG-F25-E/F/I (20/03/2026)

## 📋 Context

Post-closure review found a documentation divergence:
`docs/validation/validation_ledger.md` already marked `BUG-F25-E`, `BUG-F25-F`, and
`BUG-F25-I` as `Closed/OK`, but `docs/roadmap.md` still listed those entries in
the reopened-phases queue as open items.

## ✔ Work completed

- Updated reopened Phase 17 entries in `docs/roadmap.md`:
  - `BUG-F25-E` → Closed/OK on 19/03/2026 (`c248c91`)
  - `BUG-F25-F` → Closed/OK on 19/03/2026 (`68429c5`)
  - `BUG-F25-I` → Closed/OK on 19/03/2026 (`6c87009`)
- Updated dev-log header to reflect:
  - current last bug fix (`BUG-F25-I`)
  - current execution focus (P1 validation queue `RVP-063..069`)
  - last update date `20/03/2026`

## 📁 Updated files

- `docs/roadmap.md` (reopened list synchronized with closure state)
- `docs/dev_log.md` (status header + this block)

## 🎯 Next steps

1. Execute `RVP-063` and `RVP-064` validation packet first (Phase 10 reopen items).
2. Continue with `RVP-065`, then `RVP-066` to `RVP-069` in ledger order.

# 🔹 Block 607 — RVP-063/RVP-064 validation closure (20/03/2026)

## 📋 Context

The highest-priority reopened validation queue started with:

- `RVP-063` (Phase 10 break auto-adjust + focus-loss behavior).
- `RVP-064` (Phase 10 selection-scoped Task weight in Edit Task).

Both were still marked pending in roadmap/ledger despite implementation history
already present in code and prior dev-log blocks.

## ✔ Work completed

- Verified implementation traceability with `git blame`:
  - `5c21dc9` (`Defer break auto-adjust to focus loss`) for blur-triggered
    break adjustment hooks in Task Editor + Edit Preset.
  - `466b4223` (`feat: auto-adjust break durations`) for pomodoro-change
    auto-adjust baseline.
  - `cca359f` (`Selection-scoped task weight`) for selection-scoped
    Task weight visibility and percentage derivation flow.
- Ran local validation commands:
  - `flutter analyze`
  - `flutter test test/domain/validators_test.dart test/domain/task_weighting_test.dart test/presentation/viewmodels/task_editor_view_model_test.dart`
  - `flutter test test/domain/task_group_planner_test.dart`
- Synchronized documentation state:
  - `docs/validation/validation_ledger.md`: `RVP-063` and `RVP-064` moved to `Closed/OK` with evidence and commit traceability.
  - `docs/roadmap.md`: timeline entries (03/02) updated to validated, and reopened Phase 10 items marked `Closed/OK`.
  - `docs/dev_log.md`: status header focus moved to `RVP-065..069`.

## 🧪 Verification run

PASS:

- `flutter analyze` → No issues found.
- `flutter test test/domain/validators_test.dart test/domain/task_weighting_test.dart test/presentation/viewmodels/task_editor_view_model_test.dart` → `+28` all passed.
- `flutter test test/domain/task_group_planner_test.dart` → `+11` all passed.

## 📁 Updated files

- `docs/roadmap.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-065` validation (Phase 13 mirror session-gap stability).
2. Then continue with `RVP-066` to `RVP-069` in order.

# 🔹 Block 608 — RVP-065 validation closure (20/03/2026)

## 📋 Context

After closing `RVP-063/064`, the next P1 reopened validation item was:
`RVP-065` — "Mirror session gaps must not drop Run Mode to Ready."

This behavior was already functionally covered by the Fix 26 rewrite closure
(`BUG-001` closed/OK), but the roadmap/ledger item remained pending.

## ✔ Work completed

- Executed focused local regression suites for session-gap behavior:
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart`
  - `flutter test test/presentation/timer_screen_syncing_overlay_test.dart`
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart`
- Confirmed code-path guardrails remain in place:
  - 3s debounce before hold entry on stream null while ticking.
  - Hold/sync overlay path (`sessionMissingHold`, `runningWithoutSession`) instead
    of fallback to Ready during transient session gaps.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-065` moved to `Closed/OK`
    with Fix 26/BUG-001 evidence + local test gate.
  - `docs/roadmap.md`: reopened Phase 13 item marked `Closed/OK`.
  - `docs/dev_log.md`: status header focus advanced to `RVP-066..069`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` → `+25`.
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` → `+4`.
- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → `+4`.

## 📁 Updated files

- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-066` validation (Phase 18 mode-specific breaks).
2. Then continue with `RVP-067` to `RVP-069`.

# 🔹 Block 609 — Cross-agent rule: validation case recap + final confirmation (20/03/2026)

## 📋 Context

User request: when validation items are closed, always explain the concrete
validated case(s) so they are easy to remember, and ask for final confirmation.
The requirement must apply to any responding AI role (Claude, Codex, Gemini, or
equivalent agent in this workflow).

## ✔ Work completed

- Added mandatory rule in `AGENTS.md`:
  - handoff contract now requires user-facing validation recap per closed ID;
  - closure communication now explicitly requires final user confirmation.
- Added same requirement to `docs/team_roles.md` (mandatory handoff format),
  making it role-agnostic and applicable across Claude/Codex/Gemini.
- Added same requirement to `CLAUDE.md` bug lifecycle step 7 (closure), so the
  recap + explicit final confirmation is part of the standard closure path.

## 📁 Updated files

- `AGENTS.md`
- `docs/team_roles.md`
- `CLAUDE.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Continue validation queue with `RVP-066`.

# 🔹 Block 610 — RVP-066 validation closure (20/03/2026)

## 📋 Context

Next pending P1 reopened validation item:
`RVP-066` — Mode-specific breaks in Phase 18 (Mode A must use a global
long-break counter across the group).

Existing implementation was present (`45b522f`), but closure required explicit
validation evidence for the cross-task long-break cadence behavior.

## ✔ Work completed

- Added dedicated unit coverage:
  - `test/data/models/task_run_group_mode_a_breaks_test.dart`
  - Verifies that in shared mode the long-break cadence is global and does not
    reset at task boundaries.
  - Verifies duration differences vs individual mode for the same task set.
- Re-ran regression and gate checks:
  - `flutter test test/data/models/task_run_group_mode_a_breaks_test.dart`
  - `flutter test test/domain/task_group_planner_test.dart`
  - `flutter analyze`
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-066` → `Closed/OK`.
  - `docs/roadmap.md`: Phase 18 reopened item marked `Closed/OK`.
  - `docs/dev_log.md`: status header focus moved to `RVP-067..069`.

## 🧪 Verification run

PASS:

- `flutter test test/data/models/task_run_group_mode_a_breaks_test.dart` → `+2`.
- `flutter test test/domain/task_group_planner_test.dart` → `+11`.
- `flutter analyze` → No issues found.

## 📁 Updated files

- `test/data/models/task_run_group_mode_a_breaks_test.dart` (new)
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-067` validation (Run Mode task transition catch-up after background/resume).

# 🔹 Block 611 — RVP-067 validation closure (20/03/2026)

## 📋 Context

Next pending P1 reopened validation item:
`RVP-067` — Run Mode task transition catch-up after background/resume.

Phase 18 implementation existed in commit `992de22`, but closure needed explicit
evidence that `handleAppResumed()` catches up across task boundaries and
republishes corrected session cursor state.

## ✔ Work completed

- Added dedicated resume catch-up scenario to existing viewmodel coverage:
  - `test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart`
  - New case verifies `handleAppResumed` advances from task 0 to task 2 after
    simulated background elapsed time (cross-task boundary jump).
  - New case verifies corrected cursor state is republished via
    `publishSession` after resume catch-up.
- Extended fake session repository test double with publish tracking
  (`publishCalls`, `lastPublishedSession`) to assert republish behavior.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-067` → `Closed/OK`.
  - `docs/roadmap.md`: Phase 18 catch-up item marked `Closed/OK`.
  - `docs/dev_log.md`: status header focus moved to `RVP-068..069`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` → `+5`.
- `flutter analyze` → No issues found.

## 📁 Updated files

- `test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-068` validation (completion modal + Groups Hub navigation on owner/mirror).

# 🔹 Block 612 — RVP-068 validation closure (20/03/2026)

## 📋 Context

Next pending P1 reopened validation item:
`RVP-068` — completion modal + Groups Hub navigation must work on owner and
mirror devices.

Implementation already existed in commit `323f6bf`, but closure required
explicit owner/mirror validation evidence in the current ledger pass.

## ✔ Work completed

- Added dedicated widget coverage:
  - `test/presentation/timer_screen_completion_navigation_test.dart` (new)
  - Owner scenario: when running group transitions to `completed`, completion
    modal appears and tapping `OK` lands on Groups Hub.
  - Mirror scenario: same completion + navigation flow validated while
    `ownerDeviceId != local device` (mirror mode).
- Coverage targets the production completion-handling path in `TimerScreen`:
  - `_maybeHandleGroupCompleted`
  - `_showFinishedDialog`
  - `_navigateToGroupsHubAfterCompletion`
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-068` → `Closed/OK`.
  - `docs/roadmap.md`: completion-modal owner/mirror item marked `Closed/OK`.
  - `docs/dev_log.md`: status header focus moved to `RVP-069`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` → `+2`.
- `flutter analyze` → No issues found.

## 📁 Updated files

- `test/presentation/timer_screen_completion_navigation_test.dart` (new)
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-069` validation (deterministic initial ownership with multiple devices open).

# 🔹 Block 613 — RVP-069 validation closure (20/03/2026)

## 📋 Context

Final pending P1 reopened validation item:
`RVP-069` — initial ownership assignment must be deterministic with multiple
devices open.

Implementation existed in commit `33a17b7` (start-now owner determinism),
with single-owner claim protection from `tryClaimSession` path. Closure required
explicit test evidence for both non-initiator blocking and claim-race fallback.

## ✔ Work completed

- Extended ownership viewmodel test coverage in:
  - `test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart`
- Added two dedicated validation scenarios:
  - `start blocks non-initiator when running group was started by another device`
    (`scheduledByDeviceId` guard path).
  - `start remains idle when claim fails (single-owner race protection)`
    (`tryClaimSession` race-fail path).
- Updated test repository double to record claim attempts and claimed session.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-069` → `Closed/OK`.
  - `docs/roadmap.md`: deterministic ownership item marked `Closed/OK`.
  - `docs/dev_log.md`: current focus moved to historical validation backlog.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart` → `+4`.
- `flutter analyze` → No issues found.

## 📁 Updated files

- `test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Continue historical pending validation backlog from `RVP-001` (P2 queue).

# 🔹 Block 614 — RVP-001 validation closure (20/03/2026)

## 📋 Context

First pending P2 historical validation item:
`RVP-001` — scheduled auto-start + resume/launch catch-up.

Concrete validated case to close: if a scheduled group start time is already in
the past (app launched late or resumed late), the coordinator must catch up and
auto-start the group (including Account Mode resume when timeSync becomes
available), then open Run Mode and publish the initial session snapshot.

## ✔ Work completed

- Extended coordinator tests in:
  - `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
- Added dedicated launch catch-up validation:
  - `launch catch-up auto-starts overdue scheduled group and emits openTimer action`
  - Asserts `openTimer`, `running` status transition, and initial session publish.
- Added dedicated resume catch-up validation (Account Mode + late timeSync):
  - `resume catch-up starts overdue scheduled group once timeSync becomes available in account mode`
  - Asserts no start while timeSync is unavailable, then start on `onAppResumed()`
    after timeSync offset becomes available, with `openTimer` + publish path.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-001` -> `Closed/OK`.
  - `docs/roadmap.md`: roadmap line updated to validated/closed state.
  - `docs/dev_log.md`: current focus moved to `RVP-002 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "launch catch-up auto-starts overdue scheduled group and emits openTimer action"` -> `+1`.
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "resume catch-up starts overdue scheduled group once timeSync becomes available in account mode"` -> `+1`.

## 📁 Updated files

- `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-002` validation (completion modal -> Groups Hub navigation baseline backlog item).

# 🔹 Block 615 — RVP-002 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-002` — completion modal must navigate to Groups Hub and the placeholder
Groups Hub route must be available in the completion path.

Concrete validated case to close: when a running group reaches `completed`,
Run Mode must show the completion modal and, after confirming `OK`, navigate to
`/groups` instead of staying in TimerScreen.

## ✔ Work completed

- Re-ran dedicated completion-navigation widget coverage:
  - `test/presentation/timer_screen_completion_navigation_test.dart`
- Confirmed both baseline and hardened behavior paths remain valid:
  - Owner completion path reaches Groups Hub after modal confirm.
  - Mirror completion path reaches Groups Hub after modal confirm.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-002` -> `Closed/OK`
    (implementation commit `85bec6a`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-003 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> `+2`.

## 📁 Updated files

- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-003` validation (cancel-running confirmation -> Groups Hub navigation).

# 🔹 Block 616 — RVP-003 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-003` — canceling a running group must require confirmation and then navigate
to Groups Hub.

Concrete validated case to close: user taps `Cancel` during active run, sees the
confirmation dialog, `Keep running` keeps Run Mode unchanged, and only
`Cancel group` completes cancellation and navigates to `/groups`.

## ✔ Work completed

- Extended TimerScreen navigation widget coverage in:
  - `test/presentation/timer_screen_completion_navigation_test.dart`
- Added dedicated cancel validation scenario:
  - `cancel requests confirmation and navigates to Groups Hub only after confirm`
  - Asserts:
    - Confirmation dialog appears with expected actions.
    - `Keep running` does not navigate away.
    - Confirming `Cancel group` navigates to Groups Hub.
    - Group status is persisted as `TaskRunStatus.canceled`.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-003` -> `Closed/OK`
    (implementation commit `98f86b2`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-004 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> `+3`.

## 📁 Updated files

- `test/presentation/timer_screen_completion_navigation_test.dart`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-004` validation (Phase 19 Groups Hub core UI + Task List banner/Run Mode indicator entry points).

# 🔹 Block 617 — RVP-004 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-004` — Phase 19 Groups Hub core UI (sections + actions), plus navigation
entry points from Task List banner and Run Mode indicator.

Concrete validated cases to close:

1. Task List `View Groups Hub` CTA opens `/groups`.
2. Run Mode `Planned groups` indicator opens `/groups`.
3. Groups Hub renders core sections (`Running / Paused`, `Scheduled`,
   `Completed`, `Canceled`) and core actions (`Open Run Mode`, `Start now`,
   `Cancel schedule`, `Run again`, `Re-plan group`).

## ✔ Work completed

- Extended widget coverage in:
  - `test/presentation/timer_screen_completion_navigation_test.dart`
- Added dedicated RVP-004 scenarios:
  - `Run Mode planned-groups indicator opens Groups Hub`
  - `Task List Groups Hub CTA opens Groups Hub`
  - `Groups Hub core sections and actions are visible`
- Added reusable test helpers for bounded waits and controlled list scrolling:
  - `_pumpTaskListScreen`, `_pumpGroupsHubScreen`, `_dragUntilFound`
- Reused/extended fake repositories to seed running/scheduled/completed/canceled
  groups for full section/action rendering coverage.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-004` -> `Closed/OK`
    (implementation commit `3b78667`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-005 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> `+6`.

## 📁 Updated files

- `test/presentation/timer_screen_completion_navigation_test.dart`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-005` validation (Task List banner stale-session cleanup on group end).

# 🔹 Block 618 — RVP-005 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-005` — Task List banner must clear stale active session state when the
linked group has already ended.

Concrete validated cases to close:

1. Active session points to a `completed` group -> stale session is cleared and
   user gets `Group completed.` feedback.
2. Active session points to a `canceled` group -> stale session is cleared and
   user gets `Group ended.` feedback.

## ✔ Work completed

- Extended test repository double in:
  - `test/presentation/timer_screen_completion_navigation_test.dart`
  - Added `clearSessionIfGroupNotRunningCalls` tracking and null-session emit
    on cleanup call.
- Added dedicated Task List stale-session validation scenarios:
  - `Task List clears stale active session when group is completed`
  - `Task List clears stale active session when group is canceled`
- Validated cleanup path in `TaskListScreen` (`_maybeResolveStaleActiveSession`)
  through widget flow with real banner/session wiring.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-005` -> `Closed/OK`
    (implementation commit `6dc4d64`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-006 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> `+8`.

## 📁 Updated files

- `test/presentation/timer_screen_completion_navigation_test.dart`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-006` validation (scheduled auto-start recheck after active session end + expired-running auto-complete unblock).

# 🔹 Block 619 — RVP-006 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-006` — scheduled auto-start must re-evaluate when the active session ends,
and expired `running` groups must auto-complete so overdue scheduled groups can
start.

Concrete validated cases to close:

1. Overdue scheduled auto-start is rechecked on `activeSession` transition
   `non-null -> null`.
2. Expired running group is completed and no longer blocks overdue scheduled
   auto-start.

## ✔ Work completed

- Extended coordinator test doubles in:
  - `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
  - Added cleanup observability counters in `FakePomodoroSessionRepository`:
    `clearSessionAsOwnerCount`, `clearSessionIfStaleCount`,
    `clearSessionIfGroupNotRunningCount`.
- Added dedicated `RVP-006` scenarios:
  - `rechecks overdue scheduled auto-start when active session ends`
  - `completes expired running group and unblocks overdue scheduled auto-start`
- Added required `AppModeService` overrides in test containers so the current
  coordinator diagnostics path (`mode=...`) is valid in unit tests.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-006` -> `Closed/OK`
    (implementation commit `358c278`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-007 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` -> `+18`.

## 📁 Updated files

- `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-007` validation (running-group expiry clears stale active session / Task List banner state).

# 🔹 Block 620 — RVP-007 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-007` — running-group expiry must clear stale `activeSession` state so
terminal groups do not keep stale live-session ownership, and scheduled
execution can continue.

Concrete validated cases to close:

1. Expired running group on owner path clears stale session authority
   (`clearSessionAsOwner`) and allows overdue scheduled group progression.
2. Expired running group on stale non-owner path clears stale session via
   guarded cleanup (`clearSessionIfStale`) and allows overdue scheduled group
   progression.

## ✔ Work completed

- Extended coordinator test doubles in:
  - `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
  - Fake repositories now expose deterministic initial stream values
    (`watchAll`/`watchSession` yield current snapshot before stream updates).
- Added dedicated stale non-owner validation scenario:
  - `clears stale non-owner active session when expired running group unblocks overdue scheduled start`
- Reused and validated owner-path stale clear coverage from:
  - `completes expired running group and unblocks overdue scheduled auto-start`
  - This case asserts running expiry completion + owner stale-session cleanup.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-007` -> `Closed/OK`
    (implementation commit `b33c13f`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-008 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` -> `+19`.

## 📁 Updated files

- `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-008` validation (schedule must reserve full Pre-Run notice window and reject invalid overlaps/times).

# 🔹 Block 621 — RVP-008 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-008` — scheduling must reserve the complete Pre-Run window
(`scheduledStart - noticeMinutes` to `scheduledStart`) and block invalid starts
when that window overlaps existing running/scheduled execution.

Concrete validated cases to close:

1. Scheduling is blocked when the requested Pre-Run window overlaps a running
   group (even if the new execution window would not overlap).
2. Scheduling is blocked when the requested Pre-Run window overlaps an earlier
   scheduled group (even if the new execution window would not overlap).

## ✔ Work completed

- Extended Task List widget-test harness in:
  - `test/presentation/timer_screen_completion_navigation_test.dart`
  - Added `/tasks/plan` test route stub (`_PlanningResultRoute`) to return a
    deterministic `TaskGroupPlanningResult` without touching production code.
- Added dedicated `RVP-008` scenarios:
  - `Task List blocks scheduling when pre-run window overlaps a running group`
  - `Task List blocks scheduling when pre-run window overlaps an earlier scheduled group`
- Both scenarios assert:
  - the specific Pre-Run blocking message appears (`running` vs `scheduled`),
  - no additional TaskRunGroup is saved when scheduling is rejected.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-008` -> `Closed/OK`
    (implementation commit `358c278`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-009 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> `+10`.
- `flutter analyze` -> `No issues found!`.

## 📁 Updated files

- `test/presentation/timer_screen_completion_navigation_test.dart`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-009` validation (Pre-Run entry points from Task List banner and Groups Hub action).

# 🔹 Block 622 — Deferred feature definition for scheduling conflict UX (20/03/2026)

## 📋 Context

After validating `RVP-008`, user testing confirmed the current conflict feedback
is technically correct but hard to understand in practice:

- message is generic,
- snackbar disappears too quickly,
- no explicit blocker context (which groups/ranges cause the conflict).

The requested change is a feature-level UX upgrade, not an immediate bugfix.
Implementation is intentionally deferred until the historical `RVP-*` validation
backlog is closed.

## ✔ Work completed

- Captured and formalized new feature definition as:
  - `IDEA-039 — Scheduling Conflict Explainer + Guided Start Suggestions`
  - `docs/features/feature_backlog.md`
- Added roadmap traceability under reopened Phase 17 feature scope:
  - blocking explainer modal (replacing ephemeral conflict snackbar),
  - list all exact blockers (running/scheduled) with ranges,
  - include pre-run ranges where applicable.
- Added ledger tracking entry (deferred feature item) so closure remains
  explicit and auditable before implementation.

## 🧠 Confirmed product rules for future implementation

1. Case A — pre-run-only conflict:
   - auto-adjust effective notice with the same behavior already used for
     "start too soon" clamp coherence.
2. Case B — execution conflict (without pre-run):
   - keep current notice/pre-run unchanged,
   - provide up to two nearest valid start suggestions (before/after),
   - enforce minute-safe separation to avoid second-boundary overlap.
3. If both appear, execution-conflict handling takes precedence.

## 📁 Updated files

- `docs/features/feature_backlog.md`
- `docs/roadmap.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Continue historical validation queue with `RVP-009`.
2. Re-open `IDEA-039` implementation only after the `RVP-*` backlog priority
   gate is satisfied.

# 🔹 Block 623 — RVP-009 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-009` — scheduled groups in active Pre-Run must expose direct Run Mode
entry points from both surfaces:

1. Task List active Pre-Run banner shows `Open Pre-Run`.
2. Groups Hub scheduled card shows `Open Pre-Run` (instead of `Start now`)
   while the Pre-Run window is active.

## ✔ Work completed

- Extended widget-test harness in:
  - `test/presentation/timer_screen_completion_navigation_test.dart`
  - Added optional timer route stubbing to `_pumpTaskListScreen` and
    `_pumpGroupsHubScreen` so route-navigation assertions are deterministic.
- Added dedicated `RVP-009` validation scenarios:
  - `Task List pre-run banner opens Timer via Open Pre-Run`
  - `Groups Hub shows Open Pre-Run action for active pre-run scheduled group`
- Both scenarios validate:
  - `Open Pre-Run` CTA is visible in active Pre-Run context,
  - Groups Hub does not show `Start now` for that active Pre-Run card,
  - tapping the CTA navigates to `/timer/:groupId`.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-009` -> `Closed/OK`
    (implementation commit `358c278`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-010 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> `+12`.
- `flutter analyze` -> `No issues found!`.

## 📁 Updated files

- `test/presentation/timer_screen_completion_navigation_test.dart`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-010` validation (Task List persistent Groups Hub CTA with no active group).

# 🔹 Block 624 — RVP-010 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-010` — Task List must keep a persistent `View Groups Hub` CTA visible even
when there is no active session and no running/pre-run group.

Concrete validated case to close:

1. With `activeSession = null` and no seeded groups, Task List still renders
   `View Groups Hub` and the CTA navigates to `/groups`.

## ✔ Work completed

- Confirmed existing dedicated widget test already covers the exact scenario:
  - `Task List Groups Hub CTA opens Groups Hub`
  - fixture setup uses empty `FakeTaskRunGroupRepository` + null session.
- No app code changes were required.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-010` -> `Closed/OK`
    (implementation commit `3b78667`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-011 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> `+12`.
- `flutter analyze` -> `No issues found!`.

## 📁 Updated files

- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-011` validation (Task List running banner fallback to running groups when there is no active session in Local Mode).

# 🔹 Block 625 — RVP-011 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-011` — in Local Mode, when `activeSession` is missing/null, Task List must
still surface the running-group banner by falling back to `TaskRunGroup.status=running`.

Concrete validated case to close:

1. `activeSession = null` + one running group in repository -> Task List renders
   `Group Running` banner and `Open Run Mode` opens `/timer/:groupId`.

## ✔ Work completed

- Added dedicated widget validation case in:
  - `test/presentation/timer_screen_completion_navigation_test.dart`
  - `Task List falls back to running group banner when active session is null in Local Mode`
- Scenario setup:
  - Local Mode explicitly selected.
  - `FakePomodoroSessionRepository(null)` (no active session).
  - One seeded running group (`local-fallback-running`).
- Assertions:
  - `Group Running` banner is visible with running-group name.
  - `Open Run Mode` action navigates to the expected timer route.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-011` -> `Closed/OK`
    (implementation commit `2189e11`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-012 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> `+13`.
- `flutter analyze` -> `No issues found!`.

## 📁 Updated files

- `test/presentation/timer_screen_completion_navigation_test.dart`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-012` validation (Groups Hub hides notice/pre-run rows for start-now groups with `scheduledStartTime == null`).

# 🔹 Block 626 — RVP-012 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-012` — Groups Hub must hide scheduling notice metadata for start-now style
groups (`status=scheduled` but `scheduledStartTime == null`), avoiding
misleading `Scheduled` / `Pre-Run` details.

Concrete validated case to close:

1. Start-now scheduled group (`scheduledStartTime=null`) shows `Start now`
   action but does not render `Open Pre-Run`, `Scheduled start`, or `Pre-Run`
   metadata in card/summary.

## ✔ Work completed

- Added dedicated widget validation case in:
  - `test/presentation/timer_screen_completion_navigation_test.dart`
  - `Groups Hub hides scheduled and pre-run metadata for start-now scheduled groups`
- Scenario setup:
  - one seeded scheduled group with `scheduledStartTime: null`,
    `noticeMinutes: 10`, and valid end time.
  - `activeSession = null`.
- Assertions:
  - card shows `Start now` and hides `Open Pre-Run` / `Pre-Run`,
  - summary modal hides `Scheduled start` and `Pre-Run`.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-012` -> `Closed/OK`
    (implementation commit `d193121`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-013 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> `+14`.
- `flutter analyze` -> `No issues found!`.

## 📁 Updated files

- `test/presentation/timer_screen_completion_navigation_test.dart`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-013` validation (Phase 10 auto-adjust short/long breaks on valid pomodoro and break edits).

# 🔹 Block 627 — RVP-013 closure by existing validation coverage (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-013` — auto-adjust short/long breaks on valid pomodoro changes and break
edits (Task Editor + Edit Preset).

This behavior had already been validated under the reopened P1 item `RVP-063`,
which covers the same functional scope with explicit Task Editor + Edit Preset
evidence.

## ✔ Work completed

- Closed `RVP-013` as covered by existing `RVP-063` validation evidence
  (no additional app implementation changes).
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-013` -> `Closed/OK`
    with explicit cross-reference to `RVP-063`.
  - `docs/roadmap.md`: line updated to reflect both validation IDs
    (`RVP-063` + `RVP-013`) as closed.
  - `docs/dev_log.md`: focus moved to `RVP-014 onward`.

## 🧪 Verification run

Reused existing local gate evidence from `RVP-063` (20/03/2026):

- `flutter analyze` -> `No issues found!`
- `flutter test test/domain/validators_test.dart test/domain/task_weighting_test.dart test/presentation/viewmodels/task_editor_view_model_test.dart` -> PASS (`+28`)

No new code path was introduced for `RVP-013`; therefore no additional runtime
validation command was required in this closure step.

## 📁 Updated files

- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-014` validation (break auto-adjust applies on focus loss, not per-keystroke).

# 🔹 Block 628 — RVP-014 closure by existing validation coverage (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-014` — break auto-adjust on break edits applies on focus loss (not
per-keystroke).

This behavior was already validated under reopened P1 item `RVP-063`, which
explicitly includes focus-loss adjustment behavior.

## ✔ Work completed

- Closed `RVP-014` as covered by existing `RVP-063` validation evidence
  (no additional app implementation changes).
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-014` -> `Closed/OK`
    with explicit cross-reference to `RVP-063`.
  - `docs/roadmap.md`: line updated to reflect both validation IDs
    (`RVP-063` + `RVP-014`) as closed.
  - `docs/dev_log.md`: focus moved to `RVP-015 onward`.

## 🧪 Verification run

Reused existing local gate evidence from `RVP-063` (20/03/2026):

- `flutter analyze` -> `No issues found!`
- `flutter test test/domain/validators_test.dart test/domain/task_weighting_test.dart test/presentation/viewmodels/task_editor_view_model_test.dart` -> PASS (`+28`)

No new code path was introduced for `RVP-014`; therefore no additional runtime
validation command was required in this closure step.

## 📁 Updated files

- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-015` validation (Pomodoro Integrity Warning actions show exact configuration source names).

# 🔹 Block 629 — RVP-015 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-015` — Pomodoro Integrity Warning actions must show the exact source
configuration names so users can identify which structure each option comes
from before applying it.

Concrete validated case to close:

1. Mixed-structure selection (two tasks with distinct Pomodoro structures)
   opens Integrity Warning with explicit source labeling (`Used by:`) and exact
   task names for each structure option.

## ✔ Work completed

- Added dedicated widget validation case in:
  - `test/presentation/timer_screen_completion_navigation_test.dart`
  - `Integrity warning options show exact source task names for each structure`
- Scenario setup:
  - two selected tasks with different structures (`Deep Work`, `Email Batch`),
  - tap `Next` to trigger Integrity Warning dialog.
- Assertions:
  - dialog title `Pomodoro integrity warning` is shown,
  - two `Used by:` source sections are rendered (one per distinct structure),
  - exact source task names are visible in the dialog (`Deep Work`,
    `Email Batch`).
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-015` -> `Closed/OK`
    (implementation commit `12571b2`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-016 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> `+15`.
- `flutter analyze` -> `No issues found!`.

## 📁 Updated files

- `test/presentation/timer_screen_completion_navigation_test.dart`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-016` validation (Integrity Warning shows one visual option per distinct structure + default preset badge).

# 🔹 Block 630 — RVP-016 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-016` — Pomodoro Integrity Warning must present one visual option per
distinct structure and include a `Default preset` badge option when a default
preset exists.

Concrete validated case to close:

1. Mixed selection with two distinct structures + existing default preset must
   render two structure option cards (`Used by:`) and one default-preset option.

## ✔ Work completed

- Added dedicated widget validation case in:
  - `test/presentation/timer_screen_completion_navigation_test.dart`
  - `Integrity warning lists one visual option per structure and shows default preset badge`
- Scenario setup:
  - three selected tasks where two share one structure and one uses a different
    structure (`Deep Work`, `Planning`, `Email Batch`),
  - in-memory default preset seeded (`Focus Default`).
- Assertions:
  - Integrity Warning dialog appears,
  - exactly two `Used by:` structure sections are rendered,
  - `Default preset` badge option is shown,
  - source task names are visible in structure chips.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-016` -> `Closed/OK`
    (implementation commit `8e9b881`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-017 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> `+16`.
- `flutter analyze` -> `No issues found!`.

## 📁 Updated files

- `test/presentation/timer_screen_completion_navigation_test.dart`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-017` validation (Run Mode auto-exits to Groups Hub when group is canceled).

# 🔹 Block 631 — RVP-017 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-017` — when a running group becomes canceled while Run Mode is visible,
the screen must auto-exit to Groups Hub (no idle/stale timer screen).

Concrete validated case to close:

1. In Run Mode, cancel requires confirmation; after `Cancel group`, status
   becomes `canceled` and navigation must end in Groups Hub.

## ✔ Work completed

- Verified existing implementation/test coverage without changing app logic:
  - `lib/presentation/screens/timer_screen.dart`
  - `test/presentation/timer_screen_completion_navigation_test.dart`
- Confirmed behavior from dedicated widget scenario:
  - `cancel requests confirmation and navigates to Groups Hub only after confirm`
- Assertions validated:
  - confirmation dialog appears (`Cancel group?`, `Keep running`, `Cancel group`),
  - `Keep running` keeps user in Run Mode,
  - `Cancel group` navigates to Groups Hub,
  - repository state persists `TaskRunStatus.canceled`.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-017` -> `Closed/OK`
    (implementation commit `8e9b881`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-018 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "cancel requests confirmation and navigates to Groups Hub only after confirm"` -> `+1`.
- `flutter analyze` -> `No issues found!`.

## 📁 Updated files

- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-018` validation (Integrity Warning copy clarified + default badge below cards).

# 🔹 Block 632 — RVP-018 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-018` — Pomodoro Integrity Warning text must explicitly explain why mixed
structures are risky and present the `Default preset` option below the
structure cards to keep the visual hierarchy clear.

Concrete validated case to close:

1. Mixed-structure selection with a default preset available must show the
   clarified guidance copy and place `Default preset` below the structure
   options (`Used by:` cards).

## ✔ Work completed

- Added dedicated widget validation case in:
  - `test/presentation/timer_screen_completion_navigation_test.dart`
  - `Integrity warning shows clarified guidance copy and keeps default preset option below structure cards`
- Scenario setup:
  - three selected tasks with two distinct structures (`Deep Work`,
    `Planning`, `Email Batch`),
  - in-memory default preset seeded (`Focus Default`).
- Assertions:
  - warning copy includes explicit mixed-structure guidance and action intent
    (`configuration to apply to this group`),
  - two `Used by:` structure sections are rendered,
  - `Default preset` is rendered below the structure cards (vertical-position
    assertion against the last `Used by:` section).
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-018` -> `Closed/OK`
    (implementation commit `8e9b881`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-019 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Integrity warning shows clarified guidance copy and keeps default preset option below structure cards"` -> `+1`.
- `flutter analyze` -> `No issues found!`.

## 📁 Updated files

- `test/presentation/timer_screen_completion_navigation_test.dart`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-019` validation (Groups Hub summary modal expanded with timing, totals, and task breakdown).

# 🔹 Block 633 — RVP-019 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-019` — tapping a group in Groups Hub must open an expanded summary modal
with timing details, totals, and per-task breakdown.

Concrete validated case to close:

1. A scheduled group with notice/pre-run and multiple tasks opens `Group summary`
   showing `Timing`, `Totals`, and `Tasks` sections with complete breakdown.

## ✔ Work completed

- Added dedicated widget validation case in:
  - `test/presentation/timer_screen_completion_navigation_test.dart`
  - `Groups Hub summary modal shows timing totals and task breakdown`
- Scenario setup:
  - seeded scheduled group with two tasks (`Test task`, `Email Batch`),
  - explicit totals (`totalTasks=2`, `totalPomodoros=3`,
    `totalDurationSeconds=5400`) and `noticeMinutes=10`.
- Assertions:
  - summary modal title appears (`Group summary`),
  - sections `Timing`, `Totals`, `Tasks` are visible,
  - timing rows include `Scheduled start`, `Pre-Run`, `Actual start`, `End`,
    `Total time`,
  - totals include `Pomodoros`,
  - task breakdown includes second task entry (`Email Batch`),
  - pre-run descriptive copy (`min starts at`) is present.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-019` -> `Closed/OK`
    (implementation commit `c2c1172`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-020 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Groups Hub summary modal shows timing totals and task breakdown"` -> `+1`.
- `flutter analyze` -> `No issues found!`.

## 📁 Updated files

- `test/presentation/timer_screen_completion_navigation_test.dart`
- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-020` validation (Groups Hub summary hides Scheduled start for non-planned runs).

# 🔹 Block 634 — Deferred feature capture: Start-now `Started` timing context (20/03/2026)

## 📋 Context

User feedback during validation review: for Start-now groups in Groups Hub,
removing `Scheduled start` is correct, but the card still needs explicit
`Started` timing context (actual start) to avoid ambiguity.

## ✔ Work completed

- Captured this as a deferred feature/new requirement (no runtime change yet):
  - `docs/features/feature_backlog.md`: added `IDEA-040 — Groups Hub Started Time For Start-Now Groups`.
  - `docs/roadmap.md`: clarified reopened Phase 19 timing-row requirement as
    new requirement (explicit `Started` for Start-now groups + scheduled/pre-run
    coherence for scheduled groups).
  - `docs/validation/validation_ledger.md`: added deferred tracking entry
    `IDEA-040` under P2 deferred feature backlog items.

## 🧪 Verification run

Not applicable (documentation-only capture, no app code changes).

## 📁 Updated files

- `docs/features/feature_backlog.md`
- `docs/roadmap.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Continue historical RVP validation order from `RVP-020`.

# 🔹 Block 635 — RVP-020 validation closure (20/03/2026)

## 📋 Context

Next pending P2 historical validation item:
`RVP-020` — Groups Hub summary modal must hide `Scheduled start` for
non-planned runs (`scheduledStartTime == null`).

Concrete validated case to close:

1. A Start-now group opened in Groups Hub summary must not render
   `Scheduled start` (and no pre-run row for that non-planned flow).

## ✔ Work completed

- Reused existing dedicated widget coverage (no app logic change):
  - `test/presentation/timer_screen_completion_navigation_test.dart`
  - `Groups Hub hides scheduled and pre-run metadata for start-now scheduled groups`
- Assertions validated:
  - Start-now card shows `Start now`,
  - card does not show `Open Pre-Run` / `Pre-Run`,
  - summary modal does not show `Scheduled start`,
  - summary modal does not show `Pre-Run`.
- Synchronized docs:
  - `docs/validation/validation_ledger.md`: `RVP-020` -> `Closed/OK`
    (implementation commit `7e75e6d`).
  - `docs/roadmap.md`: item now marked validated/closed.
  - `docs/dev_log.md`: focus moved to `RVP-021 onward`.

## 🧪 Verification run

PASS:

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Groups Hub hides scheduled and pre-run metadata for start-now scheduled groups"` -> `+1`.
- `flutter analyze` -> `No issues found!`.

## 📁 Updated files

- `docs/validation/validation_ledger.md`
- `docs/roadmap.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `RVP-021` validation (Groups Hub cards hide Scheduled row for non-planned runs).

# 🔹 Block 636 — Bug snapshot audit sync (20/03/2026)

## 📋 Context

During validation review, the ledger snapshot line
`Active bug-checklist open items: 2` was reported as likely outdated.

## ✔ Work completed

- Audited `docs/bugs/bug_log.md` status entries.
- Updated `docs/validation/validation_ledger.md` snapshot to reflect current
  bug-log non-closed counts and explicit status breakdown.

## 🧪 Verification run

Documentation audit only (no runtime code change).

## 📁 Updated files

- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Continue historical RVP validation order from `RVP-021`.

# 🔹 Block 637 — Bug-log -> validation-ledger queue sync (20/03/2026)

## 📋 Context

Owner requested to prioritize bugs over historical RVP validations and asked for
all non-closed entries in `docs/bugs/bug_log.md` to be explicitly represented in
`docs/validation/validation_ledger.md`.

## ✔ Work completed

- Audited all bug-log `Status:` blocks and extracted non-closed entries.
- Added a dedicated ledger section:
  - `### Active bug-log queue (sync 2026-03-20)`
- Registered all currently non-closed bug-log items (15 total) with stable
  ledger IDs, priorities, and actionable statuses (`Pending` or `In validation`).
- Included explicit source references to `bug_log.md` line numbers for each
  queue item.
- Captured reopened traceability for `BUG-F25-E` as `BUGLOG-F25-E-R1` so the
  open bug-log state is visible in the active queue.

## 🧪 Verification run

Documentation sync only (no runtime code changes).

## 📁 Updated files

- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Start resolving the active bug-log queue in priority order (P1 first), then
   resume historical RVP backlog.

# 🔹 Block 638 — Bug-first preflight guardrail (20/03/2026)

## 📋 Context

A process gap was confirmed: priority rules existed, but there was no explicit
mandatory step to reconcile all non-closed `bug_log.md` entries with
`validation_ledger.md` before continuing with RVP validations or feature work.
This allowed the ledger queue to drift from the real bug backlog.

## ✔ Work completed

- Added an explicit bug-priority preflight gate to `AGENTS.md`:
  - startup read now includes `docs/bugs/bug_log.md`.
  - mandatory reconciliation of non-closed bug-log entries against the ledger.
  - priority order updated to execute active bug queue before reopened/historical RVP items.
- Added the same mandatory preflight rule to `CLAUDE.md`:
  - project orientation includes the reconciliation gate.
  - bug lifecycle now starts with `0. PRE-FLIGHT SYNC`.
- Added cross-role enforcement in `docs/team_roles.md`:
  - new coordination golden rule for bug-first preflight.
  - handoff format now requires a bug-queue status checkpoint before non-bug work.

## 🧪 Verification run

Documentation/process update only (no runtime code changes).

## 📁 Updated files

- `AGENTS.md`
- `CLAUDE.md`
- `docs/team_roles.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute the active bug queue from `docs/validation/validation_ledger.md` in priority order.

# 🔹 Block 639 — Branch-scope lock to prevent mixed-track commits (20/03/2026)

## 📋 Context

A workflow risk was identified: multiple commit tracks were accumulated on the
same branch (`fix-roadmap-f25-closure-sync`), mixing roadmap/validation closures
with process-governance documentation updates. Even when each commit is valid,
this reduces branch intent clarity and makes review/merge riskier.

## ✔ Work completed

- Strengthened branch-scope guardrails in `AGENTS.md`:
  - added mandatory branch-scope checkpoint before new commits.
  - added explicit `branch scope lock` rule: one branch = one scope family.
- Strengthened branch rules in `CLAUDE.md`:
  - added `R-7 Branch scope lock`.
  - added `R-8 Pre-commit branch check`.
- Extended handoff contract in `docs/team_roles.md`:
  - added mandatory `Branch-scope checkpoint` section before implementation/commit.

## 🧪 Verification run

Documentation/process update only (no runtime code changes).

## 📁 Updated files

- `AGENTS.md`
- `CLAUDE.md`
- `docs/team_roles.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. For the next non-validation/process task, create a dedicated branch that matches scope before editing.

# 🔹 Block 640 — BUGLOG-002-R1 user re-validation (21/03/2026)

## 📋 Context

Owner re-tested the residual `BUG-002` symptom (owner-side rejection banner
persistence) with repeated pause/background + reject/accept cycles in Run Mode.

## ✔ Work completed

- Recorded user-provided evidence from Android + Chrome re-run (group
  `15e6300b-0ab9-47a4-a5f8-7e220a7c31c3`) in `docs/bugs/bug_log.md`.
- Updated `docs/validation/validation_ledger.md` item `BUGLOG-002-R1` from
  `In validation` to `Validated`.
- Residual symptom (`owner rejection banner persists / second press needed`) was
  not reproduced in this validation run.

## 🧪 Verification run

Documentation/status sync only (no runtime code changes).

## 📁 Updated files

- `docs/bugs/bug_log.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Request explicit final owner confirmation to close `BUGLOG-002-R1` as `Closed/OK`.
2. Continue bug queue priority order after closure (`BUGLOG-009A` / `BUGLOG-004` / `BUGLOG-011` / `BUGLOG-012` / `BUGLOG-008B` / `BUGLOG-005` / `BUGLOG-006` / `BUGLOG-007`).

# 🔹 Block 641 — BUGLOG-002-R1 monitor note (no patch) (21/03/2026)

## 📋 Context

During owner validation follow-up, a brief (~1s) re-show of the Chrome owner
request banner was visually observed around 13:37:11 after reject.

## ✔ Work completed

- Added traceability note to `docs/bugs/bug_log.md` under `BUG-002` re-validation
  update (UI observation + correlated log pattern).
- Updated `docs/validation/validation_ledger.md` evidence for `BUGLOG-002-R1`
  to include this monitor-only anomaly.
- Explicit decision recorded: no runtime patch now, to avoid masking a possible
  underlying sync-order root cause while the behavior is self-recovering and
  non-blocking.

## 🧪 Verification run

Documentation/status sync only (no runtime code changes).

## 📁 Updated files

- `docs/bugs/bug_log.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Keep `BUGLOG-002-R1` in `Validated` monitor state.
2. Reopen implementation only if the banner re-show becomes persistent,
   requires user action, or causes state desync.

# 🔹 Block 642 — BUGLOG-009A rollback-status sync before re-validation (21/03/2026)

## 📋 Context

While continuing the active bug queue in priority order, `BUGLOG-009A` still
described the regression rollback as "pending" in both `bug_log` and
`validation_ledger`.

## ✔ Work completed

- Updated `BUG-009` entry in `docs/bugs/bug_log.md` to reflect factual status:
  rollback was already applied on 18/02/2026 (commit `0d2f7a4`).
- Updated `BUGLOG-009A` item wording in
  `docs/validation/validation_ledger.md`:
  - rollback no longer marked pending.
  - item remains pending because modern re-validation is still required.
- Refreshed active bug-queue sync date in ledger header to `2026-03-21`.

## 🧪 Verification run

Documentation/status sync only (no runtime code changes).

## 📁 Updated files

- `docs/bugs/bug_log.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute `BUGLOG-009A` exact repro validation case and classify result:
   - `Closed/OK` if not reproducible with current architecture.
   - keep `Open` with fresh evidence if reproducible.

# 🔹 Block 643 — BUGLOG-009A closed as non-repro after owner re-validation (21/03/2026)

## 📋 Context

Owner completed additional manual re-validation for `BUGLOG-009A` and confirmed
the historical symptom (mirror per-second timer swap after ownership handoff)
is no longer reproducible.

## ✔ Work completed

- Marked `BUG-009` as `Closed/OK` in `docs/bugs/bug_log.md`.
- Closed `BUGLOG-009A` in `docs/validation/validation_ledger.md` with explicit
  evidence from owner confirmation.
- Linked closure implementation reference to rollback commit `0d2f7a4`
  (`Revert mirror timer suppression due to ownership freeze`).

## 🧪 Verification run

Owner manual validation confirmation (21/03/2026):

- Multiple test runs using different interaction paths.
- Per-second mirror timer swap did not reappear.

## 📁 Updated files

- `docs/bugs/bug_log.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Continue active bug queue in priority order with `BUGLOG-004`.

# 🔹 Block 644 — BUGLOG-004 closed after long soak non-repro (21/03/2026)

## 📋 Context

Owner reported extended re-validation for `BUGLOG-004` with Android + macOS
running simultaneously for more than 10 hours without reproducing mirror drift
growth during long breaks.

## ✔ Work completed

- Marked `BUG-004` as `Closed/OK` in `docs/bugs/bug_log.md`.
- Updated `BUGLOG-004` in `docs/validation/validation_ledger.md` to
  `Closed/OK` with closure metadata.
- Linked closure to the implementation packet commit `25878cc`
  (`Stabilize ownership sync and server-time projection`).

## 🧪 Verification run

Owner manual soak validation confirmation (21/03/2026):

- Android + macOS simultaneously for >10h.
- No accumulating mirror drift observed.
- No timer jump recurrence after navigation was observed in the reported run.

## 📁 Updated files

- `docs/bugs/bug_log.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Continue active bug queue in priority order with `BUGLOG-011`.

# 🔹 Block 645 — BUGLOG-011 closed as non-repro in current builds (21/03/2026)

## 📋 Context

Owner confirmed that `BUGLOG-011` (pause offset drift after
background/foreground) is no longer reproducible.

## ✔ Work completed

- Marked `BUG-011` as `Closed/OK` in `docs/bugs/bug_log.md`.
- Closed `BUGLOG-011` in `docs/validation/validation_ledger.md` with explicit
  owner evidence.
- Linked closure to fix commit `abb053d`
  (`fix: stabilize owner hydration after pause re-entry`).

## 🧪 Verification run

Owner validation confirmation (21/03/2026):

- Pause/resume + background/foreground behavior works correctly.
- Previous pause-offset drift symptom no longer appears.

## 📁 Updated files

- `docs/bugs/bug_log.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Continue active bug queue in priority order with `BUGLOG-012`.

# 🔹 Block 646 — BUGLOG-012 closed under Fix 26 rewrite evidence (21/03/2026)

## 📋 Context

Owner reported that `BUGLOG-012` appears solved after the Fix 26 refactor
(`TimerService` + `SessionSyncService` architecture).

## ✔ Work completed

- Marked `BUG-012` as `Closed/OK` in `docs/bugs/bug_log.md`.
- Closed `BUGLOG-012` in `docs/validation/validation_ledger.md`.
- Linked closure to Fix 26 closure commit `cbd800a` and Stage C validation
  packet (`P0-F26-006`).

## 🧪 Verification run

- Existing Fix 26 Stage C pass2 soak evidence (16/03/2026) already confirms no
  irrecoverable `Syncing session...` holds in long Android+macOS runs.
- Owner confirmation (21/03/2026): no current trace of mirror-stuck behavior.

## 📁 Updated files

- `docs/bugs/bug_log.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Continue active bug queue in priority order with `BUGLOG-008B` (next P1 pending).

# 🔹 Block 647 — BUGLOG-009B/013/014 fix implementation packet (23/03/2026)

## 📋 Context

Current branch intent: `P1 bugfixes for late-start overlap queue + completion modal + postpone race`.

User validation on 23/03/2026 confirmed three active issues:

- `BUGLOG-009B`: overlap queue resolved only part of a 3-group chain.
- `BUGLOG-013`: completion modal blocked next-group pre-run/run.
- `BUGLOG-014`: `Postpone scheduled` could require a second press.

## ✔ Work completed

- Implemented `BUGLOG-009B` layer 1 in:
  - `lib/presentation/utils/scheduled_group_timing.dart`
  - `resolveLateStartConflictSet` now cascades conflicts iteratively.
- Implemented `BUGLOG-009B` layer 2 in:
  - `lib/presentation/screens/late_start_overlap_queue_screen.dart`
  - post-confirm overlap revalidation against non-selected scheduled groups,
    with queue reopen when conflicts remain.
- Implemented `BUG-013` in:
  - `lib/presentation/screens/timer_screen.dart`
  - completion modal auto-dismiss on route group switch and next-group auto-open.
- Implemented `BUG-014` in:
  - `lib/presentation/screens/timer_screen.dart`
  - deterministic postpone guard (`decision key + expected scheduled start`)
    synchronized by repository snapshots.
- Added/updated targeted regression tests:
  - `test/presentation/utils/scheduled_group_timing_test.dart`
  - `test/presentation/timer_screen_completion_navigation_test.dart`

## 🧪 Verification run

- `flutter analyze` → PASS
- `flutter test test/presentation/utils/scheduled_group_timing_test.dart` → PASS
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` → PASS
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` → PASS

## 📁 Updated files

- `lib/presentation/utils/scheduled_group_timing.dart`
- `lib/presentation/screens/late_start_overlap_queue_screen.dart`
- `lib/presentation/screens/timer_screen.dart`
- `test/presentation/utils/scheduled_group_timing_test.dart`
- `test/presentation/timer_screen_completion_navigation_test.dart`
- `docs/bugs/bug_log.md`
- `docs/validation/validation_ledger.md`
- `docs/bugs/validation_bug009_2026_03_23/plan_validacion_rapida_fix.md`
- `docs/bugs/validation_bug009_2026_03_23/quick_pass_checklist.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Run device validation protocol A/B/C on iOS Simulator + Chrome with current branch.
2. If PASS, close `BUGLOG-009B`, `BUGLOG-013`, `BUGLOG-014` with commit hash/message in `bug_log.md` + `validation_ledger.md`.

# 🔹 Block 648 — BUGLOG-009B validated + BUG-013 pre-run dismiss patch (23/03/2026)

## 📋 Context

Current branch intent: `P1 bugfixes for BUGLOG-009B / BUG-013 / BUG-014 validation packet`.

`fix_v2` device logs confirmed `BUGLOG-009B` behavior is resolved (no second runtime queue),
but `BUG-013` still dismissed completion modal at group switch (`14:04`) instead of pre-run
boundary (`14:03`).

## ✔ Work completed

- Implemented `BUG-013` follow-up in `TimerScreen`:
  - completion modal now auto-dismisses when `scheduledAutoStartGroupIdProvider`
    announces a different next group (`next != widget.groupId`) during pre-run auto-open.
- Kept existing auto-dismiss paths for group switch and active execution transitions.
- Added regression coverage in
  `test/presentation/timer_screen_completion_navigation_test.dart`:
  - `auto-dismisses completion modal when next group pre-run auto-open is announced`.
- Synced validation docs with current state:
  - `docs/bugs/validation_bug009_2026_03_23/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug009_2026_03_23/quick_pass_checklist.md`
  - `docs/bugs/bug_log.md`
  - `docs/validation/validation_ledger.md`

## 🧪 Verification run

- `flutter analyze` → PASS (`No issues found!`)
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` → PASS (`+21`)
- `flutter test test/presentation/utils/scheduled_group_timing_test.dart` → PASS (`+7`)
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` → PASS (`+19`)

## 📁 Updated files

- `lib/presentation/screens/timer_screen.dart`
- `test/presentation/timer_screen_completion_navigation_test.dart`
- `docs/bugs/validation_bug009_2026_03_23/plan_validacion_rapida_fix.md`
- `docs/bugs/validation_bug009_2026_03_23/quick_pass_checklist.md`
- `docs/bugs/bug_log.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute device rerun (`fix_v3`) on iOS + Chrome using updated commands in plan.
2. Confirm `BUG-013` dismissal at pre-run boundary (`14:03` equivalent) in iOS log.
3. Re-run explicit one-tap postpone scenario for `BUG-014` and close packet if PASS.

# 🔹 Block 649 — BUG-009B/013 follow-up after user rerun (23/03/2026)

## 📋 Context

Current branch intent: `P1 bugfix packet for BUGLOG-009B / BUGLOG-013 / BUGLOG-014 device validation closure`.

User rerun at 15:07 (iOS owner) reported no behavioral change in two points:

- completion modal still stayed visible during next-group pre-run,
- chained timing in Groups Hub still showed `G3 pre-run` in the same minute as `G2 end`.

## ✔ Work completed

- Added anchored-start helper and reused it in all chain paths:
  - `lib/presentation/utils/scheduled_group_timing.dart`
  - `lib/presentation/screens/late_start_overlap_queue_screen.dart`
  - `lib/presentation/viewmodels/scheduled_group_coordinator.dart`
  - `lib/presentation/screens/timer_screen.dart`
- Enforced strict rule for notice windows: when `noticeMinutes > 0`, pre-run must start strictly after anchor end (prevents same-minute pre-run/end overlap in chained groups).
- Updated scheduled-action bridge so pre-run `openTimer` is not deferred by visible completion modal:
  - `lib/widgets/scheduled_group_auto_starter.dart`
- Synced validation docs to `fix_v4` rerun state:
  - `docs/bugs/validation_bug009_2026_03_23/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug009_2026_03_23/quick_pass_checklist.md`
  - `docs/bugs/bug_log.md`
  - `docs/validation/validation_ledger.md`

## 🧪 Verification run

- `flutter analyze` → PASS (`No issues found!`)
- `flutter test test/presentation/utils/scheduled_group_timing_test.dart` → PASS (`+7`)
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` → PASS (`+21`)
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` → PASS (`+19`)

## 🎯 Next steps

1. Run `fix_v4` iOS + Chrome device validation from updated plan commands.
2. Confirm in logs:
   - no modal persistence at pre-run boundary,
   - chained pre-run minute no longer equals previous group end minute,
   - no regression in single-queue late-start behavior.
3. If PASS, close `BUGLOG-009B`, `BUGLOG-013`, `BUGLOG-014` together with commit hash and evidence links.

# 🔹 Block 650 — BUGLOG-009B / BUGLOG-013 / BUGLOG-014 closure after fix_v4 rerun (23/03/2026)

## 📋 Context

Current branch intent: `P1 bugfix validation closure for BUGLOG-009B / BUGLOG-013 / BUGLOG-014`.

User completed the fix_v4 rerun and confirmed:

- chained timing is coherent (`G3` pre-run no longer matches `G2` end minute),
- completion modal now dismisses during next-group pre-run,
- validated flow remains stable after overlap confirmation.

## ✔ Work completed

- Closed validation packet in:
  - `docs/bugs/validation_bug009_2026_03_23/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug009_2026_03_23/quick_pass_checklist.md`
- Closed bug entries in:
  - `docs/bugs/bug_log.md` (`BUGLOG-009B`, `BUG-013`, `BUG-014`)
- Closed ledger entries in:
  - `docs/validation/validation_ledger.md`
  - updated active non-closed bug snapshot count from 17 to 14.

## 🧪 Verification run

Log evidence reviewed from fix_v4 packet:

- `docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_fix_v4_76ee374_ios_simulator_iphone_17_pro_debug.log`
- `docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_fix_v4_76ee374_web_chrome_debug.log`

Key signatures:

- `LateStartQueue overdue=3` present (single chain queue).
- No `LateStartQueue overdue=2` in fix_v4 iOS/web logs.
- iOS: `prealert-timer-fired` for G2 at `17:00:00`, then `Auto-dismiss completion dialog: group switch` at `17:00:00`, before start timer at `17:01:00`.
- iOS: `postpone-finalized` sample keeps G3 at `17:18:00`, matching corrected chained timing behavior.
- No `Scheduling conflict` signatures after overlap resolution in fix_v4 logs.

Implementation commit referenced for closure:

- `2fdd99b` — `fix(late-start, timer): BUGLOG-009B re-queue + BUG-013 modal + BUG-014 postpone`

## 📁 Updated files

- `docs/bugs/validation_bug009_2026_03_23/plan_validacion_rapida_fix.md`
- `docs/bugs/validation_bug009_2026_03_23/quick_pass_checklist.md`
- `docs/bugs/bug_log.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Ask user for explicit final confirmation to lock closure.
2. If confirmed, create docs-only closure commit and keep branch ready for merge to `develop`.

# 🔹 Block 651 — Validation artifact hygiene after closure commit (23/03/2026)

## 📋 Context

After closing `BUGLOG-009B` / `BUGLOG-013` / `BUGLOG-014`, a malformed tracked
log path with trailing newline was detected in the validation folder.

## ✔ Work completed

- Removed malformed tracked file path from git index/history-forward commit:
  - `docs/bugs/validation_bug009_2026_03_23/logs/2026-03-23_bug009b_fix_v2_76ee374_ios_simulator_iphone_17_pro_debug.log\n`
- Added stable placeholder for folder structure compliance:
  - `docs/bugs/validation_bug009_2026_03_23/logs/.gitkeep`

## 🧪 Verification run

- `git status --short` -> clean working tree.
- Validation folder now tracks expected markdown artifacts + `.gitkeep` entries,
  while `.log` runtime files remain local artifacts (ignored by `*.log`).

## 📁 Updated files

- `docs/bugs/validation_bug009_2026_03_23/logs/.gitkeep`
- `docs/dev_log.md`

## 🎯 Next steps

1. Keep closure docs and ledger as source of truth for this packet.
2. Push branch when user confirms final closure recap.

# 🔹 Block 652 — Final closure confirmation (23/03/2026)

## 📋 Context

Closure recap delivery for `BUGLOG-009B`, `BUGLOG-013`, and `BUGLOG-014`.

## ✔ Work completed

- Marked closure confirmation as final in project history.
- No behavioral/code changes performed.

## 📁 Updated files

- `docs/dev_log.md`

## 🎯 Next steps

1. Keep branch ready for merge/push with closure packet finalized.

# 🔹 Block 653 — BUGLOG-002-R1 final documentation closure (23/03/2026)

## 📋 Context

Current branch intent: `close P1 monitor-only bug item BUGLOG-002-R1 in bug queue docs`.

`BUG-002` had already been fixed at implementation level (`7ddc1e6`), but the
ledger kept `BUGLOG-002-R1` as `Validated` pending explicit final closure after
user rerun confirmation.

## ✔ Work completed

- Synchronized closure state across queue docs:
  - `docs/bugs/bug_log.md` keeps `BUG-002` as `Closed/OK (23/03/2026)` with
    final monitor-only closure note.
  - `docs/validation/validation_ledger.md` updated:
    - `BUGLOG-002-R1` -> `[x]` `Closed/OK`
    - `closed_commit_hash` / `closed_commit_message` filled from fix commit
      `7ddc1e6`
    - active non-closed bug snapshot count updated from `14` to `13`.

## 🧪 Verification run

- Documentation consistency checks:
  - `rg -n "BUG-002|BUGLOG-002-R1" docs/bugs/bug_log.md docs/validation/validation_ledger.md`
  - `git status --short`

## 📁 Updated files

- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Commit this docs-only closure update on `fix/buglog-002-r1-closure`.
2. Continue queue execution with next open P1/P2 item in `validation_ledger.md`.

# 🔹 Block 654 — BUGLOG-008A Android validation closure (23/03/2026)

## 📋 Context

Current branch intent: `close BUGLOG-008A with Android evidence`.

`BUGLOG-008A` was marked fixed but still pending Android confirmation in the
global queue.

## ✔ Work completed

- Created required validation packet for this bug:
  - `docs/bugs/validation_bug008_2026_03_23/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug008_2026_03_23/quick_pass_checklist.md`
- Recorded Android validation evidence:
  - `docs/bugs/validation_bug008_2026_03_23/logs/2026-03-23_bug008a_4ef7f42_android_RMX3771_debug.log`
- Closed bug entry in `docs/bugs/bug_log.md`:
  - status changed from `Fixed; validation pending on Android` to `Closed/OK`.
- Closed queue item in `docs/validation/validation_ledger.md`:
  - `BUGLOG-008A` -> `Closed/OK`
  - snapshot non-closed bug count updated `13 -> 12`.

## 🧪 Verification run

Android log PASS signatures:

- `LateStartQueue overdue=3` and `Opening late-start overlap queue` on late open.
- Post-confirm transition: `scheduled=2 overdue=0` and `running-open-timer`.
- User UI verification: `Start now` on next queued group blocked by
  `Conflict with running group` (no overdue bypass).
- No `overdue=2` and no `Scheduling conflict` in this validation window.

## 📁 Updated files

- `docs/bugs/validation_bug008_2026_03_23/plan_validacion_rapida_fix.md`
- `docs/bugs/validation_bug008_2026_03_23/quick_pass_checklist.md`
- `docs/bugs/validation_bug008_2026_03_23/logs/.gitkeep`
- `docs/bugs/bug_log.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Commit docs-only closure for `BUGLOG-008A`.
2. Continue with next open P1 bug-log item.

# 🔹 Block 655 — BUG-008C registration + dual-path validation packet (23/03/2026)

## 📋 Context

Current branch intent: `register BUG-008C and prepare reproducible validation packet with logs`.

During Android startup validation (`BUG008B` log), user observed an old group
opening in ready/completed style (`15:00 + Start`) before normal flow.
Need was to register this as a formal bug and prepare exact reproduction
protocols for two plausible paths.

## ✔ Work completed

- Added new bug entry:
  - `docs/bugs/bug_log.md` → `BUG-008C` (`Open`)
  - includes evidence from startup log + Firestore fields + two repro variants.
- Added queue item:
  - `docs/validation/validation_ledger.md` → `BUGLOG-008C` (`P1`, `Pending`).
- Created dedicated validation packet:
  - `docs/bugs/validation_bug008c_2026_03_23/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug008c_2026_03_23/quick_pass_checklist.md`
  - `docs/bugs/validation_bug008c_2026_03_23/logs/.gitkeep`
  - `docs/bugs/validation_bug008c_2026_03_23/screenshots/.gitkeep`
- Validation packet includes:
  - exact repro A (stale running residue on reopen),
  - exact repro B (explicit cancellation path on reopen),
  - copy-paste run commands for Android debug/release and optional Chrome mirror,
  - quick grep signatures for bug-present vs fix-working.

## 🧪 Verification run

- Documentation synchronization checks only (no runtime/code changes).
- Branch and date verified before edits:
  - branch: `fix/buglog-008c-ready-flash-validation`
  - date: `Mon Mar 23 20:19:45 CET 2026`

## 📁 Updated files

- `docs/bugs/bug_log.md`
- `docs/validation/validation_ledger.md`
- `docs/bugs/validation_bug008c_2026_03_23/plan_validacion_rapida_fix.md`
- `docs/bugs/validation_bug008c_2026_03_23/quick_pass_checklist.md`
- `docs/bugs/validation_bug008c_2026_03_23/logs/.gitkeep`
- `docs/bugs/validation_bug008c_2026_03_23/screenshots/.gitkeep`
- `docs/dev_log.md`

## 🎯 Next steps

1. Execute Scenario A and Scenario B from the new packet and capture Android logs.
2. Mark checklist PASS/FAIL with evidence (screenshots + timestamps).
3. If reproducible, implement fix on this branch and rerun same packet for closure.

# 🔹 Block 656 — BUG-008C startup stale-ready fix implementation (23/03/2026)

## 📋 Context

Current branch intent: `implement BUG-008C startup reconciliation fix (expired running + no active session)`.

User narrowed the bug to a deterministic path:

- group remains `running` while app is closed,
- app reopens after theoretical end,
- first open shows stale `Ready` timer for historical group (`15:00 + Start`),
  instead of reconciling completion and routing away from stale Run Mode.

## ✔ Work completed

- Runtime fix in coordinator:
  - `lib/presentation/viewmodels/scheduled_group_coordinator.dart`
  - Added `openGroupsHub` scheduled action type.
  - In running-branch with `activeSession == null`, expired running groups are
    now completed immediately (`expire-running-groups-no-active-session` path).
  - If all running groups are expired in that pass, coordinator emits
    `openGroupsHub` instead of stale `openTimer`.
- Navigation handler update:
  - `lib/widgets/scheduled_group_auto_starter.dart`
  - Added handler for `openGroupsHub` action (`go('/groups')` with retry guard).
- Regression test added:
  - `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
  - New case:
    `completes expired running group without active session and routes to Groups Hub`.

## 🧪 Verification run

- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` -> PASS (`+20`).
- `flutter analyze` -> PASS (`No issues found!`).

## 📁 Updated files

- `lib/presentation/viewmodels/scheduled_group_coordinator.dart`
- `lib/widgets/scheduled_group_auto_starter.dart`
- `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
- `docs/bugs/bug_log.md` (`BUG-008C` status -> `In validation`)
- `docs/validation/validation_ledger.md` (`BUGLOG-008C` -> `In validation`)
- `docs/bugs/validation_bug008c_2026_03_23/plan_validacion_rapida_fix.md`
- `docs/dev_log.md`

## 🎯 Next steps

1. Run Android device validation packet (`Scenario A` + `Scenario B`) and capture `bug008c` logs.
2. Confirm no stale startup `Ready 15:00 + Start` appears after reopen past theoretical end.
3. If PASS, close `BUG-008C` in bug log + ledger with evidence paths and closure commit.

# 🔹 Block 657 — BUG-008C closure after Android device validation (23/03/2026)

## 📋 Context

Android debug validation run for BUG-008C (`fix/buglog-008c-ready-flash-validation`, base `d400a99`).
Scenario A executed: app reopened after scheduled group expired while running (app had been closed).

## ✔ Validation result

Fix confirmed PASS on Android owner (RMX3771, Account Mode).

Key log signals in `2026-03-23_bug008c_d400a99_android_RMX3771_debug.log`:

- `[ExpiryCheck][expire-running-groups]` (line 6747): coordinator detects expired running group.
- `[ExpiryCheck][mark-running-group-completed]` (line 6751): group marked completed on startup.
- `Active session cleared route=/groups` (line 6764): stale session cleared, navigation to Groups Hub.
- No `Timer load group=... status=completed` leading to stale Ready screen.

User screenshot sequence (6 frames) confirms final destination is Groups Hub with group completed.
No persistent `Ready 15:00 + Start` flash for historical group.

## 📝 Residual observation (not a bug — documented for tracking only)

When `activeSession != null` arrives in stream before the expiry check resolves:

1. Coordinator emits `openTimer` (session present) → brief timer screen shown (frame 5 in screenshots).
2. Session staleness check fires → session cleared → coordinator re-evaluates → emits `openGroupsHub`.
3. `Cannot use Ref after disposed` logged (lines 6775–6787) during timer screen disposal — no functional breakage.

This is a transient navigation race in the `activeSession != null` path, not the BUG-008C root cause.
Documented in `plan_validacion_rapida_fix.md` section 4 for future reference.

## 📁 Updated files

- `docs/bugs/validation_bug008c_2026_03_23/quick_pass_checklist.md` (all evidence boxes checked)
- `docs/bugs/bug_log.md` (`BUG-008C` → `Closed/OK`, evidence paths recorded)
- `docs/validation/validation_ledger.md` (`BUGLOG-008C` → `Closed/OK`)
- `docs/dev_log.md`

# 🔹 Block 658 — BUGLOG-008B closure + BUGLOG-008C hash correction (24/03/2026)

## 📋 Context

Housekeeping pass on two outstanding ledger items after user confirmed BUGLOG-008B as
validated and the BUGLOG-008C merge hash was still recorded as "pending".

## ✔ Work completed

### BUGLOG-008B — Owner becomes stale while foreground (unexpected auto-claim)

User confirmed Closed/OK. Evidence traced to:

- Commit `9916204` ("Allow owner heartbeats while awaiting session", 02/03/2026):
  root-cause fix — `lastUpdatedAt` no longer freezes when session is temporarily
  missing; owner heartbeat continues publishing independently of session stream state.
- Validation: `docs/bugs/validation_fix_2026_03_02-02/quick_pass_checklist.md`
  (all PASS, Chrome+macOS, 02/03/2026 — `lastUpdatedAt` advancing confirmed).
- Architecture-level corroboration: P0-F26-006 Stage C pass2 soak (5h+, Android
  RMX3771 + macOS, 2026-03-16) showed no unauthorized ownership flips during the
  entire soak window.

Updated:

- `docs/bugs/bug_log.md` (BUG-008 `Fix applied` + `Status` → `Closed/OK`)
- `docs/validation/validation_ledger.md` (BUGLOG-008B `[ ]` → `[x]` Closed/OK)

### BUGLOG-008C hash correction

`closed_commit_hash` was recorded as `pending (fix/buglog-008c-ready-flash-validation,
pre-merge)` because the ledger was updated before the merge completed. Updated to
actual merge commit `cfaba5e`.

Updated:

- `docs/validation/validation_ledger.md` (BUGLOG-008C `closed_commit_hash` → `cfaba5e`)

## 📁 Updated files

- `docs/bugs/bug_log.md`
- `docs/validation/validation_ledger.md`
- `docs/dev_log.md`

# 🔹 Block 659 — BUG-006 + BUG-007 validation packet (24/03/2026)

## 📋 Context

Both bugs have fixes already in `develop`. This block opens the combined device
validation to formally confirm and close them.

**BUG-006 — Status box time ranges ignore pause anchoring:**
Fix: commit `34d1938` ("Fix 5: align status box ranges") added
`currentPhaseStartFromGroup` / `currentPhaseEndFromGroup` with
`_pauseSecondsSincePhaseStart` to `pomodoro_view_model.dart`. Used by
`timer_screen.dart` lines 2689–2690.

**BUG-007 — Owner resumes behind mirror after background crash:**
Fix: `handleAppResumed` (line 2871) in Account Mode calls
`syncWithRemoteSession(preferServer: true, reason: 'resume')` +
`_subscribeToRemoteSession(reason: 'resume-rebind')` +
`_schedulePostResumeResync()` (2s delayed). Also covered by RVP-067 (Closed/OK).

## ✔ Work completed

- Created branch `fix/buglog-006-007-validation`.
- Created `docs/bugs/validation_bug006_bug007_2026_03_24/`:
  - `plan_validacion_rapida_fix.md`
  - `quick_pass_checklist.md`
  - `logs/`, `screenshots/`
- Updated ledger: BUGLOG-006, BUGLOG-007 → `In validation`.

## 🎯 Next steps

1. Run Android (RMX3771) + macOS debug commands from the plan.
2. Escenario A (BUG-006): pause 60s, resume, confirm status boxes.
3. Escenario B (BUG-007): background Android 90s+, confirm timer aligns con macOS.
4. Save logs with naming convention; update plan + checklist with results.
5. If both PASS: close BUGLOG-006 + BUGLOG-007 and merge to `develop`.

# 🔹 Block 660 — BUG-006 + BUG-007 closure after Android device validation (24/03/2026)

## 📋 Context

Combined Android + macOS validation run for BUG-006 and BUG-007.
Branch: `fix/buglog-006-007-validation`, base commit `97f6365`.

## ✔ Validation result — both PASS

### BUG-006 — Status box time ranges PASS

- Paused at 11:02:01 (log line 6983): `status=paused remaining=861 phaseStartedAt=11:01:20.522`
- Resumed at 11:03:04 (log line 7029): `status=pomodoroRunning remaining=861`
- Status box: 11:01–11:16 → 11:01–11:17. Start fixed ✓, end extended by pause duration ✓.
- Status box and task list both show 11:01–11:17 ✓.

### BUG-007 — Owner resume re-anchor PASS

- Background Android 11:09:00, foreground 11:11:02 (~2min background).
- Timer: Android 6:21, macOS 6:20 → ±1s ✓. No Groups Hub navigation needed.
- Log lines 10400–10414:
  `[SessionSub] close reason=resume-rebind` →
  `[SessionSub] open (→SSS) reason=resume-rebind` →
  `[ActiveSession] Resync start (resume).` →
  `[ActiveSession] Resync start (post-resume).`
- No `Resync missing` after foreground return ✓.

### Local gate PASS

- `flutter analyze` → `No issues found!`
- `flutter test pomodoro_view_model_pause_expiry_test.dart` → `+5: All tests passed!`

## 📁 Updated files

- `docs/bugs/validation_bug006_bug007_2026_03_24/plan_validacion_rapida_fix.md` (results added)
- `docs/bugs/validation_bug006_bug007_2026_03_24/quick_pass_checklist.md` (all boxes checked)
- `docs/bugs/bug_log.md` (BUG-006, BUG-007 → Closed/OK)
- `docs/validation/validation_ledger.md` (BUGLOG-006, BUGLOG-007 → Closed/OK)
- `docs/dev_log.md`

# 🔹 Block 661 — BUG-005 validation packet (24/03/2026)

## 📋 Context

BUG-005: ownership requests not surfaced until focus/resubscribe.
Two variants:

- **Variant A** (macOS window inactive): request never showed until user clicked macOS window.
- **Variant B/D/E** (Android foreground owner): request never showed until Groups Hub nav.

Both have fixes already in `develop`.

**Variant A fix:** `handleAppPaused()` triggers `_startInactiveResync()` on
`AppLifecycleState.inactive` (macOS focus loss included). Timer fires
`syncWithRemoteSession(preferServer: true, reason: 'inactive-resync')` every **15s**,
fetching the session with `ownershipRequest` from Firestore.
macOS: `_keepClockActiveOutOfFocus()` returns `true` (clock keeps running) but
`handleAppPaused()` IS called → inactive-resync starts correctly.

**Variant B fix:** Fix 26 architecture rewrite (`cbd800a`) — `SessionSyncService`
maintains persistent session subscription, eliminating AP-1 subscription gaps.
Any Firestore write to `ownershipRequest` arrives via stream in real time.

## ✔ Work completed

- Created branch `fix/buglog-005-validation`.
- Created `docs/bugs/validation_bug005_2026_03_24/`:
  - `plan_validacion_rapida_fix.md` (Escenarios A + B, commands, log scan, criteria)
  - `quick_pass_checklist.md`
  - `logs/`, `screenshots/`
- Updated ledger: BUGLOG-005 → `In validation`.

## 🎯 Next steps

1. Run Android (RMX3771) + macOS debug commands from the plan simultaneously.
2. Escenario A: macOS as owner, lose focus, Android requests → modal in ≤15s.
3. Escenario B: Android as owner foreground, macOS requests → modal in <5s.
4. Check log signals and update plan + checklist.
5. If both PASS: close BUGLOG-005 and merge to `develop`.

---

## Block 662 — BUG-005 closed: ownership request surfaced without focus/resubscribe (24/03/2026)

**Branch:** `fix/buglog-005-validation`
**Closed bugs:** BUG-005 (BUGLOG-005)
**Validation folder:** `docs/bugs/validation_bug005_2026_03_24/`
**Devices:** Android RMX3771 + macOS (same session)

### What was validated

Two variants of BUG-005 confirmed PASS in a single combined run.

**Escenario A — macOS owner loses window focus (Variant A)**

macOS lost focus at 11:43:50. Log macOS line 5850:

```
[ActiveSession] Resync start (inactive-resync).  (11:43:54, ~4s after focus loss)
```

Subsequent `inactive-resync` calls confirmed at lines 5859, 5864 (~15s intervals).
Android requested ownership at 11:46:07 — macOS showed the modal instantaneously
without any click or focus. ≤15s threshold met ✓.

**Escenario B — Android owner foreground, macOS mirror requests (Variant B)**

Android as owner (foreground), macOS requested ownership at 11:49:29.
Android log shows `[RunModeDiag] Active session change` via stream at ~11:49:28.5
(no `inactive-resync` — pure stream delivery ✓). `D/ViewRootImplExtImpl` tap event
at ~11:49:30.8 confirms user accepted the modal on Android. Ownership snapshot with
`owner=macOS-828508db... lastUpdatedAt=2026-03-24 11:49:31.248` confirms transfer.
Elapsed request-to-accept: ~3s (<5s threshold ✓). No Groups Hub navigation ✓.

**Local gate**

- `flutter analyze` → `No issues found!`
- `flutter test pomodoro_view_model_session_gap_test.dart` → `+25: All tests passed!`

### Fix commits

- Variant A: `b093270` — `_startInactiveResync()` periodic 15s resync on macOS inactive
- Variant B: `cbd800a` — Fix 26 SSS persistent subscription (AP-1 eliminated)

### Documents updated

- `docs/bugs/bug_log.md` → BUG-005 Status: Closed/OK
- `docs/validation/validation_ledger.md` → BUGLOG-005: `[ ]` → `[x]` Closed/OK (`b093270`)
- `docs/bugs/validation_bug005_2026_03_24/plan_validacion_rapida_fix.md` → results + Closed/OK
- `docs/bugs/validation_bug005_2026_03_24/quick_pass_checklist.md` → all boxes checked

### Ledger status after this block

**All P1 bugs now Closed/OK.** Zero open P0/P1 entries in `validation_ledger.md`.
Remaining open items: P2 bugs (BUGLOG-003, BUGLOG-010, BUGLOG-008-MIT, BUGLOG-F25-E-R1)
and RVP validation items (RVP-021–RVP-062). Neither category blocks `develop → main`.

---

## Block 663 — RVP-032/033/041/043/044 closed: batch closure using existing validation evidence (24/03/2026)

**Branch:** `fix/rvp-batch-close-032-033-041-043-044`
**Merge commit:** `5b94dca`
**Items closed:** 5 RVP validation items (P2)

No new code. All 5 items were implemented months ago; this block records their formal
closure using evidence already captured in prior validation runs.

### Items closed

**RVP-032** — Ownership publish guard + no stale owner flips
Evidence: BUG-F26-001 re-val 18/03/2026 (commit `92731b3`): `phaseStartedAt` updated on
phase transitions, `sessionRevision` coherent. Fix 26 Stage C soak (5h+, 16/03/2026):
no unauthorized owner flips. BUGLOG-008B Closed/OK (`9916204`): owner stable in foreground.

**RVP-033** — Desktop inactive resync keepalive
Evidence: BUG-005 Escenario A PASS (24/03/2026): macOS log line 5850
`[ActiveSession] Resync start (inactive-resync).` at ~4s after focus loss; ownership
request modal appeared on macOS without any click.

**RVP-041** — Ownership requests re-sync on resume
Evidence: BUG-007 PASS (24/03/2026): Android log lines 10400–10414 confirm
`resume-rebind` + `Resync start (resume)` + `Resync start (post-resume)`.

**RVP-043** — Ownership request banner dismisses immediately on reject
Evidence: BUG-002 re-val 18/03/2026 (commit `92731b3`): banner cleared immediately
on rejection without second press.

**RVP-044** — Ownership reject dismiss stable vs transient stream gaps
Evidence: Fix 26 SSS architecture (AP-2 debounce + 3s hold) + Stage C soak (5h+):
no spurious banner re-appearance across stream reconnects.

### Documents updated

- `docs/validation/validation_ledger.md` → RVP-032/033/041/043/044: `[ ]` → `[x]` Closed/OK

### Ledger status after this block

Open P2 bugs: BUGLOG-003, BUGLOG-010, BUGLOG-008-MIT, BUGLOG-F25-E-R1
Open RVP items: RVP-021–RVP-031, RVP-034–RVP-040, RVP-042, RVP-045–RVP-062 (37 items)

## Block 664 — BUGLOG-008-MIT closed: superseded by Fix 26 SSS architecture (24/03/2026)

**Branch:** `fix/buglog-008-mit-closure`
**Item closed:** BUGLOG-008-MIT (P2 mitigation candidate)

No new code. The Run Mode resync overlay mitigation candidate was designed as a manual
fallback for sync failures (Syncing session... freezes) that required navigating to
Groups Hub to recover. Fix 26's SSS persistent subscription (AP-1 eliminated) +
`_startInactiveResync()` + `handleAppResumed()` re-anchor remove all the sync failure
scenarios this fallback was meant to address.

User confirmed 24/03/2026: "gracias al refacto originado por el fix 26 se hizo innecesario."

### Documents updated

- `docs/bugs/bug_log.md` → BUGLOG-008-MIT Status: `Not implemented...` → `Closed/OK (24/03/2026)`
- `docs/validation/validation_ledger.md` → BUGLOG-008-MIT: `[ ]` → `[x]` Closed/OK (`cbd800a`)
- Snapshot updated: non-closed bugs 4 → 3 (BUG-003, BUG-010, BUG-F25-E remain open)

### Ledger status after this block

Open P2 bugs: BUGLOG-003, BUGLOG-010, BUGLOG-F25-E-R1
Open RVP items: RVP-021–RVP-031, RVP-034–RVP-040, RVP-042, RVP-045–RVP-062 (37 items)

## Block 665 — BUGLOG-F25-E-R1 closed: merge artifact, fix already in c248c91 (24/03/2026)

**Branch:** `develop` (direct, doc-only correction)
**Item closed:** BUGLOG-F25-E-R1 (P2 stale entry)

BUG-F25-E was fixed in `c248c91` (19/03/2026) and confirmed in the roadmap (line 459,
struck through Closed/OK, Chrome validation PASS). The `bug_log.md` entry at line 1489
still said "Status: Open / Fix applied: None yet" — this was a merge artifact: when
`fix-f25-h-cancel-syncing-hold` merged into develop (`fdd4cfa`), it added 144 lines
including a re-instantiated copy of the BUG-F25-E section from before `c248c91` patched
it. The fix in the code was unaffected (groups_hub_screen.dart:1414-1422 and
task_list_screen.dart:1850+ both show the dynamic group list dialog). BUGLOG-F25-E-R1
in the ledger was created to track this discrepancy.

Corrected `bug_log.md` and ledger entry to reflect actual Closed/OK state.

### Documents updated

- `docs/bugs/bug_log.md` → BUG-F25-E Status: `Open` → `Closed/OK (19/03/2026). closed_commit_hash: c248c91`
- `docs/validation/validation_ledger.md` → BUGLOG-F25-E-R1: `[ ]` → `[x]` Closed/OK (`c248c91`)
- Snapshot updated: non-closed bugs 1 → 0 (zero P0/P1/P2 open)

### Ledger status after this block

**Zero open bugs.** All BUGLOG entries closed.
Open RVP items: RVP-021–RVP-031, RVP-034–RVP-040, RVP-042, RVP-045–RVP-062 (37 items)

## Block 667 — BUG-015 Claude QA review + handoff preparado (25/03/2026)

**Branch:** `fix/buglog-running-without-foreground-ready-invalid`
**Ref commit:** `f929117`
**Context:** Codex abrió el bug y hizo docs-first. Claude revisó el código para validar
la causa raíz y dar luz verde al fix.

### Análisis de causa raíz confirmado

**Vector A (primario):** `_hydrateOwnerSession` (~línea 2091 pomodoro_view_model.dart).

- Cuando Android toma ownership de sesión stale (macOS apagado), máquina en `idle` (mirror mode).
- `_projectStateFromSession` proyecta SOLO dentro de la tarea actual.
- Si elapsed > duración total de la tarea, devuelve `PomodoroStatus.finished`.
- Se aplica y publica → Firestore `current.status = finished` → UI "Ready" + ámbar.
- `_applyGroupTimelineProjection` (que sí conoce todas las tareas) estaba bloqueada en Account mode.

**Vector B (secundario):** `_applySessionTimelineProjection` owner branch (~línea 1626).

- Un sync concurrente durante `await _resolveServerNow()` en `_handleTaskFinishedInternal`
  puede publicar el estado `finished` transitorio de la máquina (entre tareas).

### Fix design (2 commits)

**Fix A:** En `_hydrateOwnerSession`, ampliar `allowTimelineProjection`:

```dart
// antes:
final allowTimelineProjection = ref.read(appModeProvider) != AppMode.account;
// después:
final allowTimelineProjection =
    ref.read(appModeProvider) != AppMode.account ||
    (projected.status == PomodoroStatus.finished && !_groupCompleted);
```

**Fix B:** En `_applySessionTimelineProjection`, guard antes del publish:

```dart
if (_machine.state.status == PomodoroStatus.finished && !_groupCompleted) {
  return;
}
```

### ✔ Documentación creada en este bloque

- `docs/bugs/validation_bug015_2026_03_25/codex_handoff.md`
- `docs/bugs/validation_bug015_2026_03_25/plan_validacion_rapida_fix.md`
- `docs/bugs/validation_bug015_2026_03_25/quick_pass_checklist.md`
- `docs/bugs/validation_bug015_2026_03_25/logs/` (vacío, pendiente device run)
- `docs/bugs/validation_bug015_2026_03_25/screenshots/` (vacío)

### ⚠️ Siguiente paso

Entregar `codex_handoff.md` a Codex para implementación. Codex entrega diff.
Claude hace QA review del código modificado. Luego device validation.

## Block 668 — BUG-015 closure synced after device validation PASS (25/03/2026)

**Current branch intent:** BUG-015 bugfix validation closure + evidence synchronization.
**Branch:** `fix/buglog-running-without-foreground-ready-invalid`
**Scope:** docs closure + ledger synchronization after successful device run

### Validation recap (BUGLOG-015)

- Device validation PASS on Android RMX3771 + macOS.
- Exact repro passed with owner handoff + background + late foreground resume.
- No invalid terminal fallback (`Ready 00:00`, amber complete ring) during resumed run.
- Firestore session remained non-terminal (`status=pomodoroRunning`) during active timeline.

Evidence:

- `docs/bugs/validation_bug015_2026_03_25/logs/2026-03-25_bug015_f929117_android_RMX3771_debug_2.log`
- Key signals in log:
  - `Auto-open confirmed in timer` (resume path).
  - `status=pomodoroRunning ... remaining=460`, then `429`, then `399` (continuous active progression).

### Local gate (post-fix)

- `flutter analyze` — PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` — PASS
- `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` — PASS
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` — PASS
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` — PASS

### Documents synchronized

- `docs/bugs/bug_log.md` — BUG-015 status updated to `Closed/OK` with validation evidence.
- `docs/validation/validation_ledger.md` — `BUGLOG-015` moved to `Closed/OK` with closure evidence.
- `docs/bugs/validation_bug015_2026_03_25/plan_validacion_rapida_fix.md` — status updated to `Closed/OK`, root cause/fix path aligned with final implementation.
- `docs/bugs/validation_bug015_2026_03_25/quick_pass_checklist.md` — closure checklist completed.

### Ledger status after this block

- Active non-closed bug-log entries: 1 (`BUG-016` / `BUGLOG-016`, P2 Pending).

---

## Block 669 — BUG-015 commit hash corrected + BUG-017 registered (25/03/2026)

**Branch:** `fix/buglog-running-without-foreground-ready-invalid`

### BUG-015 commit hash correction

Codex's closure commit `e10a5028` was written to bug_log.md and validation_ledger.md
with placeholder text (`not-committed-yet`) because the docs were authored before the
commit was executed. Corrected in-place:

- `docs/bugs/bug_log.md` — BUG-015 Status line now references `e10a5028`
  (`fix(bug-015): repair stream cursor ingest and close validation`).
- `docs/validation/validation_ledger.md` — BUGLOG-015 `closed_commit_hash` and
  `closed_commit_message` updated from `not-committed-yet` to the actual values.

### BUG-017 registered — Edit Task preset "Custom" UX bug

New bug discovered during a UX review of the Edit Task screen (25/03/2026).

**Symptom (user perspective):** Opening the preset dropdown in Edit Task shows "Custom"
as a selectable option alongside real saved presets. Tapping it selects it — but "Custom"
is not a real preset; it is a derived label representing the unlinked state.

**Root cause (hypothesis):** The dropdown widget includes a synthetic "Custom" entry to
represent the unlinked state visually, rather than expressing that state via a separate
indicator outside the picker.

**Expected behavior:**

- Dropdown contains ONLY real presets from Settings.
- "Custom" is removed from the list entirely.
- Linked/unlinked state communicated by a visual indicator next to the "Preset" field
  label: active (bright/colored) when config matches selected preset; inactive (dim/grey)
  when config has diverged or no preset is selected.

**Documents updated:**

- `docs/bugs/bug_log.md` — BUG-017 entry added (Status: Open, P2).
- `docs/validation/validation_ledger.md` — BUGLOG-017 added (P2, Status: Pending).

### Ledger status after this block

- Active non-closed bug-log entries: 2 (`BUG-016` P2 Pending, `BUG-017` P2 Pending).
- Zero open P0/P1 bugs.

---

## Block 670 — Ledger snapshot count sync after BUG-017 registration (25/03/2026)

**Current branch intent:** Documentation consistency fix (validation ledger snapshot alignment).
**Branch:** `fix/ledger-snapshot-bug017-count`

### Issue found

After adding `BUG-017` and `BUGLOG-017`, the 25/03/2026 snapshot line in
`docs/validation/validation_ledger.md` still reported only one active non-closed
bug (`BUG-016`), which no longer matched the ledger queue.

### Correction applied

- `docs/validation/validation_ledger.md` snapshot updated:
  - from: `**1** (BUG-016 / BUGLOG-016)`
  - to: `**2** (BUG-016 / BUGLOG-016, BUG-017 / BUGLOG-017)`

### Result

- Snapshot summary now matches the active non-closed bug queue in the same file
  (`BUGLOG-016`, `BUGLOG-017` both `Pending`).
- Zero open P0/P1 bugs remains unchanged.

---

## Block 671 — BUG-016 docs-first plan locked: preview flow + explicit fixed/flexible modes (27/03/2026)

**Current branch intent:** BUG-016 documentation planning with explicit two-mode task-weight editing.
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** Docs-first only (no runtime code changes in this block).

### Decision locked

- BUG-016 now has an explicit product direction approved on 27/03/2026:
  preview-first editing with two calculation modes.
- Mode 1: **Fixed total** (default) — keeps selected-group total work constant
  and redistributes other selected tasks proportionally.
- Mode 2: **Flexible total** — keeps other selected tasks unchanged and allows
  selected-group total work to change.
- The same preview logic is required for both **Task weight (%)** and
  **Total pomodoros** edits, with explicit **Apply** and **Cancel**.

### Documents synchronized

- `docs/specs.md`
  - Added explicit preview-first editing contract.
  - Added explicit two-mode behavior (`Fixed total` / `Flexible total`).
  - Clarified that Total pomodoros edits reuse the same preview and mode selector.
- `docs/bugs/bug_log.md`
  - Updated BUG-016 from “product decision pending” to “product decision approved”.
  - Replaced option list with approved implementation direction and planned file scope.
- `docs/validation/validation_ledger.md`
  - Updated BUGLOG-016 item text to reflect locked two-mode direction and baseline-freeze requirement.
  - Synced active bug-log queue header date to 27/03/2026.
- `docs/roadmap.md`
  - Added Phase 10 reopened item for BUG-016 follow-up (preview-first editor + explicit two modes).

### Ledger status after this block

- Active non-closed bug-log entries remain: 2 (`BUG-016`, `BUG-017`; both P2 Pending).
- Zero open P0/P1 bugs remains unchanged.

---

## Block 672 — BUG-016 baseline validation packet documented (FAIL) with full evidence set (27/03/2026)

**Current branch intent:** BUG-016 docs-first validation evidence and root-cause tracing.
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** Validation documentation only (no runtime fix in this block).

### What was added

- Created mandatory validation artifacts for BUG-016:
  - `docs/bugs/validation_bug016_2026_03_27/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug016_2026_03_27/quick_pass_checklist.md`
- Preserved run log evidence:
  - `docs/bugs/validation_bug016_2026_03_27/logs/2026-03-27_bug016_fa907c9_macos_debug.log`
- Imported and normalized screenshot evidence names:
  - `docs/bugs/validation_bug016_2026_03_27/screenshots/2026-03-27_bug016_01_macos.png`
  - …
  - `docs/bugs/validation_bug016_2026_03_27/screenshots/2026-03-27_bug016_13_macos.png`

### Validation findings recorded

- Repeatable blur overwrite in editor:
  - `69 -> 43`, `50 -> 36`, `45 -> 35`.
- Save-time inconsistency between editor blur-state and Task List outcome.
- Selected-group total pomodoros collapse captured in evidence sequence:
  - initial selected total: `11` (`5+4+1+1`)
  - final selected total: `6` (`3+1+1+1`)

### Root-cause trace documented

- Per-keystroke baseline mutation in weight `onChanged` path.
- Blur-time percent resync recomputes from partial state before full redistribution apply.
- Pending redistribution map is applied on Save after intermediate-state contamination.

### Document synchronization

- `docs/bugs/bug_log.md` (BUG-016): added 27/03 validation FAIL update with evidence refs.
- `docs/validation/validation_ledger.md`:
  - BUGLOG-016 moved `Pending -> In validation`.
  - Item text extended with FAIL summary and evidence references.
  - 27/03 snapshot wording updated (`BUG-016` now In validation P2).

### Ledger status after this block

- Active non-closed bug-log entries: 2 (`BUG-016` In validation P2, `BUG-017` Open P2).
- Zero open P0/P1 bugs remains unchanged.

---

## Block 673 — BUG-016 Patch 1 implementation + validation closure (28/03/2026)

**Current branch intent:** BUG-016 correctness fix closure (baseline freeze + blur/save sync) and documentation synchronization.
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** Runtime patch + closure docs (Patch 1 only; Patch 2 UX remains pending).

### Runtime fix delivered

- Implemented Patch 1 on `lib/presentation/screens/task_editor_screen.dart`.
- Commit: `8bad479` — `fix(bug016): stabilize task-weight baseline and save-flow percent sync`.
- Core changes:
  - Freeze selected weight baseline at weight-field focus gain.
  - Prevent mixed-state overwrite in blur/save sync by prioritizing pending redistribution/last computed result.
  - Keep save-confirmation modal flow deterministic (no `%` snap-back during modal).

### Validation closure (owner-run + local gate)

- Owner manual validation packet (28/03/2026) PASS:
  - `80% -> 69%` closest result stays stable through blur/save/list/reopen.
  - `50%` path remains coherent through blur + save-warning modal + list + reopen (no `36%` regression).
  - `1%` path shows `No change possible` and persists coherent values.
  - Task list values match editor values after save (deterministic persistence).
- Local gate PASS:
  - `flutter analyze`
  - `flutter test test/domain/task_weighting_test.dart`
  - `flutter test test/presentation/viewmodels/task_editor_view_model_test.dart`

### Documents synchronized

- `docs/bugs/bug_log.md`:
  - BUG-016 status moved to `Closed/OK` for Patch 1.
  - Added 28/03 PASS validation update and closure evidence.
- `docs/bugs/validation_bug016_2026_03_27/plan_validacion_rapida_fix.md`:
  - Local verification marked PASS; status moved to `Closed/OK (Patch 1)`.
- `docs/bugs/validation_bug016_2026_03_27/quick_pass_checklist.md`:
  - Closure checklist completed (all required boxes checked).
- `docs/validation/validation_ledger.md`:
  - `BUGLOG-016` moved to `Closed/OK` with commit + evidence.
  - Active non-closed bug count snapshot updated.
- `docs/roadmap.md`:
  - Phase 10 BUG-016 line updated: Patch 1 Closed/OK; Patch 2 remains blocked on UX decisions (a–i).

### Ledger status after this block

- Active non-closed bug-log entries: 1 (`BUG-017` Open P2).
- `BUGLOG-016` is now `Closed/OK` (Patch 1).
- Phase 10 Patch 2 (preview UX) remains pending as roadmap follow-up, not a reopened correctness defect.

---

## Block 674 — BUG-016 Patch 2 UX decisions closed (28/03/2026)

**Current branch intent:** BUG-016 Patch 2 UX design lock — documentation only.
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** Design decisions only (no runtime changes in this block).

### Context

Following Patch 1 closure (Block 673), a design session between the user and Codex
produced a complete and unambiguous specification for the Patch 2 preview sheet UX.
Claude reviewed the full design, confirmed it is implementable without further ambiguity,
and flagged one architectural detail not previously explicit: the editor fields
become read-only tap targets in Patch 2 (not inline-editable), which supersedes
the per-keystroke handlers introduced in Patch 1.

### Decisions locked (a–p)

All 9 original UX questions (a–i) plus 7 additional micro-clarifications (j–p):

- a. Mode selector: segmented control (Fixed total | Flexible total) inside sheet.
- b. Preview content: three-tier (result line + group impact + mini-table of all selected tasks).
- c. Apply/Cancel: fixed footer, Cancel left / Apply right.
- d. Preview trigger: tapping field opens sheet; live recalculation inside sheet.
  Fields in editor are read-only tap targets — per-keystroke onChanged removed in Patch 2.
- e. Mode switch: recalculates immediately, does not reset entered value.
- f. Snackbar: eliminated; replaced by inline content inside sheet.
- g. Visual form: three-tier layout (result + group impact + mini-table).
- h. Cancel: restores pre-open snapshot; no DB write.
- i. Scope: same sheet and selector for both Task weight (%) and Total pomodoros.
- j. Flexible total: only edited task changes; all other selected tasks unchanged.
- k. Search range (Flexible, % path): candidates 1..max(pom×3, pom+12), cap 99 (algorithmic only).
- l. Tiebreaker: (1) smallest % deviation, (2) smallest group total change,
  (3) smallest edited task change, (4) smaller resulting group total.
- m. Apply/Save/Discard: Apply = local draft + dirty; Save = persist; Discard = reverts all draft.
- n. 1 task selected: field disabled at 100%, no sheet, optional helper text.
- o. Selection change with sheet open: close without apply + non-modal notice.
- p. New ViewModel method: `redistributeTotalPomodoros` required for Total pomodoros path.

### Documents synchronized

- `docs/bugs/bug_log.md`: pending questions (a–i) replaced with closed decisions (a–p).
  Patch 2 status updated from "blocked" to "implementation ready."
- `docs/specs.md`: "UI implications" section expanded with full preview sheet specification
  and ViewModel requirements for Patch 2.
- `docs/roadmap.md`: Phase 10 BUG-016 Patch 2 line updated from "blocked 9 decisions" to
  "all decisions closed, implementation ready."

### Ledger status after this block

- Active non-closed bug-log entries: 1 (`BUG-017` Open P2) — unchanged.
- BUG-016 Patch 2 is a roadmap follow-up, not an open bug.

---

## Block 675 — BUG-016 Patch 2 implementation landed (preview sheet + fixed/flexible modes) (28/03/2026)

**Current branch intent:** BUG-016 Patch 2 runtime implementation (preview-first editing UX).
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** Runtime implementation + local gate (no device packet yet).

### Implemented scope

- Added `WeightEditMode` (`fixed` / `flexible`) in Task Editor ViewModel.
- Extended `redistributeWeightPercent(...)` with mode-aware behavior.
- Added `redistributeTotalPomodoros(...)` for the total-pomodoros preview path.
- Added flexible-mode search with deterministic tiebreaking and algorithmic cap rule
  `min(99, max(currentPom * 3, currentPom + 12))`.
- Added new preview sheet UI (`task_weight_preview_sheet.dart`) with:
  - input + live recalculation (inside sheet),
  - segmented selector Fixed/Flexible for multi-task scope,
  - requested/closest/result summary,
  - before/after group impact,
  - affected-tasks mini-list,
  - fixed footer `Cancel` / `Apply`.
- Refactored Task Editor weight row:
  - `Task weight (%)` and `Total pomodoros` are now read-only tap targets.
  - `Total pomodoros` stays enabled regardless of weight-field visibility.
  - single-task scope rule applied: weight field disabled at `100%`, no sheet.
- Added selection-change invalidation while sheet is open:
  - close sheet without apply,
  - show non-modal notice: `Group selection changed. Reopen to recalculate.`

### Files changed

- `lib/presentation/viewmodels/task_editor_view_model.dart`
- `lib/presentation/screens/task_editor_screen.dart`
- `lib/presentation/screens/task_weight_preview_sheet.dart` (new)
- `test/presentation/viewmodels/task_editor_view_model_test.dart`
- `docs/roadmap.md`

### Local gate

- PASS — `flutter analyze`
- PASS — `flutter test test/presentation/viewmodels/task_editor_view_model_test.dart`
- PASS — `flutter test test/domain/task_weighting_test.dart`

### Status after this block

- Patch 2 implementation is in branch and locally validated.
- Device validation packet for Patch 2 remains pending before closure.

---

## Block 676 — BUG-016 Patch 2 UX clarity refinement: fullscreen preview + Back=Cancel (28/03/2026)

**Current branch intent:** BUG-016 Patch 2 runtime/UI refinement (context clarity).
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** Runtime UX adjustment + docs alignment.

### Context

User validation feedback confirmed contextual confusion because preview was rendered
as a partial-height sheet, leaving `Edit task` AppBar content (`Save`) visible behind.
This could lead to accidental mixed-context interactions and unclear navigation outcomes.

### Changes applied

- Preview surface updated to full-screen opaque rendering (no underlying editor
  elements visible during preview).
- Added top-left `Back` action inside preview with the exact same semantics as
  `Cancel` (close without apply).
- Existing footer actions remain unchanged (`Cancel` / `Apply`).

### Runtime evidence

- Commit: `bfcfa14` — `fix(bug016): make preview sheet fullscreen and add back action`
- Local gate PASS after change:
  - `flutter analyze`

### Docs synchronized

- `docs/specs.md`:
  - Added explicit full-screen opaque preview-surface requirement.
  - Added explicit `Back` action semantics equal to `Cancel`.

### Status after this block

- Patch 2 keeps local gate PASS.
- Device validation packet still pending before final Patch 2 closure.

---

## Block 678 — BUG-016 Patch 2 UX clarity refinement: compact status semantics + interaction-aware warning gating (28/03/2026)

**Current branch intent:** BUG-016 Patch 2 runtime/UI refinement (status clarity and redundancy reduction).
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** Runtime UX adjustment + docs alignment.

### Context

User feedback identified two clarity issues in preview:

- `Fixed total` explanation remained ambiguous about what total is preserved.
- Orange warning text appeared immediately on open (and could feel incorrect) even
  before a meaningful user change.
  Additionally, the top summary repeated data already visible elsewhere.

### Changes applied

- Reworded `Fixed total` explanation to explicitly state:
  - selected-group total (pomodoros + work minutes) is preserved,
  - closest achievable outcome is applied,
  - other selected tasks are redistributed proportionally.
- Removed redundant top summary lines:
  - removed `Requested`,
  - removed gray `Closest achievable`,
  - removed `Result`.
- Added compact status semantics:
  - **green** success line for exact result,
  - **orange** warning line only when needed.
- Warning gating is now interaction-aware:
  - no orange warning on first open,
  - no orange warning when user returns to opening snapshot
    (initial value in default mode),
  - orange warning shown only after interaction when exactness is not possible or
    when no change can be applied.

### Runtime evidence

- Commit: `37af472` — `fix(bug016): simplify preview status and suppress non-actionable warnings`
- Local gate PASS after change:
  - `flutter analyze`

### Docs synchronized

- `docs/specs.md`:
  - clarified Fixed-mode explanation with preserved totals + closest-achievable semantics.
  - defined compact status behavior and interaction-aware warning gating.
- `docs/roadmap.md`:
  - updated Phase 10 BUG-016 Patch 2 key decisions with compact status semantics.

### Status after this block

- Patch 2 keeps local gate PASS.
- Device validation packet still pending before final Patch 2 closure.

---

## Block 677 — BUG-016 Patch 2 UX clarity refinement: inline business-rule explanation per mode (28/03/2026)

**Current branch intent:** BUG-016 Patch 2 runtime/UI refinement (mode comprehension).
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** Runtime UX adjustment + docs alignment.

### Context

User feedback: with only `Fixed total` / `Flexible total` labels, users have to
guess expected behavior by trial-and-error because business rules are not explicit
inside the preview flow.

### Changes applied

- Added inline explanation block directly below the segmented selector in preview.
- Explanation updates dynamically with the selected mode:
  - **Fixed total:** selected-group total stays constant; other selected tasks are
    redistributed proportionally.
  - **Flexible total:** other selected tasks stay unchanged; only edited task changes,
    so selected-group total may change.

### Runtime evidence

- Commit: `7699ba4` — `fix(bug016): explain fixed vs flexible business rules in preview`
- Local gate PASS after change:
  - `flutter analyze`

### Docs synchronized

- `docs/specs.md`:
  - Added mandatory inline mode explanation requirement under preview-sheet spec.
- `docs/roadmap.md`:
  - Updated Phase 10 BUG-016 Patch 2 key decisions with inline mode explanation.

### Status after this block

- Patch 2 keeps local gate PASS.
- Device validation packet still pending before final Patch 2 closure.

---

## Block 679 — BUG-016 Patch 2 algorithm refinement: Flexible % search without hard cap (28/03/2026)

**Current branch intent:** BUG-016 Patch 2 runtime algorithm correctness refinement.
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** ViewModel redistribution logic + tests.

### Context

User validation exposed a correctness gap in Flexible `%`: high requested percentages
could collapse to low outcomes because the historical candidate cap prevented
mathematically reachable results.

### Changes applied

- Removed the artificial Flexible `%` candidate cap from `TaskEditorViewModel`.
- Reworked flexible search to evaluate achievable displayed percentages with
  deterministic selection (same tiebreak policy).
- Updated/extended redistribution tests:
  - preserved fixed-mode parity check,
  - added regression for growth beyond historical cap,
  - updated exact-reachable flexible expectation.

### Runtime evidence

- Commit: `e51de5f` — `fix(bug016): remove flexible percent cap and update redistribution tests`
- Local gate PASS:
  - `flutter test test/presentation/viewmodels/task_editor_view_model_test.dart`

### Status after this block

- Flexible `%` closest-achievable behavior is now mathematically consistent with
  unlimited candidate search.
- Device validation packet remains pending.

---

## Block 680 — BUG-016 Patch 2 UX refinement: continuous-time caution + reminder chips (28/03/2026)

**Current branch intent:** BUG-016 Patch 2 runtime UX clarity and persistence refinement.
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** Preview sheet + Task List + Groups Hub + shared utility + tests.

### Context

Approved UX direction:

- warn users inline (non-blocking) when edited plans become unusually long in
  continuous `start → end` time (focus + breaks),
- keep a persistent reminder label after save,
- expose `Total time` chip clearly in Task List selected cards.

### Changes applied

- Added shared domain helper:
  - `ContinuousPlanLoadLevel` (`none`, `unusual`, `superhuman`, `machineLevel`)
  - thresholds: `>=11h`, `>=24h`, `>=72h`
  - label/message helpers and continuous-duration calculators.
- Added shared presentation visual helper for level icon+color chips.
- Preview sheet:
  - renders inline caution (icon + text) below `Group work`,
  - caution appears only after interaction and only when net preview differs from opening snapshot.
- Task List selected cards:
  - `Time range` row now includes `Total <duration>` chip (`start → end`, includes breaks),
  - adds persistent level reminder chip (`Unusual` / `Superhuman` / `Machine-level`).
- Groups Hub:
  - adds level reminder chip to `Total time` in cards and summary modal.

### Runtime evidence

- Commit: `7736f7b` — `feat(bug016): add continuous-time cautions and reminder chips across preview/list/hub`
- Local gate PASS:
  - `flutter analyze`
  - `flutter test test/domain/continuous_plan_load_test.dart`
  - `flutter test test/presentation/viewmodels/task_editor_view_model_test.dart`
  - `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Groups Hub summary modal shows timing totals and task breakdown"`

### Status after this block

- Continuous-time caution/reminder UX is implemented with non-blocking behavior.
- Device validation packet remains pending before final Patch 2 closure.

---

## Block 681 — BUG-016 Patch 2 UX polish: work-duration readability + header consistency in preview sheets (28/03/2026)

**Current branch intent:** BUG-016 Patch 2 runtime/UI polish (preview clarity).
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** Preview sheet UI consistency + docs alignment.

### Context

User feedback highlighted two coherence issues:

- `Group work` values in preview were hard to read when large (`N min` only),
- preview top bar used `Back` text style inconsistent with other app screens
  (`< Edit ...` pattern).

### Changes applied

- Preview `Group work` now formats durations as:
  - `N min` for values `< 60`,
  - `Hh Mm` for values `>= 60`.
- Updated preview header to app-consistent style:
  - chevron back icon + sheet title row,
  - removed standalone `Back` text button presentation.

### Runtime evidence

- Local gate PASS:
  - `flutter analyze`

### Docs synchronized

- `docs/specs.md`:
  - Group impact block now specifies readable duration formatting (`min` vs `Hh Mm`).
  - Preview top-left back affordance wording aligned with app header style expectation.

### Status after this block

- BUG-016 Patch 2 UI polish applied and documented.
- Device validation packet remains pending before final Patch 2 closure.

---

## Block 682 — BUG-016 Patch 2 visual consistency: chevron-style back affordance in preview sheets (28/03/2026)

**Current branch intent:** BUG-016 Patch 2 runtime/UI polish (navigation visual coherence).
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** Preview sheet visual consistency only.

### Context

User feedback: preview header back icon still looked different from the rest of
the app (`Edit task` style), creating a subtle but visible style break.

### Changes applied

- Replaced the preview header back icon from arrow-with-shaft to chevron-style
  icon to align with app navigation visual language.
- Behavior remains unchanged (`Back` semantics still equal to `Cancel`).

### Runtime evidence

- Local gate PASS:
  - `flutter analyze`

### Status after this block

- Preview navigation affordance now follows the same visual convention as
  adjacent app screens.

---

## Block 683 — BUG-016 Patch 2 consistency fix: Edit Task weight percent after Apply now matches preview map (28/03/2026)

**Current branch intent:** BUG-016 Patch 2 runtime correctness fix (Edit Task interim percent coherence).
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** Task Editor local scope calculation only.

### Context

Validation found a deterministic mismatch after `Apply` in preview sheets:
`Edit task` could show an interim `%` inconsistent with sheet preview and final
post-save Task List values (examples: `86% -> 49%`, `72% -> 84%`).

Root cause was local-only: after `Apply`, the editor recalculated `%` with only
the edited task updated, while other selected tasks still came from the old
list snapshot until save.

### Changes applied

- `task_editor_screen.dart` now overlays `_pendingRedistribution` onto the
  selected-weight scope used for `%` rendering in `Edit task`.
- Added helper `_overlayPendingRedistribution(...)` and applied it before
  `normalizeTaskWeightPercents(...)` in `build()`.
- This keeps interim `%` in `Edit task` aligned with the exact map already
  produced by preview and later persisted on `Save`.

### Runtime evidence

- Local gate PASS:
  - `flutter analyze`

### Status after this block

- Interim `%` rendering in `Edit task` is now coherent with preview/apply/save
  for pending redistribution scenarios.

---

## Block 684 — BUG-016 Patch 2 UI compactness: value-only total-time chip + single-line timing row + machine label shortening (28/03/2026)

**Current branch intent:** BUG-016 Patch 2 runtime/UI compactness refinement.
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** Task List chip presentation + continuous-load label normalization.

### Context

User feedback requested tighter task-card timing rows so chips stay in one line
more consistently:

- remove redundant `Total` prefix in selected-card total duration chips,
- visually distinguish total duration chip,
- shorten extreme-load label to `Machine`.

### Changes applied

- `TaskCard` timing chips:
  - switched from wrapping layout to one-line horizontal flow with manual scroll.
  - total-duration chip now shows value only (example: `2h 11m`).
  - total-duration chip receives emphasized style (stronger tone and weight).
- Continuous-load label:
  - renamed `Machine-level` chip label to `Machine`.
  - load chip now has a max width with ellipsis-safe text behavior.

### Runtime evidence

- Local gate PASS:
  - `flutter analyze`

### Docs synchronized

- `docs/specs.md`:
  - Task List selected `Time range` row now specifies value-only total-duration chip
    and single-line horizontal chip behavior.
  - continuous-load reminder label list updated to `Unusual / Superhuman / Machine`.
- `docs/roadmap.md`:
  - Phase 10 BUG-016 Patch 2 decision line updated from `Machine-level` to `Machine`.

### Status after this block

- Task List timing row is now more compact and consistent for long plans without
  changing business logic.

---

## Block 685 — BUG-016 Patch 2 desktop input fix: macOS mouse-wheel horizontal chip scrolling (28/03/2026)

**Current branch intent:** BUG-016 Patch 2 runtime UX/input compatibility fix.
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** Task List selected-card timing row interaction on desktop pointer devices.

### Context

After compact-chip rollout, Android behaved correctly but macOS users could not
scroll the horizontal chip row with a mouse wheel. This blocked access to hidden
chips when content overflowed.

### Changes applied

- Added desktop-friendly horizontal scroller wrapper in `TaskCard` timing row:
  - maps pointer wheel delta (vertical or horizontal) to horizontal scroll while hovered,
  - enables drag scrolling with mouse/trackpad devices.
- Kept visual layout unchanged (single-line compact chips).

### Runtime evidence

- Local gate PASS:
  - `flutter analyze`

### Docs synchronized

- `docs/specs.md`:
  - selected `Time range` row now explicitly requires desktop pointer input support
    (drag + wheel/scroll horizontal navigation while hovered).

### Status after this block

- Horizontal chip overflow is now reachable on macOS pointer input without
  requiring touch gestures.

---

## Block 686 — BUG-016 Patch 2 preview-sheet clarity: stronger task identity + full-width selected-task chips (29/03/2026)

**Current branch intent:** BUG-016 Patch 2 preview-sheet readability/consistency refinement.
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** `TaskWeightPreviewSheet` UI hierarchy and selected-task result emphasis.

### Context

User validation highlighted two clarity issues in the preview sheet:

- the edited task/group identifier under the title was visually weak,
- `Selected tasks` cards had inconsistent widths and text-heavy rows, making
  before/after comparison harder to scan.

### Changes applied

- Header identity line (task/group name under the sheet title):
  - increased contrast (`white70`), semibold weight, and stable left alignment
    with the title text start.
- `Selected tasks` redesign:
  - cards are now full-width with uniform layout across all devices.
  - each card uses two metric rows with chips:
    - `Pomodoros`: initial chip -> result chip
    - `Weight`: initial chip -> result chip
  - initial chips remain neutral gray.
  - result-chip emphasis is field-focused:
    - editing `Total pomodoros`: only pomodoros result chip uses success/warning color.
    - editing `Task weight (%)`: only weight result chip uses success/warning color.
    - non-edited dimension result chip stays neutral gray.
  - edited task keeps a stronger neutral border highlight (no severity red).
- Fixed-mode explanation text updated to avoid promising strict invariance and
  reflect integer-constrained closest-achievable behavior.

### Runtime evidence

- Local gate PASS:
  - `flutter analyze`

### Docs synchronized

- `docs/specs.md`:
  - Fixed mode wording aligned with closest-achievable + integer constraints.
  - `Selected tasks` section updated to single-column full-width chip rows and
    field-focused result-chip coloring rules.

### Status after this block

- Preview-sheet comparisons are more legible and less ambiguous, especially for
  large numbers and dense selected-task sets.

---

## Block 687 — BUG-016 Patch 2 sheet actions simplification + edited-row baseline emphasis (29/03/2026)

**Current branch intent:** BUG-016 Patch 2 preview-sheet interaction simplification.
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** sheet exit/apply UX and edited-dimension baseline chip emphasis.

### Context

Follow-up user review requested:

- remove duplicate bottom actions (`Cancel` + `Apply`) and keep a faster
  sub-screen interaction model,
- keep `Back` as the cancel-equivalent,
- provide a subtle confirmation when exiting with unapplied changes,
- improve initial-state chip distinction on the edited row/dimension.

### Changes applied

- Sheet action model:
  - removed bottom footer buttons (`Cancel` / `Apply`).
  - added top-right `Apply` button on the same row as the sheet title.
  - top-left back chevron now closes without applying (cancel semantics).
- Exit feedback:
  - if the user exits with pending unapplied changes, a lightweight hint is shown:
    `No changes applied.`
  - if there are no pending changes, close remains silent.
  - system back uses the same hint policy via `PopScope`.
- Edited-row baseline focus:
  - initial (left) chip now receives a brighter/stronger neutral style only for
    the edited dimension on the edited task row.
  - non-edited dimensions and other task rows keep neutral baseline style.

### Runtime evidence

- Local gate PASS:
  - `flutter analyze`

### Docs synchronized

- `docs/specs.md`:
  - preview-sheet actions updated from footer Cancel/Apply to header Back + Apply.
  - added Back-exit hint rule for unapplied changes.

### Status after this block

- Preview sheet is now faster and less redundant (single visible apply action),
  while preserving safe exit semantics and clearer focus on the edited baseline.

---

## Block 688 — BUG-016 Patch 2 edited-task focus reinforcement in selected-task list (29/03/2026)

**Current branch intent:** BUG-016 Patch 2 visual focus refinement.
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** selected-task chips — stronger differentiation for edited task/dimension.

### Context

User review detected that edited-dimension result chips still looked too similar
between the edited task and other tasks, reducing clarity about "which task is
currently being edited."

### Changes applied

- In selected-task cards, for the edited dimension:
  - edited task result chip now uses stronger emphasis than the rest
    (thicker border + stronger fill intensity),
  - other task result chips keep standard emphasis.
- Existing behavior preserved:
  - only the edited dimension is color-accented,
  - non-edited dimension remains neutral,
  - edited task row keeps neutral border highlight.

### Runtime evidence

- Local gate PASS:
  - `flutter analyze`

### Docs synchronized

- `docs/specs.md`:
  - selected-task list rules now explicitly require stronger edited-task chip emphasis
    within the edited dimension.

### Status after this block

- Edited task intent is visually clearer with minimal UI noise increase.

---

## Block 689 — BUG-016 Patch 2 fix: duplicate “No changes applied.” hint on sheet exit (29/03/2026)

**Current branch intent:** BUG-016 Patch 2 UX correctness fix.
**Branch:** `fix/bug016-weight-edit-preview-modes`
**Scope:** prevent duplicate exit hint when closing preview sheet with Back.

### Context

User validation detected that exiting preview with Back after local edits could
show the same `No changes applied.` SnackBar twice in a row.

### Root cause

Two independent paths were showing the same hint for the same close action:

- explicit Back handler (`_closeWithoutApply`), and
- `PopScope.onPopInvokedWithResult` after `Navigator.pop()`.

### Changes applied

- Added a one-shot suppression guard (`_skipNextPopHint`) in
  `task_weight_preview_sheet.dart`.
- Behavior now:
  - Back button close with unapplied edits: hint shown once.
  - System back/gesture close with unapplied edits: hint shown once.
  - No unapplied edits: no hint.

### Runtime evidence

- Local gate PASS:
  - `flutter analyze`

### Status after this block

- Exit feedback is now consistent and non-duplicated across close paths.

---

## Block 690 — BUG-016 Patch 2 closure (29/03/2026)

**Current branch intent:** BUG-016 Patch 2 closure and docs synchronization.  
**Branch:** `fix/bug016-weight-edit-preview-modes`  
**Scope:** Formal closure of Phase 10 BUG-016 follow-up (preview UX track).

### Context

After the final UI/UX polish cycle and user-driven validation matrix, Patch 2
behavior is stable and coherent with the latest approved semantics:

- preview-first editing for Task weight (%) and Total pomodoros,
- Fixed/Flexible mode behavior and messaging alignment,
- Back/Apply semantics clarity,
- deterministic preview -> apply -> save pipeline,
- continuous-time caution/reminder rendering consistency.

### Validation closure packet synchronized

Created and synchronized:

- `docs/bugs/validation_bug016_2026_03_28/plan_validacion_rapida_fix.md`
- `docs/bugs/validation_bug016_2026_03_28/quick_pass_checklist.md`
- Existing runtime evidence log retained:
  - `docs/bugs/validation_bug016_2026_03_28/logs/2026-03-28_bug016p2_7736f7b_macos_debug.log`

### Local gate (final closure run)

- `flutter analyze` — PASS
- `flutter test test/domain/task_weighting_test.dart` — PASS
- `flutter test test/presentation/viewmodels/task_editor_view_model_test.dart` — PASS
- `flutter test test/domain/continuous_plan_load_test.dart` — PASS

### Cross-doc synchronization

- `docs/roadmap.md`
  - Reopened Phase 10 BUG-016 Patch 2 line moved to **Closed/OK**
    (`RVP-070`, validation complete 29/03/2026).
- `docs/validation/validation_ledger.md`
  - Added `RVP-070` as **Closed/OK** with evidence references.
  - Updated `BUGLOG-016` note to reflect Patch 2 closure tracked via `RVP-070`.
- `docs/bugs/bug_log.md`
  - BUG-016 section updated: Patch 2 implementation + validation packet + final
    status now fully closed (Patch 1 + Patch 2).

### Status after this block

- BUG-016 is fully closed end-to-end (Patch 1 correctness + Patch 2 preview UX).
- Phase 10 BUG-016 follow-up no longer pending device validation.

---

## Block 691 — BUG-019 docs-first registration + validation packet bootstrap (29/03/2026)

**Current branch intent:** BUG-019 navigation-regression documentation and pre-implementation handoff.  
**Branch:** `fix/bug019-android-back-navigation-exit`  
**Scope:** Documentation only (no runtime code changes in this block).

### Context

User-reported regression: Android system back can intermittently terminate the app
from Run Mode / Groups Hub flows instead of returning to root navigation.

### Changes applied

- Registered new bug entry:
  - `docs/bugs/bug_log.md` -> `BUG-019` (Open), with repro, expected behavior,
    hypothesis, and scope.
- Synchronized global validation queue:
  - `docs/validation/validation_ledger.md`
    - snapshot updated to 29/03/2026,
    - active non-closed bug count updated to 2 (`BUG-019` P1 + `BUG-017` P2),
    - new pending queue item `BUGLOG-019` added.
- Reopened roadmap scope for regression tracking:
  - `docs/roadmap.md`
    - added reopened Phase 19 bug item for deterministic Android back behavior.
- Created mandatory validation packet:
  - `docs/bugs/validation_bug019_2026_03_29/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug019_2026_03_29/quick_pass_checklist.md`
  - `docs/bugs/validation_bug019_2026_03_29/logs/`
  - `docs/bugs/validation_bug019_2026_03_29/screenshots/`

### Codex -> Claude handoff (required)

- Context and scope:
  - BUG-019 is now registered as docs-first P1 navigation regression.
  - No runtime patch has been applied yet.
- Files changed:
  - `docs/bugs/bug_log.md`
  - `docs/validation/validation_ledger.md`
  - `docs/roadmap.md`
  - `docs/bugs/validation_bug019_2026_03_29/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug019_2026_03_29/quick_pass_checklist.md`
- Tests executed:
  - None in this docs-only block.
- Known risks and open questions:
  - Runtime root cause still hypothesis-level (`go` route replacement + root PopScope fallback gaps).
  - Must decide final UX contract for system back at root routes before implementation.
- Explicit next action expected from Claude:
  - Confirm architecture-level navigation contract for Android system back
    (Run Mode active/non-active + Groups Hub root),
  - approve runtime implementation plan and test targets before coding starts.

### Status after this block

- BUG-019 is formally queued and traceable across bug log, ledger, roadmap, and
  validation packet.
- Project is ready for Claude review and runtime fix planning.

---

## Block 692 — BUG-019 validation-scope hardening: Settings back-stack non-regression added (29/03/2026)

**Current branch intent:** BUG-019 docs-only validation hardening before runtime implementation.
**Branch:** `fix/bug019-android-back-navigation-exit`
**Scope:** Validation packet refinement (no runtime code).

### Context

Follow-up requirement: BUG-019 must not break screens that already use normal
stack back navigation (explicitly Settings).

### Changes applied

- `docs/bugs/validation_bug019_2026_03_29/plan_validacion_rapida_fix.md`
  - Added Scenario D (`Settings` stack-back non-regression on Android).
  - Added dedicated quick-scan grep for `/settings` -> previous-route pop behavior.
  - Updated closure criteria to require Scenario D PASS evidence.
- `docs/bugs/validation_bug019_2026_03_29/quick_pass_checklist.md`
  - Added Scenario D exact-repro checkbox.
  - Added explicit regression-smoke checkbox for Settings AppBar/system back.

### Status after this block

- BUG-019 validation matrix now covers both:
  - root-route fallback hardening (`/groups`, `/timer/:id`), and
  - non-regression of existing stack-pop routes (`/settings`).

---

## Block 693 — BUG-019 closure: Android back navigation exit fix validated (29/03/2026)

**Branch:** `fix/bug019-android-back-navigation-exit`
**Commits:** `d1a1f19`, `e16a692`, `ed97de7`
**Bugs closed:** BUG-019 / BUGLOG-019 (P1)

### Root cause confirmed

All major screens (`/groups`, `/timer/:id`) are navigated to via `context.go()`,
which replaces the entire navigation stack with a single entry. When Android system
back fired on a single-entry stack, go_router had nothing to pop and delegated to
the platform → app exited. `GroupsHubScreen` had no `PopScope`. `TimerScreen` had
`PopScope(canPop: !shouldBlockExit)`: when non-active (`canPop=true`), same exit
problem; the `navigator.pop()` in the active path was dead code (`_confirmExit`
always returns `false` for active execution and handles navigation internally).

### Fix applied

**`d1a1f19` — GroupsHubScreen**: Wrapped `return Scaffold(...)` in
`PopScope(canPop: false)`. Handler: `context.canPop()` → pop; else →
`context.go('/tasks')`. Synchronous, no logic changes.

**`e16a692` — TimerScreen**: Changed `canPop: !shouldBlockExit` → `canPop: false`.
Active path: `await _confirmExit(state, vm); return` (identical behavior, dead code
removed). Non-active path: `context.canPop()` → pop; else →
`context.go(isLocalMode ? '/tasks' : '/groups')`. Zero changes to `_confirmExit`,
`_cancelAndNavigateToHub`, or any session/group logic.

**`ed97de7` — Tests**: 4 new `testWidgets` in
`timer_screen_completion_navigation_test.dart`:

- Groups Hub system back → `/tasks` (single-entry stack)
- Timer non-active system back → `/groups` (account mode, single-entry stack)
- Timer active system back → confirmation dialog; "Keep running" keeps timer running
- Settings route stack-pop non-regression (no fallback override)
  Helper `_buildRunningSession` extended with optional `status`/`phase`/`finishedAt`
  params (defaults preserve all existing tests).

### Validation results (Android RMX3771, 29/03/2026)

- Scenario A — Groups Hub back → Task List root: **PASS**
- Scenario B — Timer non-active back → Groups Hub: **PASS**
  (Note: group must be truly non-active; running/paused groups correctly show the
  confirmation dialog per Scenario C — this is expected behavior, not a bug.)
- Scenario C — Timer active confirmation guard: **PASS** (screenshot evidence)
- Scenario D — Settings stack-pop non-regression: **PASS**
- `flutter analyze`: PASS
- `flutter test timer_screen_completion_navigation_test.dart`: PASS
- `flutter test timer_screen_syncing_overlay_test.dart`: PASS

### Status after this block

BUG-019 / BUGLOG-019: **Closed/OK**.
Active P1 bugs: **0**. Active P2 bugs: **1** (BUG-017, Edit Task preset dropdown).
Branch ready to merge into `develop`.

---

## Block 694 — BUG-020: Task editor preview sheet context/feedback consistency (30/03/2026)

Branch: fix/task-editor-preview-context-duration-feedback
Commit: 78b72db

### Problem

Edit Task preview sheets (Total pomodoros + Task weight %) had multiple compounded UX
incoherencies:

1. Terminology always said "Group work" regardless of whether the task was selected for
   a group, misleading users editing a standalone task.
2. Only work duration (no breaks) was shown. The Unusual/Superhuman/Machine threshold
   warnings are based on total-with-breaks, so the basis for those warnings was invisible.
3. The Unusual/Superhuman/Machine caution was suppressed after the first show within the
   sheet session, making it feel like an erratic bug when re-entering the threshold range.
4. Exit snackbar always said "No changes applied" regardless of whether Apply was pressed.
5. No confirmation modal when pressing Back with unapplied changes.

### Fix

- `isGroupContext` added to `TaskWeightPreviewSheet`; driven by `showWeightPercent` at
  call site — true only when task is currently selected in the group scope.
- `_scopeLabel` resolves 'Task' / 'Group' at runtime. All three label strings
  (`totalPomodorosLabel`, `workLabel`, `totalDurationLabel`) derived from it.
- Second duration line added using `continuousTaskDurationsSecondsForTasks` (single task)
  / `continuousGroupDurationSecondsForTasks` (group), surfacing total-with-breaks so the
  basis of extreme-duration warnings is visible.
- `showContinuousCaution` is now value-driven: no `_hasUserInteracted` gate. Caution
  appears immediately when result meets threshold, disappears when below, reappears on
  re-entry — deterministic.
- Back flow replaced with `_handleBackPressed` + `_handlingBackFlow` re-entry guard +
  `_allowPop` controlled pop:
  - unapplied changes → modal (Apply and close / Discard and close / Continue editing);
    Apply button hidden in modal when `_result == null` (invalid input).
  - no changes → close directly + snackbar "No changes made."
- Apply button: disabled when `result == null || !_hasUnappliedChanges`.
- `_applyAndClose`: snackbar "Changes applied." on apply path.

### Validation results (Android RMX3771 + macOS, 30/03/2026)

- Scenario A — Task terminology when not selected: PASS
- Scenario B — Group terminology when selected: PASS
- Scenario C — Dual duration lines (work + total with breaks): PASS
- Scenario D — Caution reappears on re-entry to threshold: PASS
- Scenario E — Back modal fires on unapplied changes: PASS
- Scenario F — Snackbar "Changes applied." after Apply: PASS
- Scenario G — No-change close + "No changes made.": PASS
- `flutter analyze`: PASS
- `flutter test task_editor_view_model_test.dart`: PASS
- `flutter test continuous_plan_load_test.dart`: PASS

### Follow-up registered (separate branch)

- Edit Group: show Group work + Total group duration + threshold caution with the final
  preset configuration applied (Phase 20 scope, roadmap.md updated).
- Ícono "atrás" unificado entre plataformas: chevron_left vs arrow_back inconsistency
  across Edit Task and preview sheets (separate fix branch).

### Status after this block

BUG-020 / BUGLOG-020: **Closed/OK**.
Active P1 bugs: **0**. Active P2 bugs: **1** (BUG-017, Edit Task preset dropdown).

---

## Block 695 — UI consistency: unified Back icon in Edit Task + preview sheets (30/03/2026)

**Current branch intent:** UI polish only (navigation icon consistency).
**Branch:** `fix/unify-back-icon-preview-sheets`
**Scope:** Make Back icon glyph consistent between `Edit task` and preview sheets across platforms.

### Change applied

- `lib/presentation/screens/task_editor_screen.dart`
  - Added explicit AppBar leading icon button with `Icons.arrow_back` to avoid
    platform-dependent implicit icon rendering.
- `lib/presentation/screens/task_weight_preview_sheet.dart`
  - Replaced preview-sheet leading icon `Icons.chevron_left` with `Icons.arrow_back`.

### Validation

- `flutter analyze`: PASS

### Status after this block

- Back icon is now visually consistent between `Edit task` and `Edit Total pomodoros` / `Edit Task weight`.

---

## Block 696 — BUG-022 docs-first + runtime patch: macOS Authentication keyboard lock after sign-out (30/03/2026)

**Current branch intent:** BUG-022 registration, runtime hardening, and validation bootstrap.
**Branch:** `fix/bug022-macos-auth-keyboard-stuck`
**Scope:** Bug docs synchronization + LoginScreen macOS keyboard-state repair.

### Context

User reported a recurring macOS issue: after signing out to switch account, Authentication fields (`Email`/`Password`) stopped accepting keyboard input. Logs repeatedly showed duplicate key-down exceptions (`physical key is already pressed`) tied to stale Backspace key state.

### Changes applied

- Documentation-first registration:
  - Added `BUG-022` entry to `docs/bugs/bug_log.md` with repro, expected behavior, root-cause hypothesis, patch summary, and status `In validation`.
  - Added `BUGLOG-022` to `docs/validation/validation_ledger.md` as `P1 / In validation`; snapshot updated to 2026-03-30 with active non-closed bug count = 2 (`BUG-022`, `BUG-017`).
  - Updated `docs/roadmap.md` global timeline and reopened phases with explicit Phase 6 bug item for Authentication keyboard reliability (`BUG-022`).
  - Updated `docs/specs.md` section 10.1 with desktop auth reliability rule (Authentication must keep keyboard input usable after sign-out/account switch).
  - Created validation packet:
    - `docs/bugs/validation_bug022_2026_03_30/plan_validacion_rapida_fix.md`
    - `docs/bugs/validation_bug022_2026_03_30/quick_pass_checklist.md`
    - `docs/bugs/validation_bug022_2026_03_30/logs/`
    - `docs/bugs/validation_bug022_2026_03_30/screenshots/`

- Runtime patch (`lib/presentation/screens/login_screen.dart`):
  - Added macOS-only stale-key repair routine when Authentication opens and when user taps email/password fields.
  - Repair path reads engine keyboard state (`SystemChannels.keyboard` `getKeyboardState`) and compares it against framework pressed keys.
  - For stale pressed keys, synthesizes `KeyUpEvent` through `HardwareKeyboard.instance.handleKeyEvent` to unblock text input.
  - Added `[AuthKeyboardRepair]` debug diagnostics for validation logs.

### Tests executed

- `flutter analyze` -> PASS (`No issues found!`).
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> PASS (`+25`, all tests passed).

### Status after this block

- `BUG-022` / `BUGLOG-022`: **In validation** (runtime patch landed; macOS device exact repro validation pending in packet).
- Active bug queue:
  - P1: `BUG-022` (In validation)
  - P2: `BUG-017` (Open)

---

## Block 697 — BUG-022 closure: macOS Authentication keyboard lock fixed and validated (30/03/2026)

**Current branch intent:** BUG-022 closure and documentation synchronization.
**Branch:** `fix/bug022-macos-auth-keyboard-stuck`
**Commit:** `4e439db`
**Bugs closed:** `BUG-022` / `BUGLOG-022` (P1)

### Closure evidence

- User validation confirmation in thread (30/03/2026): after signing out and switching account on macOS, Authentication `Email` and `Password` fields accept keyboard input normally; no immediate recurrence observed.
- Local gate on closure commit:
  - `flutter analyze` -> PASS
  - `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> PASS

### Documentation synchronization

- `docs/bugs/bug_log.md`
  - `BUG-022` moved from `In validation` to `Closed/OK`.
  - Added closure evidence and commit reference.
- `docs/validation/validation_ledger.md`
  - Snapshot updated: active non-closed bug-log entries now `1` (`BUG-017` only).
  - `BUGLOG-022` moved to `Closed/OK` with `closed_commit_hash` + evidence.
- `docs/bugs/validation_bug022_2026_03_30/`
  - `plan_validacion_rapida_fix.md` status updated to `Closed/OK` with commit + evidence.
  - `quick_pass_checklist.md` closure checklist marked PASS.
- `docs/roadmap.md`
  - Added timeline closure note for `BUG-022`.
  - Reopened phase item for `BUG-022` struck through as `Closed/OK`.

### Status after this block

- `BUG-022` / `BUGLOG-022`: **Closed/OK**.
- Active open bugs:
  - `BUG-017` (P2).

---

## Block 698 — BUG-021 closure: stale ownership rejection snackbar invalidation accepted (30/03/2026)

**Current branch intent:** BUG-021 runtime fix + validation packet synchronization and closure.
**Branch:** `fix/bug021-ownership-snackbar-autodismiss`
**Commit:** `88e0bb1`
**Bugs closed:** `BUG-021` / `BUGLOG-021` (P1)

### Context

Run Mode could keep an obsolete ownership rejection snackbar visible after ownership context changed. The runtime fix ties visible snackbar lifecycle to the current rejected request key and auto-dismisses when context becomes invalid.

### Runtime implementation

- `lib/presentation/screens/timer_screen.dart`
  - Added `_activeOwnershipRejectionSnackKey`.
  - Added `_rejectedOwnershipRequestKeyForDevice(...)`.
  - Dismisses a visible rejection snackbar when:
    - requester becomes owner,
    - requester has pending/local-pending request,
    - current rejected request key no longer matches the visible snackbar key,
    - group switch reset occurs.
  - Preserves deterministic show-once behavior per rejection key.

- `test/presentation/timer_screen_completion_navigation_test.dart`
  - Added widget tests:
    - `Run Mode dismisses stale rejection snackbar when requester submits a new request`
    - `Run Mode dismisses stale rejection snackbar when requester becomes owner`

### Validation evidence

- Local gate PASS:
  - `flutter analyze`
  - `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Run Mode dismisses stale rejection snackbar"`
- Validation packet synchronized:
  - `docs/bugs/validation_bug021_2026_03_30/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug021_2026_03_30/quick_pass_checklist.md`
  - logs under `docs/bugs/validation_bug021_2026_03_30/logs/`
- User accepted closure in thread after reviewing behavior and evidence.

### Scope note

The original user report referred to automatic owner switch without explicit ownership request. That path does not emit the rejection snackbar targeted by BUG-021. Closure is accepted for the rejection-snackbar invalidation scope implemented and validated above.

### Documentation synchronization

- `docs/bugs/bug_log.md` — BUG-021 moved to `Closed/OK` with scope/evidence note.
- `docs/validation/validation_ledger.md` — BUGLOG-021 moved to `Closed/OK`; snapshot updated (active non-closed bug count back to 1).
- `docs/roadmap.md` — BUG-021 closure note added in timeline; reopened phase entry struck through.

### Status after this block

- `BUG-021` / `BUGLOG-021`: **Closed/OK**.
- Active open bugs:
  - `BUG-017` (P2).

---

## Block 699 — BUG-017 closure: preset dropdown no longer exposes synthetic Custom (31/03/2026)

**Current branch intent:** BUG-017 targeted UI fix + regression coverage + docs closure.
**Branch:** `fix/bug017-preset-dropdown-custom`
**Commit:** `88e0bb1`
**Bugs closed:** `BUG-017` / `BUGLOG-017` (P2)

### Context

Edit Task preset selector was exposing a synthetic `Custom` option in the dropdown,
mixing derived UI state with real persisted presets and creating ambiguity when a real
preset named `Custom` existed.

### Runtime implementation

- `lib/presentation/screens/task_editor_screen.dart`
  - Removed synthetic `Custom` sentinel item (`__custom__`) from dropdown items.
  - Kept dropdown values bound only to persisted preset IDs.
  - Added unlinked hint (`Select preset`) for closed-field unlinked state.
  - Added linked/unlinked indicator next to `Preset` label (green when linked,
    neutral when unlinked).
  - Preserved existing auto-detach behavior when linked preset values diverge.

- `test/presentation/timer_screen_completion_navigation_test.dart`
  - Added dedicated BUG-017 widget regression scenario for synthetic-item removal,
    real `Custom` preset selection, and linked/unlinked detach transitions.

### Validation evidence

- Local gate PASS:
  - `flutter analyze`
  - `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Edit Task preset selector"`
- Validation packet synchronized:
  - `docs/bugs/validation_bug017_2026_03_31/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug017_2026_03_31/quick_pass_checklist.md`
  - `docs/bugs/validation_bug017_2026_03_31/logs/2026-03-31_bug017_pending-local_analyze.log`
  - `docs/bugs/validation_bug017_2026_03_31/logs/2026-03-31_bug017_pending-local_widget_debug.log`

### Documentation synchronization

- `docs/bugs/bug_log.md` — BUG-017 moved to `Closed/OK` with closure evidence.
- `docs/validation/validation_ledger.md` — BUGLOG-017 moved to `Closed/OK`.

### Status after this block

- `BUG-017` / `BUGLOG-017`: **Closed/OK** (`pending-local`).
- Active open bug-log entries: **0**.

---

## Block 700 — BUG-023 opened: Save-as-preset return flow must auto-link in Task Editor (31/03/2026)

**Current branch intent:** BUG-023 docs-first opening + implementation kickoff for route-return preset linking.
**Branch:** `fix/bug023-save-as-preset-autolink`
**Commit:** `pending-local`
**Bugs opened:** `BUG-023` / `BUGLOG-023` (P2)

### Context

During BUG-017 validation, a new flow gap was identified: from Task Editor, `Save as new preset`
creates/saves a preset but the task remains unlinked (`Select preset`) after returning.

### Root cause summary (confirmed)

- Task Editor launches `/settings/presets/new` without consuming a navigation result.
- Preset Editor save/exit path pops without returning a preset id payload.
- Duplicate-resolution branches do not propagate a deterministic link target id back to Task Editor.

### Documentation-first synchronization

- `docs/specs.md`
  - Added explicit Save-as-preset return contract in Task Editor behavior:
    successful save/resolution must return a preset id and auto-link the current task.
  - Added duplicate-resolution id mapping for return payload:
    - Save anyway -> new preset id
    - Use existing -> existing duplicate id
    - Rename existing -> renamed existing duplicate id
    - Cancel/blocked -> no id (remain Custom)
- `docs/bugs/bug_log.md`
  - Added `BUG-023` entry with repro, symptom, expected behavior, and confirmed root cause.
- `docs/validation/validation_ledger.md`
  - Added `BUGLOG-023` (Pending, P2) to active bug queue.
  - Snapshot updated: active non-closed bug-log entries now **1**.
- `docs/roadmap.md`
  - Reopened Phase 10 item added for `BUG-023` auto-link return behavior.

### Next execution step

- Implement route-result payload from Preset Editor -> Task Editor.
- Add `applyPresetById` in TaskEditorViewModel (repo read by id, no stream-race dependency).
- Add widget regression coverage for Save-as-preset auto-link return path.

### Status after this block

- `BUG-023` / `BUGLOG-023`: **Open**.
- Active open bug-log entries: **1** (`BUG-023`).

---

## Block 701 — BUG-023 runtime implementation + local validation gate PASS (31/03/2026)

**Current branch intent:** BUG-023 runtime fix + focused regression coverage + packet evidence.
**Branch:** `fix/bug023-save-as-preset-autolink`
**Commit:** `pending-local`
**Bugs in validation:** `BUG-023` / `BUGLOG-023` (P2)

### Runtime implementation

- `lib/presentation/screens/preset_editor_screen.dart`
  - Replaced enum-only save outcome with payload-capable outcome (`linkedPresetId`).
  - Added deterministic id mapping for duplicate-resolution exits:
    - Save anyway -> draft preset id.
    - Use existing -> existing duplicate id.
    - Rename existing -> renamed existing duplicate id.
    - Cancel/blocked -> null.
  - Added caller-gated result return (`returnPresetId`) to avoid cross-flow payload leakage.
- `lib/presentation/screens/task_editor_screen.dart`
  - `Save as new preset` now awaits `/settings/presets/new?returnPresetId=1`.
  - On returned id, applies preset immediately and refreshes Task Editor UI state.
- `lib/presentation/viewmodels/task_editor_view_model.dart`
  - Added `applyPresetById(String id)` with repository read-by-id + `applyPreset` orchestration.
- `lib/app/router.dart`
  - Added query parsing for `returnPresetId` on `/settings/presets/new`.

### Regression coverage

- `test/presentation/timer_screen_completion_navigation_test.dart`
  - Added `Edit Task Save as new preset auto-links returned preset`.
  - Updated Task Editor test router harness to use real `PresetEditorScreen` route and return payload query behavior.

### Local validation evidence

- `flutter analyze` -> PASS
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Edit Task"` -> PASS (`+2`)
- Logs captured in:
  - `docs/bugs/validation_bug023_2026_03_31/logs/2026-03-31_bug023_pending-local_analyze.log`
  - `docs/bugs/validation_bug023_2026_03_31/logs/2026-03-31_bug023_pending-local_widget_debug.log`

### Documentation synchronization

- `docs/bugs/bug_log.md` -> BUG-023 moved to **In validation** with implementation details + local evidence.
- `docs/validation/validation_ledger.md` -> BUGLOG-023 moved to **In validation**.
- `docs/bugs/validation_bug023_2026_03_31/` -> packet created with required files:
  - `plan_validacion_rapida_fix.md`
  - `quick_pass_checklist.md`
  - `logs/`
  - `screenshots/`

### Status after this block

- `BUG-023` / `BUGLOG-023`: **In validation**.
- Active open bug-log entries: **1** (`BUG-023`; device validation pending).

---

## Block 702 — BUG-023 closure: Task Editor save-as-preset return now auto-links (31/03/2026)

**Current branch intent:** BUG-023 validation closure synchronization.
**Branch:** `fix/bug023-save-as-preset-autolink`
**Commit:** `pending-local`
**Bugs closed:** `BUG-023` / `BUGLOG-023` (P2)

### Closure evidence

- Local gate PASS:
  - `flutter analyze`
  - `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Edit Task"`
- macOS live validation PASS (manual):
  - `Save anyway` flow returns to Edit Task linked state.
  - `Use existing` duplicate-resolution flow returns to Edit Task linked state.
- Android manual validation was explicitly waived by project owner decision on 31/03/2026;
  waiver recorded as accepted residual risk for this UI/navigation-scope fix.

### Documentation synchronization

- `docs/bugs/validation_bug023_2026_03_31/plan_validacion_rapida_fix.md`
  - Status moved to `Closed/OK`.
  - Added macOS manual PASS details and Android waiver note.
- `docs/bugs/validation_bug023_2026_03_31/quick_pass_checklist.md`
  - Marked macOS scenarios PASS and Android waived by owner decision.
- `docs/bugs/bug_log.md`
  - `BUG-023` moved from `In validation` to `Closed/OK` with closure evidence.
- `docs/validation/validation_ledger.md`
  - `BUGLOG-023` moved to `Closed/OK`; snapshot updated (active non-closed bug count: 0).
- `docs/roadmap.md`
  - Reopened Phase 10 line for `BUG-023` struck through and marked `Closed/OK`.

### Status after this block

- `BUG-023` / `BUGLOG-023`: **Closed/OK** (`pending-local`).
- Active open bug-log entries: **0**.

---

## Block 703 — BUG-023 Android quick validation evidence synced (31/03/2026)

**Current branch intent:** BUG-023 post-closure evidence sync (Android manual quick PASS).
**Branch:** `fix/bug023-save-as-preset-autolink`
**Commit:** `pending-local`
**Bugs affected:** `BUG-023` / `BUGLOG-023` (P2, remains Closed/OK)

### Validation evidence update

- Android quick device validation PASS (RMX3771):
  - Scenario A (new preset save return) restored linked Edit Task state (`preset 21 min`).
  - Scenario B (`Use existing`) restored linked Edit Task state (`preset 20 min (2)`).
- Runtime log captured:
  - `docs/bugs/validation_bug023_2026_03_31/logs/2026-03-31_bug023_pending-local_android_debug.log`
- Screenshot evidence captured in-thread during live validation.
- Project owner explicit final closure confirmation received in-thread (31/03/2026).

### Documentation synchronization delta

- `docs/bugs/validation_bug023_2026_03_31/plan_validacion_rapida_fix.md`
  - Replaced Android waiver note with Android manual quick PASS evidence.
- `docs/bugs/validation_bug023_2026_03_31/quick_pass_checklist.md`
  - Replaced waived checkbox with Android PASS checks for Scenario A + Scenario B.
- `docs/bugs/bug_log.md`
  - Replaced Android waiver evidence with Android PASS + log path + screenshot evidence note.
- `docs/validation/validation_ledger.md`
  - `BUGLOG-023` evidence updated from waived to Android PASS.
- `docs/roadmap.md`
  - BUG-023 closure note updated from waived to Android quick validation PASS.

### Status after this block

- `BUG-023` / `BUGLOG-023`: **Closed/OK** (`pending-local`) with macOS + Android manual validation evidence.
- Active open bug-log entries: **0**.

---

## Block 704 — RVP-021..RVP-028 validation closure sync (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet for `RVP-021`..`RVP-028` with explicit test evidence per ID.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation IDs closed:** `RVP-021`, `RVP-022`, `RVP-023`, `RVP-024`, `RVP-025`, `RVP-026`, `RVP-027`, `RVP-028`

### Runtime/test implementation

- `test/presentation/timer_screen_completion_navigation_test.dart`
  - Strengthened non-planned Groups Hub coverage with card-level `Scheduled` row absence assertion (`RVP-021`).
  - Added deterministic cancel-order test proving group cancel persistence precedes activeSession clear (`RVP-024`).
  - Added heavy canceled-history retention regression test keeping Completed section visible (`RVP-026`).
  - Added canceled-group auto-fallback test from `/timer/:id` to `/groups` (`RVP-028`).
  - Added CTA placement assertion ensuring `Go to Task List` is above content sections (`RVP-025`).
  - Added reusable event logging in fake repositories for ordered side-effect assertions.
- `test/widgets/preset_sync_coordinator_test.dart`
  - Added dedicated dedupe regression for account-local preset push path:
    when remote already has `Classic Pomodoro`, local push does not duplicate classic and still pushes non-classic presets (`RVP-027`).

### Local validation gate

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart test/widgets/preset_sync_coordinator_test.dart` -> PASS (`+33`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to 01/04/2026.
  - `RVP-021`..`RVP-028` moved to `Closed/OK` with per-ID evidence.
  - Remaining open roadmap queue recomputed: 29 `RVP-*` + 3 `IDEA-*`.
  - Deferred-feature section title normalized to remove stale “after historical closure” wording.
- `docs/roadmap.md`
  - 03/02/2026 Phase 19 lines for `RVP-021`..`RVP-028` switched from `validation pending` to validated `Closed/OK` on 01/04/2026.
- `docs/features/feature_backlog.md`
  - IDEA-039 note corrected: deferral lifted by owner decision, but historical RVP backlog is still in progress.

### Status after this block

- Closed roadmap validations in this packet: **8** (`RVP-021`..`RVP-028`).
- Open historical roadmap queue now: **29** (`RVP-029`..`RVP-031`, `RVP-034`..`RVP-040`, `RVP-042`, `RVP-045`..`RVP-062`).

---

## Block 705 — RVP-029 closure via Firestore repository regression coverage (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-029`) with deterministic repository tests.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-029`

### Runtime/test implementation

- Added `test/data/repositories/firestore_pomodoro_session_repository_test.dart` with focused in-memory Firestore/Auth fakes for repository transaction paths.
- Added regression case:
  - `publishSession persists payload changes when sessionRevision is equal`:
    verifies equal `sessionRevision` writes still persist payload deltas (`phase`, `status`, `remainingSeconds`) instead of being reduced to heartbeat behavior.
- Added companion guard case:
  - `publishSession keeps existing snapshot when incoming owner differs`.

### Local validation gate

- `flutter test test/data/repositories/firestore_pomodoro_session_repository_test.dart` -> PASS (`+2`)
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart test/widgets/preset_sync_coordinator_test.dart test/data/repositories/firestore_pomodoro_session_repository_test.dart` -> PASS (`+35`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `31` pending roadmap validations.
  - `RVP-029` moved to `Closed/OK` with explicit test evidence.
  - Historical implementation commit linked for traceability:
    `6be3890` — `Fix activeSession idempotent writes preserving remainingSeconds updates`.
- `docs/roadmap.md`
  - 02/03/2026 line for idempotent activeSession writes moved from `validation pending`
    to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **9** (`RVP-021`..`RVP-029`).
- Open historical roadmap queue now: **28**
  (`RVP-030`, `RVP-031`, `RVP-034`..`RVP-040`, `RVP-042`, `RVP-045`..`RVP-062`).

---

## Block 706 — RVP-030 closure via existing owner-sync regression suite (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-030`) using focused existing regression evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-030`

### Validation evidence executed

- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart --plain-name "[REWRITE-CORE] authoritative runtime transitions must originate from TimerService (Invariant 3)"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart --plain-name "[PHASE4] active projection must continue with local fallback when timeSync is unavailable"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart --plain-name "post-resume resync callback does not use disposed ref"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Why this closes RVP-030

- Owner render/runtime authority:
  - Invariant 3 test asserts authoritative runtime transition path originates from `TimerService` and `vm.pause()` yields coherent paused runtime state.
- Local fallback without server offset:
  - Phase 4 test asserts active countdown keeps projecting and decreasing when time sync offset is unavailable (`offset=null`), avoiding freeze on snapshot remaining.
- Disposed-ref-safe resync:
  - Dispose-safe resume test asserts post-resume callbacks are no-op after disposal and emit no invalid-ref exceptions.

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `30` pending roadmap validations.
  - `RVP-030` moved to `Closed/OK` with explicit targeted test evidence.
- `docs/roadmap.md`
  - 02/03/2026 owner-sync stabilization line moved from `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **10** (`RVP-021`..`RVP-030`).
- Open historical roadmap queue now: **27**
  (`RVP-031`, `RVP-034`..`RVP-040`, `RVP-042`, `RVP-045`..`RVP-062`).

---

## Block 707 — RVP-031 closure: planning max-fit + inline adjusted-end notice validated (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-031`) with domain + widget evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-031`

### Test coverage added/validated

- Added widget coverage in `test/presentation/task_group_planning_screen_test.dart`:
  - `shows inline adjusted-end notice for schedule-by-range when max-fit ends earlier`
  - `shows inline adjusted-end notice for schedule-by-total when max-fit ends earlier`
- Reused existing domain suite in `test/domain/task_group_planner_test.dart`:
  - includes max-fit behavior assertions (`maximizes within a 6 hour window`)
    and redistribution boundary checks.

### Local validation gate

- `flutter test test/domain/task_group_planner_test.dart test/presentation/task_group_planning_screen_test.dart` -> PASS (`+13`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `29` pending roadmap validations.
  - `RVP-031` moved to `Closed/OK` with explicit domain + UI evidence.
  - Historical implementation references linked:
    - `38810bd` — `Add planner tests and max-fit refinement`
    - `5c3d22b` — `Inline adjusted-end notice in planning`
- `docs/roadmap.md`
  - 08/02/2026 planning max-fit + inline adjusted-end line moved from
    `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **11** (`RVP-021`..`RVP-031`).
- Open historical roadmap queue now: **26**
  (`RVP-034`..`RVP-040`, `RVP-042`, `RVP-045`..`RVP-062`).

---

## Block 708 — RVP-034 closure: stale ownership auto-claim + post-request resync validated (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-034`) with ownership stale-threshold and post-request resync evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-034`

### Test coverage added/validated

- `test/data/repositories/firestore_pomodoro_session_repository_test.dart`
  - Added `tryAutoClaimStaleOwner auto-claims running stale owner without manual request`.
  - Added `tryAutoClaimStaleOwner does not claim running owner before 45s stale threshold`.
- `test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart`
  - Added `requestOwnership triggers post-request resync fetch`.
  - Added `approveOwnershipRequest triggers post-request resync fetch`.
  - Added `rejectOwnershipRequest triggers post-request resync fetch`.

### Local validation gate

- `flutter test test/data/repositories/firestore_pomodoro_session_repository_test.dart test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart` -> PASS (`+11`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `28` pending roadmap validations.
  - `RVP-034` moved to `Closed/OK` with repository + ViewModel evidence.
  - Historical implementation commit linked:
    - `30097b8` — `Auto-claim stale ownership without request`
- `docs/roadmap.md`
  - 11/02/2026 ownership auto-claim + 45s threshold + post-request resync line moved from
    `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **12** (`RVP-021`..`RVP-031`, `RVP-034`).
- Open historical roadmap queue now: **25**
  (`RVP-035`..`RVP-040`, `RVP-042`, `RVP-045`..`RVP-062`).

---

## Block 709 — RVP-035 closure: paused ownership stability + paused heartbeat continuity validated (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-035`) with paused ownership guardrails and paused-heartbeat evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-035`

### Test coverage added/validated

- `test/data/repositories/firestore_pomodoro_session_repository_test.dart`
  - Added `tryAutoClaimStaleOwner claims paused stale owner only when pending request is for requester`.
  - Added `tryAutoClaimStaleOwner does not claim paused stale owner without self pending request`.
- `test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart`
  - Added `paused owner publishes periodic heartbeat snapshots` with extended timeout and paused-owner hydration setup.
  - Extended `RecordingSessionRepository` instrumentation (`publishSession` call capture + last published snapshot) to assert heartbeat writes.

### Local validation gate

- `flutter test test/data/repositories/firestore_pomodoro_session_repository_test.dart test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart` -> PASS (`+14`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `27` pending roadmap validations.
  - `RVP-035` moved to `Closed/OK` with paused ownership + heartbeat test evidence.
  - Historical implementation commit linked:
    - `9bcae9c` — `Stabilize ownership during paused sessions`
- `docs/roadmap.md`
  - 11/02/2026 paused ownership stability + Android paused heartbeat line moved from
    `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **13** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`).
- Open historical roadmap queue now: **24**
  (`RVP-036`..`RVP-040`, `RVP-042`, `RVP-045`..`RVP-062`).

---

## Block 710 — RVP-036 closure: ownership API hardening validated (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-036`) with explicit request-vs-claim and owner-only clear evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-036`

### Test coverage added/validated

- `test/data/repositories/firestore_pomodoro_session_repository_test.dart`
  - Added `requestOwnership never transfers owner even when owner heartbeat is stale`.
  - Added `clearSessionAsOwner keeps session when caller is not current owner`.
  - Added `clearSessionAsOwner deletes session when caller matches current owner`.
- Existing ownership API tests in the same suite remain green:
  - running/paused stale auto-claim rules and stale-threshold guard.

### Local validation gate

- `flutter test test/data/repositories/firestore_pomodoro_session_repository_test.dart` -> PASS (`+9`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `26` pending roadmap validations.
  - `RVP-036` moved to `Closed/OK` with API-level repository evidence.
  - Historical implementation commit linked:
    - `d979947` — `Harden stale ownership handling`
- `docs/roadmap.md`
  - 11/02/2026 ownership API hardening line moved from
    `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **14** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`).
- Open historical roadmap queue now: **23**
  (`RVP-037`..`RVP-040`, `RVP-042`, `RVP-045`..`RVP-062`).

---

## Block 711 — RVP-037 closure: missing lastUpdatedAt is non-stale for ownership paths (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-037`) with explicit missing-timestamp stale-guard evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-037`

### Test coverage added/validated

- `test/data/repositories/firestore_pomodoro_session_repository_test.dart`
  - Added `tryAutoClaimStaleOwner does not claim when lastUpdatedAt is missing`.
  - Added `clearSessionIfStale keeps active session when lastUpdatedAt is missing`.
- Existing ownership API tests in the same suite remain green.

### Local validation gate

- `flutter test test/data/repositories/firestore_pomodoro_session_repository_test.dart` -> PASS (`+11`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `25` pending roadmap validations.
  - `RVP-037` moved to `Closed/OK` with missing-timestamp stale-guard evidence.
  - Historical implementation commit linked:
    - `d979947` — `Harden stale ownership handling`
- `docs/roadmap.md`
  - 11/02/2026 stale ownership null-timestamp line moved from
    `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **15** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`).
- Open historical roadmap queue now: **22**
  (`RVP-038`..`RVP-040`, `RVP-042`, `RVP-045`..`RVP-062`).

---

## Block 712 — RVP-038 closure: wait-for-first-snapshot expiry guard validated (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-038`) with first-snapshot expiry guard evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-038`

### Test coverage validated

- `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
  - `does not complete running group while session stream is loading`
  - `does not complete when first snapshot is null then paused`

### Local validation gate

- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "does not complete running group while session stream is loading"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "does not complete when first snapshot is null then paused"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `24` pending roadmap validations.
  - `RVP-038` moved to `Closed/OK` with coordinator-level pause-resume guard evidence.
  - Historical implementation commit linked:
    - `8174bda` — `Guard paused expiry and remove repo auto-complete`
- `docs/roadmap.md`
  - 11/02/2026 first-activeSession-snapshot expiry line moved from
    `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **16** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`).
- Open historical roadmap queue now: **21**
  (`RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`..`RVP-062`).

---

## Block 713 — RVP-039 closure: activeSession running + groupId match guard validated (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-039`) with expiry guard evidence and docs coherence sync.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-039`

### Test coverage validated

- `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
  - `does not complete running group when active session is paused`
  - `does not complete when active session belongs to another group`
  - `completes expired running group and unblocks overdue scheduled auto-start`

### Local validation gate

- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "does not complete running group when active session is paused"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "does not complete when active session belongs to another group"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "completes expired running group and unblocks overdue scheduled auto-start"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/specs.md`
  - Clarified live-session expiry rule vs startup zombie-run exception (`BUGLOG-008C`) under the same section (`docs/specs.md:697-705`), preserving intentional `activeSession == null` startup path semantics.
- `docs/validation/validation_ledger.md`
  - Snapshot updated to `23` pending roadmap validations.
  - `RVP-039` moved to `Closed/OK` with targeted coordinator test evidence.
  - Historical implementation trace anchored to `8174bda` (`Guard paused expiry and remove repo auto-complete`), with startup-zombie exception context from `d8d536c`.
- `docs/roadmap.md`
  - 11/02/2026 activeSession-running + groupId-match line moved from
    `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **17** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`).
- Open historical roadmap queue now: **20**
  (`RVP-040`, `RVP-042`, `RVP-045`..`RVP-062`).

---

## Block 714 — RVP-040 closure: repository read auto-complete removed, expiry owned by coordinator/viewmodel (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-040`) with repository-vs-coordinator enforcement evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-040`

### Test coverage validated

- `test/data/repositories/firestore_task_run_group_repository_test.dart`
  - `repo does NOT complete when activeSession is null`
  - `repo does NOT complete when activeSession is paused`
  - `repo does NOT complete when activeSession is other group`
- `test/data/repositories/local_task_run_group_repository_test.dart`
  - `repo does NOT complete when activeSession is null`
  - `repo does NOT complete when activeSession is paused`
  - `repo does NOT complete when activeSession is other group`
- `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
  - `completes expired running group and unblocks overdue scheduled auto-start`

### Local validation gate

- `flutter test test/data/repositories/firestore_task_run_group_repository_test.dart` -> PASS (`+3`)
- `flutter test test/data/repositories/local_task_run_group_repository_test.dart` -> PASS (`+3`)
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "completes expired running group and unblocks overdue scheduled auto-start"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `22` pending roadmap validations.
  - `RVP-040` moved to `Closed/OK` with repository + coordinator evidence.
  - Historical implementation commit linked:
    - `8174bda` — `Guard paused expiry and remove repo auto-complete`
- `docs/roadmap.md`
  - 11/02/2026 repository auto-complete-on-read removal line moved from
    `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **18** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`).
- Open historical roadmap queue now: **19**
  (`RVP-042`, `RVP-045`..`RVP-062`).

---

## Block 715 — RVP-042 closure: optimistic pending ownership indicator validated (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-042`) with optimistic pending indicator evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-042`

### Test coverage validated

- `test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart`
  - `requestOwnership shows pending immediately`
  - `requestOwnership keeps pending after prior rejection`

### Local validation gate

- `flutter test test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart --plain-name "requestOwnership shows pending immediately"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart --plain-name "requestOwnership keeps pending after prior rejection"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `21` pending roadmap validations.
  - `RVP-042` moved to `Closed/OK` with targeted optimistic-pending evidence.
  - Historical implementation commit linked:
    - `c804582` — `Show pending ownership indicator immediately`
- `docs/roadmap.md`
  - 12/02/2026 optimistic mirror-request indicator line moved from
    `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **19** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`).
- Open historical roadmap queue now: **18**
  (`RVP-045`..`RVP-062`).

---

## Block 716 — RVP-045 closure: ownership indicator syncing variant + control gating validated (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-045`) with Run Mode ownership indicator/gating evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-045`

### Test coverage validated

- `test/presentation/timer_screen_syncing_overlay_test.dart`
  - Added `ownership indicator stays visible with syncing variant and controls gate when session snapshot is missing`
- `test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart`
  - `requestOwnership shows pending immediately`
  - `requestOwnership keeps pending after prior rejection`

### Local validation gate

- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "ownership indicator stays visible with syncing variant and controls gate when session snapshot is missing"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart --plain-name "requestOwnership shows pending immediately"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart --plain-name "requestOwnership keeps pending after prior rejection"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `20` pending roadmap validations.
  - `RVP-045` moved to `Closed/OK` with widget + ViewModel ownership evidence.
  - Historical implementation commit linked:
    - `af5cca7` — `Fix ownership request UX + requestId reconciliation`
- `docs/roadmap.md`
  - 12/02/2026 Run Mode ownership-indicator/manual-sync/control-gating line moved from
    `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **20** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`).
- Open historical roadmap queue now: **17**
  (`RVP-046`..`RVP-062`).

---

## Block 717 — RVP-046 closure: session-missing control gating + sync-then-start + neutral no-session indicator validated (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-046`) with control-gating, auto-start sync-check, and neutral ownership-indicator evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-046`

### Test coverage validated

- `test/presentation/timer_screen_syncing_overlay_test.dart`
  - `ownership indicator stays visible with syncing variant and controls gate when session snapshot is missing`
  - `ownership indicator shows neutral state when no session exists`
- `test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart`
  - `startFromAutoStart syncs first and does not start when another device owns active session`

### Local validation gate

- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "ownership indicator stays visible with syncing variant and controls gate when session snapshot is missing"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "ownership indicator shows neutral state when no session exists"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart --plain-name "startFromAutoStart syncs first and does not start when another device owns active session"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `19` pending roadmap validations.
  - `RVP-046` moved to `Closed/OK` with widget + ViewModel evidence covering all three clauses of the roadmap item.
- `docs/roadmap.md`
  - 12/02/2026 session-missing gating + sync-then-start + neutral no-session indicator line moved from `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **21** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`, `RVP-046`).
- Open historical roadmap queue now: **16**
  (`RVP-047`..`RVP-062`).

---

## Block 718 — RVP-047 closure: sync-gap neutralizes stale mirror/owner derivations validated (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-047`) with sync-gap ownership-neutralization evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-047`

### Test coverage validated

- `test/presentation/timer_screen_syncing_overlay_test.dart`
  - `sync-gap neutralizes stale mirror ownership derivation`
  - `ownership indicator stays visible with syncing variant and controls gate when session snapshot is missing`

### Local validation gate

- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "sync-gap neutralizes stale mirror ownership derivation"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "ownership indicator stays visible with syncing variant and controls gate when session snapshot is missing"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `18` pending roadmap validations.
  - `RVP-047` moved to `Closed/OK` with direct sync-gap neutralization evidence.
- `docs/roadmap.md`
  - 12/02/2026 sync-gap ownership neutralization line moved from `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **22** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`, `RVP-046`, `RVP-047`).
- Open historical roadmap queue now: **15**
  (`RVP-048`..`RVP-062`).

---

## Block 719 — RVP-048 closure: requester pending indicator priority over syncing/no-session visuals validated (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-048`) with requester pending-indicator priority evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-048`

### Test coverage validated

- `test/presentation/timer_screen_syncing_overlay_test.dart`
  - `requester pending indicator overrides syncing and no-session visuals during sync-gap`
  - `sync-gap neutralizes stale mirror ownership derivation`

### Local validation gate

- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "requester pending indicator overrides syncing and no-session visuals during sync-gap"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "sync-gap neutralizes stale mirror ownership derivation"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `17` pending roadmap validations.
  - `RVP-048` moved to `Closed/OK` with requester pending-priority evidence.
- `docs/roadmap.md`
  - 12/02/2026 ownership pending-priority line moved from `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **23** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`, `RVP-046`, `RVP-047`, `RVP-048`).
- Open historical roadmap queue now: **14**
  (`RVP-049`..`RVP-062`).

---

## Block 720 — RVP-049 closure: optimistic pending survives owner->mirror reset without amber flicker (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-049`) with optimistic pending persistence evidence across owner->mirror reset.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-049`

### Test coverage validated

- `test/presentation/timer_screen_syncing_overlay_test.dart`
  - `optimistic pending survives owner-state reset before mirror snapshot`
  - `requester pending indicator overrides syncing and no-session visuals during sync-gap`

### Local validation gate

- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "optimistic pending survives owner-state reset before mirror snapshot"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "requester pending indicator overrides syncing and no-session visuals during sync-gap"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `16` pending roadmap validations.
  - `RVP-049` moved to `Closed/OK` with owner->mirror reset persistence evidence.
- `docs/roadmap.md`
  - 12/02/2026 optimistic owner->mirror reset line moved from `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **24** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`, `RVP-046`, `RVP-047`, `RVP-048`, `RVP-049`).
- Open historical roadmap queue now: **13**
  (`RVP-050`..`RVP-062`).

---

## Block 721 — RVP-050 closure: optimistic pending overrides older rejected snapshots without indicator flicker (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-050`) with stale-rejected snapshot override evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-050`

### Test coverage validated

- `test/presentation/timer_screen_syncing_overlay_test.dart`
  - `optimistic pending overrides stale rejected snapshot from stream`
- `test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart`
  - `requestOwnership keeps pending after prior rejection`

### Local validation gate

- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "optimistic pending overrides stale rejected snapshot from stream"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart --plain-name "requestOwnership keeps pending after prior rejection"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `15` pending roadmap validations.
  - `RVP-050` moved to `Closed/OK` with stale-rejected snapshot override evidence.
- `docs/roadmap.md`
  - 12/02/2026 optimistic-pending-vs-rejected line moved from `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **25** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`, `RVP-046`, `RVP-047`, `RVP-048`, `RVP-049`, `RVP-050`).
- Open historical roadmap queue now: **12**
  (`RVP-051`..`RVP-062`).

---

## Block 722 — RVP-051 closure: optimistic pending survives stale rejected snapshots from other devices (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-051`) with cross-device stale-rejected guard evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-051`

### Test coverage validated

- `test/presentation/timer_screen_syncing_overlay_test.dart`
  - `optimistic pending is not cleared by stale rejected snapshot from another device`
  - `optimistic pending overrides stale rejected snapshot from stream`

### Local validation gate

- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "optimistic pending is not cleared by stale rejected snapshot from another device"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "optimistic pending overrides stale rejected snapshot from stream"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `14` pending roadmap validations.
  - `RVP-051` moved to `Closed/OK` with stale-rejected-other-device evidence.
- `docs/roadmap.md`
  - 12/02/2026 stale-rejected-from-other-devices line moved from `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **26** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`, `RVP-046`, `RVP-047`, `RVP-048`, `RVP-049`, `RVP-050`, `RVP-051`).
- Open historical roadmap queue now: **11**
  (`RVP-052`..`RVP-062`).

---

## Block 723 — RVP-052 closure: local pending gating blocks duplicate request taps during snapshot lag (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-052`) with local-pending request-gating evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-052`

### Test coverage validated

- `test/presentation/timer_screen_syncing_overlay_test.dart`
  - `local pending gating disables duplicate ownership taps while snapshot lags`
  - `optimistic pending is not cleared by stale rejected snapshot from another device`

### Local validation gate

- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "local pending gating disables duplicate ownership taps while snapshot lags"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "optimistic pending is not cleared by stale rejected snapshot from another device"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `13` pending roadmap validations.
  - `RVP-052` moved to `Closed/OK` with duplicate-tap gating evidence.
- `docs/roadmap.md`
  - 12/02/2026 local pending gating + duplicate taps line moved from `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **27** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`, `RVP-046`, `RVP-047`, `RVP-048`, `RVP-049`, `RVP-050`, `RVP-051`, `RVP-052`).
- Open historical roadmap queue now: **10**
  (`RVP-053`..`RVP-062`).

---

## Block 724 — RVP-053 closure: ownership requests carry requestId for optimistic reconciliation (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-053`) with requestId propagation/reconciliation evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-053`

### Test coverage validated

- `test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart`
  - `requestOwnership includes requestId for optimistic reconciliation`
- `test/presentation/timer_screen_syncing_overlay_test.dart`
  - `optimistic pending overrides stale rejected snapshot from stream`

### Local validation gate

- `flutter test test/presentation/viewmodels/pomodoro_view_model_ownership_request_test.dart --plain-name "requestOwnership includes requestId for optimistic reconciliation"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "optimistic pending overrides stale rejected snapshot from stream"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `12` pending roadmap validations.
  - `RVP-053` moved to `Closed/OK` with requestId propagation/reconciliation evidence.
- `docs/roadmap.md`
  - 12/02/2026 requestId reconciliation line moved from `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **28** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`, `RVP-046`, `RVP-047`, `RVP-048`, `RVP-049`, `RVP-050`, `RVP-051`, `RVP-052`, `RVP-053`).
- Open historical roadmap queue now: **9**
  (`RVP-054`..`RVP-062`).

---

## Block 725 — RVP-054 closure: requester pending persists until owner response or competing pending appears (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-054`) with requester-pending lifecycle evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-054`

### Test coverage validated

- `test/presentation/timer_screen_syncing_overlay_test.dart`
  - `requester pending stays active until owner rejection response arrives`
  - `requester pending yields when another device pending request appears`
  - `local pending gating disables duplicate ownership taps while snapshot lags`

### Local validation gate

- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "requester pending stays active until owner rejection response arrives"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "requester pending yields when another device pending request appears"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "local pending gating disables duplicate ownership taps while snapshot lags"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `11` pending roadmap validations.
  - `RVP-054` moved to `Closed/OK` with requester-pending lifecycle evidence.
- `docs/roadmap.md`
  - 12/02/2026 requester pending lifecycle line moved from `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **29** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`, `RVP-046`, `RVP-047`, `RVP-048`, `RVP-049`, `RVP-050`, `RVP-051`, `RVP-052`, `RVP-053`, `RVP-054`).
- Open historical roadmap queue now: **8**
  (`RVP-055`..`RVP-062`).

---

## Block 726 — RVP-055 closure: request action remains AppBar sheet-only in mirror mode (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-055`) with ownership sheet-only request-action evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-055`

### Test coverage validated

- `test/presentation/timer_screen_syncing_overlay_test.dart`
  - `mirror mode shows request action only inside ownership sheet`
  - `local pending gating disables duplicate ownership taps while snapshot lags`

### Local validation gate

- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "mirror mode shows request action only inside ownership sheet"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "local pending gating disables duplicate ownership taps while snapshot lags"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `10` pending roadmap validations.
  - `RVP-055` moved to `Closed/OK` with sheet-only request-action evidence.
- `docs/roadmap.md`
  - 12/02/2026 request-action placement line moved from `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **30** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`, `RVP-046`, `RVP-047`, `RVP-048`, `RVP-049`, `RVP-050`, `RVP-051`, `RVP-052`, `RVP-053`, `RVP-054`, `RVP-055`).
- Open historical roadmap queue now: **7**
  (`RVP-056`..`RVP-062`).

---

## Block 727 — RVP-056 closure: stale pending exposes Retry CTA in ownership sheet (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-056`) with stale-pending retry-CTA placement/behavior evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-056`

### Test coverage validated

- `test/presentation/timer_screen_syncing_overlay_test.dart`
  - `stale pending request shows Retry CTA inside ownership sheet`
  - `mirror mode shows request action only inside ownership sheet`

### Local validation gate

- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "stale pending request shows Retry CTA inside ownership sheet"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "mirror mode shows request action only inside ownership sheet"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `9` pending roadmap validations.
  - `RVP-056` moved to `Closed/OK` with stale-pending retry-CTA evidence.
- `docs/roadmap.md`
  - 12/02/2026 stale pending retry-CTA line moved from `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **31** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`, `RVP-046`, `RVP-047`, `RVP-048`, `RVP-049`, `RVP-050`, `RVP-051`, `RVP-052`, `RVP-053`, `RVP-054`, `RVP-055`, `RVP-056`).
- Open historical roadmap queue now: **6**
  (`RVP-057`..`RVP-062`).

---

## Block 728 — RVP-057 closure: CRITICAL ownership flow stays sheet-only with stable pending lifecycle (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-057`) with integrated ownership-sheet placement + pending-lifecycle evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-057`

### Test coverage validated

- `test/presentation/timer_screen_syncing_overlay_test.dart`
  - `critical ownership flow stays appbar-sheet-only and pending remains stable until owner response`
  - `mirror mode shows request action only inside ownership sheet`
  - `requester pending stays active until owner rejection response arrives`

### Local validation gate

- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "critical ownership flow stays appbar-sheet-only and pending remains stable until owner response"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "mirror mode shows request action only inside ownership sheet"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "requester pending stays active until owner rejection response arrives"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `8` pending roadmap validations.
  - `RVP-057` moved to `Closed/OK` with critical sheet-only + stable-pending evidence.
- `docs/roadmap.md`
  - 12/02/2026 CRITICAL ownership request line moved from `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **32** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`, `RVP-046`, `RVP-047`, `RVP-048`, `RVP-049`, `RVP-050`, `RVP-051`, `RVP-052`, `RVP-053`, `RVP-054`, `RVP-055`, `RVP-056`, `RVP-057`).
- Open historical roadmap queue now: **5**
  (`RVP-058`..`RVP-062`).

---

## Block 729 — RVP-058 closure: rejection clears pending and requestId keys protect re-request flow (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-058`) with reject-clear + requestId anti-suppression evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-058`

### Test coverage validated

- `test/presentation/timer_screen_syncing_overlay_test.dart`
  - `rejection clears local pending and old rejected requestId does not suppress a new request`
  - `requester pending stays active until owner rejection response arrives`

### Local validation gate

- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "rejection clears local pending and old rejected requestId does not suppress a new request"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "requester pending stays active until owner rejection response arrives"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `7` pending roadmap validations.
  - `RVP-058` moved to `Closed/OK` with reject-clear + requestId-keyed anti-suppression evidence.
- `docs/roadmap.md`
  - 12/02/2026 rejection/requestId line moved from `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **33** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`, `RVP-046`, `RVP-047`, `RVP-048`, `RVP-049`, `RVP-050`, `RVP-051`, `RVP-052`, `RVP-053`, `RVP-054`, `RVP-055`, `RVP-056`, `RVP-057`, `RVP-058`).
- Open historical roadmap queue now: **4**
  (`RVP-059`..`RVP-062`).

---

## Block 730 — RVP-060 closure: overlap warning flow validated across mirror CTA + persistent conflict snackbar (01/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-060`) with overlap-warning UX + mirror CTA + persistent snackbar evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-060`

### Test coverage validated

- `test/presentation/timer_screen_completion_navigation_test.dart`
  - `Task List mirror conflict banner shows request ownership CTA and triggers request`
  - `Groups Hub mirror conflict banner shows request ownership CTA and triggers request`
  - `Timer mirror shows persistent conflict snackbar until explicit OK`
- `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
  - `sets running overlap decision before pre-run window when overlap exists`
  - `sets running overlap decision in account mode for non-owner`

### Local validation gate

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Task List mirror conflict banner shows request ownership CTA and triggers request"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Groups Hub mirror conflict banner shows request ownership CTA and triggers request"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Timer mirror shows persistent conflict snackbar until explicit OK"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "sets running overlap decision before pre-run window when overlap exists"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "sets running overlap decision in account mode for non-owner"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `6` pending roadmap validations.
  - `RVP-060` moved to `Closed/OK` with overlap warning + mirror CTA + persistent snackbar evidence.
- `docs/roadmap.md`
  - 18/02/2026 overlap-warning/mirror-CTA/persistent-snackbar line moved from `validation pending` to validated `Closed/OK` on 01/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **34** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`, `RVP-046`, `RVP-047`, `RVP-048`, `RVP-049`, `RVP-050`, `RVP-051`, `RVP-052`, `RVP-053`, `RVP-054`, `RVP-055`, `RVP-056`, `RVP-057`, `RVP-058`, `RVP-060`).
- Open historical roadmap queue now: **3**
  (`RVP-059`, `RVP-061`, `RVP-062`).

---

## Block 731 — RVP-061 closure: postpone-follow overlap flow + paused overlap alert validated (02/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-061`) with postpone-follow and paused-overlap evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-061`

### Test coverage validated

- `test/presentation/timer_screen_completion_navigation_test.dart`
  - `suppresses immediate duplicate running-overlap modal after postpone`
- `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
  - `uses paused session projection to trigger overlap earlier`
  - `does not flag overlap when scheduled group follows running group`

### Local validation gate

- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "suppresses immediate duplicate running-overlap modal after postpone"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "uses paused session projection to trigger overlap earlier"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "does not flag overlap when scheduled group follows running group"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `5` pending roadmap validations.
  - `RVP-061` moved to `Closed/OK` with postpone-follow + paused-overlap evidence.
- `docs/roadmap.md`
  - 19/02/2026 line moved from `validation pending` to validated `Closed/OK` on 02/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **35** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`, `RVP-046`, `RVP-047`, `RVP-048`, `RVP-049`, `RVP-050`, `RVP-051`, `RVP-052`, `RVP-053`, `RVP-054`, `RVP-055`, `RVP-056`, `RVP-057`, `RVP-058`, `RVP-060`, `RVP-061`).
- Open historical roadmap queue now: **2**
  (`RVP-059`, `RVP-062`).

---

## Block 732 — RVP-062 closure: late-start queue owner-only + auto-claim + queue bootstrap validated (02/04/2026)

**Current branch intent:** Historical roadmap validation closure packet continuation (`RVP-062`) with late-start queue ownership and bootstrap evidence.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID closed:** `RVP-062`

### Test coverage validated

- `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`
  - `does not auto-claim late-start queue when heartbeat is missing but anchor is fresh`
  - `auto-claims late-start queue when heartbeat is missing and anchor is stale`
  - `launch catch-up auto-starts overdue scheduled group and emits openTimer action`
  - `resume catch-up starts overdue scheduled group once timeSync becomes available in account mode`
- `test/presentation/utils/scheduled_group_timing_test.dart`
  - `excludes queue-confirmed anchored groups from overdue detection`

### Local validation gate

- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "does not auto-claim late-start queue when heartbeat is missing but anchor is fresh"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "auto-claims late-start queue when heartbeat is missing and anchor is stale"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "launch catch-up auto-starts overdue scheduled group and emits openTimer action"` -> PASS (`+1`)
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart --plain-name "resume catch-up starts overdue scheduled group once timeSync becomes available in account mode"` -> PASS (`+1`)
- `flutter test test/presentation/utils/scheduled_group_timing_test.dart --plain-name "excludes queue-confirmed anchored groups from overdue detection"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - Snapshot updated to `4` pending roadmap validations.
  - `RVP-062` moved to `Closed/OK` with late-start queue owner-only + bootstrap evidence.
- `docs/roadmap.md`
  - 20/02/2026 line moved from `validation pending` to validated `Closed/OK` on 02/04/2026.

### Status after this block

- Closed roadmap validations in this packet: **36** (`RVP-021`..`RVP-031`, `RVP-034`, `RVP-035`, `RVP-036`, `RVP-037`, `RVP-038`, `RVP-039`, `RVP-040`, `RVP-042`, `RVP-045`, `RVP-046`, `RVP-047`, `RVP-048`, `RVP-049`, `RVP-050`, `RVP-051`, `RVP-052`, `RVP-053`, `RVP-054`, `RVP-055`, `RVP-056`, `RVP-057`, `RVP-058`, `RVP-060`, `RVP-061`, `RVP-062`).
- Open historical roadmap queue now: **1**
  (`RVP-059`).

---

## Block 733 — RVP-059 fix applied: reject-dismiss survives requestId materialization (local PASS, device validation pending) (02/04/2026)

**Current branch intent:** Historical roadmap validation packet final item (`RVP-059`) moved to in-validation after exact-repro fix.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation ID status:** `RVP-059` -> `In validation`

### Runtime fix

- `lib/presentation/screens/timer_screen.dart`
  - `_isDismissedOwnershipRequest(...)` now keeps dismissal continuity when a pending owner request is first dismissed without `requestId` and later re-ingested with materialized `requestId`, by honoring requester fallback as well as requestId match.

### Test coverage validated

- `test/presentation/timer_screen_syncing_overlay_test.dart`
  - Added exact-repro regression test:
    `owner reject dismissal stays hidden when pending request gets requestId materialized`
  - Regression smoke:
    `critical ownership flow stays appbar-sheet-only and pending remains stable until owner response`
    `rejection clears local pending and old rejected requestId does not suppress a new request`

### Local validation gate

- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "owner reject dismissal stays hidden when pending request gets requestId materialized"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "critical ownership flow stays appbar-sheet-only and pending remains stable until owner response"` -> PASS (`+1`)
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart --plain-name "rejection clears local pending and old rejected requestId does not suppress a new request"` -> PASS (`+1`)
- `flutter analyze` -> PASS (`No issues found!`)

### Documentation synchronization

- `docs/validation/validation_ledger.md`
  - `RVP-059` moved from `Pending` to `In validation` with local PASS evidence and device-validation blocker.
- `docs/roadmap.md`
  - 12/02/2026 line updated from `validation pending` to `validation in progress` (local PASS, device pending).

### Device validation policy (owner-approved)

- If real-device validation reveals regression, rollback to pre-fix state and keep this issue as observation (do not close `RVP-059`).

### Status after this block

- Closed roadmap validations in this packet: **36**.
- Open historical roadmap queue now: **1** (`RVP-059`, in validation pending real-device confirmation).

---

## Block 734 — BUG-024 formalized with validation packet (02/04/2026)

**Current branch intent:** Convert RVP-059 repro into formal bug-validation workflow artifact and keep status in validation until real-device confirmation.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation/Bug IDs:** `RVP-059` (`In validation`), `BUG-024` (`In validation`)

### Documentation-first bug workflow synchronization

- `docs/bugs/bug_log.md`
  - Registered `BUG-024` with confirmed root cause, runtime fix scope, local evidence, and device-validation pending status.
- `docs/bugs/validation_bug024_2026_04_02/`
  - Created required packet structure:
    - `plan_validacion_rapida_fix.md`
    - `quick_pass_checklist.md`
    - `logs/`
    - `screenshots/`
- `docs/validation/validation_ledger.md`
  - Added explicit `BUG-024` entry (`In validation`) to mirror non-closed bug log status.
  - Updated active bug-log snapshot count from `0` to `1`.
- `docs/roadmap.md`
  - RVP-059 line kept as `validation in progress` (local PASS, device pending).

### Local evidence captured in packet logs

- Exact repro test PASS:
  - `owner reject dismissal stays hidden when pending request gets requestId materialized`
- Regression smoke PASS:
  - `critical ownership flow stays appbar-sheet-only and pending remains stable until owner response`
  - `rejection clears local pending and old rejected requestId does not suppress a new request`
- `flutter analyze` PASS.
- Logs saved under:
  - `docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_widget_exact_repro_debug.log`
  - `docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_widget_regression_critical_debug.log`
  - `docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_widget_regression_requestid_debug.log`
  - `docs/bugs/validation_bug024_2026_04_02/logs/2026-04-02_bug024_pending-local_analyze.log`

### Status after this block

- `BUG-024`: **In validation** (local PASS; device validation pending).
- `RVP-059`: **In validation** (depends on BUG-024 device validation outcome).

---

## Block 735 — BUG-024 validation workflow compliance audit (02/04/2026)

**Current branch intent:** Keep BUG-024 / RVP-059 in strict bug-validation workflow and fix traceability mismatches only.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation/Bug IDs:** `BUG-024` (`In validation`), `RVP-059` (`In validation`)

### Compliance audit performed

- Mandatory preflight docs re-read completed in this session:
  - `CLAUDE.md`
  - `docs/specs.md`
  - `docs/roadmap.md`
  - `docs/dev_log.md`
  - `docs/bugs/bug_log.md`
  - `docs/validation/validation_ledger.md`
- Date verification executed: `Thu Apr  2 16:58:27 CEST 2026`.
- Validation packet structure check for `docs/bugs/validation_bug024_2026_04_02/`:
  - `plan_validacion_rapida_fix.md` present with all mandatory sections.
  - `quick_pass_checklist.md` present with required checkbox-only sections.
  - `logs/` and `screenshots/` present.
  - No extra markdown artifacts found.

### Corrections applied

- `docs/validation/validation_ledger.md`
  - `BUG-024` source line reference corrected:
    - `docs/bugs/bug_log.md:3245` -> `docs/bugs/bug_log.md:3261`
  - `RVP-059` roadmap source line reference corrected:
    - `docs/roadmap.md:420` -> `docs/roadmap.md:421`

### Status after this block

- `BUG-024`: **In validation** (unchanged; local PASS, device validation pending).
- `RVP-059`: **In validation** (unchanged; depends on BUG-024 device validation).

---

## Block 736 — BUG-024 / RVP-059 closed after real-device validation PASS (02/04/2026)

**Current branch intent:** Close BUG-024 and RVP-059 with full documentation synchronization after device PASS confirmation.
**Branch:** `validation-rvp021-028-sync`
**Commit:** `pending-local`
**Validation/Bug IDs:** `BUG-024` (`Closed/OK`), `RVP-059` (`Closed/OK`)

### Validation closure recap (user-confirmed)

- Scenario A PASS (Android owner + macOS mirror):
  - ownership request reject flow validated without banner reappearance after requestId materialization path.
- Scenario B PASS:
  - ownership request lifecycle remained stable (sheet CTA, pending until owner response, reject path clear).
- Scenario C PASS:
  - closure packet criteria validated in the same real-device run, no regressions observed.

### Documentation synchronization

- `docs/bugs/validation_bug024_2026_04_02/quick_pass_checklist.md`
  - device checkboxes completed (A/B/C closure path).
- `docs/bugs/validation_bug024_2026_04_02/plan_validacion_rapida_fix.md`
  - device verification section added.
  - status updated to `Closed/OK`.
- `docs/bugs/bug_log.md`
  - `BUG-024` status updated from `In validation` to `Closed/OK` with device PASS evidence.
- `docs/validation/validation_ledger.md`
  - snapshot updated:
    - roadmap pending count `4` -> `3` (IDEA backlog only)
    - active non-closed bug count `1` -> `0`
  - `BUG-024` and `RVP-059` entries moved to `Closed/OK` with closure evidence.
- `docs/roadmap.md`
  - 12/02/2026 ownership-dismiss line updated to validated `RVP-059 Closed/OK`.

### Status after this block

- `BUG-024`: **Closed/OK** (02/04/2026, real-device PASS confirmed).
- `RVP-059`: **Closed/OK** (02/04/2026, synchronized with BUG-024 closure).

---

## Block 737 — BUG-025 overlap-boundary fix packaged for device validation (03/04/2026)

**Current branch intent:** BUG-025 runtime fix validation packet + ledger synchronization before device verification.
**Branch:** `fix/overlap-threshold-exact`
**Commits:** `0a1ea3a`, `547de2b`
**Bug status:** `BUG-025` / `BUGLOG-025` moved to **In validation**

### Context

A regression was reported in running-overlap warning behavior:

- conflict warning could fail at the exact boundary in paused scenarios,
- TimerScreen entry/re-entry could miss an already-active overlap decision.

### Implemented runtime scope

- `0a1ea3a` `fix(overlap): trigger running overlap exactly at pre-run boundary`
  - Removed +1 minute grace from running-overlap threshold.
  - Updated specs timing wording to exact boundary.
  - Added boundary regression tests in timing + coordinator suites.
- `547de2b` `fix(timer): consume existing running-overlap decision on run mode mount`
  - Unified decision consumption path in TimerScreen.
  - Added mount/re-entry post-frame consumption for active decisions.
  - Added widget regression for decision already active on TimerScreen mount.

### Validation packet opened

- `docs/bugs/validation_bug025_2026_04_03/plan_validacion_rapida_fix.md`
- `docs/bugs/validation_bug025_2026_04_03/quick_pass_checklist.md`
- Folders prepared: `logs/`, `screenshots/`

### Documentation synchronization

- Added `BUG-025` entry to `docs/bugs/bug_log.md` with root cause + applied commits.
- Added `BUGLOG-025` to `docs/validation/validation_ledger.md` as `In validation` (P1).
- Snapshot updated to reflect one active non-closed bug-log entry.

### Status after this block

- `BUG-025` / `BUGLOG-025`: **Closed/OK** (device validation PASS 03/04/2026, scenarios A-D). Owner explicit closure confirmation recorded.

---

## Block 738 — IDEA-039 implementation completed, merged into develop (03/04/2026)

**Current branch intent:** IDEA-039 implementation + validation synchronization.
**Branch:** `feature/idea039-conflict-explainer`
**Commits:** `d336179`, `0cadda4`, `ecbd366`, `81de9e2`
**Item:** `IDEA-039` (P1 feature)

### Implementation delivered

- Extracted shared conflict helpers (`scheduling_conflict_helpers.dart`) from Task List legacy flow.
- Migrated `TaskGroupPlanningScreen` to `ConsumerStatefulWidget` for live provider-driven conflict evaluation.
- Added inline conflict indicator + Confirm gating in Plan Group for scheduled options.
- Added unified conflict modal with running/scheduled badges and multi-selection.
- Added transactional intent propagation (`pendingCancelIds`, `pendingDeleteIds`) in planning result.
- Removed Task List legacy conflict dialogs; destructive actions now applied after successful new-group save.

### Validation updates

- Added targeted widget coverage (`test/presentation/task_group_planning_screen_conflict_test.dart`):
  - inline conflict indicator + disabled Confirm
  - race guard → scheduled pending delete accumulation
  - race guard → running pending cancel accumulation
- Local gate PASS: `flutter analyze` + full test suite.

### Status after this block

- `IDEA-039`: **Merged into develop** (03/04/2026). Device validation pending (IDEA-039 device scenarios).

---

## Block 739 — BUG-026 closed after full validation + user confirmation (24/04/2026)

**Current branch intent:** Close BUG-026 documentation and ledger state after user-confirmed PASS evidence.
**Branch:** `fix/bug026-owner-autostart-routing`
**Commit:** `819745c`
**Validation/Bug IDs:** `BUG-026` / `BUGLOG-026` (`Closed/OK`)

### Validation recap (user run + local gate)

- Scenario A PASS (Android owner): Start now auto-opened Timer and stayed stable (no `/timer -> /tasks|/groups` rebound).
- Scenario B PASS (macOS mirror): syncing hold recovered normally; no inert/looped navigation behavior reported.
- Scenario C PASS: cancel returned once to Groups Hub (fluid, no loops).
- Scenario D PASS: stale canceled mismatch no longer navigates away; focused stale-cancel test no longer hangs.

### Local verification commands executed

- `flutter analyze` -> PASS (`No issues found!`).
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> PASS (`+37`).
- `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` -> PASS (`+19`).
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Timer ignores stale canceled vm group when displayed group id differs"` -> PASS.

### Documentation synchronization

- `docs/bugs/bug_log.md`
  - `BUG-026` moved to `Closed/OK` with fix summary, validation recap, and evidence references.
- `docs/validation/validation_ledger.md`
  - Snapshot updated to 2026-04-24.
  - Active non-closed bug count updated `4 -> 3`.
  - Active P1 bug list updated (`BUGLOG-026` removed; `BUGLOG-028` remains).
  - `BUGLOG-026` moved `Pending -> Closed/OK` with evidence and closure metadata.
- `docs/bugs/validation_bug026_2026_04_03/plan_validacion_rapida_fix.md`
  - Status updated to `Closed/OK (2026-04-24, user-confirmed)`.
- `docs/bugs/validation_bug026_2026_04_03/quick_pass_checklist.md`
  - All closure checkboxes already marked PASS.

### Status after this block

- `BUG-026` / `BUGLOG-026`: **Closed/OK** (`819745c`, 24/04/2026, user-confirmed).
- Open bug queue: `BUGLOG-028` (P1), `BUGLOG-027` (P2), `BUGLOG-029` (P2).

---

## Block 740 — BUG-028 runtime patch implemented, moved to In validation (24/04/2026)

**Current branch intent:** Fix Groups Hub paused `Ends` projection coherence and open validation packet for BUG-028.
**Branch:** `fix/bug028-paused-ends-projection`
**Commit:** `pending-local`
**Validation/Bug IDs:** `BUG-028` / `BUGLOG-028` (`In validation`)

### Implementation delivered

- Updated `GroupsHub` running card `Ends` projection to use `resolveProjectedRunningEnd(...)`
  for running/paused groups.
- Preserved scheduled card override behavior and existing card rendering semantics.
- Added widget regression coverage:
  - `Groups Hub paused running card updates Ends projection in real time`
  - Existing smoke `Groups Hub core sections and actions are visible` rerun PASS.
- Specs synchronized first:
  - `docs/specs.md` section 10.5 now explicitly states projected `Ends` behavior
    for running/paused cards while paused.

### Local verification commands executed

- `flutter analyze` -> PASS (`No issues found!`).
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Groups Hub paused running card updates Ends projection in real time"` -> PASS.
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart --plain-name "Groups Hub core sections and actions are visible"` -> PASS.

### Validation packet opened

- `docs/bugs/validation_bug028_2026_04_24/plan_validacion_rapida_fix.md`
- `docs/bugs/validation_bug028_2026_04_24/quick_pass_checklist.md`
- `docs/bugs/validation_bug028_2026_04_24/logs/`
- `docs/bugs/validation_bug028_2026_04_24/screenshots/`

### Documentation synchronization

- `docs/bugs/bug_log.md`
  - `BUG-028` updated with fix description and moved from `Open` to `In validation`.
- `docs/validation/validation_ledger.md`
  - Snapshot updated: `BUGLOG-028` moved `Pending -> In validation`.
  - `BUGLOG-028` entry now references validation packet + local gate evidence logs.

### Status after this block

- `BUG-028` / `BUGLOG-028`: **In validation** (24/04/2026).
- Local gate PASS; Android + macOS exact-repro validation pending.

---

## Block 741 — BUG-028 closure sync finalized (28/04/2026)

**Current branch intent:** Close BUG-028 packet and align bug queue status on canonical branch.
**Branch:** `fix/bug028-closure-sync`
**Commit:** `05b1001` (implementation), closure sync 28/04/2026
**Validation/Bug IDs:** `BUG-028` / `BUGLOG-028` (`Closed/OK`)

### Closure evidence synchronized

- Validation packet marked `Closed/OK` with owner+mirror evidence from 27/04:
  - `docs/bugs/validation_bug028_2026_04_24/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug028_2026_04_24/quick_pass_checklist.md`
- Bug log updated to `Closed/OK` with implementation commit + device evidence references.
- Validation ledger updated to `Closed/OK` and snapshot queue adjusted.

### Status after this block

- `BUG-028` / `BUGLOG-028`: **Closed/OK** (`05b1001`).
- Open bug queue continues with: `BUGLOG-027` (P2), `BUGLOG-029` (P2).

---

## Block 742 — BUG-032 Phase 1 coordinator guard implemented and moved to validation (29/04/2026)

**Current branch intent:** BUG-032 paused-session expiry regression hardening (minimal-risk Phase 1 coordinator guard + targeted tests + validation packet sync).
**Branch:** `fix/bug032-paused-session-expiry-guard`
**Commit:** `pending-local` (rebased over updated develop)
**Validation/Bug IDs:** `BUG-032` / `BUGLOG-032` (`In validation`)

### Context

Regression report showed a paused run being marked `completed` after ownership transfer caused by owner sleep/background and later reopen.  
Expected behavior per specs: paused sessions must not advance and must not be auto-completed by running-expiry reconciliation.

### Implementation delivered (Phase 1 only)

- Updated `lib/presentation/viewmodels/scheduled_group_coordinator.dart`.
- In `activeSession == null` running-expiry path, coordinator now corroborates server session before completion:
  - fetches `fetchSession(preferServer: true)`,
  - suppresses completion when server session exists, is active execution, and belongs to one of current running groups.
- Legitimate zombie-run completion path remains enabled when no relevant server session exists.
- Removed previously introduced startup-window gating to keep patch minimal and avoid architecture-side regressions.

### Test updates

- Updated `test/presentation/viewmodels/scheduled_group_coordinator_test.dart`:
  - Added guard test: null stream + paused server session for same group -> must not complete.
  - Added foreign-session test: null stream + server session for another group -> legitimate completion still allowed.
  - Removed startup-window-specific test after simplifying implementation.

### Local verification

- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` -> PASS (`All tests passed!`).
- `flutter analyze` -> PASS (`No issues found!`).

### Documentation synchronization

- Added new bug entry: `BUG-032` in `docs/bugs/bug_log.md` with evidence, root cause, and fix summary.
- Added ledger entry: `BUGLOG-032` as `In validation` in `docs/validation/validation_ledger.md`.
- Updated ledger snapshot counts and active P1 bug list.
- Opened validation packet:
  - `docs/bugs/validation_bug032_2026_04_28/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug032_2026_04_28/quick_pass_checklist.md`
  - `docs/bugs/validation_bug032_2026_04_28/logs/`
  - `docs/bugs/validation_bug032_2026_04_28/screenshots/`

### Status after this block

- `BUG-032` / `BUGLOG-032`: **In validation** (Phase 1 implemented, local gate PASS, device exact repro pending).

---

## Block 743 — BUG-032 closed after single-run device validation (29/04/2026)

**Current branch intent:** Close BUG-032 with exact sleep/takeover/pause repro evidence and sync canonical docs.
**Branch:** `fix/bug032-paused-session-expiry-guard`
**Commit:** `69472d7` (runtime fix)
**Validation/Bug IDs:** `BUG-032` / `BUGLOG-032` (`Closed/OK`)

### Validation recap (device + server corroboration)

- Single-run short repro executed in Account Mode using real macOS sleep (lid close) + Android takeover + pause + background past theoretical end.
- Android reopen stayed paused (`Resume` available), with no `completed` transition in Timer/Groups Hub.
- macOS post-wake logs repeatedly confirmed:
  - `ExpiryCheck][skip-expiry-session-not-running` with `sessionStatus=paused`
  - `RepoNormalize][skip-complete` for group `a4d46289-18b7-45d1-b8e2-486036a5daff` after `theoreticalEndTime=2026-04-29 12:23:22.709404`
  - no `mark-running-group-completed` for this group.
- Firestore post-wake `activeSession` remained non-terminal:
  - `status=paused`
  - `ownerDeviceId=android-029abc12-52ba-4d42-bcca-eda2aaaf257e`
  - `remainingSeconds=722`
  - `lastUpdatedAt=2026-04-29 12:43:52` (UTC-4).

### Documentation synchronization

- `docs/bugs/validation_bug032_2026_04_28/plan_validacion_rapida_fix.md`
  - Status moved to `Closed/OK`; evidence section updated with final logs/screenshots + Firestore snapshot.
- `docs/bugs/validation_bug032_2026_04_28/quick_pass_checklist.md`
  - Exact repro checklist marked PASS.
- `docs/bugs/bug_log.md`
  - BUG-032 moved from `In validation` to `Closed/OK` with final device/server evidence.
- `docs/validation/validation_ledger.md`
  - `BUGLOG-032` moved to `Closed/OK`; snapshot updated (`non-closed bugs: 2`, active P1: none).

### Status after this block

- `BUG-032` / `BUGLOG-032`: **Closed/OK** (29/04/2026).
- Remaining open bug queue: `BUGLOG-027` (P2), `BUGLOG-029` (P2).

---

## Block 744 — Always-on integration gate enforced for all agents (29/04/2026)

**Current branch intent:** Process hardening to prevent validated fixes/features from being left only in side branches.
**Branch:** `fix/process-always-on-integration-gate`
**Commits:** `e6574ff` (`docs(process): add strict integration gate command and audit checklist`) + `4a0b68c` (`docs(process): enforce always-on integration gate for all agents`)
**Scope:** governance/process (`AGENTS.md`)

### Rule change

- Upgraded strict integration gate from owner-triggered mode to **always-on mandatory**.
- The rule now applies automatically to every agent (Codex, Claude, Gemini, or future agents) with no user reminder required.
- Added mandatory post-closure integration steps:
  - merge validated work into `develop`,
  - push `develop` to `origin`,
  - verify `develop...origin/develop = 0 0`,
  - verify closure commit is contained in `develop`,
  - only then continue with new work.

### Status after this block

- Integration-safety process is now explicit, automatic, and auditable in system rules.

---

## Block 745 — BUG-030 documentary backfill synchronized on develop (29/04/2026)

**Current branch intent:** Restore BUG-030 closure traceability on canonical docs after runtime/test cherry-pick integration.
**Branch:** `fix/bug030-docs-backfill`
**Commit:** `7f15f66` (`docs(bug030): backfill closure packet and canonical traceability`)
**Validation/Bug IDs:** `BUG-030` / `BUGLOG-030` (`Closed/OK`)

### Audit result confirmed

- Runtime and test restoration for BUG-030 were already in `develop`:
  - `30be006` (`fix(bug030): preserve intentional-departure suppression and add regression test`)
  - `825c09c` (`test(bug030): make vmSub close idempotent in BUG-030 case`)
- Documentation closure artifacts were missing from canonical docs (`bug_log`, `validation_ledger`, and validation packet files).

### Documentation synchronization completed

- `docs/bugs/bug_log.md`
  - Added BUG-030 entry (regression context, root cause, fix, evidence, Closed/OK status).
- `docs/bugs/validation_bug030_2026_04_27/`
  - Added missing `plan_validacion_rapida_fix.md`.
  - Added missing `quick_pass_checklist.md`.
  - Existing iOS/Chrome logs kept as closure evidence.
- `docs/validation/validation_ledger.md`
  - Added `BUGLOG-030` as `Closed/OK` in active bug queue.
  - Snapshot line updated to include BUG-030 among closed IDs.

### Status after this block

- BUG-030 is now fully traceable in canonical docs on top of already integrated runtime/test fixes.
- Active open bug queue remains: `BUGLOG-027` (P2), `BUGLOG-029` (P2).

---

## Block 746 — BUG-031 and BUG-033 canonical traceability synchronized on develop (29/04/2026)

**Current branch intent:** Documentation governance — synchronize missing bug entries to develop so next agent preflight scan finds all open items.
**Branch:** `fix/docs-sync-031-033`
**Commit:** `e0b2f9f` (`docs(trazabilidad): sync BUG-031/033 canonical docs and fix pending-local markers`)
**Validation/Bug IDs:** `BUG-031` / `BUGLOG-031` (`In validation`); `BUG-033` / `BUGLOG-033` (`Open`)

### Context

BUG-031 and BUG-033 were discovered and documented exclusively in side branches:

- `fix/bug031-stale-conflict-snackbar-base030` (fix implemented, local gate PASS, device validation pending)
- `fix/bug033-foreground-service-crash` (crash registered, no fix yet)

Neither entry existed in `develop` canonical docs, so agent preflight scans of `bug_log.md` and `validation_ledger.md` would miss them entirely.

### Documentation synchronized

- `docs/bugs/bug_log.md`
  - Added BUG-031 entry (symptom, fix applied on branch, In validation status).
  - Added BUG-033 entry (crash evidence, hypothesis, Open status).
- `docs/bugs/validation_bug033_2026_04_29/`
  - Added `plan_validacion_rapida_fix.md` (scenarios A+B, log commands, closure criteria).
  - Added `quick_pass_checklist.md`.
- `docs/validation/validation_ledger.md`
  - Snapshot line updated: 4 non-closed bugs (BUGLOG-027 P2, BUGLOG-029 P2, BUGLOG-031 P2, BUGLOG-033 P1).
  - Active P1 blocker updated: `BUGLOG-033` blocks `develop→main`.
  - Added BUGLOG-031 entry (In validation, branch + commit reference).
  - Added BUGLOG-033 entry (Open, P1 blocker).
- `docs/dev_log.md`
  - Replaced `pending-local` in Block 744 with real commits `e6574ff` + `4a0b68c`.
  - Replaced `pending-local` in Block 745 with real commit `7f15f66`.

### Status after this block

- All open bugs visible from `develop` canonical docs.
- Next agent preflight will correctly surface: BUGLOG-033 (P1, Open, no fix yet) and BUGLOG-031 (P2, In validation, device validation pending).
- BUG-031 runtime fix remains isolated on `fix/bug031-stale-conflict-snackbar-base030` until device validation PASS.

---

## Block 747 — BUG log ordering normalized (`BUG-031` before `BUG-032`) (30/04/2026)

**Current branch intent:** Documentation hygiene — preserve deterministic bug block ordering in canonical `bug_log.md`.
**Branch:** `fix/docs-buglog-order-031-032`
**Commit:** `0773f87`
**Validation/Bug IDs:** `BUG-031` (`In validation`), `BUG-032` (`Closed/OK`)

### Context

- The canonical bug log listed `BUG-032` before `BUG-031`, breaking the expected numeric block order and making manual review/navigation harder during multi-branch merges.

### Documentation synchronization completed

- `docs/bugs/bug_log.md`
  - Reordered adjacent blocks so `BUG-031` appears before `BUG-032`.
  - No content/status/evidence changes inside either bug entry.

### Status after this block

- Canonical bug log order is now consistent for the `BUG-03x` sequence.
- Bug statuses remain unchanged:
  - `BUG-031`: In validation (runtime fix still on branch `fix/bug031-stale-conflict-snackbar-base030`).
  - `BUG-032`: Closed/OK.

---

## Block 748 — BUG-031 closed after iOS+Chrome device validation (30/04/2026)

**Current branch intent:** Close BUG-031 with exact owner/mirror repro evidence and synchronize canonical closure docs before integration.
**Branch:** `fix/bug031-validate-on-develop`
**Commit:** `a4a929a`
**Validation/Bug IDs:** `BUG-031` / `BUGLOG-031` (`Closed/OK`)

### Validation recap (owner/mirror)

- Device topology: iOS (`iPhone 17 Pro`) as owner + Chrome (`localhost:5001`) as mirror.
- Scenario A PASS:
  - owner running `G1`, mirror in Run Mode, overlap conflict triggered after owner pause.
  - conflict UX appeared correctly on both devices.
- Scenario B PASS:
  - owner selected `Postpone` at 15:49:46.
  - schedule shifted from 16:02 to 16:03 (pre-run 16:02), and mirror stale warning cleared.
- Scenario C PASS:
  - mirror navigated Run Mode -> Groups Hub -> Task List -> Run Mode without stale conflict warning reappearing.

### Evidence and docs synchronization

- `docs/bugs/validation_bug031_2026_04_28/plan_validacion_rapida_fix.md`
  - Status moved to `Closed/OK`; A/B/C timeline + evidence files recorded.
- `docs/bugs/validation_bug031_2026_04_28/quick_pass_checklist.md`
  - Scenario A/B/C checkboxes marked PASS.
- `docs/bugs/bug_log.md`
  - BUG-031 moved from `In validation` to `Closed/OK` with closure evidence.
- `docs/validation/validation_ledger.md`
  - `BUGLOG-031` moved to `Closed/OK` with closure hash `f2005cc`.
  - Snapshot updated: non-closed bug-log entries reduced from 4 to 3.
- `docs/roadmap.md`
  - Historical timeline updated with BUG-031 closure note (30/04/2026).

### Integration note — pre-rule exception

- Integration path: local `git merge fix/bug031-validate-on-develop` into `develop` (commit `0fa553e`), then push to `origin/develop`.
- `fix/bug031-validate-on-develop` was never pushed to `origin`; no GitHub PR was opened for this merge.
- This predates the PR-first rule (Block 749 / R-9 in `CLAUDE.md`). Not a P0 emergency — a process gap identified retroactively. Rule applies from Block 749 forward.

### Status after this block

- `BUG-031` / `BUGLOG-031`: **Closed/OK** (30/04/2026).
- Active non-closed bug queue: `BUGLOG-033` (P1 Open), `BUGLOG-027` (P2 Pending), `BUGLOG-029` (P2 Pending).

---

## Block 749 — PR-first integration rule for existing origin branches (30/04/2026)

**Current branch intent:** Process governance hardening for branch integration traceability.
**Branch:** `fix/process-pr-origin-branch-gate`
**Commit:** `387cf93`
**Scope:** documentation/process (`AGENTS.md`, `docs/validation/validation_ledger.md`)

### Context

- A closure can be technically integrated into `develop` via local merges, but when the same working branch already exists in `origin`, PR traceability is stronger and review/audit history is clearer.
- The project needed an explicit rule to avoid ambiguity between "works technically" and "follows canonical integration workflow".

### Rule update

- Added PR-first rule in `AGENTS.md`:
  - if a scope already has a remote branch in `origin`, continue there and push first;
  - for non-P0, merge path to `develop` must be via GitHub PR from that branch;
  - direct merge/push to `develop` without PR is limited to emergency P0 mitigation with explicit dev-log justification.
- Added matching safety bullets in `docs/validation/validation_ledger.md` under branch integration safety.

### Status after this block

- Project workflow now explicitly distinguishes:
  - standard path: branch push + PR + merge to `develop`;
  - emergency path: P0 direct merge with mandatory written justification.

---

## Block 750 — BUG-033 registration from Android crash evidence (29/04/2026)

**Current branch intent:** Register Android foreground-service crash as independent bug and open validation packet without mixing BUG-032 scope.
**Branch:** `fix/bug033-foreground-service-crash`
**Commit:** `5b9d85c`
**Validation/Bug IDs:** `BUG-033` / `BUGLOG-033` (`In validation`)

### Evidence captured

- Android runtime log reports:
  - `FATAL EXCEPTION: main`
  - `ForegroundServiceStartNotAllowedException`
  - `Service.startForeground() not allowed due to mAllowStartForeground false`
- Stacktrace points to:
  - `PomodoroForegroundService.onStartCommand(...)`
  - `startOrUpdate()`
  - `startForeground(...)`
- User screenshot captured Android system crash dialog (`focus_interval sigue sin funcionar`).

### Documentation synchronization

- `docs/bugs/bug_log.md`
  - Added `BUG-033` as open bug with captured evidence and initial hypothesis.
- `docs/validation/validation_ledger.md`
  - Snapshot updated to 2026-04-29.
  - Active non-closed bug count updated (`2 -> 3`).
  - Active P1 list updated (`BUGLOG-033`).
  - Added `BUGLOG-033` entry as `In validation`.
- Validation packet opened:
  - `docs/bugs/validation_bug033_2026_04_29/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug033_2026_04_29/quick_pass_checklist.md`
  - `docs/bugs/validation_bug033_2026_04_29/logs/`
  - `docs/bugs/validation_bug033_2026_04_29/screenshots/`

### Status after this block

- `BUG-033` / `BUGLOG-033`: **In validation**.
- Forced same-conditions repro is explicitly pending and documented as next mandatory step.

---

## Block 751 — BUG-033 rolling monitor protocol activated after long non-repro run (01/05/2026)

**Current branch intent:** Keep BUG-033 active in parallel while other bugs continue, with deterministic per-session capture protocol and persistent traceability.
**Branch:** `fix/bug033-foreground-service-crash`
**Commit:** `cd4e5da`
**Validation/Bug IDs:** `BUG-033` / `BUGLOG-033` (`In validation`)

### Validation run recap (today)

- Session window: **13:05 -> 14:35 EDT** (Android app in background under memory pressure workload).
- Dual capture was executed (Flutter + app-focused logcat).
- Result: **non-repro** for BUG-033 in this run.
  - No `ForegroundServiceStartNotAllowedException` for `com.marcdevelopez.focusinterval`.
  - No `FATAL EXCEPTION` attributable to Focus Interval process in app-focused logcat.
- Parallel signal observed:
  - repeated network/DNS unavailability (`Unable to resolve host firestore.googleapis.com`) during long background window; tracked as separate runtime condition (not closure for BUG-033).

### Documentation synchronization

- `docs/bugs/validation_bug033_2026_04_29/plan_validacion_rapida_fix.md`
  - Added Scenario C (rolling monitor).
  - Added exact reusable per-session commands (`adb logcat` + `flutter run` in `APP_ENV=prod`).
  - Added execution history entry for 01/05/2026 non-repro run and evidence file references.
- `docs/bugs/validation_bug033_2026_04_29/quick_pass_checklist.md`
  - Marked Scenario C execution as PASS for non-repro capture.
  - Added explicit rolling monitor readiness checkbox.
- `docs/bugs/bug_log.md`
  - BUG-033 status moved from `Open` to `In validation`.
  - Added 01/05/2026 non-repro evidence and rolling monitor note.
- `docs/validation/validation_ledger.md`
  - Snapshot updated to 2026-05-01.
  - BUGLOG-033 evidence expanded with non-repro run outcome and rolling monitor requirement.

### Status after this block

- `BUG-033` / `BUGLOG-033`: **In validation**.
- Required operating mode: keep dual-capture protocol available in each session while parallel fixes continue on `BUGLOG-027` and `BUGLOG-029`.

---

## Block 752 — BUG-027 context propagation implemented and moved to validation (01/05/2026)

**Current branch intent:** Implement BUG-027 root fix (shared conflict context + range-aware copy) and open formal device validation packet.
**Branch:** `fix/bug033-foreground-service-crash`
**Commit:** `8600f44`
**Validation/Bug IDs:** `BUG-027` / `BUGLOG-027` (`In validation`)

### Context

- BUG-027 reported that conflict messaging lacked actionable context (blocker identity + compared ranges) across planning/runtime/mirror surfaces.
- Root cause confirmed: copy and context assembly were fragmented per-screen, while overlap decision payload carried only IDs.

### Implementation summary

- Added shared context model/formatters in `lib/presentation/utils/scheduling_conflict_helpers.dart`:
  - `ConflictWindow`, `PreRunConflict`, `RunningOverlapContext`
  - `resolveConflictWindow`, `resolveRunningOverlapContext`
  - shared time/range summary formatters.
- Updated `GroupsHubScreen` conflict flows:
  - running conflict modal now includes selected range + running blockers (name/range),
  - scheduled conflict modal now includes selected range + scheduled blockers (name/range),
  - pre-run conflict snackbar now includes blocker context + candidate pre-run window.
- Updated mirror conflict surfaces:
  - Task List and Groups Hub banner keep base CTA and add compact contextual summary (info tooltip).
  - Timer mirror snackbar adds contextual running/scheduled summary line.
- Updated Timer runtime overlap modal:
  - now renders `Running:` + range, `Scheduled:` + range, and conditional `Pre-Run:` label.

### Local verification

- `flutter analyze` PASS.
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` PASS.
- `flutter test test/presentation/viewmodels/scheduled_group_coordinator_test.dart` PASS.

### Documentation synchronization

- Opened validation packet:
  - `docs/bugs/validation_bug027_2026_05_01/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug027_2026_05_01/quick_pass_checklist.md`
  - `docs/bugs/validation_bug027_2026_05_01/logs/`
  - `docs/bugs/validation_bug027_2026_05_01/screenshots/`
- Updated status to `In validation` in:
  - `docs/bugs/bug_log.md` (`BUG-027`)
  - `docs/validation/validation_ledger.md` (`BUGLOG-027`)
  - `docs/roadmap.md` (Phase 17 reopened item now marked In validation)

### Status after this block

- `BUG-027` / `BUGLOG-027`: **In validation**.
- Device evidence for scenarios A-D (V03/V05/V19/V24) is pending before closure.

---

## Block 753 — BUG-027 follow-up gate completed (tests + validation-plan correction) (01/05/2026)

**Current branch intent:** Close post-review follow-up from Claude for BUG-027 before PR preparation (missing local tests + log-analysis methodology correction).
**Branch:** `fix/bug033-foreground-service-crash`
**Commit:** `dfdd4d8`
**Validation/Bug IDs:** `BUG-027` / `BUGLOG-027` (`In validation`)

### Follow-up actions completed

- Re-ran and confirmed local gate expansion requested in review:
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_session_gap_test.dart` PASS (clean re-run; prior interrupted run invalid).
  - `flutter test test/presentation/viewmodels/pomodoro_view_model_pause_expiry_test.dart` PASS.
  - `flutter test test/presentation/timer_screen_syncing_overlay_test.dart` PASS.
  - `flutter test test/presentation/utils/scheduled_group_timing_test.dart` PASS.
  - `flutter analyze` PASS.
- Corrected BUG-027 packet methodology for log analysis:
  - `docs/bugs/validation_bug027_2026_05_01/plan_validacion_rapida_fix.md`
    now states visual evidence (surfaces A-D) as authoritative for this UI bug.
  - Ownership-action grep remains as secondary signal only.
  - UI-string grep checks (`Running:`, `Scheduled:`, `Pre-Run:`) are now explicitly marked non-authoritative for this bug type.

### Documentation synchronization

- `docs/bugs/validation_bug027_2026_05_01/quick_pass_checklist.md`
  - Local gate section expanded with the four additional PASS tests.
- `docs/bugs/bug_log.md`
  - BUG-027 fix section now references commit `8600f44` (no pending hash wording) and expanded regression/local coverage list.
- `docs/validation/validation_ledger.md`
  - `BUGLOG-027` evidence updated to include expanded local gate PASS set.

### Status after this block

- `BUG-027` / `BUGLOG-027`: **In validation** (device scenarios A-D still pending).
- Local review debt reported by Claude is resolved; remaining work is device evidence capture only.


---

## Block 754 — BUG-034 registered with validation packet (shared timeline desync) (01/05/2026)

**Current branch intent:** Register BUG-034 from user-provided runtime evidence (shared-mode break/timeline desync), preserve branch-scope clarity, and open deterministic validation packet.
**Branch:** `fix/bug034-shared-timeline-break-desync`
**Commit:** `f910caf`
**Validation/Bug IDs:** `BUG-034` / `BUGLOG-034` (`In validation`)

### Context

- User reported a shared-mode logic inconsistency in Run Mode for group `da943ceb-31f9-42b5-b994-235bee6586d0`:
  - `Next status` predicted `Break: 15 min`,
  - runtime executed `Break: 5 min`,
  - contextual task-item ranges no longer aligned with status-box/runtime timeline.
- Source evidence arrived as `bug.md` + three screenshots in repository root.
- Branch-scope decision applied:
  - created dedicated bug branch `fix/bug034-shared-timeline-break-desync` from current `fix/bug033-foreground-service-crash` baseline,
  - reason: keep latest BUG-027/033 documentary state while avoiding further mixed-scope commits on `fix/bug033-*`.

### Work completed

- Opened validation packet:
  - `docs/bugs/validation_bug034_2026_05_01/plan_validacion_rapida_fix.md`
  - `docs/bugs/validation_bug034_2026_05_01/quick_pass_checklist.md`
  - `docs/bugs/validation_bug034_2026_05_01/logs/`
  - `docs/bugs/validation_bug034_2026_05_01/screenshots/`
- Rehomed and renamed screenshot evidence from root into canonical packet paths:
  - `docs/bugs/validation_bug034_2026_05_01/screenshots/2026-05-01_bug034_next_status_predicts_long_break_161714.png`
  - `docs/bugs/validation_bug034_2026_05_01/screenshots/2026-05-01_bug034_runtime_executes_short_break_162539.png`
  - `docs/bugs/validation_bug034_2026_05_01/screenshots/2026-05-01_bug034_contextual_ranges_desync_163327.png`
- Updated canonical bug queue docs:
  - `docs/bugs/bug_log.md` — added BUG-034 full entry and status `In validation`.
  - `docs/validation/validation_ledger.md` — added `BUGLOG-034` (P1 In validation), updated snapshot and active P1 list.
  - `docs/roadmap.md` — added Phase 17 in-validation line for shared-mode timeline coherence requirement (`BUGLOG-034`).

### Status after this block

- `BUG-034` / `BUGLOG-034`: **In validation**.
- Pending closure work: deterministic fresh-run repro + cross-mode guard + targeted fix candidate.

---

## Block 755 — BUG-035 docs-first + global macOS keyboard repair wrapper (04/05/2026)

**Current branch intent:** Add global stale-key recovery path for macOS keyboard reliability outside Authentication, with full bug traceability packet.
**Branch:** `fix/bug035-macos-global-keyboard-repair`
**Commit:** `88e0bb1`
**Validation/Bug IDs:** `BUG-035` / `BUGLOG-035` (`In validation`)

### Context

- New report (04/05/2026): while already authenticated, keyboard input can lock across non-login screens (Task Editor and others) with repeated `A KeyDownEvent is dispatched, but the state shows that the physical key is already pressed`.
- Existing BUG-022 patch (`4e439db`) repaired stale-key state only in `LoginScreen`, so authenticated flows that never open Authentication had no recovery path.

### Changes applied

- Documentation-first sync:
  - Added `BUG-035` entry to `docs/bugs/bug_log.md`.
  - Added `BUGLOG-035` entry to `docs/validation/validation_ledger.md` (P1 / In validation) and updated snapshot counters.
  - Updated `docs/specs.md` desktop keyboard reliability rule to app-wide behavioral scope (no implementation-detail wording).
  - Updated `docs/roadmap.md` timeline + reopened Phase 6 item for global macOS keyboard reliability.
  - Opened validation packet:
    - `docs/bugs/validation_bug035_2026_05_04/plan_validacion_rapida_fix.md`
    - `docs/bugs/validation_bug035_2026_05_04/quick_pass_checklist.md`
    - `docs/bugs/validation_bug035_2026_05_04/logs/`
    - `docs/bugs/validation_bug035_2026_05_04/screenshots/`

- Runtime patch:
  - Added `lib/widgets/macos_keyboard_state_repair.dart` (`MacOsKeyboardStateRepair`).
  - Wrapper is app-scoped and runs stale-key reconciliation on:
    - app bootstrap (`postFrame`),
    - `AppLifecycleState.resumed`.
  - Wrapper includes its own `_repairingKeyboardState` guard (independent from LoginScreen state).
  - Integrated wrapper in `lib/app/app.dart` MaterialApp builder chain so all screens are covered.
  - Preserved existing LoginScreen repair path as defense in depth.

### Validation policy note

- Exact deterministic device repro for BUG-035 is explicitly waived by user decision because trigger is intermittent/non-deterministic.
- Validation packet captures this waiver; local gate remains mandatory.

### Tests executed

- `flutter analyze` -> PASS (`No issues found!`).
- `flutter test test/presentation/timer_screen_completion_navigation_test.dart` -> PASS (`All tests passed`, `+39`).

### Status after this block

- `BUG-035` / `BUGLOG-035`: **In validation**.
- Pending before closure: local gate command evidence + user final acceptance under documented repro waiver.

---

## Block 756 — BUG-035 validation closure and queue sync (04/05/2026)

**Current branch intent:** Close BUG-035 after user-confirmed macOS quick validation PASS and synchronize all canonical tracking docs before merging to `develop`.
**Branch:** `fix/bug035-macos-global-keyboard-repair`
**Implementation commit:** `88e0bb1`
**Validation/Bug IDs:** `BUG-035` / `BUGLOG-035` (**Closed/OK**)

### Validation closure evidence

- User confirmed closure in thread: **"pass, no hubo bugs"**.
- macOS quick-run evidence captured in:
  - `docs/bugs/validation_bug035_2026_05_04/logs/2026-05-04_bug035_4b1c94a_macos_debug.log`
- Log scan result on quick run:
  - no matches for stuck-key signature (`physical key is already pressed`).
- Existing local gate PASS evidence retained in packet:
  - `flutter analyze` log: `.../2026-05-04_bug035_88e0bb1_local_analyze.log`
  - targeted test log: `.../2026-05-04_bug035_88e0bb1_local_timer_screen_completion_navigation_test.log`

### Documentation synchronization completed

- `docs/bugs/validation_bug035_2026_05_04/plan_validacion_rapida_fix.md`
  - status moved to `Closed/OK` and quick-run evidence recorded.
- `docs/bugs/validation_bug035_2026_05_04/quick_pass_checklist.md`
  - closure checklist marked PASS.
- `docs/bugs/bug_log.md`
  - BUG-035 status moved from `In validation` to `Closed/OK`.
- `docs/validation/validation_ledger.md`
  - `BUGLOG-035` moved to `Closed/OK` with commit/evidence fields completed.
  - snapshot counters updated (active bug-log queue and active P1 list).
- `docs/roadmap.md`
  - Phase 6 BUGLOG-035 line moved to `Closed/OK`.

### Status after this block

- `BUG-035` / `BUGLOG-035`: **Closed/OK**.
- Active P1 bug queue reduced to: `BUGLOG-033`, `BUGLOG-034`.

---

## Block 757 — BUG-034 shared-mode next-status break prediction fix + local gate PASS (04/05/2026)

**Current branch intent:** Implement BUG-034 root cause fix (shared-mode global break cadence in `Next status`) and leave validation packet ready for device scenarios in the next session.
**Branch:** `fix/bug034-shared-timeline-break-desync`
**Commit:** `a636b0f`
**Validation/Bug IDs:** `BUG-034` / `BUGLOG-034` (`In validation`)

### Root cause confirmed

- Shared-mode runtime and timeline engines already use global pomodoro indexing for long-break cadence.
- Timer status-box preview (`Next status`) used per-task pomodoro index (`state.currentPomodoro`) directly.
- This mismatch produced false long-break prediction at task boundaries (e.g., local pomodoro 4 in task 2 with global index 7).

### Implementation applied

- `lib/presentation/viewmodels/pomodoro_view_model.dart`
  - Added public getter `currentGlobalPomodoroOffset` so UI projections can consume the same shared-mode global offset used by runtime logic.
- `lib/presentation/screens/timer_screen.dart`
  - Added `usesLongBreakForNextStatus(...)` helper (`@visibleForTesting`) with mode-aware global/per-task cadence selection.
  - Replaced direct `% longBreakInterval` check with mode-aware shared calculation using:
    - `vm.currentGlobalPomodoroOffset`,
    - `vm.currentGroup?.integrityMode`,
    - `state.currentPomodoro`.

### Regression coverage added

- New focused regression test:
  - `test/presentation/timer_screen_break_prediction_test.dart`
  - Confirms:
    - shared mode uses global index (offset 3 + local 4 => global 7 => short break),
    - shared boundary long break case remains correct (offset 3 + local 1 => global 4 => long break),
    - individual mode preserves per-task cadence.

### Local verification

- `flutter analyze` PASS (`No issues found!`).
- `flutter test test/presentation/timer_screen_break_prediction_test.dart` PASS.
- `flutter test test/data/models/task_run_group_mode_a_breaks_test.dart` PASS.

### Packet/doc synchronization

- `docs/bugs/validation_bug034_2026_05_01/plan_validacion_rapida_fix.md`
  - Scenario C terminology corrected: `fixed/flexible` -> `individual`.
  - Local verification section updated to PASS with exact commands/date.
- `docs/bugs/validation_bug034_2026_05_01/quick_pass_checklist.md`
  - Regression smoke terminology corrected to `individual`.
  - Local gate checklist marked PASS with explicit test command evidence.

### Status after this block

- `BUG-034` / `BUGLOG-034`: **In validation**.
- Device scenarios A/B/C remain pending and are the next required step before closure.

---

## Block 758 — No-loss PR checklist integration refreshed on top of develop (05/05/2026)

**Current branch intent:** Process governance hardening — integrate and preserve the no-loss PR discipline on top of latest `origin/develop`.
**Branch:** `fix/process-no-loss-pr-checklist`
**Commit:** `pending-local`
**Scope:** process/docs governance (`AGENTS.md`, `docs/validation/validation_ledger.md`, `.github/pull_request_template.md`)

### Context

- The no-loss process branch existed but remained outside `develop`, so the checklist rules were not active in the canonical flow.
- This integration keeps the latest bug/validation history from `develop` and reapplies only the no-loss process layer.

### Work completed

- Merged `origin/develop` into `fix/process-no-loss-pr-checklist` and resolved collisions by preserving newer canonical bug/status content.
- Re-applied and kept no-loss process artifacts:
  - `AGENTS.md` always-on `No-loss PR checklist rule`.
  - `docs/validation/validation_ledger.md` section `No-loss implementation checklist (mandatory)`.
  - `.github/pull_request_template.md` with pre-PR/docs-sync/validation/merge-safety gates.
- Preserved explicit collision guard for `docs/dev_log.md` block-number conflicts before merge.

### Status after this block

- No-loss PR discipline is now ready to merge from this branch into `develop` without losing current bug queue chronology or ledger state.
