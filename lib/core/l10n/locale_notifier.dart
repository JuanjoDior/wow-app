import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends ChangeNotifier {
  static const _key = 'app_locale';
  Locale _locale = const Locale('es');

  Locale get locale => _locale;

  /// Convierte el locale de la app al formato que usa la API de Blizzard
  String get blizzardLocale {
    switch (_locale.languageCode) {
      case 'es':
        return 'es_ES';
      case 'en':
      default:
        return 'en_GB';
    }
  }

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
