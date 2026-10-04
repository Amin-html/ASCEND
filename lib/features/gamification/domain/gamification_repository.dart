abstract interface class GamificationRepository {
  /// Суммарный XP по журналу событий.
  Stream<int> watchTotalXp();

  /// XP, начисленный за локальный день [dayKey] (yyyy-MM-dd).
  Stream<int> watchXpForDay(String dayKey);

  /// Дни, в которые выполнена хотя бы одна задача.
  Stream<Set<String>> watchActiveDays();
}