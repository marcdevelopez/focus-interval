import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/services/app_mode_service.dart';
import '../presentation/providers.dart';
import '../presentation/viewmodels/pre_run_notice_view_model.dart';
import '../presentation/viewmodels/scheduled_group_coordinator.dart';

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
      _handleModeChange(prior, next);
    });
    return widget.child;
  }

  void _handleModeChange(AppMode previous, AppMode next) {
    ref.invalidate(pomodoroViewModelProvider);
    ref.invalidate(taskRunGroupStreamProvider);
    ref.invalidate(pomodoroSessionStreamProvider);
    ref.invalidate(activePomodoroSessionProvider);
    ref.invalidate(preRunNoticeMinutesProvider);
    // Do NOT invalidate scheduledGroupCoordinatorProvider here.
    // The coordinator has a ref.listen<AppMode> that calls _resetForModeChange()
    // and _handleGroups() when the mode changes. Invalidating it would dispose
    // those listeners and create a race window where stream events arrive before
    // the new coordinator instance rebuilds and re-registers its subscriptions.
    ref.read(scheduledAutoStartGroupIdProvider.notifier).state = null;
    ref.read(runningOverlapDecisionProvider.notifier).state = null;
    ref.read(completionDialogVisibleProvider.notifier).state = false;

    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) return;
    final router = GoRouter.of(navigatorContext);
    final route =
        router.routerDelegate.currentConfiguration.uri.path;
    if (route != '/tasks') {
      router.go('/tasks');
    }
    if (previous == AppMode.local && next == AppMode.account) {
      // The coordinator's ref.listen<AppMode> already fires _resetForModeChange()
      // and _handleGroups(). The forceReevaluate() calls below are backup triggers
      // to catch the case where stream data arrives before the initial _handleGroups
      // runs or the time sync needs a retry window.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ref.read(appModeProvider) != AppMode.account) return;
        ref.read(scheduledGroupCoordinatorProvider.notifier).forceReevaluate();
      });
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        if (ref.read(appModeProvider) != AppMode.account) return;
        ref.read(scheduledGroupCoordinatorProvider.notifier).forceReevaluate();
      });
    }
  }
}
