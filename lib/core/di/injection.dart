import 'package:get_it/get_it.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/character/data/datasources/raiderio_datasource.dart';
import 'package:wow_companion/features/character/data/repositories/character_repository_impl.dart';
import 'package:wow_companion/features/character/domain/repositories/character_repository.dart';
import 'package:wow_companion/features/character/domain/usecases/get_character.dart';
import 'package:wow_companion/features/character/presentation/cubit/character_cubit.dart';
import 'package:wow_companion/features/favorites/data/favorites_repository_impl.dart';
import 'package:wow_companion/features/favorites/domain/favorites_repository.dart';
import 'package:wow_companion/features/favorites/presentation/favorites_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ---- Core ----
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // ---- Character Feature ----
  sl.registerLazySingleton<RaiderIoDataSource>(() => RaiderIoDataSource(sl()));

  sl.registerLazySingleton<CharacterRepository>(
    () => CharacterRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetCharacter(sl()));
  sl.registerLazySingleton(() => SearchCharacters(sl()));

  sl.registerFactory(() => CharacterCubit(sl()));
  sl.registerFactory(() => CharacterSearchCubit(sl()));

  // ---- Favorites Feature ----
  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(),
  );

  sl.registerFactory(() => FavoritesCubit(sl()));
}
