import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/character/presentation/utils/primary_stat_display.dart';

void main() {
  group('determinePrimaryStatDisplay', () {
    test('returns agility when it is the highest primary stat', () {
      final stats = CharacterStats(strength: 129, agility: 429, intellect: 210);

      final result = determinePrimaryStatDisplay(stats);

      expect(result.label, 'Agilidad');
      expect(result.value, 429);
    });

    test('returns strength when it is the highest primary stat', () {
      final stats = CharacterStats(
        strength: 74500,
        agility: 6200,
        intellect: 18000,
      );

      final result = determinePrimaryStatDisplay(stats);

      expect(result.label, 'Fuerza');
      expect(result.value, 74500);
    });

    test('falls back to intellect when only intellect is available', () {
      final stats = CharacterStats(intellect: 12000);

      final result = determinePrimaryStatDisplay(stats);

      expect(result.label, 'Intelecto');
      expect(result.value, 12000);
    });
  });
}
