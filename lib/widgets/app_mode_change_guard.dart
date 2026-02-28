import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/services/app_mode_service.dart';
import '../presentation/providers.dart';
import '../presentation/viewmodels/scheduled_group_coordinator.dart';
import '../presentation/viewmodels/pre_run_notice_view_model.dart';

class AppModeChangeGuard extends ConsumerStatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const AppModeChangeGuard({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  ConsumerState<AppModeChangeGuard> createState() =>
      _AppModeChangeGuardState();
}

class _AppModeChangeGuardState extends ConsumerState<AppModeChangeGuard> {
  AppMode? _lastMode;

  @override
  void initState() {
    super.initState();
    _lastMode = ref.read(appModeProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppMode>(appModeProvider, (previous, next) {
      final prior = previous ?? _lastMode;
      _lastMode = next;
      if (prior == null || prior == next) return;
      _handleModeChange();
    });
    return widget.child;
  }

  void _handleModeChange() {
    ref.invalidate(pomodoroViewModelProvider);
    ref.invalidate(taskRunGroupStreamProvider);
    ref.invalidate(preRunNoticeMinutesProvider);
    ref.read(scheduledAutoStartGroupIdProvider.notifier).state = null;
    ref.read(runningOverlapDecisionProvider.notifier).state = null;
    ref.read(completionDialogVisibleProvider.notifier).state = false;
    ref.read(scheduledGroupCoordinatorProvider.notifier).clearAction();

    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) return;
    final router = GoRouter.of(navigatorContext);
    final route =
        router.routerDelegate.currentConfiguration.uri.path;
    if (route != '/tasks') {
      router.go('/tasks');
    }
  }
}
