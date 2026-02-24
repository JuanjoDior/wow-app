import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/features/builds/data/datasources/spec_recommendations_local_datasource.dart';
import 'package:wow_companion/features/builds/data/repositories/spec_recommendations_repository_impl.dart';
import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';

class _FakeLocalDatasource extends SpecRecommendationsLocalDatasource {
  _FakeLocalDatasource(this._result);

  final SpecRecommendation? _result;
  int calls = 0;

  @override
  Future<SpecRecommendation?> getRecommendations({
    required String className,
    required String specName,
    String? patch,
  }) async {
    calls++;
    return _result;
  }
}

void main() {
  group('SpecRecommendationsRepositoryImpl', () {
    test('uses local datasource and returns recommendation', () async {
      const rec = SpecRecommendation(
        className: 'druid',
        specName: 'feral',
        patch: '11.2',
      );
      final local = _FakeLocalDatasource(rec);
      final repository = SpecRecommendationsRepositoryImpl(local: local);

      final result = await repository.getRecommendations(
        className: 'Druid',
        specName: 'Feral',
      );

      expect(result, isNotNull);
      expect(result!.className, 'druid');
      expect(local.calls, 1);
    });

    test('returns null when local datasource has no data', () async {
      final local = _FakeLocalDatasource(null);
      final repository = SpecRecommendationsRepositoryImpl(local: local);

      final result = await repository.getRecommendations(
        className: 'Unknown',
        specName: 'Unknown',
      );

      expect(result, isNull);
      expect(local.calls, 1);
    });
  });
}
