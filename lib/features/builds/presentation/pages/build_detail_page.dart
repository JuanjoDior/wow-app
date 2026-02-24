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
import 'package:wow_companion/shared/widgets/item_tooltip_trigger.dart';
import 'package:wow_companion/features/builds/presentation/widgets/build_guide_section.dart';
import 'package:wow_companion/features/builds/presentation/widgets/spec_recommendation_panel.dart';
import 'package:wow_companion/core/l10n/wow_translations.dart';
import 'package:wow_companion/core/data/wow_enchant_suggestions.dart';
import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';

// ─── Slot icon mapping ────────────────────────────────────────────────────────
IconData _slotIcon(WowSlot slot) => switch (slot) {
  WowSlot.head => Icons.face_retouching_natural,
  WowSlot.neck => Icons.radio_button_unchecked,
  WowSlot.shoulder => Icons.accessibility_new,
  WowSlot.back => Icons.style,
  WowSlot.chest => Icons.checkroom,
  WowSlot.wrist => Icons.watch_outlined,
  WowSlot.hands => Icons.back_hand_outlined,
  WowSlot.waist => Icons.horizontal_rule,
  WowSlot.legs => Icons.straighten,
  WowSlot.feet => Icons.directions_walk,
  WowSlot.finger1 || WowSlot.finger2 => Icons.circle_outlined,
  WowSlot.trinket1 || WowSlot.trinket2 => Icons.auto_awesome_outlined,
  WowSlot.mainHand => Icons.hardware_outlined,
  WowSlot.offHand => Icons.shield_outlined,
};

// ─── Slot name localización ───────────────────────────────────────────────────
extension WowSlotL10n on WowSlot {
  String localizedName(S t) => switch (this) {
    WowSlot.head => t.wowSlotHead,
    WowSlot.neck => t.wowSlotNeck,
    WowSlot.shoulder => t.wowSlotShoulder,
    WowSlot.back => t.wowSlotBack,
    WowSlot.chest => t.wowSlotChest,
    WowSlot.wrist => t.wowSlotWrist,
    WowSlot.hands => t.wowSlotHands,
    WowSlot.waist => t.wowSlotWaist,
    WowSlot.legs => t.wowSlotLegs,
    WowSlot.feet => t.wowSlotFeet,
    WowSlot.finger1 => t.wowSlotFinger1,
    WowSlot.finger2 => t.wowSlotFinger2,
    WowSlot.trinket1 => t.wowSlotTrinket1,
    WowSlot.trinket2 => t.wowSlotTrinket2,
    WowSlot.mainHand => t.wowSlotMainHand,
    WowSlot.offHand => t.wowSlotOffHand,
  };
}

// ─── Slot columns ─────────────────────────────────────────────────────────────
const _leftSlots = [
  WowSlot.head,
  WowSlot.shoulder,
  WowSlot.chest,
  WowSlot.hands,
  WowSlot.legs,
  WowSlot.finger1,
  WowSlot.trinket1,
  WowSlot.mainHand,
];

const _rightSlots = [
  WowSlot.neck,
  WowSlot.back,
  WowSlot.wrist,
  WowSlot.waist,
  WowSlot.feet,
  WowSlot.finger2,
  WowSlot.trinket2,
  WowSlot.offHand,
];

// ─── Page ─────────────────────────────────────────────────────────────────────
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
          final t = S.of(context);
          return Scaffold(
            appBar: AppBar(title: Text(t?.builds ?? 'Builds')),
            body: Center(
              child: Text(
                t?.buildNotFound ?? state.message,
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

// ─── Main content ─────────────────────────────────────────────────────────────
class _BuildDetailContent extends StatefulWidget {
  final Build buildData;
  const _BuildDetailContent({required this.buildData});

  @override
  State<_BuildDetailContent> createState() => _BuildDetailContentState();
}

class _BuildDetailContentState extends State<_BuildDetailContent> {
  String? _renderUrl;
  String? _avatarUrl;
  bool _loadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(_BuildDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buildData.characterRefKey !=
        widget.buildData.characterRefKey) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;
    setState(() => _loadingImage = true);
    final cubit = context.read<BuildDetailCubit>();
    final render = await cubit.fetchCharacterRenderUrl();
    final avatar = await cubit.fetchCharacterAvatarUrl();
    if (mounted) {
      setState(() {
        _renderUrl = render;
        _avatarUrl = avatar;
        _loadingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final build = widget.buildData;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          build.name,
          style: const TextStyle(color: WowTheme.primaryGold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return CustomScrollView(
            slivers: [
              // Encabezado de personaje — desaparece al hacer scroll
              if (build.characterClass != null)
                SliverToBoxAdapter(
                  child: _BuildCharacterHeader(
                    buildData: build,
                    avatarUrl: _avatarUrl,
                    loadingAvatar: _loadingImage,
                  ),
                ),
              // Barra de progreso — siempre visible (pinned)
              SliverPersistentHeader(
                pinned: true,
                delegate: _ProgressHeaderDelegate(buildData: build),
              ),
              // Contenido principal
              if (isMobile)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  sliver: _MobileSliverContent(
                    avatarUrl: _avatarUrl,
                    loadingImage: _loadingImage,
                    hasCharacter: build.characterRefKey != null,
                    showAvatar: build.characterClass == null,
                    guide: build.guide,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _PaperdollLayout(
                        renderUrl: _renderUrl,
                        loadingImage: _loadingImage,
                        hasCharacter: build.characterRefKey != null,
                      ),
                      const SizedBox(height: 8),
                      const SpecRecommendationPanel(),
                      BuildGuideSection(guide: build.guide),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Progress header delegate (pinned sliver) ────────────────────────────────
class _ProgressHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Build buildData;
  const _ProgressHeaderDelegate({required this.buildData});

  static const double _height = 56.0;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _ProgressHeader(buildData: buildData);
  }

  @override
  bool shouldRebuild(_ProgressHeaderDelegate old) => old.buildData != buildData;
}

// ─── Build character header ───────────────────────────────────────────────────
class _BuildCharacterHeader extends StatelessWidget {
  final Build buildData;
  final String? avatarUrl;
  final bool loadingAvatar;

  const _BuildCharacterHeader({
    required this.buildData,
    required this.avatarUrl,
    required this.loadingAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final classColor = WowTheme.getClassColor(buildData.characterClass!);

    final displayParts = buildData.characterRefDisplay?.split(' - ') ?? [];
    final charName = displayParts.isNotEmpty ? displayParts[0] : '';
    final charRealm = displayParts.length >= 2 ? displayParts[1] : '';
    final region =
        buildData.characterRefKey?.split('-').firstOrNull?.toUpperCase() ?? '';

    final detailParts = <String>[
      if (buildData.characterRace != null)
        WowTranslations.translateRace(buildData.characterRace!),
      WowTranslations.translateClass(buildData.characterClass!),
      if (buildData.characterSpec != null)
        WowTranslations.translateSpec(buildData.characterSpec!),
    ];

    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: classColor, width: 2),
              ),
              child: ClipOval(
                child: loadingAvatar
                    ? Container(
                        color: WowTheme.surfaceLight,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: WowTheme.primaryGold,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : avatarUrl != null
                    ? Image.network(
                        avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            _ClassFallback(classColor: classColor),
                      )
                    : _ClassFallback(classColor: classColor),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    charName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: classColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (charRealm.isNotEmpty || region.isNotEmpty)
                    Text(
                      [
                        charRealm,
                        region,
                      ].where((s) => s.isNotEmpty).join(' \u00b7 '),
                      style: const TextStyle(
                        color: WowTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  if (detailParts.isNotEmpty)
                    Text(
                      detailParts.join('  \u00b7  '),
                      style: const TextStyle(
                        color: WowTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassFallback extends StatelessWidget {
  final Color classColor;
  const _ClassFallback({required this.classColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WowTheme.surfaceLight,
      child: Icon(Icons.person_outline, color: classColor, size: 32),
    );
  }
}

// ─── Mobile sliver content ────────────────────────────────────────────────────
class _MobileSliverContent extends StatelessWidget {
  final String? avatarUrl;
  final bool loadingImage;
  final bool hasCharacter;
  final bool showAvatar;
  final BuildGuide guide;

  static const _allSlots = [
    WowSlot.head,
    WowSlot.neck,
    WowSlot.shoulder,
    WowSlot.back,
    WowSlot.chest,
    WowSlot.wrist,
    WowSlot.hands,
    WowSlot.waist,
    WowSlot.legs,
    WowSlot.feet,
    WowSlot.finger1,
    WowSlot.finger2,
    WowSlot.trinket1,
    WowSlot.trinket2,
    WowSlot.mainHand,
    WowSlot.offHand,
  ];

  const _MobileSliverContent({
    required this.avatarUrl,
    required this.loadingImage,
    required this.hasCharacter,
    required this.showAvatar,
    required this.guide,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (showAvatar) ...[
        _AvatarImage(
          avatarUrl: avatarUrl,
          loading: loadingImage,
          hasCharacter: hasCharacter,
        ),
        const SizedBox(height: 12),
      ],
      ...List.generate((_allSlots.length / 2).ceil(), (rowIndex) {
        final leftSlot = _allSlots[rowIndex * 2];
        final rightIndex = rowIndex * 2 + 1;
        final rightSlot = rightIndex < _allSlots.length
            ? _allSlots[rightIndex]
            : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _SlotButton(wowSlot: leftSlot, align: SlotAlign.left),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: rightSlot != null
                      ? _SlotButton(wowSlot: rightSlot, align: SlotAlign.right)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      }),
      // Panel de recomendaciones por spec — aparece si hay spec vinculada
      const SizedBox(height: 4),
      const SpecRecommendationPanel(),
      BuildGuideSection(guide: guide),
    ];

    return SliverList(delegate: SliverChildListDelegate(rows));
  }
}

// ─── Paperdoll layout ─────────────────────────────────────────────────────────
class _PaperdollLayout extends StatelessWidget {
  final String? renderUrl;
  final bool loadingImage;
  final bool hasCharacter;

  const _PaperdollLayout({
    required this.renderUrl,
    required this.loadingImage,
    required this.hasCharacter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final available = maxW - 64 - 24;
        final centerW = (available * 0.45).clamp(150.0, 240.0);
        final sideW = ((available - centerW) / 2) * 0.65;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: sideW,
                child: Column(
                  children: _leftSlots
                      .map(
                        (s) => _SlotButton(wowSlot: s, align: SlotAlign.left),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: centerW,
                child: _CharacterImage(
                  renderUrl: renderUrl,
                  loading: loadingImage,
                  hasCharacter: hasCharacter,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: sideW,
                child: Column(
                  children: _rightSlots
                      .map(
                        (s) => _SlotButton(wowSlot: s, align: SlotAlign.right),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Avatar image (móvil) ─────────────────────────────────────────────────────
class _AvatarImage extends StatelessWidget {
  final String? avatarUrl;
  final bool loading;
  final bool hasCharacter;

  const _AvatarImage({
    required this.avatarUrl,
    required this.loading,
    required this.hasCharacter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: WowTheme.primaryGold, width: 2),
          color: WowTheme.surfaceDark,
        ),
        child: ClipOval(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: WowTheme.primaryGold,
                    strokeWidth: 2,
                  ),
                )
              : avatarUrl != null
              ? Image.network(
                  avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _fallback(),
                )
              : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() => Icon(
    Icons.person_outline,
    size: 40,
    color: WowTheme.textSecondary.withValues(alpha: 0.5),
  );
}

// ─── Character image ──────────────────────────────────────────────────────────
class _CharacterImage extends StatelessWidget {
  final String? renderUrl;
  final bool loading;
  final bool hasCharacter;

  const _CharacterImage({
    required this.renderUrl,
    required this.loading,
    required this.hasCharacter,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (loading) {
      content = const Center(
        child: CircularProgressIndicator(
          color: WowTheme.primaryGold,
          strokeWidth: 2,
        ),
      );
    } else if (renderUrl != null) {
      content = Image.network(
        renderUrl!,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, _, _) => _silhouette(),
      );
    } else {
      content = _silhouette();
    }

    return AspectRatio(
      aspectRatio: 0.45,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              WowTheme.surfaceDark.withValues(alpha: 0.0),
              WowTheme.surfaceDark.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: content,
        ),
      ),
    );
  }

  Widget _silhouette() => Center(
    child: Icon(
      Icons.person_outline,
      size: 80,
      color: WowTheme.textSecondary.withValues(alpha: 0.3),
    ),
  );
}

// ─── Slot button ──────────────────────────────────────────────────────────────
enum SlotAlign { left, right }

class _SlotButton extends StatefulWidget {
  final WowSlot wowSlot;
  final SlotAlign align;

  const _SlotButton({required this.wowSlot, required this.align});

  @override
  State<_SlotButton> createState() => _SlotButtonState();
}

class _SlotButtonState extends State<_SlotButton> {
  bool _checkboxJustTapped = false;

  SlotAlign get align => widget.align;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BuildDetailCubit>();
    return BlocBuilder<BuildDetailCubit, BuildDetailState>(
      // Solo rebuild cuando cambia este slot concreto O llegan recomendaciones
      buildWhen: (prev, next) {
        final prevSlot = prev is BuildDetailLoaded
            ? prev.build.slots.firstWhere(
                (s) => s.slot == widget.wowSlot,
                orElse: () => BuildSlot(slot: widget.wowSlot),
              )
            : BuildSlot(slot: widget.wowSlot);
        final nextSlot = next is BuildDetailLoaded
            ? next.build.slots.firstWhere(
                (s) => s.slot == widget.wowSlot,
                orElse: () => BuildSlot(slot: widget.wowSlot),
              )
            : BuildSlot(slot: widget.wowSlot);
        final prevRec = prev is BuildDetailLoaded ? prev.recommendation : null;
        final nextRec = next is BuildDetailLoaded ? next.recommendation : null;
        return prevSlot != nextSlot || prevRec != nextRec;
      },
      builder: (context, state) {
        final slot = state is BuildDetailLoaded
            ? state.build.slots.firstWhere(
                (s) => s.slot == widget.wowSlot,
                orElse: () => BuildSlot(slot: widget.wowSlot),
              )
            : BuildSlot(slot: widget.wowSlot);
        final rec = state is BuildDetailLoaded ? state.recommendation : null;

        final hasItem = slot.item != null;
        final qualityColor = hasItem
            ? WowTheme.getQualityColor(slot.item!.quality)
            : WowTheme.border;
        final borderColor = slot.obtained
            ? WowTheme.primaryGold.withValues(alpha: 0.6)
            : qualityColor;

        final Widget icon = hasItem && slot.item!.iconUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  slot.item!.iconUrl!,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Icon(_slotIcon(slot.slot), size: 18, color: qualityColor),
                ),
              )
            : Icon(
                _slotIcon(slot.slot),
                size: 18,
                color: hasItem
                    ? qualityColor
                    : WowTheme.textSecondary.withValues(alpha: 0.5),
              );

        final t = S.of(context)!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: GestureDetector(
            onTap: () {
              if (_checkboxJustTapped) {
                _checkboxJustTapped = false;
                return;
              }
              _openSlotSheet(context, cubit, slot);
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 62),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: slot.obtained
                      ? WowTheme.surfaceDark.withValues(alpha: 0.4)
                      : WowTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor,
                    width: hasItem ? 1.5 : 1,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(5, 6, 5, 6),
                child: align == SlotAlign.left
                    ? _leftContent(
                        icon,
                        hasItem,
                        qualityColor,
                        cubit,
                        t,
                        slot,
                        rec,
                      )
                    : _rightContent(
                        icon,
                        hasItem,
                        qualityColor,
                        cubit,
                        t,
                        slot,
                        rec,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _miniCheckbox({
    required bool value,
    required Color color,
    required VoidCallback onToggle,
    Color? borderColor,
  }) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Checkbox(
        value: value,
        activeColor: color,
        checkColor: WowTheme.darkBackground,
        side: BorderSide(
          color: (borderColor ?? color).withValues(alpha: 0.8),
          width: 1.2,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onChanged: (_) {
          _checkboxJustTapped = true;
          Future.microtask(() => _checkboxJustTapped = false);
          onToggle();
        },
      ),
    );
  }

  Widget _leftContent(
    Widget icon,
    bool hasItem,
    Color qualityColor,
    BuildDetailCubit cubit,
    S t,
    BuildSlot slot,
    SpecRecommendation? rec,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        const SizedBox(width: 6),
        Expanded(
          child: _slotText(
            hasItem,
            qualityColor,
            TextAlign.left,
            cubit,
            t,
            slot,
            rec,
          ),
        ),
      ],
    );
  }

  Widget _rightContent(
    Widget icon,
    bool hasItem,
    Color qualityColor,
    BuildDetailCubit cubit,
    S t,
    BuildSlot slot,
    SpecRecommendation? rec,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _slotText(
            hasItem,
            qualityColor,
            TextAlign.right,
            cubit,
            t,
            slot,
            rec,
          ),
        ),
        const SizedBox(width: 6),
        icon,
      ],
    );
  }

  Widget _slotText(
    bool hasItem,
    Color qualityColor,
    TextAlign align,
    BuildDetailCubit cubit,
    S t,
    BuildSlot slot,
    SpecRecommendation? rec,
  ) {
    if (!hasItem) {
      return Text(
        slot.slot.localizedName(t),
        textAlign: align,
        style: TextStyle(
          color: WowTheme.textSecondary.withValues(alpha: 0.7),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Column(
      crossAxisAlignment: align == TextAlign.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          slot.slot.localizedName(t),
          textAlign: align,
          style: TextStyle(
            color: WowTheme.textSecondary.withValues(alpha: 0.6),
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (align == TextAlign.right) ...[
              _miniCheckbox(
                value: slot.obtained,
                color: WowTheme.primaryGold,
                onToggle: () => cubit.toggleObtained(slot.slot),
                borderColor: WowTheme.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                slot.item!.name,
                textAlign: align,
                style: TextStyle(
                  color: qualityColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (align == TextAlign.left) ...[
              const SizedBox(width: 4),
              _miniCheckbox(
                value: slot.obtained,
                color: WowTheme.primaryGold,
                onToggle: () => cubit.toggleObtained(slot.slot),
                borderColor: WowTheme.textSecondary,
              ),
            ],
          ],
        ),
        if (slot.item!.level != null)
          Text(
            '${t.ilvl} ${slot.item!.level}',
            textAlign: align,
            style: TextStyle(
              color: WowTheme.textSecondary.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        // Enchantment asignado O hint de sugerencia
        if (slot.enchantment != null)
          _inlineLabel(
            icon: '\u2746',
            label: slot.enchantment!.name,
            obtained: slot.enchantmentObtained,
            color: WowTheme.accentBlue,
            align: align,
            onToggle: () => cubit.toggleEnchantmentObtained(slot.slot),
          )
        else if (EnchantResolver.isEnchantable(slot.slot, recommendation: rec))
          _enchantHint(
            label: EnchantResolver.primaryForSlot(
              slot.slot,
              recommendation: rec,
            )!.name,
            align: align,
            isSpecific: rec != null,
          ),
        ...slot.gems.asMap().entries.map((e) {
          final gemObtained = e.key < slot.gemsObtained.length
              ? slot.gemsObtained[e.key]
              : false;
          return _inlineLabel(
            icon: '\u25c6',
            label: e.value.name,
            obtained: gemObtained,
            color: WowTheme.textSecondary.withValues(alpha: 0.8),
            align: align,
            onToggle: () => cubit.toggleGemObtained(slot.slot, e.key),
          );
        }),
      ],
    );
  }

  /// Texto sutil en cursiva que sugiere el enchant BiS cuando el slot no tiene ninguno.
  /// [isSpecific] = true si viene de datos por spec (vs. fallback genérico).
  Widget _enchantHint({
    required String label,
    required TextAlign align,
    bool isSpecific = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '\u2736 $label',
        textAlign: align,
        style: TextStyle(
          // Un poco más visible cuando es spec-aware
          color: WowTheme.accentBlue.withValues(
            alpha: isSpecific ? 0.55 : 0.40,
          ),
          fontSize: 10,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _inlineLabel({
    required String icon,
    required String label,
    required bool obtained,
    required Color color,
    required TextAlign align,
    required VoidCallback onToggle,
  }) {
    final cb = _miniCheckbox(value: obtained, color: color, onToggle: onToggle);
    final txt = Expanded(
      child: Text(
        '$icon $label',
        textAlign: align,
        style: TextStyle(
          color: obtained ? color.withValues(alpha: 0.35) : color,
          fontSize: 10,
          decoration: obtained ? TextDecoration.lineThrough : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: align == TextAlign.left
            ? [txt, const SizedBox(width: 4), cb]
            : [cb, const SizedBox(width: 4), txt],
      ),
    );
  }

  void _openSlotSheet(
    BuildContext context,
    BuildDetailCubit cubit,
    BuildSlot slot,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: WowTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _SlotSheet(wowSlot: slot.slot),
      ),
    );
  }
}

// ─── Slot bottom sheet ────────────────────────────────────────────────────────
class _SlotSheet extends StatelessWidget {
  final WowSlot wowSlot;
  const _SlotSheet({required this.wowSlot});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BuildDetailCubit>();
    return BlocBuilder<BuildDetailCubit, BuildDetailState>(
      builder: (context, state) {
        final loaded = state is BuildDetailLoaded ? state : null;
        final build = loaded?.build;
        final slot =
            build?.slots.firstWhere(
              (s) => s.slot == wowSlot,
              orElse: () => BuildSlot(slot: wowSlot),
            ) ??
            BuildSlot(slot: wowSlot);
        return _SlotSheetContent(
          slot: slot,
          cubit: cubit,
          recommendation: loaded?.recommendation,
        );
      },
    );
  }
}

class _SlotSheetContent extends StatelessWidget {
  final BuildSlot slot;
  final BuildDetailCubit cubit;
  final SpecRecommendation? recommendation;
  const _SlotSheetContent({
    required this.slot,
    required this.cubit,
    this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final hasItem = slot.item != null;
    final qualityColor = hasItem
        ? WowTheme.getQualityColor(slot.item!.quality)
        : WowTheme.border;
    // Usar EnchantResolver spec-aware (fallback a genérico si no hay recommendation)
    final suggestions = EnchantResolver.suggestionsForSlot(
      slot.slot,
      recommendation: recommendation,
    );
    final hasSpecificRecForSlot =
        recommendation != null &&
        recommendation!.enchantsForSlot(slot.slot.slotKey).isNotEmpty;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: WowTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Título
          Row(
            children: [
              Icon(_slotIcon(slot.slot), color: WowTheme.primaryGold, size: 20),
              const SizedBox(width: 8),
              Text(
                slot.slot.localizedName(t),
                style: const TextStyle(
                  color: WowTheme.primaryGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (hasItem)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: slot.obtained,
                    activeColor: WowTheme.primaryGold,
                    checkColor: WowTheme.darkBackground,
                    side: const BorderSide(
                      color: WowTheme.textSecondary,
                      width: 1.5,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (_) => cubit.toggleObtained(slot.slot),
                  ),
                ),
            ],
          ),
          const Divider(color: WowTheme.border, height: 24),

          // ── Ítem ──────────────────────────────────────────────────────────
          if (!hasItem)
            _sheetAction(
              icon: Icons.add,
              label: t.slotAssignItem,
              color: WowTheme.textSecondary,
              onTap: () => _pickItem(context, cubit, t),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (slot.item!.iconUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      slot.item!.iconUrl!,
                      width: 44,
                      height: 44,
                      errorBuilder: (_, _, _) => Icon(
                        _slotIcon(slot.slot),
                        size: 44,
                        color: WowTheme.textSecondary,
                      ),
                    ),
                  )
                else
                  Icon(
                    _slotIcon(slot.slot),
                    size: 44,
                    color: WowTheme.textSecondary,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: ItemTooltipTrigger.forItemId(
                    itemId: slot.item!.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.item!.name,
                          style: TextStyle(
                            color: qualityColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (slot.item!.level != null)
                          Text(
                            '${t.ilvl} ${slot.item!.level}',
                            style: const TextStyle(
                              color: WowTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.swap_horiz,
                    color: WowTheme.textSecondary,
                  ),
                  tooltip: t.slotAssignItem,
                  onPressed: () => _pickItem(context, cubit, t),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: WowTheme.textSecondary),
                  tooltip: t.slotClearSlot,
                  onPressed: () {
                    cubit.clearSlot(slot.slot);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),

            // ── Enchantment ────────────────────────────────────────────────
            const SizedBox(height: 16),
            Text(
              t.slotEnchantmentLabel,
              style: const TextStyle(
                color: WowTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            if (slot.enchantment == null) ...[
              _sheetAction(
                icon: Icons.auto_fix_high,
                label: t.slotAddEnchantment,
                color: WowTheme.textSecondary,
                onTap: () => _pickEnchant(context, cubit, t),
              ),
              // Sugerencias de enchant para este slot
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  hasSpecificRecForSlot
                      ? t.recEnchantSuggestedSpec
                      : t.recEnchantSuggestedGeneric,
                  style: TextStyle(
                    color: hasSpecificRecForSlot
                        ? WowTheme.accentBlue.withValues(alpha: 0.7)
                        : WowTheme.textSecondary.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                ...suggestions.map(
                  (s) => _SuggestionTile(
                    suggestion: s,
                    isPrimary: suggestions.first == s,
                    onApply: () => cubit.assignEnchantment(
                      slot.slot,
                      Item(id: 0, name: s.name, quality: 'UNCOMMON'),
                    ),
                  ),
                ),
              ],
            ] else
              Row(
                children: [
                  const Icon(
                    Icons.auto_fix_high,
                    size: 16,
                    color: WowTheme.accentBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      slot.enchantment!.name,
                      style: const TextStyle(
                        color: WowTheme.accentBlue,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: WowTheme.textSecondary,
                    ),
                    onPressed: () => cubit.removeEnchantment(slot.slot),
                  ),
                ],
              ),

            // ── Gems ───────────────────────────────────────────────────────
            const SizedBox(height: 16),
            Text(
              t.slotGemsLabel,
              style: const TextStyle(
                color: WowTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ...slot.gems.asMap().entries.map(
                  (e) => Chip(
                    backgroundColor: WowTheme.border,
                    label: Text(
                      e.value.name,
                      style: const TextStyle(
                        color: WowTheme.textPrimary,
                        fontSize: 11,
                      ),
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
                    style: const TextStyle(
                      color: WowTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  onPressed: () => _pickGem(context, cubit, t),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sheetAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: WowTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
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
    Navigator.of(context).pop();
    final item = await showDialog<Item>(
      context: context,
      builder: (_) => ItemSearchDialog(
        slot: slot.slot,
        title: t.slotSearchItem(slot.slot.localizedName(t)),
      ),
    );
    if (item != null) cubit.assignItem(slot.slot, item);
  }

  Future<void> _pickEnchant(
    BuildContext context,
    BuildDetailCubit cubit,
    S t,
  ) async {
    final item = await showDialog<Item>(
      context: context,
      builder: (_) =>
          ItemSearchDialog(slot: null, title: t.slotSearchEnchantment),
    );
    if (item != null) cubit.assignEnchantment(slot.slot, item);
  }

  Future<void> _pickGem(
    BuildContext context,
    BuildDetailCubit cubit,
    S t,
  ) async {
    final item = await showDialog<Item>(
      context: context,
      builder: (_) => ItemSearchDialog(slot: null, title: t.slotSearchGem),
    );
    if (item != null) cubit.addGem(slot.slot, item);
  }
}

// ─── Suggestion tile (sheet) ─────────────────────────────────────────────────
/// Fila de sugerencia de enchant con botón "Aplicar" de un tap.
class _SuggestionTile extends StatelessWidget {
  final EnchantSuggestion suggestion;
  final bool isPrimary;
  final VoidCallback onApply;

  const _SuggestionTile({
    required this.suggestion,
    required this.isPrimary,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onApply,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: WowTheme.accentBlue.withValues(
              alpha: isPrimary ? 0.08 : 0.04,
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: WowTheme.accentBlue.withValues(
                alpha: isPrimary ? 0.35 : 0.15,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_fix_high,
                size: 14,
                color: WowTheme.accentBlue.withValues(
                  alpha: isPrimary ? 0.9 : 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.name,
                      style: TextStyle(
                        color: WowTheme.accentBlue.withValues(
                          alpha: isPrimary ? 1.0 : 0.7,
                        ),
                        fontSize: 12,
                        fontWeight: isPrimary
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (suggestion.note != null)
                      Text(
                        suggestion.note!,
                        style: TextStyle(
                          color: WowTheme.textSecondary.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Builder(
                builder: (ctx) => Text(
                  S.of(ctx)!.recEnchantApply,
                  style: TextStyle(
                    color: WowTheme.accentBlue.withValues(
                      alpha: isPrimary ? 0.9 : 0.5,
                    ),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Progress header ──────────────────────────────────────────────────────────
class _ProgressHeader extends StatelessWidget {
  final Build buildData;
  const _ProgressHeader({required this.buildData});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final progress = buildData.progress;

    final barColor = progress < 0.33
        ? const Color(0xFFE74C3C)
        : progress < 0.66
        ? const Color(0xFFF39C12)
        : progress < 1.0
        ? WowTheme.primaryGold
        : const Color(0xFF2ECC71);

    final percent = '${(progress * 100).toInt()}%';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: WowTheme.surfaceDark,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (_, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: WowTheme.border,
                  color: barColor,
                  minHeight: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                t.buildsSlots(buildData.obtainedSlots, buildData.totalSlots),
                style: const TextStyle(
                  color: WowTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                percent,
                style: TextStyle(
                  color: barColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
