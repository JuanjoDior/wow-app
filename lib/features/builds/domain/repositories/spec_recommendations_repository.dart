import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';

abstract class SpecRecommendationsRepository {
  /// Devuelve las recomendaciones para una clase/spec.
  /// Intenta primero el Worker remoto; si falla, usa el fallback estático.
  Future<SpecRecommendation?> getRecommendations({
    required String className,
    required String specName,
    String? patch,
  });

  /// Solo el fallback local — útil para tests y modo offline.
  SpecRecommendation? getLocalFallback({
    required String className,
    required String specName,
  });
}
