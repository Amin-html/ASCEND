import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/router/app_router.dart';
import 'package:ascend/core/services/messenger.dart';
import 'package:ascend/core/theme/app_theme.dart';
import 'package:ascend/features/achievements/presentation/achievement_watcher.dart';
import 'package:ascend/features/notifications/presentation/notification_sync.dart';

class AscendApp extends ConsumerWidget {
  const AscendApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ASCEND',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      scaffoldMessengerKey: appMessengerKey,
      builder: (context, child) => AchievementWatcher(
        child: NotificationSync(child: child ?? const SizedBox.shrink()),
      ),
      routerConfig: router,
    );
  }
}