import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../services/ai_models.dart';
import '../../services/native_audio_player.dart';
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

  static const Map<Storyteller, String> _greetingAudio = {
    Storyteller.bulgarian: 'assets/audio/bulgarian_greeting_audio.wav',
    Storyteller.turkish: 'assets/audio/turkish_greeting_audio.wav',
  };

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _playGreetingThenAdvance();
  }

  Future<void> _playGreetingThenAdvance() async {
    final audioPath = _greetingAudio[widget.storyteller];
    if (audioPath != null) {
      try {
        final data = await rootBundle.load(audioPath);
        final bytes = data.buffer.asUint8List();
        await NativeAudioPlayer.play(bytes);
      } catch (_) {
        await Future.delayed(const Duration(seconds: 4));
      }
    } else {
      await Future.delayed(const Duration(seconds: 4));
    }

    if (!mounted || _navigated) return;
    _navigated = true;
    _goToCamera();
  }

  void _goToCamera() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CameraScreen(storyteller: widget.storyteller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _greetingImages[widget.storyteller] ??
        'assets/images/bulgarian_greeting.png';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (!_navigated) {
            _navigated = true;
            _goToCamera();
          }
        },
        child: Center(
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            width: double.infinity,
          ),
        ),
      ),
    );
  }
}
