import 'package:ascend/features/statistics/domain/stats_models.dart';

abstract interface class StatsRepository {
  /// Сохранённые дни в диапазоне [fromDayKey, toDayKey] включительно.
  Stream<List<DayStat>> watchRange(String fromDayKey, String toDayKey);
}