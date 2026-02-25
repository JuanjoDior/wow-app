import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/l10n/wow_translations.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/core/wow/character_search_input.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/character/presentation/cubit/character_cubit.dart';
import 'package:wow_companion/features/favorites/domain/favorites_repository.dart';
import 'package:wow_companion/features/favorites/presentation/favorites_cubit.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';
import 'package:wow_companion/features/character/presentation/utils/primary_stat_display.dart';
import 'package:wow_companion/shared/widgets/common_widgets.dart';
import 'package:wow_companion/shared/widgets/item_tooltip_trigger.dart';

class CharacterPage extends StatefulWidget {
  final String region;
  final String realm;
  final String name;

  const CharacterPage({
    super.key,
    required this.region,
    required this.realm,
    required this.name,
  });

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> {
  late final CharacterCubit _cubit;
  late final FavoritesCubit _favCubit;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _cubit = sl<CharacterCubit>();
    _favCubit = sl<FavoritesCubit>();
    _cubit.fetchCharacter(
      region: widget.region,
      realm: widget.realm,
      name: widget.name,
    );
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final key = '${widget.region}-${widget.realm}-${widget.name}'.toLowerCase();
    final isFav = await _favCubit.isFavorite(key);
    if (mounted) {
      setState(() => _isFavorite = isFav);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  // Slots que van a la izquierda
  static const _leftSlots = [
    'HEAD',
    'NECK',
    'SHOULDER',
    'BACK',
    'CHEST',
    'WRIST',
    'MAIN_HAND',
    'OFF_HAND',
  ];

  // Slots que van a la derecha
  static const _rightSlots = [
    'HANDS',
    'WAIST',
    'LEGS',
    'FEET',
    'FINGER_1',
    'FINGER_2',
    'TRINKET_1',
    'TRINKET_2',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CharacterCubit, CharacterState>(
      bloc: _cubit,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              state is CharacterLoaded
                  ? state.character.name
                  : S.of(context)!.character,
            ),
            actions: [
              if (state is CharacterLoaded)
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.star : Icons.star_outline,
                    color: _isFavorite ? WowTheme.primaryGold : null,
                  ),
                  onPressed: () async {
                    final fav = FavoriteCharacter.fromCharacter(
                      state.character,
                    );
                    await _favCubit.toggleFavorite(fav);
                    _checkFavorite();
                  },
                ),
            ],
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(CharacterState state) {
    if (state is CharacterLoading) {
      return WowLoadingWidget(message: S.of(context)!.loadingCharacter);
    }
    if (state is CharacterError) {
      return WowErrorWidget(
        message: state.message,
        suggestion: state.suggestion,
        onRetry: () => _cubit.fetchCharacter(
          region: widget.region,
          realm: widget.realm,
          name: widget.name,
        ),
      );
    }
    if (state is CharacterLoaded) {
      return _buildProfile(state.character);
    }
    return const SizedBox.shrink();
  }

  Widget _buildProfile(Character char) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCharacterInfo(char),
          const SizedBox(height: 16),
          _buildEquipmentPanel(char),
          if (char.stats != null) ...[
            const SizedBox(height: 16),
            _buildStatsPanel(char.stats!),
          ],
          const SizedBox(height: 16),
          _buildProgressionCard(char),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCharacterInfo(Character char) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildSmallAvatar(char),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    char.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: WowTheme.getClassColor(char.characterClass),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${char.realm} · ${char.region}',
                    style: const TextStyle(color: WowTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      (S.of(context)!.level(char.level)),
                      WowTranslations.translateRace(char.race),
                      WowTranslations.translateClass(char.characterClass),
                      if (char.specialization != null)
                        WowTranslations.translateSpec(char.specialization!),
                      if (char.guild != null) '< ${char.guild} >',
                    ].join('  ·  '),
                    style: const TextStyle(
                      color: WowTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ExternalProfileButton(
                      tooltip: 'Raider.IO',
                      icon: Icons.auto_graph_rounded,
                      onTap: () =>
                          _openExternalProfile(_buildRaiderIoUrl(char)),
                    ),
                    const SizedBox(width: 8),
                    _ExternalProfileButton(
                      tooltip: 'World of Warcraft',
                      icon: Icons.public,
                      onTap: () =>
                          _openExternalProfile(_buildWowProfileUrl(char)),
                    ),
                  ],
                ),
                if (char.equippedItemLevel != null) ...[
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Text(
                        '${char.equippedItemLevel}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: WowTheme.primaryGold,
                        ),
                      ),
                      Text(
                        S.of(context)!.ilvl,
                        style: const TextStyle(
                          color: WowTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentPanel(Character char) {
    final leftItems = _leftSlots
        .map((s) => char.equipment.where((e) => e.slot == s).firstOrNull)
        .toList();
    final rightItems = _rightSlots
        .map((s) => char.equipment.where((e) => e.slot == s).firstOrNull)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < _leftSlots.length; i++)
                      _buildItemRow(
                        leftItems[i],
                        _leftSlots[i],
                        alignRight: true,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildCenterCharacter(char),
              ),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < _rightSlots.length; i++)
                      _buildItemRow(
                        rightItems[i],
                        _rightSlots[i],
                        alignRight: false,
                      ),
                  ],
                ),
              ),
            ],
          );
        }

        // Móvil
        return Column(
          children: [
            _buildCenterCharacter(char),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context)!.equipment,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: WowTheme.primaryGold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...char.equipment.map((item) => _buildItemRowMobile(item)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCenterCharacter(Character char) {
    final imageUrl = char.bestAvatarUrl;
    return SizedBox(
      width: 300,
      height: 440,
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Transform.scale(
                scale: 1.25, //Zoom al personaje no al contenedor
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.topCenter,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      color: WowTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: WowTheme.primaryGold,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      color: WowTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: ClassIcon(
                        className: char.characterClass,
                        size: 80,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: WowTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: ClassIcon(className: char.characterClass, size: 80),
              ),
            ),
    );
  }

  Widget _buildItemRow(
    EquippedItem? item,
    String slotName, {
    required bool alignRight,
  }) {
    if (item == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          height: 44,
          child: Align(
            alignment: alignRight
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Text(
              _formatSlotName(slotName),
              style: TextStyle(
                color: WowTheme.textSecondary.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    final icon = _buildItemIcon(item);
    final info = Expanded(
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: TextStyle(
              color: WowTheme.getQualityColor(item.quality),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${item.itemLevel}',
                style: TextStyle(
                  color: WowTheme.getQualityColor(
                    item.quality,
                  ).withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (item.enchantments.isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item.enchantments.first,
                    style: const TextStyle(color: Colors.green, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return ItemTooltipTrigger.forEquippedItem(
      equippedItem: item,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: SizedBox(
          height: 44,
          child: Row(
            children: alignRight
                ? [info, const SizedBox(width: 8), icon]
                : [icon, const SizedBox(width: 8), info],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRowMobile(EquippedItem item) {
    return ItemTooltipTrigger.forEquippedItem(
      equippedItem: item,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            _buildItemIcon(item),
            const SizedBox(width: 10),
            SizedBox(
              width: 70,
              child: Text(
                _formatSlotName(item.slot),
                style: const TextStyle(
                  color: WowTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: WowTheme.getQualityColor(item.quality),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.enchantments.isNotEmpty || item.gems.isNotEmpty)
                    Text(
                      [...item.enchantments, ...item.gems].join(' · '),
                      style: const TextStyle(color: Colors.green, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            QualityBadge(quality: item.quality, itemLevel: item.itemLevel),
          ],
        ),
      ),
    );
  }

  Widget _buildItemIcon(EquippedItem item) {
    final borderColor = WowTheme.getQualityColor(item.quality);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: item.iconUrl != null
            ? CachedNetworkImage(
                imageUrl: item.iconUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: WowTheme.surfaceLight),
                errorWidget: (context, url, error) => Container(
                  color: WowTheme.surfaceLight,
                  child: Icon(
                    Icons.shield_outlined,
                    color: borderColor,
                    size: 20,
                  ),
                ),
              )
            : Container(
                color: WowTheme.surfaceLight,
                child: Icon(
                  Icons.shield_outlined,
                  color: borderColor,
                  size: 20,
                ),
              ),
      ),
    );
  }

  Widget _buildStatsPanel(CharacterStats stats) {
    // Stat primaria real: la mayor entre Fuerza/Agilidad/Intelecto.
    final primary = determinePrimaryStatDisplay(stats);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recursos primarios: Salud + Maná/Energía/Furia
            if (stats.health != null || stats.mana != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    if (stats.health != null)
                      Expanded(
                        child: _StatTile(
                          icon: Icons.favorite,
                          iconColor: const Color(0xFF2ECC71),
                          label: 'Salud',
                          value: _formatLargeNumber(stats.health!),
                        ),
                      ),
                    if (stats.mana != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.water_drop,
                          iconColor: const Color(0xFF3498DB),
                          label: _powerLabel(stats.powerType),
                          value: _formatLargeNumber(stats.mana!),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Stats base: Agilidad/Fuerza/Int + Aguante
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.local_fire_department,
                    iconColor: WowTheme.primaryGold,
                    label: primary.label,
                    value: primary.value.toString(),
                  ),
                ),
                if (stats.stamina != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.shield_outlined,
                      iconColor: const Color(0xFFF39C12),
                      label: 'Aguante',
                      value: stats.stamina!.toString(),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: WowTheme.border),
            const SizedBox(height: 10),

            // Stats secundarias: Crítico, Celeridad, Maestría, Versatilidad
            Align(
              alignment: Alignment.center,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: [
                  if (stats.criticalStrike != null)
                    _SecondaryStatChip(
                      label: 'Golpe Crítico',
                      value: stats.criticalStrike!,
                      color: const Color(0xFFE74C3C),
                    ),
                  if (stats.haste != null)
                    _SecondaryStatChip(
                      label: 'Celeridad',
                      value: stats.haste!,
                      color: const Color(0xFF27AE60),
                    ),
                  if (stats.mastery != null)
                    _SecondaryStatChip(
                      label: 'Maestría',
                      value: stats.mastery!,
                      color: const Color(0xFF9B59B6),
                    ),
                  if (stats.versatility != null)
                    _SecondaryStatChip(
                      label: 'Versatilidad',
                      value: stats.versatility!,
                      color: const Color(0xFF2980B9),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLargeNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toString();
  }

  String _powerLabel(String? powerType) {
    return switch (powerType?.toUpperCase()) {
      'ENERGY' => 'Energía',
      'RAGE' => 'Furia',
      'RUNIC_POWER' => 'Poder Rúnico',
      'FOCUS' => 'Concentración',
      'MAELSTROM' => 'Maelstrom',
      'FURY' => 'Furia del DH',
      'PAIN' => 'Dolor',
      'ESSENCE' => 'Esencia',
      'ASTRAL_POWER' => 'Poder Astral',
      _ => 'Maná',
    };
  }

  String _buildRaiderIoUrl(Character char) {
    final region = Uri.encodeComponent(normalizeRegion(char.region));
    final realm = Uri.encodeComponent(normalizeRealmForRequest(char.realm));
    final name = Uri.encodeComponent(normalizeName(char.name));
    return 'https://raider.io/characters/$region/$realm/$name';
  }

  String _buildWowProfileUrl(Character char) {
    final locale = Localizations.localeOf(context).languageCode == 'es'
        ? 'es-es'
        : 'en-us';
    final region = Uri.encodeComponent(normalizeRegion(char.region));
    final realm = Uri.encodeComponent(normalizeRealmForRequest(char.realm));
    final name = Uri.encodeComponent(normalizeName(char.name));
    return 'https://worldofwarcraft.blizzard.com/$locale/character/$region/$realm/$name';
  }

  Future<void> _openExternalProfile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildProgressionCard(Character char) {
    final t = S.of(context)!;
    final mythicScore = char.mythicPlusScore ?? 0;
    final mythicProfile = char.mythicPlusProfile;
    final currentRaid = char.raidProgressionDetails.firstOrNull;
    final raidSummary = (char.raidProgression?.trim().isNotEmpty ?? false)
        ? char.raidProgression!.trim()
        : (currentRaid != null ? '0/${currentRaid.totalBosses}' : '0/0');

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        t.mythicPlus,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: WowTheme.primaryGold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mythicScore.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _getMythicPlusColor(mythicScore),
                        ),
                      ),
                      Text(
                        t.rating,
                        style: const TextStyle(
                          color: WowTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (mythicProfile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildRoleScores(mythicProfile),
                        ),
                    ],
                  ),
                ),
                Container(width: 1, height: 80, color: WowTheme.border),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        t.raid,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: WowTheme.primaryGold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        raidSummary,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: WowTheme.textPrimary,
                        ),
                      ),
                      Text(
                        currentRaid?.displayName ?? t.progression,
                        style: const TextStyle(
                          color: WowTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildRaidDetailCard(currentRaid),
        const SizedBox(height: 16),
        _buildBestRunsCard(char.mythicPlusProfile?.bestRuns ?? const []),
      ],
    );
  }

  Widget _buildRoleScores(MythicPlusProfile profile) {
    final roles = <MapEntry<String, double>>[];
    if (profile.scoreDps > 0) {
      roles.add(MapEntry('DPS', profile.scoreDps));
    }
    if (profile.scoreHealer > 0) {
      roles.add(MapEntry(S.of(context)!.healer, profile.scoreHealer));
    }
    if (profile.scoreTank > 0) {
      roles.add(MapEntry(S.of(context)!.tank, profile.scoreTank));
    }

    if (roles.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      children: roles.map((r) {
        return Text(
          '${r.key}: ${r.value.toStringAsFixed(0)}',
          style: TextStyle(
            color: _getMythicPlusColor(r.value),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBestRunsCard(List<MythicPlusRun> runs) {
    final t = S.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.bestMythicRuns,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: WowTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      t.dungeon,
                      style: const TextStyle(
                        color: WowTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      t.lvl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: WowTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      t.time,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: WowTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      t.score,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: WowTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: WowTheme.border),
            if (runs.isEmpty)
              Text(
                t.searchNoResults,
                style: const TextStyle(
                  color: WowTheme.textSecondary,
                  fontSize: 12,
                ),
              )
            else
              ...runs.map((run) => _buildRunRow(run)),
          ],
        ),
      ),
    );
  }

  Widget _buildRunRow(MythicPlusRun run) {
    final upgradeColor = run.inTime
        ? const Color(0xFF1EFF00)
        : const Color(0xFF9D9D9D);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: upgradeColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    run.shortName,
                    style: const TextStyle(
                      color: WowTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '+${run.mythicLevel}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: upgradeColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              run.formattedTime,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: run.inTime
                    ? WowTheme.textPrimary
                    : const Color(0xFF9D9D9D),
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              run.score.toStringAsFixed(1),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: _getMythicPlusColor(run.score * 10),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallAvatar(Character char) {
    final imageUrl = char.bestAvatarUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: WowTheme.getClassColor(char.characterClass),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Container(color: WowTheme.surfaceLight),
            errorWidget: (context, url, error) =>
                ClassIcon(className: char.characterClass, size: 56),
          ),
        ),
      );
    }
    return ClassIcon(className: char.characterClass, size: 56);
  }

  String _formatSlotName(String slot) {
    final t = S.of(context)!;
    return switch (slot) {
      'HEAD' => t.wowSlotHead,
      'NECK' => t.wowSlotNeck,
      'SHOULDER' => t.wowSlotShoulder,
      'BACK' => t.wowSlotBack,
      'CHEST' => t.wowSlotChest,
      'WRIST' => t.wowSlotWrist,
      'HANDS' => t.wowSlotHands,
      'WAIST' => t.wowSlotWaist,
      'LEGS' => t.wowSlotLegs,
      'FEET' => t.wowSlotFeet,
      'FINGER_1' => t.wowSlotFinger1,
      'FINGER_2' => t.wowSlotFinger2,
      'TRINKET_1' => t.wowSlotTrinket1,
      'TRINKET_2' => t.wowSlotTrinket2,
      'MAIN_HAND' => t.wowSlotMainHand,
      'OFF_HAND' => t.wowSlotOffHand,
      _ =>
        slot
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
            .join(' '),
    };
  }

  Color _getMythicPlusColor(double score) {
    if (score >= 3000) return const Color(0xFFFF8000);
    if (score >= 2500) return const Color(0xFFA335EE);
    if (score >= 2000) return const Color(0xFF0070DD);
    if (score >= 1500) return const Color(0xFF1EFF00);
    if (score >= 1000) return const Color(0xFFFFFFFF);
    return const Color(0xFF9D9D9D);
  }

  Widget _buildRaidDetailCard(RaidProgress? currentRaid) {
    final t = S.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.raidProgression,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: WowTheme.primaryGold,
                ),
              ),
              const SizedBox(height: 12),
              if (currentRaid == null)
                Text(
                  t.searchNoResults,
                  style: const TextStyle(
                    color: WowTheme.textSecondary,
                    fontSize: 12,
                  ),
                )
              else
                _buildRaidRow(currentRaid),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRaidRow(RaidProgress raid) {
    final t = S.of(context)!;
    final summary = raid.summary.trim().isNotEmpty
        ? raid.summary.trim()
        : '0/${raid.totalBosses}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                raid.displayName,
                style: const TextStyle(
                  color: WowTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                summary,
                style: TextStyle(
                  color: _getRaidDifficultyColor(raid.currentTier),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDifficultyBar(
            t.normal,
            raid.normalKilled,
            raid.totalBosses,
            const Color(0xFF1EFF00),
          ),
          const SizedBox(height: 4),
          _buildDifficultyBar(
            t.heroic,
            raid.heroicKilled,
            raid.totalBosses,
            const Color(0xFF0070DD),
          ),
          const SizedBox(height: 4),
          _buildDifficultyBar(
            t.mythic,
            raid.mythicKilled,
            raid.totalBosses,
            const Color(0xFFA335EE),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBar(String label, int killed, int total, Color color) {
    final progress = total > 0 ? killed / total : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: TextStyle(
              color: killed > 0 ? color : WowTheme.textSecondary,
              fontSize: 11,
              fontWeight: killed > 0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: WowTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            '$killed/$total',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: killed > 0 ? WowTheme.textPrimary : WowTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getRaidDifficultyColor(String tier) {
    switch (tier) {
      case 'Mythic':
        return const Color(0xFFA335EE);
      case 'Heroic':
        return const Color(0xFF0070DD);
      case 'Normal':
        return const Color(0xFF1EFF00);
      default:
        return WowTheme.textSecondary;
    }
  }
}

// ─── Widgets auxiliares de stats ─────────────────────────────────────────────

/// Tile de recurso primario (Salud, Maná, etc.) con icon + label + valor grande.
class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withValues(alpha: 0.25)),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: WowTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: WowTheme.textSecondary.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip de stat secundaria con porcentaje coloreado.
class _SecondaryStatChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _SecondaryStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${value.toStringAsFixed(1)}%',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: WowTheme.textSecondary.withValues(alpha: 0.65),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExternalProfileButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _ExternalProfileButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Ink(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: WowTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: WowTheme.border),
            ),
            child: Icon(icon, size: 18, color: WowTheme.primaryGold),
          ),
        ),
      ),
    );
  }
}
