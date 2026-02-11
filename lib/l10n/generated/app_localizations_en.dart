// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'WoW Companion';

  @override
  String get home => 'Home';

  @override
  String get favorites => 'Favorites';

  @override
  String get items => 'Items';

  @override
  String get guides => 'Guides';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Character name';

  @override
  String get realmHint => 'Realm (e.g. Sargeras)';

  @override
  String get lookUpCharacter => 'Look Up Character';

  @override
  String get compareCharacters => 'Compare Characters';

  @override
  String get compare => 'Compare';

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get clearAll => 'Clear all';

  @override
  String get regionEurope => 'Europe';

  @override
  String get regionAmericas => 'Americas';

  @override
  String get regionKorea => 'Korea';

  @override
  String get regionTaiwan => 'Taiwan';

  @override
  String level(int level) {
    return 'Level $level';
  }

  @override
  String itemLevel(int ilvl) {
    return 'Item Level $ilvl';
  }

  @override
  String get ilvl => 'iLvl';

  @override
  String get character => 'Character';

  @override
  String get equipment => 'Equipment';

  @override
  String get mythicPlus => 'Mythic+';

  @override
  String get rating => 'Rating';

  @override
  String get raid => 'Raid';

  @override
  String get raidProgression => 'Raid Progression';

  @override
  String get bestMythicRuns => 'Best Mythic+ Runs';

  @override
  String get dungeon => 'Dungeon';

  @override
  String get lvl => 'Lvl';

  @override
  String get time => 'Time';

  @override
  String get score => 'Score';

  @override
  String get noEnchantmentsOrGems => 'No enchantments or gems';

  @override
  String get viewOnWowhead => 'View on Wowhead';

  @override
  String get comparison => 'Comparison';

  @override
  String get loadingCharacter => 'Loading character...';

  @override
  String get loadingBothCharacters => 'Loading both characters...';

  @override
  String get loadingGuide => 'Loading guide...';

  @override
  String get characterNotFound =>
      'Character not found. Check region, realm and name.';

  @override
  String get checkRealmAndName =>
      'Check the region, realm, and character name.';

  @override
  String get enterRealmAndName => 'Please enter both realm and character name';

  @override
  String get retry => 'Retry';

  @override
  String get equipmentComparison => 'Equipment Comparison';

  @override
  String get char1 => 'Char 1';

  @override
  String get char2 => 'Char 2';

  @override
  String get quickCheatsheets => 'Quick Cheatsheets';

  @override
  String get cheatsheetsSubtitle =>
      'Stat priorities, rotations & consumables at a glance';

  @override
  String get all => 'All';

  @override
  String get dps => 'DPS';

  @override
  String get healer => 'Healer';

  @override
  String get tank => 'Tank';

  @override
  String get statPriority => 'Stat Priority';

  @override
  String get rotation => 'Rotation / Priority';

  @override
  String get consumables => 'Consumables';

  @override
  String get tips => 'Tips';

  @override
  String lastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get guideNotFound => 'Guide not found.';

  @override
  String get normal => 'Normal';

  @override
  String get heroic => 'Heroic';

  @override
  String get mythic => 'Mythic';

  @override
  String get progression => 'Progression';

  @override
  String get region => 'Region';

  @override
  String get realm => 'Realm';

  @override
  String get characterName => 'Character Name';

  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String get favoritesHint => 'Search for a character and tap ★ to save';

  @override
  String get itemCatalog => 'Item Catalog';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get character1 => 'Character 1';

  @override
  String get character2 => 'Character 2';

  @override
  String get slot => 'Slot';

  @override
  String get vs => 'VS';
}
