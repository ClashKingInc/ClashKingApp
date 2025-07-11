// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'ClashKing';

  @override
  String get appDescription =>
      'Your ultimate Clash of Clans companion for tracking stats, managing clans, and analyzing performance.';

  @override
  String get generalLoading => 'Φορτώνει...';

  @override
  String get loadingVillages => 'Loading your villages...';

  @override
  String get loadingClanData => 'Fetching clan data...';

  @override
  String get loadingWarStats => 'Analyzing war stats...';

  @override
  String get loadingLegendsData => 'Preparing legends data...';

  @override
  String get loadingCapitalRaids => 'Loading capital raids...';

  @override
  String get loadingAlmostReady => 'Almost ready...';

  @override
  String get accountVerificationTitle => 'Verify Account';

  @override
  String get accountVerificationMessage =>
      'Enter your API token to verify you own this account. You can find it in Clash of Clans Settings > More Settings > API Token.';

  @override
  String get accountVerified => 'Account verified';

  @override
  String get accountNotVerified => 'Account not verified';

  @override
  String get accountVerifyButton => 'Verify';

  @override
  String get accountVerificationSuccess => 'Account verified successfully!';

  @override
  String get accountVerificationFailed =>
      'Verification failed. Please check your API token.';

  @override
  String get generalRetry => 'Retry';

  @override
  String get generalTryAgain => 'Try again';

  @override
  String get generalCancel => 'Cancel';

  @override
  String get generalOk => 'OK';

  @override
  String get generalApply => 'Apply';

  @override
  String get generalConfirm => 'Confirm';

  @override
  String get generalManage => 'Διαχείριση';

  @override
  String get generalSettings => 'Ρυθμίσεις';

  @override
  String get generalCopiedToClipboard => 'Αντιγράφηκε στο πρόχειρο';

  @override
  String get generalComingSoon => 'Coming soon!';

  @override
  String generalLastRefresh(String time) {
    return 'Last refresh: $time';
  }

  @override
  String generalRefreshFailed(String error) {
    return 'Refresh failed: $error';
  }

  @override
  String get generalAll => 'Όλα';

  @override
  String get generalTotal => 'Σύνολο';

  @override
  String get generalBest => 'Καλύτερο';

  @override
  String get generalWorst => 'Χειρότερο';

  @override
  String get generalAverage => 'Μέσος όρος';

  @override
  String get generalRemaining => 'Απομένει';

  @override
  String get generalActive => 'Active';

  @override
  String get generalInactive => 'Inactive';

  @override
  String get generalStarted => 'Ξεκίνησε';

  @override
  String get generalEnded => 'Έληξε';

  @override
  String get generalRole => 'Role';

  @override
  String get generalStats => 'Στατιστικά';

  @override
  String get generalFullStats => 'Full Stats';

  @override
  String get generalDetails => 'Λεπτομέρειες';

  @override
  String get generalHistory => 'Ιστορικό';

  @override
  String get generalFilters => 'Filters';

  @override
  String get generalNotSet => 'Not set';

  @override
  String get generalWarning => 'Προειδοποίηση';

  @override
  String get generalNoDataAvailable => 'Δεν υπάρχουν διαθέσιμα δεδομένα.';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authLogin => 'Είσοδος';

  @override
  String get authLogout => 'Έξοδος';

  @override
  String get authCreateAccount => 'Create Account';

  @override
  String get authJoinClashKing => 'Join ClashKing';

  @override
  String get authCreateClashKingAccount => 'Create ClashKing Account';

  @override
  String get authCreateAccountToGetStarted =>
      'Create your account to get started';

  @override
  String get authAlreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get authConfirmLogout => 'Are you sure you want to log out?';

  @override
  String get authDiscordTitle => 'Discord';

  @override
  String get authDiscordSignIn => 'Είσοδος με Discord';

  @override
  String get authDiscordContinue => 'Continue with Discord';

  @override
  String get authDiscordDescription =>
      'Sync your data with ClashKing Bot and unlock the full potential of ClashKing!';

  @override
  String get authEmailTitle => 'Email';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'Enter your email address';

  @override
  String get authEmailDescription =>
      'Use email if you can\'t access Discord or prefer app-only features';

  @override
  String get authEmailRequired => 'Please enter your email';

  @override
  String get authEmailInvalid => 'Please enter a valid email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authPasswordConfirm => 'Confirm Password';

  @override
  String get authPasswordRequired => 'Please enter your password';

  @override
  String get authPasswordConfirmRequired => 'Please confirm your password';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get authPasswordRequirements =>
      'Password must contain: uppercase, lowercase, digit, and special character';

  @override
  String get authPasswordForgot => 'Forgot password?';

  @override
  String get authPasswordForgotDescription =>
      'Enter your email address and we\'ll send you a 6-digit code to reset your password.';

  @override
  String get authPasswordResetSend => 'Send Reset Code';

  @override
  String get authPasswordResetSent => 'Code Sent!';

  @override
  String get authPasswordResetSentDescription =>
      'We\'ve sent a 6-digit reset code to your email address. Please check your inbox and use the code to reset your password.';

  @override
  String get authPasswordReset => 'Reset Password';

  @override
  String get authPasswordResetDescription =>
      'Enter your email, the 6-digit code from the email, and your new password below.';

  @override
  String get authPasswordNew => 'New Password';

  @override
  String get authPasswordConfirmHint => 'Re-enter your new password';

  @override
  String get authPasswordResetConfirm => 'Reset Password';

  @override
  String get authPasswordResetSuccess =>
      'Password reset successful! You can now log in.';

  @override
  String get authPasswordResetContinue => 'Continue to Reset Password';

  @override
  String get authPasswordResetCode => 'Reset Code';

  @override
  String get authPasswordResetCodeHint =>
      'Enter the 6-digit code from your email';

  @override
  String get authPasswordResetCodeRequired => 'Please enter the reset code';

  @override
  String get authPasswordResetCodeInvalid =>
      'Please enter a valid 6-digit code';

  @override
  String get authBackToLogin => 'Back to Login';

  @override
  String get authUsernameLabel => 'Username';

  @override
  String get authUsernameRequired => 'Please enter a username';

  @override
  String get authUsernameTooShort => 'Username must be at least 3 characters';

  @override
  String get authErrorConnection =>
      'An error occurred. Please check your internet connection and try again.';

  @override
  String get authErrorConnectionRelaunch =>
      'An error occurred. Please check your internet connection and relaunch the app.';

  @override
  String get authErrorEmailAlreadyRegistered =>
      'This email is already registered. Please try logging in instead.';

  @override
  String get authErrorEmailAlreadyPending =>
      'A verification email was already sent to this address. Please check your email or try resending.';

  @override
  String get authErrorEmailInvalidFormat =>
      'Please enter a valid email address.';

  @override
  String get authErrorPasswordWeak =>
      'Password is too weak. Please use a stronger password.';

  @override
  String get authErrorUsernameInvalid =>
      'Username is invalid. Please use only letters, numbers, and underscores.';

  @override
  String get authErrorUsernameExists =>
      'This username is already taken. Please choose a different one.';

  @override
  String get authErrorRegistrationFailed =>
      'Registration failed. Please try again later.';

  @override
  String get authErrorEmailSendFailed =>
      'Failed to send verification email. Please try again later.';

  @override
  String get authErrorRateLimited =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get authErrorServerUnavailable =>
      'Server is temporarily unavailable. Please try again later.';

  @override
  String get authAccountManagement =>
      'Add, remove, and reorder your Clash of Clans accounts. Verify your accounts to access all features.';

  @override
  String get authAccountConnected => 'Connected Accounts';

  @override
  String get authAccountConnectedStatus => 'Connected';

  @override
  String get authAccountNotConnected => 'Not connected';

  @override
  String get authAccountEmailAndPassword => 'Email & Password';

  @override
  String get authAccountSecured =>
      'Your account is secured with multiple authentication methods';

  @override
  String get authAccountLinkEmail => 'Link Email Account';

  @override
  String get authAccountAddEmailAuth =>
      'Add email & password authentication to your account for additional security.';

  @override
  String get authAccountEmailLinkedSuccess =>
      'Email account successfully linked!';

  @override
  String get authEmailVerificationTitle => 'Verify Email';

  @override
  String get authEmailVerificationCheckEmail => 'Check Your Email';

  @override
  String get authEmailVerificationSentTo =>
      'We\'ve sent a verification email to:';

  @override
  String get authEmailVerificationInstructions =>
      'Click the link in the email to verify your account. If you don\'t see the email, check your spam folder.';

  @override
  String get authEmailVerificationResend => 'Resend Verification Email';

  @override
  String get authEmailVerificationResendSuccess =>
      'Verification email resent successfully! Please check your email.';

  @override
  String get authEmailVerificationResendFailed =>
      'Failed to resend verification email. Please try again.';

  @override
  String get authEmailVerificationBackToLogin => 'Back to Login';

  @override
  String get authEmailVerificationDevToken =>
      'I have a verification token (Dev)';

  @override
  String get authEmailVerificationDevMode =>
      'Development Mode - Manual Token Input:';

  @override
  String get authEmailVerificationTokenLabel => 'Verification Token';

  @override
  String get authEmailVerificationTokenRequired =>
      'Verification token is required';

  @override
  String get authEmailVerificationVerifyButton => 'Verify Email';

  @override
  String get authEmailVerificationExpired =>
      'Verification expired. Please register again.';

  @override
  String get authEmailVerificationAlreadyVerified =>
      'This email is already verified. Please try logging in instead.';

  @override
  String get authEmailVerificationNoToken =>
      'No pending verification found. Please register first.';

  @override
  String get authEmailVerificationVerifying => 'Verifying your email...';

  @override
  String get authEmailVerificationCodeInstructions =>
      'Enter the 6-digit code sent to your email:';

  @override
  String get authEmailVerificationCodeRequired =>
      'Please enter the 6-digit verification code';

  @override
  String get authEmailVerificationVerify => 'Verify Code';

  @override
  String get helpTitle => 'Need help?';

  @override
  String get helpJoinDiscord => 'Join Discord';

  @override
  String get helpEmailUs => 'Email Us';

  @override
  String get accountsWelcome => 'Καλώς Ήλθατε!';

  @override
  String get accountsWelcomeMessage =>
      'Παρακαλώ προσθέστε έναν ή περισσότερους λογαριασμούς \"Clash Of Clans\" στο προφίλ σας. Μπορείτε να προσθέσετε ή να αφαιρέσετε λογαριασμούς αργότερα.';

  @override
  String get accountsManageTitle => 'Manage your accounts';

  @override
  String get accountsNoneFound => 'No account linked to your profile found';

  @override
  String get accountsPlayerTag => 'Player Tag (#ABC123)';

  @override
  String get accountsEnterPlayerTag => 'Εισάγετε ετικέτα λογαριασμού';

  @override
  String get accountsAdd => 'Προσθήκη λογαριασμού';

  @override
  String get accountsDelete => 'Διαγραφή λογαριασμού';

  @override
  String get accountsApiToken => 'Κλειδί API λογαριασμού';

  @override
  String get accountsEnterApiToken =>
      'Παρακαλώ εισάγετε το κλειδί «API» του λογαριασμού σας για να επιβεβαιώσετε ότι είναι δικός σας. Μπορείτε να το βρείτε στο Clash of Clans > Ρυθμίσεις > Περισσότερες Ρυθμίσεις > Κλειδί API.';

  @override
  String get accountsFillAllFields => 'Please fill all fields.';

  @override
  String get accountsErrorTagNotExists =>
      'Ο αριθμός λογαριασμού που καταγράψατε δεν υπάρχει.';

  @override
  String accountsErrorAlreadyLinked(Object tag) {
    return 'Ο αριθμός λογαριασμού είναι ήδη συνδεδεμένος σε κάποιον.';
  }

  @override
  String get accountsErrorAlreadyLinkedToYou =>
      'Ο αριθμός λογαριασμού είναι ήδη συνδεδεμένος σε εσάς.';

  @override
  String get accountsErrorWrongApiToken =>
      'Το κλειδί API που εισάγατε είναι λάθος';

  @override
  String get accountsErrorFailedToAdd =>
      'Failed to add the account. Please try again later.';

  @override
  String get accountsErrorFailedToDelete =>
      'Σφάλμα στη διαγραφή της σύνδεσης. Παρακαλώ προσπαθήστε ξανά αργότερα.';

  @override
  String get accountsErrorFailedToUpdateOrder =>
      'Failed to update the order of accounts.';

  @override
  String get errorTitle =>
      'Oops! Our servers might have taken a fireball to the face! We\'re casting a healing spell... Try again in a moment.';

  @override
  String get errorSubtitle =>
      'If the issue persists, check our Discord Server to see if we\'re aware of it.';

  @override
  String get errorLoadingVersion => 'Σφάλμα στη φόρτωσης της εκδοχής';

  @override
  String get errorCannotOpenLink => 'We can\'t open this link.';

  @override
  String get errorExitAppToOpenClash =>
      'Πρόκειται να βγείτε από την εφαρμογή για να ανοίξετε το Clash of Clans.';

  @override
  String get playerSearchTitle => 'Αναζήτηση παίχτη';

  @override
  String get playerSearchPlaceholder => 'Όνομα παίχτη ή αριθμός λογαριασμού';

  @override
  String playerLastActive(String date) {
    return 'Τελευταία ενεργός: $date';
  }

  @override
  String get playerNotTracked =>
      'Αυτός ο παίχτης δεν καταγράφεται. Τα δεδομένα ενδέχεται να είναι ανακριβή.';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Η ομάδα σας είναι η \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(
      String ratio, String donations, String received) {
    return 'Η αναλογία δωρεάς σας είναι $ratio. Έχετε δωρίσει $donations στρατιώτες και έχετε λάβει $received.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Η προτίμηση πολέμου σας είναι \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'Έχετε $stars αστέρια πολέμου.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'Διαθέτετε $trophies τρόπαια. Βρίσκεστε στο επίπεδο $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Το επίπεδο του Δημαρχείου σας είναι $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Το επίπεδο του Δημαρχείου Χτίστη σας είναι $level και διαθέτετε $trophies τρόπαια.';
  }

  @override
  String get gameBaseHome => 'Κύρια Βάση';

  @override
  String get gameBaseBuilder => 'Βάση Χτίστη';

  @override
  String get gameClanCapital => 'Πρωτεύουσα Φυλής';

  @override
  String get gameTownHall => 'Δ';

  @override
  String get gameTownHallLevel => 'TH Level';

  @override
  String gameTownHallLevelNumber(int level) {
    return 'Town Hall $level';
  }

  @override
  String gameTHLevel(int level) {
    return 'TH$level';
  }

  @override
  String get gameExpLevel => 'Experience Level';

  @override
  String get gameTrophies => 'Trophies';

  @override
  String get gameBuilderBaseTrophies => 'BB Trophies';

  @override
  String get gameDonations => 'Donations';

  @override
  String get gameDonationsReceived => 'Donations Received';

  @override
  String get gameDonationsRatio => 'Donation Ratio';

  @override
  String gameLevel(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get gameHeroes => 'Ήρωες';

  @override
  String get gameEquipment => 'Εξοπλισμός';

  @override
  String get gameHeroesEquipments => 'Εξοπλισμοί ηρώων';

  @override
  String get gameTroops => 'Στρατός';

  @override
  String get gameActiveSuperTroops => 'Ενεργός Σούπερ Στρατός';

  @override
  String get gamePets => 'Κατοικίδια';

  @override
  String get gameSiegeMachines => 'Μηχανές Πολιορκίας';

  @override
  String get gameSpells => 'Ξόρκια';

  @override
  String get gameAchievements => 'Επιτεύγματα';

  @override
  String get gameClanGames => 'Clan Games';

  @override
  String get gameSeasonPass => 'Season Pass';

  @override
  String get gameCreatorCode => 'Κωδικός Δημιουργού: ClashKing';

  @override
  String get gameCreatorCodeDescription =>
      'Tap for info • Support us for free!';

  @override
  String get gameCreatorCodeDialogTitle => 'Support ClashKing';

  @override
  String get gameCreatorCodeDialogDescription =>
      'When you use our creator code, you help fund development, keep the app and bot free for everyone, and support the addition of new features.\n\nWe receive 5% of your in-game purchases at no extra cost to you — just enter \"ClashKing\" in the shop of any Supercell game.\n\nThank you for your support!';

  @override
  String get gameCreatorCodeDialogButton => 'Use Creator Code';

  @override
  String get clanTitle => 'Clan';

  @override
  String get clanSearchTitle => 'Search clan';

  @override
  String get clanSearchPlaceholder => 'Clan\'s name';

  @override
  String get clanNone => 'No clan';

  @override
  String get clanJoinToUnlock => 'Join a clan to unlock new features.';

  @override
  String get clanMembers => 'Members';

  @override
  String get clanWarFrequency => 'War frequency';

  @override
  String get clanMinimumMembers => 'Minimum members';

  @override
  String get clanMaximumMembers => 'Maximum members';

  @override
  String get clanLocation => 'Location';

  @override
  String get clanMinimumPoints => 'Minimum clan points';

  @override
  String get clanMinimumLevel => 'Minimum clan level';

  @override
  String get clanInviteOnly => 'Invite Only';

  @override
  String get clanOpened => 'Opened';

  @override
  String get clanClosed => 'Έκλεισε';

  @override
  String get clanRoleLeader => 'Αρχηγός';

  @override
  String get clanRoleCoLeader => 'Υπ-Αρχηγός';

  @override
  String get clanRoleElder => 'Επίτιμο Μέλος';

  @override
  String get clanRoleMember => 'Μέλος';

  @override
  String get clanWarFrequencyAlways => 'Always';

  @override
  String get clanWarFrequencyNever => 'Never';

  @override
  String get clanWarFrequencyUnknown => 'Unknown';

  @override
  String get clanWarFrequencyOncePerWeek => '1/week';

  @override
  String get clanWarFrequencyMoreThanOncePerWeek => 'More than 1/week';

  @override
  String get clanWarFrequencyRarely => 'Rarely';

  @override
  String get timeHourIndicator => 'ω';

  @override
  String timeDaysAgo(int days) {
    return 'πριν από $days ημέρες';
  }

  @override
  String timeDayAgo(int day) {
    return 'πριν από $day ημέρα';
  }

  @override
  String timeHourAgo(int hour) {
    return 'πριν από $hour ώρα';
  }

  @override
  String timeHoursAgo(int hours) {
    return 'πριν από $hours ώρες';
  }

  @override
  String timeMinuteAgo(int minute) {
    return 'πριν από $minute λεπτό';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return 'πριν από $minutes λεπτά';
  }

  @override
  String get timeJustNow => 'Μόλις Τώρα';

  @override
  String get timeEndedJustNow => 'Ended just now';

  @override
  String timeEndedMinutesAgo(int minutes) {
    return 'Ended $minutes minutes ago';
  }

  @override
  String timeEndedHoursAgo(int hours) {
    return 'Ended $hours hours ago';
  }

  @override
  String timeEndedDaysAgo(int days) {
    return 'Ended $days days ago';
  }

  @override
  String timeStartsIn(String time) {
    return 'Starts in $time';
  }

  @override
  String timeStartsAt(String time) {
    return 'Starts at $time';
  }

  @override
  String timeEndsIn(String time) {
    return 'Ends in $time';
  }

  @override
  String timeEndsAt(String time) {
    return 'Ends at $time';
  }

  @override
  String get legendsTitle => 'Ανακριβή δεδομένα;';

  @override
  String get legendsNotInLeague => 'Εκτός επιπέδου Θρύλου';

  @override
  String get legendsNoDataToday =>
      'You\'re not in Legend League, but past seasons are available.';

  @override
  String legendsStartDescription(String trophies) {
    return 'Ξεκινήσατε τη μέρα με $trophies τρόπαια.';
  }

  @override
  String legendsNoRankLocalDescription(String country, int trophies) {
    return 'Δε βρίσκεστε στην κατάταξη κορυφαίων παιχτών της χώρας ($country) με $trophies τρόπαια.';
  }

  @override
  String legendsRankLocalDescription(int rank, String country, int trophies) {
    return 'Βρίσκεστε στη θέση $rank κορυφαίων παιχτών της χώρας ($country) με $trophies τρόπαια.';
  }

  @override
  String legendsGainDescription(int trophies) {
    return 'Κερδίσατε $trophies τρόπαια μέχρι τώρα.';
  }

  @override
  String legendsLossDescription(int trophies) {
    return 'Χάσατε $trophies τρόπαια μέχρι τώρα.';
  }

  @override
  String legendsNoGlobalRankDescription(int trophies) {
    return 'Δε βρίσκεστε στην κατάταξη κορυφαίων παιχτών του κόσμου με $trophies τρόπαια.';
  }

  @override
  String legendsGlobalRankDescription(int rank, int trophies) {
    return 'You are currently ranked $rank globally with $trophies trophies.';
  }

  @override
  String get legendsNoRank => 'Δεν υπάρχει κατάταξη';

  @override
  String get legendsBestTrophies => 'Υψηλότερα Τρόπαια';

  @override
  String get legendsMostAttacks => 'Περισσότερες Επιθέσεις';

  @override
  String get legendsLastSeason => 'Τελευταία Σεζόν';

  @override
  String get legendsBestRank => 'Υψηλότερη Παγκόσμια Θέση';

  @override
  String get legendsTrophiesBySeason => 'Trophies by season';

  @override
  String get legendsEosTrophies => 'End Of Season Trophies';

  @override
  String get legendsEosDetails => 'End Of Season Details';

  @override
  String get legendsInaccurateTitle => 'Ανακριβή δεδομένα;';

  @override
  String get legendsInaccurateIntro =>
      'Λόγω περιορισμών από τον προγραμματισμό του Clash of Clans τα δεδομένα μας ενδέχεται να μην είναι πάντα ακριβή. Αυτός είναι ο λόγος:\n';

  @override
  String get legendsInaccurateApiDelayTitle => '1. Καθυστερήσεις του «API»: ';

  @override
  String get legendsInaccurateApiDelayBody =>
      'Το «API» ενδέχεται να χρειαστεί μέχρι και 5 λεπτά να ενημερωθεί, δημιουργώντας καθυστέρηση στην αναγραφή των αλλαγών στα τρόπαια σε πραγματικό χρόνο.\n';

  @override
  String get legendsInaccurateConcurrentTitle => '2. Συνεχείς Αλλαγές:\n';

  @override
  String get legendsInaccurateMultipleAttacksTitle =>
      '- Πολλαπλές Επιθέσεις/Άμυνες: ';

  @override
  String get legendsInaccurateMultipleAttacksBody =>
      'Εάν πολλαπλές επιθέσεις ή άμυνες λάβουν μέρος σε γρήγορη διαδοχή, το «API» ενδέχεται να δείξει το άθροισμα του αποτελέσματος (π.χ. +68 ή -68).\n';

  @override
  String get legendsInaccurateSimultaneousTitle =>
      '- Ταυτόχρονη Επίθεση και άμυνα: ';

  @override
  String get legendsInaccurateSimultaneousBody =>
      'Εάν μία επίθεση ή άμυνα λάβουν μέρος ταυτόχρονα, τότε θα δείτε το άθροισμα του αποτελέσματος (π.χ. +4).\n';

  @override
  String get legendsInaccurateNetGainTitle => '3. Συνολικό Κέρδος/Απώλεια: ';

  @override
  String get legendsInaccurateNetGainBody =>
      'Παρά τα προβλήματα χρονισμού, το συνολικό κέρδος ή απώλεια για τη μέρα είναι ακριβές. ';

  @override
  String get legendsInaccurateConclusion =>
      'Αυτοί οι περιορισμοί είναι κοινοί σε όλα τα εργαλεία που χρησιμοποιούν τον προγραμματισμό του Clash of Clans. Προσπαθούμε το καλύτερο που μπορούμε για να αντισταθμίσουμε αυτούς τους περιορισμούς και να παράσχουμε αποτελέσματα όσο το δυνατόν πιο κοντά στην πραγματικότητα. Σας ευχαριστούμε για την κατανόηση!';

  @override
  String get statsSeasonStats => 'Στατιστικά Σεζόν';

  @override
  String get statsByDay => 'Με τη μέρα';

  @override
  String get statsBySeason => 'Με τη σεζόν';

  @override
  String statsDayIndex(int index) {
    return 'Μέρα $index';
  }

  @override
  String statsIndexDays(int index) {
    return '$index Μέρες';
  }

  @override
  String statsSeasonDate(String date) {
    return '$date season';
  }

  @override
  String get statsAllTownHalls => 'All Town Halls';

  @override
  String get statsMembers => 'Members Stats';

  @override
  String get todoTitle => 'Λίστα εργασιών';

  @override
  String get todoExplanationTitle => 'Υπολογισμός εργασιών';

  @override
  String get todoExplanationIntro =>
      'Το ποσοστό ολοκλήρωσης των εργασιών υπολογίζεται βασισμένο στις ακόλουθες ενέργειες με συγκεκριμένο βάρος:';

  @override
  String get todoExplanationLegendsTitle => 'Επίπεδο Θρύλου:';

  @override
  String get todoExplanationLegends =>
      'Βάρος έως και 8 πόντους για κάθε λογαριασμό, 1 επίθεση = 1 πόντος.';

  @override
  String get todoExplanationRaidsTitle => 'Επιδρομές:';

  @override
  String get todoExplanationRaids =>
      'Βάρος έως και 5 πόντους για κάθε λογαριασμό (ή έως και 6 εάν η τελευταία επίθεση έχει ξεκλειδωθεί), 1 επίθεση = 1 πόντος.';

  @override
  String get todoExplanationClanWarsTitle => 'Πόλεμος Φυλής:';

  @override
  String get todoExplanationClanWars =>
      'Βάρος έως και 2 πόντους για κάθε λογαριασμό, 1 επίθεση = 1 πόντος.';

  @override
  String get todoExplanationCwlTitle => 'Πρωτάθλημα Πολέμου Φυλής:';

  @override
  String get todoExplanationCwl =>
      'Βάρος έως και 1 πόντο για κάθε λογαριασμό, 1 επίθεση = 1 πόντος. Το «CWL» δεν μπορεί να καταγραφεί εάν ο παίχτης δεν βρίσκεται μέσα στην ομάδα του πρωταθλήματος.';

  @override
  String get todoExplanationPassAndGamesTitle =>
      'Πάσο σεζόν & Παιχνίδια Φυλής:';

  @override
  String get todoExplanationPassAndGames =>
      'Βάρος έως και 2 πόντους για κάθε λογαριασμό. Η αναλογία βασίζεται στον αριθμό ημερών που απομένουν (1 μήνα για το πάσο σεζόν και 6 ημέρες για τα παιχνίδια). Πράσινο = σε τροχιά να ολοκληρωθεί το πάσο ή τα παιχνίδια, κόκκινο = πίσω από το πρόγραμμα.';

  @override
  String get todoExplanationConclusion =>
      'Το τελικό ποσοστό υπολογίζεται διαιρώντας το σύνολο των ολοκληρωμένων ενεργειών στο χρόνο διάρκειας των «events» με το σύνολο των απαιτούμενων ενεργειών. Ανενεργού λογαριασμοί για περισσότερο από 14 ημέρες εξαιρούνται από τον υπολογισμό.';

  @override
  String todoAccountsNumber(int number) {
    return '$number λογαριασμοί';
  }

  @override
  String todoAccountsNumberActive(int number) {
    return '$number ενεργοί λογαριασμοί';
  }

  @override
  String todoAccountsNumberInactive(int number) {
    return '$number ανενεργοί λογαριασμοί';
  }

  @override
  String get todoAccountsActive => 'Ενεργοί λογαριασμοί';

  @override
  String get todoAccountsInactive => 'Ανενεργοί λογαριασμοί';

  @override
  String get todoAccountsNoInactive => 'Κανένας ανενεργός λογαριασμός.';

  @override
  String get todoAccountsNoActive => 'Κανένας ενεργός λογαριασμός.';

  @override
  String todoAttacksLeftDescription(int attacks, String type) {
    return 'You have $attacks attack(s) left ($type).';
  }

  @override
  String todoDefensesLeftDescription(int defenses, String type) {
    return 'You have $defenses defense(s) left ($type).';
  }

  @override
  String todoNoAttacksLeftDescription(String type) {
    return 'Congratulations, you have done all your attacks ($type)!';
  }

  @override
  String todoPointsLeftDescription(int points, String type) {
    return 'You have $points points left to get today to be in time for the end of the event ($type).';
  }

  @override
  String todoPointsLeftDescriptionNoPoints(String type) {
    return 'Congratulations, you are on time to get the maximum rewards at the end of the event ($type)!';
  }

  @override
  String get warTitle => 'War';

  @override
  String get warFrequency => 'War frequency';

  @override
  String get warParticipation => 'War Participation';

  @override
  String get warLeague => 'War/League';

  @override
  String get warHistory => 'War History';

  @override
  String get warLog => 'War Log';

  @override
  String warLogClosed(String clan) {
    return '$clan\'s war log is closed.';
  }

  @override
  String get warStats => 'War Stats';

  @override
  String get warOngoing => 'Ongoing war';

  @override
  String warIsNotInWar(String clan) {
    return '$clan is not in war.';
  }

  @override
  String get warAskForWar =>
      'Contact the leader or a co-leader to start a war.';

  @override
  String get warAskForWarLogOpening =>
      'Contact a leader or a co-leader to open the war log.';

  @override
  String get warEnded => 'War ended';

  @override
  String get warPreparation => 'Preparation';

  @override
  String get warPerfectWar => 'Perfect war';

  @override
  String get warVictory => 'Victory';

  @override
  String get warDefeat => 'Defeat';

  @override
  String get warDraw => 'Draw';

  @override
  String get warTeamSize => 'Team size';

  @override
  String get warMyTeam => 'My team';

  @override
  String get warEnemiesTeam => 'Enemies';

  @override
  String get warClanDraw => 'The two clans are tied';

  @override
  String get warStateOfTheWar => 'State of the war';

  @override
  String warStarsNeededToTakeTheLead(
      String clan, int star, int stars2, String percent) {
    return '$clan still need $star more star(s) or $stars2 star(s) and $percent% to take the lead.';
  }

  @override
  String warStarsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan still need $percent% or 1 more star to take the lead';
  }

  @override
  String get warNoDataAvailableForThisWar => 'No data available for this war';

  @override
  String get warCalculatorFast => 'Fast calculator';

  @override
  String warCalculatorAnswer(String percentNeeded, String result) {
    return 'To achieve a destruction rate of $percentNeeded%, a total of $result% is needed.';
  }

  @override
  String get warCalculatorNeededOverall => '% Needed overall';

  @override
  String get warCalculatorCalculate => 'Calculate';

  @override
  String get warAttacksTitle => 'Attacks';

  @override
  String get warAttacksNone => 'No attack yet';

  @override
  String get warAttacksBest => 'Best attacks';

  @override
  String get warAttacksCount => 'Attack Count';

  @override
  String get warAttacksMissed => 'Missed Attacks';

  @override
  String warAttacksNumber(int number_time, int number_war) {
    return 'You attacked $number_time time(s) during the last $number_war wars.';
  }

  @override
  String warAttacksAverageStars(String stars) {
    return 'You had an average of $stars stars per war.';
  }

  @override
  String warAttacksAverageDestruction(String percent) {
    return 'You had an average of $percent% destruction rate per war.';
  }

  @override
  String get warDefensesTitle => 'Defenses';

  @override
  String get warDefensesNone => 'No defense yet';

  @override
  String get warDefensesBest => 'Best defenses';

  @override
  String warDefensesBestOutOf(int number) {
    return 'Best defense (out of $number)';
  }

  @override
  String warDefensesNumber(int number_time, int number_war) {
    return 'You defended $number_time time(s) during the last $number_war wars.';
  }

  @override
  String warDefensesAverageStars(double stars) {
    return 'You had an average of $stars stars per defense.';
  }

  @override
  String warDefensesAverageDestruction(String percent) {
    return 'You had an average of $percent% destruction rate per defense.';
  }

  @override
  String get warStarsTitle => 'Stars';

  @override
  String get warStarsAverage => 'Average stars';

  @override
  String get warStarsNumber => 'Number of stars';

  @override
  String get warStarsOne => '1 star';

  @override
  String get warStarsTwo => '2 stars';

  @override
  String get warStarsThree => '3 stars';

  @override
  String get warStarsZero => '0 Star';

  @override
  String get warStarsBestPerformance => 'Best performance';

  @override
  String get warDestructionTitle => 'Destruction';

  @override
  String get warDestructionAverage => 'Average destruction';

  @override
  String get warDestructionRate => 'Destruction rate';

  @override
  String warHistoryWinsDescription(int wins, String percent) {
    return 'Your clan won $wins wars ($percent%) out of the last 50 wars.';
  }

  @override
  String warHistoryLossesDescription(int losses, String percent) {
    return 'Your clan lost $losses wars ($percent%) out of the last 50 wars.';
  }

  @override
  String warHistoryDrawsDescription(int draws, String percent) {
    return 'Your clan had $draws draws ($percent%) out of the last 50 wars.';
  }

  @override
  String warHistoryAverageMembersDescription(int members) {
    return 'Your clan has an average of $members members participating out of the last 50 wars.';
  }

  @override
  String warHistoryAverageWarStarsDescription(double stars, String percent) {
    return 'Your clan had an average of $stars stars per war from the last 50 wars. It represents $percent of the total stars.';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return 'Your clan had an average of $percent% destruction rate from the last 50 wars.';
  }

  @override
  String get warPositionMap => 'Map Position';

  @override
  String get warPositionAbbr => 'Pos';

  @override
  String get warPositionOrder => 'Order';

  @override
  String get warOpponentTownhall => 'Opp TH';

  @override
  String get warOpponentLowerTownhall => 'Lower TH';

  @override
  String get warOpponentUpperTownhall => 'Upper TH';

  @override
  String get warOpponentEqualThLevel => 'Equal TH';

  @override
  String get warOpponentSelectMembersThLevel => 'Members TH Level';

  @override
  String get warOpponentSelectOpponentsThLevel => 'Opponents TH Level';

  @override
  String warFiltersLastXwars(int number) {
    return 'Last $number wars';
  }

  @override
  String get warFiltersFriendly => 'Friendly';

  @override
  String get warFiltersRandom => 'Random';

  @override
  String get warVisibilityToggleTownHall =>
      'Hide/Show stats from former TH levels';

  @override
  String get warEventsTitle => 'Events';

  @override
  String get warEventsNewest => 'Newest';

  @override
  String get warEventsOldest => 'Oldest';

  @override
  String get warStatusReady => 'Opted In';

  @override
  String get warStatusUnready => 'Opted Out';

  @override
  String get warStatusMissed => 'Missed';

  @override
  String get warAbbreviationAvg => 'Avg';

  @override
  String get warAbbreviationAvgPercentage => 'Avg %';

  @override
  String get cwlTitle => 'CWL';

  @override
  String get cwlClanWarLeague => 'Clan War League';

  @override
  String get cwlOngoing => 'Ongoing CWL';

  @override
  String get cwlRounds => 'Rounds';

  @override
  String cwlRoundNumber(int number) {
    return 'Round $number';
  }

  @override
  String cwlCurrentRound(int round) {
    return 'Current round (Round $round)';
  }

  @override
  String cwlRank(int rank) {
    return 'Your clan is currently ranked $rank.';
  }

  @override
  String cwlStars(int stars) {
    return 'Your clan has a total of $stars stars.';
  }

  @override
  String cwlDestructionPercentage(String percent) {
    return 'Your clan has a total destruction rate of $percent%.';
  }

  @override
  String cwlTotalAttacks(int attacks, int totalAttacks) {
    return 'Your clan has a total of $attacks attacks out of $totalAttacks possible attacks.';
  }

  @override
  String get joinLeaveTitle => 'Join/Leave Logs (Current Season)';

  @override
  String get joinLeaveJoin => 'Join';

  @override
  String get joinLeaveLeave => 'Leave';

  @override
  String get joinLeaveReset => 'Reset';

  @override
  String get joinLeaveJoins => 'Joins';

  @override
  String get joinLeaveLeaves => 'Leaves';

  @override
  String get joinLeaveUniquePlayers => 'Unique Players';

  @override
  String get joinLeaveMovingPlayers => 'Moving Players';

  @override
  String get joinLeaveMostMovingPlayers => 'Most Moving Players';

  @override
  String get joinLeaveStillInClan => 'Still in Clan';

  @override
  String get joinLeaveLeftForever => 'Left Forever';

  @override
  String get joinLeaveRejoinedPlayers => 'Rejoined Players';

  @override
  String get joinLeaveAvgTimeJoinLeave => 'Avg Join/Leave Time';

  @override
  String get joinLeavePeakHour => 'Most Active Hour';

  @override
  String joinLeaveNumberDescription(int number, String date) {
    return '$number leave events occurred during the current season ($date).';
  }

  @override
  String joinLeaveJoinNumberDescription(int number, String date) {
    return '$number join events occurred during the current season ($date).';
  }

  @override
  String joinLeaveMovingNumberDescription(int number, String date) {
    return '$number player(s) left and rejoined the clan during the current season ($date).';
  }

  @override
  String joinLeaveUniqueNumberDescription(int number, String date) {
    return '$number unique player(s) joined/left the clan during the current season ($date).';
  }

  @override
  String joinLeaveStillInClanNumberDescription(int number) {
    return '$number player(s) joined and are still in the clan.';
  }

  @override
  String joinLeaveLeftClanNumberDescription(int number) {
    return '$number player(s) joined, then left the clan and never rejoined.';
  }

  @override
  String joinLeaveLeftOnAt(String date, String time) {
    return 'Left on $date at $time.';
  }

  @override
  String joinLeaveJoinedOnAt(String date, String time) {
    return 'Joined on $date at $time.';
  }

  @override
  String get raidsTitle => 'Raids';

  @override
  String get raidsLast => 'Last raids';

  @override
  String get raidsOngoing => 'Ongoing raids';

  @override
  String get raidsDistrictsDestroyed => 'Districts destroyed';

  @override
  String get raidsCompleted => 'Raids completed';

  @override
  String get searchNoResult => 'No result.';

  @override
  String get maintenanceTitle => 'Maintenance';

  @override
  String get maintenanceDescription =>
      'Clash of Clans is currently under maintenance, so we can\'t access the API. Please check back later.';

  @override
  String get downloadTooltip => 'Download CWL summary';

  @override
  String get downloadInProgress =>
      'Downloading file... It can take a few seconds...';

  @override
  String downloadSuccess(String path) {
    return 'File saved successfully in $path';
  }

  @override
  String get downloadError => 'Failed to download file';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get navigationTeam => 'Teams';

  @override
  String get navigationStatistics => 'Statistics';

  @override
  String get versionDevice => 'Εκδοχή & Συσκευή';

  @override
  String get settingsLicenses => 'Open Source Licenses';

  @override
  String get settingsLicensesSubtitle =>
      'View licenses for third-party libraries';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsPrivacyPolicySubtitle => 'How we handle your data';

  @override
  String get betaFeature => 'Χαρακτηριστικό εκδοχής Βήτα';

  @override
  String get betaLabel => 'BETA';

  @override
  String get betaDescription =>
      'Αυτό το χαρακτηριστικό βρίσκεται ακόμη στην εκδοχή βήτα, οπότε μπορεί να αντιμετωπίσετε μερικά σφάλματα ή να μην είναι ολοκληρωμένο. Δουλεύουμε ενεργά για τη βελτίωση της εφαρμογής και σας προσκαλούμε, να μοιραστείτε τις ιδέες σας και να αναφέρετε οποιαδήποτε σφάλματα αντιμετωπίζετε, στην ομάδα μας στο Discord.';

  @override
  String get settingsLanguage => 'Γλώσσα';

  @override
  String get settingsSelectLanguage => 'Επιλέξτε μία γλώσσα';

  @override
  String get settingsToggleTheme => 'Αλλαγή Εμφάνισης';

  @override
  String get faqTitle => 'FAQ';

  @override
  String get faqSubtitle => 'Συχνές Ερωτήσεις';

  @override
  String get faqIsThisFromSupercell => 'Η εφαρμογή ανήκει στη Supercell;';

  @override
  String get faqFanContentPolicy =>
      'Η εφαρμογή είναι ανεπίσημη και δεν υποστηρίζεται από τη Supercell. Για περισσότερες πληροφορίες δείτε την Πολιτική Δημιουργίας για Θαυμαστές της Supercell: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate =>
      'Γιατί τα δεδομένα είναι μερικές φορές ανακριβή ή ελλιπή;';

  @override
  String get faqClanNotTracked => 'Η ομάδα δεν καταγράφεται';

  @override
  String get faqClanNotTrackedAnswer =>
      'Το ClashKing μπορεί να καταγράφει αυτές τις πληροφορίες μόνο όταν η ομάδα είναι ήδη καταγεγραμμένη. Εάν η ομάδα δεν είναι καταγεγραμμένη, παρακαλώ προσθέστε το εργαλείο ClashKing στη σελίδα του Discord σας και χρησιμοποιείστε την εντολή /addclan. Δουλεύουμε για να φέρουμε αυτό το χαρακτηριστικό στην εφαρμογή σύντομα.';

  @override
  String get faqTrackingDown => 'Σταμάτησε η καταγραφή';

  @override
  String get faqTrackingDownAnswer =>
      'Η καταγραφή μπορεί να σταματήσει για ένα συγκεκριμένο χρονικό διάστημα. Για αυτόν τον λόγο μπορεί μερικές φορές να μην είναι ολοκληρωμένα τα δεδομένα σας. Δουλεύουμε για να το βελτιώσουμε.';

  @override
  String get faqApiLimitation => 'Όρια του Clash Of Clans API';

  @override
  String get faqApiLimitationAnswer =>
      'Μερικά δεδομένα που παρέχει το Clash of Clans και το «API» τους έχουνε μερικούς περιορισμούς. Αυτή είναι η περίπτωση για το επίπεδο θρύλου και την καταγραφή του, όπου μερικές φορές αθροίζει το κέρδος τρόπαιων με την απώλεια σαν να ήταν μία επίθεση. Αυτός είναι επίσης ο λόγος για τον οποίο δε διαθέτουμε πληροφορίες στα επίπεδα των κτηρίων σας.';

  @override
  String get faqSupportWork => 'Πώς μπορώ να υποστηρίξω το έργο σας;';

  @override
  String get faqSupportWorkAnswer =>
      'Υπάρχουν αρκετοί τρόποι για να μας υποστηρίξετε:';

  @override
  String get faqUseCodeClashKing =>
      'Χρησιμοποιήστε τον κωδικό δημιουργού \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Υποστηρίξτε μας στο Patreon';

  @override
  String get faqShareTheApp => 'Μοιραστείτε την εφαρμογή με τους φίλους σας';

  @override
  String get faqRateTheApp => 'Αξιολογείστε την εφαρμογή';

  @override
  String get faqHelpUsTranslate => 'Βοηθήστε μας να μεταφράσουμε την εφαρμογή';

  @override
  String get faqHowToInviteTheBot =>
      'Πώς μπορώ να προσθέσω το εργαλείο ClashKing στην ομάδα μου στο Discord;';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'Μπορείτε να προσθέσετε το εργαλείο Clashking στην ομάδα σας πατώντας το παρακάτω κουμπί. Θα χρειαστεί να επιτρέψετε την άδεια \"Διαχείριση Ομάδας\" για να προσθέσετε το εργαλείο.';

  @override
  String get faqInviteTheBot => 'Προσθέστε το εργαλείο Clashking';

  @override
  String get faqNeedHelp =>
      'Χρειάζομαι βοήθεια ή θα ήθελα να κάνω μία πρόταση. Πώς μπορώ να επικοινωνήσω μαζί σας;';

  @override
  String get faqNeedHelpAnswer =>
      'You can join our Discord Server to ask for help or to provide feedback, or you can email us at devs@clashk.ing. Please only write in English or French.';

  @override
  String get faqSendEmail => 'Στείλτε μας ένα email';

  @override
  String get faqJoinDiscord => 'Εισέλθετε στην ομάδα μας στο Discord';

  @override
  String get faqCannotOpenMailClient =>
      'Για κάποιους λόγους δεν μπορέσαμε να ανοίξουμε το mail σας. Έχουμε αντιγράψει τη διεύθυνση ηλεκτρονικού ταχυδρομείου για εσάς. Μπορείτε να γράψετε ένα email και να αποκολλήσετε τη διεύθυνση στο πεδίο του παραλήπτη.';

  @override
  String get translationHelpUsTranslate => 'Βοηθήστε μας να μεταφράσουμε';

  @override
  String get translationSuggestFeatures => 'Προτείνετε χαρακτηριστικά';

  @override
  String get translationThankYou => 'Σας ευχαριστούμε!';

  @override
  String get translationThankYouContent =>
      'Ένα τεράστιο ευχαριστώ σε όλους τους εξαιρετικούς μεταφραστές μας που μας βοηθάνε να κάνουμε την εφαρμογή προσβάσιμη σε περισσότερους ανθρώπους σε όλο τον κόσμο!';

  @override
  String get translationHelpTranslateContent =>
      'Μπορείτε να μας βοηθήσετε να μεταφράσουμε την εφαρμογή στο Crowdin. Εάν η γλώσσα σας δεν είναι διαθέσιμη στο Crowdin, παρακαλώ ζητείστε το στην ομάδα μας στο Discord. Σας ευχαριστούμε πολύ για τη βοήθεια!';

  @override
  String get translationHelpTranslateButton =>
      'Βοηθήστε μας στη μετάφραση στο Crowdin';

  @override
  String get translationCurrentTranslators => 'Τωρινοί μεταφραστές';
}
