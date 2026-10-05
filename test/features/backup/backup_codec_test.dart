import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/backup/data/backup_codec.dart';
import 'package:ascend/features/backup/domain/backup_exceptions.dart';
import 'package:ascend/features/backup/domain/backup_format.dart';
import 'package:ascend/features/backup/domain/backup_models.dart';

void main() {
  const codec = BackupCodec();
  final createdAt = DateTime.utc(2026, 10, 4, 12);
  const summary = BackupSummary(
    tasks: 3,
    completedTasks: 1,
    goals: 2,
    habits: 1,
    totalXp: 120,
  );
  final payload = <String, Object?>{
    'tables': {
      'tasks': [
        {'id': 'a', 'title': 'Подготовить отчёт'},
      ],
    },
    'settings': {'notificationsEnabled': true},
  };

  Future<Uint8List> encode({String? password}) {
    return codec.encode(
      payload: payload,
      schemaVersion: 1,
      createdAt: createdAt,
      summary: summary,
      password: password,
      iterations: 1000,
    );
  }

  Uint8List tamper(
      Uint8List bytes,
      void Function(Map<String, dynamic> envelope) change,
      ) {
    final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    change(envelope);
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  test('plain backup roundtrip', () async {
    final bytes = await encode();
    final parsed = codec.parse(bytes);

    expect(parsed.header.encrypted, isFalse);
    expect(parsed.header.backupVersion, 1);
    expect(parsed.header.schemaVersion, 1);
    expect(parsed.header.createdAt.isAtSameMomentAs(createdAt), isTrue);
    expect(parsed.header.summary.tasks, 3);
    expect(parsed.header.summary.totalXp, 120);

    expect(await codec.readPayload(parsed), equals(payload));
  });

  test('encrypted backup roundtrip', () async {
    final bytes = await encode(password: 'secret');
    final parsed = codec.parse(bytes);

    expect(parsed.header.encrypted, isTrue);
    expect(parsed.header.kdfIterations, 1000);
    expect(parsed.header.summary.tasks, 3);

    expect(
      await codec.readPayload(parsed, password: 'secret'),
      equals(payload),
    );
  });

  test('encrypted backup requires a password', () async {
    final parsed = codec.parse(await encode(password: 'secret'));

    await expectLater(
      codec.readPayload(parsed),
      throwsA(isA<BackupPasswordRequiredException>()),
    );
  });

  test('wrong password is reported', () async {
    final parsed = codec.parse(await encode(password: 'secret'));

    await expectLater(
      codec.readPayload(parsed, password: 'other'),
      throwsA(isA<BackupWrongPasswordException>()),
    );
  });

  test('changed payload is detected as corruption', () async {
    final bytes = await encode();
    final bad = tamper(bytes, (e) => e['payload'] = base64Encode([1, 2, 3]));

    expect(() => codec.parse(bad), throwsA(isA<BackupCorruptedException>()));
  });

  test('garbage is not a backup', () {
    expect(
          () => codec.parse(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<BackupInvalidFileException>()),
    );
    expect(
          () => codec.parse(Uint8List.fromList(utf8.encode('[]'))),
      throwsA(isA<BackupInvalidFileException>()),
    );
  });

  test('wrong magic is rejected', () async {
    final bad = tamper(await encode(), (e) => e['magic'] = 'SOMETHING_ELSE');

    expect(() => codec.parse(bad), throwsA(isA<BackupInvalidFileException>()));
  });

  test('newer container version is rejected', () async {
    final bad = tamper(await encode(), (e) => e['backupVersion'] = 99);

    expect(() => codec.parse(bad), throwsA(isA<BackupNewerVersionException>()));
  });

  test('absurd KDF iterations are rejected', () async {
    final bytes = await encode(password: 'secret');
    final bad = tamper(bytes, (e) {
      (e['kdf'] as Map<String, dynamic>)['iterations'] = 999999999;
    });

    expect(() => codec.parse(bad), throwsA(isA<BackupInvalidFileException>()));
  });

  test('backupFileName', () {
    expect(
      backupFileName(
        DateTime(2026, 1, 2, 3, 4, 5),
        prefix: 'safety',
        withSeconds: true,
      ),
      'safety-20260102-030405.plannerbackup',
    );
    expect(
      backupFileName(DateTime(2026, 1, 2, 3, 4), prefix: 'safety'),
      'safety-20260102-0304.plannerbackup',
    );
  });
}