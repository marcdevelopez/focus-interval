import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'router.dart';
import 'theme.dart';
import '../widgets/active_session_auto_opener.dart';
import '../widgets/app_mode_change_guard.dart';
import '../widgets/linux_dependency_gate.dart';
import '../widgets/macos_keyboard_state_repair.dart';
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
        final modeWrapped = AppModeChangeGuard(
          navigatorKey: rootNavigatorKey,
          child: content,
        );
        final wrapped = ActiveSessionAutoOpener(
          navigatorKey: rootNavigatorKey,
          child: modeWrapped,
        );
        final presetSyncWrapped = PresetSyncCoordinator(child: wrapped);
        final scheduledWrapped = ScheduledGroupAutoStarter(
          navigatorKey: rootNavigatorKey,
          child: presetSyncWrapped,
        );
        final keyboardRepairWrapped = MacOsKeyboardStateRepair(
          child: scheduledWrapped,
        );
        if (!_isLinux) return keyboardRepairWrapped;
        return LinuxDependencyGate(
          navigatorKey: rootNavigatorKey,
          child: keyboardRepairWrapped,
        );
      },
    );
  }
}

bool get _isLinux => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
