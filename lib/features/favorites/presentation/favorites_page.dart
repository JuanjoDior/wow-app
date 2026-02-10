import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/favorites/presentation/favorites_cubit.dart';
import 'package:wow_companion/shared/widgets/common_widgets.dart';

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
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state is FavoritesLoaded) {
            if (state.favorites.isEmpty) {
              return _buildEmptyState();
            }
            return _buildFavoritesList(state);
          }
          return const WowLoadingWidget();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_outline, size: 64, color: WowTheme.textSecondary),
          SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(color: WowTheme.textSecondary, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Search for a character and tap ★ to save',
            style: TextStyle(color: WowTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(FavoritesLoaded state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.favorites.length,
      itemBuilder: (context, index) {
        final fav = state.favorites[index];
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
                '${fav.realm} · ${fav.specialization ?? fav.characterClass}',
                style: const TextStyle(color: WowTheme.textSecondary),
              ),
              trailing: fav.itemLevel != null
                  ? QualityBadge(quality: 'EPIC', itemLevel: fav.itemLevel!)
                  : null,
              onTap: () {
                final realmSlug = fav.realm.toLowerCase().replaceAll(' ', '-');
                context.push(
                  '/character/${fav.region.toLowerCase()}/$realmSlug/${fav.name.toLowerCase()}',
                );
              },
            ),
          ),
        );
      },
    );
  }
}
