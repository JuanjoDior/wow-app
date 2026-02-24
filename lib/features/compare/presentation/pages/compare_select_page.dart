import 'package:flutter/material.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:wow_companion/core/wow/character_search_input.dart';
import 'package:wow_companion/core/wow/supported_regions.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class CompareSelectPage extends StatefulWidget {
  const CompareSelectPage({super.key});

  @override
  State<CompareSelectPage> createState() => _CompareSelectPageState();
}

class _CompareSelectPageState extends State<CompareSelectPage> {
  // Character 1
  final _region1 = TextEditingController(text: supportedRegionCodes.first);
  final _realm1 = TextEditingController();
  final _name1 = TextEditingController();

  // Character 2
  final _region2 = TextEditingController(text: supportedRegionCodes.first);
  final _realm2 = TextEditingController();
  final _name2 = TextEditingController();

  bool get _canCompare =>
      _realm1.text.trim().isNotEmpty &&
      _name1.text.trim().isNotEmpty &&
      _realm2.text.trim().isNotEmpty &&
      _name2.text.trim().isNotEmpty;

  @override
  void dispose() {
    _region1.dispose();
    _realm1.dispose();
    _name1.dispose();
    _region2.dispose();
    _realm2.dispose();
    _name2.dispose();
    super.dispose();
  }

  void _startCompare() {
    if (!_canCompare) return;
    context.push(
      buildCompareRoute(
        region1: _region1.text,
        realm1: _realm1.text,
        name1: _name1.text,
        region2: _region2.text,
        realm2: _realm2.text,
        name2: _name2.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.compareCharacters)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                _buildCharacterForm(
                  title: t.character1,
                  regionCtrl: _region1,
                  realmCtrl: _realm1,
                  nameCtrl: _name1,
                  color: const Color(0xFF0070DD),
                ),
                const SizedBox(height: 12),
                const Icon(
                  Icons.compare_arrows,
                  color: WowTheme.primaryGold,
                  size: 36,
                ),
                const SizedBox(height: 12),
                _buildCharacterForm(
                  title: t.character2,
                  regionCtrl: _region2,
                  realmCtrl: _realm2,
                  nameCtrl: _name2,
                  color: const Color(0xFFA335EE),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _canCompare ? _startCompare : null,
                    icon: const Icon(Icons.compare_arrows),
                    label: Text(
                      t.compare,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WowTheme.primaryGold,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: WowTheme.surfaceLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterForm({
    required String title,
    required TextEditingController regionCtrl,
    required TextEditingController realmCtrl,
    required TextEditingController nameCtrl,
    required Color color,
  }) {
    final t = S.of(context)!;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: regionCtrl.text,
              decoration: InputDecoration(
                labelText: t.region,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              dropdownColor: WowTheme.surfaceDark,
              items: supportedRegionCodes
                  .map(
                    (regionCode) => DropdownMenuItem(
                      value: regionCode,
                      child: Text(
                        '${regionFlag(regionCode)} ${regionLabel(regionCode, t)}',
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (v) => setState(
                () => regionCtrl.text = v ?? supportedRegionCodes.first,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: realmCtrl,
              decoration: InputDecoration(
                labelText: t.realm,
                hintText: 'e.g. sanguino',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: t.characterName,
                hintText: 'e.g. iidrexii',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}
