import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/l10n/locale_notifier.dart';
import 'package:wow_companion/features/search/domain/search_entry.dart';
import 'package:wow_companion/features/search/domain/search_history_repository.dart';
import 'package:wow_companion/features/search/presentation/home_page.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class _FakeSearchHistoryRepository implements SearchHistoryRepository {
  final List<SearchEntry> _entries = <SearchEntry>[];

  @override
  Future<void> addEntry(SearchEntry entry) async {
    _entries.removeWhere((e) => e.key == entry.key);
    _entries.insert(0, entry);
  }

  @override
  Future<void> clearHistory() async {
    _entries.clear();
  }

  @override
  Future<List<SearchEntry>> getHistory() async {
    return List<SearchEntry>.from(_entries);
  }

  @override
  Future<void> removeEntry(String key) async {
    _entries.removeWhere((e) => e.key == key);
  }
}

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerLazySingleton<SearchHistoryRepository>(
      () => _FakeSearchHistoryRepository(),
    );
    sl.registerLazySingleton<LocaleNotifier>(() => LocaleNotifier());
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget app(GoRouter router) {
    return MaterialApp.router(
      locale: const Locale('es'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      routerConfig: router,
    );
  }

  testWidgets('region dropdown shows only EU/US/KR/TW', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/character/:region/:realm/:name',
          builder: (context, state) => Scaffold(
            body: Text(
              'target ${state.pathParameters['region']}',
              key: const Key('target'),
            ),
          ),
        ),
        GoRoute(
          path: '/compare',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );

    await tester.pumpWidget(app(router));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    expect(find.textContaining('Europa'), findsWidgets);
    expect(find.textContaining('Américas'), findsWidgets);
    expect(find.textContaining('Corea'), findsWidgets);
    expect(find.textContaining('Taiwán'), findsWidgets);
    expect(find.textContaining('China'), findsNothing);
    expect(find.textContaining('CN'), findsNothing);
  });

  testWidgets('submit builds encoded character route', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/character/:region/:realm/:name',
          builder: (context, state) => Scaffold(
            body: Text(
              'region=${state.pathParameters['region']} '
              'realm=${state.pathParameters['realm']} '
              'name=${state.pathParameters['name']}',
              key: const Key('target'),
            ),
          ),
        ),
        GoRoute(
          path: '/compare',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );

    await tester.pumpWidget(app(router));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Américas').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), "Cho'gall");
    await tester.enterText(find.byType(TextField).at(1), 'Thrall');
    await tester.tap(find.text('Buscar Personaje'));
    await tester.pumpAndSettle();

    final targetText = tester
        .widget<Text>(find.byKey(const Key('target')))
        .data;
    expect(targetText, contains('region=us'));
    expect(
      targetText,
      anyOf(contains("realm=cho'gall"), contains('realm=cho%27gall')),
    );
    expect(targetText, contains('name=thrall'));
  });
}
