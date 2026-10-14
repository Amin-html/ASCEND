import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/theme/app_typography.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/notifications/data/notification_providers.dart';
import 'package:ascend/features/notifications/presentation/notification_labels.dart';
import 'package:ascend/features/settings/data/settings_providers.dart';
import 'package:ascend/shared/widgets/app_card.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _toggleMaster(
      BuildContext context,
      WidgetRef ref,
      bool value,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(settingsProvider.notifier);
    final service = ref.read(notificationServiceProvider);

    if (value) {
      final granted = await service.requestPermission();
      if (!granted) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Notifications are blocked for ASCEND. '
                    'Allow them in the system settings.',
              ),
            ),
          );
        return;
      }
    }
    await controller.update((s) => s.copyWith(notificationsEnabled: value));
  }

  Future<void> _pickTime(
      BuildContext context,
      WidgetRef ref,
      int current,
      ) async {
    final controller = ref.read(settingsProvider.notifier);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    await controller.update(
          (s) => s.copyWith(
        dailyPlanReminderMinutes: picked.hour * 60 + picked.minute,
      ),
    );
  }

  Future<void> _sendTest(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(notificationServiceProvider).showTest();
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Test notification scheduled. It should appear in a few seconds.'
                : 'Could not schedule a notification on this device.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final available = ref.watch(notificationsAvailableProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              if (available == false) ...[
                AppCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Notifications are not available on this device.',
                          style: text.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              _SwitchCard(
                title: 'Allow notifications',
                subtitle: 'Task reminders and daily plan alerts',
                value: settings.notificationsEnabled,
                onChanged: (value) => _toggleMaster(context, ref, value),
              ),
              if (settings.notificationsEnabled) ...[
                const SizedBox(height: AppSpacing.xxl),
                Text('Default reminder', style: text.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Used for new tasks that have a start time.',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final m in reminderPresets)
                      ChoiceChip(
                        showCheckmark: false,
                        label: Text(reminderLabel(m)),
                        selected: settings.defaultReminderMinutesBefore == m,
                        onSelected: (_) => controller.update(
                              (s) => s.copyWith(defaultReminderMinutesBefore: m),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                _SwitchCard(
                  title: 'Evening plan reminder',
                  subtitle: 'Only on days with unfinished tasks',
                  value: settings.dailyPlanReminderEnabled,
                  onChanged: (value) => controller.update(
                        (s) => s.copyWith(dailyPlanReminderEnabled: value),
                  ),
                ),
                if (settings.dailyPlanReminderEnabled) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    onTap: () => _pickTime(
                      context,
                      ref,
                      settings.dailyPlanReminderMinutes,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text('Reminder time', style: text.titleMedium),
                        ),
                        Text(
                          minutesOfDayLabel(settings.dailyPlanReminderMinutes),
                          style: AppTypography.numeric.copyWith(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                OutlinedButton(
                  onPressed:
                  available == false ? null : () => _sendTest(context, ref),
                  child: const Text('Send test notification'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}