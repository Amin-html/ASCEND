import 'package:flutter/material.dart';

import 'package:ascend/shared/widgets/coming_soon_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Home',
      icon: Icons.home_rounded,
      message: "Today's plan, XP and streak will live here.",
    );
  }
}