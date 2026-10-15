import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/profile/data/drift_profile_actions.dart';
import 'package:ascend/features/profile/data/drift_profile_repository.dart';

import '../../helpers/fakes.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);

  late AppDatabase db;
  late DriftProfileRepository repo;
  late DriftProfileActions actions;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftProfileRepository(db);
    actions = DriftProfileActions(db: db, clock: FakeClock(now));
  });

  tearDown(() async {
    await db.close();
  });

  test('a fresh database has an empty name', () async {
    final profile = await repo.watch().first;

    expect(profile.name, '');
    expect(profile.hasName, isFalse);
  });

  test('setName saves a normalized name', () async {
    await actions.setName('  Amin   Adilov ');

    expect((await repo.watch().first).name, 'Amin Adilov');
  });

  test('setName overwrites and can clear the name', () async {
    await actions.setName('Amin');
    await actions.setName('Sam');
    expect((await repo.watch().first).name, 'Sam');

    await actions.setName('   ');
    expect((await repo.watch().first).hasName, isFalse);
  });

  test('setName records the change time', () async {
    await actions.setName('Amin');

    final row = await (db.select(db.userProfiles)
      ..where((p) => p.id.equals(1)))
        .getSingle();
    expect(row.updatedAt, now);
  });

  test('setName works even if the profile row is missing', () async {
    await db.delete(db.userProfiles).go();

    await actions.setName('Sam');

    expect((await repo.watch().first).name, 'Sam');
    expect((await db.select(db.userProfiles).get()).length, 1);
  });

  test('watch follows changes', () async {
    final names = <String>[];
    final sub = repo.watch().listen((p) => names.add(p.name));
    addTearDown(sub.cancel);

    await Future<void>.delayed(Duration.zero);
    await actions.setName('Amin');
    await Future<void>.delayed(Duration.zero);

    expect(names.first, '');
    expect(names.last, 'Amin');
  });
}