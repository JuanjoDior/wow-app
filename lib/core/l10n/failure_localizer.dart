import 'package:wow_companion/l10n/generated/app_localizations.dart';

String localizeFailureMessage(S t, String message) {
  final normalized = message.trim().toLowerCase();

  if (normalized.contains('character not found')) return t.characterNotFound;
  if (normalized.contains('too many requests') ||
      normalized.contains('rate limit')) {
    return t.rateLimitError;
  }
  if (normalized.contains('could not connect') ||
      normalized.contains('no internet') ||
      normalized.contains('request timed out')) {
    return t.networkError;
  }
  if (normalized.contains('cache')) return t.cacheError;
  if (normalized.contains('server error') ||
      normalized.contains('something went wrong on the server') ||
      normalized.contains('unexpected response from worker') ||
      normalized.contains('unknown worker error')) {
    return t.serverError;
  }

  return message;
}

String? localizeFailureSuggestion(S t, String? suggestion) {
  if (suggestion == null || suggestion.trim().isEmpty) return suggestion;

  final normalized = suggestion.trim().toLowerCase();

  if (normalized.contains('try again in a few seconds')) {
    return t.serverErrorSuggestion;
  }
  if (normalized.contains('check your connection and try again') ||
      normalized.contains('check your connection')) {
    return t.networkErrorSuggestion;
  }
  if (normalized.contains('try refreshing')) {
    return t.cacheErrorSuggestion;
  }
  if (normalized.contains('wait a moment and try again')) {
    return t.rateLimitErrorSuggestion;
  }
  if (normalized.contains('check region, realm and name') ||
      normalized.contains('check the region, realm, and character name')) {
    return t.checkRealmAndName;
  }

  return suggestion;
}
