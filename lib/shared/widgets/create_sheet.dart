import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/shared/widgets/app_card.dart';
import 'package:ascend/shared/widgets/fade_slide_in.dart';
import 'package:ascend/shared/widgets/icon_badge.dart';

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
      child: SingleChildScrollView(
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
            for (var i = 0; i < CreateAction.values.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: FadeSlideIn(
                  delay: Duration(milliseconds: 50 * i),
                  offset: 10,
                  child: _CreateTile(action: CreateAction.values[i]),
                ),
              ),
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

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      onTap: () => Navigator.of(context).pop(action),
      child: Row(
        children: [
          IconBadge(icon: action.icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.title, style: text.titleMedium),
                Text(
                  action.subtitle,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
