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
      body: _TabFade(
        index: navigationShell.currentIndex,
        child: navigationShell,
      ),
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
            extended: true,
            minExtendedWidth: 232,
            backgroundColor: AppColors.surface,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onSelected,
            indicatorColor: AppColors.primary.withValues(alpha: 0.14),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            selectedIconTheme: const IconThemeData(
              color: AppColors.primaryLight,
            ),
            unselectedIconTheme: const IconThemeData(
              color: AppColors.textMuted,
            ),
            selectedLabelTextStyle: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            unselectedLabelTextStyle: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            leading: _RailHeader(onCreate: () => _onCreate(context)),
            destinations: [
              for (final item in _items)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(item.label),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _TabFade(
              index: navigationShell.currentIndex,
              child: navigationShell,
            ),
          ),
        ],
      ),
    );
  }
}

/// Шапка боковой панели: название приложения и кнопка создания.
class _RailHeader extends StatelessWidget {
  const _RailHeader({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 208,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.landscape_rounded,
                  size: 24,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'ASCEND',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FloatingActionButton.extended(
                onPressed: onCreate,
                tooltip: 'Create',
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Короткое появление содержимого при переключении вкладок.
class _TabFade extends StatefulWidget {
  const _TabFade({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
    value: 1,
  );

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.curve,
  );

  @override
  void didUpdateWidget(_TabFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _progress,
      child: AnimatedBuilder(
        animation: _progress,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - _progress.value) * 10),
          child: child,
        ),
      ),
    );
  }
}
