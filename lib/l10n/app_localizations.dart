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
import 'app_localizations_ur.dart';
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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('ur'),
    Locale('vi'),
    Locale('zh')
  ];

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Your ultimate Clash of Clans companion for tracking stats, managing clans, and analyzing performance.'**
  String get appDescription;

  /// No description provided for @generalLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get generalLoading;

  /// No description provided for @loadingVillages.
  ///
  /// In en, this message translates to:
  /// **'Loading your villages...'**
  String get loadingVillages;

  /// No description provided for @loadingClanData.
  ///
  /// In en, this message translates to:
  /// **'Fetching clan data...'**
  String get loadingClanData;

  /// No description provided for @loadingWarStats.
  ///
  /// In en, this message translates to:
  /// **'Analyzing war stats...'**
  String get loadingWarStats;

  /// No description provided for @loadingLegendsData.
  ///
  /// In en, this message translates to:
  /// **'Preparing legends data...'**
  String get loadingLegendsData;

  /// No description provided for @loadingCapitalRaids.
  ///
  /// In en, this message translates to:
  /// **'Loading capital raids...'**
  String get loadingCapitalRaids;

  /// No description provided for @loadingAlmostReady.
  ///
  /// In en, this message translates to:
  /// **'Almost ready...'**
  String get loadingAlmostReady;

  /// No description provided for @accountVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Account'**
  String get accountVerificationTitle;

  /// No description provided for @accountVerificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your API token to verify you own this account. You can find it in Clash of Clans Settings > More Settings > API Token.'**
  String get accountVerificationMessage;

  /// No description provided for @accountVerified.
  ///
  /// In en, this message translates to:
  /// **'Account verified'**
  String get accountVerified;

  /// No description provided for @accountNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Account not verified'**
  String get accountNotVerified;

  /// No description provided for @accountVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get accountVerifyButton;

  /// No description provided for @accountVerificationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account verified successfully!'**
  String get accountVerificationSuccess;

  /// No description provided for @accountVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please check your API token.'**
  String get accountVerificationFailed;

  /// No description provided for @generalRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get generalRetry;

  /// No description provided for @generalTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get generalTryAgain;

  /// No description provided for @generalCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get generalCancel;

  /// OK button on pop up
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get generalOk;

  /// No description provided for @generalApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get generalApply;

  /// No description provided for @generalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get generalConfirm;

  /// No description provided for @generalManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get generalManage;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get generalSettings;

  /// No description provided for @generalCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get generalCopiedToClipboard;

  /// No description provided for @generalComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get generalComingSoon;

  /// Last refresh time indicator
  ///
  /// In en, this message translates to:
  /// **'Last refresh: {time}'**
  String generalLastRefresh(String time);

  /// Error message when refresh fails
  ///
  /// In en, this message translates to:
  /// **'Refresh failed: {error}'**
  String generalRefreshFailed(String error);

  /// all items
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get generalAll;

  /// No description provided for @generalTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get generalTotal;

  /// Best end of day trophies
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get generalBest;

  /// Worst end of day trophies
  ///
  /// In en, this message translates to:
  /// **'Worst'**
  String get generalWorst;

  /// Average value of legend trophies (defense and attack)
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get generalAverage;

  /// Remaining attacks or defenses
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get generalRemaining;

  /// No description provided for @generalActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get generalActive;

  /// No description provided for @generalInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get generalInactive;

  /// Title for the number of trophies at the beginning of the day
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get generalStarted;

  /// Title for the number of trophies at the end of the day
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get generalEnded;

  /// No description provided for @generalRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get generalRole;

  /// No description provided for @generalStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get generalStats;

  /// No description provided for @generalFullStats.
  ///
  /// In en, this message translates to:
  /// **'Full Stats'**
  String get generalFullStats;

  /// No description provided for @generalDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get generalDetails;

  /// Shows EOS trophies history
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get generalHistory;

  /// No description provided for @generalFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get generalFilters;

  /// Filter value is not set
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get generalNotSet;

  /// No description provided for @generalWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get generalWarning;

  /// No description provided for @generalNoDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available.'**
  String get generalNoDataAvailable;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUp;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLogin;

  /// No description provided for @authLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get authLogout;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// No description provided for @authJoinClashKing.
  ///
  /// In en, this message translates to:
  /// **'Join ClashKing'**
  String get authJoinClashKing;

  /// No description provided for @authCreateClashKingAccount.
  ///
  /// In en, this message translates to:
  /// **'Create ClashKing Account'**
  String get authCreateClashKingAccount;

  /// No description provided for @authCreateAccountToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Create your account to get started'**
  String get authCreateAccountToGetStarted;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authAlreadyHaveAccount;

  /// Prompt asking the user to confirm logout
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get authConfirmLogout;

  /// No description provided for @authDiscordTitle.
  ///
  /// In en, this message translates to:
  /// **'Discord'**
  String get authDiscordTitle;

  /// No description provided for @authDiscordSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Discord'**
  String get authDiscordSignIn;

  /// No description provided for @authDiscordContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue with Discord'**
  String get authDiscordContinue;

  /// No description provided for @authDiscordDescription.
  ///
  /// In en, this message translates to:
  /// **'Sync your data with ClashKing Bot and unlock the full potential of ClashKing!'**
  String get authDiscordDescription;

  /// No description provided for @authEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailTitle;

  /// No description provided for @authEmailDescription.
  ///
  /// In en, this message translates to:
  /// **'Use email if you can\'t access Discord or prefer app-only features'**
  String get authEmailDescription;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authPasswordConfirm;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get authPasswordConfirmRequired;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordMismatch;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get authPasswordTooShort;

  /// No description provided for @authPasswordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password must contain: uppercase, lowercase, digit, and special character'**
  String get authPasswordRequirements;

  /// No description provided for @authPasswordForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authPasswordForgot;

  /// No description provided for @authUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsernameLabel;

  /// No description provided for @authUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get authUsernameRequired;

  /// No description provided for @authUsernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get authUsernameTooShort;

  /// No description provided for @authErrorConnection.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please check your internet connection and try again.'**
  String get authErrorConnection;

  /// No description provided for @authErrorConnectionRelaunch.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please check your internet connection and relaunch the app.'**
  String get authErrorConnectionRelaunch;

  /// No description provided for @authAccountManagement.
  ///
  /// In en, this message translates to:
  /// **'Add, remove, and reorder your Clash of Clans accounts. Verify your accounts to access all features.'**
  String get authAccountManagement;

  /// No description provided for @authAccountConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts'**
  String get authAccountConnected;

  /// No description provided for @authAccountConnectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get authAccountConnectedStatus;

  /// No description provided for @authAccountNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get authAccountNotConnected;

  /// No description provided for @authAccountEmailAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Email & Password'**
  String get authAccountEmailAndPassword;

  /// No description provided for @authAccountSecured.
  ///
  /// In en, this message translates to:
  /// **'Your account is secured with multiple authentication methods'**
  String get authAccountSecured;

  /// No description provided for @authAccountLinkEmail.
  ///
  /// In en, this message translates to:
  /// **'Link Email Account'**
  String get authAccountLinkEmail;

  /// No description provided for @authAccountAddEmailAuth.
  ///
  /// In en, this message translates to:
  /// **'Add email & password authentication to your account for additional security.'**
  String get authAccountAddEmailAuth;

  /// No description provided for @authAccountEmailLinkedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email account successfully linked!'**
  String get authAccountEmailLinkedSuccess;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get helpTitle;

  /// No description provided for @helpJoinDiscord.
  ///
  /// In en, this message translates to:
  /// **'Join Discord'**
  String get helpJoinDiscord;

  /// No description provided for @helpEmailUs.
  ///
  /// In en, this message translates to:
  /// **'Email Us'**
  String get helpEmailUs;

  /// No description provided for @accountsWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get accountsWelcome;

  /// No description provided for @accountsWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Please add one or more Clash of Clans accounts to your profile. You can add or remove accounts later.'**
  String get accountsWelcomeMessage;

  /// No description provided for @accountsManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your accounts'**
  String get accountsManageTitle;

  /// No description provided for @accountsNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No account linked to your profile found'**
  String get accountsNoneFound;

  /// No description provided for @accountsPlayerTag.
  ///
  /// In en, this message translates to:
  /// **'Player Tag (#ABC123)'**
  String get accountsPlayerTag;

  /// No description provided for @accountsEnterPlayerTag.
  ///
  /// In en, this message translates to:
  /// **'Enter a player tag'**
  String get accountsEnterPlayerTag;

  /// No description provided for @accountsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get accountsAdd;

  /// No description provided for @accountsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountsDelete;

  /// No description provided for @accountsApiToken.
  ///
  /// In en, this message translates to:
  /// **'Account API Token'**
  String get accountsApiToken;

  /// No description provided for @accountsEnterApiToken.
  ///
  /// In en, this message translates to:
  /// **'Please enter the account API token to confirm it\'s yours. You can find it in Clash of Clans Settings > More Settings > API Token.'**
  String get accountsEnterApiToken;

  /// No description provided for @accountsFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields.'**
  String get accountsFillAllFields;

  /// No description provided for @accountsErrorTagNotExists.
  ///
  /// In en, this message translates to:
  /// **'The player tag entered does not exist.'**
  String get accountsErrorTagNotExists;

  /// No description provided for @accountsErrorAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'The player tag is already linked to someone.'**
  String accountsErrorAlreadyLinked(Object tag);

  /// No description provided for @accountsErrorAlreadyLinkedToYou.
  ///
  /// In en, this message translates to:
  /// **'The player tag is already linked to you.'**
  String get accountsErrorAlreadyLinkedToYou;

  /// No description provided for @accountsErrorWrongApiToken.
  ///
  /// In en, this message translates to:
  /// **'The API token entered is incorrect'**
  String get accountsErrorWrongApiToken;

  /// No description provided for @accountsErrorFailedToAdd.
  ///
  /// In en, this message translates to:
  /// **'Failed to add the account. Please try again later.'**
  String get accountsErrorFailedToAdd;

  /// No description provided for @accountsErrorFailedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete link. Please try again later.'**
  String get accountsErrorFailedToDelete;

  /// No description provided for @accountsErrorFailedToUpdateOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to update the order of accounts.'**
  String get accountsErrorFailedToUpdateOrder;

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

  /// Error message when the app version cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Error loading version'**
  String get errorLoadingVersion;

  /// No description provided for @errorCannotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'We can\'t open this link.'**
  String get errorCannotOpenLink;

  /// No description provided for @errorExitAppToOpenClash.
  ///
  /// In en, this message translates to:
  /// **'You are about to leave the app to open Clash of Clans.'**
  String get errorExitAppToOpenClash;

  /// No description provided for @playerSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search player'**
  String get playerSearchTitle;

  /// No description provided for @playerSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Player\'s name or tag'**
  String get playerSearchPlaceholder;

  /// No description provided for @playerLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active: {date}'**
  String playerLastActive(String date);

  /// No description provided for @playerNotTracked.
  ///
  /// In en, this message translates to:
  /// **'This player is not tracked. Data may be inaccurate.'**
  String get playerNotTracked;

  /// No description provided for @playerClanDescription.
  ///
  /// In en, this message translates to:
  /// **'Your clan is \"{clan}\" ({tag}).'**
  String playerClanDescription(String clan, String tag);

  /// No description provided for @playerRatioDescription.
  ///
  /// In en, this message translates to:
  /// **'Your donation ratio is {ratio}. You have donated {donations} troops and received {received} troops.'**
  String playerRatioDescription(
      String ratio, String donations, String received);

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

  /// No description provided for @gameBaseHome.
  ///
  /// In en, this message translates to:
  /// **'Home Base'**
  String get gameBaseHome;

  /// No description provided for @gameBaseBuilder.
  ///
  /// In en, this message translates to:
  /// **'Builder Base'**
  String get gameBaseBuilder;

  /// No description provided for @gameClanCapital.
  ///
  /// In en, this message translates to:
  /// **'Clan Capital'**
  String get gameClanCapital;

  /// No description provided for @gameTownHall.
  ///
  /// In en, this message translates to:
  /// **'TH'**
  String get gameTownHall;

  /// No description provided for @gameTownHallLevel.
  ///
  /// In en, this message translates to:
  /// **'TH Level'**
  String get gameTownHallLevel;

  /// No description provided for @gameTownHallLevelNumber.
  ///
  /// In en, this message translates to:
  /// **'Town Hall {level}'**
  String gameTownHallLevelNumber(int level);

  /// No description provided for @gameTHLevel.
  ///
  /// In en, this message translates to:
  /// **'TH{level}'**
  String gameTHLevel(int level);

  /// No description provided for @gameExpLevel.
  ///
  /// In en, this message translates to:
  /// **'Experience Level'**
  String get gameExpLevel;

  /// No description provided for @gameTrophies.
  ///
  /// In en, this message translates to:
  /// **'Trophies'**
  String get gameTrophies;

  /// No description provided for @gameBuilderBaseTrophies.
  ///
  /// In en, this message translates to:
  /// **'BB Trophies'**
  String get gameBuilderBaseTrophies;

  /// No description provided for @gameDonations.
  ///
  /// In en, this message translates to:
  /// **'Donations'**
  String get gameDonations;

  /// No description provided for @gameDonationsReceived.
  ///
  /// In en, this message translates to:
  /// **'Donations Received'**
  String get gameDonationsReceived;

  /// No description provided for @gameDonationsRatio.
  ///
  /// In en, this message translates to:
  /// **'Donation Ratio'**
  String get gameDonationsRatio;

  /// No description provided for @gameLevel.
  ///
  /// In en, this message translates to:
  /// **'Level: {level}/{maxLevel}'**
  String gameLevel(int level, int maxLevel);

  /// No description provided for @gameHeroes.
  ///
  /// In en, this message translates to:
  /// **'Heroes'**
  String get gameHeroes;

  /// No description provided for @gameEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipments'**
  String get gameEquipment;

  /// No description provided for @gameHeroesEquipments.
  ///
  /// In en, this message translates to:
  /// **'Hero equipments'**
  String get gameHeroesEquipments;

  /// No description provided for @gameTroops.
  ///
  /// In en, this message translates to:
  /// **'Troops'**
  String get gameTroops;

  /// No description provided for @gameActiveSuperTroops.
  ///
  /// In en, this message translates to:
  /// **'Active Super Troops'**
  String get gameActiveSuperTroops;

  /// No description provided for @gamePets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get gamePets;

  /// No description provided for @gameSiegeMachines.
  ///
  /// In en, this message translates to:
  /// **'Siege Machines'**
  String get gameSiegeMachines;

  /// No description provided for @gameSpells.
  ///
  /// In en, this message translates to:
  /// **'Spells'**
  String get gameSpells;

  /// No description provided for @gameAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get gameAchievements;

  /// No description provided for @gameClanGames.
  ///
  /// In en, this message translates to:
  /// **'Clan Games'**
  String get gameClanGames;

  /// No description provided for @gameSeasonPass.
  ///
  /// In en, this message translates to:
  /// **'Season Pass'**
  String get gameSeasonPass;

  /// No description provided for @gameCreatorCode.
  ///
  /// In en, this message translates to:
  /// **'Creator Code: ClashKing'**
  String get gameCreatorCode;

  /// No description provided for @clanTitle.
  ///
  /// In en, this message translates to:
  /// **'Clan'**
  String get clanTitle;

  /// No description provided for @clanSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search clan'**
  String get clanSearchTitle;

  /// No description provided for @clanSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Clan\'s name'**
  String get clanSearchPlaceholder;

  /// No description provided for @clanNone.
  ///
  /// In en, this message translates to:
  /// **'No clan'**
  String get clanNone;

  /// No description provided for @clanJoinToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Join a clan to unlock new features.'**
  String get clanJoinToUnlock;

  /// No description provided for @clanMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get clanMembers;

  /// No description provided for @clanWarFrequency.
  ///
  /// In en, this message translates to:
  /// **'War frequency'**
  String get clanWarFrequency;

  /// No description provided for @clanMinimumMembers.
  ///
  /// In en, this message translates to:
  /// **'Minimum members'**
  String get clanMinimumMembers;

  /// No description provided for @clanMaximumMembers.
  ///
  /// In en, this message translates to:
  /// **'Maximum members'**
  String get clanMaximumMembers;

  /// No description provided for @clanLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get clanLocation;

  /// No description provided for @clanMinimumPoints.
  ///
  /// In en, this message translates to:
  /// **'Minimum clan points'**
  String get clanMinimumPoints;

  /// No description provided for @clanMinimumLevel.
  ///
  /// In en, this message translates to:
  /// **'Minimum clan level'**
  String get clanMinimumLevel;

  /// Clan is invite only
  ///
  /// In en, this message translates to:
  /// **'Invite Only'**
  String get clanInviteOnly;

  /// Clan is opened
  ///
  /// In en, this message translates to:
  /// **'Opened'**
  String get clanOpened;

  /// Clan is closed
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get clanClosed;

  /// No description provided for @clanRoleLeader.
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get clanRoleLeader;

  /// No description provided for @clanRoleCoLeader.
  ///
  /// In en, this message translates to:
  /// **'Co-Leader'**
  String get clanRoleCoLeader;

  /// No description provided for @clanRoleElder.
  ///
  /// In en, this message translates to:
  /// **'Elder'**
  String get clanRoleElder;

  /// No description provided for @clanRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get clanRoleMember;

  /// No description provided for @clanWarFrequencyAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get clanWarFrequencyAlways;

  /// No description provided for @clanWarFrequencyNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get clanWarFrequencyNever;

  /// No description provided for @clanWarFrequencyUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get clanWarFrequencyUnknown;

  /// No description provided for @clanWarFrequencyOncePerWeek.
  ///
  /// In en, this message translates to:
  /// **'1/week'**
  String get clanWarFrequencyOncePerWeek;

  /// No description provided for @clanWarFrequencyMoreThanOncePerWeek.
  ///
  /// In en, this message translates to:
  /// **'More than 1/week'**
  String get clanWarFrequencyMoreThanOncePerWeek;

  /// No description provided for @clanWarFrequencyRarely.
  ///
  /// In en, this message translates to:
  /// **'Rarely'**
  String get clanWarFrequencyRarely;

  /// No description provided for @timeHourIndicator.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get timeHourIndicator;

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String timeDaysAgo(int days);

  /// No description provided for @timeDayAgo.
  ///
  /// In en, this message translates to:
  /// **'{day} day ago'**
  String timeDayAgo(int day);

  /// No description provided for @timeHourAgo.
  ///
  /// In en, this message translates to:
  /// **'{hour} hour ago'**
  String timeHourAgo(int hour);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String timeHoursAgo(int hours);

  /// No description provided for @timeMinuteAgo.
  ///
  /// In en, this message translates to:
  /// **'{minute} minute ago'**
  String timeMinuteAgo(int minute);

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String timeMinutesAgo(int minutes);

  /// Indicates something happened just now
  ///
  /// In en, this message translates to:
  /// **'Just Now'**
  String get timeJustNow;

  /// No description provided for @timeEndedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Ended just now'**
  String get timeEndedJustNow;

  /// No description provided for @timeEndedMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'Ended {minutes} minutes ago'**
  String timeEndedMinutesAgo(int minutes);

  /// No description provided for @timeEndedHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'Ended {hours} hours ago'**
  String timeEndedHoursAgo(int hours);

  /// No description provided for @timeEndedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Ended {days} days ago'**
  String timeEndedDaysAgo(int days);

  /// No description provided for @timeStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Starts in {time}'**
  String timeStartsIn(String time);

  /// No description provided for @timeStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at {time}'**
  String timeStartsAt(String time);

  /// No description provided for @timeEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Ends in {time}'**
  String timeEndsIn(String time);

  /// No description provided for @timeEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends at {time}'**
  String timeEndsAt(String time);

  /// No description provided for @legendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Legend League'**
  String get legendsTitle;

  /// No description provided for @legendsNotInLeague.
  ///
  /// In en, this message translates to:
  /// **'Not in Legend League'**
  String get legendsNotInLeague;

  /// No description provided for @legendsNoDataToday.
  ///
  /// In en, this message translates to:
  /// **'You\'re not in Legend League, but past seasons are available.'**
  String get legendsNoDataToday;

  /// No description provided for @legendsStartDescription.
  ///
  /// In en, this message translates to:
  /// **'You started the day with {trophies} trophies.'**
  String legendsStartDescription(String trophies);

  /// No description provided for @legendsNoRankLocalDescription.
  ///
  /// In en, this message translates to:
  /// **'You are currently not ranked ({country}) with {trophies} trophies.'**
  String legendsNoRankLocalDescription(String country, int trophies);

  /// No description provided for @legendsRankLocalDescription.
  ///
  /// In en, this message translates to:
  /// **'You are currently ranked {rank} ({country}) with {trophies} trophies.'**
  String legendsRankLocalDescription(int rank, String country, int trophies);

  /// No description provided for @legendsGainDescription.
  ///
  /// In en, this message translates to:
  /// **'You gained {trophies} trophies for now.'**
  String legendsGainDescription(int trophies);

  /// No description provided for @legendsLossDescription.
  ///
  /// In en, this message translates to:
  /// **'You lost {trophies} trophies for now.'**
  String legendsLossDescription(int trophies);

  /// No description provided for @legendsNoGlobalRankDescription.
  ///
  /// In en, this message translates to:
  /// **'You are currently not ranked globally with {trophies} trophies.'**
  String legendsNoGlobalRankDescription(int trophies);

  /// No description provided for @legendsGlobalRankDescription.
  ///
  /// In en, this message translates to:
  /// **'You are currently ranked {rank} globally with {trophies} trophies.'**
  String legendsGlobalRankDescription(int rank, int trophies);

  /// No description provided for @legendsNoRank.
  ///
  /// In en, this message translates to:
  /// **'No ranking'**
  String get legendsNoRank;

  /// No description provided for @legendsBestTrophies.
  ///
  /// In en, this message translates to:
  /// **'Best Trophies'**
  String get legendsBestTrophies;

  /// No description provided for @legendsMostAttacks.
  ///
  /// In en, this message translates to:
  /// **'Most Attacks'**
  String get legendsMostAttacks;

  /// No description provided for @legendsLastSeason.
  ///
  /// In en, this message translates to:
  /// **'Last Season'**
  String get legendsLastSeason;

  /// No description provided for @legendsBestRank.
  ///
  /// In en, this message translates to:
  /// **'Best Global Rank'**
  String get legendsBestRank;

  /// No description provided for @legendsTrophiesBySeason.
  ///
  /// In en, this message translates to:
  /// **'Trophies by season'**
  String get legendsTrophiesBySeason;

  /// No description provided for @legendsEosTrophies.
  ///
  /// In en, this message translates to:
  /// **'End Of Season Trophies'**
  String get legendsEosTrophies;

  /// No description provided for @legendsEosDetails.
  ///
  /// In en, this message translates to:
  /// **'End Of Season Details'**
  String get legendsEosDetails;

  /// No description provided for @legendsInaccurateTitle.
  ///
  /// In en, this message translates to:
  /// **'Inaccurate data?'**
  String get legendsInaccurateTitle;

  /// No description provided for @legendsInaccurateIntro.
  ///
  /// In en, this message translates to:
  /// **'Due to limitations of the Clash of Clans API, our data might not always be perfectly accurate. Here\'s why:\n'**
  String get legendsInaccurateIntro;

  /// No description provided for @legendsInaccurateApiDelayTitle.
  ///
  /// In en, this message translates to:
  /// **'1. API Delay: '**
  String get legendsInaccurateApiDelayTitle;

  /// No description provided for @legendsInaccurateApiDelayBody.
  ///
  /// In en, this message translates to:
  /// **'The API can take up to 5 minutes to update, causing a lag in reflecting real-time trophy changes.\n'**
  String get legendsInaccurateApiDelayBody;

  /// No description provided for @legendsInaccurateConcurrentTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Concurrent Changes: \n'**
  String get legendsInaccurateConcurrentTitle;

  /// No description provided for @legendsInaccurateMultipleAttacksTitle.
  ///
  /// In en, this message translates to:
  /// **'- Multiple Attacks/Defenses: '**
  String get legendsInaccurateMultipleAttacksTitle;

  /// No description provided for @legendsInaccurateMultipleAttacksBody.
  ///
  /// In en, this message translates to:
  /// **'If multiple attacks or defenses happen in quick succession, the API might show combined results (e.g., +68 or -68).\n'**
  String get legendsInaccurateMultipleAttacksBody;

  /// No description provided for @legendsInaccurateSimultaneousTitle.
  ///
  /// In en, this message translates to:
  /// **'- Simultaneous Attack and Defense: '**
  String get legendsInaccurateSimultaneousTitle;

  /// No description provided for @legendsInaccurateSimultaneousBody.
  ///
  /// In en, this message translates to:
  /// **'If an attack and defense occur at the same time, you might see a mixed result (e.g., +4).\n'**
  String get legendsInaccurateSimultaneousBody;

  /// No description provided for @legendsInaccurateNetGainTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Net Gain/Loss: '**
  String get legendsInaccurateNetGainTitle;

  /// No description provided for @legendsInaccurateNetGainBody.
  ///
  /// In en, this message translates to:
  /// **'Despite timing issues, the overall net gain or loss for the day is accurate. '**
  String get legendsInaccurateNetGainBody;

  /// No description provided for @legendsInaccurateConclusion.
  ///
  /// In en, this message translates to:
  /// **'These limitations are common across all tools using the Clash of Clans API. We sadly can\'t fix that as it is in Supercell\'s hands. We do our best to compensate for these limits and provide results as close to reality as possible. Thank you for understanding!'**
  String get legendsInaccurateConclusion;

  /// No description provided for @statsSeasonStats.
  ///
  /// In en, this message translates to:
  /// **'Season Stats'**
  String get statsSeasonStats;

  /// Shows stats by day
  ///
  /// In en, this message translates to:
  /// **'By Day'**
  String get statsByDay;

  /// Shows stats by season
  ///
  /// In en, this message translates to:
  /// **'By Season'**
  String get statsBySeason;

  /// No description provided for @statsDayIndex.
  ///
  /// In en, this message translates to:
  /// **'Day {index}'**
  String statsDayIndex(int index);

  /// No description provided for @statsIndexDays.
  ///
  /// In en, this message translates to:
  /// **'{index} days'**
  String statsIndexDays(int index);

  /// Example: August 2024 season
  ///
  /// In en, this message translates to:
  /// **'{date} season'**
  String statsSeasonDate(String date);

  /// No description provided for @statsAllTownHalls.
  ///
  /// In en, this message translates to:
  /// **'All Town Halls'**
  String get statsAllTownHalls;

  /// No description provided for @statsMembers.
  ///
  /// In en, this message translates to:
  /// **'Members Stats'**
  String get statsMembers;

  /// No description provided for @todoTitle.
  ///
  /// In en, this message translates to:
  /// **'To-do list'**
  String get todoTitle;

  /// No description provided for @todoExplanationTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Calculation'**
  String get todoExplanationTitle;

  /// No description provided for @todoExplanationIntro.
  ///
  /// In en, this message translates to:
  /// **'The task completion percentage is calculated based on the following activities with specific weightings:'**
  String get todoExplanationIntro;

  /// No description provided for @todoExplanationLegendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Legend League:'**
  String get todoExplanationLegendsTitle;

  /// No description provided for @todoExplanationLegends.
  ///
  /// In en, this message translates to:
  /// **'Weight of 8 points per account, 1 attack = 1 point.'**
  String get todoExplanationLegends;

  /// No description provided for @todoExplanationRaidsTitle.
  ///
  /// In en, this message translates to:
  /// **'Raids:'**
  String get todoExplanationRaidsTitle;

  /// No description provided for @todoExplanationRaids.
  ///
  /// In en, this message translates to:
  /// **'Weight of 5 points per account (or 6 if the last attack has been unlocked), 1 attack = 1 point.'**
  String get todoExplanationRaids;

  /// No description provided for @todoExplanationClanWarsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clan Wars:'**
  String get todoExplanationClanWarsTitle;

  /// No description provided for @todoExplanationClanWars.
  ///
  /// In en, this message translates to:
  /// **'Weight of 2 points per account, 1 attack = 1 point.'**
  String get todoExplanationClanWars;

  /// No description provided for @todoExplanationCwlTitle.
  ///
  /// In en, this message translates to:
  /// **'Clan War League:'**
  String get todoExplanationCwlTitle;

  /// No description provided for @todoExplanationCwl.
  ///
  /// In en, this message translates to:
  /// **'Weight of 1 point per account, 1 attack = 1 point. CWL cannot be tracked if the player is not in their league clan.'**
  String get todoExplanationCwl;

  /// No description provided for @todoExplanationPassAndGamesTitle.
  ///
  /// In en, this message translates to:
  /// **'Season Pass & Clan Games:'**
  String get todoExplanationPassAndGamesTitle;

  /// No description provided for @todoExplanationPassAndGames.
  ///
  /// In en, this message translates to:
  /// **'Weight of 2 points each per account. The ratio is based on the number of days remaining (1 month for the pass and 6 days for the games). Green = on track to complete the pass or games, red = behind schedule.'**
  String get todoExplanationPassAndGames;

  /// No description provided for @todoExplanationConclusion.
  ///
  /// In en, this message translates to:
  /// **'The final percentage is calculated by dividing the total actions completed during ongoing events by the total required actions. Accounts inactive for more than 14 days are excluded from the calculation.'**
  String get todoExplanationConclusion;

  /// Number of accounts (ex: 4 accounts)
  ///
  /// In en, this message translates to:
  /// **'{number} accounts'**
  String todoAccountsNumber(int number);

  /// No description provided for @todoAccountsNumberActive.
  ///
  /// In en, this message translates to:
  /// **'{number} active accounts'**
  String todoAccountsNumberActive(int number);

  /// No description provided for @todoAccountsNumberInactive.
  ///
  /// In en, this message translates to:
  /// **'{number} inactive accounts'**
  String todoAccountsNumberInactive(int number);

  /// No description provided for @todoAccountsActive.
  ///
  /// In en, this message translates to:
  /// **'Active accounts'**
  String get todoAccountsActive;

  /// No description provided for @todoAccountsInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive accounts'**
  String get todoAccountsInactive;

  /// No description provided for @todoAccountsNoInactive.
  ///
  /// In en, this message translates to:
  /// **'No inactive accounts.'**
  String get todoAccountsNoInactive;

  /// No description provided for @todoAccountsNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active accounts.'**
  String get todoAccountsNoActive;

  /// No description provided for @todoAttacksLeftDescription.
  ///
  /// In en, this message translates to:
  /// **'You have {attacks} attack(s) left ({type}).'**
  String todoAttacksLeftDescription(int attacks, String type);

  /// No description provided for @todoDefensesLeftDescription.
  ///
  /// In en, this message translates to:
  /// **'You have {defenses} defense(s) left ({type}).'**
  String todoDefensesLeftDescription(int defenses, String type);

  /// No description provided for @todoNoAttacksLeftDescription.
  ///
  /// In en, this message translates to:
  /// **'Congratulations, you have done all your attacks ({type})!'**
  String todoNoAttacksLeftDescription(String type);

  /// No description provided for @todoPointsLeftDescription.
  ///
  /// In en, this message translates to:
  /// **'You have {points} points left to get today to be in time for the end of the event ({type}).'**
  String todoPointsLeftDescription(int points, String type);

  /// No description provided for @todoPointsLeftDescriptionNoPoints.
  ///
  /// In en, this message translates to:
  /// **'Congratulations, you are on time to get the maximum rewards at the end of the event ({type})!'**
  String todoPointsLeftDescriptionNoPoints(String type);

  /// No description provided for @warTitle.
  ///
  /// In en, this message translates to:
  /// **'War'**
  String get warTitle;

  /// No description provided for @warFrequency.
  ///
  /// In en, this message translates to:
  /// **'War frequency'**
  String get warFrequency;

  /// No description provided for @warParticipation.
  ///
  /// In en, this message translates to:
  /// **'War Participation'**
  String get warParticipation;

  /// No description provided for @warLeague.
  ///
  /// In en, this message translates to:
  /// **'War/League'**
  String get warLeague;

  /// No description provided for @warHistory.
  ///
  /// In en, this message translates to:
  /// **'War History'**
  String get warHistory;

  /// No description provided for @warLog.
  ///
  /// In en, this message translates to:
  /// **'War Log'**
  String get warLog;

  /// No description provided for @warLogClosed.
  ///
  /// In en, this message translates to:
  /// **'{clan}\'s war log is closed.'**
  String warLogClosed(String clan);

  /// No description provided for @warStats.
  ///
  /// In en, this message translates to:
  /// **'War Stats'**
  String get warStats;

  /// No description provided for @warOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing war'**
  String get warOngoing;

  /// No description provided for @warIsNotInWar.
  ///
  /// In en, this message translates to:
  /// **'{clan} is not in war.'**
  String warIsNotInWar(String clan);

  /// No description provided for @warAskForWar.
  ///
  /// In en, this message translates to:
  /// **'Contact the leader or a co-leader to start a war.'**
  String get warAskForWar;

  /// No description provided for @warAskForWarLogOpening.
  ///
  /// In en, this message translates to:
  /// **'Contact a leader or a co-leader to open the war log.'**
  String get warAskForWarLogOpening;

  /// No description provided for @warEnded.
  ///
  /// In en, this message translates to:
  /// **'War ended'**
  String get warEnded;

  /// No description provided for @warPreparation.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get warPreparation;

  /// No description provided for @warPerfectWar.
  ///
  /// In en, this message translates to:
  /// **'Perfect war'**
  String get warPerfectWar;

  /// No description provided for @warVictory.
  ///
  /// In en, this message translates to:
  /// **'Victory'**
  String get warVictory;

  /// No description provided for @warDefeat.
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get warDefeat;

  /// War ended in a draw
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get warDraw;

  /// No description provided for @warTeamSize.
  ///
  /// In en, this message translates to:
  /// **'Team size'**
  String get warTeamSize;

  /// No description provided for @warMyTeam.
  ///
  /// In en, this message translates to:
  /// **'My team'**
  String get warMyTeam;

  /// No description provided for @warEnemiesTeam.
  ///
  /// In en, this message translates to:
  /// **'Enemies'**
  String get warEnemiesTeam;

  /// No description provided for @warClanDraw.
  ///
  /// In en, this message translates to:
  /// **'The two clans are tied'**
  String get warClanDraw;

  /// No description provided for @warStateOfTheWar.
  ///
  /// In en, this message translates to:
  /// **'State of the war'**
  String get warStateOfTheWar;

  /// No description provided for @warStarsNeededToTakeTheLead.
  ///
  /// In en, this message translates to:
  /// **'{clan} still need {star} more star(s) or {stars2} star(s) and {percent}% to take the lead.'**
  String warStarsNeededToTakeTheLead(
      String clan, int star, int stars2, String percent);

  /// No description provided for @warStarsAndPercentNeededToTakeTheLead.
  ///
  /// In en, this message translates to:
  /// **'{clan} still need {percent}% or 1 more star to take the lead'**
  String warStarsAndPercentNeededToTakeTheLead(String clan, String percent);

  /// No description provided for @warNoDataAvailableForThisWar.
  ///
  /// In en, this message translates to:
  /// **'No data available for this war'**
  String get warNoDataAvailableForThisWar;

  /// No description provided for @warCalculatorFast.
  ///
  /// In en, this message translates to:
  /// **'Fast calculator'**
  String get warCalculatorFast;

  /// No description provided for @warCalculatorAnswer.
  ///
  /// In en, this message translates to:
  /// **'To achieve a destruction rate of {percentNeeded}%, a total of {result}% is needed.'**
  String warCalculatorAnswer(String percentNeeded, String result);

  /// No description provided for @warCalculatorNeededOverall.
  ///
  /// In en, this message translates to:
  /// **'% Needed overall'**
  String get warCalculatorNeededOverall;

  /// No description provided for @warCalculatorCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get warCalculatorCalculate;

  /// No description provided for @warAttacksTitle.
  ///
  /// In en, this message translates to:
  /// **'Attacks'**
  String get warAttacksTitle;

  /// No attack yet in war
  ///
  /// In en, this message translates to:
  /// **'No attack yet'**
  String get warAttacksNone;

  /// No description provided for @warAttacksBest.
  ///
  /// In en, this message translates to:
  /// **'Best attacks'**
  String get warAttacksBest;

  /// No description provided for @warAttacksCount.
  ///
  /// In en, this message translates to:
  /// **'Attack Count'**
  String get warAttacksCount;

  /// No description provided for @warAttacksMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed Attacks'**
  String get warAttacksMissed;

  /// No description provided for @warAttacksNumber.
  ///
  /// In en, this message translates to:
  /// **'You attacked {number_time} time(s) during the last {number_war} wars.'**
  String warAttacksNumber(int number_time, int number_war);

  /// No description provided for @warAttacksAverageStars.
  ///
  /// In en, this message translates to:
  /// **'You had an average of {stars} stars per war.'**
  String warAttacksAverageStars(String stars);

  /// No description provided for @warAttacksAverageDestruction.
  ///
  /// In en, this message translates to:
  /// **'You had an average of {percent}% destruction rate per war.'**
  String warAttacksAverageDestruction(String percent);

  /// No description provided for @warDefensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Defenses'**
  String get warDefensesTitle;

  /// No defense yet in war
  ///
  /// In en, this message translates to:
  /// **'No defense yet'**
  String get warDefensesNone;

  /// No description provided for @warDefensesBest.
  ///
  /// In en, this message translates to:
  /// **'Best defenses'**
  String get warDefensesBest;

  /// Best war defense (out of 3 defenses)
  ///
  /// In en, this message translates to:
  /// **'Best defense (out of {number})'**
  String warDefensesBestOutOf(int number);

  /// No description provided for @warDefensesNumber.
  ///
  /// In en, this message translates to:
  /// **'You defended {number_time} time(s) during the last {number_war} wars.'**
  String warDefensesNumber(int number_time, int number_war);

  /// No description provided for @warDefensesAverageStars.
  ///
  /// In en, this message translates to:
  /// **'You had an average of {stars} stars per defense.'**
  String warDefensesAverageStars(double stars);

  /// No description provided for @warDefensesAverageDestruction.
  ///
  /// In en, this message translates to:
  /// **'You had an average of {percent}% destruction rate per defense.'**
  String warDefensesAverageDestruction(String percent);

  /// No description provided for @warStarsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get warStarsTitle;

  /// No description provided for @warStarsAverage.
  ///
  /// In en, this message translates to:
  /// **'Average stars'**
  String get warStarsAverage;

  /// No description provided for @warStarsNumber.
  ///
  /// In en, this message translates to:
  /// **'Number of stars'**
  String get warStarsNumber;

  /// No description provided for @warStarsOne.
  ///
  /// In en, this message translates to:
  /// **'1 star'**
  String get warStarsOne;

  /// No description provided for @warStarsTwo.
  ///
  /// In en, this message translates to:
  /// **'2 stars'**
  String get warStarsTwo;

  /// No description provided for @warStarsThree.
  ///
  /// In en, this message translates to:
  /// **'3 stars'**
  String get warStarsThree;

  /// No description provided for @warStarsZero.
  ///
  /// In en, this message translates to:
  /// **'0 Star'**
  String get warStarsZero;

  /// Best performance in war
  ///
  /// In en, this message translates to:
  /// **'Best performance'**
  String get warStarsBestPerformance;

  /// No description provided for @warDestructionTitle.
  ///
  /// In en, this message translates to:
  /// **'Destruction'**
  String get warDestructionTitle;

  /// No description provided for @warDestructionAverage.
  ///
  /// In en, this message translates to:
  /// **'Average destruction'**
  String get warDestructionAverage;

  /// Percentage of destruction in war
  ///
  /// In en, this message translates to:
  /// **'Destruction rate'**
  String get warDestructionRate;

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

  /// Map position in war
  ///
  /// In en, this message translates to:
  /// **'Map Position'**
  String get warPositionMap;

  /// Abbreviation for map position
  ///
  /// In en, this message translates to:
  /// **'Pos'**
  String get warPositionAbbr;

  /// Order of the player in the clan
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get warPositionOrder;

  /// Abbreviation for opponent's town hall level
  ///
  /// In en, this message translates to:
  /// **'Opp TH'**
  String get warOpponentTownhall;

  /// No description provided for @warOpponentLowerTownhall.
  ///
  /// In en, this message translates to:
  /// **'Lower TH'**
  String get warOpponentLowerTownhall;

  /// No description provided for @warOpponentUpperTownhall.
  ///
  /// In en, this message translates to:
  /// **'Upper TH'**
  String get warOpponentUpperTownhall;

  /// No description provided for @warOpponentEqualThLevel.
  ///
  /// In en, this message translates to:
  /// **'Equal TH'**
  String get warOpponentEqualThLevel;

  /// No description provided for @warOpponentSelectMembersThLevel.
  ///
  /// In en, this message translates to:
  /// **'Members TH Level'**
  String get warOpponentSelectMembersThLevel;

  /// No description provided for @warOpponentSelectOpponentsThLevel.
  ///
  /// In en, this message translates to:
  /// **'Opponents TH Level'**
  String get warOpponentSelectOpponentsThLevel;

  /// Example: Shows the last 25 wars
  ///
  /// In en, this message translates to:
  /// **'Last {number} wars'**
  String warFiltersLastXwars(int number);

  /// Friendly war
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get warFiltersFriendly;

  /// Random/basic war (not friendly or cwl)
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get warFiltersRandom;

  /// For example, hide stats from TH15 and below if the player is now TH16
  ///
  /// In en, this message translates to:
  /// **'Hide/Show stats from former TH levels'**
  String get warVisibilityToggleTownHall;

  /// War events
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get warEventsTitle;

  /// No description provided for @warEventsNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get warEventsNewest;

  /// No description provided for @warEventsOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get warEventsOldest;

  /// Opted In for war
  ///
  /// In en, this message translates to:
  /// **'Opted In'**
  String get warStatusReady;

  /// Opted Out for war
  ///
  /// In en, this message translates to:
  /// **'Opted Out'**
  String get warStatusUnready;

  /// Missed attacks
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get warStatusMissed;

  /// Abbreviation for average
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get warAbbreviationAvg;

  /// Abbreviation for average percentage
  ///
  /// In en, this message translates to:
  /// **'Avg %'**
  String get warAbbreviationAvgPercentage;

  /// No description provided for @cwlTitle.
  ///
  /// In en, this message translates to:
  /// **'CWL'**
  String get cwlTitle;

  /// No description provided for @cwlClanWarLeague.
  ///
  /// In en, this message translates to:
  /// **'Clan War League'**
  String get cwlClanWarLeague;

  /// No description provided for @cwlOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing CWL'**
  String get cwlOngoing;

  /// No description provided for @cwlRounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get cwlRounds;

  /// No description provided for @cwlRoundNumber.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String cwlRoundNumber(int number);

  /// No description provided for @cwlCurrentRound.
  ///
  /// In en, this message translates to:
  /// **'Current round (Round {round})'**
  String cwlCurrentRound(int round);

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

  /// Logs of players joining or leaving the clan.
  ///
  /// In en, this message translates to:
  /// **'Join/Leave Logs (Current Season)'**
  String get joinLeaveTitle;

  /// No description provided for @joinLeaveJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinLeaveJoin;

  /// No description provided for @joinLeaveLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get joinLeaveLeave;

  /// No description provided for @joinLeaveReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get joinLeaveReset;

  /// No description provided for @joinLeaveJoins.
  ///
  /// In en, this message translates to:
  /// **'Joins'**
  String get joinLeaveJoins;

  /// No description provided for @joinLeaveLeaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get joinLeaveLeaves;

  /// No description provided for @joinLeaveUniquePlayers.
  ///
  /// In en, this message translates to:
  /// **'Unique Players'**
  String get joinLeaveUniquePlayers;

  /// No description provided for @joinLeaveMovingPlayers.
  ///
  /// In en, this message translates to:
  /// **'Moving Players'**
  String get joinLeaveMovingPlayers;

  /// No description provided for @joinLeaveMostMovingPlayers.
  ///
  /// In en, this message translates to:
  /// **'Most Moving Players'**
  String get joinLeaveMostMovingPlayers;

  /// No description provided for @joinLeaveStillInClan.
  ///
  /// In en, this message translates to:
  /// **'Still in Clan'**
  String get joinLeaveStillInClan;

  /// No description provided for @joinLeaveLeftForever.
  ///
  /// In en, this message translates to:
  /// **'Left Forever'**
  String get joinLeaveLeftForever;

  /// No description provided for @joinLeaveRejoinedPlayers.
  ///
  /// In en, this message translates to:
  /// **'Rejoined Players'**
  String get joinLeaveRejoinedPlayers;

  /// No description provided for @joinLeaveAvgTimeJoinLeave.
  ///
  /// In en, this message translates to:
  /// **'Avg Join/Leave Time'**
  String get joinLeaveAvgTimeJoinLeave;

  /// No description provided for @joinLeavePeakHour.
  ///
  /// In en, this message translates to:
  /// **'Most Active Hour'**
  String get joinLeavePeakHour;

  /// No description provided for @joinLeaveNumberDescription.
  ///
  /// In en, this message translates to:
  /// **'{number} leave events occurred during the current season ({date}).'**
  String joinLeaveNumberDescription(int number, String date);

  /// No description provided for @joinLeaveJoinNumberDescription.
  ///
  /// In en, this message translates to:
  /// **'{number} join events occurred during the current season ({date}).'**
  String joinLeaveJoinNumberDescription(int number, String date);

  /// Number of players who left and rejoined the clan during the current season.
  ///
  /// In en, this message translates to:
  /// **'{number} player(s) left and rejoined the clan during the current season ({date}).'**
  String joinLeaveMovingNumberDescription(int number, String date);

  /// Number of unique players who joined/left the clan during the current season.
  ///
  /// In en, this message translates to:
  /// **'{number} unique player(s) joined/left the clan during the current season ({date}).'**
  String joinLeaveUniqueNumberDescription(int number, String date);

  /// No description provided for @joinLeaveStillInClanNumberDescription.
  ///
  /// In en, this message translates to:
  /// **'{number} player(s) joined and are still in the clan.'**
  String joinLeaveStillInClanNumberDescription(int number);

  /// No description provided for @joinLeaveLeftClanNumberDescription.
  ///
  /// In en, this message translates to:
  /// **'{number} player(s) joined, then left the clan and never rejoined.'**
  String joinLeaveLeftClanNumberDescription(int number);

  /// [The player] left the clan on 16/06/2024 at 10:35.
  ///
  /// In en, this message translates to:
  /// **'Left on {date} at {time}.'**
  String joinLeaveLeftOnAt(String date, String time);

  /// [The player] joined the clan on 16/06/2024 at 10:35.
  ///
  /// In en, this message translates to:
  /// **'Joined on {date} at {time}.'**
  String joinLeaveJoinedOnAt(String date, String time);

  /// No description provided for @raidsTitle.
  ///
  /// In en, this message translates to:
  /// **'Raids'**
  String get raidsTitle;

  /// No description provided for @raidsLast.
  ///
  /// In en, this message translates to:
  /// **'Last raids'**
  String get raidsLast;

  /// No description provided for @raidsOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing raids'**
  String get raidsOngoing;

  /// No description provided for @raidsDistrictsDestroyed.
  ///
  /// In en, this message translates to:
  /// **'Districts destroyed'**
  String get raidsDistrictsDestroyed;

  /// No description provided for @raidsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Raids completed'**
  String get raidsCompleted;

  /// No description provided for @searchNoResult.
  ///
  /// In en, this message translates to:
  /// **'No result.'**
  String get searchNoResult;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Clash of Clans is currently under maintenance, so we can\'t access the API. Please check back later.'**
  String get maintenanceDescription;

  /// No description provided for @downloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download CWL summary'**
  String get downloadTooltip;

  /// No description provided for @downloadInProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading file... It can take a few seconds...'**
  String get downloadInProgress;

  /// No description provided for @downloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'File saved successfully in {path}'**
  String downloadSuccess(String path);

  /// No description provided for @downloadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to download file'**
  String get downloadError;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @toolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsTitle;

  /// No description provided for @navigationTeam.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get navigationTeam;

  /// No description provided for @navigationStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get navigationStatistics;

  /// Version of the app and device information
  ///
  /// In en, this message translates to:
  /// **'Version & Device'**
  String get versionDevice;

  /// No description provided for @betaFeature.
  ///
  /// In en, this message translates to:
  /// **'Beta Feature'**
  String get betaFeature;

  /// No description provided for @betaLabel.
  ///
  /// In en, this message translates to:
  /// **'BETA'**
  String get betaLabel;

  /// No description provided for @betaDescription.
  ///
  /// In en, this message translates to:
  /// **'This feature is currently in beta, it may have some bugs or be incomplete. We are actively working on improvements and welcome your feedback. Please share your ideas and report any issues in our Discord Server to help us make it better.'**
  String get betaDescription;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select a language'**
  String get settingsSelectLanguage;

  /// No description provided for @settingsToggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle Theme'**
  String get settingsToggleTheme;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faqTitle;

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

  /// No description provided for @translationHelpUsTranslate.
  ///
  /// In en, this message translates to:
  /// **'Help us translate'**
  String get translationHelpUsTranslate;

  /// No description provided for @translationSuggestFeatures.
  ///
  /// In en, this message translates to:
  /// **'Suggest features'**
  String get translationSuggestFeatures;

  /// No description provided for @translationThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get translationThankYou;

  /// No description provided for @translationThankYouContent.
  ///
  /// In en, this message translates to:
  /// **'A huge thank you to all our amazing translators who help us make this app accessible to more people around the world!'**
  String get translationThankYouContent;

  /// No description provided for @translationHelpTranslateContent.
  ///
  /// In en, this message translates to:
  /// **'You can help us translate the app on Crowdin. If your language is not available on Crowdin, feel free to request it in our Discord Server. Thank you so much for your help!'**
  String get translationHelpTranslateContent;

  /// No description provided for @translationHelpTranslateButton.
  ///
  /// In en, this message translates to:
  /// **'Help Translate on Crowdin'**
  String get translationHelpTranslateButton;

  /// No description provided for @translationCurrentTranslators.
  ///
  /// In en, this message translates to:
  /// **'Current Translators'**
  String get translationCurrentTranslators;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'af',
        'ar',
        'ca',
        'cs',
        'da',
        'de',
        'el',
        'en',
        'es',
        'fi',
        'fr',
        'he',
        'hi',
        'hu',
        'it',
        'ja',
        'ko',
        'nl',
        'no',
        'pl',
        'pt',
        'ro',
        'ru',
        'sr',
        'sv',
        'tr',
        'uk',
        'ur',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'GB':
            return AppLocalizationsEnGb();
          case 'US':
            return AppLocalizationsEnUs();
        }
        break;
      }
    case 'es':
      {
        switch (locale.countryCode) {
          case 'ES':
            return AppLocalizationsEsEs();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'af':
      return AppLocalizationsAf();
    case 'ar':
      return AppLocalizationsAr();
    case 'ca':
      return AppLocalizationsCa();
    case 'cs':
      return AppLocalizationsCs();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'he':
      return AppLocalizationsHe();
    case 'hi':
      return AppLocalizationsHi();
    case 'hu':
      return AppLocalizationsHu();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'no':
      return AppLocalizationsNo();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'sr':
      return AppLocalizationsSr();
    case 'sv':
      return AppLocalizationsSv();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'ur':
      return AppLocalizationsUr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
