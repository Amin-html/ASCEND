import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/backup/data/backup_codec.dart';
import 'package:ascend/features/backup/data/backup_service.dart';
import 'package:ascend/features/backup/domain/backup_exceptions.dart';
import 'package:ascend/features/gamification/domain/xp_engine.dart';
import 'package:ascend/features/settings/domain/app_settings.dart';
import 'package:ascend/features/tasks/data/drift_task_actions.dart';
import 'package:ascend/features/tasks/domain/task.dart';

import '../../helpers/fakes.dart';

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

Future<void> expectSameData(Env actual, Env expected) async {
  expect(
    await actual.db.select(actual.db.tasks).get(),
    unorderedEquals(await expected.db.select(expected.db.tasks).get()),
  );
  expect(
    await actual.db.select(actual.db.xpEvents).get(),
    unorderedEquals(await expected.db.select(expected.db.xpEvents).get()),
  );
  expect(
    await actual.db.select(actual.db.categories).get(),
    unorderedEquals(await expected.db.select(expected.db.categories).get()),
  );
  expect(
    await actual.db.select(actual.db.dailyStats).get(),
    unorderedEquals(await expected.db.select(expected.db.dailyStats).get()),
  );
  expect(
    await actual.db.select(actual.db.userProfiles).get(),
    unorderedEquals(await expected.db.select(expected.db.userProfiles).get()),
  );
  expect(actual.settings.current, expected.settings.current);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Env a;
  late Env b;
  // ... остальное без изменений

  Future<void> fillSource() async {
    await a.addTask('t1', dayKey: '2026-10-04', xp: 25);
    await a.addTask('t2', dayKey: '2026-10-04');
    await a.actions.complete('t1');
    a.settings.current = const AppSettings(
      notificationsEnabled: false,
      defaultReminderMinutesBefore: 30,
    );
  }

  setUp(() {
    a = Env();
    b = Env();
  });

  tearDown(() async {
    await a.close();
    await b.close();
  });

  test('backup then restore reproduces the same data', () async {
    await fillSource();

    final file = await a.service.createBackup();
    expect(file.fileName, 'ascend-backup-20261004-1000.plannerbackup');

    await b.service.restore(file.bytes);

    await expectSameData(b, a);
  });

  test('header summary describes the content', () async {
    await fillSource();

    final file = await a.service.createBackup();
    final summary = a.service.inspect(file.bytes).header.summary;

    expect(summary.tasks, 2);
    expect(summary.completedTasks, 1);
    expect(summary.totalXp, 25);
  });

  test('restore replaces existing data', () async {
    await fillSource();
    await b.addTask('x');

    final file = await a.service.createBackup();
    await b.service.restore(file.bytes);

    expect(await b.taskIds(), unorderedEquals(['t1', 't2']));
  });

  test('restore saves a safety copy of the previous data first', () async {
    await fillSource();
    await b.addTask('x');

    final file = await a.service.createBackup();
    await b.service.restore(file.bytes);

    expect(b.safety.files.length, 1);
    final name = b.safety.files.keys.single;
    expect(name, startsWith('safety-before-restore-'));

    final summary = b.service.inspect(b.safety.files[name]!).header.summary;
    expect(summary.tasks, 1);
  });

  test('encrypted backup roundtrip through the service', () async {
    await fillSource();

    final file = await a.service.createBackup(password: 'secret');
    final header = a.service.inspect(file.bytes).header;
    expect(header.encrypted, isTrue);
    expect(header.summary.tasks, 2);

    await b.service.restore(file.bytes, password: 'secret');

    await expectSameData(b, a);
  });

  test('wrong password changes nothing', () async {
    await fillSource();
    await b.addTask('x');

    final file = await a.service.createBackup(password: 'secret');

    await expectLater(
      b.service.restore(file.bytes, password: 'wrong'),
      throwsA(isA<BackupWrongPasswordException>()),
    );
    expect(await b.taskIds(), ['x']);
    expect(b.safety.files, isEmpty);
  });

  test('failed restore rolls back completely', () async {
    await fillSource();
    await b.addTask('x');

    const codec = BackupCodec();
    final good = await a.service.createBackup();
    final parsed = codec.parse(good.bytes);
    final payload = await codec.readPayload(parsed);
    final tables = payload['tables']! as Map<String, dynamic>;
    final tasks = tables['tasks']! as List<dynamic>;
    // Ссылка на несуществующую цель нарушает внешний ключ.
    (tasks.first as Map<String, dynamic>)['goalId'] = 'missing-goal';
    final bad = await codec.encode(
      payload: payload,
      schemaVersion: a.db.schemaVersion,
      createdAt: DateTime.now(),
      summary: parsed.header.summary,
    );

    await expectLater(
      b.service.restore(bad),
      throwsA(isA<BackupRestoreFailedException>()),
    );
    expect(await b.taskIds(), ['x']);
  });

  test('backup from a newer schema is rejected', () async {
    await fillSource();
    const codec = BackupCodec();
    final good = await a.service.createBackup();
    final parsed = codec.parse(good.bytes);
    final payload = await codec.readPayload(parsed);
    final future = await codec.encode(
      payload: payload,
      schemaVersion: 999,
      createdAt: DateTime.now(),
      summary: parsed.header.summary,
    );

    expect(
          () => b.service.inspect(future),
      throwsA(isA<BackupNewerVersionException>()),
    );
    await expectLater(
      b.service.restore(future),
      throwsA(isA<BackupNewerVersionException>()),
    );
  });
}