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
  String get compareRealmExample => 'e.g. sanguino';

  @override
  String get compareNameExample => 'e.g. iidrexii';

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
  String unexpectedError(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String get serverError => 'Something went wrong on the server.';

  @override
  String get serverErrorSuggestion => 'Try again in a few seconds.';

  @override
  String get networkError => 'Could not connect to the internet.';

  @override
  String get networkErrorSuggestion => 'Check your connection and try again.';

  @override
  String get cacheError => 'Could not load cached data.';

  @override
  String get cacheErrorSuggestion => 'Try refreshing.';

  @override
  String get rateLimitError => 'Too many requests.';

  @override
  String get rateLimitErrorSuggestion => 'Wait a moment and try again.';

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
  String get switchToEnglish => 'English';

  @override
  String get switchToSpanish => 'Spanish';

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
  String get health => 'Health';

  @override
  String get stamina => 'Stamina';

  @override
  String get strength => 'Strength';

  @override
  String get agility => 'Agility';

  @override
  String get intellect => 'Intellect';

  @override
  String get criticalStrike => 'Critical Strike';

  @override
  String get haste => 'Haste';

  @override
  String get mastery => 'Mastery';

  @override
  String get versatility => 'Versatility';

  @override
  String get mana => 'Mana';

  @override
  String get energy => 'Energy';

  @override
  String get rage => 'Rage';

  @override
  String get runicPower => 'Runic Power';

  @override
  String get focus => 'Focus';

  @override
  String get maelstrom => 'Maelstrom';

  @override
  String get demonHunterFury => 'Demon Hunter Fury';

  @override
  String get pain => 'Pain';

  @override
  String get essence => 'Essence';

  @override
  String get astralPower => 'Astral Power';

  @override
  String get externalRaiderIo => 'Raider.IO';

  @override
  String get externalWorldOfWarcraft => 'World of Warcraft';

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
  String get builds => 'Builds';

  @override
  String get vs => 'VS';

  @override
  String get buildsNoBuildsYet => 'No builds yet';

  @override
  String get buildsNoBuildsHint => 'Tap + to create your first build';

  @override
  String get buildsNewBuild => 'New Build';

  @override
  String get buildsBuildName => 'Build name (e.g. Rogue M+ Assassination)';

  @override
  String get buildsGenericBuild => 'Generic build (no character)';

  @override
  String get buildsNoFavoritesYet => 'No favorites saved yet';

  @override
  String get buildsLinkCharacter => 'Link to character (optional)';

  @override
  String get buildsClassAndSpec => 'Class & Spec';

  @override
  String get buildsSelectClass => 'Select class';

  @override
  String get buildsSelectSpec => 'Select spec';

  @override
  String get buildsCreate => 'Create';

  @override
  String get buildsCancel => 'Cancel';

  @override
  String get buildsDeleteTitle => 'Delete build';

  @override
  String buildsDeleteConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get buildsDelete => 'Delete';

  @override
  String buildsSlots(int obtained, int total) {
    return '$obtained/$total slots';
  }

  @override
  String get slotAssignItem => 'Assign item';

  @override
  String get slotClearSlot => 'Clear slot';

  @override
  String get slotEnchantmentLabel => 'Enchantment';

  @override
  String get slotGemsLabel => 'Gems';

  @override
  String get slotAddEnchantment => 'Add enchantment';

  @override
  String get slotRemoveEnchantment => 'Remove enchantment';

  @override
  String get slotAddGem => '+ Gem';

  @override
  String slotSearchItem(String slot) {
    return 'Search $slot';
  }

  @override
  String get slotSearchEnchantment => 'Search Enchantment';

  @override
  String get slotSearchGem => 'Search Gem';

  @override
  String get searchTypeAtLeast => 'Type at least 2 characters...';

  @override
  String get searchNoResults => 'No results';

  @override
  String get searchLoading => 'Searching...';

  @override
  String get unknownItem => 'Unknown Item';

  @override
  String get tooltipItemLevel => 'Item Level';

  @override
  String get tooltipRequiredLevel => 'Required Level';

  @override
  String get tooltipType => 'Type';

  @override
  String get wowSlotHead => 'Helm';

  @override
  String get wowSlotNeck => 'Neck';

  @override
  String get wowSlotShoulder => 'Shoulder';

  @override
  String get wowSlotBack => 'Cloak';

  @override
  String get wowSlotChest => 'Chest';

  @override
  String get wowSlotWrist => 'Bracers';

  @override
  String get wowSlotHands => 'Gloves';

  @override
  String get wowSlotWaist => 'Belt';

  @override
  String get wowSlotLegs => 'Legs';

  @override
  String get wowSlotFeet => 'Boots';

  @override
  String get wowSlotFinger1 => 'Ring #1';

  @override
  String get wowSlotFinger2 => 'Ring #2';

  @override
  String get wowSlotTrinket1 => 'Trinket #1';

  @override
  String get wowSlotTrinket2 => 'Trinket #2';

  @override
  String get wowSlotMainHand => 'Weapon Main-Hand';

  @override
  String get wowSlotOffHand => 'Weapon Off-Hand';

  @override
  String get buildNotFound => 'Build not found';

  @override
  String get buildIntelligenceTitle => 'Build Verification';

  @override
  String get buildIntelligenceSubtitle =>
      'Objective comparison of character vs your target build';

  @override
  String get buildIntelligenceNoData => 'No analysis data available.';

  @override
  String get buildIntelligenceMissingCharacter =>
      'Link a character to run analysis.';

  @override
  String get buildIntelligenceCharacterStatus => 'Verifiable character status';

  @override
  String get buildIntelligenceNoTargetHint =>
      'Add enchants and gems to your build to enable target actions.';

  @override
  String get buildIntelligenceEquippedItems => 'Equipped slots';

  @override
  String get buildIntelligenceEnchantedItems => 'Items with enchant';

  @override
  String get buildIntelligenceSockets => 'Sockets with gem';

  @override
  String get buildIntelligenceCompletion => 'Completion';

  @override
  String get buildIntelligenceMissingEnchants => 'Missing enchants';

  @override
  String get buildIntelligenceMissingGems => 'Missing gems';

  @override
  String get buildIntelligenceTopActions => 'Top actions';

  @override
  String buildIntelligenceActionEnchantMissing(String name) {
    return 'Apply $name';
  }

  @override
  String buildIntelligenceActionEnchantMismatch(String name) {
    return 'Replace enchant with $name';
  }

  @override
  String buildIntelligenceActionGemMissing(String name) {
    return 'Socket $name';
  }

  @override
  String buildIntelligenceActionGemMismatch(String name) {
    return 'Replace gem with $name';
  }

  @override
  String get economyAssistantTitle => 'Economy Assistant';

  @override
  String get economyAssistantSubtitle =>
      'Objective price snapshot for enchants, gems and consumables';

  @override
  String get economyAssistantNoData => 'No market data available.';

  @override
  String get economyAssistantEmptyBuild =>
      'Add enchants, gems or consumables to estimate costs.';

  @override
  String get economyAssistantPricedItems => 'Priced items';

  @override
  String get economyAssistantMissingItems => 'Missing prices';

  @override
  String get economyAssistantMarket => 'Market';

  @override
  String get economyAssistantTopItems => 'Top market costs';

  @override
  String get economyAssistantMedianPrice => 'Median';

  @override
  String get economyAssistantMarketCommodities => 'Commodities';

  @override
  String get economyAssistantMarketAuctions => 'Realm auctions';

  @override
  String get economyAssistantMarketUnknown => 'Unknown';

  @override
  String economyAssistantItemFallback(int id) {
    return 'Item #$id';
  }

  @override
  String get weeklyPlannerTitle => 'Weekly Planner';

  @override
  String get weeklyPlannerTooltip => 'Open Weekly Planner';

  @override
  String get weeklyPlannerUnavailable =>
      'Weekly Planner is disabled right now.';

  @override
  String get weeklyPlannerSummaryTitle => 'Weekly summary';

  @override
  String get weeklyPlannerCompletion => 'Completion';

  @override
  String get weeklyPlannerChecks => 'Checks';

  @override
  String get weeklyPlannerRuns => 'Weekly runs';

  @override
  String get weeklyPlannerRating => 'Rating';

  @override
  String get weeklyPlannerAffixes => 'Affixes';

  @override
  String get weeklyPlannerNoAffixes => 'No affix data available yet.';

  @override
  String get weeklyPlannerChecklist => 'Checklist';

  @override
  String get weeklyPlannerResetLocalProgress => 'Reset local progress';

  @override
  String get weeklyPlannerObjectiveCompleted => 'Completed from character data';

  @override
  String get weeklyPlannerActions => 'Priority actions';

  @override
  String get weeklyPlannerNoActions => 'No pending actions.';

  @override
  String get weeklyPlannerTaskEnchantsCompleted => 'Apply missing enchants';

  @override
  String get weeklyPlannerTaskSocketsFilled => 'Fill empty sockets';

  @override
  String get weeklyPlannerTaskMplusOne => 'Complete at least 1 Mythic+ run';

  @override
  String get weeklyPlannerTaskMplusFour => 'Complete 4 Mythic+ runs';

  @override
  String get weeklyPlannerTaskMplusEight => 'Complete 8 Mythic+ runs';

  @override
  String weeklyPlannerActionRemaining(String label, int remaining) {
    return '$label ($remaining remaining)';
  }

  @override
  String get guideTitle => 'Build Guide';

  @override
  String get guideContent => 'Content';

  @override
  String get guideContentRaid => 'Raid';

  @override
  String get guideContentMythicPlus => 'M+';

  @override
  String get guideContentBoth => 'Both';

  @override
  String get guideHeroTalent => 'Hero Talent / Import string';

  @override
  String get guideHeroTalentHint => 'Paste your talent import string here...';

  @override
  String get guideRotation => 'Rotation';

  @override
  String guideSpellsCount(int count) {
    return '$count spells';
  }

  @override
  String get guideRotationEmpty =>
      'No spells added yet. Add your priority list.';

  @override
  String get guideAddSpell => 'Add spell';

  @override
  String get guideSearchSpell => 'Search spell';

  @override
  String get guideConsumables => 'Consumables';

  @override
  String get guideFlask => 'Flask';

  @override
  String get guidePotion => 'Potion';

  @override
  String get guideFood => 'Food';

  @override
  String get guideNotes => 'Notes';

  @override
  String get guideNotesHint => 'Situational tips, cooldown notes...';

  @override
  String get consumableTypeFlask => 'Flask';

  @override
  String get consumableTypePotion => 'Potion';

  @override
  String get consumableTypeFood => 'Food';

  @override
  String get consumableTypeRune => 'Rune';

  @override
  String get consumableTypeWeapon => 'Weapon';

  @override
  String get consumableTypeEnchant => 'Enchantment';
}
