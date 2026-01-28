import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/login_screen.dart';
import '../presentation/screens/task_list_screen.dart';
import '../presentation/screens/task_editor_screen.dart';
import '../presentation/screens/timer_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/tasks',
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
