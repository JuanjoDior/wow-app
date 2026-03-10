import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/core/l10n/wow_translations.dart';

void main() {
  group('WowTranslations', () {
    test('translates canonical english values to spanish', () {
      expect(
        WowTranslations.translateClass('Demon Hunter', 'es'),
        'Cazador de Demonios',
      );
      expect(
        WowTranslations.translateSpec(
          'Devourer',
          'es',
          className: 'Demon Hunter',
        ),
        'Devorador',
      );
      expect(
        WowTranslations.translateRace('Night Elf', 'es'),
        'Elfo de la noche',
      );
    });

    test('normalizes spanish stored values back to english', () {
      expect(
        WowTranslations.translateClass('Cazador de Demonios', 'en'),
        'Demon Hunter',
      );
      expect(
        WowTranslations.translateRace('Elfo de la noche', 'en'),
        'Night Elf',
      );
      expect(
        WowTranslations.translateSpec(
          'Venganza',
          'en',
          className: 'Cazador de Demonios',
        ),
        'Vengeance',
      );
    });

    test('disambiguates duplicated localized specs with class context', () {
      expect(
        WowTranslations.translateSpec(
          'Devastacion',
          'en',
          className: 'Cazador de Demonios',
        ),
        'Havoc',
      );
      expect(
        WowTranslations.translateSpec(
          'Devastacion',
          'en',
          className: 'Evocador',
        ),
        'Devastation',
      );
    });
  });
}
