import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'router.dart';
import 'theme.dart';
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
        if (!_isLinux) return content;
        return LinuxDependencyGate(
          navigatorKey: rootNavigatorKey,
          child: content,
        );
      },
    );
  }
}

bool get _isLinux =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
