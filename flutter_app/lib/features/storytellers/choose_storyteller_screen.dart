import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/ai_models.dart';
import '../reading/camera_screen.dart';

class ChooseStorytellerScreen extends StatelessWidget {
  const ChooseStorytellerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Storyteller'),
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
              description: 'Ancient Balkan coffee reading tradition.',
              enabled: true,
              storyteller: Storyteller.bulgarian,
            ),
            const SizedBox(height: AppSpacing.md),
            _StorytellerCard(
              flag: Storyteller.turkish.flag,
              name: Storyteller.turkish.displayName,
              description: 'Traditional Turkish coffee fortune reading.',
              enabled: true,
              storyteller: Storyteller.turkish,
            ),
            const SizedBox(height: AppSpacing.md),
            const _StorytellerCard(
              flag: '🔒',
              name: 'Coming Soon',
              description: 'A new storyteller will arrive in a future update.',
              enabled: false,
              storyteller: null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StorytellerCard extends StatelessWidget {
  const _StorytellerCard({
    required this.flag,
    required this.name,
    required this.description,
    required this.enabled,
    required this.storyteller,
  });

  final String flag;
  final String name;
  final String description;
  final bool enabled;
  final Storyteller? storyteller;

  @override
  Widget build(BuildContext context) {
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
              description,
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
                            builder: (context) =>
                                CameraScreen(storyteller: storyteller!),
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
                child: Text(enabled ? 'Select' : 'Coming Soon'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
