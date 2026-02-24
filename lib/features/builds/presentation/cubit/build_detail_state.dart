import 'package:equatable/equatable.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';

abstract class BuildDetailState extends Equatable {
  const BuildDetailState();
  @override
  List<Object?> get props => [];
}

class BuildDetailLoading extends BuildDetailState {
  const BuildDetailLoading();
}

class BuildDetailLoaded extends BuildDetailState {
  final Build build;

  /// Recomendaciones por spec cargadas desde la fuente local.
  /// null = sin spec vinculada o fallo de carga.
  final SpecRecommendation? recommendation;
  final bool recommendationLookupDone;

  const BuildDetailLoaded(
    this.build, {
    this.recommendation,
    this.recommendationLookupDone = false,
  });

  BuildDetailLoaded copyWith({
    Build? build,
    SpecRecommendation? recommendation,
    bool clearRecommendation = false,
    bool? recommendationLookupDone,
  }) => BuildDetailLoaded(
    build ?? this.build,
    recommendation: clearRecommendation
        ? null
        : (recommendation ?? this.recommendation),
    recommendationLookupDone:
        recommendationLookupDone ?? this.recommendationLookupDone,
  );

  @override
  List<Object?> get props => [build, recommendation, recommendationLookupDone];
}

class BuildDetailError extends BuildDetailState {
  final String message;
  const BuildDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
