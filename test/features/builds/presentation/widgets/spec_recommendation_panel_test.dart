import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_cubit.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_state.dart';
import 'package:wow_companion/features/builds/presentation/widgets/spec_recommendation_panel.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class _MockBuildDetailCubit extends MockCubit<BuildDetailState>
    implements BuildDetailCubit {}

void main() {
  group('SpecRecommendationPanel', () {
    late _MockBuildDetailCubit cubit;

    final build = Build(
      id: '1',
      name: 'Build',
      characterClass: 'Druid',
      characterSpec: 'Feral',
      createdAt: DateTime(2026, 2, 24),
      slots: Build.emptySlots,
    );

    const rec = SpecRecommendation(
      className: 'druid',
      specName: 'feral',
      patch: '11.2',
      statPriority: ['Agilidad', 'Critical Strike'],
      flask: ItemSuggestion(name: 'Flask of Alchemical Chaos'),
      food: ItemSuggestion(name: "Beledar's Bounty"),
      potion: ItemSuggestion(name: 'Tempered Potion'),
    );

    setUp(() {
      cubit = _MockBuildDetailCubit();
    });

    tearDown(() => cubit.close());

    Future<void> pumpPanel(WidgetTester tester, BuildDetailLoaded state) async {
      when(() => cubit.state).thenReturn(state);
      whenListen(
        cubit,
        Stream<BuildDetailState>.fromIterable([state]),
        initialState: state,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: BlocProvider<BuildDetailCubit>.value(
              value: cubit,
              child: const SpecRecommendationPanel(),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('renders recommendation content when data exists', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        BuildDetailLoaded(
          build,
          recommendation: rec,
          recommendationLookupDone: true,
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.text('Agilidad'), findsOneWidget);
      expect(find.text('Flask of Alchemical Chaos'), findsOneWidget);
    });

    testWidgets(
      'shows local fallback message when lookup completed with no data',
      (tester) async {
        await pumpPanel(
          tester,
          BuildDetailLoaded(build, recommendationLookupDone: true),
        );

        expect(find.text('Consulta en Icy Veins'), findsOneWidget);
      },
    );

    testWidgets('does not show fallback before lookup completion', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        BuildDetailLoaded(build, recommendationLookupDone: false),
      );

      expect(find.text('Consulta en Icy Veins'), findsNothing);
      expect(find.byType(SpecRecommendationPanel), findsOneWidget);
    });
  });
}
