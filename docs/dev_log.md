# 📝 Focus Interval — Dev Log (MVP 1.2)

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

---

# 📍 Current status

Active phase: **20 — Group Naming & Task Visual Identity**
Last update: **25/02/2026**

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

- Prevented _resetLocalSessionState from clearing optimistic ownership when
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

- Added docs/bug_log.md to centralize bug tracking.
- Seeded the log with BUG-001 (mirror Ready with active session) and marked it intermittent.

### 🧠 Decisions made:

- Bug notes live in docs/bug_log.md; dev log references them only when tied to code changes.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Add new bug reports to docs/bug_log.md in chronological order.


# 🔹 Block 371 — Add feature backlog (13/02/2026)

### ✔ Work completed:

- Added docs/feature_backlog.md to centralize feature ideas.
- Seeded IDEA-001 (circular group progress ring around the timer).

### 🧠 Decisions made:

- Feature ideas live in docs/feature_backlog.md with a consistent template.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Add the remaining feature ideas using the same template.


# 🔹 Block 372 — Document ownership desync + mirror flicker bugs (13/02/2026)

### ✔ Work completed:

- Added BUG-002 and BUG-003 to docs/bug_log.md, splitting ownership rejection
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

- Added BUG-006 to docs/bug_log.md for status-box time ranges that ignore pause
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

- Updated IDEA-016 in `docs/feature_backlog.md` to state that scheduled previews
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

- Added IDEA-018 to `docs/feature_backlog.md` for live pause updates of task
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

- Added IDEA-019 to `docs/feature_backlog.md` for a Break tasks list in Run Mode
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

- Added IDEA-020 to `docs/feature_backlog.md` for showing scheduledByDeviceId
  in Group Summary with a legacy fallback.

### 🧠 Decisions made:

- Treat scheduled-by visibility as a UI-only traceability improvement.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-020 on its own branch.


# 🔹 Block 393 — Add account deletion idea (16/02/2026)

### ✔ Work completed:

- Added IDEA-021 to `docs/feature_backlog.md` for an Account Mode "Delete account"
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

- Added IDEA-022 to `docs/feature_backlog.md` for pomodoro presence verification
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

- Added IDEA-023 to `docs/feature_backlog.md` for resuming canceled groups while
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

- Added IDEA-024 to `docs/feature_backlog.md` for Workspaces with shared
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

- Added IDEA-025 to `docs/feature_backlog.md` for break-focused workspace chat,
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

- Added IDEA-026 to `docs/feature_backlog.md` for consistent Manage Presets item
  preview, star placement, and tap/long-press behavior.

### 🧠 Decisions made:

- Align preset item gestures with Task List: tap edits, long-press selects.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-026 on its own branch.


# 🔹 Block 410 — Add unified mode indicator idea (17/02/2026)

### ✔ Work completed:

- Added IDEA-027 to `docs/feature_backlog.md` for consistent mode indicator
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

- Added IDEA-028 to `docs/feature_backlog.md` for verified weekly/monthly totals,
  task breakdowns, and a Week-start setting aligned with IDEA-022.

### 🧠 Decisions made:

- Only verified pomodoros count toward totals and breakdowns.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-028 on its own branch.


# 🔹 Block 412 — Add live pause time ranges idea (17/02/2026)

### ✔ Work completed:

- Added IDEA-029 to `docs/feature_backlog.md` for live pause time ranges that
  update forward-only during paused state.

### 🧠 Decisions made:

- Pause offsets must never rewrite past start times; only forward ranges move.

### ⚠️ Issues found:

_(fill in when they happen)_

### 🎯 Next steps:

- Commit and push IDEA-029 on its own branch.


# 🔹 Block 413 — Log owner resume drift after background crash (17/02/2026)

### ✔ Work completed:

- Logged BUG-007 in `docs/bug_log.md` for owner resume drift after an Android
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

- Added a "Recommended execution order" section to `docs/feature_backlog.md`
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

- Added a mitigation note to `docs/bug_log.md` proposing a Run Mode "Syncing..."
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
  + status boxes).

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

# 🔹 Block 459 — Feature docs structure (25/02/2026)

### ✔ Work completed:

- Added `docs/features/` with a README and a reusable feature template.
- Template requires explicit backlog linkage to `docs/feature_backlog.md`.
- AGENTS.md updated to enforce feature doc creation before implementation.

### 🧠 Decisions made:

- Feature folders must be prefixed with the exact backlog ID for traceability.

### ⚠️ Issues found:

_(none)_

### 🎯 Next steps:

- Use the template for the next feature pulled from the backlog.
