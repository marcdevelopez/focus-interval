import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'router.dart';
import 'theme.dart';
import '../widgets/active_session_auto_opener.dart';
import '../widgets/linux_dependency_gate.dart';
import '../widgets/preset_sync_coordinator.dart';
import '../widgets/scheduled_group_auto_starter.dart';

class FocusIntervalApp extends StatelessWidget {
  const FocusIntervalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "Focus Interval",
      routerConfig: buildRouter(),
      theme: buildDarkTheme(),
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        final wrapped = ActiveSessionAutoOpener(
          navigatorKey: rootNavigatorKey,
          child: content,
        );
        final presetSyncWrapped = PresetSyncCoordinator(child: wrapped);
        final scheduledWrapped = ScheduledGroupAutoStarter(
          navigatorKey: rootNavigatorKey,
          child: presetSyncWrapped,
        );
        if (!_isLinux) return scheduledWrapped;
        return LinuxDependencyGate(
          navigatorKey: rootNavigatorKey,
          child: scheduledWrapped,
        );
      },
    );
  }
}

bool get _isLinux =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
