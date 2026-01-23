import 'package:flutter/material.dart';
import '../data/models/pomodoro_task.dart';
import '../data/models/selected_sound.dart';
import '../data/services/local_sound_overrides.dart';

enum _TaskCardAction { edit, delete }

class _SoundLabel {
  final String text;
  final bool isDefault;

  const _SoundLabel({required this.text, required this.isDefault});
}

class _SoundLabels {
  final _SoundLabel start;
  final _SoundLabel breakStart;

  const _SoundLabels({required this.start, required this.breakStart});
}

class TaskCard extends StatelessWidget {
  final PomodoroTask task;
  final VoidCallback onTap;
  final bool selected;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget? reorderHandle;
  final String? timeRange;
  final LocalSoundOverrides? soundOverrides;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.selected,
    required this.onEdit,
    required this.onDelete,
    this.reorderHandle,
    this.timeRange,
    this.soundOverrides,
  });

  @override
  Widget build(BuildContext context) {
    final title = task.name.isEmpty ? "(Untitled)" : task.name;

    final cardColor = selected ? Colors.white12 : Colors.white10;
    final borderColor = selected ? Colors.white38 : Colors.white12;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: selected ? 1.2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _statCard(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${task.totalPomodoros}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _metricCircle(
                                    value: "${task.pomodoroMinutes}",
                                    size: 30,
                                    stroke: 2,
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _statCard(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _metricCircle(
                                    value: "${task.shortBreakMinutes}",
                                    size: 30,
                                    stroke: 1,
                                    color: Colors.blueAccent,
                                    fontSize: 12,
                                  ),
                                  const SizedBox(width: 6),
                                  _metricCircle(
                                    value: "${task.longBreakMinutes}",
                                    size: 30,
                                    stroke: 3,
                                    color: Colors.blueAccent,
                                    fontSize: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _statCard(
                            child: _breakDots(task.longBreakInterval),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Colors.white12),
                    const SizedBox(height: 8),
                    if (timeRange != null) ...[
                      Row(
                        children: [
                          const Text(
                            "Time range",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: _timeRangeChips(timeRange!)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    _buildSoundRow(),
                  ],
                ),
              ),
              if (reorderHandle != null) reorderHandle!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundRow() {
    final fallback = _SoundLabels(
      start: _soundLabel(task.startSound, slot: SoundSlot.pomodoroStart),
      breakStart: _soundLabel(task.startBreakSound, slot: SoundSlot.breakStart),
    );
    final overrides = soundOverrides;
    if (overrides == null) {
      return _soundRow(fallback);
    }
    return FutureBuilder<_SoundLabels>(
      future: _resolveSoundLabels(overrides),
      builder: (context, snapshot) {
        return _soundRow(snapshot.data ?? fallback);
      },
    );
  }

  Widget _soundRow(_SoundLabels labels) {
    return Row(
      children: [
        Expanded(
          child: _soundEntry(
            color: Colors.redAccent,
            label: labels.start.text,
            isDefault: labels.start.isDefault,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 1,
          height: 18,
          color: Colors.white24,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _soundEntry(
            color: Colors.blueAccent,
            label: labels.breakStart.text,
            isDefault: labels.breakStart.isDefault,
          ),
        ),
      ],
    );
  }

  Future<_SoundLabels> _resolveSoundLabels(LocalSoundOverrides overrides) async {
    final startOverride = await overrides.getOverride(
      task.id,
      SoundSlot.pomodoroStart,
    );
    final breakOverride = await overrides.getOverride(
      task.id,
      SoundSlot.breakStart,
    );
    return _SoundLabels(
      start: _overrideLabel(startOverride) ??
          _soundLabel(task.startSound, slot: SoundSlot.pomodoroStart),
      breakStart: _overrideLabel(breakOverride) ??
          _soundLabel(task.startBreakSound, slot: SoundSlot.breakStart),
    );
  }

  _SoundLabel? _overrideLabel(LocalSoundOverride? override) {
    if (override == null) return null;
    final name = override.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return _SoundLabel(text: name, isDefault: false);
    }
    final path = override.sound.value;
    final fallback = _basename(path);
    return fallback.isEmpty
        ? null
        : _SoundLabel(text: fallback, isDefault: false);
  }

  Widget _metricCircle({
    required String value,
    required double size,
    required double stroke,
    required Color color,
    double? fontSize,
  }) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize ?? (size * 0.36),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard({required Widget child}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: child,
    );
  }

  Widget _breakDots(int interval) {
    final redDots = interval <= 0 ? 1 : interval;
    final totalDots = redDots + 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 120.0;
        const maxHeight = 24.0;
        var dotSize = 6.0;
        var spacing = 4.0;
        const minDot = 3.5;

        while (dotSize >= minDot) {
          final rows = _rowsFor(maxHeight, dotSize, spacing, totalDots);
          final maxCols = _maxColsFor(maxWidth, dotSize, spacing);
          if (rows * maxCols >= totalDots) break;
          dotSize -= 0.5;
          spacing = dotSize <= 4 ? 2 : 3;
        }

        if (redDots == 1) {
          return SizedBox(
            height: maxHeight,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Dot(color: Colors.redAccent, size: dotSize),
                  SizedBox(width: spacing),
                  _Dot(color: Colors.blueAccent, size: dotSize),
                ],
              ),
            ),
          );
        }

        final rows = _rowsFor(maxHeight, dotSize, spacing, totalDots);
        final maxCols = _maxColsFor(maxWidth, dotSize, spacing);
        final redColsNeeded = (redDots / rows).ceil();
        final blueSeparate = redColsNeeded < maxCols;
        final columns = <Widget>[];
        var remainingRed = redDots;
        final redColumnsCount = blueSeparate ? redColsNeeded : maxCols;

        for (var col = 0; col < redColumnsCount; col += 1) {
          final isLast = col == redColumnsCount - 1;
          final capacity = (!blueSeparate && isLast) ? rows - 1 : rows;
          final take = remainingRed > capacity ? capacity : remainingRed;
          remainingRed -= take;
          columns.add(
            _dotColumn(
              redCount: take,
              includeBlue: !blueSeparate && isLast,
              dotSize: dotSize,
              spacing: spacing,
              height: maxHeight,
            ),
          );
        }

        if (blueSeparate) {
          columns.add(
            _dotColumn(
              redCount: 0,
              includeBlue: true,
              dotSize: dotSize,
              spacing: spacing,
              height: maxHeight,
            ),
          );
        }

        return SizedBox(
          height: maxHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _withColumnSpacing(columns, spacing + 2),
          ),
        );
      },
    );
  }

  int _rowsFor(
    double maxHeight,
    double dotSize,
    double spacing,
    int totalDots,
  ) {
    final rows = ((maxHeight + spacing) / (dotSize + spacing)).floor();
    if (rows < 1) return 1;
    return rows > totalDots ? totalDots : rows;
  }

  int _maxColsFor(double maxWidth, double dotSize, double spacing) {
    final cols = ((maxWidth + spacing) / (dotSize + spacing)).floor();
    return cols < 1 ? 1 : cols;
  }

  List<Widget> _withColumnSpacing(List<Widget> columns, double spacing) {
    final spaced = <Widget>[];
    for (var i = 0; i < columns.length; i += 1) {
      spaced.add(columns[i]);
      if (i < columns.length - 1) {
        spaced.add(SizedBox(width: spacing));
      }
    }
    return spaced;
  }

  Widget _dotColumn({
    required int redCount,
    required bool includeBlue,
    required double dotSize,
    required double spacing,
    required double height,
  }) {
    return SizedBox(
      width: dotSize,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (var i = 0; i < redCount; i += 1) ...[
            _Dot(color: Colors.redAccent, size: dotSize),
            if (i < redCount - 1) SizedBox(height: spacing),
          ],
          if (includeBlue) ...[
            if (redCount > 0) SizedBox(height: spacing),
            _Dot(color: Colors.blueAccent, size: dotSize),
          ],
        ],
      ),
    );
  }

  Widget _soundEntry({
    required Color color,
    required String label,
    required bool isDefault,
  }) {
    return Row(
      children: [
        Icon(Icons.volume_up_rounded, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isDefault ? Colors.white54 : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _timeRangeChips(String timeRange) {
    final parts = _splitTimeRange(timeRange);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: parts.map(_timeChip).toList(),
    );
  }

  List<String> _splitTimeRange(String timeRange) {
    final trimmed = timeRange.trim();
    if (trimmed.contains('–')) {
      final parts = trimmed.split('–');
      if (parts.length == 2) {
        return [parts.first.trim(), parts.last.trim()];
      }
    }
    if (trimmed.contains('-')) {
      final parts = trimmed.split('-');
      if (parts.length == 2) {
        return [parts.first.trim(), parts.last.trim()];
      }
    }
    return [trimmed];
  }

  Widget _timeChip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _SoundLabel _soundLabel(
    SelectedSound sound, {
    required SoundSlot slot,
  }) {
    if (sound.type == SoundType.custom) {
      final name = _basename(sound.value);
      return _SoundLabel(
        text: name.isEmpty ? "Custom file" : name,
        isDefault: false,
      );
    }

    final defaultId = slot == SoundSlot.pomodoroStart
        ? 'default_chime'
        : 'default_chime_break';
    if (sound.value.isEmpty || sound.value == defaultId) {
      final label = slot == SoundSlot.pomodoroStart
          ? 'Default chime'
          : 'Default break chime';
      return _SoundLabel(text: label, isDefault: true);
    }

    final label = switch (sound.value) {
      'default_chime' => 'Chime',
      'default_chime_break' => 'Break chime',
      'default_chime_finish' => 'Finish chime',
      _ => sound.value,
    };
    return _SoundLabel(text: label, isDefault: true);
  }

  String _basename(String path) {
    final parts = path.split(RegExp(r'[\\/]+'));
    return parts.isNotEmpty ? parts.last : path;
  }

  Future<void> _showContextMenu(BuildContext context) async {
    final overlayState = Overlay.of(context);
    if (overlayState == null) return;
    final overlay = overlayState.context.findRenderObject() as RenderBox?;
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return;
    final position = box.localToGlobal(Offset.zero, ancestor: overlay);
    final rect = Rect.fromLTWH(
      position.dx,
      position.dy,
      box.size.width,
      box.size.height,
    );
    final action = await showMenu<_TaskCardAction>(
      context: context,
      color: const Color(0xFF1A1A1A),
      position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
      items: const [
        PopupMenuItem<_TaskCardAction>(
          value: _TaskCardAction.edit,
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text('Edit', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem<_TaskCardAction>(
          value: _TaskCardAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.redAccent, size: 18),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
    if (action == _TaskCardAction.edit) {
      onEdit();
      return;
    }
    if (action == _TaskCardAction.delete) {
      onDelete();
    }
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;

  const _Dot({required this.color, this.size = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
