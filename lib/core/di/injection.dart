import 'package:get_it/get_it.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/character/data/datasources/blizzard_character_datasource.dart';
import 'package:wow_companion/features/character/data/datasources/raiderio_datasource.dart';
import 'package:wow_companion/features/character/data/repositories/character_repository_impl.dart';
import 'package:wow_companion/features/character/domain/repositories/character_repository.dart';
import 'package:wow_companion/features/character/domain/usecases/get_character.dart';
import 'package:wow_companion/features/character/presentation/cubit/character_cubit.dart';
import 'package:wow_companion/features/favorites/data/favorites_repository_impl.dart';
import 'package:wow_companion/features/favorites/domain/favorites_repository.dart';
import 'package:wow_companion/features/favorites/presentation/favorites_cubit.dart';
import 'package:wow_companion/features/search/data/search_history_repository_impl.dart';
import 'package:wow_companion/features/search/domain/search_history_repository.dart';
import 'package:wow_companion/core/cache/memory_cache.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/core/l10n/locale_notifier.dart';
import 'package:wow_companion/features/items/data/datasources/blizzard_items_datasource.dart';
import 'package:wow_companion/features/items/data/repositories/items_repository_impl.dart';
import 'package:wow_companion/features/items/domain/repositories/items_repository.dart';
import 'package:wow_companion/features/items/domain/usecases/search_items.dart';
import 'package:wow_companion/features/items/presentation/cubit/items_cubit.dart';
import 'package:wow_companion/features/builds/data/repositories/builds_repository_impl.dart';
import 'package:wow_companion/features/builds/domain/repositories/builds_repository.dart';
import 'package:wow_companion/features/builds/presentation/cubit/builds_cubit.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_cubit.dart';
import 'package:wow_companion/features/builds/data/datasources/spells_datasource.dart';
import 'package:wow_companion/features/builds/data/repositories/spells_repository_impl.dart';
import 'package:wow_companion/features/builds/domain/repositories/spells_repository.dart';
import 'package:wow_companion/features/builds/domain/usecases/search_spells.dart';
import 'package:wow_companion/features/items/domain/usecases/get_item_detail.dart';
import 'package:wow_companion/features/builds/data/datasources/character_media_datasource.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── Core ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  sl.registerLazySingleton<MemoryCache<Character>>(
    () => MemoryCache<Character>(),
  );

  // ── Character Feature ─────────────────────────────────────────────────────
  sl.registerLazySingleton<BlizzardCharacterDatasource>(
    () => BlizzardCharacterDatasource(),
  );
  sl.registerLazySingleton<RaiderIoDataSource>(() => RaiderIoDataSource(sl()));
  sl.registerLazySingleton<CharacterRepository>(
    () => CharacterRepositoryImpl(
      blizzardDataSource: sl(),
      raiderIoDataSource: sl(),
      cache: sl<MemoryCache<Character>>(),
    ),
  );
  sl.registerLazySingleton(() => GetCharacter(sl()));
  sl.registerFactory(() => CharacterCubit(sl()));

  // ── Favorites Feature ─────────────────────────────────────────────────────
  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(),
  );
  sl.registerLazySingleton(() => FavoritesCubit(sl()));

  // ── Search History ────────────────────────────────────────────────────────
  sl.registerLazySingleton<SearchHistoryRepository>(
    () => SearchHistoryRepositoryImpl(),
  );
  sl.registerLazySingleton<LocaleNotifier>(() => LocaleNotifier());
  await sl<LocaleNotifier>().load();

  // ── Items Feature ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<BlizzardItemsDataSource>(
    () => BlizzardItemsDataSource(sl()),
  );
  sl.registerLazySingleton<ItemsRepository>(
    () => ItemsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => SearchItems(sl()));
  sl.registerFactory(() => ItemsCubit(sl()));
  sl.registerLazySingleton(() => GetItemDetail(sl()));

  // ── Builds Feature ────────────────────────────────────────────────────────
  sl.registerLazySingleton<BuildsRepository>(() => BuildsRepositoryImpl());
  sl.registerFactory(() => BuildsCubit(sl()));
  sl.registerFactory(() => BuildDetailCubit(sl(), sl()));

  // ── Spells (Build Guide) ──────────────────────────────────────────────────
  sl.registerLazySingleton<SpellsDataSource>(() => SpellsDataSource(sl()));
  sl.registerLazySingleton<SpellsRepository>(
    () => SpellsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => SearchSpells(sl()));

  // ── Character Media ───────────────────────────────────────────────────────
  sl.registerLazySingleton<CharacterMediaDataSource>(
    () => CharacterMediaDataSource(sl()),
  );
}
