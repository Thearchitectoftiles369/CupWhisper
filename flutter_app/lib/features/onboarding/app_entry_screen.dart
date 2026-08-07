import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/user_repository.dart';
import '../home/home_screen.dart';
import 'ai_disclosure_screen.dart';

class AppEntryScreen extends ConsumerStatefulWidget {
  const AppEntryScreen({super.key});

  @override
  ConsumerState<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends ConsumerState<AppEntryScreen> {
  bool? _hasSeenDisclosure;

  @override
  void initState() {
    super.initState();
    _checkDisclosure();
  }

  Future<void> _checkDisclosure() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      setState(() => _hasSeenDisclosure = true);
      return;
    }
    final seen = await ref.read(userRepositoryProvider).hasSeenDisclosure(user.uid);
    if (!mounted) return;
    setState(() => _hasSeenDisclosure = seen);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSeenDisclosure == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _hasSeenDisclosure!
        ? const HomeScreen()
        : const AIDisclosureScreen();
  }
}
