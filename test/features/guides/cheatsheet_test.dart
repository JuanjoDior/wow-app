import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/features/guides/domain/entities/cheatsheet.dart';

void main() {
  group('Cheatsheet', () {
    final json = {
      'class_slug': 'warrior',
      'spec_slug': 'fury',
      'class_name': 'Warrior',
      'spec_name': 'Fury',
      'role': 'DPS',
      'stat_priority': ['Haste', 'Mastery'],
      'rotation': [
        {'priority': 1, 'ability': 'Rampage', 'condition': 'At 80+ rage'},
      ],
      'consumables': [
        {'type': 'Flask', 'name': 'Test Flask', 'note': 'Best'},
      ],
      'tips': ['Tip one'],
      'last_updated': '2025-05',
    };

    test('fromJson creates valid Cheatsheet', () {
      final cs = Cheatsheet.fromJson(json);
      expect(cs.classSlug, 'warrior');
      expect(cs.specSlug, 'fury');
      expect(cs.displayTitle, 'Fury Warrior');
      expect(cs.role, 'DPS');
    });

    test('id is class-spec', () {
      final cs = Cheatsheet.fromJson(json);
      expect(cs.id, 'warrior-fury');
    });

    test('statPriority parsed correctly', () {
      final cs = Cheatsheet.fromJson(json);
      expect(cs.statPriority, ['Haste', 'Mastery']);
    });

    test('rotation parsed correctly', () {
      final cs = Cheatsheet.fromJson(json);
      expect(cs.rotation.length, 1);
      expect(cs.rotation.first.ability, 'Rampage');
      expect(cs.rotation.first.priority, 1);
      expect(cs.rotation.first.condition, 'At 80+ rage');
    });

    test('consumables parsed correctly', () {
      final cs = Cheatsheet.fromJson(json);
      expect(cs.consumables.length, 1);
      expect(cs.consumables.first.type, 'Flask');
      expect(cs.consumables.first.name, 'Test Flask');
      expect(cs.consumables.first.note, 'Best');
    });

    test('tips parsed correctly', () {
      final cs = Cheatsheet.fromJson(json);
      expect(cs.tips, ['Tip one']);
    });

    test('fromJson without optional fields', () {
      final minimal = Map<String, dynamic>.from(json)
        ..remove('tips')
        ..remove('last_updated');
      final cs = Cheatsheet.fromJson(minimal);
      expect(cs.tips, isEmpty);
      expect(cs.lastUpdated, isNull);
    });
  });

  group('RotationStep', () {
    test('fromJson without condition', () {
      final step = RotationStep.fromJson({
        'priority': 1,
        'ability': 'Fireball',
      });
      expect(step.condition, '');
    });
  });

  group('ConsumableInfo', () {
    test('fromJson without note', () {
      final c = ConsumableInfo.fromJson({
        'type': 'Potion',
        'name': 'Health Potion',
      });
      expect(c.note, isNull);
    });
  });
}
