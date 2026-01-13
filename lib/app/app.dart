import 'package:flutter/material.dart';
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
        return LinuxDependencyGate(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
