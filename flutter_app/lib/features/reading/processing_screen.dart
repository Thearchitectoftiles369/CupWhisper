import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ai_models.dart';
import '../../services/ai_service.dart';
import '../../services/app_language.dart';
import '../../services/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/purchase_service.dart';
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
  final PurchaseService _purchaseService = PurchaseService();

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
      _offerPurchase();
    } catch (e) {
      if (!mounted) return;
      _showErrorAndGoBack(ref.tr('reading_error_message'));
    }
  }

  Future<void> _offerPurchase() async {
    final wantsToBuy = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(ref.tr('buy_reading_title')),
        content: Text(ref.tr('buy_reading_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(ref.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(ref.tr('buy_for_price')),
          ),
        ],
      ),
    );

    if (wantsToBuy != true) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    try {
      final success = await _purchaseService.buyReadingCredit();
      if (!mounted) return;

      if (success) {
        _generateReading();
      } else {
        _showErrorAndGoBack(ref.tr('purchase_failed_message'));
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorAndGoBack(ref.tr('purchase_failed_message'));
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
