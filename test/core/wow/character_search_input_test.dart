import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/core/wow/character_search_input.dart';

void main() {
  group('character_search_input', () {
    test('normalizes region and name', () {
      expect(normalizeRegion(' US '), 'us');
      expect(normalizeName(' Thrall '), 'thrall');
    });

    test('normalizes realm for request preserving apostrophes', () {
      expect(normalizeRealmForRequest(' Burning   Legion '), 'burning-legion');
      expect(normalizeRealmForRequest(" Cho'gall "), "cho'gall");
    });

    test('buildCharacterRoute encodes path segments safely', () {
      final route = buildCharacterRoute(
        region: 'US',
        realm: "Cho'gall",
        name: ' Thrall ',
      );
      expect(route, "/character/us/cho'gall/thrall");
    });

    test('buildCompareRoute normalizes both characters', () {
      final route = buildCompareRoute(
        region1: 'EU',
        realm1: 'Burning Legion',
        name1: 'Alpha',
        region2: 'TW',
        realm2: "Cho'gall",
        name2: 'Beta',
      );

      expect(route, "/compare/eu/burning-legion/alpha/vs/tw/cho'gall/beta");
    });

    test('buildWeeklyPlannerRoute normalizes route safely', () {
      final route = buildWeeklyPlannerRoute(
        region: 'EU',
        realm: "Burning Legion",
        name: 'Apästar',
      );
      expect(route, '/planner/eu/burning-legion/ap%C3%A4star');
    });
  });
}
