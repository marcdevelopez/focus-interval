import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/services/linux_dependency_checker.dart'
    if (dart.library.html) '../data/services/linux_dependency_checker_stub.dart';
import '../data/services/linux_dependency_types.dart';

const Map<LinuxPackageFamily, Map<LinuxDependency, List<String>>>
    _packagesByFamily = {
  LinuxPackageFamily.debian: {
    LinuxDependency.notifications: ['libnotify4'],
    LinuxDependency.audio: [
      'gstreamer1.0-plugins-base',
      'gstreamer1.0-plugins-good',
      'gstreamer1.0-plugins-ugly',
      'gstreamer1.0-libav',
    ],
  },
  LinuxPackageFamily.fedora: {
    LinuxDependency.notifications: ['libnotify'],
    LinuxDependency.audio: [
      'gstreamer1',
      'gstreamer1-plugins-base',
      'gstreamer1-plugins-good',
      'gstreamer1-plugins-ugly',
      'gstreamer1-libav',
    ],
  },
  LinuxPackageFamily.arch: {
    LinuxDependency.notifications: ['libnotify'],
    LinuxDependency.audio: [
      'gstreamer',
      'gst-plugins-base',
      'gst-plugins-good',
      'gst-plugins-ugly',
      'gst-libav',
    ],
  },
  LinuxPackageFamily.suse: {
    LinuxDependency.notifications: ['libnotify'],
    LinuxDependency.audio: [
      'gstreamer',
      'gstreamer-plugins-base',
      'gstreamer-plugins-good',
      'gstreamer-plugins-ugly',
      'gstreamer-plugins-libav',
    ],
  },
};

class LinuxDependencyGate extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const LinuxDependencyGate({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<LinuxDependencyGate> createState() => _LinuxDependencyGateState();
}

class _LinuxDependencyGateState extends State<LinuxDependencyGate> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runCheck());
  }

  Future<void> _runCheck() async {
    if (_hasChecked) return;
    _hasChecked = true;
    final report = await LinuxDependencyChecker.check();
    if (!mounted || !report.hasIssues) return;
    await _showDialog(report);
  }

  Future<void> _showDialog(LinuxDependencyReport report) async {
    final dialogContext = widget.navigatorKey.currentContext;
    if (dialogContext == null) {
      debugPrint('Linux dependency dialog skipped: navigator not ready.');
      return;
    }
    final missingText = _missingLines(report.missing);
    final installCommand = _installCommand(report.family, report.missing);
    final hasCommand = installCommand.isNotEmpty;

    await showDialog<void>(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Missing Linux desktop dependencies'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                const Text(
                  'Some optional system libraries are missing. The app can run, '
                  'but these features may not work:',
                ),
                const SizedBox(height: 8),
                Text(missingText),
                const SizedBox(height: 12),
                const Text('Install the missing packages and restart the app.'),
                if (hasCommand) ...[
                  const SizedBox(height: 12),
                  const Text('Install command:'),
                  const SizedBox(height: 6),
                  SelectableText(installCommand),
                ],
                const SizedBox(height: 12),
                const Text(
                  'See docs/linux_dependencies.md for per-distro details.',
                ),
              ],
            ),
          ),
          actions: [
            if (hasCommand)
              TextButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: installCommand),
                  );
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Install command copied to clipboard.'),
                    ),
                  );
                },
                child: const Text('Copy command'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _missingLines(Set<LinuxDependency> missing) {
    final lines = <String>[];
    if (missing.contains(LinuxDependency.notifications)) {
      lines.add('- Notifications (libnotify)');
    }
    if (missing.contains(LinuxDependency.audio)) {
      lines.add('- Audio playback (GStreamer + plugins)');
    }
    return lines.join('\n');
  }

  String _installCommand(
    LinuxPackageFamily family,
    Set<LinuxDependency> missing,
  ) {
    final packages = _packagesFor(family, missing);
    if (packages.isEmpty) return '';

    final joined = packages.join(' ');
    switch (family) {
      case LinuxPackageFamily.debian:
        return 'sudo apt-get update\nsudo apt-get install -y $joined';
      case LinuxPackageFamily.fedora:
        return 'sudo dnf install -y $joined';
      case LinuxPackageFamily.arch:
        return 'sudo pacman -S --needed $joined';
      case LinuxPackageFamily.suse:
        return 'sudo zypper install -y $joined';
      case LinuxPackageFamily.unknown:
        return '';
    }
  }

  List<String> _packagesFor(
    LinuxPackageFamily family,
    Set<LinuxDependency> missing,
  ) {
    final byDependency = _packagesByFamily[family];
    if (byDependency == null) return const <String>[];

    final packages = <String>[];
    for (final dependency in LinuxDependency.values) {
      if (!missing.contains(dependency)) continue;
      final entries = byDependency[dependency] ?? const <String>[];
      for (final entry in entries) {
        if (!packages.contains(entry)) {
          packages.add(entry);
        }
      }
    }
    return packages;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
