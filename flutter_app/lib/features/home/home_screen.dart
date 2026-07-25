import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../storytellers/choose_storyteller_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '☕',
                style: TextStyle(fontSize: 64),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'CupWhisper',
                style: textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Every cup has a story waiting to be told.',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.warmCreamMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ChooseStorytellerScreen(),
                      ),
                    );
                  },
                  child: const Text('Begin Reading'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
