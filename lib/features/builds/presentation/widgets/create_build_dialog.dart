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

class _CreateBuildDialogState extends State<CreateBuildDialog> {
  final _nameController = TextEditingController();
  List<FavoriteCharacter> _favorites = [];
  FavoriteCharacter? _selectedCharacter;
  bool _loadingFavorites = true;

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
      characterClass: _selectedCharacter?.characterClass,
      characterSpec: _selectedCharacter?.specialization,
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
      content: Column(
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
          else if (_favorites.isEmpty)
            Text(
              t.buildsNoFavoritesYet,
              style: const TextStyle(
                color: WowTheme.textSecondary,
                fontSize: 13,
              ),
            )
          else
            DropdownButtonFormField<FavoriteCharacter>(
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
              onChanged: (value) => setState(() => _selectedCharacter = value),
            ),
        ],
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
