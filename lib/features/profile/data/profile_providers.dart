import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/database/database_providers.dart';
import 'package:ascend/core/services/service_providers.dart';
import 'package:ascend/features/profile/data/drift_profile_actions.dart';
import 'package:ascend/features/profile/data/drift_profile_repository.dart';
import 'package:ascend/features/profile/domain/profile_actions.dart';
import 'package:ascend/features/profile/domain/profile_repository.dart';
import 'package:ascend/features/profile/domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
      (ref) => DriftProfileRepository(ref.watch(appDatabaseProvider)),
);

final profileActionsProvider = Provider<ProfileActions>(
      (ref) => DriftProfileActions(
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final profileProvider = StreamProvider<UserProfile>(
      (ref) => ref.watch(profileRepositoryProvider).watch(),
);