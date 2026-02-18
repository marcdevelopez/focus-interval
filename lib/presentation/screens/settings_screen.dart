import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/task_run_notice_service.dart';
import '../../widgets/mode_indicator.dart';
import '../viewmodels/pre_run_notice_view_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticeSubtitle = ref.watch(preRunNoticeMinutesProvider).when(
          data: (minutes) {
            if (minutes <= TaskRunNoticeService.minNoticeMinutes) {
              return 'Off';
            }
            return 'Notice $minutes min before';
          },
          loading: () => 'Loading...',
          error: (_, __) => 'Unavailable',
        );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Settings'),
        actions: const [ModeIndicatorAction(compact: true)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel('Presets'),
          _settingsTile(
            context,
            title: 'Manage presets',
            subtitle: 'Create, edit, delete, and set defaults',
            icon: Icons.tune,
            onTap: () => context.push('/settings/presets'),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Scheduling'),
          _settingsTile(
            context,
            title: 'Pre-run notice',
            subtitle: noticeSubtitle,
            icon: Icons.schedule,
            onTap: () => context.push('/settings/pre-run-notice'),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Preferences'),
          _settingsTile(
            context,
            title: 'Language',
            subtitle: 'System (auto-detect)',
            icon: Icons.language,
            onTap: () {},
            enabled: false,
          ),
          _settingsTile(
            context,
            title: 'Theme',
            subtitle: 'Dark',
            icon: Icons.dark_mode,
            onTap: () {},
            enabled: false,
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return ListTile(
      enabled: enabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: enabled ? Colors.white70 : Colors.white24),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white38,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled ? Colors.white60 : Colors.white24,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: enabled ? Colors.white54 : Colors.white24,
      ),
      onTap: enabled ? onTap : null,
    );
  }
}
