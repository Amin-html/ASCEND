import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/router/app_routes.dart';
import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/focus/data/focus_providers.dart';
import 'package:ascend/shared/widgets/app_card.dart';

class HomeFocusCard extends ConsumerWidget {
  const HomeFocusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final todayKey = dayKeyOf(ref.watch(clockProvider).now());
    final seconds = ref.watch(focusSecondsForDayProvider(todayKey)).value ?? 0;

    return AppCard(
      onTap: () => context.push(AppRoutes.focus),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: const Icon(
              Icons.timer_rounded,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Focus', style: text.titleMedium),
                Text(
                  seconds <= 0
                      ? 'Start a focus session'
                      : 'Today: ${formatMinutes(seconds ~/ 60)}',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.focus),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}