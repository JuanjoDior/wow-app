import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/character/presentation/cubit/character_cubit.dart';
import 'package:wow_companion/features/favorites/domain/favorites_repository.dart';
import 'package:wow_companion/features/favorites/presentation/favorites_cubit.dart';
import 'package:wow_companion/shared/widgets/common_widgets.dart';
import 'package:wow_companion/shared/widgets/item_tooltip.dart';
import 'package:wow_companion/core/l10n/wow_translations.dart';

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
    if (mounted) setState(() => _isFavorite = isFav);
  }

  @override
  void dispose() {
    _cubit.close();
    _favCubit.close();
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
              state is CharacterLoaded ? state.character.name : 'Character',
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
      return const WowLoadingWidget(message: 'Loading character...');
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
          // Info del personaje (nombre, clase, guild, ilvl)
          _buildCharacterInfo(char),
          const SizedBox(height: 16),
          // Panel de equipo con personaje en el centro
          _buildEquipmentPanel(char),
          const SizedBox(height: 16),
          // M+ y Raid
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
            // Avatar pequeño
            _buildSmallAvatar(char),
            const SizedBox(width: 16),
            // Info
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
                      'Nivel ${char.level}',
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
            // iLvl
            if (char.equippedItemLevel != null)
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
                  const Text(
                    'iLvl',
                    style: TextStyle(
                      color: WowTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
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
          // Desktop: izquierda - centro - derecha
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna izquierda
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
              // Personaje central
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildCenterCharacter(char),
              ),
              // Columna derecha
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

        // Móvil: personaje arriba, lista debajo
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
                    const Text(
                      'Equipment',
                      style: TextStyle(
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
    return SizedBox(
      width: 300,
      height: 440,
      child: char.avatarUrl != null
          ? CachedNetworkImage(
              imageUrl: char.avatarUrl!,
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
                  child: ClassIcon(className: char.characterClass, size: 80),
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

  /// Item row para layout desktop (izquierda o derecha)
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

    return GestureDetector(
      onTapUp: (details) =>
          showItemTooltip(context, item, details.globalPosition),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
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
      ),
    );
  }

  /// Item row para layout móvil
  Widget _buildItemRowMobile(EquippedItem item) {
    return GestureDetector(
      onTapUp: (details) =>
          showItemTooltip(context, item, details.globalPosition),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
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
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                        ),
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
      ),
    );
  }

  /// Icono del item con borde de calidad
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

  Widget _buildProgressionCard(Character char) {
    if (char.mythicPlusScore == null && char.raidProgression == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // M+ Summary + Raid row
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (char.mythicPlusScore != null)
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Mythic+',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: WowTheme.primaryGold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          char.mythicPlusScore!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _getMythicPlusColor(char.mythicPlusScore!),
                          ),
                        ),
                        const Text(
                          'Rating',
                          style: TextStyle(
                            color: WowTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        // Role scores
                        if (char.mythicPlusProfile != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildRoleScores(char.mythicPlusProfile!),
                          ),
                      ],
                    ),
                  ),
                if (char.mythicPlusScore != null &&
                    char.raidProgression != null)
                  Container(width: 1, height: 80, color: WowTheme.border),
                if (char.raidProgression != null)
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Raid',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: WowTheme.primaryGold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          char.raidProgression!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: WowTheme.textPrimary,
                          ),
                        ),
                        if (char.raidProgressionDetails.isNotEmpty)
                          Text(
                            char.raidProgressionDetails.first.displayName,
                            style: const TextStyle(
                              color: WowTheme.textSecondary,
                              fontSize: 12,
                            ),
                          )
                        else
                          const Text(
                            'Progression',
                            style: TextStyle(
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
        // Raid detail
        if (char.raidProgressionDetails.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildRaidDetailCard(char.raidProgressionDetails),
        ],
        // Best M+ Runs
        if (char.mythicPlusProfile != null &&
            char.mythicPlusProfile!.bestRuns.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildBestRunsCard(char.mythicPlusProfile!.bestRuns),
        ],
      ],
    );
  }

  Widget _buildRoleScores(MythicPlusProfile profile) {
    final roles = <MapEntry<String, double>>[];
    if (profile.scoreDps > 0) {
      roles.add(MapEntry('DPS', profile.scoreDps));
    }
    if (profile.scoreHealer > 0) {
      roles.add(MapEntry('Healer', profile.scoreHealer));
    }
    if (profile.scoreTank > 0) {
      roles.add(MapEntry('Tank', profile.scoreTank));
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Best Mythic+ Runs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: WowTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 12),
            // Header
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Dungeon',
                      style: TextStyle(
                        color: WowTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      'Lvl',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: WowTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      'Time',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: WowTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      'Score',
                      textAlign: TextAlign.end,
                      style: TextStyle(
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
            // Runs
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
          // Dungeon name + upgrade indicator
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
          // Level + upgrade
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
          // Time
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
          // Score
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
    if (char.avatarUrl != null && char.avatarUrl!.isNotEmpty) {
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
            imageUrl: char.avatarUrl!,
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
    return slot
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  Color _getMythicPlusColor(double score) {
    if (score >= 3000) return const Color(0xFFFF8000);
    if (score >= 2500) return const Color(0xFFA335EE);
    if (score >= 2000) return const Color(0xFF0070DD);
    if (score >= 1500) return const Color(0xFF1EFF00);
    if (score >= 1000) return const Color(0xFFFFFFFF);
    return const Color(0xFF9D9D9D);
  }

  Widget _buildRaidDetailCard(List<RaidProgress> raids) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Raid Progression',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: WowTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 12),
            ...raids.map((raid) => _buildRaidRow(raid)),
          ],
        ),
      ),
    );
  }

  Widget _buildRaidRow(RaidProgress raid) {
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
                raid.summary,
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
            'Normal',
            raid.normalKilled,
            raid.totalBosses,
            const Color(0xFF1EFF00),
          ),
          const SizedBox(height: 4),
          _buildDifficultyBar(
            'Heroic',
            raid.heroicKilled,
            raid.totalBosses,
            const Color(0xFF0070DD),
          ),
          const SizedBox(height: 4),
          _buildDifficultyBar(
            'Mythic',
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
