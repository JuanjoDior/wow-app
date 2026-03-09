import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/core/l10n/failure_localizer.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

Future<S> _loadL10n(Locale locale) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  return S.delegate.load(locale);
}

void main() {
  late S t;

  setUpAll(() async {
    t = await _loadL10n(const Locale('es'));
  });

  test('localiza errores técnicos frecuentes del worker', () {
    expect(
      localizeFailureMessage(t, 'Invalid build verification query parameters.'),
      t.checkRealmAndName,
    );
    expect(
      localizeFailureMessage(
        t,
        'Build verification data not found for the selected character.',
      ),
      t.characterNotFound,
    );
    expect(
      localizeFailureMessage(t, 'Unknown build verification error'),
      t.serverError,
    );
  });

  test('localiza sugerencias técnicas en inglés', () {
    expect(
      localizeFailureSuggestion(
        t,
        'Request timed out. The server may be slow.',
      ),
      t.networkErrorSuggestion,
    );
    expect(
      localizeFailureSuggestion(t, 'Check your connection and try again.'),
      t.networkErrorSuggestion,
    );
  });
}
