import 'package:wow_companion/l10n/generated/app_localizations.dart';

const List<String> supportedRegionCodes = <String>['eu', 'us', 'kr', 'tw'];

bool isSupportedRegion(String code) {
  final normalized = code.trim().toLowerCase();
  return supportedRegionCodes.contains(normalized);
}

String regionLabel(String code, S t) {
  switch (code.trim().toLowerCase()) {
    case 'eu':
      return t.regionEurope;
    case 'us':
      return t.regionAmericas;
    case 'kr':
      return t.regionKorea;
    case 'tw':
      return t.regionTaiwan;
    default:
      return code.toUpperCase();
  }
}

String regionFlag(String code) {
  switch (code.trim().toLowerCase()) {
    case 'eu':
      return '🇪🇺';
    case 'us':
      return '🇺🇸';
    case 'kr':
      return '🇰🇷';
    case 'tw':
      return '🇹🇼';
    default:
      return '🌍';
  }
}
