import 'package:flutter/material.dart';

import '../../domain/continuous_plan_load.dart';

class ContinuousPlanLoadVisual {
  const ContinuousPlanLoadVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

ContinuousPlanLoadVisual? continuousPlanLoadVisualForLevel(
  ContinuousPlanLoadLevel level,
) {
  switch (level) {
    case ContinuousPlanLoadLevel.unusual:
      return const ContinuousPlanLoadVisual(
        icon: Icons.warning_amber_rounded,
        color: Colors.amberAccent,
      );
    case ContinuousPlanLoadLevel.superhuman:
      return const ContinuousPlanLoadVisual(
        icon: Icons.bolt_rounded,
        color: Colors.orangeAccent,
      );
    case ContinuousPlanLoadLevel.machineLevel:
      return const ContinuousPlanLoadVisual(
        icon: Icons.memory_rounded,
        color: Colors.redAccent,
      );
    case ContinuousPlanLoadLevel.none:
      return null;
  }
}

Widget? buildContinuousPlanLoadChip(
  ContinuousPlanLoadLevel level, {
  double fontSize = 11,
}) {
  if (level == ContinuousPlanLoadLevel.none) return null;
  final visual = continuousPlanLoadVisualForLevel(level);
  if (visual == null) return null;
  final label = continuousPlanLoadLabel(level);
  if (label.isEmpty) return null;
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 116),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: visual.color.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: 13, color: visual.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: visual.color,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
