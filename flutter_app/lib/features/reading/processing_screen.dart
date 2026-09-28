import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ai_models.dart';
import '../../services/ai_service.dart';
import '../../services/app_language.dart';
import '../../services/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/user_repository.dart';
import 'symbol_reveal_screen.dart';

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

  static const List<String> _messageKeys = [
    'processing_msg_1',
    'processing_msg_2',
    'processing_msg_3',
    'processing_msg_4',
  ];

  int _messageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _messageTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messageKeys.length;
      });
    });
    _generateReading();
  }

  Future<void> _generateReading() async {
    final language = ref.read(appLanguageProvider);
    final user = ref.read(authServiceProvider).currentUser;

    try {
      bool usedFree = true;
      if (user != null) {
        final repo = ref.read(userRepositoryProvider);
        usedFree = await repo.hasUsedFreeReading(user.uid);
      }

      ReadingResult result;
      if (!usedFree) {
        try {
          result = await _aiService.generateFreeReading(
            imagePath: widget.imagePath,
            storyteller: widget.storyteller,
            language: language,
          );
        } on FreeReadingUsedException {
          result = await _aiService.generateReading(
            imagePath: widget.imagePath,
            storyteller: widget.storyteller,
            language: language,
          );
        }
      } else {
        result = await _aiService.generateReading(
          imagePath: widget.imagePath,
          storyteller: widget.storyteller,
          language: language,
        );
      }

      if (user != null) {
        final repo = ref.read(userRepositoryProvider);
        await repo.updateLastStoryteller(user.uid, widget.storyteller);
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SymbolRevealScreen(result: result),
        ),
      );
    } on NoCreditsException {
      if (!mounted) return;
      _showErrorAndGoBack(ref.tr('no_credits_message'));
    } catch (e) {
      if (!mounted) return;
      _showErrorAndGoBack(ref.tr('reading_error_message'));
    }
  }

  void _showErrorAndGoBack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
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
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  ref.tr(_messageKeys[_messageIndex]),
                  key: ValueKey(_messageIndex),
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
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
