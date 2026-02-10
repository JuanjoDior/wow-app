import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';

void main() {
  group('EquippedItem', () {
    test('wowheadUrl with itemId', () {
      const item = EquippedItem(
        slot: 'HEAD',
        name: 'Test Helm',
        itemLevel: 200,
        quality: 'EPIC',
        itemId: 12345,
      );
      expect(item.wowheadUrl, 'https://www.wowhead.com/item=12345');
    });

    test('wowheadUrl with bonusIds', () {
      const item = EquippedItem(
        slot: 'HEAD',
        name: 'Test Helm',
        itemLevel: 200,
        quality: 'EPIC',
        itemId: 12345,
        bonusIds: [1, 2, 3],
      );
      expect(item.wowheadUrl, 'https://www.wowhead.com/item=12345&bonus=1:2:3');
    });

    test('wowheadUrl null without itemId', () {
      const item = EquippedItem(
        slot: 'HEAD',
        name: 'Test Helm',
        itemLevel: 200,
        quality: 'EPIC',
      );
      expect(item.wowheadUrl, isNull);
    });

    test('displaySlot formats correctly', () {
      const item = EquippedItem(
        slot: 'MAIN_HAND',
        name: 'Sword',
        itemLevel: 200,
        quality: 'EPIC',
      );
      expect(item.displaySlot, 'Main Hand');
    });
  });
}
