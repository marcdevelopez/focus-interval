import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'router.dart';
import 'theme.dart';
import '../widgets/active_session_auto_opener.dart';
import '../widgets/linux_dependency_gate.dart';

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
        if (!_isLinux) return wrapped;
        return LinuxDependencyGate(
          navigatorKey: rootNavigatorKey,
          child: wrapped,
        );
      },
    );
  }
}

bool get _isLinux =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
