import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/character/domain/usecases/get_character.dart';

// ========================
// CHARACTER PROFILE STATES
// ========================

abstract class CharacterState extends Equatable {
  const CharacterState();

  @override
  List<Object?> get props => [];
}

class CharacterInitial extends CharacterState {
  const CharacterInitial();
}

class CharacterLoading extends CharacterState {
  const CharacterLoading();
}

class CharacterLoaded extends CharacterState {
  final Character character;

  const CharacterLoaded(this.character);

  @override
  List<Object?> get props => [character];
}

class CharacterError extends CharacterState {
  final String message;

  const CharacterError(this.message);

  @override
  List<Object?> get props => [message];
}

// ========================
// CHARACTER SEARCH STATES
// ========================

abstract class CharacterSearchState extends Equatable {
  const CharacterSearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends CharacterSearchState {
  const SearchInitial();
}

class SearchLoading extends CharacterSearchState {
  const SearchLoading();
}

class SearchLoaded extends CharacterSearchState {
  final List<Character> results;

  const SearchLoaded(this.results);

  @override
  List<Object?> get props => [results];
}

class SearchError extends CharacterSearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}

// ========================
// CUBITS
// ========================

class CharacterCubit extends Cubit<CharacterState> {
  final GetCharacter _getCharacter;

  CharacterCubit(this._getCharacter) : super(const CharacterInitial());

  Future<void> fetchCharacter({
    required String region,
    required String realm,
    required String name,
  }) async {
    emit(const CharacterLoading());

    final result = await _getCharacter(
      region: region,
      realm: realm,
      name: name,
    );

    result.fold(
      (failure) => emit(CharacterError(failure.message)),
      (character) => emit(CharacterLoaded(character)),
    );
  }

  void reset() => emit(const CharacterInitial());
}

class CharacterSearchCubit extends Cubit<CharacterSearchState> {
  final SearchCharacters _searchCharacters;

  CharacterSearchCubit(this._searchCharacters) : super(const SearchInitial());

  Future<void> search({required String query, String region = 'eu'}) async {
    if (query.trim().length < 2) {
      emit(const SearchInitial());
      return;
    }

    emit(const SearchLoading());

    final result = await _searchCharacters(query: query.trim(), region: region);

    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (characters) => emit(SearchLoaded(characters)),
    );
  }

  void clear() => emit(const SearchInitial());
}
