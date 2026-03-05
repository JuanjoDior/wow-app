import 'package:wow_companion/core/wow/supported_regions.dart';

String normalizeRegion(String value) {
  final normalized = value.trim().toLowerCase();
  if (isSupportedRegion(normalized)) return normalized;
  return normalized;
}

String normalizeName(String value) {
  return value.trim().toLowerCase();
}

String normalizeRealmForRequest(String value) {
  final normalizedWhitespace = value.trim().toLowerCase().replaceAll(
    RegExp(r'\s+'),
    ' ',
  );
  return normalizedWhitespace.replaceAll(' ', '-');
}

String buildCharacterRoute({
  required String region,
  required String realm,
  required String name,
}) {
  final normalizedRegion = Uri.encodeComponent(normalizeRegion(region));
  final normalizedRealm = Uri.encodeComponent(normalizeRealmForRequest(realm));
  final normalizedName = Uri.encodeComponent(normalizeName(name));
  return '/character/$normalizedRegion/$normalizedRealm/$normalizedName';
}

String buildCompareRoute({
  required String region1,
  required String realm1,
  required String name1,
  required String region2,
  required String realm2,
  required String name2,
}) {
  final leftRegion = Uri.encodeComponent(normalizeRegion(region1));
  final leftRealm = Uri.encodeComponent(normalizeRealmForRequest(realm1));
  final leftName = Uri.encodeComponent(normalizeName(name1));
  final rightRegion = Uri.encodeComponent(normalizeRegion(region2));
  final rightRealm = Uri.encodeComponent(normalizeRealmForRequest(realm2));
  final rightName = Uri.encodeComponent(normalizeName(name2));
  return '/compare/$leftRegion/$leftRealm/$leftName/vs/$rightRegion/$rightRealm/$rightName';
}

String buildWeeklyPlannerRoute({
  required String region,
  required String realm,
  required String name,
}) {
  final normalizedRegion = Uri.encodeComponent(normalizeRegion(region));
  final normalizedRealm = Uri.encodeComponent(normalizeRealmForRequest(realm));
  final normalizedName = Uri.encodeComponent(normalizeName(name));
  return '/planner/$normalizedRegion/$normalizedRealm/$normalizedName';
}
