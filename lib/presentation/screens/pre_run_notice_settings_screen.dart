import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/task_run_notice_service.dart';
import '../viewmodels/pre_run_notice_view_model.dart';

class PreRunNoticeSettingsScreen extends ConsumerStatefulWidget {
  const PreRunNoticeSettingsScreen({super.key});

  @override
  ConsumerState<PreRunNoticeSettingsScreen> createState() =>
      _PreRunNoticeSettingsScreenState();
}

class _PreRunNoticeSettingsScreenState
    extends ConsumerState<PreRunNoticeSettingsScreen> {
  double? _sliderValue;

  @override
  Widget build(BuildContext context) {
    final noticeAsync = ref.watch(preRunNoticeMinutesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Pre-Run Notice'),
      ),
      body: noticeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _errorState(error),
        data: (minutes) => _buildContent(minutes),
      ),
    );
  }

  Widget _buildContent(int minutes) {
    final sliderValue = _sliderValue ?? minutes.toDouble();
    final rounded = sliderValue.round();
    final label =
        rounded == 0 ? 'Pre-run notice is off' : 'Notice $rounded min before';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Controls how early the pre-run countdown starts for scheduled groups.',
          style: TextStyle(color: Colors.white60, height: 1.4),
        ),
        const SizedBox(height: 24),
        Slider(
          value: sliderValue,
          min: TaskRunNoticeService.minNoticeMinutes.toDouble(),
          max: TaskRunNoticeService.maxNoticeMinutes.toDouble(),
          divisions: TaskRunNoticeService.maxNoticeMinutes,
          label: '$rounded min',
          onChanged: (value) {
            setState(() {
              _sliderValue = value;
            });
          },
          onChangeEnd: (value) async {
            final updated = await ref
                .read(preRunNoticeMinutesProvider.notifier)
                .setNoticeMinutes(value.round());
            if (!mounted) return;
            setState(() {
              _sliderValue = updated.toDouble();
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '0 min',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            Text(
              '${TaskRunNoticeService.maxNoticeMinutes} min',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Applies to new scheduled groups only.',
          style: TextStyle(color: Colors.white38, height: 1.4),
        ),
      ],
    );
  }

  Widget _errorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Failed to load notice minutes. $error',
          style: const TextStyle(color: Colors.white60),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
