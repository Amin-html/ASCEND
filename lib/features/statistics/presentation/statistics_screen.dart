import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/statistics/data/stats_providers.dart';
import 'package:ascend/features/statistics/domain/stats_models.dart';
import 'package:ascend/shared/widgets/app_card.dart';
import 'package:ascend/shared/widgets/bar_series_chart.dart';
import 'package:ascend/shared/widgets/empty_state.dart';
import 'package:ascend/shared/widgets/error_state.dart';
import 'package:ascend/shared/widgets/stat_tile.dart';
import 'package:ascend/shared/widgets/split_row.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider).now();
    final async = ref.watch(statsRangeProvider(_days));

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      selectedForegroundColor: AppColors.textPrimary,
                      selectedBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.25),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    segments: const [
                      ButtonSegment(value: 7, label: Text('7 days')),
                      ButtonSegment(value: 30, label: Text('30 days')),
                    ],
                    selected: {_days},
                    onSelectionChanged: (selection) =>
                        setState(() => _days = selection.first),
                  ),
                ),
              ),
              Expanded(
                child: async.when(
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => ErrorState(
                    message: 'Could not load statistics.',
                    onRetry: () => ref.invalidate(statsRangeProvider(_days)),
                  ),
                  data: (stored) => _buildContent(stored, now),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<DayStat> stored, DateTime now) {
    final series = buildSeries(stored, now, _days);
    final summary = summarize(series);

    if (!summary.hasActivity) {
      return const EmptyState(
        icon: Icons.insights_rounded,
        title: 'No activity yet',
        message: 'Complete tasks, focus or build habits to see your stats.',
      );
    }

    final dates = [for (final s in series) dateFromDayKey(s.dayKey)];
    final labels = [
      for (final d in dates) _days == 7 ? weekdayAbbr(d) : '${d.day}',
    ];

    List<String> tips(String Function(DayStat s) value) => [
      for (var i = 0; i < series.length; i++)
        '${shortDate(dates[i])}: ${value(series[i])}',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.success,
                  value: '${summary.tasksCompleted}',
                  label: 'Tasks done',
                  caption: '${summary.activeDays} active days',
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: StatTile(
                  icon: Icons.timer_rounded,
                  iconColor: AppColors.primaryLight,
                  value: formatDurationShort(summary.focusSeconds),
                  label: 'Focus time',
                  caption:
                  'Avg ${formatDurationShort(summary.avgFocusSeconds)} / day',
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
                  icon: Icons.bolt_rounded,
                  iconColor: AppColors.accent,
                  value: '${summary.xpEarned}',
                  label: 'XP earned',
                  caption: 'Avg ${summary.avgXp} / day',
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: StatTile(
                  icon: Icons.verified_rounded,
                  iconColor: AppColors.warning,
                  value: '${summary.perfectDays}',
                  label: 'Perfect days',
                  caption: 'Whole plan completed',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _ChartCard(
          title: 'Tasks completed',
          total: 'Total ${summary.tasksCompleted}',
          chart: BarSeriesChart(
            values: [for (final s in series) s.tasksCompleted.toDouble()],
            labels: labels,
            tooltips: tips((s) => '${s.tasksCompleted}'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ChartCard(
          title: 'Focus',
          total: 'Total ${formatDurationShort(summary.focusSeconds)}',
          chart: BarSeriesChart(
            values: [for (final s in series) s.focusSeconds / 60],
            labels: labels,
            tooltips: tips((s) => formatDurationShort(s.focusSeconds)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ChartCard(
          title: 'XP earned',
          total: 'Total ${summary.xpEarned}',
          chart: BarSeriesChart(
            values: [for (final s in series) s.xpEarned.toDouble()],
            labels: labels,
            tooltips: tips((s) => '${s.xpEarned} XP'),
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.total,
    required this.chart,
  });

  final String title;
  final String total;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SplitRow(
            left: Text(title, style: text.titleMedium),
            right: Text(
              total,
              style: text.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          chart,
        ],
      ),
    );
  }
}