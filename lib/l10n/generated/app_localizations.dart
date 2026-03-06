import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'WoW Companion'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @guides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get guides;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Character name'**
  String get searchHint;

  /// No description provided for @realmHint.
  ///
  /// In en, this message translates to:
  /// **'Realm (e.g. Sargeras)'**
  String get realmHint;

  /// No description provided for @lookUpCharacter.
  ///
  /// In en, this message translates to:
  /// **'Look Up Character'**
  String get lookUpCharacter;

  /// No description provided for @compareCharacters.
  ///
  /// In en, this message translates to:
  /// **'Compare Characters'**
  String get compareCharacters;

  /// No description provided for @compare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compare;

  /// No description provided for @compareRealmExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. sanguino'**
  String get compareRealmExample;

  /// No description provided for @compareNameExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. iidrexii'**
  String get compareNameExample;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @regionEurope.
  ///
  /// In en, this message translates to:
  /// **'Europe'**
  String get regionEurope;

  /// No description provided for @regionAmericas.
  ///
  /// In en, this message translates to:
  /// **'Americas'**
  String get regionAmericas;

  /// No description provided for @regionKorea.
  ///
  /// In en, this message translates to:
  /// **'Korea'**
  String get regionKorea;

  /// No description provided for @regionTaiwan.
  ///
  /// In en, this message translates to:
  /// **'Taiwan'**
  String get regionTaiwan;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String level(int level);

  /// No description provided for @itemLevel.
  ///
  /// In en, this message translates to:
  /// **'Item Level {ilvl}'**
  String itemLevel(int ilvl);

  /// No description provided for @ilvl.
  ///
  /// In en, this message translates to:
  /// **'iLvl'**
  String get ilvl;

  /// No description provided for @character.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get character;

  /// No description provided for @equipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get equipment;

  /// No description provided for @mythicPlus.
  ///
  /// In en, this message translates to:
  /// **'Mythic+'**
  String get mythicPlus;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @raid.
  ///
  /// In en, this message translates to:
  /// **'Raid'**
  String get raid;

  /// No description provided for @raidProgression.
  ///
  /// In en, this message translates to:
  /// **'Raid Progression'**
  String get raidProgression;

  /// No description provided for @bestMythicRuns.
  ///
  /// In en, this message translates to:
  /// **'Best Mythic+ Runs'**
  String get bestMythicRuns;

  /// No description provided for @dungeon.
  ///
  /// In en, this message translates to:
  /// **'Dungeon'**
  String get dungeon;

  /// No description provided for @lvl.
  ///
  /// In en, this message translates to:
  /// **'Lvl'**
  String get lvl;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @noEnchantmentsOrGems.
  ///
  /// In en, this message translates to:
  /// **'No enchantments or gems'**
  String get noEnchantmentsOrGems;

  /// No description provided for @viewOnWowhead.
  ///
  /// In en, this message translates to:
  /// **'View on Wowhead'**
  String get viewOnWowhead;

  /// No description provided for @comparison.
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get comparison;

  /// No description provided for @loadingCharacter.
  ///
  /// In en, this message translates to:
  /// **'Loading character...'**
  String get loadingCharacter;

  /// No description provided for @loadingBothCharacters.
  ///
  /// In en, this message translates to:
  /// **'Loading both characters...'**
  String get loadingBothCharacters;

  /// No description provided for @loadingGuide.
  ///
  /// In en, this message translates to:
  /// **'Loading guide...'**
  String get loadingGuide;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String unexpectedError(String error);

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on the server.'**
  String get serverError;

  /// No description provided for @serverErrorSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Try again in a few seconds.'**
  String get serverErrorSuggestion;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the internet.'**
  String get networkError;

  /// No description provided for @networkErrorSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get networkErrorSuggestion;

  /// No description provided for @cacheError.
  ///
  /// In en, this message translates to:
  /// **'Could not load cached data.'**
  String get cacheError;

  /// No description provided for @cacheErrorSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Try refreshing.'**
  String get cacheErrorSuggestion;

  /// No description provided for @rateLimitError.
  ///
  /// In en, this message translates to:
  /// **'Too many requests.'**
  String get rateLimitError;

  /// No description provided for @rateLimitErrorSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Wait a moment and try again.'**
  String get rateLimitErrorSuggestion;

  /// No description provided for @characterNotFound.
  ///
  /// In en, this message translates to:
  /// **'Character not found. Check region, realm and name.'**
  String get characterNotFound;

  /// No description provided for @checkRealmAndName.
  ///
  /// In en, this message translates to:
  /// **'Check the region, realm, and character name.'**
  String get checkRealmAndName;

  /// No description provided for @enterRealmAndName.
  ///
  /// In en, this message translates to:
  /// **'Please enter both realm and character name'**
  String get enterRealmAndName;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @switchToEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get switchToEnglish;

  /// No description provided for @switchToSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get switchToSpanish;

  /// No description provided for @equipmentComparison.
  ///
  /// In en, this message translates to:
  /// **'Equipment Comparison'**
  String get equipmentComparison;

  /// No description provided for @char1.
  ///
  /// In en, this message translates to:
  /// **'Char 1'**
  String get char1;

  /// No description provided for @char2.
  ///
  /// In en, this message translates to:
  /// **'Char 2'**
  String get char2;

  /// No description provided for @quickCheatsheets.
  ///
  /// In en, this message translates to:
  /// **'Quick Cheatsheets'**
  String get quickCheatsheets;

  /// No description provided for @cheatsheetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stat priorities, rotations & consumables at a glance'**
  String get cheatsheetsSubtitle;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @dps.
  ///
  /// In en, this message translates to:
  /// **'DPS'**
  String get dps;

  /// No description provided for @healer.
  ///
  /// In en, this message translates to:
  /// **'Healer'**
  String get healer;

  /// No description provided for @tank.
  ///
  /// In en, this message translates to:
  /// **'Tank'**
  String get tank;

  /// No description provided for @statPriority.
  ///
  /// In en, this message translates to:
  /// **'Stat Priority'**
  String get statPriority;

  /// No description provided for @rotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation / Priority'**
  String get rotation;

  /// No description provided for @consumables.
  ///
  /// In en, this message translates to:
  /// **'Consumables'**
  String get consumables;

  /// No description provided for @tips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tips;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @stamina.
  ///
  /// In en, this message translates to:
  /// **'Stamina'**
  String get stamina;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get strength;

  /// No description provided for @agility.
  ///
  /// In en, this message translates to:
  /// **'Agility'**
  String get agility;

  /// No description provided for @intellect.
  ///
  /// In en, this message translates to:
  /// **'Intellect'**
  String get intellect;

  /// No description provided for @criticalStrike.
  ///
  /// In en, this message translates to:
  /// **'Critical Strike'**
  String get criticalStrike;

  /// No description provided for @haste.
  ///
  /// In en, this message translates to:
  /// **'Haste'**
  String get haste;

  /// No description provided for @mastery.
  ///
  /// In en, this message translates to:
  /// **'Mastery'**
  String get mastery;

  /// No description provided for @versatility.
  ///
  /// In en, this message translates to:
  /// **'Versatility'**
  String get versatility;

  /// No description provided for @mana.
  ///
  /// In en, this message translates to:
  /// **'Mana'**
  String get mana;

  /// No description provided for @energy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energy;

  /// No description provided for @rage.
  ///
  /// In en, this message translates to:
  /// **'Rage'**
  String get rage;

  /// No description provided for @runicPower.
  ///
  /// In en, this message translates to:
  /// **'Runic Power'**
  String get runicPower;

  /// No description provided for @focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// No description provided for @maelstrom.
  ///
  /// In en, this message translates to:
  /// **'Maelstrom'**
  String get maelstrom;

  /// No description provided for @demonHunterFury.
  ///
  /// In en, this message translates to:
  /// **'Demon Hunter Fury'**
  String get demonHunterFury;

  /// No description provided for @pain.
  ///
  /// In en, this message translates to:
  /// **'Pain'**
  String get pain;

  /// No description provided for @essence.
  ///
  /// In en, this message translates to:
  /// **'Essence'**
  String get essence;

  /// No description provided for @astralPower.
  ///
  /// In en, this message translates to:
  /// **'Astral Power'**
  String get astralPower;

  /// No description provided for @externalRaiderIo.
  ///
  /// In en, this message translates to:
  /// **'Raider.IO'**
  String get externalRaiderIo;

  /// No description provided for @externalWorldOfWarcraft.
  ///
  /// In en, this message translates to:
  /// **'World of Warcraft'**
  String get externalWorldOfWarcraft;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String lastUpdated(String date);

  /// No description provided for @guideNotFound.
  ///
  /// In en, this message translates to:
  /// **'Guide not found.'**
  String get guideNotFound;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @heroic.
  ///
  /// In en, this message translates to:
  /// **'Heroic'**
  String get heroic;

  /// No description provided for @mythic.
  ///
  /// In en, this message translates to:
  /// **'Mythic'**
  String get mythic;

  /// No description provided for @progression.
  ///
  /// In en, this message translates to:
  /// **'Progression'**
  String get progression;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @realm.
  ///
  /// In en, this message translates to:
  /// **'Realm'**
  String get realm;

  /// No description provided for @characterName.
  ///
  /// In en, this message translates to:
  /// **'Character Name'**
  String get characterName;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// No description provided for @favoritesHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a character and tap ★ to save'**
  String get favoritesHint;

  /// No description provided for @itemCatalog.
  ///
  /// In en, this message translates to:
  /// **'Item Catalog'**
  String get itemCatalog;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @character1.
  ///
  /// In en, this message translates to:
  /// **'Character 1'**
  String get character1;

  /// No description provided for @character2.
  ///
  /// In en, this message translates to:
  /// **'Character 2'**
  String get character2;

  /// No description provided for @slot.
  ///
  /// In en, this message translates to:
  /// **'Slot'**
  String get slot;

  /// No description provided for @builds.
  ///
  /// In en, this message translates to:
  /// **'Builds'**
  String get builds;

  /// No description provided for @vs.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get vs;

  /// No description provided for @buildsNoBuildsYet.
  ///
  /// In en, this message translates to:
  /// **'No builds yet'**
  String get buildsNoBuildsYet;

  /// No description provided for @buildsNoBuildsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first build'**
  String get buildsNoBuildsHint;

  /// No description provided for @buildsNewBuild.
  ///
  /// In en, this message translates to:
  /// **'New Build'**
  String get buildsNewBuild;

  /// No description provided for @buildsBuildName.
  ///
  /// In en, this message translates to:
  /// **'Build name (e.g. Rogue M+ Assassination)'**
  String get buildsBuildName;

  /// No description provided for @buildsGenericBuild.
  ///
  /// In en, this message translates to:
  /// **'Generic build (no character)'**
  String get buildsGenericBuild;

  /// No description provided for @buildsNoFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites saved yet'**
  String get buildsNoFavoritesYet;

  /// No description provided for @buildsLinkCharacter.
  ///
  /// In en, this message translates to:
  /// **'Link to character (optional)'**
  String get buildsLinkCharacter;

  /// No description provided for @buildsClassAndSpec.
  ///
  /// In en, this message translates to:
  /// **'Class & Spec'**
  String get buildsClassAndSpec;

  /// No description provided for @buildsSelectClass.
  ///
  /// In en, this message translates to:
  /// **'Select class'**
  String get buildsSelectClass;

  /// No description provided for @buildsSelectSpec.
  ///
  /// In en, this message translates to:
  /// **'Select spec'**
  String get buildsSelectSpec;

  /// No description provided for @buildsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get buildsCreate;

  /// No description provided for @buildsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buildsCancel;

  /// No description provided for @buildsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete build'**
  String get buildsDeleteTitle;

  /// No description provided for @buildsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String buildsDeleteConfirm(String name);

  /// No description provided for @buildsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get buildsDelete;

  /// No description provided for @buildsSlots.
  ///
  /// In en, this message translates to:
  /// **'{obtained}/{total} slots'**
  String buildsSlots(int obtained, int total);

  /// No description provided for @slotAssignItem.
  ///
  /// In en, this message translates to:
  /// **'Assign item'**
  String get slotAssignItem;

  /// No description provided for @slotClearSlot.
  ///
  /// In en, this message translates to:
  /// **'Clear slot'**
  String get slotClearSlot;

  /// No description provided for @slotEnchantmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Enchantment'**
  String get slotEnchantmentLabel;

  /// No description provided for @slotGemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Gems'**
  String get slotGemsLabel;

  /// No description provided for @slotAddEnchantment.
  ///
  /// In en, this message translates to:
  /// **'Add enchantment'**
  String get slotAddEnchantment;

  /// No description provided for @slotRemoveEnchantment.
  ///
  /// In en, this message translates to:
  /// **'Remove enchantment'**
  String get slotRemoveEnchantment;

  /// No description provided for @slotAddGem.
  ///
  /// In en, this message translates to:
  /// **'+ Gem'**
  String get slotAddGem;

  /// No description provided for @slotSearchItem.
  ///
  /// In en, this message translates to:
  /// **'Search {slot}'**
  String slotSearchItem(String slot);

  /// No description provided for @slotSearchEnchantment.
  ///
  /// In en, this message translates to:
  /// **'Search Enchantment'**
  String get slotSearchEnchantment;

  /// No description provided for @slotSearchGem.
  ///
  /// In en, this message translates to:
  /// **'Search Gem'**
  String get slotSearchGem;

  /// No description provided for @searchTypeAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters...'**
  String get searchTypeAtLeast;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchNoResults;

  /// No description provided for @searchLoading.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searchLoading;

  /// No description provided for @unknownItem.
  ///
  /// In en, this message translates to:
  /// **'Unknown Item'**
  String get unknownItem;

  /// No description provided for @tooltipItemLevel.
  ///
  /// In en, this message translates to:
  /// **'Item Level'**
  String get tooltipItemLevel;

  /// No description provided for @tooltipRequiredLevel.
  ///
  /// In en, this message translates to:
  /// **'Required Level'**
  String get tooltipRequiredLevel;

  /// No description provided for @tooltipType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get tooltipType;

  /// No description provided for @wowSlotHead.
  ///
  /// In en, this message translates to:
  /// **'Helm'**
  String get wowSlotHead;

  /// No description provided for @wowSlotNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get wowSlotNeck;

  /// No description provided for @wowSlotShoulder.
  ///
  /// In en, this message translates to:
  /// **'Shoulder'**
  String get wowSlotShoulder;

  /// No description provided for @wowSlotBack.
  ///
  /// In en, this message translates to:
  /// **'Cloak'**
  String get wowSlotBack;

  /// No description provided for @wowSlotChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get wowSlotChest;

  /// No description provided for @wowSlotWrist.
  ///
  /// In en, this message translates to:
  /// **'Bracers'**
  String get wowSlotWrist;

  /// No description provided for @wowSlotHands.
  ///
  /// In en, this message translates to:
  /// **'Gloves'**
  String get wowSlotHands;

  /// No description provided for @wowSlotWaist.
  ///
  /// In en, this message translates to:
  /// **'Belt'**
  String get wowSlotWaist;

  /// No description provided for @wowSlotLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get wowSlotLegs;

  /// No description provided for @wowSlotFeet.
  ///
  /// In en, this message translates to:
  /// **'Boots'**
  String get wowSlotFeet;

  /// No description provided for @wowSlotFinger1.
  ///
  /// In en, this message translates to:
  /// **'Ring #1'**
  String get wowSlotFinger1;

  /// No description provided for @wowSlotFinger2.
  ///
  /// In en, this message translates to:
  /// **'Ring #2'**
  String get wowSlotFinger2;

  /// No description provided for @wowSlotTrinket1.
  ///
  /// In en, this message translates to:
  /// **'Trinket #1'**
  String get wowSlotTrinket1;

  /// No description provided for @wowSlotTrinket2.
  ///
  /// In en, this message translates to:
  /// **'Trinket #2'**
  String get wowSlotTrinket2;

  /// No description provided for @wowSlotMainHand.
  ///
  /// In en, this message translates to:
  /// **'Weapon Main-Hand'**
  String get wowSlotMainHand;

  /// No description provided for @wowSlotOffHand.
  ///
  /// In en, this message translates to:
  /// **'Weapon Off-Hand'**
  String get wowSlotOffHand;

  /// No description provided for @buildNotFound.
  ///
  /// In en, this message translates to:
  /// **'Build not found'**
  String get buildNotFound;

  /// No description provided for @buildIntelligenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Build Verification'**
  String get buildIntelligenceTitle;

  /// No description provided for @buildIntelligenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Objective comparison of character vs your target build'**
  String get buildIntelligenceSubtitle;

  /// No description provided for @buildIntelligenceNoData.
  ///
  /// In en, this message translates to:
  /// **'No analysis data available.'**
  String get buildIntelligenceNoData;

  /// No description provided for @buildIntelligenceMissingCharacter.
  ///
  /// In en, this message translates to:
  /// **'Link a character to run analysis.'**
  String get buildIntelligenceMissingCharacter;

  /// No description provided for @buildIntelligenceCharacterStatus.
  ///
  /// In en, this message translates to:
  /// **'Verifiable character status'**
  String get buildIntelligenceCharacterStatus;

  /// No description provided for @buildIntelligenceNoTargetHint.
  ///
  /// In en, this message translates to:
  /// **'Add enchants and gems to your build to enable target actions.'**
  String get buildIntelligenceNoTargetHint;

  /// No description provided for @buildIntelligenceEquippedItems.
  ///
  /// In en, this message translates to:
  /// **'Equipped slots'**
  String get buildIntelligenceEquippedItems;

  /// No description provided for @buildIntelligenceEnchantedItems.
  ///
  /// In en, this message translates to:
  /// **'Items with enchant'**
  String get buildIntelligenceEnchantedItems;

  /// No description provided for @buildIntelligenceSockets.
  ///
  /// In en, this message translates to:
  /// **'Sockets with gem'**
  String get buildIntelligenceSockets;

  /// No description provided for @buildIntelligenceCompletion.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get buildIntelligenceCompletion;

  /// No description provided for @buildIntelligenceMissingEnchants.
  ///
  /// In en, this message translates to:
  /// **'Missing enchants'**
  String get buildIntelligenceMissingEnchants;

  /// No description provided for @buildIntelligenceMissingGems.
  ///
  /// In en, this message translates to:
  /// **'Missing gems'**
  String get buildIntelligenceMissingGems;

  /// No description provided for @buildIntelligenceTopActions.
  ///
  /// In en, this message translates to:
  /// **'Top actions'**
  String get buildIntelligenceTopActions;

  /// No description provided for @buildIntelligenceActionEnchantMissing.
  ///
  /// In en, this message translates to:
  /// **'Apply {name}'**
  String buildIntelligenceActionEnchantMissing(String name);

  /// No description provided for @buildIntelligenceActionEnchantMismatch.
  ///
  /// In en, this message translates to:
  /// **'Replace enchant with {name}'**
  String buildIntelligenceActionEnchantMismatch(String name);

  /// No description provided for @buildIntelligenceActionGemMissing.
  ///
  /// In en, this message translates to:
  /// **'Socket {name}'**
  String buildIntelligenceActionGemMissing(String name);

  /// No description provided for @buildIntelligenceActionGemMismatch.
  ///
  /// In en, this message translates to:
  /// **'Replace gem with {name}'**
  String buildIntelligenceActionGemMismatch(String name);

  /// No description provided for @economyAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Economy Assistant'**
  String get economyAssistantTitle;

  /// No description provided for @economyAssistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Objective price snapshot for enchants, gems and consumables'**
  String get economyAssistantSubtitle;

  /// No description provided for @economyAssistantNoData.
  ///
  /// In en, this message translates to:
  /// **'No market data available.'**
  String get economyAssistantNoData;

  /// No description provided for @economyAssistantEmptyBuild.
  ///
  /// In en, this message translates to:
  /// **'Add enchants, gems or consumables to estimate costs.'**
  String get economyAssistantEmptyBuild;

  /// No description provided for @economyAssistantPricedItems.
  ///
  /// In en, this message translates to:
  /// **'Priced items'**
  String get economyAssistantPricedItems;

  /// No description provided for @economyAssistantMissingItems.
  ///
  /// In en, this message translates to:
  /// **'Missing prices'**
  String get economyAssistantMissingItems;

  /// No description provided for @economyAssistantMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get economyAssistantMarket;

  /// No description provided for @economyAssistantTopItems.
  ///
  /// In en, this message translates to:
  /// **'Top market costs'**
  String get economyAssistantTopItems;

  /// No description provided for @economyAssistantMedianPrice.
  ///
  /// In en, this message translates to:
  /// **'Median'**
  String get economyAssistantMedianPrice;

  /// No description provided for @economyAssistantMarketCommodities.
  ///
  /// In en, this message translates to:
  /// **'Commodities'**
  String get economyAssistantMarketCommodities;

  /// No description provided for @economyAssistantMarketAuctions.
  ///
  /// In en, this message translates to:
  /// **'Realm auctions'**
  String get economyAssistantMarketAuctions;

  /// No description provided for @economyAssistantMarketUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get economyAssistantMarketUnknown;

  /// No description provided for @economyAssistantItemFallback.
  ///
  /// In en, this message translates to:
  /// **'Item #{id}'**
  String economyAssistantItemFallback(int id);

  /// No description provided for @weeklyPlannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Planner'**
  String get weeklyPlannerTitle;

  /// No description provided for @weeklyPlannerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open Weekly Planner'**
  String get weeklyPlannerTooltip;

  /// No description provided for @weeklyPlannerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weekly Planner is disabled right now.'**
  String get weeklyPlannerUnavailable;

  /// No description provided for @weeklyPlannerSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary'**
  String get weeklyPlannerSummaryTitle;

  /// No description provided for @weeklyPlannerCompletion.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get weeklyPlannerCompletion;

  /// No description provided for @weeklyPlannerChecks.
  ///
  /// In en, this message translates to:
  /// **'Checks'**
  String get weeklyPlannerChecks;

  /// No description provided for @weeklyPlannerRuns.
  ///
  /// In en, this message translates to:
  /// **'Weekly runs'**
  String get weeklyPlannerRuns;

  /// No description provided for @weeklyPlannerRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get weeklyPlannerRating;

  /// No description provided for @weeklyPlannerAffixes.
  ///
  /// In en, this message translates to:
  /// **'Affixes'**
  String get weeklyPlannerAffixes;

  /// No description provided for @weeklyPlannerNoAffixes.
  ///
  /// In en, this message translates to:
  /// **'No affix data available yet.'**
  String get weeklyPlannerNoAffixes;

  /// No description provided for @weeklyPlannerChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get weeklyPlannerChecklist;

  /// No description provided for @weeklyPlannerResetLocalProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset local progress'**
  String get weeklyPlannerResetLocalProgress;

  /// No description provided for @weeklyPlannerObjectiveCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed from character data'**
  String get weeklyPlannerObjectiveCompleted;

  /// No description provided for @weeklyPlannerActions.
  ///
  /// In en, this message translates to:
  /// **'Priority actions'**
  String get weeklyPlannerActions;

  /// No description provided for @weeklyPlannerNoActions.
  ///
  /// In en, this message translates to:
  /// **'No pending actions.'**
  String get weeklyPlannerNoActions;

  /// No description provided for @weeklyPlannerTaskEnchantsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Apply missing enchants'**
  String get weeklyPlannerTaskEnchantsCompleted;

  /// No description provided for @weeklyPlannerTaskSocketsFilled.
  ///
  /// In en, this message translates to:
  /// **'Fill empty sockets'**
  String get weeklyPlannerTaskSocketsFilled;

  /// No description provided for @weeklyPlannerTaskMplusOne.
  ///
  /// In en, this message translates to:
  /// **'Complete at least 1 Mythic+ run'**
  String get weeklyPlannerTaskMplusOne;

  /// No description provided for @weeklyPlannerTaskMplusFour.
  ///
  /// In en, this message translates to:
  /// **'Complete 4 Mythic+ runs'**
  String get weeklyPlannerTaskMplusFour;

  /// No description provided for @weeklyPlannerTaskMplusEight.
  ///
  /// In en, this message translates to:
  /// **'Complete 8 Mythic+ runs'**
  String get weeklyPlannerTaskMplusEight;

  /// No description provided for @weeklyPlannerActionRemaining.
  ///
  /// In en, this message translates to:
  /// **'{label} ({remaining} remaining)'**
  String weeklyPlannerActionRemaining(String label, int remaining);

  /// No description provided for @guideTitle.
  ///
  /// In en, this message translates to:
  /// **'Build Guide'**
  String get guideTitle;

  /// No description provided for @guideContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get guideContent;

  /// No description provided for @guideContentRaid.
  ///
  /// In en, this message translates to:
  /// **'Raid'**
  String get guideContentRaid;

  /// No description provided for @guideContentMythicPlus.
  ///
  /// In en, this message translates to:
  /// **'M+'**
  String get guideContentMythicPlus;

  /// No description provided for @guideContentBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get guideContentBoth;

  /// No description provided for @guideHeroTalent.
  ///
  /// In en, this message translates to:
  /// **'Hero Talent / Import string'**
  String get guideHeroTalent;

  /// No description provided for @guideHeroTalentHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your talent import string here...'**
  String get guideHeroTalentHint;

  /// No description provided for @guideRotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get guideRotation;

  /// No description provided for @guideSpellsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} spells'**
  String guideSpellsCount(int count);

  /// No description provided for @guideRotationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No spells added yet. Add your priority list.'**
  String get guideRotationEmpty;

  /// No description provided for @guideAddSpell.
  ///
  /// In en, this message translates to:
  /// **'Add spell'**
  String get guideAddSpell;

  /// No description provided for @guideSearchSpell.
  ///
  /// In en, this message translates to:
  /// **'Search spell'**
  String get guideSearchSpell;

  /// No description provided for @guideConsumables.
  ///
  /// In en, this message translates to:
  /// **'Consumables'**
  String get guideConsumables;

  /// No description provided for @guideFlask.
  ///
  /// In en, this message translates to:
  /// **'Flask'**
  String get guideFlask;

  /// No description provided for @guidePotion.
  ///
  /// In en, this message translates to:
  /// **'Potion'**
  String get guidePotion;

  /// No description provided for @guideFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get guideFood;

  /// No description provided for @guideNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get guideNotes;

  /// No description provided for @guideNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Situational tips, cooldown notes...'**
  String get guideNotesHint;

  /// No description provided for @consumableTypeFlask.
  ///
  /// In en, this message translates to:
  /// **'Flask'**
  String get consumableTypeFlask;

  /// No description provided for @consumableTypePotion.
  ///
  /// In en, this message translates to:
  /// **'Potion'**
  String get consumableTypePotion;

  /// No description provided for @consumableTypeFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get consumableTypeFood;

  /// No description provided for @consumableTypeRune.
  ///
  /// In en, this message translates to:
  /// **'Rune'**
  String get consumableTypeRune;

  /// No description provided for @consumableTypeWeapon.
  ///
  /// In en, this message translates to:
  /// **'Weapon'**
  String get consumableTypeWeapon;

  /// No description provided for @consumableTypeEnchant.
  ///
  /// In en, this message translates to:
  /// **'Enchantment'**
  String get consumableTypeEnchant;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'es':
      return SEs();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
