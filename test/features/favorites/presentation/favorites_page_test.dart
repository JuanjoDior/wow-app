import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/features/favorites/domain/favorites_repository.dart';
import 'package:wow_companion/features/favorites/presentation/favorites_cubit.dart';
import 'package:wow_companion/features/favorites/presentation/favorites_page.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

void main() {
  late _MockFavoritesCubit cubit;

  setUp(() async {
    await sl.reset();
    cubit = _MockFavoritesCubit();
    when(() => cubit.loadFavorites()).thenAnswer((_) async {});
    sl.registerLazySingleton<FavoritesCubit>(() => cubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget appWidget({Locale locale = const Locale('es')}) {
    return MaterialApp(
      locale: locale,
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: const FavoritesPage(),
    );
  }

  testWidgets('traduce la especialización en la lista de favoritos', (
    tester,
  ) async {
    final favorites = [
      FavoriteCharacter(
        name: 'Idrexii',
        realm: 'Sanguino',
        region: 'eu',
        characterClass: 'Demon Hunter',
        specialization: 'Vengeance',
        itemLevel: 140,
      ),
    ];

    when(() => cubit.state).thenReturn(FavoritesLoaded(favorites));
    whenListen(
      cubit,
      const Stream<FavoritesState>.empty(),
      initialState: FavoritesLoaded(favorites),
    );

    await tester.pumpWidget(appWidget());
    await tester.pumpAndSettle();

    expect(find.text('Sanguino · Venganza'), findsOneWidget);
  });

  testWidgets('normaliza favoritos guardados en español al cambiar a ingles', (
    tester,
  ) async {
    final favorites = [
      FavoriteCharacter(
        name: 'Idrexii',
        realm: 'Sanguino',
        region: 'eu',
        characterClass: 'Cazador de Demonios',
        specialization: 'Venganza',
        itemLevel: 140,
      ),
    ];

    when(() => cubit.state).thenReturn(FavoritesLoaded(favorites));
    whenListen(
      cubit,
      const Stream<FavoritesState>.empty(),
      initialState: FavoritesLoaded(favorites),
    );

    await tester.pumpWidget(appWidget(locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Sanguino · Vengeance'), findsOneWidget);
  });
}
