import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage {
  english(code: 'en', displayName: 'English', flag: '🇬🇧'),
  bulgarian(code: 'bg', displayName: 'Български', flag: '🇧🇬'),
  turkish(code: 'tr', displayName: 'Türkçe', flag: '🇹🇷'),
  german(code: 'de', displayName: 'Deutsch', flag: '🇩🇪'),
  french(code: 'fr', displayName: 'Français', flag: '🇫🇷'),
  spanish(code: 'es', displayName: 'Español', flag: '🇪🇸');

  const AppLanguage({
    required this.code,
    required this.displayName,
    required this.flag,
  });

  final String code;
  final String displayName;
  final String flag;
}

class AppLanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.english;

  void setLanguage(AppLanguage language) {
    state = language;
  }
}

final appLanguageProvider =
    NotifierProvider<AppLanguageNotifier, AppLanguage>(
  AppLanguageNotifier.new,
);
