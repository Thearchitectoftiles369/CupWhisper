import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/user_repository.dart';
import '../home/home_screen.dart';

class AIDisclosureScreen extends ConsumerStatefulWidget {
  const AIDisclosureScreen({super.key});

  @override
  ConsumerState<AIDisclosureScreen> createState() =>
      _AIDisclosureScreenState();
}

class _AIDisclosureScreenState extends ConsumerState<AIDisclosureScreen> {
  bool _showMore = false;

  Future<void> _continue() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      await ref.read(userRepositoryProvider).markDisclosureSeen(user.uid);
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('☕', style: TextStyle(fontSize: 56)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                ref.tr('disclosure_title'),
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        ref.tr('disclosure_body'),
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.warmCream,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_showMore) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          ref.tr('disclosure_learn_more_body'),
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.warmCreamMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (!_showMore)
                TextButton(
                  onPressed: () => setState(() => _showMore = true),
                  child: Text(ref.tr('learn_more')),
                ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continue,
                  child: Text(ref.tr('i_understand')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
