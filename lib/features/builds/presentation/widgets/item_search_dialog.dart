import 'package:flutter/material.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/l10n/failure_localizer.dart';
import 'package:wow_companion/core/l10n/locale_notifier.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/entities/item_search_mode.dart';
import 'package:wow_companion/features/items/domain/usecases/search_items.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';
import 'dart:async';
import 'package:wow_companion/shared/widgets/item_tooltip_trigger.dart';

class ItemSearchDialog extends StatefulWidget {
  final WowSlot? slot;
  final String title;
  final ItemSearchMode mode;
  final String region;

  const ItemSearchDialog({
    super.key,
    this.slot,
    required this.title,
    this.mode = ItemSearchMode.item,
    this.region = 'eu',
  });

  @override
  State<ItemSearchDialog> createState() => _ItemSearchDialogState();
}

class _ItemSearchDialogState extends State<ItemSearchDialog> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Item> _results = [];
  bool _loading = false;
  bool _hasSearched = false; // ← nueva línea
  String? _error;
  int _requestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _loading = false;
        _hasSearched = false;
        _error = null;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _hasSearched = true;
      _doSearch(query);
    });
  }

  Future<void> _doSearch(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final requestId = ++_requestId;

    try {
      final searchItems = sl<SearchItems>();
      final effectiveInventoryType = _effectiveInventoryType();
      final result = await searchItems(
        query.trim(),
        mode: widget.mode,
        inventoryType: effectiveInventoryType,
        slot: widget.slot?.name,
        region: widget.region,
        locale: sl<LocaleNotifier>().blizzardLocale,
      );
      if (!mounted || requestId != _requestId) return;

      result.fold(
        (failure) {
          final t = S.of(context)!;
          setState(() => _error = localizeFailureMessage(t, failure.message));
        },
        (items) {
          setState(() => _results = items);
        },
      );
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      final t = S.of(context)!;
      setState(() => _error = t.unexpectedError('$e'));
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  String? _effectiveInventoryType() {
    switch (widget.mode) {
      case ItemSearchMode.item:
        final type = widget.slot?.inventoryType;
        if (type == null || type.isEmpty) return null;
        return type;
      case ItemSearchMode.enchant:
      case ItemSearchMode.gem:
      case ItemSearchMode.consumable:
        return 'NON_EQUIP';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Dialog(
      backgroundColor: WowTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: WowTheme.primaryGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(color: WowTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: t.searchTypeAtLeast,
                  hintStyle: const TextStyle(color: WowTheme.textSecondary),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: WowTheme.textSecondary,
                  ),
                ),
                onChanged: _onQueryChanged,
              ),
              if (_loading)
                const LinearProgressIndicator(
                  color: WowTheme.primaryGold,
                  backgroundColor: Colors.transparent,
                  minHeight: 2,
                )
              else
                const SizedBox(height: 2),
              const SizedBox(height: 10),
              Expanded(child: _buildBody(t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(S t) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: WowTheme.primaryGold),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: WowTheme.textSecondary),
        ),
      );
    }
    if (!_hasSearched) {
      return Center(
        child: Text(
          t.searchTypeAtLeast,
          style: const TextStyle(color: WowTheme.textSecondary),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          t.searchNoResults,
          style: const TextStyle(color: WowTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final item = _results[i];
        final color = WowTheme.getQualityColor(item.quality);
        final localeCode = Localizations.localeOf(context).languageCode;
        final primaryName = _primaryName(item, localeCode);
        final secondaryName = _secondaryName(item, localeCode);
        return ItemTooltipTrigger.forItemId(
          itemId: item.id,
          mode: ItemTooltipInteractionMode.actionFirstMode,
          enableWebOfficialTooltip: false,
          onPrimaryTap: () => Navigator.of(context).pop(_persistableItem(item)),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: item.iconUrl != null
                  ? Image.network(
                      item.iconUrl!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallbackIcon(color),
                    )
                  : _fallbackIcon(color),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryName,
                  style: TextStyle(color: color, fontWeight: FontWeight.w500),
                ),
                if (secondaryName != null)
                  Text(
                    secondaryName,
                    style: const TextStyle(
                      color: WowTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              [
                if (item.level != null) 'iLvl ${item.level}',
                if (item.inventoryName != null) item.inventoryName!,
              ].join(' · '),
              style: const TextStyle(
                color: WowTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  String _primaryName(Item item, String localeCode) {
    if (localeCode == 'es') {
      return item.localizedName?.trim().isNotEmpty == true
          ? item.localizedName!
          : item.name;
    }
    return item.canonicalNameEn?.trim().isNotEmpty == true
        ? item.canonicalNameEn!
        : item.name;
  }

  String? _secondaryName(Item item, String localeCode) {
    final localized = item.localizedName?.trim();
    final canonical = item.canonicalNameEn?.trim();
    if (localized == null || localized.isEmpty) return null;
    if (canonical == null || canonical.isEmpty) return null;
    if (_normalizeName(localized) == _normalizeName(canonical)) return null;
    return localeCode == 'es' ? canonical : localized;
  }

  String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Item _persistableItem(Item item) {
    final canonical = item.canonicalNameEn?.trim();
    final nameForStorage = canonical != null && canonical.isNotEmpty
        ? canonical
        : item.name;
    return Item(
      id: item.id,
      name: nameForStorage,
      quality: item.quality,
      level: item.level,
      requiredLevel: item.requiredLevel,
      itemClass: item.itemClass,
      itemSubclass: item.itemSubclass,
      inventoryType: item.inventoryType,
      inventoryName: item.inventoryName,
      iconUrl: item.iconUrl,
      localizedName: item.localizedName,
      canonicalNameEn: canonical != null && canonical.isNotEmpty
          ? canonical
          : nameForStorage,
    );
  }

  Widget _fallbackIcon(Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: WowTheme.border,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.inventory_2_outlined, size: 20, color: color),
    );
  }
}
