import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/character/domain/usecases/get_character.dart';

// ========================
// States
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
  final String? suggestion;

  const CharacterError(this.message, {this.suggestion});

  @override
  List<Object?> get props => [message, suggestion];
}

// ========================
// Cubit
// ========================

class CharacterCubit extends Cubit<CharacterState> {
  final GetCharacter _getCharacter;

  CharacterCubit(this._getCharacter) : super(const CharacterInitial());

  Future<void> fetchCharacter({
    required String region,
    required String realm,
    required String name,
    String locale = 'en_GB',
  }) async {
    emit(const CharacterLoading());

    final result = await _getCharacter(
      region: region,
      realm: realm,
      name: name,
      locale: locale,
    );

    result.fold(
      (failure) =>
          emit(CharacterError(failure.message, suggestion: failure.suggestion)),
      (character) => emit(CharacterLoaded(character)),
    );
  }

  void reset() => emit(const CharacterInitial());
}
