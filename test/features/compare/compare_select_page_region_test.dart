import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wow_companion/features/compare/presentation/pages/compare_select_page.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

void main() {
  Widget app(GoRouter router) {
    return MaterialApp.router(
      locale: const Locale('es'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      routerConfig: router,
    );
  }

  testWidgets('region selector shows only EU/US/KR/TW', (tester) async {
    final router = GoRouter(
      initialLocation: '/compare',
      routes: [
        GoRoute(
          path: '/compare',
          builder: (context, state) => const CompareSelectPage(),
        ),
        GoRoute(
          path: '/compare/:region1/:realm1/:name1/vs/:region2/:realm2/:name2',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );

    await tester.pumpWidget(app(router));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Europa'), findsWidgets);
    expect(find.textContaining('Américas'), findsWidgets);
    expect(find.textContaining('Corea'), findsWidgets);
    expect(find.textContaining('Taiwán'), findsWidgets);
    expect(find.textContaining('China'), findsNothing);
    expect(find.textContaining('CN'), findsNothing);
  });

  testWidgets('submit builds normalized compare route', (tester) async {
    final router = GoRouter(
      initialLocation: '/compare',
      routes: [
        GoRoute(
          path: '/compare',
          builder: (context, state) => const CompareSelectPage(),
        ),
        GoRoute(
          path: '/compare/:region1/:realm1/:name1/vs/:region2/:realm2/:name2',
          builder: (context, state) => Scaffold(
            body: Text(
              'left=${state.pathParameters['region1']}/'
              '${state.pathParameters['realm1']}/'
              '${state.pathParameters['name1']} '
              'right=${state.pathParameters['region2']}/'
              '${state.pathParameters['realm2']}/'
              '${state.pathParameters['name2']}',
              key: const Key('compare-target'),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(app(router));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Burning Legion');
    await tester.enterText(find.byType(TextField).at(1), 'Alpha');
    await tester.enterText(find.byType(TextField).at(2), 'Aerie Peak');
    await tester.enterText(find.byType(TextField).at(3), 'Beta');
    await tester.pump();

    final compareButton = find.widgetWithText(ElevatedButton, 'Comparar');
    final buttonWidget = tester.widget<ElevatedButton>(compareButton);
    expect(buttonWidget.onPressed, isNotNull);
    await tester.ensureVisible(compareButton);
    await tester.tap(compareButton);
    await tester.pumpAndSettle();

    final text = tester
        .widget<Text>(find.byKey(const Key('compare-target')))
        .data;
    expect(text, contains('left=eu/burning-legion/alpha'));
    expect(text, contains('right=eu/aerie-peak/beta'));
  });
}
