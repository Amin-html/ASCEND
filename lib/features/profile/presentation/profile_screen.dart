import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/router/app_routes.dart';
import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/theme/app_typography.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/achievements/data/achievement_providers.dart';
import 'package:ascend/features/achievements/domain/achievement_models.dart';
import 'package:ascend/features/achievements/presentation/achievement_icons.dart';
import 'package:ascend/features/gamification/data/gamification_providers.dart';
import 'package:ascend/shared/widgets/app_card.dart';
import 'package:ascend/shared/widgets/progress_ring.dart';
import 'package:ascend/shared/widgets/stat_tile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final progress = ref.watch(levelProgressProvider);
    final rank = ref.watch(xpEngineProvider).rankForLevel(progress.level);
    final nextRank = rank.next;
    final todayKey = dayKeyOf(ref.watch(clockProvider).now());
    final streak = ref.watch(streakProvider(todayKey));
    final metrics = ref.watch(achievementMetricsProvider);
    final unlocked = ref.watch(unlockedAchievementsProvider).value ??
        const <String, DateTime>{};

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
              AppCard(
                glow: true,
                child: Row(
                  children: [
                    ProgressRing(
                      value: progress.fraction,
                      size: 112,
                      strokeWidth: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'LEVEL',
                            style: text.labelSmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            '${progress.level}',
                            style: AppTypography.numeric.copyWith(fontSize: 34),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rank.label, style: text.titleLarge),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${progress.xpIntoLevel} / '
                                '${progress.xpForNextLevel} XP to next level',
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            nextRank == null
                                ? 'Highest rank reached'
                                : 'Next rank: ${nextRank.label} '
                                'at level ${nextRank.minLevel}',
                            style: text.bodySmall?.copyWith(
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: AppColors.warning,
                        value: '${streak.current}',
                        label: 'Day streak',
                        caption: 'Best: ${streak.best}',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: StatTile(
                        icon: Icons.check_circle_rounded,
                        iconColor: AppColors.success,
                        value: metrics == null ? '–' : '${metrics.completedTasks}',
                        label: 'Tasks done',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: Icons.timer_rounded,
                        iconColor: AppColors.primaryLight,
                        value: metrics == null
                            ? '–'
                            : formatDurationShort(metrics.focusSeconds),
                        label: 'Focus time',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: StatTile(
                        icon: Icons.bolt_rounded,
                        iconColor: AppColors.accent,
                        value: '${progress.totalXp}',
                        label: 'Total XP',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _AchievementsPreview(unlocked: unlocked),
              const SizedBox(height: AppSpacing.md),
              _MenuTile(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: 'Reminders and daily plan alerts',
                onTap: () => context.push(AppRoutes.notifications),
              ),
              const SizedBox(height: AppSpacing.md),
              _MenuTile(
                icon: Icons.backup_rounded,
                title: 'Data & Backup',
                subtitle: 'Export and restore your data',
                onTap: () => context.push(AppRoutes.backup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementsPreview extends StatelessWidget {
  const _AchievementsPreview({required this.unlocked});

  final Map<String, DateTime> unlocked;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = achievementDefs.length;
    final done = achievementDefs.where((d) => unlocked.containsKey(d.code)).length;

    return AppCard(
      onTap: () => context.push(AppRoutes.achievements),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Achievements', style: text.titleMedium)),
              Text(
                '$done of $total',
                style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: () => context.push(AppRoutes.achievements),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final d in achievementDefs)
                Tooltip(
                  message: d.title,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unlocked.containsKey(d.code)
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.surfaceHighest,
                    ),
                    child: Icon(
                      achievementIcon(d.code),
                      size: 22,
                      color: unlocked.containsKey(d.code)
                          ? AppColors.primaryLight
                          : AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(icon, color: AppColors.primaryLight),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                Text(
                  subtitle,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}