import 'package:flutter/material.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/character/domain/repositories/character_repository.dart';
import 'package:wow_companion/shared/widgets/common_widgets.dart';

class CompareResultPage extends StatefulWidget {
  final String region1, realm1, name1;
  final String region2, realm2, name2;

  const CompareResultPage({
    super.key,
    required this.region1,
    required this.realm1,
    required this.name1,
    required this.region2,
    required this.realm2,
    required this.name2,
  });

  @override
  State<CompareResultPage> createState() => _CompareResultPageState();
}

class _CompareResultPageState extends State<CompareResultPage> {
  Character? _char1;
  Character? _char2;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBoth();
  }

  Future<void> _loadBoth() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = sl<CharacterRepository>();
      final results = await Future.wait([
        repo.getCharacter(
          region: widget.region1,
          realm: widget.realm1,
          name: widget.name1,
        ),
        repo.getCharacter(
          region: widget.region2,
          realm: widget.realm2,
          name: widget.name2,
        ),
      ]);

      Character? c1;
      Character? c2;
      String? err;

      results[0].fold((f) => err = 'Character 1: ${f.message}', (c) => c1 = c);
      results[1].fold(
        (f) => err = '${err != null ? "$err\n" : ""}Character 2: ${f.message}',
        (c) => c2 = c,
      );

      if (mounted) {
        setState(() {
          _char1 = c1;
          _char2 = c2;
          _error = err;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unexpected error: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comparison')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const WowLoadingWidget(message: 'Loading both characters...');
    }
    if (_error != null && (_char1 == null || _char2 == null)) {
      return WowErrorWidget(
        message: _error!,
        suggestion: 'Check that both names are correct.',
        onRetry: _loadBoth,
      );
    }
    if (_char1 == null || _char2 == null) {
      return const WowErrorWidget(message: 'Could not load characters.');
    }
    return _buildComparison(_char1!, _char2!);
  }

  Widget _buildComparison(Character c1, Character c2) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header: both names
          _buildHeader(c1, c2),
          const SizedBox(height: 16),
          // Stats comparison rows
          _buildStatCard(c1, c2),
          const SizedBox(height: 16),
          // Equipment comparison
          _buildEquipmentCompare(c1, c2),
        ],
      ),
    );
  }

  Widget _buildHeader(Character c1, Character c2) {
    return Row(
      children: [
        Expanded(child: _buildCharHeader(c1, const Color(0xFF0070DD))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'VS',
            style: TextStyle(
              color: WowTheme.primaryGold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(child: _buildCharHeader(c2, const Color(0xFFA335EE))),
      ],
    );
  }

  Widget _buildCharHeader(Character c, Color accentColor) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              c.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: WowTheme.getClassColor(c.characterClass),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${c.realm} · ${c.region}',
              style: const TextStyle(
                color: WowTheme.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '${c.specialization ?? c.characterClass} · ${c.race}',
              style: const TextStyle(
                color: WowTheme.textSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(Character c1, Character c2) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCompareRow(
              'Item Level',
              c1.equippedItemLevel?.toDouble(),
              c2.equippedItemLevel?.toDouble(),
              higherIsBetter: true,
            ),
            const Divider(height: 20, color: WowTheme.border),
            _buildCompareRow(
              'M+ Rating',
              c1.mythicPlusScore,
              c2.mythicPlusScore,
              higherIsBetter: true,
            ),
            if (c1.mythicPlusProfile != null ||
                c2.mythicPlusProfile != null) ...[
              const Divider(height: 20, color: WowTheme.border),
              _buildCompareRow(
                'M+ DPS Score',
                c1.mythicPlusProfile?.scoreDps,
                c2.mythicPlusProfile?.scoreDps,
                higherIsBetter: true,
              ),
              const SizedBox(height: 8),
              _buildCompareRow(
                'M+ Healer Score',
                c1.mythicPlusProfile?.scoreHealer,
                c2.mythicPlusProfile?.scoreHealer,
                higherIsBetter: true,
              ),
              const SizedBox(height: 8),
              _buildCompareRow(
                'M+ Tank Score',
                c1.mythicPlusProfile?.scoreTank,
                c2.mythicPlusProfile?.scoreTank,
                higherIsBetter: true,
              ),
            ],
            if (c1.raidProgressionDetails.isNotEmpty ||
                c2.raidProgressionDetails.isNotEmpty) ...[
              const Divider(height: 20, color: WowTheme.border),
              _buildRaidCompare(c1, c2),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompareRow(
    String label,
    double? val1,
    double? val2, {
    required bool higherIsBetter,
  }) {
    final v1 = val1 ?? 0;
    final v2 = val2 ?? 0;

    Color color1 = WowTheme.textPrimary;
    Color color2 = WowTheme.textPrimary;

    if (v1 != v2 && (val1 != null || val2 != null)) {
      final winner1 = higherIsBetter ? v1 > v2 : v1 < v2;
      color1 = winner1 ? const Color(0xFF1EFF00) : const Color(0xFFFF4444);
      color2 = winner1 ? const Color(0xFFFF4444) : const Color(0xFF1EFF00);
    }

    String format(double? v) {
      if (v == null || v == 0) return '—';
      return v == v.roundToDouble()
          ? v.toInt().toString()
          : v.toStringAsFixed(1);
    }

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            format(val1),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color1,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: WowTheme.textSecondary, fontSize: 13),
          ),
        ),
        SizedBox(
          width: 80,
          child: Text(
            format(val2),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color2,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRaidCompare(Character c1, Character c2) {
    // Use first raid from either character as reference
    final raid1 = c1.raidProgressionDetails.isNotEmpty
        ? c1.raidProgressionDetails.first
        : null;
    final raid2 = c2.raidProgressionDetails.isNotEmpty
        ? c2.raidProgressionDetails.first
        : null;

    final raidName = raid1?.displayName ?? raid2?.displayName ?? 'Raid';

    return Column(
      children: [
        Text(
          raidName,
          style: const TextStyle(
            color: WowTheme.primaryGold,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildCompareRow(
          'Normal',
          raid1?.normalKilled.toDouble(),
          raid2?.normalKilled.toDouble(),
          higherIsBetter: true,
        ),
        const SizedBox(height: 4),
        _buildCompareRow(
          'Heroic',
          raid1?.heroicKilled.toDouble(),
          raid2?.heroicKilled.toDouble(),
          higherIsBetter: true,
        ),
        const SizedBox(height: 4),
        _buildCompareRow(
          'Mythic',
          raid1?.mythicKilled.toDouble(),
          raid2?.mythicKilled.toDouble(),
          higherIsBetter: true,
        ),
      ],
    );
  }

  Widget _buildEquipmentCompare(Character c1, Character c2) {
    final allSlots = [
      'HEAD',
      'NECK',
      'SHOULDER',
      'BACK',
      'CHEST',
      'WRIST',
      'HANDS',
      'WAIST',
      'LEGS',
      'FEET',
      'FINGER_1',
      'FINGER_2',
      'TRINKET_1',
      'TRINKET_2',
      'MAIN_HAND',
      'OFF_HAND',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Equipment Comparison',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: WowTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 12),
            // Header
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Char 1',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF0070DD),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Slot',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: WowTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Char 2',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFA335EE),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: WowTheme.border),
            ...allSlots.map((slot) {
              final item1 = c1.equipment
                  .where((e) => e.slot == slot)
                  .firstOrNull;
              final item2 = c2.equipment
                  .where((e) => e.slot == slot)
                  .firstOrNull;
              return _buildEquipRow(slot, item1, item2);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipRow(String slot, EquippedItem? item1, EquippedItem? item2) {
    final ilvl1 = item1?.itemLevel ?? 0;
    final ilvl2 = item2?.itemLevel ?? 0;

    Color ilvlColor1 = WowTheme.textPrimary;
    Color ilvlColor2 = WowTheme.textPrimary;
    if (ilvl1 != ilvl2 && (item1 != null || item2 != null)) {
      ilvlColor1 = ilvl1 > ilvl2
          ? const Color(0xFF1EFF00)
          : const Color(0xFFFF4444);
      ilvlColor2 = ilvl2 > ilvl1
          ? const Color(0xFF1EFF00)
          : const Color(0xFFFF4444);
    }

    String slotLabel = slot
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) =>
              w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase(),
        )
        .join(' ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Char 1 item
          Expanded(
            child: item1 != null
                ? Text(
                    '${item1.name} (${item1.itemLevel})',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ilvlColor1, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  )
                : const Text(
                    '—',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: WowTheme.textSecondary),
                  ),
          ),
          // Slot name
          SizedBox(
            width: 80,
            child: Text(
              slotLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WowTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Char 2 item
          Expanded(
            child: item2 != null
                ? Text(
                    '${item2.name} (${item2.itemLevel})',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ilvlColor2, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  )
                : const Text(
                    '—',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: WowTheme.textSecondary),
                  ),
          ),
        ],
      ),
    );
  }
}
