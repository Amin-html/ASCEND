import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';

enum CreateAction {
  task(
    'New task',
    'Plan something and earn XP',
    Icons.check_circle_outline_rounded,
  ),
  goal(
    'New goal',
    'Break a big result into milestones',
    Icons.flag_outlined,
  ),
  habit(
    'New habit',
    'Build a streak day by day',
    Icons.repeat_rounded,
  ),
  note(
    'New note',
    'Capture a thought',
    Icons.sticky_note_2_outlined,
  );

  const CreateAction(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}

Future<CreateAction?> showCreateSheet(BuildContext context) {
  return showModalBottomSheet<CreateAction>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => const _CreateSheet(),
  );
}

class _CreateSheet extends StatelessWidget {
  const _CreateSheet();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text('Create', style: text.titleLarge),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final action in CreateAction.values)
              _CreateTile(action: action),
          ],
        ),
      ),
    );
  }
}

class _CreateTile extends StatelessWidget {
  const _CreateTile({required this.action});

  final CreateAction action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListTile(
      onTap: () => Navigator.of(context).pop(action),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Icon(action.icon, color: AppColors.primaryLight),
      ),
      title: Text(action.title, style: text.titleMedium),
      subtitle: Text(
        action.subtitle,
        style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}