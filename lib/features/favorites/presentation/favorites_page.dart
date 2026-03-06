import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/l10n/wow_translations.dart';
import 'package:wow_companion/core/wow/character_search_input.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/favorites/presentation/favorites_cubit.dart';
import 'package:wow_companion/shared/widgets/common_widgets.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late final FavoritesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<FavoritesCubit>();
    _cubit.loadFavorites();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.favorites)),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state is FavoritesLoaded) {
            if (state.favorites.isEmpty) {
              return _buildEmptyState(t);
            }
            return _buildFavoritesList(state);
          }
          return const WowLoadingWidget();
        },
      ),
    );
  }

  Widget _buildEmptyState(S t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_outline,
            size: 64,
            color: WowTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            t.noFavoritesYet,
            style: const TextStyle(color: WowTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            t.favoritesHint,
            style: const TextStyle(color: WowTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(FavoritesLoaded state) {
    final localeCode = Localizations.localeOf(context).languageCode;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.favorites.length,
          itemBuilder: (context, index) {
            final fav = state.favorites[index];
            final detailRaw = fav.specialization ?? fav.characterClass;
            final detailTranslated = fav.specialization != null
                ? WowTranslations.translateSpec(detailRaw, localeCode)
                : WowTranslations.translateClass(detailRaw, localeCode);
            return Dismissible(
              key: ValueKey(fav.key),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  color: WowTheme.accentRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => _cubit.toggleFavorite(fav),
              child: Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: ClassIcon(className: fav.characterClass),
                  title: Text(
                    fav.name,
                    style: TextStyle(
                      color: WowTheme.getClassColor(fav.characterClass),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${fav.realm} · $detailTranslated',
                    style: const TextStyle(color: WowTheme.textSecondary),
                  ),
                  trailing: fav.itemLevel != null
                      ? QualityBadge(quality: 'EPIC', itemLevel: fav.itemLevel!)
                      : null,
                  onTap: () {
                    context.push(
                      buildCharacterRoute(
                        region: fav.region,
                        realm: fav.realm,
                        name: fav.name,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
