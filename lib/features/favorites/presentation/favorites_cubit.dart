import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/features/favorites/domain/favorites_repository.dart';

// States
abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {
  const FavoritesInitial();
}

class FavoritesLoaded extends FavoritesState {
  final List<FavoriteCharacter> favorites;

  const FavoritesLoaded(this.favorites);

  @override
  List<Object?> get props => [favorites];
}

// Cubit
class FavoritesCubit extends Cubit<FavoritesState> {
  final FavoritesRepository _repository;

  FavoritesCubit(this._repository) : super(const FavoritesInitial());

  Future<void> loadFavorites() async {
    final favorites = await _repository.getFavorites();
    emit(FavoritesLoaded(favorites));
  }

  Future<void> toggleFavorite(FavoriteCharacter character) async {
    final isFav = await _repository.isFavorite(character.key);
    if (isFav) {
      await _repository.removeFavorite(character.key);
    } else {
      await _repository.addFavorite(character);
    }
    await loadFavorites();
  }

  Future<bool> isFavorite(String key) async {
    return _repository.isFavorite(key);
  }
}
