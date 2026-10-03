import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ascend/features/settings/data/shared_prefs_settings_repository.dart';
import 'package:ascend/features/settings/domain/app_settings.dart';
import 'package:ascend/features/settings/domain/settings_repository.dart';

/// Переопределяется в main() готовым экземпляром SharedPreferences.
final sharedPreferencesProvider = Provider<SharedPreferences>(
      (ref) => throw UnimplementedError('Override in main()'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
      (ref) => SharedPrefsSettingsRepository(ref.watch(sharedPreferencesProvider)),
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> update(AppSettings Function(AppSettings current) change) async {
    final next = change(state);
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);