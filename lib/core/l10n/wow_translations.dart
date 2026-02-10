/// Translation mappings for WoW game data (EN → ES).
/// Expand as needed with more classes, races, specs, etc.
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
    // Warrior
    'Arms': 'Armas',
    'Fury': 'Furia',
    'Protection': 'Protección',
    // Paladin
    'Holy': 'Sagrado',
    'Retribution': 'Reprensión',
    // Hunter
    'Beast Mastery': 'Dominio de bestias',
    'Marksmanship': 'Puntería',
    'Survival': 'Supervivencia',
    // Rogue
    'Assassination': 'Asesinato',
    'Outlaw': 'Forajido',
    'Subtlety': 'Sutileza',
    // Priest
    'Discipline': 'Disciplina',
    'Shadow': 'Sombras',
    // Death Knight
    'Blood': 'Sangre',
    'Frost': 'Escarcha',
    'Unholy': 'Profano',
    // Shaman
    'Elemental': 'Elemental',
    'Enhancement': 'Mejora',
    'Restoration': 'Restauración',
    // Mage
    'Arcane': 'Arcano',
    'Fire': 'Fuego',
    // Warlock
    'Affliction': 'Aflicción',
    'Demonology': 'Demonología',
    'Destruction': 'Destrucción',
    // Monk
    'Brewmaster': 'Maestro cervecero',
    'Mistweaver': 'Tejedor de niebla',
    'Windwalker': 'Viajero del viento',
    // Druid
    'Balance': 'Equilibrio',
    'Feral': 'Feral',
    'Guardian': 'Guardián',
    // Demon Hunter
    'Havoc': 'Devastación',
    'Vengeance': 'Venganza',
    // Evoker
    'Devastation': 'Devastación',
    'Preservation': 'Preservación',
    'Augmentation': 'Aumentación',
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
    'Kul Tiran': 'Kultireno',
    'Mechagnome': 'Mecagnomo',
    'Dracthyr': 'Dracthyr',
    'Earthen': 'Terrino',
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

  /// Translate a value using the given map. Returns original if no translation found.
  static String translate(String value, Map<String, String> map) {
    return map[value] ?? value;
  }

  static String translateClass(String name) => translate(name, classes);
  static String translateSpec(String name) => translate(name, specs);
  static String translateRace(String name) => translate(name, races);
}
