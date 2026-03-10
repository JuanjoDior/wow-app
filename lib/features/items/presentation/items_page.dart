import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/l10n/failure_localizer.dart';
import 'package:wow_companion/core/l10n/item_name_localizer.dart';
import 'package:wow_companion/core/l10n/locale_notifier.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/entities/item_search_mode.dart';
import 'package:wow_companion/features/items/presentation/cubit/items_cubit.dart';
import 'package:wow_companion/features/items/presentation/cubit/items_state.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';
import 'package:wow_companion/shared/widgets/item_tooltip_trigger.dart';

class ItemsPage extends StatelessWidget {
  const ItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ItemsCubit>(),
      child: const _ItemsView(),
    );
  }
}

class _ItemsView extends StatefulWidget {
  const _ItemsView();

  @override
  State<_ItemsView> createState() => _ItemsViewState();
}

class _ItemsViewState extends State<_ItemsView> {
  final _controller = TextEditingController();
  Timer? _debounce;
  late final LocaleNotifier _localeNotifier;

  @override
  void initState() {
    super.initState();
    _localeNotifier = sl<LocaleNotifier>();
    _localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _localeNotifier.removeListener(_onLocaleChanged);
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onLocaleChanged() {
    if (!mounted) return;
    final query = _controller.text.trim();
    if (query.length < 2) return;
    _debounce?.cancel();
    context.read<ItemsCubit>().search(
      query,
      mode: ItemSearchMode.item,
      locale: _localeNotifier.blizzardLocale,
    );
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      context.read<ItemsCubit>().clear();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<ItemsCubit>().search(
          value.trim(),
          mode: ItemSearchMode.item,
          locale: _localeNotifier.blizzardLocale,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.itemCatalog)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              style: const TextStyle(color: WowTheme.textPrimary),
              decoration: InputDecoration(
                hintText: t.searchTypeAtLeast,
                hintStyle: const TextStyle(color: WowTheme.textSecondary),
                prefixIcon: const Icon(
                  Icons.search,
                  color: WowTheme.textSecondary,
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (_, value, _) => value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: WowTheme.textSecondary,
                          ),
                          onPressed: () {
                            _controller.clear();
                            context.read<ItemsCubit>().clear();
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ItemsCubit, ItemsState>(
              builder: (context, state) {
                if (state is ItemsInitial) return _buildHint(context);
                if (state is ItemsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: WowTheme.primaryGold,
                    ),
                  );
                }
                if (state is ItemsEmpty) return _buildEmpty(context);
                if (state is ItemsError) {
                  return _buildError(context, state.message);
                }
                if (state is ItemsLoaded) return _buildList(state.items);
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint(BuildContext context) {
    final t = S.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: WowTheme.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            t.itemCatalog,
            style: const TextStyle(color: WowTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            t.searchTypeAtLeast,
            style: const TextStyle(color: WowTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final t = S.of(context)!;
    return Center(
      child: Text(
        t.searchNoResults,
        style: const TextStyle(color: WowTheme.textSecondary, fontSize: 15),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final t = S.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: WowTheme.accentRed,
            ),
            const SizedBox(height: 12),
            Text(
              localizeFailureMessage(t, message),
              textAlign: TextAlign.center,
              style: const TextStyle(color: WowTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Item> items) => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    itemCount: items.length,
    itemBuilder: (_, i) => _ItemCard(item: items[i]),
  );
}

class _ItemCard extends StatelessWidget {
  final Item item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final qualityColor = WowTheme.getQualityColor(item.quality);
    final localeCode = Localizations.localeOf(context).languageCode;
    final primaryName = item.primaryNameForLanguage(localeCode);
    final secondaryName = item.secondaryNameForLanguage(localeCode);
    return Card(
      color: WowTheme.surfaceDark,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: qualityColor.withValues(alpha: 0.4), width: 1),
      ),
      child: ItemTooltipTrigger.forItemId(
        itemId: item.id,
        entityKind: item.lookupKind,
        fallbackItem: item,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: qualityColor, width: 2),
                  color: WowTheme.darkBackground,
                ),
                child: item.iconUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: item.iconUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const Icon(
                            Icons.inventory_2,
                            color: WowTheme.textSecondary,
                            size: 28,
                          ),
                          errorWidget: (_, _, _) => const Icon(
                            Icons.inventory_2,
                            color: WowTheme.textSecondary,
                            size: 28,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2,
                        color: WowTheme.textSecondary,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryName,
                      style: TextStyle(
                        color: qualityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (secondaryName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        secondaryName,
                        style: const TextStyle(
                          color: WowTheme.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      [
                        item.inventoryName,
                        item.itemSubclass,
                      ].where((e) => e != null && e.isNotEmpty).join(' · '),
                      style: const TextStyle(
                        color: WowTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (item.level != null)
                Text(
                  '${t.ilvl} ${item.level}',
                  style: const TextStyle(
                    color: WowTheme.primaryGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
