import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MacOsKeyboardStateRepair extends StatefulWidget {
  const MacOsKeyboardStateRepair({super.key, required this.child});

  final Widget child;

  @override
  State<MacOsKeyboardStateRepair> createState() =>
      _MacOsKeyboardStateRepairState();
}

class _MacOsKeyboardStateRepairState extends State<MacOsKeyboardStateRepair>
    with WidgetsBindingObserver {
  bool _repairingKeyboardState = false;

  bool get _isMacOsDesktop =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        _repairStaleKeyboardStateIfNeeded(trigger: 'app_wrapper_bootstrap'),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    unawaited(_repairStaleKeyboardStateIfNeeded(trigger: 'app_resumed'));
  }

  Future<void> _repairStaleKeyboardStateIfNeeded({
    required String trigger,
  }) async {
    if (!_isMacOsDesktop || _repairingKeyboardState) return;
    _repairingKeyboardState = true;
    try {
      final keyboardState =
          await SystemChannels.keyboard.invokeMapMethod<int, int>(
            'getKeyboardState',
          ) ??
          const <int, int>{};
      final platformPressed = keyboardState.keys
          .map(PhysicalKeyboardKey.new)
          .toSet();
      final stalePressed = HardwareKeyboard.instance.physicalKeysPressed
          .difference(platformPressed);
      if (stalePressed.isEmpty) return;
      for (final physicalKey in stalePressed) {
        final logicalKey = HardwareKeyboard.instance.lookUpLayout(physicalKey);
        if (logicalKey == null) continue;
        HardwareKeyboard.instance.handleKeyEvent(
          KeyUpEvent(
            physicalKey: physicalKey,
            logicalKey: logicalKey,
            synthesized: true,
            timeStamp: Duration.zero,
          ),
        );
      }
      debugPrint(
        '[GlobalKeyboardRepair] trigger=$trigger cleared=${stalePressed.length}',
      );
    } catch (e) {
      debugPrint('[GlobalKeyboardRepair] trigger=$trigger failed: $e');
    } finally {
      _repairingKeyboardState = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
