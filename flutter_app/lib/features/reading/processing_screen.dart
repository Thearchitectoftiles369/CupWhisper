import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ai_models.dart';
import '../../services/ai_service.dart';
import '../../services/app_language.dart';
import '../../services/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/user_repository.dart';
import 'reading_result_screen.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({
    super.key,
    required this.imagePath,
    required this.storyteller,
  });

  final String imagePath;
  final Storyteller storyteller;

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  final AIService _aiService = BackendAIService();

  @override
  void initState() {
    super.initState();
    _generateReading();
  }

  Future<void> _generateReading() async {
    final language = ref.read(appLanguageProvider);

    final result = await _aiService.generateReading(
      imagePath: widget.imagePath,
      storyteller: widget.storyteller,
      language: language,
    );

    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateLastStoryteller(user.uid, widget.storyteller);
      await repo.saveReading(
        uid: user.uid,
        storyteller: widget.storyteller,
        language: language,
        result: result.story,
      );
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ReadingResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('☕', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                ref.tr('reading_symbols'),
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                ref.tr('please_wait'),
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
