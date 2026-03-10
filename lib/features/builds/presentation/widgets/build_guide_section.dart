import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/core/l10n/item_name_localizer.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_cubit.dart';
import 'package:wow_companion/features/builds/presentation/widgets/item_search_dialog.dart';
import 'package:wow_companion/features/builds/presentation/widgets/spell_search_dialog.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/entities/item_search_mode.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class BuildGuideSection extends StatefulWidget {
  final BuildGuide guide;
  const BuildGuideSection({super.key, required this.guide});

  @override
  State<BuildGuideSection> createState() => _BuildGuideSectionState();
}

class _BuildGuideSectionState extends State<BuildGuideSection> {
  bool _expanded = false;
  late TextEditingController _heroTalentController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _heroTalentController = TextEditingController(
      text: widget.guide.heroTalent ?? '',
    );
    _notesController = TextEditingController(text: widget.guide.notes ?? '');
  }

  @override
  void didUpdateWidget(BuildGuideSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controllers solo si el valor externo cambió (evita loop)
    if (oldWidget.guide.heroTalent != widget.guide.heroTalent &&
        _heroTalentController.text != (widget.guide.heroTalent ?? '')) {
      _heroTalentController.text = widget.guide.heroTalent ?? '';
    }
    if (oldWidget.guide.notes != widget.guide.notes &&
        _notesController.text != (widget.guide.notes ?? '')) {
      _notesController.text = widget.guide.notes ?? '';
    }
  }

  @override
  void dispose() {
    _heroTalentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final cubit = context.read<BuildDetailCubit>();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: WowTheme.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WowTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header expandible ──
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    color: WowTheme.primaryGold,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.guideTitle,
                    style: const TextStyle(
                      color: WowTheme.primaryGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (!widget.guide.isEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: WowTheme.primaryGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _summaryLabel(widget.guide, t),
                        style: const TextStyle(
                          color: WowTheme.primaryGold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: WowTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Contenido ──
          if (_expanded) ...[
            const Divider(color: WowTheme.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de contenido
                  _ContentSelector(
                    value: widget.guide.content,
                    onChanged: (v) => cubit.updateGuide(
                      widget.guide.copyWith(
                        content: v,
                        clearContent: v == null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hero Talent
                  _SectionLabel(t.guideHeroTalent),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _heroTalentController,
                    style: const TextStyle(
                      color: WowTheme.textPrimary,
                      fontSize: 13,
                    ),
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: t.guideHeroTalentHint,
                      hintStyle: const TextStyle(color: WowTheme.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (v) =>
                        cubit.updateGuide(widget.guide.copyWith(heroTalent: v)),
                  ),
                  const SizedBox(height: 16),

                  // Rotación
                  _SectionLabel(t.guideRotation),
                  const SizedBox(height: 8),
                  _RotationBoard(
                    spells: widget.guide.rotation,
                    cubit: cubit,
                    guide: widget.guide,
                  ),
                  const SizedBox(height: 16),

                  // Consumibles
                  _SectionLabel(t.guideConsumables),
                  const SizedBox(height: 8),
                  _ConsumablesSection(
                    consumables: widget.guide.consumables,
                    cubit: cubit,
                  ),
                  const SizedBox(height: 16),

                  // Notas
                  _SectionLabel(t.guideNotes),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    style: const TextStyle(
                      color: WowTheme.textPrimary,
                      fontSize: 13,
                    ),
                    maxLines: 5,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: t.guideNotesHint,
                      hintStyle: const TextStyle(color: WowTheme.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (v) =>
                        cubit.updateGuide(widget.guide.copyWith(notes: v)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _summaryLabel(BuildGuide g, S t) {
    final parts = <String>[];
    if (g.content != null) parts.add(_contentLabel(g.content!, t));
    if (g.rotation.isNotEmpty) parts.add(t.guideSpellsCount(g.rotation.length));
    if (!g.consumables.isEmpty) parts.add(t.guideConsumables);
    return parts.join(' · ');
  }

  String _contentLabel(BuildContent c, S t) => switch (c) {
    BuildContent.raid => t.guideContentRaid,
    BuildContent.mythicPlus => t.guideContentMythicPlus,
    BuildContent.both => t.guideContentBoth,
  };
}

// ─── Content selector ─────────────────────────────────────────────────────────
class _ContentSelector extends StatelessWidget {
  final BuildContent? value;
  final ValueChanged<BuildContent?> onChanged;

  const _ContentSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Row(
      children: [
        Text(
          t.guideContent,
          style: const TextStyle(color: WowTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 6,
            children: BuildContent.values.map((c) {
              final selected = value == c;
              final label = switch (c) {
                BuildContent.raid => t.guideContentRaid,
                BuildContent.mythicPlus => t.guideContentMythicPlus,
                BuildContent.both => t.guideContentBoth,
              };
              return GestureDetector(
                onTap: () => onChanged(selected ? null : c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? WowTheme.primaryGold.withValues(alpha: 0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected ? WowTheme.primaryGold : WowTheme.border,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? WowTheme.primaryGold
                          : WowTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: WowTheme.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );
}

// ─── Rotation board ───────────────────────────────────────────────────────────
class _RotationBoard extends StatelessWidget {
  final List<WowSpell> spells;
  final BuildDetailCubit cubit;
  final BuildGuide guide;

  const _RotationBoard({
    required this.spells,
    required this.cubit,
    required this.guide,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (spells.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              t.guideRotationEmpty,
              style: const TextStyle(
                color: WowTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          )
        else
          SizedBox(
            height: spells.length * 52.0,
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: spells.length,
              onReorder: (oldIndex, newIndex) =>
                  cubit.reorderRotation(oldIndex, newIndex),
              itemBuilder: (_, i) {
                final spell = spells[i];
                return _SpellCard(
                  key: ValueKey('rotation_$i'),
                  spell: spell,
                  index: i,
                  onRemove: () => cubit.removeSpellFromRotation(i),
                );
              },
            ),
          ),
        // Botón añadir
        GestureDetector(
          onTap: () => _addSpell(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(
                color: WowTheme.primaryGold.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  size: 14,
                  color: WowTheme.primaryGold.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  t.guideAddSpell,
                  style: TextStyle(
                    color: WowTheme.primaryGold.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addSpell(BuildContext context) async {
    final t = S.of(context)!;
    final spell = await showDialog<WowSpell>(
      context: context,
      builder: (_) => SpellSearchDialog(title: t.guideSearchSpell),
    );
    if (spell != null) cubit.addSpellToRotation(spell);
  }
}

// ─── Spell card ───────────────────────────────────────────────────────────────
class _SpellCard extends StatelessWidget {
  final WowSpell spell;
  final int index;
  final VoidCallback onRemove;

  const _SpellCard({
    super.key,
    required this.spell,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: WowTheme.darkBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WowTheme.border),
      ),
      child: Row(
        children: [
          // Número de orden
          SizedBox(
            width: 20,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: WowTheme.textSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 6),
          // Icono del spell
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: spell.iconUrl != null
                ? Image.network(
                    spell.iconUrl!,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallback(),
                  )
                : _fallback(),
          ),
          const SizedBox(width: 8),
          // Nombre
          Expanded(
            child: Text(
              spell.name,
              style: const TextStyle(color: WowTheme.textPrimary, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Drag handle
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.drag_handle,
                color: WowTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Eliminar
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              color: WowTheme.textSecondary,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: WowTheme.border,
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Icon(
      Icons.flash_on_outlined,
      size: 16,
      color: WowTheme.primaryGold,
    ),
  );
}

// ─── Consumables section ──────────────────────────────────────────────────────
class _ConsumablesSection extends StatelessWidget {
  final BuildConsumables consumables;
  final BuildDetailCubit cubit;

  const _ConsumablesSection({required this.consumables, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Column(
      children: [
        _ConsumableRow(
          label: t.guideFlask,
          item: consumables.flask,
          icon: Icons.science_outlined,
          onPick: () => _pick(
            context,
            title: t.guideFlask,
            onPicked: (item) => cubit.updateConsumable(flask: item),
            onClear: () => cubit.updateConsumable(clearFlask: true),
          ),
          onClear: () => cubit.updateConsumable(clearFlask: true),
        ),
        const SizedBox(height: 6),
        _ConsumableRow(
          label: t.guidePotion,
          item: consumables.potion,
          icon: Icons.local_drink_outlined,
          onPick: () => _pick(
            context,
            title: t.guidePotion,
            onPicked: (item) => cubit.updateConsumable(potion: item),
            onClear: () => cubit.updateConsumable(clearPotion: true),
          ),
          onClear: () => cubit.updateConsumable(clearPotion: true),
        ),
        const SizedBox(height: 6),
        _ConsumableRow(
          label: t.guideFood,
          item: consumables.food,
          icon: Icons.restaurant_outlined,
          onPick: () => _pick(
            context,
            title: t.guideFood,
            onPicked: (item) => cubit.updateConsumable(food: item),
            onClear: () => cubit.updateConsumable(clearFood: true),
          ),
          onClear: () => cubit.updateConsumable(clearFood: true),
        ),
      ],
    );
  }

  Future<void> _pick(
    BuildContext context, {
    required String title,
    required ValueChanged<Item> onPicked,
    required VoidCallback onClear,
  }) async {
    final item = await showDialog<Item>(
      context: context,
      builder: (_) => ItemSearchDialog(
        slot: null,
        title: title,
        mode: ItemSearchMode.consumable,
        region: cubit.searchRegion,
      ),
    );
    if (item != null) onPicked(item);
  }
}

class _ConsumableRow extends StatelessWidget {
  final String label;
  final Item? item;
  final IconData icon;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ConsumableRow({
    required this.label,
    required this.item,
    required this.icon,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasItem = item != null;
    final localeCode = Localizations.localeOf(context).languageCode;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: WowTheme.darkBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: hasItem
                ? WowTheme.border.withValues(alpha: 0.6)
                : WowTheme.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: hasItem ? WowTheme.primaryGold : WowTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: WowTheme.textSecondary,
                fontSize: 11,
                fontWeight: hasItem ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: hasItem
                  ? Row(
                      children: [
                        if (item!.iconUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Image.network(
                              item!.iconUrl!,
                              width: 18,
                              height: 18,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item!.primaryNameForLanguage(localeCode),
                            style: const TextStyle(
                              color: WowTheme.textPrimary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '—',
                      style: const TextStyle(
                        color: WowTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
            ),
            if (hasItem)
              GestureDetector(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: WowTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
