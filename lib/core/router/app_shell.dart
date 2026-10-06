import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_dimens.dart';
import 'package:ascend/core/theme/app_typography.dart';
import 'package:ascend/features/goals/presentation/goal_interactions.dart';
import 'package:ascend/features/habits/presentation/habit_interactions.dart';
import 'package:ascend/features/tasks/presentation/task_form_sheet.dart';
import 'package:ascend/shared/widgets/create_sheet.dart';

class _NavItem {
  const _NavItem(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _items = <_NavItem>[
  _NavItem('Home', Icons.home_outlined, Icons.home_rounded),
  _NavItem(
    'Planner',
    Icons.calendar_month_outlined,
    Icons.calendar_month_rounded,
  ),
  _NavItem('Goals', Icons.flag_outlined, Icons.flag_rounded),
  _NavItem('Stats', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
  _NavItem('Profile', Icons.person_outline_rounded, Icons.person_rounded),
];

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Ширина, с которой нижняя панель заменяется боковой.
  static const double wideBreakpoint = 840;

  void _onSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Future<void> _createTask(BuildContext context) async {
    final saved = await showTaskFormSheet(context);
    if (saved && context.mounted) _snack(context, 'Task created');
  }

  Future<void> _onCreate(BuildContext context) async {
    final action = await showCreateSheet(context);
    if (action == null || !context.mounted) return;

    switch (action) {
      case CreateAction.task:
        await _createTask(context);
      case CreateAction.goal:
        await createGoalAndOpen(context);
      case CreateAction.habit:
        await createHabit(context);
      case CreateAction.note:
      // Заметки появятся на одном из следующих этапов.
        _snack(context, '${action.title} is coming soon');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= wideBreakpoint) {
          return _buildWide(context);
        }
        return _buildCompact(context);
      },
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onCreate(context),
        tooltip: 'Create',
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onSelected,
          destinations: [
            for (final item in _items)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: AppColors.surface,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onSelected,
            labelType: NavigationRailLabelType.all,
            indicatorColor: AppColors.primary.withValues(alpha: 0.18),
            selectedIconTheme: const IconThemeData(
              color: AppColors.primaryLight,
            ),
            unselectedIconTheme: const IconThemeData(
              color: AppColors.textMuted,
            ),
            selectedLabelTextStyle: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            unselectedLabelTextStyle: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: FloatingActionButton(
                onPressed: () => _onCreate(context),
                tooltip: 'Create',
                child: const Icon(Icons.add_rounded),
              ),
            ),
            destinations: [
              for (final item in _items)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}