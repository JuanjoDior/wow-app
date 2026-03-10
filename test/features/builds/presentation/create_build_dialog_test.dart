import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/repositories/builds_repository.dart';
import 'package:wow_companion/features/builds/presentation/cubit/builds_cubit.dart';
import 'package:wow_companion/features/builds/presentation/widgets/create_build_dialog.dart';
import 'package:wow_companion/features/favorites/domain/favorites_repository.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class _MockFavoritesRepository extends Mock implements FavoritesRepository {}

class _MockBuildsRepository extends Mock implements BuildsRepository {}

class _FakeBuild extends Fake implements Build {}

void main() {
  late _MockFavoritesRepository favoritesRepository;
  late _MockBuildsRepository buildsRepository;
  late BuildsCubit cubit;

  setUpAll(() {
    registerFallbackValue(_FakeBuild());
  });

  setUp(() async {
    await sl.reset();
    favoritesRepository = _MockFavoritesRepository();
    buildsRepository = _MockBuildsRepository();
    cubit = BuildsCubit(buildsRepository);

    when(
      () => favoritesRepository.getFavorites(),
    ).thenAnswer((_) async => const []);
    when(() => buildsRepository.getBuilds()).thenAnswer((_) async => const []);
    when(() => buildsRepository.saveBuild(any())).thenAnswer((_) async {});

    sl.registerLazySingleton<FavoritesRepository>(() => favoritesRepository);
  });

  tearDown(() async {
    await cubit.close();
    await sl.reset();
  });

  Widget appWidget({Locale locale = const Locale('es')}) {
    return MaterialApp(
      locale: locale,
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

  Future<void> openDialog(
    WidgetTester tester, {
    Locale locale = const Locale('es'),
  }) async {
    await tester.pumpWidget(appWidget(locale: locale));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  DropdownButton<T> dropdownButton<T>(WidgetTester tester, Key key) {
    final finder = find.descendant(
      of: find.byKey(key),
      matching: find.byWidgetPredicate((widget) => widget is DropdownButton<T>),
    );
    return tester.widget<DropdownButton<T>>(finder);
  }

  Future<void> selectDropdownValue<T>(
    WidgetTester tester, {
    required Key key,
    required T value,
  }) async {
    final button = dropdownButton<T>(tester, key);
    button.onChanged!(value);
    await tester.pumpAndSettle();
  }

  List<String> dropdownItemLabels<T>(WidgetTester tester, Key key) {
    final button = dropdownButton<T>(tester, key);
    return button.items!
        .map((item) => item.child)
        .whereType<Text>()
        .map((text) => text.data ?? '')
        .where((text) => text.isNotEmpty)
        .toList();
  }

  T dropdownInitialValue<T>(WidgetTester tester, Key key) {
    final button = dropdownButton<T>(tester, key);
    return button.value as T;
  }

  Future<void> fillValidGenericBuild(
    WidgetTester tester, {
    required String name,
    required String className,
    required String specName,
  }) async {
    await tester.enterText(find.byKey(const Key('create-build-name')), name);
    await selectDropdownValue<String>(
      tester,
      key: const Key('create-build-class'),
      value: className,
    );
    await selectDropdownValue<String>(
      tester,
      key: const Key('create-build-spec'),
      value: specName,
    );
  }

  testWidgets('muestra Devourer localizado en castellano', (tester) async {
    await openDialog(tester);

    await selectDropdownValue<String>(
      tester,
      key: const Key('create-build-class'),
      value: 'Demon Hunter',
    );

    final labels = dropdownItemLabels<String>(
      tester,
      const Key('create-build-spec'),
    );
    expect(labels, contains('Devorador'));
    expect(labels, isNot(contains('Devourer')));
    expect(labels, contains('Devastación'));
    expect(labels, contains('Venganza'));
  });

  testWidgets('muestra Devourer en ingles', (tester) async {
    await openDialog(tester, locale: const Locale('en'));

    await selectDropdownValue<String>(
      tester,
      key: const Key('create-build-class'),
      value: 'Demon Hunter',
    );

    final labels = dropdownItemLabels<String>(
      tester,
      const Key('create-build-spec'),
    );
    expect(labels, contains('Devourer'));
    expect(labels, contains('Havoc'));
    expect(labels, contains('Vengeance'));
  });

  testWidgets('valida nombre clase y spec en build generica', (tester) async {
    await openDialog(tester);

    await tester.tap(find.byKey(const Key('create-build-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Introduce un nombre para la build.'), findsOneWidget);
    expect(find.text('Selecciona una clase.'), findsOneWidget);
    expect(find.text('Selecciona una spec.'), findsOneWidget);
    verifyNever(() => buildsRepository.saveBuild(any()));
  });

  testWidgets('permite editar la spec de una build ligada', (tester) async {
    final favorite = FavoriteCharacter(
      name: 'Illidan',
      realm: 'Sargeras',
      region: 'eu',
      characterClass: 'Demon Hunter',
      specialization: 'Havoc',
      race: 'Night Elf',
    );
    when(
      () => favoritesRepository.getFavorites(),
    ).thenAnswer((_) async => [favorite]);

    await openDialog(tester);

    await tester.enterText(
      find.byKey(const Key('create-build-name')),
      'DH Raid Devourer',
    );
    await selectDropdownValue<FavoriteCharacter?>(
      tester,
      key: const Key('create-build-character'),
      value: favorite,
    );

    final linkedClassField = tester.widget<TextFormField>(
      find.byKey(const Key('create-build-linked-class')),
    );
    expect(linkedClassField.initialValue, 'Cazador de Demonios');
    expect(
      dropdownInitialValue<String>(tester, const Key('create-build-spec')),
      'Havoc',
    );

    await selectDropdownValue<String>(
      tester,
      key: const Key('create-build-spec'),
      value: 'Devourer',
    );
    expect(
      dropdownInitialValue<String>(tester, const Key('create-build-spec')),
      'Devourer',
    );
  });

  testWidgets('normaliza favoritos guardados en español al enlazar build', (
    tester,
  ) async {
    final favorite = FavoriteCharacter(
      name: 'Illidan',
      realm: 'Sargeras',
      region: 'eu',
      characterClass: 'Cazador de Demonios',
      specialization: 'Devastacion',
      race: 'Elfo de la noche',
    );
    when(
      () => favoritesRepository.getFavorites(),
    ).thenAnswer((_) async => [favorite]);

    await openDialog(tester, locale: const Locale('en'));
    await selectDropdownValue<FavoriteCharacter?>(
      tester,
      key: const Key('create-build-character'),
      value: favorite,
    );

    final linkedClassField = tester.widget<TextFormField>(
      find.byKey(const Key('create-build-linked-class')),
    );
    expect(linkedClassField.initialValue, 'Demon Hunter');
    expect(
      dropdownInitialValue<String>(tester, const Key('create-build-spec')),
      'Havoc',
    );
  });

  testWidgets('restaura la seleccion manual al volver a build generica', (
    tester,
  ) async {
    final favorite = FavoriteCharacter(
      name: 'Jaina',
      realm: 'Kul Tiras',
      region: 'eu',
      characterClass: 'Mage',
      specialization: 'Arcane',
    );
    when(
      () => favoritesRepository.getFavorites(),
    ).thenAnswer((_) async => [favorite]);

    await openDialog(tester);

    await selectDropdownValue<String>(
      tester,
      key: const Key('create-build-class'),
      value: 'Warlock',
    );
    await selectDropdownValue<String>(
      tester,
      key: const Key('create-build-spec'),
      value: 'Destruction',
    );

    await selectDropdownValue<FavoriteCharacter?>(
      tester,
      key: const Key('create-build-character'),
      value: favorite,
    );
    await selectDropdownValue<FavoriteCharacter?>(
      tester,
      key: const Key('create-build-character'),
      value: null,
    );

    expect(
      dropdownInitialValue<String>(tester, const Key('create-build-class')),
      'Warlock',
    );
    expect(
      dropdownInitialValue<String>(tester, const Key('create-build-spec')),
      'Destruction',
    );
  });

  testWidgets('mantiene el dialogo abierto si guardar falla', (tester) async {
    when(
      () => buildsRepository.saveBuild(any()),
    ).thenThrow(Exception('save failed'));

    await openDialog(tester);
    await fillValidGenericBuild(
      tester,
      name: 'Mage Frost',
      className: 'Mage',
      specName: 'Frost',
    );

    await tester.tap(find.byKey(const Key('create-build-submit')));
    await tester.pumpAndSettle();

    expect(find.byType(CreateBuildDialog), findsOneWidget);
    expect(find.text('No se pudo guardar la build.'), findsOneWidget);
  });

  testWidgets('si favoritos falla sigue permitiendo build generica', (
    tester,
  ) async {
    when(
      () => favoritesRepository.getFavorites(),
    ).thenThrow(Exception('favorites failed'));

    await openDialog(tester);

    expect(find.text('No se pudieron cargar los favoritos.'), findsOneWidget);

    await fillValidGenericBuild(
      tester,
      name: 'Mage Frost Offline',
      className: 'Mage',
      specName: 'Frost',
    );
    expect(
      dropdownInitialValue<String>(tester, const Key('create-build-class')),
      'Mage',
    );
    expect(
      dropdownInitialValue<String>(tester, const Key('create-build-spec')),
      'Frost',
    );
  });
}
