import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/app_language.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = ref.watch(appLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                'Language',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...AppLanguage.values.map((language) {
              final isSelected = language == selectedLanguage;
              return Card(
                color: isSelected
                    ? AppColors.darkChocolateVariant
                    : AppColors.darkChocolate,
                child: ListTile(
                  leading: Text(
                    language.flag,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(language.displayName),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.antiqueGold,
                        )
                      : null,
                  onTap: () {
                    ref
                        .read(appLanguageProvider.notifier)
                        .setLanguage(language);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
