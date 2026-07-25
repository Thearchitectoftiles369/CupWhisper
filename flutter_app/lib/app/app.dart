import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';

class CupWhisperApp extends StatelessWidget {
  const CupWhisperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CupWhisper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.brown,
      ),
      home: const HomeScreen(),
    );
  }
}
