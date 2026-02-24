import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';

abstract class SpecRecommendationsRepository {
  /// Devuelve las recomendaciones para una clase/spec.
  /// En esta fase usa únicamente la fuente local embebida en la app.
  Future<SpecRecommendation?> getRecommendations({
    required String className,
    required String specName,
    String? patch,
  });

  /// Solo el fallback local — útil para tests y modo offline.
  Future<SpecRecommendation?> getLocalFallback({
    required String className,
    required String specName,
  });
}
