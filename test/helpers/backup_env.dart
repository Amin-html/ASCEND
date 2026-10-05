import 'package:drift/native.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/backup/data/backup_service.dart';
import 'package:ascend/features/gamification/domain/xp_engine.dart';
import 'package:ascend/features/tasks/data/drift_task_actions.dart';
import 'package:ascend/features/tasks/domain/task.dart';

import 'fakes.dart';

/// Одно «устройство»: своя БД в памяти, настройки и хранилище safety-копий.
class Env {
  Env() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    clock = FakeClock(DateTime(2026, 10, 4, 10));
    settings = InMemorySettingsRepository();
    safety = FakeSafetyBackupStore();
    actions = DriftTaskActions(
      db: db,
      clock: clock,
      ids: SequentialIds(),
      engine: const XpEngine(),
    );
    service = BackupService(
      db: db,
      settings: settings,
      clock: clock,
      safetyStore: safety,
      kdfIterations: 1000,
    );
  }

  late final AppDatabase db;
  late final FakeClock clock;
  late final InMemorySettingsRepository settings;
  late final FakeSafetyBackupStore safety;
  late final DriftTaskActions actions;
  late final BackupService service;

  Future<void> close() => db.close();

  Future<void> addTask(String id, {String? dayKey, int xp = 10}) {
    final now = clock.now();
    return actions.save(
      Task(
        id: id,
        title: 'Task $id',
        dayKey: dayKey,
        xpReward: xp,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<List<String>> taskIds() async {
    final rows = await db.select(db.tasks).get();
    return rows.map((t) => t.id).toList();
  }
}