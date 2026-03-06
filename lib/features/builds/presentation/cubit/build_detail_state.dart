import 'package:equatable/equatable.dart';
import 'package:wow_companion/features/builds/domain/entities/build_gap_analysis.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/entities/economy_price_summary.dart';

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
  final BuildGapAnalysis? gapAnalysis;
  final bool isGapAnalysisLoading;
  final EconomyPriceSummary? economySummary;
  final bool isEconomyLoading;

  const BuildDetailLoaded(
    this.build, {
    this.gapAnalysis,
    this.isGapAnalysisLoading = false,
    this.economySummary,
    this.isEconomyLoading = false,
  });

  BuildDetailLoaded copyWith({
    Build? build,
    BuildGapAnalysis? gapAnalysis,
    bool? isGapAnalysisLoading,
    EconomyPriceSummary? economySummary,
    bool? isEconomyLoading,
    bool clearGapAnalysis = false,
    bool clearEconomySummary = false,
  }) => BuildDetailLoaded(
    build ?? this.build,
    gapAnalysis: clearGapAnalysis ? null : (gapAnalysis ?? this.gapAnalysis),
    isGapAnalysisLoading: isGapAnalysisLoading ?? this.isGapAnalysisLoading,
    economySummary: clearEconomySummary
        ? null
        : (economySummary ?? this.economySummary),
    isEconomyLoading: isEconomyLoading ?? this.isEconomyLoading,
  );

  @override
  List<Object?> get props => [
    build,
    gapAnalysis,
    isGapAnalysisLoading,
    economySummary,
    isEconomyLoading,
  ];
}

class BuildDetailError extends BuildDetailState {
  final String message;
  const BuildDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
