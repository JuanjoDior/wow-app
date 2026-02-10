import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/features/search/domain/search_entry.dart';

void main() {
  group('SearchEntry', () {
    test('key is lowercase combination of region-realm-name', () {
      final entry = SearchEntry(
        region: 'EU',
        realm: 'Sargeras',
        name: 'TestPala',
      );
      expect(entry.key, 'eu-sargeras-testpala');
    });

    test('realmSlug converts spaces to hyphens', () {
      final entry = SearchEntry(
        region: 'eu',
        realm: 'Burning Legion',
        name: 'test',
      );
      expect(entry.realmSlug, 'burning-legion');
    });

    test('displayRealm capitalizes each word', () {
      final entry = SearchEntry(
        region: 'eu',
        realm: 'burning-legion',
        name: 'test',
      );
      expect(entry.displayRealm, 'Burning Legion');
    });

    test('toJson and fromJson roundtrip', () {
      final original = SearchEntry(
        region: 'us',
        realm: 'illidan',
        name: 'test',
      );
      final json = original.toJson();
      final restored = SearchEntry.fromJson(json);

      expect(restored.region, original.region);
      expect(restored.realm, original.realm);
      expect(restored.name, original.name);
      expect(restored.searchedAt, original.searchedAt);
    });

    test('equality is based on region, realm, name', () {
      final a = SearchEntry(region: 'eu', realm: 'sargeras', name: 'test');
      final b = SearchEntry(region: 'eu', realm: 'sargeras', name: 'test');
      expect(a, equals(b));
    });

    test('different names are not equal', () {
      final a = SearchEntry(region: 'eu', realm: 'sargeras', name: 'alpha');
      final b = SearchEntry(region: 'eu', realm: 'sargeras', name: 'beta');
      expect(a, isNot(equals(b)));
    });
  });
}
