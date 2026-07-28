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
  static const Map<Storyteller, String> _greetingImages = {
    Storyteller.bulgarian: 'assets/images/bulgarian_greeting.png',
    Storyteller.turkish: 'assets/images/turkish_greeting.png',
  };

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
    final imagePath = _greetingImages[widget.storyteller] ??
        'assets/images/bulgarian_greeting.png';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          width: double.infinity,
        ),
      ),
    );
  }
}
