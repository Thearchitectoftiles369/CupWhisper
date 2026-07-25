import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/home/home_screen.dart';

class CupWhisperApp extends StatelessWidget {
  const CupWhisperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CupWhisper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
