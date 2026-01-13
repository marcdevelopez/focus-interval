# 📝 Focus Interval — Dev Log (MVP 1.0)

Chronological history of the MVP development using work blocks.  
Each block represents significant progress within the same day or sprint.

This document is used to:

- Preserve real progress traceability
- Align architecture with the roadmap
- Inform the AI of the exact project state
- Serve as professional evidence of collaborative AI work
- Show how the MVP was built at an accelerated pace

---

# 📍 Current status

Active phase: **14 — Sounds and Notifications**  
Last update: **13/01/2026**

---

# 📅 Development log

# 🔹 Block 1 — Initial setup (21/11/2025)

### ✔ Work completed:

- Initial `/docs` structure created
- Added full `specs.md`
- Added full `roadmap.md`

### 🧠 Decisions made:

- The final clock animation will be **mandatory** in the MVP
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

- Keep three sounds in the MVP: pomodoro start, break start, and task finish (fixed), avoiding duplication with break end.
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

- Validate Windows/Linux notification delivery if required for MVP.

---

# 🔹 Block 29 — Android Google Sign-In (debug keystore) — 08/01/2026

### ✔ Work completed:

- Identified Google Sign-In failure caused by a new macOS user generating a new debug keystore.
- Updated SHA-1/SHA-256 in Firebase and replaced `android/app/google-services.json`.
- Confirmed Google Sign-In works and session persists after rebuild.

---

# 🔹 Block 30 — Auth roadmap note (macOS OAuth) — 08/01/2026

### ✔ Work completed:

- Logged a post-MVP note to add macOS Google Sign-In via OAuth web flow (PKCE + browser).

---

# 🔹 Block 31 — iOS Google Sign-In fix — 08/01/2026

### ✔ Work completed:

- Fixed iOS Google Sign-In crash by adding the REVERSED_CLIENT_ID URL scheme to `ios/Runner/Info.plist`.
- Verified Google Sign-In works on iOS and the session persists.

---

# Block 32 - Windows desktop validation and auth stubs - 08/01/2026

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

# Block 33 - Windows audio/notifications via adapters - 08/01/2026

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

# Block 34 - Linux dependency checks and docs - 13/01/2026

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

# Block 35 - Linux auth guard on task list/login - 13/01/2026

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

# 🧾 General notes

- Update this document at the **end of each development session**
- Use short bullet points, not long narrative
- This allows the AI to jump in on any day and continue directly

---

# 🚀 End of file
