import 'package:flutter/material.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/l10n/locale_notifier.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/usecases/search_items.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class ItemSearchDialog extends StatefulWidget {
  final WowSlot? slot;
  final String title;

  const ItemSearchDialog({super.key, this.slot, required this.title});

  @override
  State<ItemSearchDialog> createState() => _ItemSearchDialogState();
}

class _ItemSearchDialogState extends State<ItemSearchDialog> {
  final _controller = TextEditingController();
  List<Item> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final searchItems = sl<SearchItems>();
      final result = await searchItems(
        query.trim(),
        inventoryType: widget.slot?.inventoryType,
        locale: sl<LocaleNotifier>().blizzardLocale,
      );

      result.fold(
        (failure) {
          if (mounted) setState(() => _error = failure.toString());
        },
        (items) {
          if (mounted) setState(() => _results = items);
        },
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
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
                onChanged: _search,
              ),
              const SizedBox(height: 12),
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
        return ListTile(
          title: Text(
            item.name,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            [
              if (item.level != null) 'iLvl ${item.level}',
              if (item.inventoryName != null) item.inventoryName!,
            ].join(' · '),
            style: const TextStyle(color: WowTheme.textSecondary, fontSize: 12),
          ),
          onTap: () => Navigator.of(context).pop(item),
        );
      },
    );
  }
}
