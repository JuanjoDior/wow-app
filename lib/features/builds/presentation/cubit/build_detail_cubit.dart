import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/core/config/feature_flags.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/l10n/locale_notifier.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/repositories/builds_repository.dart';
import 'package:wow_companion/features/builds/data/datasources/build_gap_analysis_datasource.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_state.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/usecases/get_item_detail.dart';
import 'package:wow_companion/features/builds/data/datasources/character_media_datasource.dart';

class BuildDetailCubit extends Cubit<BuildDetailState> {
  final BuildsRepository _repository;
  final CharacterMediaDataSource _mediaDataSource;
  final BuildGapAnalysisDataSource _gapAnalysisDataSource;

  BuildDetailCubit(
    this._repository,
    this._mediaDataSource,
    this._gapAnalysisDataSource,
  ) : super(const BuildDetailLoading());

  Future<void> loadBuild(String id) async {
    try {
      final builds = await _repository.getBuilds();
      final build = builds.firstWhere((b) => b.id == id);
      emit(
        BuildDetailLoaded(
          build,
          isGapAnalysisLoading: _canLoadGapAnalysis(build),
        ),
      );

      await _loadGapAnalysisForBuild(build);

      // Cargar avatar si falta
      if (build.characterAvatarUrl == null && build.characterRefKey != null) {
        final media = await _fetchMedia();
        if (media?.avatarUrl != null) {
          final updated = build.copyWith(characterAvatarUrl: media!.avatarUrl);
          await _repository.saveBuild(updated);
          final current = state;
          if (current is BuildDetailLoaded) {
            emit(current.copyWith(build: updated));
          }
        }
      }
    } catch (e) {
      emit(const BuildDetailError('buildNotFound'));
    }
  }

  // ─── Item / Enchantment / Gem ─────────────────────────────────────────────

  Future<void> assignItem(WowSlot slot, Item item) async {
    final current = _currentBuild;
    if (current == null) return;

    Item enrichedItem = item;
    if (item.iconUrl == null) {
      final result = await sl<GetItemDetail>()(
        item.id,
        locale: sl<LocaleNotifier>().blizzardLocale,
      );
      result.fold((_) {}, (detail) => enrichedItem = detail);
    }

    final updatedSlots = current.slots.map((s) {
      if (s.slot == slot) return s.copyWith(item: enrichedItem);
      return s;
    }).toList();

    await _save(current.copyWith(slots: updatedSlots));
  }

  Future<void> assignEnchantment(WowSlot slot, Item enchantment) async {
    final current = _currentBuild;
    if (current == null) return;

    final updatedSlots = current.slots.map((s) {
      if (s.slot == slot) return s.copyWith(enchantment: enchantment);
      return s;
    }).toList();

    await _save(current.copyWith(slots: updatedSlots));
  }

  Future<void> removeEnchantment(WowSlot slot) async {
    final current = _currentBuild;
    if (current == null) return;

    final updatedSlots = current.slots.map((s) {
      if (s.slot == slot) return s.copyWith(clearEnchantment: true);
      return s;
    }).toList();

    await _save(current.copyWith(slots: updatedSlots));
  }

  Future<void> addGem(WowSlot slot, Item gem) async {
    final current = _currentBuild;
    if (current == null) return;

    final updatedSlots = current.slots.map((s) {
      if (s.slot == slot) {
        final syncedObtained = List<bool>.from(
          s.gemsObtained.length == s.gems.length
              ? s.gemsObtained
              : List.filled(s.gems.length, false),
        )..add(false);
        return s.copyWith(gems: [...s.gems, gem], gemsObtained: syncedObtained);
      }
      return s;
    }).toList();

    await _save(current.copyWith(slots: updatedSlots));
  }

  Future<void> removeGem(WowSlot slot, int gemIndex) async {
    final current = _currentBuild;
    if (current == null) return;

    final updatedSlots = current.slots.map((s) {
      if (s.slot == slot) {
        if (gemIndex < 0 || gemIndex >= s.gems.length) return s;
        final newGems = [...s.gems]..removeAt(gemIndex);
        final syncedObtained = List<bool>.from(
          s.gemsObtained.length == s.gems.length
              ? s.gemsObtained
              : List.filled(s.gems.length, false),
        )..removeAt(gemIndex);
        return s.copyWith(gems: newGems, gemsObtained: syncedObtained);
      }
      return s;
    }).toList();

    await _save(current.copyWith(slots: updatedSlots));
  }

  // ─── Toggle states ────────────────────────────────────────────────────────

  Future<void> toggleEnchantmentObtained(WowSlot slot) async {
    final current = _currentBuild;
    if (current == null) return;

    final updatedSlots = current.slots.map((s) {
      if (s.slot == slot) {
        return s.copyWith(enchantmentObtained: !s.enchantmentObtained);
      }
      return s;
    }).toList();

    await _save(current.copyWith(slots: updatedSlots));
  }

  Future<void> toggleGemObtained(WowSlot slot, int gemIndex) async {
    final current = _currentBuild;
    if (current == null) return;

    final updatedSlots = current.slots.map((s) {
      if (s.slot == slot) {
        final newGemsObtained = List<bool>.from(
          s.gemsObtained.length == s.gems.length
              ? s.gemsObtained
              : List.filled(s.gems.length, false),
        );
        if (gemIndex < newGemsObtained.length) {
          newGemsObtained[gemIndex] = !newGemsObtained[gemIndex];
        }
        return s.copyWith(gemsObtained: newGemsObtained);
      }
      return s;
    }).toList();

    await _save(current.copyWith(slots: updatedSlots));
  }

  Future<void> toggleObtained(WowSlot slot) async {
    final current = _currentBuild;
    if (current == null) return;

    final updatedSlots = current.slots.map((s) {
      if (s.slot == slot) return s.copyWith(obtained: !s.obtained);
      return s;
    }).toList();

    await _save(current.copyWith(slots: updatedSlots));
  }

  // ─── Guide ────────────────────────────────────────────────────────────────

  Future<void> updateGuide(BuildGuide guide) async {
    final current = _currentBuild;
    if (current == null) return;
    await _save(current.copyWith(guide: guide));
  }

  Future<void> addSpellToRotation(WowSpell spell) async {
    final current = _currentBuild;
    if (current == null) return;
    final updated = current.guide.copyWith(
      rotation: [...current.guide.rotation, spell],
    );
    await _save(current.copyWith(guide: updated));
  }

  Future<void> removeSpellFromRotation(int index) async {
    final current = _currentBuild;
    if (current == null) return;
    final newRotation = [...current.guide.rotation]..removeAt(index);
    await _save(
      current.copyWith(guide: current.guide.copyWith(rotation: newRotation)),
    );
  }

  Future<void> reorderRotation(int oldIndex, int newIndex) async {
    final current = _currentBuild;
    if (current == null) return;
    final list = [...current.guide.rotation];
    final item = list.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    list.insert(insertAt, item);
    await _save(
      current.copyWith(guide: current.guide.copyWith(rotation: list)),
    );
  }

  Future<void> updateConsumable({
    Item? flask,
    Item? potion,
    Item? food,
    bool clearFlask = false,
    bool clearPotion = false,
    bool clearFood = false,
  }) async {
    final current = _currentBuild;
    if (current == null) return;
    final updated = current.guide.copyWith(
      consumables: current.guide.consumables.copyWith(
        flask: flask,
        potion: potion,
        food: food,
        clearFlask: clearFlask,
        clearPotion: clearPotion,
        clearFood: clearFood,
      ),
    );
    await _save(current.copyWith(guide: updated));
  }

  Future<void> clearSlot(WowSlot slot) async {
    final current = _currentBuild;
    if (current == null) return;

    final updatedSlots = current.slots.map((s) {
      if (s.slot == slot) return BuildSlot(slot: slot);
      return s;
    }).toList();

    await _save(current.copyWith(slots: updatedSlots));
  }

  Future<void> refreshGapAnalysis({bool force = true}) async {
    final current = _currentBuild;
    if (current == null) return;
    await _loadGapAnalysisForBuild(current, force: force);
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  /// Guarda y emite el build actualizado.
  Future<void> _save(Build updated) async {
    await _repository.saveBuild(updated);
    final current = state;
    if (current is BuildDetailLoaded) {
      emit(current.copyWith(build: updated));
      return;
    }
    emit(BuildDetailLoaded(updated));
  }

  Build? get _currentBuild {
    final s = state;
    return s is BuildDetailLoaded ? s.build : null;
  }

  String get searchRegion {
    final current = _currentBuild;
    final refKey = current?.characterRefKey;
    if (refKey == null) return 'eu';
    final parts = refKey.split('-');
    if (parts.isEmpty) return 'eu';
    return parts.first.toLowerCase();
  }

  Future<String?> fetchCharacterRenderUrl() async {
    final media = await _fetchMedia();
    return media?.renderUrl ?? media?.avatarUrl;
  }

  Future<String?> fetchCharacterAvatarUrl() async {
    final media = await _fetchMedia();
    return media?.avatarUrl;
  }

  Future<CharacterMedia?> _fetchMedia() async {
    final current = _currentBuild;
    if (current?.characterRefKey == null) return null;

    final parts = current!.characterRefKey!.split('-');
    if (parts.length < 3) return null;

    final region = parts[0];
    final realm = parts[1];
    final name = parts.sublist(2).join('-');

    return _mediaDataSource.getMedia(region: region, realm: realm, name: name);
  }

  bool _canLoadGapAnalysis(Build build) {
    return FeatureFlags.buildIntelligence && build.characterRefKey != null;
  }

  Future<void> _loadGapAnalysisForBuild(
    Build build, {
    bool force = false,
  }) async {
    if (!_canLoadGapAnalysis(build)) {
      final current = state;
      if (current is BuildDetailLoaded && current.build.id == build.id) {
        emit(
          current.copyWith(clearGapAnalysis: true, isGapAnalysisLoading: false),
        );
      }
      return;
    }

    final refKey = build.characterRefKey!;
    final parts = refKey.split('-');
    if (parts.length < 3) {
      final current = state;
      if (current is BuildDetailLoaded && current.build.id == build.id) {
        emit(
          current.copyWith(clearGapAnalysis: true, isGapAnalysisLoading: false),
        );
      }
      return;
    }

    final region = parts[0];
    final realm = parts[1];
    final name = parts.sublist(2).join('-');

    final current = state;
    if (current is BuildDetailLoaded && current.build.id == build.id) {
      emit(current.copyWith(isGapAnalysisLoading: true));
    }

    try {
      final analysis = await _gapAnalysisDataSource.getGapAnalysis(
        region: region,
        realm: realm,
        name: name,
        className: build.characterClass,
        specName: build.characterSpec,
        buildSlots: build.slots,
        force: force,
      );
      final latest = state;
      if (latest is BuildDetailLoaded && latest.build.id == build.id) {
        emit(
          latest.copyWith(gapAnalysis: analysis, isGapAnalysisLoading: false),
        );
      }
    } catch (_) {
      final latest = state;
      if (latest is BuildDetailLoaded && latest.build.id == build.id) {
        emit(latest.copyWith(isGapAnalysisLoading: false));
      }
    }
  }
}
