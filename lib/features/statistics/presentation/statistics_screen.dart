import 'package:flutter/material.dart';

import 'package:ascend/shared/widgets/coming_soon_screen.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Stats',
      icon: Icons.bar_chart_rounded,
      message: 'Productivity charts and trends will live here.',
    );
  }
}