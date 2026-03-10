import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/core/l10n/item_name_localizer.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';

void main() {
  group('ItemNameLocalizer', () {
    const item = Item(
      id: 1,
      name: 'Authority of Fiery Resolve',
      quality: 'EPIC',
      localizedName: 'Autoridad de resolución ígnea',
      canonicalNameEn: 'Authority of Fiery Resolve',
    );

    test('uses localized primary name in spanish', () {
      expect(
        item.primaryNameForLanguage('es'),
        'Autoridad de resolución ígnea',
      );
      expect(item.secondaryNameForLanguage('es'), 'Authority of Fiery Resolve');
    });

    test('uses canonical primary name in english', () {
      expect(item.primaryNameForLanguage('en'), 'Authority of Fiery Resolve');
      expect(
        item.secondaryNameForLanguage('en'),
        'Autoridad de resolución ígnea',
      );
    });
  });
}
