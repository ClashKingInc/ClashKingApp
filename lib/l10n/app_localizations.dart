import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_af.dart';
import 'app_localizations_ar.dart';
import 'app_localizations_ca.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_no.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sr.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('af'),
    Locale('ar'),
    Locale('ca'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('en', 'GB'),
    Locale('en', 'US'),
    Locale('es'),
    Locale('es', 'ES'),
    Locale('fi'),
    Locale('fr'),
    Locale('he'),
    Locale('hi'),
    Locale('hu'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('no'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('sr'),
    Locale('sv'),
    Locale('tr'),
    Locale('uk'),
    Locale('vi'),
    Locale('zh')
  ];

  /// No description provided for @creatorCode.
  ///
  /// In en, this message translates to:
  /// **'Creator Code: ClashKing'**
  String get creatorCode;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Oops! Our servers might have taken a fireball to the face! We\'re casting a healing spell... Try again in a moment.'**
  String get errorTitle;

  /// No description provided for @errorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If the issue persists, check our Discord Server to see if we\'re aware of it.'**
  String get errorSubtitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @signInWithDiscord.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Discord'**
  String get signInWithDiscord;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest Mode'**
  String get guestMode;

  /// No description provided for @needHelpJoinDiscord.
  ///
  /// In en, this message translates to:
  /// **'Need help? Join us on Discord.'**
  String get needHelpJoinDiscord;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while logging in. Please try again later.'**
  String get loginError;

  /// No description provided for @doesNotExist.
  ///
  /// In en, this message translates to:
  /// **'{tag} does not exist.'**
  String doesNotExist(String tag);

  /// No description provided for @isAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'{tag} is already linked to someone.'**
  String isAlreadyLinked(String tag);

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @playerTag.
  ///
  /// In en, this message translates to:
  /// **'Player Tag (#ABC123)'**
  String get playerTag;

  /// No description provided for @playerTags.
  ///
  /// In en, this message translates to:
  /// **'Player Tags'**
  String get playerTags;

  /// No description provided for @linkedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Linked Accounts'**
  String get linkedAccounts;

  /// No description provided for @followingTagsDoNotExist.
  ///
  /// In en, this message translates to:
  /// **'The following tags do not exist: {tags}.'**
  String followingTagsDoNotExist(String tags);

  /// No description provided for @followingTagsAreAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'The following tags are already linked to someone: {tags}.'**
  String followingTagsAreAlreadyLinked(String tags);

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Please add one or more Clash of Clans accounts to your profile. You can add or remove accounts later.'**
  String get welcomeMessage;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @toggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle Theme'**
  String get toggleTheme;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select a language'**
  String get selectLanguage;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @faqSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faqSubtitle;

  /// No description provided for @faqIsThisFromSupercell.
  ///
  /// In en, this message translates to:
  /// **'Is this App from Supercell?'**
  String get faqIsThisFromSupercell;

  /// No description provided for @faqFanContentPolicy.
  ///
  /// In en, this message translates to:
  /// **'This material is unofficial and is not endorsed by Supercell. For more information see Supercell\'s Fan Content Policy: www.supercell.com/fan-content-policy'**
  String get faqFanContentPolicy;

  /// No description provided for @faqWhyNotAccurate.
  ///
  /// In en, this message translates to:
  /// **'Why is the data sometimes inaccurate or missing?'**
  String get faqWhyNotAccurate;

  /// No description provided for @faqClanNotTracked.
  ///
  /// In en, this message translates to:
  /// **'Clan not tracked'**
  String get faqClanNotTracked;

  /// No description provided for @faqClanNotTrackedAnswer.
  ///
  /// In en, this message translates to:
  /// **'ClashKing can only retrieve this info if the clan is tracked. If your clan isn\'t tracked, please invite the ClashKing Bot to your Discord Server and use the command /addclan. We are working on making this feature available in the app soon.'**
  String get faqClanNotTrackedAnswer;

  /// No description provided for @faqTrackingDown.
  ///
  /// In en, this message translates to:
  /// **'Tracking down'**
  String get faqTrackingDown;

  /// No description provided for @faqTrackingDownAnswer.
  ///
  /// In en, this message translates to:
  /// **'The tracking can stop working for a certain period of time. This is why you can sometimes have holes in your data. We are working on improving this.'**
  String get faqTrackingDownAnswer;

  /// No description provided for @faqApiLimitation.
  ///
  /// In en, this message translates to:
  /// **'Clash of Clans API limitation'**
  String get faqApiLimitation;

  /// No description provided for @faqApiLimitationAnswer.
  ///
  /// In en, this message translates to:
  /// **'Some data is provided by Clash of Clans and their API have some limitations. This is the case for legends tracking, it sometimes stacks the trophy gain and loss as if it was a single attack. This is also why we don\'t have any information on your building levels.'**
  String get faqApiLimitationAnswer;

  /// No description provided for @faqSupportWork.
  ///
  /// In en, this message translates to:
  /// **'How can I support your work?'**
  String get faqSupportWork;

  /// No description provided for @faqSupportWorkAnswer.
  ///
  /// In en, this message translates to:
  /// **'There are several ways to support us:'**
  String get faqSupportWorkAnswer;

  /// No description provided for @faqUseCodeClashKing.
  ///
  /// In en, this message translates to:
  /// **'Use code \"ClashKing\"'**
  String get faqUseCodeClashKing;

  /// No description provided for @faqSupportUsOnPatreon.
  ///
  /// In en, this message translates to:
  /// **'Support us on Patreon'**
  String get faqSupportUsOnPatreon;

  /// No description provided for @faqShareTheApp.
  ///
  /// In en, this message translates to:
  /// **'Share the app with your friends'**
  String get faqShareTheApp;

  /// No description provided for @faqRateTheApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the app in the store'**
  String get faqRateTheApp;

  /// No description provided for @faqHelpUsTranslate.
  ///
  /// In en, this message translates to:
  /// **'Help us translate the app'**
  String get faqHelpUsTranslate;

  /// No description provided for @faqHowToInviteTheBot.
  ///
  /// In en, this message translates to:
  /// **'How can I invite your bot to my Discord Server?'**
  String get faqHowToInviteTheBot;

  /// No description provided for @faqHowToInviteTheBotAnswer.
  ///
  /// In en, this message translates to:
  /// **'You can invite our bot to your server by clicking on the button below. You will need the \"Manage Server\" permission to add the bot.'**
  String get faqHowToInviteTheBotAnswer;

  /// No description provided for @faqInviteTheBot.
  ///
  /// In en, this message translates to:
  /// **'Invite ClashKing Bot'**
  String get faqInviteTheBot;

  /// No description provided for @faqNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'I need help or I would like to make a suggestion. How can I contact you?'**
  String get faqNeedHelp;

  /// No description provided for @faqNeedHelpAnswer.
  ///
  /// In en, this message translates to:
  /// **'You can join our Discord Server to ask for help or to provide feedback, or you can email us at devs@clashkingbot.com. Please only write in English or French.'**
  String get faqNeedHelpAnswer;

  /// No description provided for @faqSendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send an email'**
  String get faqSendEmail;

  /// No description provided for @faqJoinDiscord.
  ///
  /// In en, this message translates to:
  /// **'Join our Discord Server'**
  String get faqJoinDiscord;

  /// No description provided for @faqCannotOpenMailClient.
  ///
  /// In en, this message translates to:
  /// **'For some reasons we can\'t open your mail client. We copied the email address for you. You can write an email and paste the address in the recipient field.'**
  String get faqCannotOpenMailClient;

  /// No description provided for @helpUsTranslate.
  ///
  /// In en, this message translates to:
  /// **'Help us translate'**
  String get helpUsTranslate;

  /// No description provided for @suggestFeatures.
  ///
  /// In en, this message translates to:
  /// **'Suggest features'**
  String get suggestFeatures;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get thankYou;

  /// No description provided for @thankYouContent.
  ///
  /// In en, this message translates to:
  /// **'A huge thank you to all our amazing translators who help us make this app accessible to more people around the world!'**
  String get thankYouContent;

  /// No description provided for @helpTranslateContent.
  ///
  /// In en, this message translates to:
  /// **'You can help us translate the app on Crowdin. If your language is not available on Crowdin, feel free to request it in our Discord Server. Thank you so much for your help!'**
  String get helpTranslateContent;

  /// No description provided for @helpTranslateButton.
  ///
  /// In en, this message translates to:
  /// **'Help Translate on Crowdin'**
  String get helpTranslateButton;

  /// No description provided for @versionDevice.
  ///
  /// In en, this message translates to:
  /// **'Version & Device'**
  String get versionDevice;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Error message when the app version cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Error loading version'**
  String get errorLoadingVersion;

  /// No description provided for @currentTranslators.
  ///
  /// In en, this message translates to:
  /// **'Current Translators'**
  String get currentTranslators;

  /// No description provided for @betaFeature.
  ///
  /// In en, this message translates to:
  /// **'Beta Feature'**
  String get betaFeature;

  /// No description provided for @beta.
  ///
  /// In en, this message translates to:
  /// **'BETA'**
  String get beta;

  /// No description provided for @betaDescription.
  ///
  /// In en, this message translates to:
  /// **'This feature is currently in beta, it may have some bugs or be incomplete. We are actively working on improvements and welcome your feedback. Please share your ideas and report any issues in our Discord Server to help us make it better.'**
  String get betaDescription;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// all items
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @hourIndicator.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hourIndicator;

  /// No description provided for @minIndicator.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minIndicator;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available.'**
  String get noDataAvailable;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// WarLog closed
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @player.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player;

  /// No description provided for @notFoundOrNotLinkedToOurSystem.
  ///
  /// In en, this message translates to:
  /// **'{player} not found or not linked to our system.'**
  String notFoundOrNotLinkedToOurSystem(String player);

  /// No description provided for @tryAnotherNameOrTagOrLinkIt.
  ///
  /// In en, this message translates to:
  /// **'Try another name/tag or link it.'**
  String get tryAnotherNameOrTagOrLinkIt;

  /// No description provided for @playerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Player not found'**
  String get playerNotFound;

  /// No description provided for @noValueEntered.
  ///
  /// In en, this message translates to:
  /// **'No value entered'**
  String get noValueEntered;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @enterPlayerTag.
  ///
  /// In en, this message translates to:
  /// **'Enter a player tag'**
  String get enterPlayerTag;

  /// Add an account
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Delete an account
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @playerTagNotExists.
  ///
  /// In en, this message translates to:
  /// **'The player tag entered does not exist.'**
  String get playerTagNotExists;

  /// No description provided for @accountAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'The player tag is already linked to someone.'**
  String accountAlreadyLinked(Object tag);

  /// No description provided for @enterApiToken.
  ///
  /// In en, this message translates to:
  /// **'Please enter the account API token to confirm it\'s yours. You can find it in Clash of Clans Settings > More Settings > API Token.'**
  String get enterApiToken;

  /// No description provided for @wrongApiToken.
  ///
  /// In en, this message translates to:
  /// **'The API token entered is incorrect'**
  String get wrongApiToken;

  /// No description provided for @accountAlreadyLinkedToYou.
  ///
  /// In en, this message translates to:
  /// **'The player tag is already linked to you.'**
  String get accountAlreadyLinkedToYou;

  /// No description provided for @apiToken.
  ///
  /// In en, this message translates to:
  /// **'Account API Token'**
  String get apiToken;

  /// No description provided for @failedToAddTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to add the account. Please try again later.'**
  String get failedToAddTryAgain;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields.'**
  String get fillAllFields;

  /// No description provided for @failedToDeleteTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete link. Please try again later.'**
  String get failedToDeleteTryAgain;

  /// No description provided for @enterPlayerTagWarning.
  ///
  /// In en, this message translates to:
  /// **'You must enter a player tag and click on the \"+\" to continue.'**
  String get enterPlayerTagWarning;

  /// No description provided for @failedToLoadAccountData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load accounts data.'**
  String get failedToLoadAccountData;

  /// No description provided for @loadAccountData.
  ///
  /// In en, this message translates to:
  /// **'Load accounts data'**
  String get loadAccountData;

  /// Search for a player or a clan
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @exitAppToOpenClash.
  ///
  /// In en, this message translates to:
  /// **'You are about to leave the app to open Clash of Clans.'**
  String get exitAppToOpenClash;

  /// Prompt asking the user to confirm logout
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get confirmLogout;

  /// No description provided for @tagOrNamePlayer.
  ///
  /// In en, this message translates to:
  /// **'Player\'s tag or name'**
  String get tagOrNamePlayer;

  /// No description provided for @searchPlayer.
  ///
  /// In en, this message translates to:
  /// **'Search player'**
  String get searchPlayer;

  /// No description provided for @nameOrTagPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player\'s name or tag'**
  String get nameOrTagPlayer;

  /// No description provided for @playerClanDescription.
  ///
  /// In en, this message translates to:
  /// **'Your clan is \"{clan}\" ({tag}).'**
  String playerClanDescription(String clan, String tag);

  /// No description provided for @playerRatioDescription.
  ///
  /// In en, this message translates to:
  /// **'Your donation ratio is {ratio}. You have donated {donations} troops and received {received} troops.'**
  String playerRatioDescription(String ratio, String donations, String received);

  /// No description provided for @playerWarPreferenceDescription.
  ///
  /// In en, this message translates to:
  /// **'Your war preference is \"{preference}\".'**
  String playerWarPreferenceDescription(String preference);

  /// No description provided for @playerWarStarsDescription.
  ///
  /// In en, this message translates to:
  /// **'You have {stars} war stars.'**
  String playerWarStarsDescription(int stars);

  /// No description provided for @playerTrophiesDescription.
  ///
  /// In en, this message translates to:
  /// **'You have {trophies} trophies. You\'re currently in {league}.'**
  String playerTrophiesDescription(int trophies, String league);

  /// No description provided for @playerTownHallLevelDescription.
  ///
  /// In en, this message translates to:
  /// **'Your Town Hall level is {level}.'**
  String playerTownHallLevelDescription(int level);

  /// No description provided for @playerBuilderBaseDescription.
  ///
  /// In en, this message translates to:
  /// **'Your Builder Hall level is {level} and you have {trophies} trophies.'**
  String playerBuilderBaseDescription(int level, int trophies);

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @homeBase.
  ///
  /// In en, this message translates to:
  /// **'Home Base'**
  String get homeBase;

  /// No description provided for @th.
  ///
  /// In en, this message translates to:
  /// **'TH'**
  String get th;

  /// No description provided for @builderBase.
  ///
  /// In en, this message translates to:
  /// **'Builder Base'**
  String get builderBase;

  /// No description provided for @bh.
  ///
  /// In en, this message translates to:
  /// **'BH'**
  String get bh;

  /// No description provided for @clanCapital.
  ///
  /// In en, this message translates to:
  /// **'Clan Capital'**
  String get clanCapital;

  /// No description provided for @leader.
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get leader;

  /// No description provided for @coLeader.
  ///
  /// In en, this message translates to:
  /// **'Co-Leader'**
  String get coLeader;

  /// No description provided for @elder.
  ///
  /// In en, this message translates to:
  /// **'Elder'**
  String get elder;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// Opted In for war
  ///
  /// In en, this message translates to:
  /// **'Opted In'**
  String get ready;

  /// Opted Out for war
  ///
  /// In en, this message translates to:
  /// **'Opted Out'**
  String get unready;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level: {level}/{maxLevel}'**
  String level(int level, int maxLevel);

  /// No description provided for @heroes.
  ///
  /// In en, this message translates to:
  /// **'Heroes'**
  String get heroes;

  /// No description provided for @equipment.
  ///
  /// In en, this message translates to:
  /// **'Equipments'**
  String get equipment;

  /// No description provided for @troops.
  ///
  /// In en, this message translates to:
  /// **'Troops'**
  String get troops;

  /// No description provided for @superTroops.
  ///
  /// In en, this message translates to:
  /// **'Super Troops'**
  String get superTroops;

  /// No description provided for @activeSuperTroops.
  ///
  /// In en, this message translates to:
  /// **'Active Super Troops'**
  String get activeSuperTroops;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @pets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get pets;

  /// No description provided for @siegeMachines.
  ///
  /// In en, this message translates to:
  /// **'Siege Machines'**
  String get siegeMachines;

  /// No description provided for @spells.
  ///
  /// In en, this message translates to:
  /// **'Spells'**
  String get spells;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// Shows stats by day
  ///
  /// In en, this message translates to:
  /// **'By Day'**
  String get byDay;

  /// No description provided for @bySeason.
  ///
  /// In en, this message translates to:
  /// **'By Season'**
  String get bySeason;

  /// No description provided for @dayIndex.
  ///
  /// In en, this message translates to:
  /// **'Day {index}'**
  String dayIndex(int index);

  /// No description provided for @indexDays.
  ///
  /// In en, this message translates to:
  /// **'{index} days'**
  String indexDays(int index);

  /// No description provided for @bestTrophies.
  ///
  /// In en, this message translates to:
  /// **'Best Trophies'**
  String get bestTrophies;

  /// No description provided for @mostAttacks.
  ///
  /// In en, this message translates to:
  /// **'Most Attacks'**
  String get mostAttacks;

  /// No description provided for @lastSeason.
  ///
  /// In en, this message translates to:
  /// **'Last Season'**
  String get lastSeason;

  /// No description provided for @bestRank.
  ///
  /// In en, this message translates to:
  /// **'Best Global Rank'**
  String get bestRank;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String daysLeft(int days);

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @fullStats.
  ///
  /// In en, this message translates to:
  /// **'Full Stats'**
  String get fullStats;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @seasonStats.
  ///
  /// In en, this message translates to:
  /// **'Season Stats'**
  String get seasonStats;

  /// No description provided for @charts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get charts;

  /// Shows EOS trophies history
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @legendLeague.
  ///
  /// In en, this message translates to:
  /// **'Legend League'**
  String get legendLeague;

  /// No description provided for @notInLegendLeague.
  ///
  /// In en, this message translates to:
  /// **'Not in Legend League'**
  String get notInLegendLeague;

  /// No description provided for @noLegendsDataToday.
  ///
  /// In en, this message translates to:
  /// **'You\'re not in Legend League, but past seasons are available.'**
  String get noLegendsDataToday;

  /// No description provided for @legendStartDescription.
  ///
  /// In en, this message translates to:
  /// **'You started the day with {trophies} trophies.'**
  String legendStartDescription(String trophies);

  /// No description provided for @legendNoRankLocalDescription.
  ///
  /// In en, this message translates to:
  /// **'You are currently not ranked ({country}) with {trophies} trophies.'**
  String legendNoRankLocalDescription(String country, int trophies);

  /// No description provided for @legendRankLocalDescription.
  ///
  /// In en, this message translates to:
  /// **'You are currently ranked {rank} ({country}) with {trophies} trophies.'**
  String legendRankLocalDescription(Object country, Object rank, Object trophies);

  /// No description provided for @legendGainDescription.
  ///
  /// In en, this message translates to:
  /// **'You gained {trophies} trophies for now.'**
  String legendGainDescription(int trophies);

  /// No description provided for @legendLossDescription.
  ///
  /// In en, this message translates to:
  /// **'You lost {trophies} trophies for now.'**
  String legendLossDescription(int trophies);

  /// No description provided for @legendNoGlobalRankDescription.
  ///
  /// In en, this message translates to:
  /// **'You are currently not ranked globally with {trophies} trophies.'**
  String legendNoGlobalRankDescription(int trophies);

  /// No description provided for @legendGlobalRankDescription.
  ///
  /// In en, this message translates to:
  /// **'You are currently ranked {rank} globally.'**
  String legendGlobalRankDescription(int rank, Object trophies);

  /// No description provided for @noRank.
  ///
  /// In en, this message translates to:
  /// **'No ranking'**
  String get noRank;

  /// Title for the number of trophies at the beginning of the day
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// Title for the number of trophies at the end of the day
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get ended;

  /// Average value of legend trophies (defense and attack)
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// Remaining attacks or defenses
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @legendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Inaccurate data?'**
  String get legendsTitle;

  /// No description provided for @legendsExplanation_intro.
  ///
  /// In en, this message translates to:
  /// **'Due to limitations of the Clash of Clans API, our data might not always be perfectly accurate. Here\'s why:\n'**
  String get legendsExplanation_intro;

  /// No description provided for @legendsExplanation_api_delay_title.
  ///
  /// In en, this message translates to:
  /// **'1. API Delay: '**
  String get legendsExplanation_api_delay_title;

  /// No description provided for @legendsExplanation_api_delay_body.
  ///
  /// In en, this message translates to:
  /// **'The API can take up to 5 minutes to update, causing a lag in reflecting real-time trophy changes.\n'**
  String get legendsExplanation_api_delay_body;

  /// No description provided for @legendsExplanation_concurrent_changes_title.
  ///
  /// In en, this message translates to:
  /// **'2. Concurrent Changes: \n'**
  String get legendsExplanation_concurrent_changes_title;

  /// No description provided for @legendsExplanation_multiple_attacks_defenses_title.
  ///
  /// In en, this message translates to:
  /// **'- Multiple Attacks/Defenses: '**
  String get legendsExplanation_multiple_attacks_defenses_title;

  /// No description provided for @legendsExplanation_multiple_attacks_defenses_body.
  ///
  /// In en, this message translates to:
  /// **'If multiple attacks or defenses happen in quick succession, the API might show combined results (e.g., +68 or -68).\n'**
  String get legendsExplanation_multiple_attacks_defenses_body;

  /// No description provided for @legendsExplanation_simultaneous_attack_defense_title.
  ///
  /// In en, this message translates to:
  /// **'- Simultaneous Attack and Defense: '**
  String get legendsExplanation_simultaneous_attack_defense_title;

  /// No description provided for @legendsExplanation_simultaneous_attack_defense_body.
  ///
  /// In en, this message translates to:
  /// **'If an attack and defense occur at the same time, you might see a mixed result (e.g., +4).\n'**
  String get legendsExplanation_simultaneous_attack_defense_body;

  /// No description provided for @legendsExplanation_net_gain_loss_title.
  ///
  /// In en, this message translates to:
  /// **'3. Net Gain/Loss: '**
  String get legendsExplanation_net_gain_loss_title;

  /// No description provided for @legendsExplanation_net_gain_loss_body.
  ///
  /// In en, this message translates to:
  /// **'Despite timing issues, the overall net gain or loss for the day is accurate. '**
  String get legendsExplanation_net_gain_loss_body;

  /// No description provided for @legendsExplanation_conclusion.
  ///
  /// In en, this message translates to:
  /// **'These limitations are common across all tools using the Clash of Clans API. We sadly can\'t fix that as it is in Supercell\'s hands. We do our best to compensate for these limits and provide results as close to reality as possible. Thank you for understanding!'**
  String get legendsExplanation_conclusion;

  /// No description provided for @toDoList.
  ///
  /// In en, this message translates to:
  /// **'To-do list'**
  String get toDoList;

  /// No description provided for @lastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active: {date}'**
  String lastActive(String date);

  /// No description provided for @playerNotTracked.
  ///
  /// In en, this message translates to:
  /// **'This player is not tracked. Data may be inaccurate.'**
  String get playerNotTracked;

  /// Number of accounts (ex: 4 accounts)
  ///
  /// In en, this message translates to:
  /// **'{number} accounts'**
  String numberAccounts(int number);

  /// No description provided for @numberActiveAccounts.
  ///
  /// In en, this message translates to:
  /// **'{number} active accounts'**
  String numberActiveAccounts(int number);

  /// No description provided for @numberInactiveAccounts.
  ///
  /// In en, this message translates to:
  /// **'{number} inactive accounts'**
  String numberInactiveAccounts(int number);

  /// No description provided for @activeAccounts.
  ///
  /// In en, this message translates to:
  /// **'Active accounts'**
  String get activeAccounts;

  /// No description provided for @inactiveAccounts.
  ///
  /// In en, this message translates to:
  /// **'Inactive accounts'**
  String get inactiveAccounts;

  /// No description provided for @noInactiveAccounts.
  ///
  /// In en, this message translates to:
  /// **'No inactive accounts.'**
  String get noInactiveAccounts;

  /// No description provided for @noActiveAccounts.
  ///
  /// In en, this message translates to:
  /// **'No active accounts.'**
  String get noActiveAccounts;

  /// No description provided for @todoExplanation_title.
  ///
  /// In en, this message translates to:
  /// **'Task Calculation'**
  String get todoExplanation_title;

  /// No description provided for @todoExplanation_intro.
  ///
  /// In en, this message translates to:
  /// **'The task completion percentage is calculated based on the following activities with specific weightings:'**
  String get todoExplanation_intro;

  /// No description provided for @todoExplanation_legends_title.
  ///
  /// In en, this message translates to:
  /// **'Legend League:'**
  String get todoExplanation_legends_title;

  /// No description provided for @todoExplanation_legends.
  ///
  /// In en, this message translates to:
  /// **'Weight of 8 points per account, 1 attack = 1 point.'**
  String get todoExplanation_legends;

  /// No description provided for @todoExplanation_raids_title.
  ///
  /// In en, this message translates to:
  /// **'Raids:'**
  String get todoExplanation_raids_title;

  /// No description provided for @todoExplanation_raids.
  ///
  /// In en, this message translates to:
  /// **'Weight of 5 points per account (or 6 if the last attack has been unlocked), 1 attack = 1 point.'**
  String get todoExplanation_raids;

  /// No description provided for @todoExplanation_clanWars_title.
  ///
  /// In en, this message translates to:
  /// **'Clan Wars:'**
  String get todoExplanation_clanWars_title;

  /// No description provided for @todoExplanation_clanWars.
  ///
  /// In en, this message translates to:
  /// **'Weight of 2 points per account, 1 attack = 1 point.'**
  String get todoExplanation_clanWars;

  /// No description provided for @todoExplanation_cwl_title.
  ///
  /// In en, this message translates to:
  /// **'Clan War League:'**
  String get todoExplanation_cwl_title;

  /// No description provided for @todoExplanation_cwl.
  ///
  /// In en, this message translates to:
  /// **'Weight of 1 point per account, 1 attack = 1 point. CWL cannot be tracked if the player is not in their league clan.'**
  String get todoExplanation_cwl;

  /// No description provided for @todoExplanation_passAndGames_title.
  ///
  /// In en, this message translates to:
  /// **'Season Pass & Clan Games:'**
  String get todoExplanation_passAndGames_title;

  /// No description provided for @todoExplanation_passAndGames.
  ///
  /// In en, this message translates to:
  /// **'Weight of 2 points each per account. The ratio is based on the number of days remaining (1 month for the pass and 6 days for the games). Green = on track to complete the pass or games, red = behind schedule.'**
  String get todoExplanation_passAndGames;

  /// No description provided for @todoExplanation_conclusion.
  ///
  /// In en, this message translates to:
  /// **'The final percentage is calculated by dividing the total actions completed during ongoing events by the total required actions. Accounts inactive for more than 14 days are excluded from the calculation.'**
  String get todoExplanation_conclusion;

  /// Worst end of day trophies
  ///
  /// In en, this message translates to:
  /// **'Worst'**
  String get worst;

  /// Best end of day trophies
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get best;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @heroesEquipments.
  ///
  /// In en, this message translates to:
  /// **'Hero equipments'**
  String get heroesEquipments;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(int days);

  /// No description provided for @dayAgo.
  ///
  /// In en, this message translates to:
  /// **'{day} day ago'**
  String dayAgo(int day);

  /// No description provided for @hourAgo.
  ///
  /// In en, this message translates to:
  /// **'{hour} hour ago'**
  String hourAgo(int hour);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String hoursAgo(int hours, Object Hours);

  /// No description provided for @minuteAgo.
  ///
  /// In en, this message translates to:
  /// **'{minute} minute ago'**
  String minuteAgo(int minute);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String minutesAgo(int minutes);

  /// No description provided for @secondAgo.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s ago'**
  String secondAgo(int seconds);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just Now'**
  String get justNow;

  /// No description provided for @endedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Ended just now'**
  String get endedJustNow;

  /// No description provided for @endedMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'Ended {minutes} minutes ago'**
  String endedMinutesAgo(int minutes);

  /// No description provided for @endedHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'Ended {hours} hours ago'**
  String endedHoursAgo(int hours);

  /// No description provided for @endedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Ended {days} days ago'**
  String endedDaysAgo(int days);

  /// No description provided for @trophiesByMonth.
  ///
  /// In en, this message translates to:
  /// **'Trophies by month'**
  String get trophiesByMonth;

  /// No description provided for @trophiesBySeason.
  ///
  /// In en, this message translates to:
  /// **'Trophies by season'**
  String get trophiesBySeason;

  /// No description provided for @eosTrophies.
  ///
  /// In en, this message translates to:
  /// **'End Of Season Trophies'**
  String get eosTrophies;

  /// No description provided for @eosDetails.
  ///
  /// In en, this message translates to:
  /// **'End Of Season Details'**
  String get eosDetails;

  /// No description provided for @searchClan.
  ///
  /// In en, this message translates to:
  /// **'Search clan'**
  String get searchClan;

  /// No description provided for @clanName.
  ///
  /// In en, this message translates to:
  /// **'Clan\'s name'**
  String get clanName;

  /// No description provided for @nameOrTagClan.
  ///
  /// In en, this message translates to:
  /// **'Clan\'s name or tag'**
  String get nameOrTagClan;

  /// No description provided for @noResult.
  ///
  /// In en, this message translates to:
  /// **'No result.'**
  String get noResult;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// Whatever the value
  ///
  /// In en, this message translates to:
  /// **'Whatever'**
  String get whatever;

  /// Any value is accepted
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// Filter value is not set
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @warFrequency.
  ///
  /// In en, this message translates to:
  /// **'War frequency'**
  String get warFrequency;

  /// No description provided for @minimumMembers.
  ///
  /// In en, this message translates to:
  /// **'Minimum members'**
  String get minimumMembers;

  /// No description provided for @maximumMembers.
  ///
  /// In en, this message translates to:
  /// **'Maximum members'**
  String get maximumMembers;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @minimumClanPoints.
  ///
  /// In en, this message translates to:
  /// **'Minimum clan points'**
  String get minimumClanPoints;

  /// No description provided for @minimumClanLevel.
  ///
  /// In en, this message translates to:
  /// **'Minimum clan level'**
  String get minimumClanLevel;

  /// No description provided for @noClan.
  ///
  /// In en, this message translates to:
  /// **'No clan'**
  String get noClan;

  /// No description provided for @joinClanToUnlockNewFeatures.
  ///
  /// In en, this message translates to:
  /// **'Join a clan to unlock new features.'**
  String get joinClanToUnlockNewFeatures;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Clan is opened
  ///
  /// In en, this message translates to:
  /// **'Opened'**
  String get opened;

  /// No description provided for @inviteOnly.
  ///
  /// In en, this message translates to:
  /// **'Invite Only'**
  String get inviteOnly;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @clan.
  ///
  /// In en, this message translates to:
  /// **'Clan'**
  String get clan;

  /// No description provided for @clans.
  ///
  /// In en, this message translates to:
  /// **'Clans'**
  String get clans;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @expLevel.
  ///
  /// In en, this message translates to:
  /// **'Experience Level'**
  String get expLevel;

  /// No description provided for @townHallLevel.
  ///
  /// In en, this message translates to:
  /// **'TH Level'**
  String get townHallLevel;

  /// No description provided for @thLevel.
  ///
  /// In en, this message translates to:
  /// **'TH{level}'**
  String thLevel(int level);

  /// No description provided for @bhLevel.
  ///
  /// In en, this message translates to:
  /// **'BH{level}'**
  String bhLevel(int level);

  /// No description provided for @townHallLevelLevel.
  ///
  /// In en, this message translates to:
  /// **'Town Hall {level}'**
  String townHallLevelLevel(int level);

  /// filter by number of wars
  ///
  /// In en, this message translates to:
  /// **'By number of wars'**
  String get byNumberOfWars;

  /// OK button on pop up
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// filter by date range
  ///
  /// In en, this message translates to:
  /// **'By date range'**
  String get byDateRange;

  /// Ask player to select a season
  ///
  /// In en, this message translates to:
  /// **'Select a season'**
  String get selectSeason;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @allTownHalls.
  ///
  /// In en, this message translates to:
  /// **'All Town Halls'**
  String get allTownHalls;

  /// Example: August 2024 season
  ///
  /// In en, this message translates to:
  /// **'{date} season'**
  String seasonDate(String date);

  /// Example: Shows the last 25 wars
  ///
  /// In en, this message translates to:
  /// **'Last {number} wars'**
  String lastXwars(int number);

  /// Friendly war
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get friendly;

  /// No description provided for @cwl.
  ///
  /// In en, this message translates to:
  /// **'CWL'**
  String get cwl;

  /// Random/basic war (not friendly or cwl)
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get random;

  /// No description provided for @selectMembersThLevel.
  ///
  /// In en, this message translates to:
  /// **'Members TH Level'**
  String get selectMembersThLevel;

  /// No description provided for @selectOpponentsThLevel.
  ///
  /// In en, this message translates to:
  /// **'Opponents TH Level'**
  String get selectOpponentsThLevel;

  /// No description provided for @equalThLevel.
  ///
  /// In en, this message translates to:
  /// **'Equal TH'**
  String get equalThLevel;

  /// No description provided for @builderBaseTrophies.
  ///
  /// In en, this message translates to:
  /// **'BB Trophies'**
  String get builderBaseTrophies;

  /// No description provided for @donations.
  ///
  /// In en, this message translates to:
  /// **'Donations'**
  String get donations;

  /// No description provided for @donationsReceived.
  ///
  /// In en, this message translates to:
  /// **'Donations Received'**
  String get donationsReceived;

  /// No description provided for @donationsRatio.
  ///
  /// In en, this message translates to:
  /// **'Donation Ratio'**
  String get donationsRatio;

  /// No description provided for @trophies.
  ///
  /// In en, this message translates to:
  /// **'Trophies'**
  String get trophies;

  /// No description provided for @always.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get always;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @oncePerWeek.
  ///
  /// In en, this message translates to:
  /// **'1/week'**
  String get oncePerWeek;

  /// No description provided for @twicePerWeek.
  ///
  /// In en, this message translates to:
  /// **'2/week'**
  String get twicePerWeek;

  /// No description provided for @rarely.
  ///
  /// In en, this message translates to:
  /// **'Rarely'**
  String get rarely;

  /// No description provided for @warLeague.
  ///
  /// In en, this message translates to:
  /// **'War/League'**
  String get warLeague;

  /// No description provided for @war.
  ///
  /// In en, this message translates to:
  /// **'War'**
  String get war;

  /// No description provided for @league.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get league;

  /// No description provided for @wars.
  ///
  /// In en, this message translates to:
  /// **'Wars'**
  String get wars;

  /// No description provided for @ongoingWar.
  ///
  /// In en, this message translates to:
  /// **'Ongoing war'**
  String get ongoingWar;

  /// No description provided for @ongoingCwl.
  ///
  /// In en, this message translates to:
  /// **'Ongoing CWL'**
  String get ongoingCwl;

  /// No description provided for @cantOpenLink.
  ///
  /// In en, this message translates to:
  /// **'We can\'t open this link.'**
  String get cantOpenLink;

  /// No description provided for @notInWar.
  ///
  /// In en, this message translates to:
  /// **'Not in war'**
  String get notInWar;

  /// No description provided for @warHistory.
  ///
  /// In en, this message translates to:
  /// **'War History'**
  String get warHistory;

  /// No description provided for @warHistoryWinsDescription.
  ///
  /// In en, this message translates to:
  /// **'Your clan won {wins} wars ({percent}%) out of the last 50 wars.'**
  String warHistoryWinsDescription(int wins, String percent);

  /// No description provided for @warHistoryLossesDescription.
  ///
  /// In en, this message translates to:
  /// **'Your clan lost {losses} wars ({percent}%) out of the last 50 wars.'**
  String warHistoryLossesDescription(int losses, String percent);

  /// No description provided for @warHistoryDrawsDescription.
  ///
  /// In en, this message translates to:
  /// **'Your clan had {draws} draws ({percent}%) out of the last 50 wars.'**
  String warHistoryDrawsDescription(int draws, String percent);

  /// No description provided for @warHistoryAverageMembersDescription.
  ///
  /// In en, this message translates to:
  /// **'Your clan has an average of {members} members participating out of the last 50 wars.'**
  String warHistoryAverageMembersDescription(int members);

  /// No description provided for @warHistoryAverageWarStarsDescription.
  ///
  /// In en, this message translates to:
  /// **'Your clan had an average of {stars} stars per war from the last 50 wars. It represents {percent} of the total stars.'**
  String warHistoryAverageWarStarsDescription(double stars, String percent);

  /// No description provided for @warHistoryAverageHitRateDescription.
  ///
  /// In en, this message translates to:
  /// **'Your clan had an average of {percent}% destruction rate from the last 50 wars.'**
  String warHistoryAverageHitRateDescription(String percent);

  /// No description provided for @warHistoryAverageClanStarsPerMember.
  ///
  /// In en, this message translates to:
  /// **'Your clan had an average of {stars} stars per member from the last 50 wars.'**
  String warHistoryAverageClanStarsPerMember(Object stars);

  /// No description provided for @warHistoryAverageMembers.
  ///
  /// In en, this message translates to:
  /// **'~{members} members per war'**
  String warHistoryAverageMembers(int members);

  /// No description provided for @averageStars.
  ///
  /// In en, this message translates to:
  /// **'Average stars'**
  String get averageStars;

  /// No description provided for @averageDestruction.
  ///
  /// In en, this message translates to:
  /// **'Average destruction'**
  String get averageDestruction;

  /// No description provided for @oneStar.
  ///
  /// In en, this message translates to:
  /// **'1 star'**
  String get oneStar;

  /// No description provided for @twoStars.
  ///
  /// In en, this message translates to:
  /// **'2 stars'**
  String get twoStars;

  /// No description provided for @threeStars.
  ///
  /// In en, this message translates to:
  /// **'3 stars'**
  String get threeStars;

  /// No description provided for @highDestruction.
  ///
  /// In en, this message translates to:
  /// **'High destruction'**
  String get highDestruction;

  /// No description provided for @lowDestruction.
  ///
  /// In en, this message translates to:
  /// **'Low destruction'**
  String get lowDestruction;

  /// Abbreviation for average
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get avg;

  /// Abbreviation for average percentage
  ///
  /// In en, this message translates to:
  /// **'Avg %'**
  String get avgPercentage;

  /// No description provided for @attackCount.
  ///
  /// In en, this message translates to:
  /// **'Attack Count'**
  String get attackCount;

  /// No description provided for @missedAttacks.
  ///
  /// In en, this message translates to:
  /// **'Missed Attacks'**
  String get missedAttacks;

  /// Order of the player in the clan
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @defenseStars.
  ///
  /// In en, this message translates to:
  /// **'Defense Stars'**
  String get defenseStars;

  /// No description provided for @defenseDestruction.
  ///
  /// In en, this message translates to:
  /// **'Defense Destruction'**
  String get defenseDestruction;

  /// No description provided for @defenseAverageStars.
  ///
  /// In en, this message translates to:
  /// **'Defense Avg Stars'**
  String get defenseAverageStars;

  /// No description provided for @defenseAverageDestruction.
  ///
  /// In en, this message translates to:
  /// **'Defense Avg Destruction'**
  String get defenseAverageDestruction;

  /// No description provided for @zeroStar.
  ///
  /// In en, this message translates to:
  /// **'0 Star'**
  String get zeroStar;

  /// No description provided for @warParticipation.
  ///
  /// In en, this message translates to:
  /// **'War Participation'**
  String get warParticipation;

  /// Missed attacks
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @totalStars.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalStars;

  /// No description provided for @destruction.
  ///
  /// In en, this message translates to:
  /// **'Destruction'**
  String get destruction;

  /// Map position in war
  ///
  /// In en, this message translates to:
  /// **'Map Position'**
  String get mapPosition;

  /// Abbreviation for map position
  ///
  /// In en, this message translates to:
  /// **'Pos'**
  String get pos;

  /// Abbreviation for opponent's town hall level
  ///
  /// In en, this message translates to:
  /// **'Opp TH'**
  String get oppTownhall;

  /// No description provided for @lowerTownhall.
  ///
  /// In en, this message translates to:
  /// **'Lower TH'**
  String get lowerTownhall;

  /// No description provided for @upperTownhall.
  ///
  /// In en, this message translates to:
  /// **'Upper TH'**
  String get upperTownhall;

  /// For example, hide stats from TH15 and below if the player is now TH16
  ///
  /// In en, this message translates to:
  /// **'Hide/Show stats from former TH levels'**
  String get toggleTownHallVisibility;

  /// No description provided for @warLog.
  ///
  /// In en, this message translates to:
  /// **'War Log'**
  String get warLog;

  /// No description provided for @publicWarLog.
  ///
  /// In en, this message translates to:
  /// **'Public War Log'**
  String get publicWarLog;

  /// No description provided for @privateWarLog.
  ///
  /// In en, this message translates to:
  /// **'Private War Log'**
  String get privateWarLog;

  /// No description provided for @startsIn.
  ///
  /// In en, this message translates to:
  /// **'Starts in {time}'**
  String startsIn(String time);

  /// No description provided for @startsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at {time}'**
  String startsAt(String time);

  /// No description provided for @endsIn.
  ///
  /// In en, this message translates to:
  /// **'Ends in {time}'**
  String endsIn(String time);

  /// No description provided for @endsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends at {time}'**
  String endsAt(String time);

  /// Logs of players joining or leaving the clan.
  ///
  /// In en, this message translates to:
  /// **'Join/Leave Logs (Current Season)'**
  String get joinLeaveLogs;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @joins.
  ///
  /// In en, this message translates to:
  /// **'Joins'**
  String get joins;

  /// No description provided for @leaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get leaves;

  /// No description provided for @uniquePlayers.
  ///
  /// In en, this message translates to:
  /// **'Unique Players'**
  String get uniquePlayers;

  /// No description provided for @movingPlayers.
  ///
  /// In en, this message translates to:
  /// **'Moving Players'**
  String get movingPlayers;

  /// No description provided for @mostMovingPlayers.
  ///
  /// In en, this message translates to:
  /// **'Most Moving Players'**
  String get mostMovingPlayers;

  /// No description provided for @stillInClan.
  ///
  /// In en, this message translates to:
  /// **'Still in Clan'**
  String get stillInClan;

  /// No description provided for @leftForever.
  ///
  /// In en, this message translates to:
  /// **'Left Forever'**
  String get leftForever;

  /// No description provided for @rejoinedPlayers.
  ///
  /// In en, this message translates to:
  /// **'Rejoined Players'**
  String get rejoinedPlayers;

  /// No description provided for @avgTimeJoinLeave.
  ///
  /// In en, this message translates to:
  /// **'Avg Join/Leave Time'**
  String get avgTimeJoinLeave;

  /// No description provided for @peakHour.
  ///
  /// In en, this message translates to:
  /// **'Most Active Hour'**
  String get peakHour;

  /// No description provided for @leaveNumberDescription.
  ///
  /// In en, this message translates to:
  /// **'{number} leave events occurred during the current season ({date}).'**
  String leaveNumberDescription(int number, String date);

  /// No description provided for @joinNumberDescription.
  ///
  /// In en, this message translates to:
  /// **'{number} join events occurred during the current season ({date}).'**
  String joinNumberDescription(int number, String date);

  /// Number of players who left and rejoined the clan during the current season.
  ///
  /// In en, this message translates to:
  /// **'{number} player(s) left and rejoined the clan during the current season ({date}).'**
  String movingNumberDescription(int number, String date);

  /// Number of unique players who joined/left the clan during the current season.
  ///
  /// In en, this message translates to:
  /// **'{number} unique player(s) joined/left the clan during the current season ({date}).'**
  String uniqueNumberDescription(int number, String date);

  /// The hour with the most join/leave activity.
  ///
  /// In en, this message translates to:
  /// **'{hour}h is usually the hour with the most join/leave activity.'**
  String mostMovingHourDescription(int hour);

  /// No description provided for @stillInClanNumberDescription.
  ///
  /// In en, this message translates to:
  /// **'{number} player(s) joined and are still in the clan.'**
  String stillInClanNumberDescription(int number);

  /// No description provided for @leftClanNumberDescription.
  ///
  /// In en, this message translates to:
  /// **'{number} player(s) joined, then left the clan and never rejoined.'**
  String leftClanNumberDescription(int number);

  /// Number of members lost by the clan this season.
  ///
  /// In en, this message translates to:
  /// **'Your clan has lost {number} member(s) this season ({date}).'**
  String joinLeaveDifferenceDownDescription(int number, String date);

  /// Difference in the number of members between the beginning and the end of the season.
  ///
  /// In en, this message translates to:
  /// **'Your clan has the same number of members as at the beginning of the season ({date}).'**
  String joinLeaveDifferenceEqualDescription(String date);

  /// [The player] left the clan on 16/06/2024 at 10:35.
  ///
  /// In en, this message translates to:
  /// **'Left on {date} at {time}.'**
  String leftOnAt(String date, String time);

  /// [The player] joined the clan on 16/06/2024 at 10:35.
  ///
  /// In en, this message translates to:
  /// **'Joined on {date} at {time}.'**
  String joinedOnAt(String date, String time);

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @stars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get stars;

  /// No description provided for @numberOfStars.
  ///
  /// In en, this message translates to:
  /// **'Number of stars'**
  String get numberOfStars;

  /// Percentage of destruction in war
  ///
  /// In en, this message translates to:
  /// **'Destruction rate'**
  String get destructionRate;

  /// War events
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get team;

  /// No description provided for @myTeam.
  ///
  /// In en, this message translates to:
  /// **'My team'**
  String get myTeam;

  /// No description provided for @enemiesTeam.
  ///
  /// In en, this message translates to:
  /// **'Enemies'**
  String get enemiesTeam;

  /// No description provided for @defense.
  ///
  /// In en, this message translates to:
  /// **'Defense'**
  String get defense;

  /// No description provided for @defenses.
  ///
  /// In en, this message translates to:
  /// **'Defenses'**
  String get defenses;

  /// No description provided for @bestDefenses.
  ///
  /// In en, this message translates to:
  /// **'Best defenses'**
  String get bestDefenses;

  /// Best war defense (out of 3 defenses)
  ///
  /// In en, this message translates to:
  /// **'Best defense (out of {number})'**
  String bestDefenseOutOf(int number);

  /// No description provided for @attack.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get attack;

  /// No description provided for @attacks.
  ///
  /// In en, this message translates to:
  /// **'Attacks'**
  String get attacks;

  /// No description provided for @bestAttacks.
  ///
  /// In en, this message translates to:
  /// **'Best attacks'**
  String get bestAttacks;

  /// No attack yet in war
  ///
  /// In en, this message translates to:
  /// **'No attack yet'**
  String get noAttackYet;

  /// No defense yet in war
  ///
  /// In en, this message translates to:
  /// **'No defense yet'**
  String get noDefenseYet;

  /// Best performance in war
  ///
  /// In en, this message translates to:
  /// **'Best performance'**
  String get bestPerformance;

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'Victory'**
  String get victory;

  /// No description provided for @defeat.
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get defeat;

  /// War ended in a draw
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @perfectWar.
  ///
  /// In en, this message translates to:
  /// **'Perfect war'**
  String get perfectWar;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get oldest;

  /// No description provided for @warEnded.
  ///
  /// In en, this message translates to:
  /// **'War ended'**
  String get warEnded;

  /// No description provided for @preparation.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get preparation;

  /// No description provided for @isNotInWar.
  ///
  /// In en, this message translates to:
  /// **'{clan} is not in war.'**
  String isNotInWar(String clan);

  /// No description provided for @warLogIsClosed.
  ///
  /// In en, this message translates to:
  /// **'{clan}\'s war log is closed.'**
  String warLogIsClosed(String clan);

  /// No description provided for @askForWar.
  ///
  /// In en, this message translates to:
  /// **'Contact the leader or a co-leader to start a war.'**
  String get askForWar;

  /// No description provided for @askForWarLogOpening.
  ///
  /// In en, this message translates to:
  /// **'Contact a leader or a co-leader to open the war log.'**
  String get askForWarLogOpening;

  /// No description provided for @warLogClosed.
  ///
  /// In en, this message translates to:
  /// **'War log closed.'**
  String get warLogClosed;

  /// No description provided for @rounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get rounds;

  /// No description provided for @roundNumber.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String roundNumber(int number);

  /// No description provided for @currentRound.
  ///
  /// In en, this message translates to:
  /// **'Current round (Round {number})'**
  String currentRound(int number);

  /// No description provided for @noDataAvailableForThisWar.
  ///
  /// In en, this message translates to:
  /// **'No data available for this war'**
  String get noDataAvailableForThisWar;

  /// No description provided for @stateOfTheWar.
  ///
  /// In en, this message translates to:
  /// **'State of the war'**
  String get stateOfTheWar;

  /// No description provided for @starsNeededToTakeTheLead.
  ///
  /// In en, this message translates to:
  /// **'{clan} still need {star} more star(s) or {stars2} star(s) and {percent}% to take the lead.'**
  String starsNeededToTakeTheLead(String clan, int star, int star2, String percent, Object stars2);

  /// No description provided for @starsAndPercentNeededToTakeTheLead.
  ///
  /// In en, this message translates to:
  /// **'{clan} still need {percent}% or 1 more star to take the lead'**
  String starsAndPercentNeededToTakeTheLead(String clan, String percent);

  /// No description provided for @clanDraw.
  ///
  /// In en, this message translates to:
  /// **'The two clans are tied'**
  String get clanDraw;

  /// No description provided for @fastCalculator.
  ///
  /// In en, this message translates to:
  /// **'Fast calculator'**
  String get fastCalculator;

  /// No description provided for @fastCalculatorAnswer.
  ///
  /// In en, this message translates to:
  /// **'To achieve a destruction rate of {percentNeeded}%, a total of {result}% is needed.'**
  String fastCalculatorAnswer(String percentNeedeed, String result, Object percentNeeded);

  /// No description provided for @teamSize.
  ///
  /// In en, this message translates to:
  /// **'Team size'**
  String get teamSize;

  /// No description provided for @neededOverall.
  ///
  /// In en, this message translates to:
  /// **'% Needed overall'**
  String get neededOverall;

  /// No description provided for @calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// No description provided for @warStats.
  ///
  /// In en, this message translates to:
  /// **'War Stats'**
  String get warStats;

  /// No description provided for @membersStats.
  ///
  /// In en, this message translates to:
  /// **'Members Stats'**
  String get membersStats;

  /// No description provided for @clanWarLeague.
  ///
  /// In en, this message translates to:
  /// **'Clan War League'**
  String get clanWarLeague;

  /// No description provided for @cwlRank.
  ///
  /// In en, this message translates to:
  /// **'Your clan is currently ranked {rank}.'**
  String cwlRank(int rank);

  /// No description provided for @cwlStars.
  ///
  /// In en, this message translates to:
  /// **'Your clan has a total of {stars} stars.'**
  String cwlStars(int stars);

  /// No description provided for @cwlMissingStarsFromNext.
  ///
  /// In en, this message translates to:
  /// **'Your clan is missing {stars} stars to catch up with the next clan.'**
  String cwlMissingStarsFromNext(int stars);

  /// No description provided for @cwlMissingStarsFromFirst.
  ///
  /// In en, this message translates to:
  /// **'Your clan is missing {stars} stars to catch up with the first clan.'**
  String cwlMissingStarsFromFirst(int stars);

  /// No description provided for @cwlDestructionPercentage.
  ///
  /// In en, this message translates to:
  /// **'Your clan has a total destruction rate of {percent}%.'**
  String cwlDestructionPercentage(String percent);

  /// No description provided for @cwlTotalAttacks.
  ///
  /// In en, this message translates to:
  /// **'Your clan has a total of {attacks} attacks out of {totalAttacks} possible attacks.'**
  String cwlTotalAttacks(int attacks, int totalAttacks);

  /// No description provided for @cwlCurrentRound.
  ///
  /// In en, this message translates to:
  /// **'It\'s currently round {round}.'**
  String cwlCurrentRound(int round);

  /// No description provided for @noAccountLinkedToYourProfileFound.
  ///
  /// In en, this message translates to:
  /// **'No account linked to your profile found'**
  String get noAccountLinkedToYourProfileFound;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get management;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get comingSoon;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please check your internet connection and try again.'**
  String get connectionError;

  /// No description provided for @connectionErrorRelaunch.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please check your internet connection and relaunch the app.'**
  String get connectionErrorRelaunch;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at {time}'**
  String updatedAt(String time);

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @lastRaids.
  ///
  /// In en, this message translates to:
  /// **'Last raids'**
  String get lastRaids;

  /// No description provided for @ongoingRaids.
  ///
  /// In en, this message translates to:
  /// **'Ongoing raids'**
  String get ongoingRaids;

  /// No description provided for @districtsDestroyed.
  ///
  /// In en, this message translates to:
  /// **'Districts destroyed'**
  String get districtsDestroyed;

  /// No description provided for @raidsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Raids completed'**
  String get raidsCompleted;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @maintenanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Clash of Clans is currently under maintenance, so we can\'t access the API. Please check back later.'**
  String get maintenanceDescription;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['af', 'ar', 'ca', 'cs', 'da', 'de', 'el', 'en', 'es', 'fi', 'fr', 'he', 'hi', 'hu', 'it', 'ja', 'ko', 'nl', 'no', 'pl', 'pt', 'ro', 'ru', 'sr', 'sv', 'tr', 'uk', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en': {
  switch (locale.countryCode) {
    case 'GB': return AppLocalizationsEnGb();
case 'US': return AppLocalizationsEnUs();
   }
  break;
   }
    case 'es': {
  switch (locale.countryCode) {
    case 'ES': return AppLocalizationsEsEs();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'af': return AppLocalizationsAf();
    case 'ar': return AppLocalizationsAr();
    case 'ca': return AppLocalizationsCa();
    case 'cs': return AppLocalizationsCs();
    case 'da': return AppLocalizationsDa();
    case 'de': return AppLocalizationsDe();
    case 'el': return AppLocalizationsEl();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fi': return AppLocalizationsFi();
    case 'fr': return AppLocalizationsFr();
    case 'he': return AppLocalizationsHe();
    case 'hi': return AppLocalizationsHi();
    case 'hu': return AppLocalizationsHu();
    case 'it': return AppLocalizationsIt();
    case 'ja': return AppLocalizationsJa();
    case 'ko': return AppLocalizationsKo();
    case 'nl': return AppLocalizationsNl();
    case 'no': return AppLocalizationsNo();
    case 'pl': return AppLocalizationsPl();
    case 'pt': return AppLocalizationsPt();
    case 'ro': return AppLocalizationsRo();
    case 'ru': return AppLocalizationsRu();
    case 'sr': return AppLocalizationsSr();
    case 'sv': return AppLocalizationsSv();
    case 'tr': return AppLocalizationsTr();
    case 'uk': return AppLocalizationsUk();
    case 'vi': return AppLocalizationsVi();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
