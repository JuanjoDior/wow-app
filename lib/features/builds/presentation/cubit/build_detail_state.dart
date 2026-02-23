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

  /// Recomendaciones por spec cargadas desde Worker o static fallback.
  /// null = sin spec vinculada o fallo de carga.
  final SpecRecommendation? recommendation;

  const BuildDetailLoaded(this.build, {this.recommendation});

  BuildDetailLoaded copyWith({
    Build? build,
    SpecRecommendation? recommendation,
    bool clearRecommendation = false,
  }) =>
      BuildDetailLoaded(
        build ?? this.build,
        recommendation: clearRecommendation ? null : (recommendation ?? this.recommendation),
      );

  @override
  List<Object?> get props => [build, recommendation];
}

class BuildDetailError extends BuildDetailState {
  final String message;
  const BuildDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
