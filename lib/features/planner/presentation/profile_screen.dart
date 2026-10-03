import 'package:flutter/material.dart';

import 'package:ascend/shared/widgets/coming_soon_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Profile',
      icon: Icons.person_rounded,
      message: 'Level, rank, achievements and settings will live here.',
    );
  }
}