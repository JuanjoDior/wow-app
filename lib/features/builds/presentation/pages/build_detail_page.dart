import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/core/config/feature_flags.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/entities/build_gap_analysis.dart';
import 'package:wow_companion/features/builds/domain/entities/economy_price_summary.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_cubit.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_state.dart';
import 'package:wow_companion/features/builds/presentation/widgets/item_search_dialog.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/entities/item_search_mode.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';
import 'package:wow_companion/shared/widgets/item_tooltip_trigger.dart';
import 'package:wow_companion/features/builds/presentation/widgets/build_guide_section.dart';
import 'package:wow_companion/core/l10n/wow_translations.dart';

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

String _itemNameForLocale(BuildContext context, Item item) {
  final localeCode = Localizations.localeOf(context).languageCode;
  final localized = item.localizedName?.trim();
  final canonical = item.canonicalNameEn?.trim() ?? item.name;
  if (localeCode == 'es' &&
      localized != null &&
      localized.isNotEmpty &&
      localized.toLowerCase() != canonical.toLowerCase()) {
    return '$localized · $canonical';
  }
  return canonical;
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
  final bool showEconomyAssistant;
  const BuildDetailPage({
    super.key,
    required this.buildId,
    bool? showEconomyAssistant,
  }) : showEconomyAssistant =
           showEconomyAssistant ?? FeatureFlags.economyAssistant;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BuildDetailCubit>()..loadBuild(buildId),
      child: _BuildDetailView(showEconomyAssistant: showEconomyAssistant),
    );
  }
}

class _BuildDetailView extends StatelessWidget {
  final bool showEconomyAssistant;
  const _BuildDetailView({required this.showEconomyAssistant});

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
          final t = S.of(context)!;
          return Scaffold(
            appBar: AppBar(title: Text(t.builds)),
            body: Center(
              child: Text(
                t.buildNotFound,
                style: const TextStyle(color: WowTheme.textSecondary),
              ),
            ),
          );
        }
        if (state is BuildDetailLoaded) {
          return _BuildDetailContent(
            buildData: state.build,
            gapAnalysis: state.gapAnalysis,
            gapAnalysisLoading: state.isGapAnalysisLoading,
            showEconomyAssistant: showEconomyAssistant,
            economySummary: state.economySummary,
            economyLoading: state.isEconomyLoading,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ─── Main content ─────────────────────────────────────────────────────────────
class _BuildDetailContent extends StatefulWidget {
  final Build buildData;
  final BuildGapAnalysis? gapAnalysis;
  final bool gapAnalysisLoading;
  final bool showEconomyAssistant;
  final EconomyPriceSummary? economySummary;
  final bool economyLoading;

  const _BuildDetailContent({
    required this.buildData,
    required this.gapAnalysis,
    required this.gapAnalysisLoading,
    required this.showEconomyAssistant,
    required this.economySummary,
    required this.economyLoading,
  });

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
    setState(() {
      _loadingImage = true;
      _avatarUrl ??= widget.buildData.characterAvatarUrl;
    });
    final cubit = context.read<BuildDetailCubit>();
    final render = await cubit.fetchCharacterRenderUrl();
    final avatar = await cubit.fetchCharacterAvatarUrl();
    if (mounted) {
      setState(() {
        _renderUrl = render;
        _avatarUrl = avatar ?? render ?? widget.buildData.characterAvatarUrl;
        _loadingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final build = widget.buildData;
    final hasCharacter = build.characterRefKey != null;

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
                    avatarUrl: _avatarUrl ?? build.characterAvatarUrl,
                    loadingAvatar: _loadingImage,
                  ),
                ),
              // Barra de progreso — siempre visible (pinned)
              SliverPersistentHeader(
                pinned: true,
                delegate: _ProgressHeaderDelegate(buildData: build),
              ),
              if (FeatureFlags.buildIntelligence)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 12 : 16,
                      10,
                      isMobile ? 12 : 16,
                      4,
                    ),
                    child: _BuildIntelligenceSection(
                      gapAnalysis: widget.gapAnalysis,
                      loading: widget.gapAnalysisLoading,
                      hasCharacter: hasCharacter,
                    ),
                  ),
                ),
              if (widget.showEconomyAssistant)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 12 : 16,
                      4,
                      isMobile ? 12 : 16,
                      4,
                    ),
                    child: _BuildEconomySection(
                      buildData: build,
                      economySummary: widget.economySummary,
                      loading: widget.economyLoading,
                    ),
                  ),
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
                    hasCharacter: hasCharacter,
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
                        hasCharacter: hasCharacter,
                      ),
                      const SizedBox(height: 8),
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
    final localeCode = Localizations.localeOf(context).languageCode;
    final classColor = WowTheme.getClassColor(buildData.characterClass!);

    final displayParts = buildData.characterRefDisplay?.split(' - ') ?? [];
    final charName = displayParts.isNotEmpty ? displayParts[0] : '';
    final charRealm = displayParts.length >= 2 ? displayParts[1] : '';
    final region =
        buildData.characterRefKey?.split('-').firstOrNull?.toUpperCase() ?? '';

    final detailParts = <String>[
      if (buildData.characterRace != null)
        WowTranslations.translateRace(buildData.characterRace!, localeCode),
      WowTranslations.translateClass(buildData.characterClass!, localeCode),
      if (buildData.characterSpec != null)
        WowTranslations.translateSpec(buildData.characterSpec!, localeCode),
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

class _BuildIntelligenceSection extends StatelessWidget {
  final BuildGapAnalysis? gapAnalysis;
  final bool loading;
  final bool hasCharacter;

  const _BuildIntelligenceSection({
    required this.gapAnalysis,
    required this.loading,
    required this.hasCharacter,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.buildIntelligenceTitle,
                        style: const TextStyle(
                          color: WowTheme.primaryGold,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.buildIntelligenceSubtitle,
                        style: TextStyle(
                          color: WowTheme.textSecondary.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: WowTheme.textSecondary,
                  ),
                  tooltip: t.retry,
                  onPressed: loading || !hasCharacter
                      ? null
                      : () => context
                            .read<BuildDetailCubit>()
                            .refreshGapAnalysis(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!hasCharacter)
              Text(
                t.buildIntelligenceMissingCharacter,
                style: const TextStyle(color: WowTheme.textSecondary),
              )
            else if (loading && gapAnalysis == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: CircularProgressIndicator(
                    color: WowTheme.primaryGold,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (gapAnalysis == null)
              Text(
                t.buildIntelligenceNoData,
                style: const TextStyle(color: WowTheme.textSecondary),
              )
            else ...[
              if ((gapAnalysis!.summary.targetProfile ?? '') ==
                      'build_target' ||
                  gapAnalysis!.summary.checksTotal > 0)
                _BuildIntelligenceSummary(summary: gapAnalysis!.summary)
              else if (gapAnalysis!.facts != null) ...[
                Text(
                  t.buildIntelligenceCharacterStatus,
                  style: const TextStyle(
                    color: WowTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _BuildIntelligenceFacts(facts: gapAnalysis!.facts!),
                const SizedBox(height: 8),
                Text(
                  t.buildIntelligenceNoTargetHint,
                  style: const TextStyle(
                    color: WowTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ] else
                Text(
                  t.buildIntelligenceNoData,
                  style: const TextStyle(color: WowTheme.textSecondary),
                ),
              const SizedBox(height: 10),
              if ((gapAnalysis!.summary.targetProfile ?? '') ==
                      'build_target' ||
                  gapAnalysis!.summary.checksTotal > 0) ...[
                Text(
                  t.buildIntelligenceTopActions,
                  style: const TextStyle(
                    color: WowTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                if (gapAnalysis!.actions.isEmpty)
                  Text(
                    t.buildIntelligenceNoData,
                    style: const TextStyle(color: WowTheme.textSecondary),
                  )
                else
                  ...gapAnalysis!.actions.take(3).map((action) {
                    final meta = _buildActionMeta(t, action);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• [${action.priorityScore}] ${_localizeActionLabel(t, action)}',
                            style: const TextStyle(
                              color: WowTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          if (meta != null)
                            Text(
                              meta,
                              style: const TextStyle(
                                color: WowTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _localizeActionLabel(S t, BuildGapAction action) {
    final expected = action.expected?.trim();
    final recommended = action.recommended?.trim();
    final target = (expected != null && expected.isNotEmpty)
        ? expected
        : (recommended != null && recommended.isNotEmpty)
        ? recommended
        : action.label;

    return switch (action.type) {
      'enchant_missing_target' ||
      'enchant_missing' => t.buildIntelligenceActionEnchantMissing(target),
      'enchant_mismatch_target' ||
      'enchant_mismatch' => t.buildIntelligenceActionEnchantMismatch(target),
      'gem_missing_target' ||
      'gem_missing' => t.buildIntelligenceActionGemMissing(target),
      'gem_mismatch_target' ||
      'gem_mismatch' => t.buildIntelligenceActionGemMismatch(target),
      _ => action.label,
    };
  }

  String? _buildActionMeta(S t, BuildGapAction action) {
    final parts = <String>[];

    if ((action.estimatedCostCopper ?? 0) > 0) {
      parts.add(
        '${t.buildIntelligenceEstimatedCostShort}: ${_formatCopperValue(action.estimatedCostCopper)}',
      );
    }
    if ((action.roiScore ?? 0) > 0) {
      parts.add('${t.buildIntelligenceRoiShort}: ${action.roiScore}');
    }

    if (parts.isEmpty) return null;
    return parts.join('  ·  ');
  }
}

class _BuildIntelligenceFacts extends StatelessWidget {
  final BuildGapFacts facts;

  const _BuildIntelligenceFacts({required this.facts});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final metrics = [
      (
        label: t.buildIntelligenceEquippedItems,
        value: '${facts.equippedItemsCount}',
      ),
      (
        label: t.buildIntelligenceEnchantedItems,
        value: '${facts.enchantedItemsCount}',
      ),
      (
        label: t.buildIntelligenceSockets,
        value: '${facts.socketsFilledCount}/${facts.socketsTotalCount}',
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: metrics
          .map(
            (metric) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: WowTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: WowTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    style: TextStyle(
                      color: WowTheme.textSecondary.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metric.value,
                    style: const TextStyle(
                      color: WowTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _BuildIntelligenceSummary extends StatelessWidget {
  final BuildGapSummary summary;

  const _BuildIntelligenceSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final metrics = <({String label, String value})>[
      (
        label: t.buildIntelligenceCompletion,
        value: '${summary.completionPct}%',
      ),
      (
        label: t.buildIntelligenceMissingEnchants,
        value: '${summary.missingEnchants}',
      ),
      (label: t.buildIntelligenceMissingGems, value: '${summary.missingGems}'),
    ];
    if ((summary.estimatedTotalCostCopper ?? 0) > 0) {
      metrics.add((
        label: t.buildIntelligenceSummaryEstimatedCost,
        value: _formatCopperValue(summary.estimatedTotalCostCopper),
      ));
    }
    if (summary.pricedActionsCount != null) {
      metrics.add((
        label: t.buildIntelligenceSummaryPricedActions,
        value: '${summary.pricedActionsCount}/${summary.actionsCount}',
      ));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: metrics
          .map(
            (metric) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: WowTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: WowTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    style: TextStyle(
                      color: WowTheme.textSecondary.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metric.value,
                    style: const TextStyle(
                      color: WowTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _BuildEconomySection extends StatelessWidget {
  final Build buildData;
  final EconomyPriceSummary? economySummary;
  final bool loading;

  const _BuildEconomySection({
    required this.buildData,
    required this.economySummary,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final itemMap = _collectEconomyItems(buildData);
    final hasTargets = itemMap.isNotEmpty;
    final pricedResults =
        (economySummary?.results ?? <EconomyPriceResult>[])
            .where((entry) => entry.listingCount > 0)
            .toList()
          ..sort((a, b) {
            final left = a.medianPrice ?? a.p95Price ?? a.minPrice ?? 0;
            final right = b.medianPrice ?? b.p95Price ?? b.minPrice ?? 0;
            return right.compareTo(left);
          });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.economyAssistantTitle,
                        style: const TextStyle(
                          color: WowTheme.primaryGold,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.economyAssistantSubtitle,
                        style: TextStyle(
                          color: WowTheme.textSecondary.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: WowTheme.textSecondary,
                  ),
                  tooltip: t.retry,
                  onPressed: loading || !hasTargets
                      ? null
                      : () => context.read<BuildDetailCubit>().refreshEconomy(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!hasTargets)
              Text(
                t.economyAssistantEmptyBuild,
                style: const TextStyle(color: WowTheme.textSecondary),
              )
            else if (loading && economySummary == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: CircularProgressIndicator(
                    color: WowTheme.primaryGold,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (economySummary == null)
              Text(
                t.economyAssistantNoData,
                style: const TextStyle(color: WowTheme.textSecondary),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _EconomyMetricChip(
                    label: t.economyAssistantPricedItems,
                    value:
                        '${economySummary!.summary.resolvedItems}/${economySummary!.summary.requestedItems}',
                  ),
                  _EconomyMetricChip(
                    label: t.economyAssistantMissingItems,
                    value: '${economySummary!.summary.missingItems}',
                  ),
                  _EconomyMetricChip(
                    label: t.economyAssistantMarket,
                    value: _marketLabel(t, economySummary!.source?.market),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                t.economyAssistantTopItems,
                style: const TextStyle(
                  color: WowTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              if (pricedResults.isEmpty)
                Text(
                  t.economyAssistantNoData,
                  style: const TextStyle(color: WowTheme.textSecondary),
                )
              else
                ...pricedResults.take(5).map((entry) {
                  final item = itemMap[entry.itemId];
                  final label = item == null
                      ? t.economyAssistantItemFallback(entry.itemId)
                      : _itemNameForLocale(context, item);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: WowTheme.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${t.economyAssistantMedianPrice}: ${_formatCopperValue(entry.medianPrice)}',
                          style: const TextStyle(
                            color: WowTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }

  String _marketLabel(S t, String? market) {
    switch ((market ?? '').toLowerCase().trim()) {
      case 'commodities':
        return t.economyAssistantMarketCommodities;
      case 'auctions':
        return t.economyAssistantMarketAuctions;
      default:
        return t.economyAssistantMarketUnknown;
    }
  }

  Map<int, Item> _collectEconomyItems(Build build) {
    final items = <int, Item>{};
    for (final slot in build.slots) {
      final enchant = slot.enchantment;
      if (enchant != null && enchant.id > 0) {
        items[enchant.id] = enchant;
      }
      for (final gem in slot.gems) {
        if (gem.id > 0) {
          items[gem.id] = gem;
        }
      }
    }

    final consumables = build.guide.consumables;
    if (consumables.flask != null && consumables.flask!.id > 0) {
      items[consumables.flask!.id] = consumables.flask!;
    }
    if (consumables.potion != null && consumables.potion!.id > 0) {
      items[consumables.potion!.id] = consumables.potion!;
    }
    if (consumables.food != null && consumables.food!.id > 0) {
      items[consumables.food!.id] = consumables.food!;
    }

    return items;
  }
}

String _formatCopperValue(int? value) {
  if (value == null || value <= 0) return '-';
  final gold = value ~/ 10000;
  final silver = (value % 10000) ~/ 100;
  final copper = value % 100;
  return '${gold}g ${silver}s ${copper}c';
}

class _EconomyMetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _EconomyMetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: WowTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WowTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: WowTheme.textSecondary.withValues(alpha: 0.85),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: WowTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
        final cfg = _paperdollConfigForWidth(constraints.maxWidth);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: cfg.outerHorizontalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: cfg.sideFlex,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cfg.sideMaxWidth),
                    child: Column(
                      children: _leftSlots
                          .map(
                            (s) =>
                                _SlotButton(wowSlot: s, align: SlotAlign.left),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
              SizedBox(width: cfg.gap),
              Expanded(
                flex: cfg.centerFlex,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: cfg.centerInnerHorizontalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: cfg.centerMinWidth,
                      maxWidth: cfg.centerMaxWidth,
                    ),
                    child: _CharacterImage(
                      renderUrl: renderUrl,
                      loading: loadingImage,
                      hasCharacter: hasCharacter,
                      aspectRatio: cfg.centerAspectRatio,
                    ),
                  ),
                ),
              ),
              SizedBox(width: cfg.gap),
              Expanded(
                flex: cfg.sideFlex,
                child: Align(
                  alignment: Alignment.topRight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cfg.sideMaxWidth),
                    child: Column(
                      children: _rightSlots
                          .map(
                            (s) =>
                                _SlotButton(wowSlot: s, align: SlotAlign.right),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _PaperdollResponsiveConfig _paperdollConfigForWidth(double width) {
    if (width >= 1700) {
      return const _PaperdollResponsiveConfig(
        outerHorizontalPadding: 20,
        sideFlex: 34,
        centerFlex: 32,
        gap: 28,
        sideMaxWidth: 390,
        centerMinWidth: 260,
        centerMaxWidth: 380,
        centerInnerHorizontalPadding: 10,
        centerAspectRatio: 0.64,
      );
    }
    if (width >= 1400) {
      return const _PaperdollResponsiveConfig(
        outerHorizontalPadding: 18,
        sideFlex: 35,
        centerFlex: 30,
        gap: 24,
        sideMaxWidth: 360,
        centerMinWidth: 240,
        centerMaxWidth: 340,
        centerInnerHorizontalPadding: 8,
        centerAspectRatio: 0.6,
      );
    }
    if (width >= 1150) {
      return const _PaperdollResponsiveConfig(
        outerHorizontalPadding: 16,
        sideFlex: 36,
        centerFlex: 28,
        gap: 20,
        sideMaxWidth: 330,
        centerMinWidth: 220,
        centerMaxWidth: 310,
        centerInnerHorizontalPadding: 6,
        centerAspectRatio: 0.57,
      );
    }
    return const _PaperdollResponsiveConfig(
      outerHorizontalPadding: 12,
      sideFlex: 37,
      centerFlex: 26,
      gap: 12,
      sideMaxWidth: 285,
      centerMinWidth: 190,
      centerMaxWidth: 260,
      centerInnerHorizontalPadding: 2,
      centerAspectRatio: 0.53,
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
  final double aspectRatio;

  const _CharacterImage({
    required this.renderUrl,
    required this.loading,
    required this.hasCharacter,
    required this.aspectRatio,
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
      final imageUrl = renderUrl!;
      final avatarLike =
          imageUrl.contains('avatar') && !imageUrl.contains('main-raw');
      final zoom = avatarLike ? 1.48 : 1.2;

      content = Align(
        alignment: Alignment.topCenter,
        child: Transform.scale(
          scale: zoom,
          alignment: Alignment.topCenter,
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.fitHeight,
            alignment: Alignment.topCenter,
            errorBuilder: (_, _, _) => _silhouette(),
          ),
        ),
      );
    } else {
      content = _silhouette();
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
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

class _PaperdollResponsiveConfig {
  final double outerHorizontalPadding;
  final int sideFlex;
  final int centerFlex;
  final double gap;
  final double sideMaxWidth;
  final double centerMinWidth;
  final double centerMaxWidth;
  final double centerInnerHorizontalPadding;
  final double centerAspectRatio;

  const _PaperdollResponsiveConfig({
    required this.outerHorizontalPadding,
    required this.sideFlex,
    required this.centerFlex,
    required this.gap,
    required this.sideMaxWidth,
    required this.centerMinWidth,
    required this.centerMaxWidth,
    required this.centerInnerHorizontalPadding,
    required this.centerAspectRatio,
  });
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
      // Solo rebuild cuando cambia este slot concreto
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
        return prevSlot != nextSlot;
      },
      builder: (context, state) {
        final slot = state is BuildDetailLoaded
            ? state.build.slots.firstWhere(
                (s) => s.slot == widget.wowSlot,
                orElse: () => BuildSlot(slot: widget.wowSlot),
              )
            : BuildSlot(slot: widget.wowSlot);
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
                    ? _leftContent(icon, hasItem, qualityColor, cubit, t, slot)
                    : _rightContent(
                        icon,
                        hasItem,
                        qualityColor,
                        cubit,
                        t,
                        slot,
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
        return _SlotSheetContent(slot: slot, cubit: cubit);
      },
    );
  }
}

class _SlotSheetContent extends StatelessWidget {
  final BuildSlot slot;
  final BuildDetailCubit cubit;
  const _SlotSheetContent({required this.slot, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final hasItem = slot.item != null;
    final qualityColor = hasItem
        ? WowTheme.getQualityColor(slot.item!.quality)
        : WowTheme.border;

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
                      _formatItemName(context, slot.enchantment!),
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
                      _formatItemName(context, e.value),
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
        mode: ItemSearchMode.item,
        region: cubit.searchRegion,
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
      builder: (_) => ItemSearchDialog(
        slot: slot.slot,
        title: t.slotSearchEnchantment,
        mode: ItemSearchMode.enchant,
        region: cubit.searchRegion,
      ),
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
      builder: (_) => ItemSearchDialog(
        slot: slot.slot,
        title: t.slotSearchGem,
        mode: ItemSearchMode.gem,
        region: cubit.searchRegion,
      ),
    );
    if (item != null) cubit.addGem(slot.slot, item);
  }

  String _formatItemName(BuildContext context, Item item) {
    return _itemNameForLocale(context, item);
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
