import 'package:wow_companion/core/l10n/wow_translations.dart';

const wowClasses = <String>[
  'Death Knight',
  'Demon Hunter',
  'Druid',
  'Evoker',
  'Hunter',
  'Mage',
  'Monk',
  'Paladin',
  'Priest',
  'Rogue',
  'Shaman',
  'Warlock',
  'Warrior',
];

const wowSpecsByClass = <String, List<String>>{
  'Death Knight': ['Blood', 'Frost', 'Unholy'],
  'Demon Hunter': ['Devourer', 'Havoc', 'Vengeance'],
  'Druid': ['Balance', 'Feral', 'Guardian', 'Restoration'],
  'Evoker': ['Augmentation', 'Devastation', 'Preservation'],
  'Hunter': ['Beast Mastery', 'Marksmanship', 'Survival'],
  'Mage': ['Arcane', 'Fire', 'Frost'],
  'Monk': ['Brewmaster', 'Mistweaver', 'Windwalker'],
  'Paladin': ['Holy', 'Protection', 'Retribution'],
  'Priest': ['Discipline', 'Holy', 'Shadow'],
  'Rogue': ['Assassination', 'Outlaw', 'Subtlety'],
  'Shaman': ['Elemental', 'Enhancement', 'Restoration'],
  'Warlock': ['Affliction', 'Demonology', 'Destruction'],
  'Warrior': ['Arms', 'Fury', 'Protection'],
};

String? canonicalWowClass(String? className) {
  if (className == null || className.trim().isEmpty) return null;
  final canonical = WowTranslations.canonicalizeClass(className);
  return wowSpecsByClass.containsKey(canonical) ? canonical : null;
}

String? canonicalWowSpec(String? className, String? specName) {
  final canonicalClass = canonicalWowClass(className);
  if (canonicalClass == null) return null;
  final canonical = WowTranslations.canonicalizeSpec(
    specName,
    className: canonicalClass,
  );
  if (canonical == null) return null;
  return wowSpecsByClass[canonicalClass]?.contains(canonical) == true
      ? canonical
      : null;
}

List<String> specsForClass(String? className) {
  final canonicalClass = canonicalWowClass(className);
  if (canonicalClass == null) return const <String>[];
  return wowSpecsByClass[canonicalClass] ?? const <String>[];
}

bool isValidSpecForClass(String className, String? specName) {
  return canonicalWowSpec(className, specName) != null;
}
