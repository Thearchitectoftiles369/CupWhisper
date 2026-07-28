import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/ai_models.dart';
import '../../services/app_strings.dart';
import 'storyteller_greeting_screen.dart';

class ChooseStorytellerScreen extends ConsumerWidget {
  const ChooseStorytellerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr('choose_storyteller_title')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            _StorytellerCard(
              flag: Storyteller.bulgarian.flag,
              name: Storyteller.bulgarian.displayName,
              descriptionKey: 'bulgarian_desc',
              enabled: true,
              storyteller: Storyteller.bulgarian,
            ),
            const SizedBox(height: AppSpacing.md),
            _StorytellerCard(
              flag: Storyteller.turkish.flag,
              name: Storyteller.turkish.displayName,
              descriptionKey: 'turkish_desc',
              enabled: true,
              storyteller: Storyteller.turkish,
            ),
            const SizedBox(height: AppSpacing.md),
            _StorytellerCard(
              flag: '🔒',
              name: ref.tr('coming_soon'),
              descriptionKey: 'coming_soon_desc',
              enabled: false,
              storyteller: null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StorytellerCard extends ConsumerWidget {
  const _StorytellerCard({
    required this.flag,
    required this.name,
    required this.descriptionKey,
    required this.enabled,
    required this.storyteller,
  });

  final String flag;
  final String name;
  final String descriptionKey;
  final bool enabled;
  final Storyteller? storyteller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(flag, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: AppSpacing.sm),
            Text(name, style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              ref.tr(descriptionKey),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: enabled && storyteller != null
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => StorytellerGreetingScreen(
                              storyteller: storyteller!,
                            ),
                          ),
                        );
                      }
                    : null,
                style: enabled
                    ? null
                    : ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkChocolateVariant,
                        foregroundColor: AppColors.warmCreamMuted,
                      ),
                child: Text(enabled ? ref.tr('select') : ref.tr('coming_soon')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
