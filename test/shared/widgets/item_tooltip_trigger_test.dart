import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';
import 'package:wow_companion/shared/widgets/item_tooltip_trigger.dart';

Widget _appWithBody(Widget body, {Size size = const Size(800, 600)}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: Center(child: body)),
    ),
  );
}

void main() {
  group('ItemTooltipTrigger', () {
    testWidgets('detailMode opens and closes tooltip on tap', (tester) async {
      final equipped = EquippedItem(
        slot: 'HEAD',
        name: 'Crimson Helm',
        itemLevel: 626,
        quality: 'EPIC',
      );

      await tester.pumpWidget(
        _appWithBody(
          ItemTooltipTrigger.forEquippedItem(
            equippedItem: equipped,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Open Tooltip'),
            ),
          ),
        ),
      );

      expect(find.text('Crimson Helm'), findsNothing);

      await tester.tap(find.text('Open Tooltip'));
      await tester.pumpAndSettle();

      expect(find.text('Crimson Helm'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('Crimson Helm'), findsNothing);
    });

    testWidgets('actionFirstMode keeps primary tap and opens on long press', (
      tester,
    ) async {
      int primaryTapCount = 0;
      final equipped = EquippedItem(
        slot: 'TRINKET_1',
        name: 'Mystic Charm',
        itemLevel: 619,
        quality: 'RARE',
      );

      await tester.pumpWidget(
        _appWithBody(
          ItemTooltipTrigger.forEquippedItem(
            equippedItem: equipped,
            mode: ItemTooltipInteractionMode.actionFirstMode,
            onPrimaryTap: () => primaryTapCount++,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Selectable Item'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Selectable Item'));
      await tester.pumpAndSettle();

      expect(primaryTapCount, 1);
      expect(find.text('Mystic Charm'), findsNothing);

      await tester.longPress(find.text('Selectable Item'));
      await tester.pumpAndSettle();

      expect(find.text('Mystic Charm'), findsOneWidget);
    });

    testWidgets('backdrop tap closes opened tooltip', (tester) async {
      final equipped = EquippedItem(
        slot: 'CHEST',
        name: 'Twilight Breastplate',
        itemLevel: 632,
        quality: 'EPIC',
      );

      await tester.pumpWidget(
        _appWithBody(
          ItemTooltipTrigger.forEquippedItem(
            equippedItem: equipped,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Tooltip Target'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tooltip Target'));
      await tester.pumpAndSettle();
      expect(find.text('Twilight Breastplate'), findsOneWidget);

      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(find.text('Twilight Breastplate'), findsNothing);
    });
  });
}
