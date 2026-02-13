import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/presentation/cubit/builds_cubit.dart';
import 'package:wow_companion/features/favorites/domain/favorites_repository.dart';
import 'package:wow_companion/features/favorites/presentation/favorites_cubit.dart';

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
      createdAt: DateTime.now(),
      slots: Build.emptySlots,
    );

    context.read<BuildsCubit>().saveBuild(build);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: WowTheme.surfaceDark,
      title: const Text(
        'New Build',
        style: TextStyle(color: WowTheme.primaryGold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(color: WowTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Build name (e.g. Rogue M+ Assassination)',
              hintStyle: TextStyle(color: WowTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingFavorites)
            const CircularProgressIndicator(color: WowTheme.primaryGold)
          else if (_favorites.isEmpty)
            const Text(
              'No favorites saved yet',
              style: TextStyle(color: WowTheme.textSecondary, fontSize: 13),
            )
          else
            DropdownButtonFormField<FavoriteCharacter>(
              value: _selectedCharacter,
              dropdownColor: WowTheme.surfaceDark,
              decoration: const InputDecoration(
                hintText: 'Link to character (optional)',
                hintStyle: TextStyle(color: WowTheme.textSecondary),
              ),
              style: const TextStyle(color: WowTheme.textPrimary),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text(
                    'Generic build (no character)',
                    style: TextStyle(color: WowTheme.textSecondary),
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
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: WowTheme.textSecondary),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text(
            'Create',
            style: TextStyle(color: WowTheme.primaryGold),
          ),
        ),
      ],
    );
  }
}
