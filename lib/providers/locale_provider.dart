import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言状态管理
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey);
    if (localeCode != null) {
      _locale = Locale(localeCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> toggleLocale() async {
    final newLocale = _locale.languageCode == 'en' ? const Locale('zh') : const Locale('en');
    await setLocale(newLocale);
  }

  bool get isEnglish => _locale.languageCode == 'en';
  bool get isChinese => _locale.languageCode == 'zh';
}