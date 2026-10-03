import 'package:flutter/material.dart';

import 'package:ascend/shared/widgets/coming_soon_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Goals',
      icon: Icons.flag_rounded,
      message: 'Long-term goals and milestones will live here.',
    );
  }
}