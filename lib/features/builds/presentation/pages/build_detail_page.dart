import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_cubit.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_state.dart';
import 'package:wow_companion/features/builds/presentation/widgets/item_search_dialog.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';
import 'package:wow_companion/shared/widgets/wow_item_tooltip.dart';

class BuildDetailPage extends StatelessWidget {
  final String buildId;
  const BuildDetailPage({super.key, required this.buildId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BuildDetailCubit>()..loadBuild(buildId),
      child: const _BuildDetailView(),
    );
  }
}

class _BuildDetailView extends StatelessWidget {
  const _BuildDetailView();

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return BlocBuilder<BuildDetailCubit, BuildDetailState>(
      builder: (context, state) {
        if (state is BuildDetailLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: WowTheme.primaryGold),
            ),
          );
        }
        if (state is BuildDetailError) {
          return Scaffold(
            appBar: AppBar(title: Text(t.builds)),
            body: Center(
              child: Text(
                state.message,
                style: const TextStyle(color: WowTheme.textSecondary),
              ),
            ),
          );
        }
        if (state is BuildDetailLoaded) {
          return _BuildDetailContent(buildData: state.build);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _BuildDetailContent extends StatelessWidget {
  final Build buildData;
  const _BuildDetailContent({required this.buildData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              buildData.name,
              style: const TextStyle(color: WowTheme.primaryGold, fontSize: 16),
            ),
            if (buildData.characterRefDisplay != null)
              Text(
                buildData.characterRefDisplay!,
                style: const TextStyle(
                  color: WowTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          _ProgressHeader(buildData: buildData),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: buildData.slots.length,
              itemBuilder: (_, i) => _SlotCard(slot: buildData.slots[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final Build buildData;
  const _ProgressHeader({required this.buildData});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: WowTheme.surfaceDark,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: buildData.progress,
                backgroundColor: WowTheme.border,
                color: WowTheme.primaryGold,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            t.buildsSlots(buildData.obtainedSlots, buildData.totalSlots),
            style: const TextStyle(color: WowTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final BuildSlot slot;
  const _SlotCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final cubit = context.read<BuildDetailCubit>();
    final hasItem = slot.item != null;
    final qualityColor = hasItem
        ? WowTheme.getQualityColor(slot.item!.quality)
        : WowTheme.border;

    return Card(
      color: slot.obtained
          ? WowTheme.surfaceDark.withValues(alpha: 0.6)
          : WowTheme.surfaceDark,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: slot.obtained
              ? WowTheme.primaryGold.withValues(alpha: 0.4)
              : qualityColor,
          width: slot.obtained ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  slot.slot.displayName,
                  style: const TextStyle(
                    color: WowTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (hasItem)
                  Checkbox(
                    value: slot.obtained,
                    activeColor: WowTheme.primaryGold,
                    checkColor: WowTheme.darkBackground,
                    side: const BorderSide(color: WowTheme.textSecondary),
                    onChanged: (_) => cubit.toggleObtained(slot.slot),
                  ),
              ],
            ),
            if (!hasItem)
              TextButton.icon(
                onPressed: () => _pickItem(context, cubit, t),
                icon: const Icon(
                  Icons.add,
                  size: 16,
                  color: WowTheme.textSecondary,
                ),
                label: Text(
                  t.slotAssignItem,
                  style: const TextStyle(
                    color: WowTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: WowItemTooltip(
                      itemId: slot.item!.id,
                      child: Text(
                        slot.item!.name,
                        style: TextStyle(
                          color: qualityColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  if (slot.item!.level != null)
                    Text(
                      'iLvl ${slot.item!.level}',
                      style: const TextStyle(
                        color: WowTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: WowTheme.textSecondary,
                    ),
                    tooltip: t.slotClearSlot,
                    onPressed: () => cubit.clearSlot(slot.slot),
                  ),
                ],
              ),
              _EnchantRow(slot: slot, cubit: cubit),
              _GemsRow(slot: slot, cubit: cubit),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickItem(
    BuildContext context,
    BuildDetailCubit cubit,
    S t,
  ) async {
    final item = await showDialog<Item>(
      context: context,
      builder: (_) => ItemSearchDialog(
        slot: slot.slot,
        title: t.slotSearchItem(slot.slot.displayName),
      ),
    );
    if (item != null) cubit.assignItem(slot.slot, item);
  }
}

class _EnchantRow extends StatelessWidget {
  final BuildSlot slot;
  final BuildDetailCubit cubit;
  const _EnchantRow({required this.slot, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    if (slot.enchantment == null) {
      return TextButton.icon(
        onPressed: () => _pickEnchant(context, t),
        icon: const Icon(
          Icons.auto_fix_high,
          size: 14,
          color: WowTheme.textSecondary,
        ),
        label: Text(
          t.slotAddEnchantment,
          style: const TextStyle(color: WowTheme.textSecondary, fontSize: 12),
        ),
      );
    }
    return Row(
      children: [
        const Icon(Icons.auto_fix_high, size: 14, color: WowTheme.accentBlue),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            slot.enchantment!.name,
            style: const TextStyle(color: WowTheme.accentBlue, fontSize: 12),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.close,
            size: 14,
            color: WowTheme.textSecondary,
          ),
          tooltip: t.slotRemoveEnchantment,
          onPressed: () => cubit.removeEnchantment(slot.slot),
        ),
      ],
    );
  }

  Future<void> _pickEnchant(BuildContext context, S t) async {
    final item = await showDialog<Item>(
      context: context,
      builder: (_) =>
          ItemSearchDialog(slot: null, title: t.slotSearchEnchantment),
    );
    if (item != null) cubit.assignEnchantment(slot.slot, item);
  }
}

class _GemsRow extends StatelessWidget {
  final BuildSlot slot;
  final BuildDetailCubit cubit;
  const _GemsRow({required this.slot, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ...slot.gems.asMap().entries.map(
          (e) => Chip(
            backgroundColor: WowTheme.border,
            label: Text(
              e.value.name,
              style: const TextStyle(color: WowTheme.textPrimary, fontSize: 11),
            ),
            deleteIcon: const Icon(
              Icons.close,
              size: 12,
              color: WowTheme.textSecondary,
            ),
            onDeleted: () => cubit.removeGem(slot.slot, e.key),
          ),
        ),
        ActionChip(
          backgroundColor: WowTheme.border,
          label: Text(
            t.slotAddGem,
            style: const TextStyle(color: WowTheme.textSecondary, fontSize: 11),
          ),
          onPressed: () => _pickGem(context, t),
        ),
      ],
    );
  }

  Future<void> _pickGem(BuildContext context, S t) async {
    final item = await showDialog<Item>(
      context: context,
      builder: (_) => ItemSearchDialog(slot: null, title: t.slotSearchGem),
    );
    if (item != null) cubit.addGem(slot.slot, item);
  }
}
