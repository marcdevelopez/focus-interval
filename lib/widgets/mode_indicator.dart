import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/app_mode_service.dart';
import '../presentation/providers.dart';

class ModeIndicatorChip extends ConsumerWidget {
  final bool compact;

  const ModeIndicatorChip({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(appModeProvider);
    final requiresVerification = ref.watch(emailVerificationRequiredProvider);
    final isCompact = compact || MediaQuery.of(context).size.width < 360;
    final label = appMode == AppMode.local
        ? (isCompact ? 'Local' : 'Local mode')
        : (isCompact ? 'Account' : 'Account mode');
    final backgroundColor =
        appMode == AppMode.local ? Colors.grey[850] : Colors.blue[900];
    final icon =
        appMode == AppMode.local ? Icons.phone_iphone : Icons.cloud;

    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: isCompact ? 10 : 11)),
          if (appMode == AppMode.account && requiresVerification) ...[
            const SizedBox(width: 4),
            const Icon(Icons.lock, size: 12),
          ],
        ],
      ),
      labelPadding: isCompact ? const EdgeInsets.symmetric(horizontal: 4) : null,
      padding: isCompact ? const EdgeInsets.symmetric(horizontal: 4) : null,
      avatar: Icon(icon, size: 16),
      backgroundColor: backgroundColor,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
