# Focus Interval — AI Coding Agent Instructions

## Project Overview

Cross-platform Pomodoro desktop app (macOS/Windows/Linux) built with Flutter. Uses Firebase Auth (Google Sign-In + email/password on macOS), Firestore for cloud sync, and real-time multi-device session mirroring.

## Architecture (MVVM + Clean Architecture)

```
lib/
├── app/                  # Router, theme, app config
├── domain/               # Business logic (PomodoroMachine, validators)
├── data/
│   ├── models/          # PomodoroTask, PomodoroSession
│   ├── repositories/    # Abstract + Firestore implementations
│   └── services/        # Firebase, sound, device info
├── presentation/
│   ├── screens/         # Login, TaskList, TaskEditor, Timer
│   ├── viewmodels/      # Riverpod Notifiers (AsyncNotifier for lists)
│   └── providers.dart   # Centralized Riverpod providers
└── widgets/             # Reusable components (e.g., TimerDisplay)
```

**Key Pattern**: ViewModels extend `Notifier<T>` or `AsyncNotifier<T>` (Riverpod 3.x). Use `.autoDispose` for disposable resources. All Firebase operations go through abstract repositories with both Firestore and stub implementations.

## Critical Developer Workflows

### Before ANY code change

1. **Read** [docs/roadmap.md](../docs/roadmap.md) and [docs/dev_log.md](../docs/dev_log.md) to understand current phase
2. Check `FASE ACTUAL` status at top of roadmap
3. Verify change aligns with active phase objectives

### After completing work

1. Update [docs/roadmap.md](../docs/roadmap.md): Mark phase complete with **real date** (format: `DD/MM/YYYY`)
2. Update [docs/dev_log.md](../docs/dev_log.md): Add block with date, decisions, problems, next steps
3. **Never commit** with build errors or known bugs—use branches for WIP

### Build Commands

- **Debug**: `flutter run` (defaults to desktop on macOS/Windows/Linux)
- **Android APKs**: `flutter build apk --release` (produces split APKs by ABI: armeabi-v7a, arm64-v8a, x86_64)
  - Output: `build/app/outputs/flutter-apk/`
  - For single universal APK: `flutter build apk --no-split-per-abi`
  - For Play Store: `flutter build appbundle`
- **Analyzer**: `flutter analyze` (must pass before commits)

### Testing

Current state: Minimal testing (placeholder in [test/widget_test.dart](../test/widget_test.dart)). Run with `flutter test`.

## Project-Specific Conventions

### State Management (Riverpod 3.x)

- **Lists**: Use `AsyncNotifier<List<T>>` (see [TaskListViewModel](../lib/presentation/viewmodels/task_list_view_model.dart))
- **Single objects**: Use `Notifier<T>` (see [PomodoroViewModel](../lib/presentation/viewmodels/pomodoro_view_model.dart))
- **Streams**: Subscribe in `build()`, cancel in `ref.onDispose()` (example: `PomodoroViewModel._sub`)
- **Providers**: Define in [presentation/providers.dart](../lib/presentation/providers.dart), always use `.autoDispose` for machine/service providers

### Firebase Integration

- **Auth strategy**: Google Sign-In on iOS/Android/Web/Windows/Linux; email/password on macOS
- **User isolation**: All Firestore queries filter by `uid` (see [FirestoreTaskRepository](../lib/data/repositories/firestore_task_repository.dart))
- **Repository pattern**: Abstract interfaces in [data/repositories/](../lib/data/repositories/), with Firestore + in-memory implementations
- **Auth state**: `authStateProvider` (StreamProvider) determines which repository to use

### PomodoroMachine (State Machine)

Core business logic in [domain/pomodoro_machine.dart](../lib/domain/pomodoro_machine.dart):

- **States**: `idle`, `pomodoroRunning`, `shortBreakRunning`, `longBreakRunning`, `paused`, `finished`
- **Strict lifecycle**: Configure → Start → Auto-transitions → Finish (stops after all pomodoros)
- **Immutable events**: Exposes `Stream<PomodoroState>` for ViewModels
- **Validation**: Rejects configurations with <=0 values

### Real-time Session Sync (Multi-device)

- One device is "owner" (starts session), others are "mirrors" (read-only)
- [FirestorePomodoroSessionRepository](../lib/data/repositories/firestore_pomodoro_session_repository.dart) manages session documents
- [PomodoroViewModel](../lib/presentation/viewmodels/pomodoro_view_model.dart) subscribes to session stream, polls remaining seconds for mirrors

### Navigation & Animations (GoRouter)

[app/router.dart](../lib/app/router.dart) defines custom transitions:

- `/tasks` → Fade (350ms)
- `/tasks/new`, `/tasks/edit/:id` → Slide right-to-left (300ms)
- `/timer/:id` → FadeScale (350ms)

### Audio

[SoundService](../lib/data/services/sound_service.dart) uses `just_audio`. Asset paths: `assets/sounds/` (see [pubspec.yaml](../pubspec.yaml)).

## Documentation Sources

- **Specs**: [docs/specs.md](../docs/specs.md) (MVP 1.0 functional spec, 618 lines)
- **Roadmap**: [docs/roadmap.md](../docs/roadmap.md) (19 phases, currently Phase 13—multi-device sync)
- **DevLog**: [docs/dev_log.md](../docs/dev_log.md) (chronological work blocks with dates/decisions)
- **Agent guide**: [agent.md](../agent.md) (workflow rules for AI agents)
- **Team roles**: [docs/team_roles.md](../docs/team_roles.md) (Marcos as Lead Engineer, ChatGPT as AI Architect, Codex as Implementation Engineer)

## Critical Rules

1. **Always** check roadmap phase before implementing features—don't skip ahead
2. **Never** commit broken builds (run `flutter analyze` first)
3. Use **real dates** (DD/MM/YYYY format) when updating roadmap/devlog
4. Follow MVVM strictly: UI (Screens) → ViewModels → Repositories → Services
5. All Firebase writes require authenticated user (`authStateProvider`)
6. Dispose streams/timers in `ref.onDispose()` to prevent leaks

## Common Pitfalls

- **Don't** use `Provider.of` or `context.read`—use `ref.watch`/`ref.read` (Riverpod)
- **Don't** put business logic in Screens—use ViewModels
- **Don't** directly instantiate repositories—get from providers
- **Don't** forget to mark phases complete in roadmap after finishing work
