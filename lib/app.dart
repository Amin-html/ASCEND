import 'package:flutter/material.dart';

/// Root widget. Theme and router are placeholders until steps 2 and 5.
class AscendApp extends StatelessWidget {
  const AscendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASCEND',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07070A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
      ),
      home: const _BootstrapScreen(),
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'ASCEND',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}