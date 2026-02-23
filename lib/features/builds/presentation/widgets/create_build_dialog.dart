import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/presentation/cubit/builds_cubit.dart';
import 'package:wow_companion/features/favorites/domain/favorites_repository.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class CreateBuildDialog extends StatefulWidget {
  const CreateBuildDialog({super.key});

  @override
  State<CreateBuildDialog> createState() => _CreateBuildDialogState();
}

// ─── Clases y specs disponibles ───────────────────────────────────────────────

// Todas las clases en orden alfabético
const _classes = [
  'Death Knight',
  'Demon Hunter',
  'Druid',
  'Evoker',
  'Hunter',
  'Mage',
  'Monk',
  'Paladin',
  'Priest',
  'Rogue',
  'Shaman',
  'Warlock',
  'Warrior',
];

const _specsByClass = <String, List<String>>{
  'Death Knight': ['Blood', 'Frost', 'Unholy'],
  'Demon Hunter': ['Devourer', 'Havoc', 'Vengeance'],
  'Druid':        ['Balance', 'Feral', 'Guardian', 'Restoration'],
  'Evoker':       ['Augmentation', 'Devastation', 'Preservation'],
  'Hunter':       ['Beast Mastery', 'Marksmanship', 'Survival'],
  'Mage':         ['Arcane', 'Fire', 'Frost'],
  'Monk':         ['Brewmaster', 'Mistweaver', 'Windwalker'],
  'Paladin':      ['Holy', 'Protection', 'Retribution'],
  'Priest':       ['Discipline', 'Holy', 'Shadow'],
  'Rogue':        ['Assassination', 'Outlaw', 'Subtlety'],
  'Shaman':       ['Elemental', 'Enhancement', 'Restoration'],
  'Warlock':      ['Affliction', 'Demonology', 'Destruction'],
  'Warrior':      ['Arms', 'Fury', 'Protection'],
};

class _CreateBuildDialogState extends State<CreateBuildDialog> {
  final _nameController = TextEditingController();
  List<FavoriteCharacter> _favorites = [];
  FavoriteCharacter? _selectedCharacter;
  bool _loadingFavorites = true;

  // Selección manual
  String? _manualClass;
  String? _manualSpec;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favs = await sl<FavoritesRepository>().getFavorites();
    if (mounted) {
      setState(() {
        _favorites = favs;
        _loadingFavorites = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? get _effectiveClass =>
      _selectedCharacter?.characterClass ?? _manualClass;

  String? get _effectiveSpec =>
      _selectedCharacter?.specialization ?? _manualSpec;

  void _onClassChanged(String? value) {
    setState(() {
      _manualClass = value;
      _manualSpec = null; // Reset spec al cambiar clase
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final build = Build(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      characterRefKey: _selectedCharacter?.key,
      characterRefDisplay: _selectedCharacter != null
          ? '${_selectedCharacter!.name} - ${_selectedCharacter!.realm}'
          : null,
      characterClass: _effectiveClass,
      characterSpec: _effectiveSpec,
      characterRace: _selectedCharacter?.race,
      createdAt: DateTime.now(),
      slots: Build.emptySlots,
    );

    context.read<BuildsCubit>().saveBuild(build);
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return AlertDialog(
      backgroundColor: WowTheme.surfaceDark,
      title: Text(
        t.buildsNewBuild,
        style: const TextStyle(color: WowTheme.primaryGold),
      ),
      content: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(color: WowTheme.textPrimary),
            decoration: InputDecoration(
              hintText: t.buildsBuildName,
              hintStyle: const TextStyle(color: WowTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingFavorites)
            const CircularProgressIndicator(color: WowTheme.primaryGold)
          else if (_favorites.isNotEmpty) ...[  
            DropdownButtonFormField<FavoriteCharacter?>(
              initialValue: _selectedCharacter,
              dropdownColor: WowTheme.surfaceDark,
              decoration: InputDecoration(
                hintText: t.buildsLinkCharacter,
                hintStyle: const TextStyle(color: WowTheme.textSecondary),
              ),
              style: const TextStyle(color: WowTheme.textPrimary),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(
                    t.buildsGenericBuild,
                    style: const TextStyle(color: WowTheme.textSecondary),
                  ),
                ),
                ..._favorites.map(
                  (f) => DropdownMenuItem(
                    value: f,
                    child: Text(
                      '${f.name} - ${f.realm}',
                      style: const TextStyle(color: WowTheme.textPrimary),
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() {
                _selectedCharacter = value;
                // Reset manual si vinculamos personaje
                if (value != null) { _manualClass = null; _manualSpec = null; }
              }),
            ),
            const SizedBox(height: 8),
          ],

          // Selector manual (solo si no hay personaje vinculado)
          if (_selectedCharacter == null) ...[  
            const Divider(color: WowTheme.textSecondary),
            const SizedBox(height: 4),
            const Text(
              'Class & Spec',
              style: TextStyle(color: WowTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _manualClass,
              dropdownColor: WowTheme.surfaceDark,
              decoration: const InputDecoration(
                hintText: 'Select class',
                hintStyle: TextStyle(color: WowTheme.textSecondary),
              ),
              style: const TextStyle(color: WowTheme.textPrimary),
              items: _classes
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: _onClassChanged,
            ),
            if (_manualClass != null) ...[  
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _manualSpec,
                dropdownColor: WowTheme.surfaceDark,
                decoration: const InputDecoration(
                  hintText: 'Select spec',
                  hintStyle: TextStyle(color: WowTheme.textSecondary),
                ),
                style: const TextStyle(color: WowTheme.textPrimary),
                items: (_specsByClass[_manualClass] ?? <String>[])
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => _manualSpec = value),
              ),
            ],
          ],
        ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text(
            t.buildsCancel,
            style: const TextStyle(color: WowTheme.textSecondary),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            t.buildsCreate,
            style: const TextStyle(color: WowTheme.primaryGold),
          ),
        ),
      ],
    );
  }
}
