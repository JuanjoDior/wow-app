/// Translation and normalization helpers for WoW game data.
///
/// Domain values should be stored canonically in English. These helpers accept
/// either EN or ES input and return the right display value for the active
/// locale.
class WowTranslations {
  WowTranslations._();

  static const Map<String, String> classes = {
    'Warrior': 'Guerrero',
    'Paladin': 'Paladín',
    'Hunter': 'Cazador',
    'Rogue': 'Pícaro',
    'Priest': 'Sacerdote',
    'Death Knight': 'Caballero de la Muerte',
    'Shaman': 'Chamán',
    'Mage': 'Mago',
    'Warlock': 'Brujo',
    'Monk': 'Monje',
    'Druid': 'Druida',
    'Demon Hunter': 'Cazador de Demonios',
    'Evoker': 'Evocador',
  };

  static const Map<String, String> specs = {
    'Arms': 'Armas',
    'Fury': 'Furia',
    'Protection': 'Protección',
    'Holy': 'Sagrado',
    'Retribution': 'Reprensión',
    'Beast Mastery': 'Dominio de bestias',
    'Marksmanship': 'Puntería',
    'Survival': 'Supervivencia',
    'Assassination': 'Asesinato',
    'Outlaw': 'Forajido',
    'Subtlety': 'Sutileza',
    'Discipline': 'Disciplina',
    'Shadow': 'Sombras',
    'Blood': 'Sangre',
    'Frost': 'Escarcha',
    'Unholy': 'Profano',
    'Elemental': 'Elemental',
    'Enhancement': 'Mejora',
    'Restoration': 'Restauración',
    'Arcane': 'Arcano',
    'Fire': 'Fuego',
    'Affliction': 'Aflicción',
    'Demonology': 'Demonología',
    'Destruction': 'Destrucción',
    'Brewmaster': 'Maestro cervecero',
    'Mistweaver': 'Tejedor de niebla',
    'Windwalker': 'Viajero del viento',
    'Balance': 'Equilibrio',
    'Feral': 'Feral',
    'Guardian': 'Guardián',
    'Devourer': 'Devorador',
    'Havoc': 'Devastación',
    'Vengeance': 'Venganza',
    'Devastation': 'Devastación',
    'Preservation': 'Preservación',
    'Augmentation': 'Aumentación',
  };

  static const Map<String, List<String>> specsByClass = {
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

  static const Map<String, String> races = {
    'Human': 'Humano',
    'Dwarf': 'Enano',
    'Night Elf': 'Elfo de la noche',
    'Gnome': 'Gnomo',
    'Draenei': 'Draenei',
    'Worgen': 'Huargen',
    'Pandaren': 'Pandaren',
    'Void Elf': 'Elfo del Vacío',
    'Lightforged Draenei': 'Draenei forjado por la Luz',
    'Dark Iron Dwarf': 'Enano Hierro Negro',
    'Kul Tiran': 'Kultirano',
    'Mechagnome': 'Mecagnomo',
    'Dracthyr': 'Dracthyr',
    'Earthen': 'Terráneo',
    'Orc': 'Orco',
    'Undead': 'No-muerto',
    'Tauren': 'Tauren',
    'Troll': 'Trol',
    'Blood Elf': 'Elfo de sangre',
    'Goblin': 'Goblin',
    'Nightborne': 'Nocheterna',
    'Highmountain Tauren': 'Tauren Monte Alto',
    "Mag'har Orc": "Orco Mag'har",
    'Zandalari Troll': 'Trol Zandalari',
    'Vulpera': 'Vulpera',
  };

  static String translateClass(String name, String languageCode) {
    final canonical = canonicalizeClass(name);
    return _translateForLocale(canonical, classes, languageCode);
  }

  static String translateSpec(
    String name,
    String languageCode, {
    String? className,
  }) {
    final canonical = canonicalizeSpec(name, className: className);
    if (canonical == null) return name;
    return _translateForLocale(canonical, specs, languageCode);
  }

  static String translateRace(String name, String languageCode) {
    final canonical = canonicalizeRace(name);
    return _translateForLocale(canonical, races, languageCode);
  }

  static String canonicalizeClass(String name) {
    return _canonicalizeSimple(name, classes) ?? name;
  }

  static String? canonicalizeSpec(String? name, {String? className}) {
    if (name == null) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final canonicalClass = className == null
        ? null
        : canonicalizeClass(className);
    final normalized = _normalize(trimmed);

    if (canonicalClass != null) {
      final candidates = specsByClass[canonicalClass] ?? const <String>[];
      for (final candidate in candidates) {
        if (_matchesCandidate(normalized, candidate, specs[candidate])) {
          return candidate;
        }
      }
    }

    final direct = _canonicalizeSimple(trimmed, specs);
    if (direct != null) return direct;

    final matches = <String>[
      for (final entry in specs.entries)
        if (_normalize(entry.value) == normalized) entry.key,
    ];
    if (matches.length == 1) return matches.first;

    return null;
  }

  static String canonicalizeRace(String name) {
    return _canonicalizeSimple(name, races) ?? name;
  }

  static String _translateForLocale(
    String canonicalValue,
    Map<String, String> map,
    String languageCode,
  ) {
    final normalized = languageCode.trim().toLowerCase();
    if (normalized != 'es') return canonicalValue;
    return map[canonicalValue] ?? canonicalValue;
  }

  static String? _canonicalizeSimple(String value, Map<String, String> map) {
    final normalized = _normalize(value);
    for (final entry in map.entries) {
      if (_normalize(entry.key) == normalized) return entry.key;
      if (_normalize(entry.value) == normalized) return entry.key;
    }
    return null;
  }

  static bool _matchesCandidate(
    String normalizedInput,
    String canonical,
    String? localized,
  ) {
    return _normalize(canonical) == normalizedInput ||
        (localized != null && _normalize(localized) == normalizedInput);
  }

  static String _normalize(String value) {
    var normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return normalized;

    const replacements = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
    };
    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });

    normalized = normalized.replaceAll(RegExp(r'[_-]+'), ' ');
    normalized = normalized.replaceAll("'", '');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    return normalized;
  }
}
