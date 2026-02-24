import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/shared/widgets/item_tooltip_trigger.dart';

void main() {
  group('ItemTooltipDisplayData.fromSources', () {
    test('uses EquippedItem data when only equipped source exists', () {
      final equipped = EquippedItem(
        slot: 'MAIN_HAND',
        name: 'Raid Blade',
        itemLevel: 639,
        quality: 'EPIC',
        itemId: 19019,
        iconUrl: 'https://cdn.example/raid-blade.jpg',
        enchantments: const ['Authority of Radiant Power'],
        gems: const ['Masterful Ruby'],
        bonusIds: const [12, 34],
      );

      final data = ItemTooltipDisplayData.fromSources(equippedItem: equipped);

      expect(data.itemId, 19019);
      expect(data.name, 'Raid Blade');
      expect(data.quality, 'EPIC');
      expect(data.itemLevel, 639);
      expect(data.slotLabel, 'Main Hand');
      expect(data.iconUrl, 'https://cdn.example/raid-blade.jpg');
      expect(data.enchantments, ['Authority of Radiant Power']);
      expect(data.gems, ['Masterful Ruby']);
      expect(data.bonusIds, [12, 34]);
      expect(data.wowheadUrl, 'https://www.wowhead.com/item=19019&bonus=12:34');
    });

    test('uses Item detail data when only item source exists', () {
      final item = Item(
        id: 171639,
        name: 'Reclaimed Ashkandi',
        quality: 'EPIC',
        level: 60,
        requiredLevel: 32,
        itemClass: 'Weapon',
        itemSubclass: 'Sword',
        inventoryType: 'TWOHWEAPON',
        inventoryName: 'Two-Hand',
        iconUrl: 'https://cdn.example/ashkandi.jpg',
      );

      final data = ItemTooltipDisplayData.fromSources(itemDetail: item);

      expect(data.itemId, 171639);
      expect(data.name, 'Reclaimed Ashkandi');
      expect(data.quality, 'EPIC');
      expect(data.itemLevel, 60);
      expect(data.requiredLevel, 32);
      expect(data.slotLabel, 'Two-Hand');
      expect(data.itemSubclass, 'Sword');
      expect(data.iconUrl, 'https://cdn.example/ashkandi.jpg');
      expect(data.enchantments, isEmpty);
      expect(data.gems, isEmpty);
      expect(data.bonusIds, isEmpty);
      expect(data.wowheadUrl, 'https://www.wowhead.com/item=171639');
    });

    test('merges both sources preserving equipped enchants and gems', () {
      final equipped = EquippedItem(
        slot: 'HEAD',
        name: 'Unknown',
        itemLevel: 0,
        quality: 'EPIC',
        itemId: 1234,
        enchantments: const ['Stormrider\'s Intellect'],
        gems: const ['Culminating Blasphemite'],
      );

      final item = Item(
        id: 1234,
        name: 'Crown of Midnight',
        quality: 'LEGENDARY',
        level: 639,
        requiredLevel: 80,
        itemSubclass: 'Plate',
        inventoryName: 'Head',
        iconUrl: 'https://cdn.example/crown.jpg',
      );

      final data = ItemTooltipDisplayData.fromSources(
        equippedItem: equipped,
        itemDetail: item,
      );

      expect(data.name, 'Crown of Midnight');
      expect(data.quality, 'EPIC');
      expect(data.itemLevel, 639);
      expect(data.requiredLevel, 80);
      expect(data.slotLabel, 'Head');
      expect(data.itemSubclass, 'Plate');
      expect(data.iconUrl, 'https://cdn.example/crown.jpg');
      expect(data.enchantments, ['Stormrider\'s Intellect']);
      expect(data.gems, ['Culminating Blasphemite']);
      expect(data.wowheadUrl, 'https://www.wowhead.com/item=1234');
    });
  });
}
