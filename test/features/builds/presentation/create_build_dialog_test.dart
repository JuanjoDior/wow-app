import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/features/builds/domain/repositories/builds_repository.dart';
import 'package:wow_companion/features/builds/presentation/cubit/builds_cubit.dart';
import 'package:wow_companion/features/builds/presentation/widgets/create_build_dialog.dart';
import 'package:wow_companion/features/favorites/domain/favorites_repository.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class _MockFavoritesRepository extends Mock implements FavoritesRepository {}

class _MockBuildsRepository extends Mock implements BuildsRepository {}

void main() {
  late _MockFavoritesRepository favoritesRepository;
  late _MockBuildsRepository buildsRepository;
  late BuildsCubit cubit;

  setUp(() async {
    await sl.reset();
    favoritesRepository = _MockFavoritesRepository();
    buildsRepository = _MockBuildsRepository();
    cubit = BuildsCubit(buildsRepository);

    when(
      () => favoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const []);

    sl.registerLazySingleton<FavoritesRepository>(() => favoritesRepository);
  });

  tearDown(() async {
    await cubit.close();
    await sl.reset();
  });

  Widget appWidget() {
    return MaterialApp(
      locale: const Locale('es'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: BlocProvider.value(
        value: cubit,
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => const CreateBuildDialog(),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('muestra clases y specs localizadas en castellano', (
    tester,
  ) async {
    await tester.pumpWidget(appWidget());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();

    expect(find.text('Caballero de la Muerte'), findsWidgets);
    expect(find.text('Death Knight'), findsNothing);

    await tester.tap(find.text('Caballero de la Muerte').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();

    expect(find.text('Sangre'), findsWidgets);
    expect(find.text('Blood'), findsNothing);
  });
}
