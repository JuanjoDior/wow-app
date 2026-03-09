import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readArb(String path) {
  final raw = File(path).readAsStringSync();
  return Map<String, dynamic>.from(jsonDecode(raw) as Map);
}

Map<String, String> _readMessages(Map<String, dynamic> arb) {
  final messages = <String, String>{};
  for (final entry in arb.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key == '@@locale' || key.startsWith('@')) continue;
    if (value is String) {
      messages[key] = value;
    }
  }
  return messages;
}

Set<String> _placeholderSet(Map<String, dynamic> arb, String messageKey) {
  final metadata = arb['@$messageKey'];
  if (metadata is! Map) return const <String>{};
  final placeholders = metadata['placeholders'];
  if (placeholders is! Map) return const <String>{};
  return placeholders.keys.map((key) => key.toString()).toSet();
}

void main() {
  group('ARB glossary guard', () {
    late Map<String, dynamic> enArb;
    late Map<String, dynamic> esArb;
    late Map<String, String> enMessages;
    late Map<String, String> esMessages;

    setUpAll(() {
      enArb = _readArb('lib/l10n/app_en.arb');
      esArb = _readArb('lib/l10n/app_es.arb');
      enMessages = _readMessages(enArb);
      esMessages = _readMessages(esArb);
    });

    test('EN and ES expose the same translatable keys', () {
      expect(esMessages.keys.toSet(), enMessages.keys.toSet());
    });

    test('EN and ES keep placeholder metadata aligned', () {
      for (final key in enMessages.keys) {
        expect(
          _placeholderSet(esArb, key),
          _placeholderSet(enArb, key),
          reason: 'Placeholder mismatch for key "$key"',
        );
      }
    });

    test('non-translatable WoW terms keep canonical form', () {
      const exactSame = <String, String>{
        'ilvl': 'iLvl',
        'mythicPlus': 'Mythic+',
        'guideContentMythicPlus': 'M+',
        'dps': 'DPS',
        'builds': 'Builds',
        'vs': 'VS',
        'externalRaiderIo': 'Raider.IO',
        'externalWorldOfWarcraft': 'World of Warcraft',
      };

      for (final entry in exactSame.entries) {
        final key = entry.key;
        final expected = entry.value;
        expect(
          enMessages[key],
          expected,
          reason: 'Unexpected EN value for $key',
        );
        expect(
          esMessages[key],
          expected,
          reason: 'Unexpected ES value for $key',
        );
      }

      expect(esMessages['bestMythicRuns'], contains('Mythic+'));
      expect(esMessages['itemLevel'], contains('{ilvl}'));

      const forbiddenEsTerms = <String>['mítica+', 'míticas+'];
      for (final key in ['mythicPlus', 'bestMythicRuns']) {
        final value = (esMessages[key] ?? '').toLowerCase();
        for (final forbidden in forbiddenEsTerms) {
          expect(
            value,
            isNot(contains(forbidden)),
            reason: 'Found forbidden term "$forbidden" in key "$key"',
          );
        }
      }
    });

    test('critical ES labels are not left in English', () {
      const mustBeLocalized = <String>[
        'slot',
        'slotClearSlot',
        'buildsSlots',
        'buildIntelligenceTitle',
        'buildIntelligenceTopActions',
        'buildIntelligenceEquippedItems',
        'buildIntelligenceActionEnchantMissing',
      ];

      for (final key in mustBeLocalized) {
        expect(
          esMessages[key],
          isNot(enMessages[key]),
          reason: 'Expected key "$key" to be localized in ES',
        );
      }

      const forbiddenFragments = <String>[
        'weekly',
        'planner',
        'checklist',
        'top actions',
        'apply',
        'complete',
        'remaining',
        'slot',
      ];

      for (final key in mustBeLocalized) {
        final raw = (esMessages[key] ?? '').toLowerCase();
        final sanitized = raw.replaceAll(RegExp(r'\{[^}]+\}'), '');
        for (final fragment in forbiddenFragments) {
          expect(
            sanitized,
            isNot(contains(fragment)),
            reason:
                'Found English fragment "$fragment" in localized key "$key"',
          );
        }
      }
    });
  });
}
