import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/l10n/wow_translations.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/core/wow/wow_class_specs.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  List<FavoriteCharacter> _favorites = [];
  FavoriteCharacter? _selectedCharacter;
  String? _manualClass;
  String? _manualSpec;
  String? _linkedSpec;
  bool _loadingFavorites = true;
  String? _favoritesLoadError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _hasLinkedCharacter => _selectedCharacter != null;

  String? get _effectiveClass => _hasLinkedCharacter
      ? canonicalWowClass(_selectedCharacter!.characterClass)
      : canonicalWowClass(_manualClass);

  String? get _effectiveSpec => _hasLinkedCharacter
      ? canonicalWowSpec(_effectiveClass, _linkedSpec)
      : canonicalWowSpec(_effectiveClass, _manualSpec);

  List<String> get _effectiveSpecs => specsForClass(_effectiveClass);

  Future<void> _loadFavorites() async {
    try {
      final favs = await sl<FavoritesRepository>().getFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = favs;
        _loadingFavorites = false;
        _favoritesLoadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _favorites = const [];
        _loadingFavorites = false;
        _favoritesLoadError = 'load_error';
      });
    }
  }

  void _onClassChanged(String? value) {
    setState(() {
      _manualClass = canonicalWowClass(value);
      _manualSpec = canonicalWowSpec(_manualClass, _manualSpec);
    });
    _formKey.currentState?.validate();
  }

  void _onCharacterChanged(FavoriteCharacter? value) {
    setState(() {
      _selectedCharacter = value;
      _linkedSpec = value != null ? _defaultLinkedSpec(value) : null;
    });
    _formKey.currentState?.validate();
  }

  String? _defaultLinkedSpec(FavoriteCharacter character) {
    return canonicalWowSpec(character.characterClass, character.specialization);
  }

  String? _validateName(String? value) {
    final t = S.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return t.buildsNameRequired;
    }
    return null;
  }

  String? _validateManualClass(String? value) {
    final t = S.of(context)!;
    if (_hasLinkedCharacter) return null;
    if (value == null || value.trim().isEmpty) {
      return t.buildsClassRequired;
    }
    return null;
  }

  String? _validateEffectiveSpec(String? value) {
    final t = S.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return t.buildsSpecRequired;
    }
    final className = _effectiveClass;
    if (className == null || !isValidSpecForClass(className, value)) {
      return t.buildsSpecRequired;
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final name = _nameController.text.trim();
    final build = Build(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      characterRefKey: _selectedCharacter?.key,
      characterRefDisplay: _selectedCharacter != null
          ? '${_selectedCharacter!.name} - ${_selectedCharacter!.realm}'
          : null,
      characterClass: _effectiveClass,
      characterSpec: _effectiveSpec,
      characterRace: _selectedCharacter?.race == null
          ? null
          : WowTranslations.canonicalizeRace(_selectedCharacter!.race!),
      createdAt: DateTime.now(),
      slots: Build.emptySlots,
    );

    setState(() => _isSaving = true);

    try {
      await context.read<BuildsCubit>().saveBuild(build);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {
      if (!mounted) return;
      final t = S.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.buildsSaveError)));
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    return AlertDialog(
      backgroundColor: WowTheme.surfaceDark,
      title: Text(
        t.buildsNewBuild,
        style: const TextStyle(color: WowTheme.primaryGold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                key: const Key('create-build-name'),
                controller: _nameController,
                autofocus: true,
                enabled: !_isSaving,
                style: const TextStyle(color: WowTheme.textPrimary),
                textInputAction: TextInputAction.done,
                validator: _validateName,
                onFieldSubmitted: (_) => _isSaving ? null : _submit(),
                decoration: InputDecoration(
                  hintText: t.buildsBuildName,
                  hintStyle: const TextStyle(color: WowTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              if (_loadingFavorites)
                const Center(
                  child: CircularProgressIndicator(color: WowTheme.primaryGold),
                )
              else ...[
                if (_favorites.isNotEmpty)
                  KeyedSubtree(
                    key: ValueKey(
                      'create-build-character-${_selectedCharacter?.key ?? 'generic'}',
                    ),
                    child: DropdownButtonFormField<FavoriteCharacter?>(
                      key: const Key('create-build-character'),
                      initialValue: _selectedCharacter,
                      dropdownColor: WowTheme.surfaceDark,
                      decoration: InputDecoration(
                        hintText: t.buildsLinkCharacter,
                        hintStyle: const TextStyle(
                          color: WowTheme.textSecondary,
                        ),
                      ),
                      style: const TextStyle(color: WowTheme.textPrimary),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            t.buildsGenericBuild,
                            style: const TextStyle(
                              color: WowTheme.textSecondary,
                            ),
                          ),
                        ),
                        ..._favorites.map(
                          (favorite) => DropdownMenuItem(
                            value: favorite,
                            child: Text(
                              '${favorite.name} - ${favorite.realm}',
                              style: const TextStyle(
                                color: WowTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: _isSaving ? null : _onCharacterChanged,
                    ),
                  )
                else if (_favoritesLoadError != null)
                  Text(
                    t.buildsFavoritesLoadError,
                    style: const TextStyle(
                      color: WowTheme.accentRed,
                      fontSize: 12,
                    ),
                  )
                else
                  Text(
                    t.buildsNoFavoritesYet,
                    style: const TextStyle(
                      color: WowTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              const Divider(color: WowTheme.textSecondary),
              const SizedBox(height: 4),
              Text(
                t.buildsClassAndSpec,
                style: const TextStyle(
                  color: WowTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              if (_hasLinkedCharacter)
                KeyedSubtree(
                  key: ValueKey(
                    'create-build-linked-class-${_effectiveClass ?? 'none'}',
                  ),
                  child: TextFormField(
                    key: const Key('create-build-linked-class'),
                    initialValue: WowTranslations.translateClass(
                      _effectiveClass!,
                      localeCode,
                    ),
                    enabled: false,
                    style: const TextStyle(color: WowTheme.textSecondary),
                    decoration: InputDecoration(
                      labelText: t.buildsLinkedClass,
                      labelStyle: const TextStyle(
                        color: WowTheme.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                KeyedSubtree(
                  key: ValueKey('create-build-class-${_manualClass ?? 'none'}'),
                  child: DropdownButtonFormField<String>(
                    key: const Key('create-build-class'),
                    initialValue: _manualClass,
                    dropdownColor: WowTheme.surfaceDark,
                    decoration: InputDecoration(
                      labelText: t.buildsSelectClass,
                      labelStyle: const TextStyle(
                        color: WowTheme.textSecondary,
                      ),
                    ),
                    style: const TextStyle(color: WowTheme.textPrimary),
                    validator: _validateManualClass,
                    items: wowClasses
                        .map(
                          (className) => DropdownMenuItem(
                            value: className,
                            child: Text(
                              WowTranslations.translateClass(
                                className,
                                localeCode,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving ? null : _onClassChanged,
                  ),
                ),
              const SizedBox(height: 8),
              KeyedSubtree(
                key: ValueKey(
                  'create-build-spec-${_selectedCharacter?.key ?? 'generic'}-${_effectiveClass ?? 'none'}-${_effectiveSpec ?? 'none'}',
                ),
                child: DropdownButtonFormField<String>(
                  key: const Key('create-build-spec'),
                  initialValue: _effectiveSpec,
                  dropdownColor: WowTheme.surfaceDark,
                  decoration: InputDecoration(
                    labelText: _hasLinkedCharacter
                        ? t.buildsLinkedSpec
                        : t.buildsSelectSpec,
                    labelStyle: const TextStyle(color: WowTheme.textSecondary),
                  ),
                  style: const TextStyle(color: WowTheme.textPrimary),
                  validator: _validateEffectiveSpec,
                  items: _effectiveSpecs
                      .map(
                        (specName) => DropdownMenuItem(
                          value: specName,
                          child: Text(
                            WowTranslations.translateSpec(
                              specName,
                              localeCode,
                              className: _effectiveClass,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving || _effectiveClass == null
                      ? null
                      : (value) {
                          setState(() {
                            if (_hasLinkedCharacter) {
                              _linkedSpec = value;
                            } else {
                              _manualSpec = value;
                            }
                          });
                          _formKey.currentState?.validate();
                        },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text(
            t.buildsCancel,
            style: const TextStyle(color: WowTheme.textSecondary),
          ),
        ),
        TextButton(
          key: const Key('create-build-submit'),
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: WowTheme.primaryGold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.buildsSaving,
                      style: const TextStyle(color: WowTheme.primaryGold),
                    ),
                  ],
                )
              : Text(
                  t.buildsCreate,
                  style: const TextStyle(color: WowTheme.primaryGold),
                ),
        ),
      ],
    );
  }
}
