import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/features/analysis/domain/services/character_analysis_service.dart';
import 'package:wow_companion/features/analysis/domain/services/gear_progress_service.dart';
import 'package:wow_companion/features/analysis/presentation/cubit/character_analysis_state.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';

/// Cubit that triggers character analysis and exposes the result.
///
/// Usage in CharacterPage (after character loads):
///   ```dart
///   context.read<CharacterAnalysisCubit>().analyze(character);
///   ```
///
/// The cubit is registered as a factory in DI — one instance per
/// CharacterPage lifecycle — and disposed with the page.
///
/// [analyze] is async: it loads the previous [GearSnapshot] from
/// SharedPreferences before running the synchronous analysis pipeline,
/// then saves the current snapshot for future comparisons.
class CharacterAnalysisCubit extends Cubit<CharacterAnalysisState> {
  final CharacterAnalysisService _service;
  final GearProgressService _gearProgressService;

  CharacterAnalysisCubit(this._service, this._gearProgressService)
      : super(const CharacterAnalysisInitial());

  /// Runs all analyzers and emits the result.
  /// Safe to call multiple times (re-runs on character refresh).
  Future<void> analyze(Character character) async {
    // 1. Load previous snapshot (non-blocking; null on first visit)
    final previousSnapshot =
        await _gearProgressService.loadSnapshot(character);

    // 2. Run synchronous analysis pipeline with snapshot context
    final result = _service.analyze(
      character,
      previousSnapshot: previousSnapshot,
    );

    // 3. Save current state as new snapshot (fire-and-forget)
    _gearProgressService.saveSnapshot(character);

    emit(CharacterAnalysisLoaded(result));
  }
}
