import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/features/builds/data/datasources/spec_recommendations_local_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpecRecommendationsLocalDatasource', () {
    late SpecRecommendationsLocalDatasource datasource;

    setUp(() {
      datasource = SpecRecommendationsLocalDatasource();
    });

    test('resolves druid feral recommendation from local dataset', () async {
      final rec = await datasource.getRecommendations(
        className: 'druid',
        specName: 'feral',
      );

      expect(rec, isNotNull);
      expect(rec!.className, 'druid');
      expect(rec.specName, 'feral');
      expect(rec.statPriority, isNotEmpty);
      expect(rec.flask?.name, isNotEmpty);
      expect(rec.patch, isNotEmpty);
    });

    test('normalizes class/spec names before lookup', () async {
      final rec = await datasource.getRecommendations(
        className: '  Druid ',
        specName: ' FERAL  ',
      );

      expect(rec, isNotNull);
      expect(rec!.specName, 'feral');
    });

    test('returns null for class/spec not present locally', () async {
      final rec = await datasource.getRecommendations(
        className: 'unknown class',
        specName: 'unknown spec',
      );

      expect(rec, isNull);
    });
  });
}
