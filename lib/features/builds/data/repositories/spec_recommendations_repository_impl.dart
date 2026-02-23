import 'package:wow_companion/core/data/wow_static_recommendations.dart';
import 'package:wow_companion/features/builds/data/datasources/spec_recommendations_datasource.dart';
import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';
import 'package:wow_companion/features/builds/domain/repositories/spec_recommendations_repository.dart';

/// Repositorio con estrategia remote-first + fallback local.
///
/// Orden de resolución:
///  1. Worker remoto (KV cache + static data)
///  2. Static data local (WowStaticRecommendations)
///  3. null → el consumer lo maneja mostrando hints genéricos
class SpecRecommendationsRepositoryImpl implements SpecRecommendationsRepository {
  final SpecRecommendationsRemoteDatasource _remote;

  SpecRecommendationsRepositoryImpl({
    required SpecRecommendationsRemoteDatasource remote,
  }) : _remote = remote;

  @override
  Future<SpecRecommendation?> getRecommendations({
    required String className,
    required String specName,
    String? patch,
  }) async {
    // 1. Intentar remoto
    final remote = await _remote.getRecommendations(
      className: className,
      specName: specName,
      patch: patch,
    );
    if (remote != null) return remote;

    // 2. Fallback local
    return WowStaticRecommendations.forSpec(className, specName);
  }

  @override
  SpecRecommendation? getLocalFallback({
    required String className,
    required String specName,
  }) =>
      WowStaticRecommendations.forSpec(className, specName);
}
