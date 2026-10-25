import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/achievements/data/achievement_providers.dart';
import 'package:ascend/features/achievements/domain/achievement_models.dart';
import 'package:ascend/features/achievements/presentation/achievement_icons.dart';
import 'package:ascend/shared/widgets/app_card.dart';
import 'package:ascend/shared/widgets/fade_slide_in.dart';
import 'package:ascend/shared/widgets/gradient_progress_bar.dart';
import 'package:ascend/shared/widgets/progress_ring.dart';
import 'package:ascend/shared/widgets/split_row.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final metrics = ref.watch(achievementMetricsProvider);
    final unlocked = ref.watch(unlockedAchievementsProvider).value ??
        const <String, DateTime>{};

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: metrics == null
          ? const Center(child: CircularProgressIndicator())
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _buildList(
                  text,
                  buildAchievementEntries(metrics, unlocked),
                ),
              ),
            ),
    );
  }

  Widget _buildList(TextTheme text, List<AchievementEntry> entries) {
    final done = entries.where((e) => e.isUnlocked).length;
    final fraction = entries.isEmpty ? 0.0 : done / entries.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        FadeSlideIn(
          child: AppCard(
            glow: entries.isNotEmpty && done == entries.length,
            child: Row(
              children: [
                ProgressRing(
                  value: fraction,
                  size: 72,
                  strokeWidth: 7,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$done/${entries.length}',
                        maxLines: 1,
                        style: text.labelLarge,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: SplitRow(
                    left: Text('Your progress', style: text.titleMedium),
                    right: Text(
                      '$done of ${entries.length} unlocked',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: FadeSlideIn(
              key: ValueKey(entries[i].def.code),
              delay: Duration(milliseconds: 60 * (i + 1)),
              child: _AchievementTile(entry: entries[i]),
            ),
          ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.entry});

  final AchievementEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final def = entry.def;
    final unlockedAt = entry.unlockedAt;
    final unlocked = entry.isUnlocked;

    return AppCard(
      glow: unlocked,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unlocked
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.sunsetPink],
                    )
                  : null,
              color: unlocked ? null : AppColors.surfaceHighest,
            ),
            child: Icon(
              achievementIcon(def.code),
              color: unlocked ? Colors.white : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.title,
                  style: text.titleMedium?.copyWith(
                    color: unlocked
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  def.description,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (unlockedAt != null)
                  Text(
                    'Unlocked ${longDate(unlockedAt.toLocal())}',
                    style: text.labelSmall?.copyWith(color: AppColors.success),
                  )
                else ...[
                  GradientProgressBar(value: entry.fraction, height: 5),
                  const SizedBox(height: 4),
                  Text(
                    def.progressLabel(entry.current),
                    style: text.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
