import 'package:flutter/material.dart';

import 'package:ascend/shared/widgets/empty_state.dart';

/// Временная заглушка экрана, пока фича не реализована.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    required this.title,
    required this.icon,
    required this.message,
    super.key,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(icon: icon, title: 'Coming soon', message: message),
    );
  }
}