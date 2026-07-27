import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final container = ProviderContainer();
  await container.read(authServiceProvider).ensureSignedIn();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CupWhisperApp(),
    ),
  );
}
