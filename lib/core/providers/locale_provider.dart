import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/app_preferences.dart';

/// Supported locales for DevConnect.
const supportedLocales = [
  Locale('en'), // English (default)
  Locale('vi'), // Vietnamese
  Locale('zh', 'TW'), // Chinese Traditional
  Locale('zh', 'CN'), // Chinese Simplified
  Locale('ja'), // Japanese
  Locale('fr'), // French
];

/// Locale display names for the language switcher.
const localeDisplayNames = {
  'en': 'English',
  'vi': 'Tiếng Việt',
  'zh_TW': '繁體中文',
  'zh_CN': '简体中文',
  'ja': '日本語',
  'fr': 'Français',
};

/// Persisted locale provider. Defaults to English.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_load());

  static Locale _load() {
    final raw = AppPreferences().get<String>('locale');
    switch (raw) {
      case 'vi':
        return const Locale('vi');
      case 'zh_TW':
        return const Locale('zh', 'TW');
      case 'zh_CN':
        return const Locale('zh', 'CN');
      case 'ja':
        return const Locale('ja');
      case 'fr':
        return const Locale('fr');
      default:
        return const Locale('en');
    }
  }

  void setLocale(Locale locale) {
    state = locale;
    final key = locale.countryCode != null
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    AppPreferences().set('locale', key);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);
