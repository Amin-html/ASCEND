import 'package:ascend/features/settings/domain/app_settings.dart';

abstract interface class SettingsRepository {
  AppSettings load();
  Future<void> save(AppSettings settings);
}