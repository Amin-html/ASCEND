import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:ascend/core/database/tables.dart';

part 'app_database.g.dart';

const _defaultCategories = <({String id, String name, int color, String icon})>[
  (id: 'cat_work', name: 'Work', color: 0xFF7C3AED, icon: 'work'),
  (id: 'cat_study', name: 'Study', color: 0xFF3B82F6, icon: 'school'),
  (id: 'cat_health', name: 'Health', color: 0xFF22C55E, icon: 'favorite'),
  (id: 'cat_personal', name: 'Personal', color: 0xFFF59E0B, icon: 'person'),
  (id: 'cat_finance', name: 'Finance', color: 0xFF14B8A6, icon: 'payments'),
];

@DriftDatabase(
  tables: [
    Categories,
    RecurrenceRules,
    Goals,
    Milestones,
    Tasks,
    Notes,
    Habits,
    HabitLogs,
    FocusSessions,
    XpEvents,
    Achievements,
    DailyStats,
    UserProfiles,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'ascend'));

  /// Для тестов: `AppDatabase.forTesting(NativeDatabase.memory())`.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaults();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _seedDefaults() async {
    final now = DateTime.now();
    await batch((b) {
      b.insertAll(categories, [
        for (final (index, c) in _defaultCategories.indexed)
          CategoriesCompanion.insert(
            id: c.id,
            name: c.name,
            colorValue: c.color,
            iconKey: c.icon,
            isDefault: const Value(true),
            sortOrder: Value(index),
            createdAt: now,
            updatedAt: now,
          ),
      ]);
      b.insert(
        userProfiles,
        UserProfilesCompanion.insert(
          id: const Value(1),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });
  }
}