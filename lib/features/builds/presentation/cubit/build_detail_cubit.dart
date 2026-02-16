import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/repositories/builds_repository.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_state.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';

class BuildDetailCubit extends Cubit<BuildDetailState> {
  final BuildsRepository _repository;

  BuildDetailCubit(this._repository) : super(const BuildDetailLoading());

  Future<void> loadBuild(String id) async {
    try {
      final builds = await _repository.getBuilds();
      final build = builds.firstWhere((b) => b.id == id);
      emit(BuildDetailLoaded(build));
    } catch (e) {
      emit(BuildDetailError('Build not found'));
    }
  }

  Future<void> assignItem(WowSlot slot, Item item) async {
    final current = _currentBuild;
    if (current == null) return;

    final updatedSlots = current.slots.map((s) {
      if (s.slot == slot) return s.copyWith(item: item);
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

  Future<void> clearEnchantment(WowSlot slot) async {
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
        return s.copyWith(gems: [...s.gems, gem]);
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
        return s.copyWith(gems: newGems);
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
}
