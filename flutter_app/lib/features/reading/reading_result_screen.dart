import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/ai_models.dart';
import '../../services/app_strings.dart';
import '../home/home_screen.dart';

class ReadingResultScreen extends ConsumerWidget {
  const ReadingResultScreen({super.key, required this.result});

  final ReadingResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                result.storyteller.flag,
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                ref.tr('${result.storyteller.id}_name'),
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.warmCreamMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                result.story,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.warmCream,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: Text(ref.tr('back_to_home')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
