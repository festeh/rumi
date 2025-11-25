import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ASRLanguage {
  auto,
  ru,
  en,
}

extension ASRLanguageExtension on ASRLanguage {
  String get displayName {
    switch (this) {
      case ASRLanguage.auto:
        return 'Auto-detect';
      case ASRLanguage.ru:
        return 'Russian';
      case ASRLanguage.en:
        return 'English';
    }
  }

  String get code {
    switch (this) {
      case ASRLanguage.auto:
        return '';
      case ASRLanguage.ru:
        return 'ru';
      case ASRLanguage.en:
        return 'en';
    }
  }
}

class ASRSettingsProvider extends ChangeNotifier {
  static const String _languageKey = 'asr_language';

  ASRLanguage _language = ASRLanguage.auto;
  bool _isLoaded = false;

  ASRLanguage get language => _language;
  bool get isLoaded => _isLoaded;

  ASRSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageIndex = prefs.getInt(_languageKey);
      if (languageIndex != null && languageIndex < ASRLanguage.values.length) {
        _language = ASRLanguage.values[languageIndex];
      }
    } catch (e) {
      // Use default on error
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(ASRLanguage language) async {
    if (_language == language) return;

    _language = language;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_languageKey, language.index);
    } catch (e) {
      // Setting change still works even if persistence fails
    }
  }
}
