import 'package:ascend/core/database/app_database.dart';
import 'package:ascend/features/profile/domain/profile_repository.dart';
import 'package:ascend/features/profile/domain/user_profile.dart';

class DriftProfileRepository implements ProfileRepository {
  DriftProfileRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<UserProfile> watch() {
    final query = _db.select(_db.userProfiles)..where((p) => p.id.equals(1));
    return query
        .watchSingleOrNull()
        .map((row) => UserProfile(name: row?.name ?? ''));
  }
}