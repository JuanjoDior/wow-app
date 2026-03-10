import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/core/config/feature_flags.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/l10n/locale_notifier.dart';
import 'package:wow_companion/core/l10n/wow_translations.dart';
import 'package:wow_companion/features/character/data/datasources/blizzard_character_datasource.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/repositories/builds_repository.dart';
import 'package:wow_companion/features/builds/data/datasources/build_gap_analysis_datasource.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_sync_result.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_state.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/usecases/get_item_detail.dart';
import 'package:wow_companion/features/builds/data/datasources/character_media_datasource.dart';

class BuildDetailCubit extends Cubit<BuildDetailState> {
  static const syncNoCharacterMessageCode = 'sync_no_character';

  final BuildsRepository _repository;
  final CharacterMediaDataSource _mediaDataSource;
  final BuildGapAnalysisDataSource _gapAnalysisDataSource;
  final BlizzardCharacterDatasource _blizzardCharacterDatasource;
  final LocaleNotifier _localeNotifier;
  final GetItemDetail _getItemDetail;

  bool _hydratingLocalizedItems = false;

  BuildDetailCubit(
    this._repository,
    this._mediaDataSource,
    this._gapAnalysisDataSource,
    this._blizzardCharacterDatasource,
    this._localeNotifier,
    this._getItemDetail,
  ) : super(const BuildDetailLoading()) {
    _localeNotifier.addListener(_handleLocaleChanged);
  }

  @override
  Future<void> close() {
    _localeNotifier.removeListener(_handleLocaleChanged);
    return super.close();
  }

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

      await _ensureLocalizedItemData(build);

      final hydratedBuild = _currentBuild ?? build;
      await _loadGapAnalysisForBuild(hydratedBuild);

      // Cargar avatar si falta
      if (hydratedBuild.characterAvatarUrl == null &&
          hydratedBuild.characterRefKey != null) {
        final media = await _fetchMedia();
        if (media?.avatarUrl != null) {
          final updated = hydratedBuild.copyWith(
            characterAvatarUrl: media!.avatarUrl,
          );
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

    final enrichedItem = await _prepareStoredItem(item);

    final updatedSlots = current.slots.map((s) {
      if (s.slot == slot) return s.copyWith(item: enrichedItem);
      return s;
    }).toList();

    await _save(current.copyWith(slots: updatedSlots));
  }

  Future<void> assignEnchantment(WowSlot slot, Item enchantment) async {
    final current = _currentBuild;
    if (current == null) return;
    final enrichedEnchantment = await _prepareStoredItem(enchantment);

    final updatedSlots = current.slots.map((s) {
      if (s.slot == slot) return s.copyWith(enchantment: enrichedEnchantment);
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
    final enrichedGem = await _prepareStoredItem(gem);

    final updatedSlots = current.slots.map((s) {
      if (s.slot == slot) {
        final syncedObtained = List<bool>.from(
          s.gemsObtained.length == s.gems.length
              ? s.gemsObtained
              : List.filled(s.gems.length, false),
        )..add(false);
        return s.copyWith(
          gems: [...s.gems, enrichedGem],
          gemsObtained: syncedObtained,
        );
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
    final nextFlask = clearFlask || flask == null
        ? flask
        : await _prepareStoredItem(flask);
    final nextPotion = clearPotion || potion == null
        ? potion
        : await _prepareStoredItem(potion);
    final nextFood = clearFood || food == null
        ? food
        : await _prepareStoredItem(food);
    final updated = current.guide.copyWith(
      consumables: current.guide.consumables.copyWith(
        flask: nextFlask,
        potion: nextPotion,
        food: nextFood,
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

  Future<BuildSyncResult> syncCharacterProgress({bool force = true}) async {
    final current = state;
    if (current is! BuildDetailLoaded) {
      throw const ServerException(message: syncNoCharacterMessageCode);
    }

    final build = current.build;
    final characterRef = _parseCharacterRefKey(build.characterRefKey);
    if (characterRef == null) {
      throw const ServerException(message: syncNoCharacterMessageCode);
    }

    emit(current.copyWith(isCharacterSyncLoading: true));

    try {
      final snapshot = await _blizzardCharacterDatasource.getCharacter(
        region: characterRef.region,
        realm: characterRef.realm,
        name: characterRef.name,
        locale: 'en_US',
        force: force,
      );

      final equipmentBySlot = _buildEquipmentBySlot(snapshot.equipment);
      var slotsUpdated = 0;
      var itemsMatched = 0;
      var itemsTargeted = 0;

      final updatedSlots = build.slots
          .map((slot) {
            final equippedItem = equipmentBySlot[slot.slot];
            var nextObtained = false;
            if (slot.item != null) {
              itemsTargeted += 1;
              nextObtained = _matchesEquippedItem(slot.item!, equippedItem);
              if (nextObtained) {
                itemsMatched += 1;
              }
            }

            if (slot.obtained != nextObtained) {
              slotsUpdated += 1;
            }

            return slot.copyWith(obtained: nextObtained);
          })
          .toList(growable: false);

      final updatedBuild = build.copyWith(slots: updatedSlots);
      await _repository.saveBuild(updatedBuild);

      final latest = state;
      if (latest is BuildDetailLoaded && latest.build.id == build.id) {
        emit(
          latest.copyWith(build: updatedBuild, isCharacterSyncLoading: false),
        );
      }

      await _loadGapAnalysisForBuild(updatedBuild, force: true);

      return BuildSyncResult(
        slotsUpdated: slotsUpdated,
        itemsMatched: itemsMatched,
        itemsTargeted: itemsTargeted,
      );
    } catch (_) {
      final latest = state;
      if (latest is BuildDetailLoaded && latest.build.id == build.id) {
        emit(latest.copyWith(isCharacterSyncLoading: false));
      }
      rethrow;
    }
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
    final parsed = _parseCharacterRefKey(current?.characterRefKey);
    return parsed?.region ?? 'eu';
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
    final parsed = _parseCharacterRefKey(current?.characterRefKey);
    if (parsed == null) return null;

    return _mediaDataSource.getMedia(
      region: parsed.region,
      realm: parsed.realm,
      name: parsed.name,
    );
  }

  bool _canLoadGapAnalysis(Build build) {
    return FeatureFlags.buildIntelligence &&
        _parseCharacterRefKey(build.characterRefKey) != null;
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

    final characterRef = _parseCharacterRefKey(build.characterRefKey);
    if (characterRef == null) {
      final current = state;
      if (current is BuildDetailLoaded && current.build.id == build.id) {
        emit(
          current.copyWith(clearGapAnalysis: true, isGapAnalysisLoading: false),
        );
      }
      return;
    }

    final current = state;
    if (current is BuildDetailLoaded && current.build.id == build.id) {
      emit(current.copyWith(isGapAnalysisLoading: true));
    }

    try {
      final canonicalClass = build.characterClass == null
          ? null
          : WowTranslations.canonicalizeClass(build.characterClass!);
      final canonicalSpec = WowTranslations.canonicalizeSpec(
        build.characterSpec,
        className: canonicalClass,
      );
      final analysis = await _gapAnalysisDataSource.getGapAnalysis(
        region: characterRef.region,
        realm: characterRef.realm,
        name: characterRef.name,
        className: canonicalClass,
        specName: canonicalSpec,
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

  void _handleLocaleChanged() {
    final current = _currentBuild;
    if (current == null) return;
    unawaited(_ensureLocalizedItemData(current));
  }

  Future<void> _ensureLocalizedItemData(Build build) async {
    if (_hydratingLocalizedItems) return;
    _hydratingLocalizedItems = true;

    try {
      final localizedBuild = await _hydrateBuildItemData(build);
      if (localizedBuild == null || localizedBuild == build) return;

      await _repository.saveBuild(localizedBuild);
      final current = state;
      if (current is BuildDetailLoaded && current.build.id == build.id) {
        emit(current.copyWith(build: localizedBuild));
      }
    } finally {
      _hydratingLocalizedItems = false;
    }
  }

  Future<Build?> _hydrateBuildItemData(Build build) async {
    final languageCode = _localeNotifier.locale.languageCode;
    final detailCache = <String, Future<Item?>>{};

    Future<Item?> fetchDetail(int id, String locale) {
      return detailCache.putIfAbsent('$id:$locale', () async {
        final result = await _getItemDetail(id, locale: locale);
        return result.fold<Item?>((_) => null, (detail) => detail);
      });
    }

    var changed = false;

    Future<Item?> hydrateNullable(Item? item) async {
      if (item == null) return null;
      final hydrated = await _hydrateStoredItem(
        item,
        languageCode: languageCode,
        fetchDetail: fetchDetail,
      );
      if (hydrated != item) changed = true;
      return hydrated;
    }

    final updatedSlots = <BuildSlot>[];
    for (final slot in build.slots) {
      final item = await hydrateNullable(slot.item);
      final enchantment = await hydrateNullable(slot.enchantment);
      final gems = <Item>[];
      for (final gem in slot.gems) {
        gems.add((await hydrateNullable(gem)) ?? gem);
      }

      final updatedSlot = slot.copyWith(
        item: item ?? slot.item,
        enchantment: enchantment ?? slot.enchantment,
        gems: gems,
      );
      if (updatedSlot != slot) changed = true;
      updatedSlots.add(updatedSlot);
    }

    final consumables = build.guide.consumables;
    final updatedFlask = await hydrateNullable(consumables.flask);
    final updatedPotion = await hydrateNullable(consumables.potion);
    final updatedFood = await hydrateNullable(consumables.food);
    final updatedGuide = build.guide.copyWith(
      consumables: consumables.copyWith(
        flask: updatedFlask ?? consumables.flask,
        potion: updatedPotion ?? consumables.potion,
        food: updatedFood ?? consumables.food,
      ),
    );

    if (!changed && updatedGuide == build.guide) {
      return null;
    }

    return build.copyWith(slots: updatedSlots, guide: updatedGuide);
  }

  Future<Item> _prepareStoredItem(Item item) async {
    final detailCache = <String, Future<Item?>>{};
    final languageCode = _localeNotifier.locale.languageCode;
    return _hydrateStoredItem(
      item,
      languageCode: languageCode,
      fetchDetail: (id, locale) {
        return detailCache.putIfAbsent('$id:$locale', () async {
          final result = await _getItemDetail(id, locale: locale);
          return result.fold<Item?>((_) => null, (detail) => detail);
        });
      },
    );
  }

  Future<Item> _hydrateStoredItem(
    Item item, {
    required String languageCode,
    required Future<Item?> Function(int id, String locale) fetchDetail,
  }) async {
    if (item.id <= 0 || item.lookupKind == TooltipEntityKind.spell) {
      return item;
    }

    final needsEnglish = _isBlank(item.canonicalNameEn);
    final needsLocalized = languageCode == 'es' && _isBlank(item.localizedName);
    final needsMetadata = _isBlank(item.iconUrl);

    if (!needsEnglish && !needsLocalized && !needsMetadata) {
      return item;
    }

    Item? englishDetail;
    Item? localizedDetail;

    if (needsEnglish || needsMetadata) {
      englishDetail = await fetchDetail(item.id, 'en_GB');
    }
    if (needsLocalized) {
      localizedDetail = await fetchDetail(
        item.id,
        _localeNotifier.blizzardLocale,
      );
    }

    return _mergeHydratedItem(
      base: item,
      englishDetail: englishDetail,
      localizedDetail: localizedDetail,
      languageCode: languageCode,
    );
  }

  Item _mergeHydratedItem({
    required Item base,
    Item? englishDetail,
    Item? localizedDetail,
    required String languageCode,
  }) {
    final canonicalName = _firstNonBlank([
      base.canonicalNameEn,
      englishDetail?.canonicalNameEn,
      englishDetail?.name,
    ]);
    final localizedName = _firstNonBlank([
      base.localizedName,
      localizedDetail?.localizedName,
      if (languageCode == 'es') localizedDetail?.name,
    ]);

    return Item(
      id: base.id,
      name: canonicalName ?? base.name,
      quality: base.quality,
      lookupKind: base.lookupKind,
      level: base.level ?? englishDetail?.level ?? localizedDetail?.level,
      requiredLevel:
          base.requiredLevel ??
          englishDetail?.requiredLevel ??
          localizedDetail?.requiredLevel,
      itemClass:
          base.itemClass ??
          englishDetail?.itemClass ??
          localizedDetail?.itemClass,
      itemSubclass:
          base.itemSubclass ??
          englishDetail?.itemSubclass ??
          localizedDetail?.itemSubclass,
      inventoryType:
          base.inventoryType ??
          englishDetail?.inventoryType ??
          localizedDetail?.inventoryType,
      inventoryName:
          base.inventoryName ??
          englishDetail?.inventoryName ??
          localizedDetail?.inventoryName,
      iconUrl:
          base.iconUrl ?? englishDetail?.iconUrl ?? localizedDetail?.iconUrl,
      localizedName: localizedName,
      canonicalNameEn: canonicalName,
    );
  }

  String? _firstNonBlank(List<String?> values) {
    for (final value in values) {
      if (!_isBlank(value)) return value!.trim();
    }
    return null;
  }

  bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  _CharacterRefParts? _parseCharacterRefKey(String? refKey) {
    if (refKey == null || refKey.trim().isEmpty) return null;

    final parts = refKey.split('-');
    if (parts.length < 3) return null;

    final region = parts[0].trim().toLowerCase();
    final realm = parts[1].trim().toLowerCase();
    final name = parts.sublist(2).join('-').trim().toLowerCase();

    if (region.isEmpty || realm.isEmpty || name.isEmpty) return null;
    return _CharacterRefParts(region: region, realm: realm, name: name);
  }

  Map<WowSlot, EquippedItem> _buildEquipmentBySlot(List<EquippedItem> items) {
    final map = <WowSlot, EquippedItem>{};
    for (final item in items) {
      final slot = _mapCharacterSlot(item.slot);
      if (slot == null) continue;
      map[slot] = item;
    }
    return map;
  }

  WowSlot? _mapCharacterSlot(String rawSlot) {
    return switch (rawSlot.toUpperCase()) {
      'HEAD' => WowSlot.head,
      'NECK' => WowSlot.neck,
      'SHOULDER' => WowSlot.shoulder,
      'BACK' => WowSlot.back,
      'CHEST' => WowSlot.chest,
      'WRIST' => WowSlot.wrist,
      'HANDS' => WowSlot.hands,
      'WAIST' => WowSlot.waist,
      'LEGS' => WowSlot.legs,
      'FEET' => WowSlot.feet,
      'FINGER_1' => WowSlot.finger1,
      'FINGER_2' => WowSlot.finger2,
      'TRINKET_1' => WowSlot.trinket1,
      'TRINKET_2' => WowSlot.trinket2,
      'MAIN_HAND' => WowSlot.mainHand,
      'OFF_HAND' => WowSlot.offHand,
      _ => null,
    };
  }

  bool _matchesEquippedItem(Item target, EquippedItem? equipped) {
    if (equipped == null) return false;

    final equippedId = equipped.itemId;
    if (target.id > 0 && equippedId != null && equippedId > 0) {
      return target.id == equippedId;
    }

    return _normalizeName(target.canonicalNameEn ?? target.name) ==
        _normalizeName(equipped.name);
  }

  String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _CharacterRefParts {
  final String region;
  final String realm;
  final String name;

  const _CharacterRefParts({
    required this.region,
    required this.realm,
    required this.name,
  });
}
