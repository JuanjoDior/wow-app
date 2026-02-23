import 'package:equatable/equatable.dart';
import 'package:wow_companion/features/analysis/domain/services/character_analysis_service.dart';

abstract class CharacterAnalysisState extends Equatable {
  const CharacterAnalysisState();
}

/// Initial state — no analysis run yet.
class CharacterAnalysisInitial extends CharacterAnalysisState {
  const CharacterAnalysisInitial();
  @override
  List<Object?> get props => [];
}

/// Analysis complete.
class CharacterAnalysisLoaded extends CharacterAnalysisState {
  final CharacterAnalysisResult result;

  const CharacterAnalysisLoaded(this.result);

  @override
  List<Object?> get props => [result.specKey, result.insights];
}
