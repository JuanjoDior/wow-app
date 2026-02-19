import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/repositories/builds_repository.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_state.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/usecases/get_item_detail.dart';
import 'package:wow_companion/features/builds/data/datasources/character_media_datasource.dart';

class BuildDetailCubit extends Cubit<BuildDetailState> {
  final BuildsRepository _repository;

  final CharacterMediaDataSource _mediaDataSource;

  BuildDetailCubit(this._repository, this._mediaDataSource)
    : super(const BuildDetailLoading());

  Future<void> loadBuild(String id) async {
    try {
      final builds = await _repository.getBuilds();
      final build = builds.firstWhere((b) => b.id == id);
      emit(BuildDetailLoaded(build));
    } catch (e) {
      emit(const BuildDetailError('buildNotFound'));
    }
  }

  Future<void> assignItem(WowSlot slot, Item item) async {
    final current = _currentBuild;
    if (current == null) return;

    // Enriquecer con iconUrl si no lo tiene
    Item enrichedItem = item;
    if (item.iconUrl == null) {
      final result = await sl<GetItemDetail>()(item.id);
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
        // Sincronizar gemsObtained al añadir
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
        // Sincronizar gemsObtained al eliminar
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

  // ─── Guide ─────────────────────────────────────────────────────────────
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
    final updated = current.guide.copyWith(rotation: newRotation);
    await _save(current.copyWith(guide: updated));
  }

  Future<void> reorderRotation(int oldIndex, int newIndex) async {
    final current = _currentBuild;
    if (current == null) return;
    final list = [...current.guide.rotation];
    final item = list.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    list.insert(insertAt, item);
    final updated = current.guide.copyWith(rotation: list);
    await _save(current.copyWith(guide: updated));
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
      if (s.slot == slot) {
        return BuildSlot(slot: slot);
      }
      return s;
    }).toList();

    await _save(current.copyWith(slots: updatedSlots));
  }

  Future<void> _save(Build updated) async {
    await _repository.saveBuild(updated);
    emit(BuildDetailLoaded(updated));
  }

  Build? get _currentBuild {
    final s = state;
    if (s is BuildDetailLoaded) return s.build;
    return null;
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
}
