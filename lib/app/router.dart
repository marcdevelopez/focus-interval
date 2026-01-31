import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/pomodoro_preset.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/task_list_screen.dart';
import '../presentation/screens/task_editor_screen.dart';
import '../presentation/screens/timer_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/preset_list_screen.dart';
import '../presentation/screens/preset_editor_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/tasks',
    redirect: (context, state) {
      final uri = state.uri;
      if (uri.scheme.startsWith('com.googleusercontent.apps') &&
          uri.host == 'firebaseauth') {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      GoRoute(
        path: '/tasks',
        pageBuilder: (_, __) => _fade(const TaskListScreen()),
      ),

      GoRoute(
        path: '/tasks/new',
        pageBuilder: (_, __) =>
            _slide(const TaskEditorScreen(isEditing: false)),
      ),

      GoRoute(
        path: '/tasks/edit/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _slide(TaskEditorScreen(isEditing: true, taskId: id));
        },
      ),

      GoRoute(
        path: '/timer/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _fadeScale(TimerScreen(groupId: id));
        },
      ),

      GoRoute(
        path: '/settings',
        pageBuilder: (_, __) => _slide(const SettingsScreen()),
      ),
      GoRoute(
        path: '/settings/presets',
        pageBuilder: (_, __) => _slide(const PresetListScreen()),
      ),
      GoRoute(
        path: '/settings/presets/new',
        pageBuilder: (context, state) => _slide(
          PresetEditorScreen(
            isEditing: false,
            seed: state.extra is PomodoroPreset ? state.extra as PomodoroPreset : null,
          ),
        ),
      ),
      GoRoute(
        path: '/settings/presets/edit/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _slide(PresetEditorScreen(isEditing: true, presetId: id));
        },
      ),
    ],
  );
}

/// Reusable transitions
CustomTransitionPage _fade(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}

CustomTransitionPage _slide(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (_, animation, __, child) {
      return SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

CustomTransitionPage _fadeScale(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.95, end: 1.0).animate(animation),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
