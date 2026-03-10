import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/core/config/feature_flags.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/l10n/failure_localizer.dart';
import 'package:wow_companion/core/l10n/item_name_localizer.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/entities/build_gap_analysis.dart';
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
            characterSyncLoading: state.isCharacterSyncLoading,
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
  final bool characterSyncLoading;

  const _BuildDetailContent({
    required this.buildData,
    required this.gapAnalysis,
    required this.gapAnalysisLoading,
    required this.characterSyncLoading,
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
                      isCharacterSyncLoading: widget.characterSyncLoading,
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
        WowTranslations.translateSpec(
          buildData.characterSpec!,
          localeCode,
          className: buildData.characterClass,
        ),
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
  final bool isCharacterSyncLoading;

  const _BuildIntelligenceSection({
    required this.gapAnalysis,
    required this.loading,
    required this.hasCharacter,
    required this.isCharacterSyncLoading,
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
                Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed:
                          loading || !hasCharacter || isCharacterSyncLoading
                          ? null
                          : () => _runProgressSync(context),
                      icon: isCharacterSyncLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: WowTheme.primaryGold,
                              ),
                            )
                          : const Icon(
                              Icons.sync,
                              size: 16,
                              color: WowTheme.primaryGold,
                            ),
                      label: Text(
                        t.buildIntelligenceProgressSyncAction,
                        style: const TextStyle(
                          color: WowTheme.primaryGold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        size: 18,
                        color: WowTheme.textSecondary,
                      ),
                      tooltip: t.retry,
                      onPressed:
                          loading || !hasCharacter || isCharacterSyncLoading
                          ? null
                          : () => context
                                .read<BuildDetailCubit>()
                                .refreshGapAnalysis(),
                    ),
                  ],
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
                    final meta = _buildActionMeta(action);
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

  String? _buildActionMeta(BuildGapAction action) {
    final impact = action.estimatedImpact?.trim();
    if (impact == null || impact.isEmpty) return null;
    return impact;
  }

  Future<void> _runProgressSync(BuildContext context) async {
    final t = S.of(context)!;
    final cubit = context.read<BuildDetailCubit>();

    try {
      final result = await cubit.syncCharacterProgress(force: true);
      if (!context.mounted) return;

      final message = t.buildIntelligenceProgressSyncSuccess(
        result.itemsMatched,
        result.itemsTargeted,
        result.slotsUpdated,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_syncErrorMessage(t, error)),
          backgroundColor: WowTheme.accentRed,
        ),
      );
    }
  }

  String _syncErrorMessage(S t, Object error) {
    final raw = error.toString().trim();
    if (raw.contains(BuildDetailCubit.syncNoCharacterMessageCode)) {
      return t.buildIntelligenceSyncErrorNoCharacter;
    }

    final localized = localizeFailureMessage(t, raw);
    if (localized == raw) {
      return t.buildIntelligenceProgressSyncErrorGeneric;
    }
    return localized;
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
        final slotColumnHeight = _slotColumnHeight(cfg);
        final availableWidth =
            constraints.maxWidth - (cfg.outerHorizontalPadding * 2);
        final desiredWidth =
            (cfg.sideColumnWidth * 2) + cfg.centerWidth + (cfg.gap * 2);
        final layoutScale = availableWidth < desiredWidth
            ? availableWidth / desiredWidth
            : 1.0;
        final sideColumnWidth = cfg.sideColumnWidth * layoutScale;
        final centerWidth = cfg.centerWidth * layoutScale;
        final gap = cfg.gap * layoutScale;
        final layoutWidth = (sideColumnWidth * 2) + centerWidth + (gap * 2);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: cfg.outerHorizontalPadding),
          child: Center(
            child: SizedBox(
              width: layoutWidth,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    key: const Key('paperdoll-left-column'),
                    width: sideColumnWidth,
                    child: _buildSlotColumn(
                      slots: _leftSlots,
                      align: SlotAlign.left,
                      config: cfg,
                    ),
                  ),
                  SizedBox(width: gap),
                  SizedBox(
                    key: const Key('paperdoll-center-frame'),
                    width: centerWidth,
                    height: slotColumnHeight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: cfg.centerInnerHorizontalPadding,
                      ),
                      child: _CharacterImage(
                        renderUrl: renderUrl,
                        loading: loadingImage,
                        hasCharacter: hasCharacter,
                        imageScale: cfg.imageScale,
                      ),
                    ),
                  ),
                  SizedBox(width: gap),
                  SizedBox(
                    key: const Key('paperdoll-right-column'),
                    width: sideColumnWidth,
                    child: _buildSlotColumn(
                      slots: _rightSlots,
                      align: SlotAlign.right,
                      config: cfg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _slotColumnHeight(_PaperdollResponsiveConfig config) {
    final spacingCount = (_leftSlots.length - 1).clamp(0, _leftSlots.length);
    return (_leftSlots.length * config.slotHeight) +
        (spacingCount * config.slotSpacing);
  }

  Widget _buildSlotColumn({
    required List<WowSlot> slots,
    required SlotAlign align,
    required _PaperdollResponsiveConfig config,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < slots.length; i++) ...[
          _SlotButton(
            wowSlot: slots[i],
            align: align,
            slotHeight: config.slotHeight,
          ),
          if (i < slots.length - 1) SizedBox(height: config.slotSpacing),
        ],
      ],
    );
  }

  _PaperdollResponsiveConfig _paperdollConfigForWidth(double width) {
    if (width >= 1700) {
      return const _PaperdollResponsiveConfig(
        outerHorizontalPadding: 20,
        sideColumnWidth: 390,
        centerWidth: 364,
        gap: 28,
        centerInnerHorizontalPadding: 10,
        slotHeight: 74,
        slotSpacing: 4,
        imageScale: 1.12,
      );
    }
    if (width >= 1400) {
      return const _PaperdollResponsiveConfig(
        outerHorizontalPadding: 18,
        sideColumnWidth: 360,
        centerWidth: 332,
        gap: 24,
        centerInnerHorizontalPadding: 8,
        slotHeight: 72,
        slotSpacing: 4,
        imageScale: 1.14,
      );
    }
    if (width >= 1150) {
      return const _PaperdollResponsiveConfig(
        outerHorizontalPadding: 16,
        sideColumnWidth: 330,
        centerWidth: 304,
        gap: 20,
        centerInnerHorizontalPadding: 6,
        slotHeight: 70,
        slotSpacing: 4,
        imageScale: 1.16,
      );
    }
    return const _PaperdollResponsiveConfig(
      outerHorizontalPadding: 12,
      sideColumnWidth: 285,
      centerWidth: 252,
      gap: 12,
      centerInnerHorizontalPadding: 2,
      slotHeight: 66,
      slotSpacing: 3,
      imageScale: 1.18,
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
  final double imageScale;

  const _CharacterImage({
    required this.renderUrl,
    required this.loading,
    required this.hasCharacter,
    required this.imageScale,
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
      final zoom = avatarLike ? imageScale + 0.24 : imageScale;

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

    return Container(
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
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: content),
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
  final double sideColumnWidth;
  final double centerWidth;
  final double gap;
  final double centerInnerHorizontalPadding;
  final double slotHeight;
  final double slotSpacing;
  final double imageScale;

  const _PaperdollResponsiveConfig({
    required this.outerHorizontalPadding,
    required this.sideColumnWidth,
    required this.centerWidth,
    required this.gap,
    required this.centerInnerHorizontalPadding,
    required this.slotHeight,
    required this.slotSpacing,
    required this.imageScale,
  });
}

// ─── Slot button ──────────────────────────────────────────────────────────────
enum SlotAlign { left, right }

class _SlotButton extends StatefulWidget {
  final WowSlot wowSlot;
  final SlotAlign align;
  final double slotHeight;

  const _SlotButton({
    required this.wowSlot,
    required this.align,
    this.slotHeight = 82,
  });

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

        final t = S.of(context)!;
        return GestureDetector(
          onTap: () {
            if (_checkboxJustTapped) {
              _checkboxJustTapped = false;
              return;
            }
            _openSlotSheet(context, cubit, slot);
          },
          child: SizedBox(
            height: widget.slotHeight,
            child: AnimatedContainer(
              key: Key('paperdoll-slot-${slot.slot.name}'),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final density = _SlotDensity.forSlot(
                    width: constraints.maxWidth,
                    slotHeight: widget.slotHeight,
                  );

                  final adaptedIcon = hasItem && slot.item!.iconUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            slot.item!.iconUrl!,
                            width: density.imageSize,
                            height: density.imageSize,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              _slotIcon(slot.slot),
                              size: density.iconSize,
                              color: qualityColor,
                            ),
                          ),
                        )
                      : Icon(
                          _slotIcon(slot.slot),
                          size: density.iconSize,
                          color: hasItem
                              ? qualityColor
                              : WowTheme.textSecondary.withValues(alpha: 0.5),
                        );

                  return Padding(
                    padding: density.padding,
                    child: align == SlotAlign.left
                        ? _leftContent(
                            adaptedIcon,
                            hasItem,
                            qualityColor,
                            cubit,
                            t,
                            slot,
                            density,
                          )
                        : _rightContent(
                            adaptedIcon,
                            hasItem,
                            qualityColor,
                            cubit,
                            t,
                            slot,
                            density,
                          ),
                  );
                },
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
    required double size,
    Color? borderColor,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Checkbox(
        value: value,
        activeColor: color,
        checkColor: WowTheme.darkBackground,
        side: BorderSide(
          color: (borderColor ?? color).withValues(alpha: 0.8),
          width: size <= 16 ? 1 : 1.2,
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
    _SlotDensity density,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: density.iconBoxWidth,
          child: Center(child: icon),
        ),
        SizedBox(width: density.contentGap),
        Expanded(
          child: _slotText(
            hasItem,
            qualityColor,
            TextAlign.left,
            cubit,
            t,
            slot,
            density,
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
    _SlotDensity density,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _slotText(
            hasItem,
            qualityColor,
            TextAlign.right,
            cubit,
            t,
            slot,
            density,
          ),
        ),
        SizedBox(width: density.contentGap),
        SizedBox(
          width: density.iconBoxWidth,
          child: Center(child: icon),
        ),
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
    _SlotDensity density,
  ) {
    final localeCode = Localizations.localeOf(context).languageCode;
    if (!hasItem) {
      return Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: align == TextAlign.left
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Text(
            slot.slot.localizedName(t),
            textAlign: align,
            style: TextStyle(
              color: WowTheme.textSecondary.withValues(alpha: 0.75),
              fontSize: density.slotLabelFontSize,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            t.slotAssignItem,
            textAlign: align,
            style: TextStyle(
              color: WowTheme.textSecondary.withValues(alpha: 0.55),
              fontSize: density.secondaryFontSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: align == TextAlign.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          slot.slot.localizedName(t),
          textAlign: align,
          style: TextStyle(
            color: WowTheme.textSecondary.withValues(alpha: 0.6),
            fontSize: density.slotLabelFontSize,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: density.nameTopGap),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (align == TextAlign.right) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: _miniCheckbox(
                    value: slot.obtained,
                    color: WowTheme.primaryGold,
                    onToggle: () => cubit.toggleObtained(slot.slot),
                    borderColor: WowTheme.textSecondary,
                    size: density.checkboxSize,
                  ),
                ),
                SizedBox(width: density.checkboxGap),
              ],
              Expanded(
                child: Align(
                  alignment: align == TextAlign.left
                      ? Alignment.topLeft
                      : Alignment.topRight,
                  child: Tooltip(
                    message: slot.item!.primaryNameForLanguage(localeCode),
                    child: Text(
                      key: Key('paperdoll-slot-item-name-${slot.slot.name}'),
                      slot.item!.primaryNameForLanguage(localeCode),
                      textAlign: align,
                      style: TextStyle(
                        color: qualityColor,
                        fontSize: density.itemNameFontSize,
                        fontWeight: FontWeight.w600,
                        height: density.itemNameLineHeight,
                      ),
                      maxLines: density.itemNameMaxLines,
                      softWrap: density.itemNameMaxLines > 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              if (align == TextAlign.left) ...[
                SizedBox(width: density.checkboxGap),
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: _miniCheckbox(
                    value: slot.obtained,
                    color: WowTheme.primaryGold,
                    onToggle: () => cubit.toggleObtained(slot.slot),
                    borderColor: WowTheme.textSecondary,
                    size: density.checkboxSize,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: density.footerTopGap),
        _slotFooter(align, cubit, t, slot, density),
      ],
    );
  }

  Widget _slotFooter(
    TextAlign align,
    BuildDetailCubit cubit,
    S t,
    BuildSlot slot,
    _SlotDensity density,
  ) {
    final info = Text(
      slot.item!.level != null ? '${t.ilvl} ${slot.item!.level}' : '',
      textAlign: align,
      style: TextStyle(
        color: WowTheme.textSecondary.withValues(alpha: 0.72),
        fontSize: density.footerFontSize,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final statusTrail = _statusTrail(cubit, slot, density);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: align == TextAlign.left
          ? [
              Expanded(child: info),
              if (statusTrail != null) ...[
                SizedBox(width: density.footerGap),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: statusTrail,
                  ),
                ),
              ],
            ]
          : [
              if (statusTrail != null) ...[
                Flexible(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: statusTrail,
                  ),
                ),
                SizedBox(width: density.footerGap),
              ],
              Expanded(child: info),
            ],
    );
  }

  Widget? _statusTrail(
    BuildDetailCubit cubit,
    BuildSlot slot,
    _SlotDensity density,
  ) {
    final toggles = <Widget>[
      if (slot.enchantment != null)
        _statusToggle(
          tooltip: slot.enchantment!.primaryNameForLanguage(
            Localizations.localeOf(context).languageCode,
          ),
          color: WowTheme.accentBlue,
          obtained: slot.enchantmentObtained,
          onToggle: () => cubit.toggleEnchantmentObtained(slot.slot),
          density: density,
          child: const Icon(Icons.auto_fix_high),
        ),
      ...slot.gems.asMap().entries.map((entry) {
        final index = entry.key;
        final gem = entry.value;
        final gemObtained = index < slot.gemsObtained.length
            ? slot.gemsObtained[index]
            : false;
        return _statusToggle(
          tooltip: gem.primaryNameForLanguage(
            Localizations.localeOf(context).languageCode,
          ),
          color: WowTheme.primaryGold,
          obtained: gemObtained,
          onToggle: () => cubit.toggleGemObtained(slot.slot, index),
          density: density,
          child: const Icon(Icons.diamond),
        );
      }),
    ];

    if (toggles.isEmpty) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < toggles.length; i++) ...[
          if (i > 0) SizedBox(width: density.statusSpacing),
          toggles[i],
        ],
      ],
    );
  }

  Widget _statusToggle({
    required String tooltip,
    required Color color,
    required bool obtained,
    required VoidCallback onToggle,
    required _SlotDensity density,
    required Widget child,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          _checkboxJustTapped = true;
          Future.microtask(() => _checkboxJustTapped = false);
          onToggle();
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: BoxConstraints(
            minWidth: density.statusSize,
            minHeight: density.statusSize,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: density.statusHorizontalPadding,
            vertical: density.statusVerticalPadding,
          ),
          decoration: BoxDecoration(
            color: obtained
                ? color.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: obtained
                  ? color.withValues(alpha: 0.9)
                  : color.withValues(alpha: 0.45),
            ),
          ),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: obtained ? color : color.withValues(alpha: 0.75),
                size: density.statusContentSize,
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: obtained ? color : color.withValues(alpha: 0.75),
                  fontSize: density.statusContentSize,
                  fontWeight: FontWeight.w700,
                ),
                child: child,
              ),
            ),
          ),
        ),
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

class _SlotDensity {
  final EdgeInsets padding;
  final double iconBoxWidth;
  final double iconSize;
  final double imageSize;
  final double contentGap;
  final double checkboxSize;
  final double checkboxGap;
  final double slotLabelFontSize;
  final double secondaryFontSize;
  final double itemNameFontSize;
  final double itemNameLineHeight;
  final int itemNameMaxLines;
  final double nameTopGap;
  final double footerTopGap;
  final double footerFontSize;
  final double footerGap;
  final double statusSpacing;
  final double statusSize;
  final double statusHorizontalPadding;
  final double statusVerticalPadding;
  final double statusContentSize;

  const _SlotDensity({
    required this.padding,
    required this.iconBoxWidth,
    required this.iconSize,
    required this.imageSize,
    required this.contentGap,
    required this.checkboxSize,
    required this.checkboxGap,
    required this.slotLabelFontSize,
    required this.secondaryFontSize,
    required this.itemNameFontSize,
    required this.itemNameLineHeight,
    required this.itemNameMaxLines,
    required this.nameTopGap,
    required this.footerTopGap,
    required this.footerFontSize,
    required this.footerGap,
    required this.statusSpacing,
    required this.statusSize,
    required this.statusHorizontalPadding,
    required this.statusVerticalPadding,
    required this.statusContentSize,
  });

  factory _SlotDensity.forSlot({
    required double width,
    required double slotHeight,
  }) {
    final compact = width < 340 || slotHeight <= 70;
    final ultraCompact = width < 290 || slotHeight <= 66;

    if (ultraCompact) {
      return const _SlotDensity(
        padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
        iconBoxWidth: 28,
        iconSize: 18,
        imageSize: 26,
        contentGap: 6,
        checkboxSize: 16,
        checkboxGap: 3,
        slotLabelFontSize: 9,
        secondaryFontSize: 9,
        itemNameFontSize: 11,
        itemNameLineHeight: 1.05,
        itemNameMaxLines: 1,
        nameTopGap: 1,
        footerTopGap: 1,
        footerFontSize: 8,
        footerGap: 6,
        statusSpacing: 3,
        statusSize: 16,
        statusHorizontalPadding: 2.5,
        statusVerticalPadding: 1,
        statusContentSize: 9,
      );
    }

    if (compact) {
      return const _SlotDensity(
        padding: EdgeInsets.fromLTRB(6, 5, 6, 5),
        iconBoxWidth: 30,
        iconSize: 19,
        imageSize: 28,
        contentGap: 7,
        checkboxSize: 17,
        checkboxGap: 4,
        slotLabelFontSize: 9,
        secondaryFontSize: 9,
        itemNameFontSize: 11.5,
        itemNameLineHeight: 1.08,
        itemNameMaxLines: 1,
        nameTopGap: 1,
        footerTopGap: 1,
        footerFontSize: 8.5,
        footerGap: 6,
        statusSpacing: 3,
        statusSize: 17,
        statusHorizontalPadding: 2.5,
        statusVerticalPadding: 1,
        statusContentSize: 9,
      );
    }

    return const _SlotDensity(
      padding: EdgeInsets.fromLTRB(6, 6, 6, 6),
      iconBoxWidth: 34,
      iconSize: 20,
      imageSize: 30,
      contentGap: 8,
      checkboxSize: 18,
      checkboxGap: 4,
      slotLabelFontSize: 10,
      secondaryFontSize: 10,
      itemNameFontSize: 12,
      itemNameLineHeight: 1.12,
      itemNameMaxLines: 2,
      nameTopGap: 2,
      footerTopGap: 1,
      footerFontSize: 9,
      footerGap: 8,
      statusSpacing: 4,
      statusSize: 18,
      statusHorizontalPadding: 3,
      statusVerticalPadding: 1.5,
      statusContentSize: 10,
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
                          _formatItemName(context, slot.item!),
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
    return item.primaryNameForLanguage(
      Localizations.localeOf(context).languageCode,
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
