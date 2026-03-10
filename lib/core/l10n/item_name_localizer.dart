import 'package:wow_companion/features/items/domain/entities/item.dart';

extension ItemNameLocalizer on Item {
  String primaryNameForLanguage(String languageCode) {
    final normalized = languageCode.trim().toLowerCase();
    final localized = localizedName?.trim();
    final canonical = canonicalNameEn?.trim();

    if (normalized == 'es') {
      if (localized != null && localized.isNotEmpty) return localized;
      if (canonical != null && canonical.isNotEmpty) return canonical;
      return name;
    }

    if (canonical != null && canonical.isNotEmpty) return canonical;
    if (localized != null && localized.isNotEmpty) return localized;
    return name;
  }

  String? secondaryNameForLanguage(String languageCode) {
    final normalized = languageCode.trim().toLowerCase();
    final localized = localizedName?.trim();
    final canonical = canonicalNameEn?.trim();

    if (localized == null || localized.isEmpty) return null;
    if (canonical == null || canonical.isEmpty) return null;
    if (_normalizeName(localized) == _normalizeName(canonical)) return null;

    return normalized == 'es' ? canonical : localized;
  }

  static String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
