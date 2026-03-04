import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/task_run_group.dart';
import '../providers.dart';

void openRunModeForGroup(
  BuildContext context,
  WidgetRef ref,
  TaskRunGroup group,
) {
  ref.read(pomodoroViewModelProvider.notifier).primeGroupForLoad(group);
  if (!context.mounted) return;
  context.go('/timer/${group.id}');
}
