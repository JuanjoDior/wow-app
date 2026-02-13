import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/presentation/cubit/items_cubit.dart';
import 'package:wow_companion/features/items/presentation/cubit/items_state.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      context.read<ItemsCubit>().clear();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) context.read<ItemsCubit>().search(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              style: const TextStyle(color: WowTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search items by name...',
                hintStyle: const TextStyle(color: WowTheme.textSecondary),
                prefixIcon: const Icon(
                  Icons.search,
                  color: WowTheme.textSecondary,
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (_, value, __) => value.text.isNotEmpty
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
                if (state is ItemsInitial) return _buildHint();
                if (state is ItemsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: WowTheme.primaryGold,
                    ),
                  );
                }
                if (state is ItemsEmpty) return _buildEmpty();
                if (state is ItemsError) return _buildError(state.message);
                if (state is ItemsLoaded) return _buildList(state.items);
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.inventory_2_outlined,
          size: 64,
          color: WowTheme.textSecondary,
        ),
        SizedBox(height: 12),
        Text(
          'Search for items by name',
          style: TextStyle(color: WowTheme.textSecondary, fontSize: 16),
        ),
        SizedBox(height: 4),
        Text(
          'Type at least 2 characters',
          style: TextStyle(color: WowTheme.textSecondary, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _buildEmpty() => const Center(
    child: Text(
      'No items found',
      style: TextStyle(color: WowTheme.textSecondary, fontSize: 15),
    ),
  );

  Widget _buildError(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 56, color: WowTheme.accentRed),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: WowTheme.textSecondary),
          ),
        ],
      ),
    ),
  );

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
    final qualityColor = WowTheme.getQualityColor(item.quality);
    return Card(
      color: WowTheme.surfaceDark,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: qualityColor.withOpacity(0.4), width: 1),
      ),
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
                        placeholder: (_, __) => const Icon(
                          Icons.inventory_2,
                          color: WowTheme.textSecondary,
                          size: 28,
                        ),
                        errorWidget: (_, __, ___) => const Icon(
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
                    item.name,
                    style: TextStyle(
                      color: qualityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                'iLvl ${item.level}',
                style: const TextStyle(
                  color: WowTheme.primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
