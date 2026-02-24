import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/l10n/locale_notifier.dart';
import 'package:wow_companion/features/items/presentation/cubit/items_cubit.dart';
import 'package:wow_companion/features/items/presentation/cubit/items_state.dart';
import 'package:wow_companion/features/items/presentation/items_page.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class _MockItemsCubit extends MockCubit<ItemsState> implements ItemsCubit {}

class _TestLocaleNotifier extends LocaleNotifier {
  Locale _currentLocale = const Locale('es');

  @override
  Locale get locale => _currentLocale;

  @override
  String get blizzardLocale =>
      _currentLocale.languageCode == 'es' ? 'es_ES' : 'en_GB';

  @override
  Future<void> load() async {}

  @override
  Future<void> setLocale(Locale newLocale) async {
    if (_currentLocale == newLocale) return;
    _currentLocale = newLocale;
    notifyListeners();
  }

  @override
  Future<void> toggleLocale() async {
    await setLocale(
      _currentLocale.languageCode == 'es'
          ? const Locale('en')
          : const Locale('es'),
    );
  }
}

void main() {
  late _MockItemsCubit cubit;
  late _TestLocaleNotifier localeNotifier;

  setUp(() async {
    await sl.reset();
    cubit = _MockItemsCubit();
    localeNotifier = _TestLocaleNotifier();

    when(() => cubit.state).thenReturn(const ItemsInitial());
    whenListen(
      cubit,
      const Stream<ItemsState>.empty(),
      initialState: const ItemsInitial(),
    );
    when(
      () => cubit.search(
        any(),
        inventoryType: any(named: 'inventoryType'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});
    when(() => cubit.clear()).thenReturn(null);

    sl.registerFactory<ItemsCubit>(() => cubit);
    sl.registerLazySingleton<LocaleNotifier>(() => localeNotifier);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget appWidget() {
    return MaterialApp(
      locale: const Locale('es'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: const ItemsPage(),
    );
  }

  testWidgets('search passes es_ES locale from LocaleNotifier', (tester) async {
    await tester.pumpWidget(appWidget());
    await tester.enterText(find.byType(TextField), 'moneda');
    await tester.pump(const Duration(milliseconds: 600));

    verify(() => cubit.search('moneda', locale: 'es_ES')).called(1);
  });

  testWidgets('changing locale re-runs active query with new locale', (
    tester,
  ) async {
    await tester.pumpWidget(appWidget());

    await tester.enterText(find.byType(TextField), 'moneda');
    await tester.pump(const Duration(milliseconds: 600));
    verify(() => cubit.search('moneda', locale: 'es_ES')).called(1);
    clearInteractions(cubit);

    await localeNotifier.setLocale(const Locale('en'));
    await tester.pump();

    verify(() => cubit.search('moneda', locale: 'en_GB')).called(1);
  });
}
