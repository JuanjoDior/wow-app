import 'package:wow_companion/features/builds/data/datasources/spec_recommendations_local_datasource.dart';
import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';
import 'package:wow_companion/features/builds/domain/repositories/spec_recommendations_repository.dart';

/// Repositorio local-only para recomendaciones por spec.
class SpecRecommendationsRepositoryImpl
    implements SpecRecommendationsRepository {
  final SpecRecommendationsLocalDatasource _local;

  SpecRecommendationsRepositoryImpl({
    required SpecRecommendationsLocalDatasource local,
  }) : _local = local;

  @override
  Future<SpecRecommendation?> getRecommendations({
    required String className,
    required String specName,
    String? patch,
  }) {
    return _local.getRecommendations(
      className: className,
      specName: specName,
      patch: patch,
    );
  }

  @override
  Future<SpecRecommendation?> getLocalFallback({
    required String className,
    required String specName,
  }) {
    return _local.getRecommendations(className: className, specName: specName);
  }
}
