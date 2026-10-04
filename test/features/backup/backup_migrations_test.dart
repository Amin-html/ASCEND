import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/backup/domain/backup_exceptions.dart';
import 'package:ascend/features/backup/domain/backup_migrations.dart';

void main() {
  test('same version is a no-op', () {
    final payload = <String, Object?>{'a': 1};

    expect(
      const BackupMigrations().upgrade(payload, from: 1, to: 1),
      equals(payload),
    );
  });

  test('missing migration step is rejected', () {
    expect(
          () => const BackupMigrations().upgrade(
        <String, Object?>{},
        from: 1,
        to: 2,
      ),
      throwsA(isA<BackupInvalidFileException>()),
    );
  });
}