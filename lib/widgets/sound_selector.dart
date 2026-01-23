import 'package:flutter/material.dart';

import '../data/models/selected_sound.dart';

class SoundOption {
  final String id;
  final String label;
  const SoundOption(this.id, this.label);
}

class SoundSelector extends StatelessWidget {
  static const String _localPickId = '__local_pick__';
  static const String _customCurrentId = '__custom_current__';

  final String label;
  final SelectedSound value;
  final List<SoundOption> options;
  final ValueChanged<SelectedSound> onChanged;
  final VoidCallback? onPickLocal;
  final String? customDisplayName;
  final Widget? leading;
  final Widget? trailing;

  const SoundSelector({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.onPickLocal,
    this.customDisplayName,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final hasCustom = value.type == SoundType.custom;
    final customName = hasCustom
        ? (customDisplayName != null && customDisplayName!.trim().isNotEmpty
            ? customDisplayName!.trim()
            : _basename(value.value))
        : '';

    final items = <DropdownMenuItem<String>>[
      if (onPickLocal != null)
        const DropdownMenuItem(
          value: _localPickId,
          child: Text('Choose local file...'),
        ),
      ...options.map(
        (o) => DropdownMenuItem<String>(value: o.id, child: Text(o.label)),
      ),
      if (hasCustom)
        DropdownMenuItem<String>(
          value: _customCurrentId,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Custom: $customName'),
            ],
          ),
        ),
    ];

    final builtInIds = options.map((o) => o.id).toSet();
    final effectiveValue = hasCustom
        ? _customCurrentId
        : (builtInIds.contains(value.value) ? value.value : options.first.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey(effectiveValue),
          initialValue: effectiveValue,
          dropdownColor: const Color(0xFF1A1A1A),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white10,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
          ),
          iconEnabledColor: Colors.white70,
          style: const TextStyle(color: Colors.white),
          items: items,
          onChanged: (v) {
            if (v == null) return;
            if (v == _localPickId) {
              onPickLocal?.call();
              return;
            }
            if (v == _customCurrentId) {
              return;
            }
            onChanged(SelectedSound.builtIn(v));
          },
        ),
      ],
    );
  }

  String _basename(String path) {
    final parts = path.split(RegExp(r'[\\/]+'));
    return parts.isNotEmpty ? parts.last : path;
  }
}
