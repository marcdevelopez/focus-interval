# 📝 Focus Interval — Dev Log (MVP 1.2)

Chronological history of the MVP 1.2 development using work blocks.
Each block represents significant progress within the same day or sprint.

This document is used to:

- Preserve real progress traceability
- Align architecture with the roadmap
- Inform the AI of the exact project state
- Serve as professional evidence of collaborative AI work
- Show how the MVP 1.2 was built at an accelerated pace

---

# 📍 Current status

Active phase: **17 — Planning Flow + Conflict Management**
Last update: **29/01/2026**

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

# 🧾 General notes

- Update this document at the **end of each development session**
- Use short bullet points, not long narrative
- This allows the AI to jump in on any day and continue directly

---

# 🚀 End of file
