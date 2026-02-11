import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends ChangeNotifier {
  static const _key = 'app_locale';
  Locale _locale = const Locale('es');

  Locale get locale => _locale;

  /// Carga el idioma guardado o usa 'es' por defecto
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'es';
    _locale = Locale(code);
    notifyListeners();
  }

  /// Cambia el idioma y lo persiste
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, newLocale.languageCode);
  }

  /// Toggle rápido entre es/en
  Future<void> toggleLocale() async {
    final next = _locale.languageCode == 'es'
        ? const Locale('en')
        : const Locale('es');
    await setLocale(next);
  }
}
