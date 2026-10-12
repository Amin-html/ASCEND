import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/database/database_providers.dart';
import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/core/utils/day_key.dart';
import 'package:ascend/features/statistics/data/drift_stats_repository.dart';
import 'package:ascend/features/statistics/domain/stats_models.dart';
import 'package:ascend/features/statistics/domain/stats_repository.dart';

final statsRepositoryProvider = Provider<StatsRepository>(
      (ref) => DriftStatsRepository(ref.watch(appDatabaseProvider)),
);

/// Сохранённые дни за последние [days] дней, включая сегодня.
final statsRangeProvider = StreamProvider.family<List<DayStat>, int>((
    ref,
    days,
    ) {
  final now = ref.watch(clockProvider).now();
  final to = DateTime(now.year, now.month, now.day);
  final from = DateTime(to.year, to.month, to.day - (days - 1));
  return ref
      .watch(statsRepositoryProvider)
      .watchRange(dayKeyOf(from), dayKeyOf(to));
});