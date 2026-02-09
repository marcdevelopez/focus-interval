# Focus Interval — AI Coding Agent Instructions

This project is governed by AGENTS.md.
All architectural, workflow, and authority rules defined there are mandatory
and override any suggestion unless explicitly stated otherwise.

## Project Overview

Cross-platform Pomodoro app built with Flutter for macOS/Windows/Linux/iOS/Android/Web.
Uses Firebase Auth + Firestore for cloud sync, plus a first-class Local Mode (offline, no auth).
Google Sign-In is used on iOS/Android/Web; email/password is used on macOS/Windows;
Linux auth is disabled (local-only). Optional GitHub Sign-In is documented; desktop uses
GitHub Device Flow where enabled.

## Mandatory Workflow (non-negotiable, from AGENTS.md)

At the start of every session:
1. Read `docs/specs.md`, `docs/roadmap.md`, `docs/dev_log.md`.
2. Confirm the real date (use `date`).
3. Verify CURRENT PHASE and any Reopened phases in `docs/roadmap.md`.
4. If a phase is reopened and not listed, add it immediately to the Reopened list.
5. Do not start coding until context is aligned.
6. Ensure you are not on `main`; create a new branch before any code or doc changes.
7. If already on a branch, ensure the change matches the branch scope; otherwise finish/commit that work and create a new branch.

Documentation-first rule:
- Specs must define behavior before code changes.
- If docs and code diverge, docs win.

## Architecture & Authority (must follow)

Layer boundaries (strict):
- presentation/ → UI only
- viewmodels/ → UI state & orchestration
- domain/ → pure logic (no Flutter/Firebase)
- data/ → persistence & external services

Single source of truth:
- Pomodoro flow & rules → `PomodoroMachine`
- Execution orchestration → `PomodoroViewModel`
- Persistence & sync → repositories / Firestore
- Active execution authority (Account Mode) → Firestore `activeSession` owner
- Active execution authority (Local Mode) → local session owner

Time rules:
- ViewModels may project time only from authoritative timestamps.
- UI must never own authoritative timers or state transitions.
- ViewModels may use timers only for projection/rendering; never for authoritative decisions.

Local vs Account Mode:
- No implicit sync, no silent merges, no shared authority.
- Import Local → Account is explicit with overwrite-by-ID (MVP rule).

Platform discipline:
- Platform differences must be isolated in services/adapters/guards.
- Fallback behavior is silent, logs only in debug, and preserves UX consistency.
- Minimal UI guards are allowed only when no service-level alternative exists.

Derived vs authoritative:
- Derived logic must be read-only, deterministic, and based solely on authoritative data.
- Do not duplicate authoritative ownership, state transitions, or conflict rules.

## Current Implementation Lock-Ins (do not change without explicit approval)

- TimerDisplay visuals are approved and locked: progress ring + shadowed marker dot,
  no hand/needle, base ring/shadows preserved, ring colors red/blue/amber.
- Run Mode status boxes and contextual list already show time ranges (HH:mm–HH:mm).
- Auto task transitions are handled in `PomodoroViewModel` (no UI modal).
- Groups Hub indicator exists in the TimerScreen header (placeholder until Phase 19).
- UI polish is only allowed in Phase 23 and must be explicitly approved.

## Feature Development Protocol (from AGENTS.md)

- Create a new branch for every feature or fix; never work on `main`.
- Implement only one logical change per branch.
- Ensure the app compiles and `flutter analyze` passes before any commit.
- Verify the change (manual or automated) before committing.
- Update `docs/dev_log.md` (same real date) and `docs/roadmap.md` if phase status changes.
- Commit code + docs together; never commit broken builds or temporary hacks.

## Project Structure (MVVM + Clean Architecture)

```
lib/
├── app/                  # Router, theme, app config
├── domain/               # Business logic (PomodoroMachine, validators)
├── data/
│   ├── models/          # PomodoroTask, TaskRunGroup, PomodoroSession
│   ├── repositories/    # Abstract + Firestore implementations
│   └── services/        # Firebase, sound, device info
├── presentation/
│   ├── screens/         # Login, TaskList, TaskEditor, Timer
│   ├── viewmodels/      # Riverpod Notifiers (AsyncNotifier for lists)
│   └── providers.dart   # Centralized Riverpod providers
└── widgets/             # Reusable components (e.g., TimerDisplay)
```

## State Management (Riverpod)

- Lists: `AsyncNotifier<List<T>>`
- Single objects: `Notifier<T>`
- Streams: subscribe in `build()`, cancel in `ref.onDispose()`
- Providers live in `presentation/providers.dart` and use `.autoDispose`

## Auth & Sync

- Auth strategy: Google Sign-In on iOS/Android/Web; email/password on macOS/Windows;
  Linux auth disabled (local-only).
- Optional GitHub Sign-In provider; desktop uses GitHub Device Flow where enabled.
- Firestore is isolated per `uid` for all queries and writes.

## Navigation & Animations (GoRouter)

`lib/app/router.dart` defines custom transitions:
- `/tasks` → Fade (350ms)
- `/tasks/new`, `/tasks/edit/:id` → Slide right-to-left (300ms)
- `/timer/:id` → FadeScale (350ms)

## Audio

`SoundService` uses `just_audio`. Asset paths live under `assets/sounds/`.

## Build & Testing

- Debug: `flutter run`
- Analyzer: `flutter analyze` (must pass before commits)
- Tests: `flutter test` (minimal coverage currently)

## Documentation Sources

- Specs: `docs/specs.md` (MVP 1.2.0)
- Roadmap: `docs/roadmap.md` (24 phases, current Phase 18)
- Dev Log: `docs/dev_log.md`
- Agent Guide: `AGENTS.md`

## Critical Rules

1. Always check the roadmap phase before implementing features.
2. Never commit broken builds.
3. Use real dates (DD/MM/YYYY) when updating roadmap/dev_log.
4. English only for code, comments, UI strings, and docs.
5. Do not change locked UI elements without explicit approval.

## Release & Safety Checks (before any release discussion)

- Confirm Android keystore backup.
- Confirm Firebase project access.
- Confirm bundle IDs are consistent.
- Confirm platform stubs exist where features are unsupported.

## Release Safety and Data Evolution

For any change touching Firestore data, queries, rules, auth, sync, or migrations:

- Follow `docs/release_safety.md`.
- Keep production backward compatible (additive changes first).
- Use versioned documents and staged migrations (dual-read/dual-write + backfill).
- Validate rules and schema changes in emulator or STAGING before PROD.
