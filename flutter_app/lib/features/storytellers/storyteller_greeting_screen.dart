import 'package:flutter/material.dart';
import '../../services/ai_models.dart';
import '../reading/camera_screen.dart';

class StorytellerGreetingScreen extends StatefulWidget {
  const StorytellerGreetingScreen({super.key, required this.storyteller});

  final Storyteller storyteller;

  @override
  State<StorytellerGreetingScreen> createState() =>
      _StorytellerGreetingScreenState();
}

class _StorytellerGreetingScreenState
    extends State<StorytellerGreetingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CameraScreen(storyteller: widget.storyteller),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          'assets/images/bulgarian_greeting.png',
          fit: BoxFit.contain,
          width: double.infinity,
        ),
      ),
    );
  }
}
