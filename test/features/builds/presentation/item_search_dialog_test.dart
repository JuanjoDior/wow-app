import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/l10n/locale_notifier.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/presentation/widgets/item_search_dialog.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/entities/item_search_mode.dart';
import 'package:wow_companion/features/items/domain/usecases/search_items.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class _MockSearchItems extends Mock implements SearchItems {}

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
    _currentLocale = newLocale;
    notifyListeners();
  }
}

void main() {
  late _MockSearchItems searchItems;
  late _TestLocaleNotifier localeNotifier;

  setUpAll(() {
    registerFallbackValue(ItemSearchMode.item);
  });

  setUp(() async {
    await sl.reset();
    searchItems = _MockSearchItems();
    localeNotifier = _TestLocaleNotifier();

    when(
      () => searchItems(
        any(),
        mode: any(named: 'mode'),
        inventoryType: any(named: 'inventoryType'),
        slot: any(named: 'slot'),
        region: any(named: 'region'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async => const Right(<Item>[]));

    sl.registerLazySingleton<SearchItems>(() => searchItems);
    sl.registerLazySingleton<LocaleNotifier>(() => localeNotifier);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget appWidget(Widget child) {
    return MaterialApp(
      locale: const Locale('es'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: Scaffold(body: child),
    );
  }

  testWidgets('forwards enchant mode context and renders ES+EN names', (
    tester,
  ) async {
    when(
      () => searchItems(
        any(),
        mode: any(named: 'mode'),
        inventoryType: any(named: 'inventoryType'),
        slot: any(named: 'slot'),
        region: any(named: 'region'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer(
      (_) async => const Right([
        Item(
          id: 3001,
          name: 'Authority of Fiery Resolve',
          quality: 'EPIC',
          lookupKind: TooltipEntityKind.spell,
          inventoryType: 'NON_EQUIP',
          inventoryName: 'No equipable',
          localizedName: 'Autoridad de resolución ígnea',
          canonicalNameEn: 'Authority of Fiery Resolve',
        ),
      ]),
    );

    await tester.pumpWidget(
      appWidget(
        const ItemSearchDialog(
          slot: WowSlot.mainHand,
          title: 'Search Enchantment',
          mode: ItemSearchMode.enchant,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'authority');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();

    verify(
      () => searchItems(
        'authority',
        mode: ItemSearchMode.enchant,
        inventoryType: 'NON_EQUIP',
        slot: 'mainHand',
        region: 'eu',
        locale: 'es_ES',
      ),
    ).called(1);

    expect(find.text('Autoridad de resolución ígnea'), findsOneWidget);
    expect(find.text('Authority of Fiery Resolve'), findsOneWidget);
  });

  testWidgets('ignores stale responses and keeps latest query results', (
    tester,
  ) async {
    when(
      () => searchItems(
        any(),
        mode: any(named: 'mode'),
        inventoryType: any(named: 'inventoryType'),
        slot: any(named: 'slot'),
        region: any(named: 'region'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((invocation) async {
      final query = invocation.positionalArguments.first as String;
      if (query == 'ab') {
        await Future<void>.delayed(const Duration(milliseconds: 220));
        return const Right([
          Item(id: 1, name: 'Old Result', quality: 'COMMON'),
        ]);
      }
      if (query == 'abc') {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return const Right([
          Item(id: 2, name: 'New Result', quality: 'COMMON'),
        ]);
      }
      return const Right(<Item>[]);
    });

    await tester.pumpWidget(
      appWidget(
        const ItemSearchDialog(
          slot: WowSlot.head,
          title: 'Search Item',
          mode: ItemSearchMode.item,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'ab');
    await tester.pump(const Duration(milliseconds: 450));

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('New Result'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('New Result'), findsOneWidget);
    expect(find.text('Old Result'), findsNothing);
  });

  testWidgets('returns item with canonical name when selected', (tester) async {
    when(
      () => searchItems(
        any(),
        mode: any(named: 'mode'),
        inventoryType: any(named: 'inventoryType'),
        slot: any(named: 'slot'),
        region: any(named: 'region'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer(
      (_) async => const Right([
        Item(
          id: 3001,
          name: 'Authority of Fiery Resolve',
          quality: 'EPIC',
          lookupKind: TooltipEntityKind.spell,
          localizedName: 'Autoridad de resolución ígnea',
          canonicalNameEn: 'Authority of Fiery Resolve',
        ),
      ]),
    );

    Item? selected;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  selected = await showDialog<Item>(
                    context: context,
                    builder: (_) => const ItemSearchDialog(
                      slot: WowSlot.mainHand,
                      title: 'Search Enchantment',
                      mode: ItemSearchMode.enchant,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'authority');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autoridad de resolución ígnea'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.name, 'Authority of Fiery Resolve');
    expect(selected!.localizedName, 'Autoridad de resolución ígnea');
    expect(selected!.canonicalNameEn, 'Authority of Fiery Resolve');
    expect(selected!.lookupKind, TooltipEntityKind.spell);
  });
}
