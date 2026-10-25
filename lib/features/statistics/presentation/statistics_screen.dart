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
import 'package:ascend/shared/widgets/fade_slide_in.dart';
import 'package:ascend/shared/widgets/page_header.dart';
import 'package:ascend/shared/widgets/segment_control.dart';
import 'package:ascend/shared/widgets/split_row.dart';
import 'package:ascend/shared/widgets/stat_tile.dart';

/// Ширина контента, с которой плитки идут в один ряд, а графики в два столбца.
const double _wideWidth = 760;

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

    final content = async.when<List<Widget>>(
      loading: () => const [
        Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (error, stack) => [
        ErrorState(
          message: 'Could not load statistics.',
          onRetry: () => ref.invalidate(statsRangeProvider(_days)),
        ),
      ],
      data: (stored) => _buildContent(stored, now),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              children: [
                const PageHeader(title: 'Statistics'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: SegmentControl<int>(
                    segments: const [(7, '7 days'), (30, '30 days')],
                    selected: _days,
                    onChanged: (value) => setState(() => _days = value),
                  ),
                ),
                ...content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(List<DayStat> stored, DateTime now) {
    final series = buildSeries(stored, now, _days);
    final summary = summarize(series);

    if (!summary.hasActivity) {
      return const [
        EmptyState(
          icon: Icons.insights_rounded,
          title: 'No activity yet',
          message: 'Complete tasks, focus or build habits to see your stats.',
        ),
      ];
    }

    final dates = [for (final s in series) dateFromDayKey(s.dayKey)];
    final labels = [
      for (final d in dates) _days == 7 ? weekdayAbbr(d) : '${d.day}',
    ];

    List<String> tips(String Function(DayStat s) value) => [
      for (var i = 0; i < series.length; i++)
        '${shortDate(dates[i])}: ${value(series[i])}',
    ];

    Widget stagger(int index, Widget child) => FadeSlideIn(
      delay: Duration(milliseconds: 60 * index),
      child: child,
    );

    final tiles = <Widget>[
      stagger(
        0,
        StatTile(
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.success,
          value: '${summary.tasksCompleted}',
          countTo: summary.tasksCompleted,
          label: 'Tasks done',
          caption: '${summary.activeDays} active days',
        ),
      ),
      stagger(
        1,
        StatTile(
          icon: Icons.timer_rounded,
          iconColor: AppColors.primaryLight,
          value: formatDurationShort(summary.focusSeconds),
          label: 'Focus time',
          caption: 'Avg ${formatDurationShort(summary.avgFocusSeconds)} / day',
        ),
      ),
      stagger(
        2,
        StatTile(
          icon: Icons.bolt_rounded,
          iconColor: AppColors.accent,
          value: '${summary.xpEarned}',
          countTo: summary.xpEarned,
          label: 'XP earned',
          caption: 'Avg ${summary.avgXp} / day',
        ),
      ),
      stagger(
        3,
        StatTile(
          icon: Icons.verified_rounded,
          iconColor: AppColors.warning,
          value: '${summary.perfectDays}',
          countTo: summary.perfectDays,
          label: 'Perfect days',
          caption: 'Whole plan completed',
        ),
      ),
    ];

    final charts = <Widget>[
      stagger(
        4,
        _ChartCard(
          title: 'Tasks completed',
          total: 'Total ${summary.tasksCompleted}',
          chart: BarSeriesChart(
            values: [for (final s in series) s.tasksCompleted.toDouble()],
            labels: labels,
            tooltips: tips((s) => '${s.tasksCompleted}'),
          ),
        ),
      ),
      stagger(
        5,
        _ChartCard(
          title: 'Focus',
          total: 'Total ${formatDurationShort(summary.focusSeconds)}',
          chart: BarSeriesChart(
            values: [for (final s in series) s.focusSeconds / 60],
            labels: labels,
            tooltips: tips((s) => formatDurationShort(s.focusSeconds)),
          ),
        ),
      ),
      stagger(
        6,
        _ChartCard(
          title: 'XP earned',
          total: 'Total ${summary.xpEarned}',
          chart: BarSeriesChart(
            values: [for (final s in series) s.xpEarned.toDouble()],
            labels: labels,
            tooltips: tips((s) => '${s.xpEarned} XP'),
          ),
        ),
      ),
    ];

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _wideWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TileGrid(tiles: tiles, columns: wide ? 4 : 2),
                const SizedBox(height: AppSpacing.xxl),
                if (wide)
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.lg,
                    children: [
                      for (final chart in charts)
                        SizedBox(
                          width: (constraints.maxWidth - AppSpacing.lg) / 2,
                          child: chart,
                        ),
                    ],
                  )
                else
                  for (var i = 0; i < charts.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.lg),
                    charts[i],
                  ],
              ],
            );
          },
        ),
      ),
    ];
  }
}

/// Плитки рядами по [columns] штук. Плитки в ряду одной высоты.
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles, required this.columns});

  final List<Widget> tiles;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += columns) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = i; j < i + columns; j++) ...[
                  if (j > i) const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: j < tiles.length
                        ? tiles[j]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
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
