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
