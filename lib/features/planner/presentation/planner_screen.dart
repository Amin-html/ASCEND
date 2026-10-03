import 'package:flutter/material.dart';

import 'package:ascend/shared/widgets/coming_soon_screen.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Planner',
      icon: Icons.calendar_month_rounded,
      message: 'Today, tomorrow, week and month views will live here.',
    );
  }
}