import 'package:flutter/material.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/theme/app_theme.dart';
import 'package:ascend/core/theme/app_typography.dart';
import 'package:ascend/shared/widgets/app_card.dart';
import 'package:ascend/shared/widgets/empty_state.dart';
import 'package:ascend/shared/widgets/progress_ring.dart';
import 'package:ascend/shared/widgets/xp_bar.dart';

/// Root widget. Router подключим на этапе 5.
class AscendApp extends StatelessWidget {
  const AscendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASCEND',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      home: const _BootstrapScreen(),
    );
  }
}

/// Временный экран для визуальной проверки дизайн-системы.
class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ASCEND', style: text.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Plan. Focus. Complete. Ascend.',
                style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppCard(
                glow: true,
                child: Row(
                  children: [
                    ProgressRing(
                      value: 0.65,
                      size: 96,
                      strokeWidth: 9,
                      child: Text(
                        '65%',
                        style: AppTypography.numeric.copyWith(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Today's plan", style: text.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '5 of 8 tasks completed',
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppCard(
                child: XpBar(level: 7, currentXp: 340, nextLevelXp: 520),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: EmptyState(
                  icon: Icons.checklist_rounded,
                  title: 'No tasks yet',
                  message: 'Create your first task to start earning XP.',
                  actionLabel: 'Add task',
                  onAction: () {},
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: () {}, child: const Text('New task')),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
            ],
          ),
        ),
      ),
    );
  }
}