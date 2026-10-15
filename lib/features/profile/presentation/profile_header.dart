import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/features/profile/data/profile_providers.dart';
import 'package:ascend/features/profile/domain/user_profile.dart';
import 'package:ascend/features/profile/presentation/name_dialog.dart';
import 'package:ascend/shared/widgets/app_card.dart';

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key});

  Future<void> _edit(
      BuildContext context,
      WidgetRef ref,
      UserProfile profile,
      ) async {
    final name = await showNameDialog(context, initial: profile.name);
    if (name == null || !context.mounted) return;
    await ref.read(profileActionsProvider).setName(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final profile = ref.watch(profileProvider).value ?? const UserProfile();

    return AppCard(
      onTap: () => _edit(context, ref, profile),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: profile.hasName
                ? Text(
              profile.initial,
              style: text.titleLarge?.copyWith(color: Colors.white),
            )
                : const Icon(Icons.person_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.hasName ? profile.name : 'Add your name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium,
                ),
                Text(
                  'Tap to change',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_rounded, size: 20, color: AppColors.textMuted),
        ],
      ),
    );
  }
}