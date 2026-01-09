import 'package:flutter/material.dart';

class SoundOption {
  final String id;
  final String label;
  const SoundOption(this.id, this.label);
}

class SoundSelector extends StatelessWidget {
  final String label;
  final String value;
  final List<SoundOption> options;
  final ValueChanged<String> onChanged;

  const SoundSelector({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValue =
        options.any((o) => o.id == value) ? value : options.first.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: effectiveValue,
          dropdownColor: Colors.black,
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
          items: options
              .map(
                (o) => DropdownMenuItem<String>(
                  value: o.id,
                  child: Text(o.label),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
