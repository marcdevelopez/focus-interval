import 'package:firebase_auth/firebase_auth.dart';
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
    final label = appMode == AppMode.local ? 'Local' : 'Account';
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

class ModeIndicatorAction extends ConsumerWidget {
  final bool compact;
  final VoidCallback? onTap;
  final double maxEmailWidth;

  const ModeIndicatorAction({
    super.key,
    this.compact = false,
    this.onTap,
    this.maxEmailWidth = 180,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(appModeProvider);
    final user = ref.watch(currentUserProvider);
    final email = _accountLabel(user);
    final isAccount = appMode == AppMode.account && email.isNotEmpty;
    final canShowEmail =
        isAccount && !compact && MediaQuery.of(context).size.width >= 420;
    final effectiveOnTap = onTap ??
        (!canShowEmail && isAccount
            ? () => _showAccountDialog(context, email)
            : null);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ModeIndicatorChip(compact: compact),
        if (canShowEmail) ...[
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxEmailWidth),
            child: Text(
              email,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );

    if (effectiveOnTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: effectiveOnTap,
      child: content,
    );
  }

  String _accountLabel(User? user) {
    if (user == null) return '';
    final email = user.email;
    if (email != null && email.trim().isNotEmpty) return email.trim();
    return user.uid;
  }

  void _showAccountDialog(BuildContext context, String email) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Active account'),
          content: Text(email),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
