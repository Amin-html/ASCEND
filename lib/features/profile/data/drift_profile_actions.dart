import 'package:drift/drift.dart';

import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/core/services/clock.dart';
import 'package:ascend/features/profile/domain/profile_actions.dart';
import 'package:ascend/features/profile/domain/user_profile.dart';

class DriftProfileActions implements ProfileActions {
  DriftProfileActions({required this._db, required this._clock});

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<void> setName(String name) {
    final clean = normalizeName(name);

    return _db.transaction(() async {
      final now = _clock.now();
      final updated = await (_db.update(_db.userProfiles)
        ..where((p) => p.id.equals(1)))
          .write(
        UserProfilesCompanion(name: Value(clean), updatedAt: Value(now)),
      );
      // Строка профиля создаётся при первом запуске, но после неудачного
      // восстановления её может не быть.
      if (updated == 0) {
        await _db.into(_db.userProfiles).insert(
          UserProfilesCompanion.insert(
            id: const Value(1),
            name: Value(clean),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    });
  }
}