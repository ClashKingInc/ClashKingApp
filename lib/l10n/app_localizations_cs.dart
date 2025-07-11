// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'ClashKing';

  @override
  String get appDescription =>
      'Vaše konečné Clash klanů společník pro sledování statistik, správu klanů a analýzu výkonu.';

  @override
  String get generalLoading => 'Načítám...';

  @override
  String get loadingVillages => 'Načítání vesnic...';

  @override
  String get loadingClanData => 'Načítání dat o klanu...';

  @override
  String get loadingWarStats => 'Analyzuji válečné statistiky...';

  @override
  String get loadingLegendsData => 'Příprava legendových dat...';

  @override
  String get loadingCapitalRaids => 'Načítám údery kapitálu...';

  @override
  String get loadingAlmostReady => 'Téměř připraveno...';

  @override
  String get accountVerificationTitle => 'Ověřit účet';

  @override
  String get accountVerificationMessage =>
      'Zadejte svůj API token pro ověření vašeho účtu. Najdete ho v Clash of Clans Nastavení > Další nastavení > API Token.';

  @override
  String get accountVerified => 'Účet ověřen';

  @override
  String get accountNotVerified => 'Účet nebyl ověřen';

  @override
  String get accountVerifyButton => 'Ověřit';

  @override
  String get accountVerificationSuccess => 'Účet byl úspěšně ověřen!';

  @override
  String get accountVerificationFailed =>
      'Ověření se nezdařilo. Zkontrolujte prosím váš API token.';

  @override
  String get generalRetry => 'Opakovat';

  @override
  String get generalTryAgain => 'Zkuste to znovu';

  @override
  String get generalCancel => 'Zrušit';

  @override
  String get generalOk => 'OK';

  @override
  String get generalApply => 'Použít';

  @override
  String get generalConfirm => 'Potvrdit';

  @override
  String get generalManage => 'Spravovat';

  @override
  String get generalSettings => 'Nastavení';

  @override
  String get generalCopiedToClipboard => 'Zkopírováno do schránky';

  @override
  String get generalComingSoon => 'Již brzy!';

  @override
  String generalLastRefresh(String time) {
    return 'Poslední aktualizace: $time';
  }

  @override
  String generalRefreshFailed(String error) {
    return 'Obnovení selhalo: $error';
  }

  @override
  String get generalAll => 'Vše';

  @override
  String get generalTotal => 'Celkem';

  @override
  String get generalBest => 'Nejlepší';

  @override
  String get generalWorst => 'Nejhorší';

  @override
  String get generalAverage => 'Průměr';

  @override
  String get generalRemaining => 'Zbývající';

  @override
  String get generalActive => 'Aktivní';

  @override
  String get generalInactive => 'Neaktivní';

  @override
  String get generalStarted => 'Začínáno';

  @override
  String get generalEnded => 'Ukončeno';

  @override
  String get generalRole => 'Role';

  @override
  String get generalStats => 'Statistiky';

  @override
  String get generalFullStats => 'Úplné statistiky';

  @override
  String get generalDetails => 'Detaily';

  @override
  String get generalHistory => 'Historie';

  @override
  String get generalFilters => 'Filtry';

  @override
  String get generalNotSet => 'Nenastaveno';

  @override
  String get generalWarning => 'Varování';

  @override
  String get generalNoDataAvailable => 'Nejsou k dispozici žádná data.';

  @override
  String get authSignUp => 'Zaregistrovat se';

  @override
  String get authLogin => 'Přihlásit se';

  @override
  String get authLogout => 'Odhlásit se';

  @override
  String get authCreateAccount => 'Vytvořit účet';

  @override
  String get authJoinClashKing => 'Připojit se k ClashKing';

  @override
  String get authCreateClashKingAccount => 'Vytvořit ClashKing účet';

  @override
  String get authCreateAccountToGetStarted =>
      'Vytvořte si účet, abyste mohli začít';

  @override
  String get authAlreadyHaveAccount => 'Již máte účet? Přihlaste se';

  @override
  String get authConfirmLogout => 'Jste si jisti, že se chcete odhlásit?';

  @override
  String get authDiscordTitle => 'Discord';

  @override
  String get authDiscordSignIn => 'Přihlásit se pomocí Discordu';

  @override
  String get authDiscordContinue => 'Pokračovat s Discord';

  @override
  String get authDiscordDescription =>
      'Synchronizujte svá data s ClashKing Bot a odemkněte plný potenciál ClashKing!';

  @override
  String get authEmailTitle => 'E-mailová adresa';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'Enter your email address';

  @override
  String get authEmailDescription =>
      'Pokud nemáte přístup k Discordu nebo preferováte funkce pouze pro aplikace';

  @override
  String get authEmailRequired => 'Prosím, zadejte svůj e-mail';

  @override
  String get authEmailInvalid => 'Zadejte prosím platný e-mail';

  @override
  String get authPasswordLabel => 'Heslo';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authPasswordConfirm => 'Potvrzení hesla';

  @override
  String get authPasswordRequired => 'Zadejte prosím své heslo';

  @override
  String get authPasswordConfirmRequired => 'Potvrďte prosím své heslo';

  @override
  String get authPasswordMismatch => 'Hesla se neshodují';

  @override
  String get authPasswordTooShort => 'Heslo musí mít alespoň 8 znaků';

  @override
  String get authPasswordRequirements =>
      'Heslo musí obsahovat: velká písmena, malá písmena, číslice a speciální znak';

  @override
  String get authPasswordForgot => 'Zapomněli jste heslo?';

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
  String get authUsernameLabel => 'Uživatelské jméno';

  @override
  String get authUsernameRequired => 'Zadejte prosím uživatelské jméno';

  @override
  String get authUsernameTooShort =>
      'Uživatelské jméno musí mít alespoň 3 znaky';

  @override
  String get authErrorConnection =>
      'Došlo k chybě. Zkontrolujte připojení k internetu a zkuste to znovu.';

  @override
  String get authErrorConnectionRelaunch =>
      'Došlo k chybě. Zkontrolujte připojení k internetu a restartujte aplikaci.';

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
      'Přidejte, odeberte a upravte pořadí účtů Clash z Clans. Ověřte své účty pro přístup ke všem funkcím.';

  @override
  String get authAccountConnected => 'Připojené účty';

  @override
  String get authAccountConnectedStatus => 'Připojeno';

  @override
  String get authAccountNotConnected => 'Nepřipojeno';

  @override
  String get authAccountEmailAndPassword => 'E-mail & heslo';

  @override
  String get authAccountSecured =>
      'Váš účet je zabezpečen více metodami ověřování';

  @override
  String get authAccountLinkEmail => 'Propojit e-mailový účet';

  @override
  String get authAccountAddEmailAuth =>
      'Přidejte do svého účtu e-mail a heslo pro další zabezpečení.';

  @override
  String get authAccountEmailLinkedSuccess =>
      'E-mailový účet byl úspěšně propojen!';

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
  String get helpTitle => 'Potřebujete pomoc?';

  @override
  String get helpJoinDiscord => 'Připojit se k Discordu';

  @override
  String get helpEmailUs => 'Napište nám';

  @override
  String get accountsWelcome => 'Vítejte!';

  @override
  String get accountsWelcomeMessage =>
      'Přidejte do svého profilu jeden nebo více účtů Clash Clans. Účty můžete přidat nebo odebrat později.';

  @override
  String get accountsManageTitle => 'Spravovat své účty';

  @override
  String get accountsNoneFound => 'S Vaším profilem nebyl nalezen žádný účet';

  @override
  String get accountsPlayerTag => 'Tag hráče (#ABC123)';

  @override
  String get accountsEnterPlayerTag => 'Zadejte štítek hráče';

  @override
  String get accountsAdd => 'Přidat účet';

  @override
  String get accountsDelete => 'Odstranit účet';

  @override
  String get accountsApiToken => 'API token účtu';

  @override
  String get accountsEnterApiToken =>
      'Zadejte prosím API token účtu pro potvrzení vašeho účtu. Najdete ho v Clash of Clans Nastavení > Další nastavení > API Token.';

  @override
  String get accountsFillAllFields => 'Vyplňte prosím všechna pole.';

  @override
  String get accountsErrorTagNotExists => 'Zadaný štítek hráče neexistuje.';

  @override
  String accountsErrorAlreadyLinked(Object tag) {
    return 'Štítek hráče je již s někým propojen.';
  }

  @override
  String get accountsErrorAlreadyLinkedToYou =>
      'Štítek hráče je s vámi již propojen.';

  @override
  String get accountsErrorWrongApiToken => 'Zadaný API token je nesprávný';

  @override
  String get accountsErrorFailedToAdd =>
      'Přidání účtu se nezdařilo. Opakujte akci později.';

  @override
  String get accountsErrorFailedToDelete =>
      'Nepodařilo se odstranit odkaz. Opakujte akci později.';

  @override
  String get accountsErrorFailedToUpdateOrder =>
      'Nepodařilo se aktualizovat pořadí účtů.';

  @override
  String get errorTitle =>
      'Jejda! Naše servery možná vzaly ohnivou kouli na tvář! Vrháme uzdravující kouzel... Zkuste to znovu za chvíli.';

  @override
  String get errorSubtitle =>
      'Pokud problém přetrvává, podívejte se na náš Discord server, abyste zjistili, zda ho známe.';

  @override
  String get errorLoadingVersion => 'Chyba při načítání verze';

  @override
  String get errorCannotOpenLink => 'Tento odkaz nelze otevřít.';

  @override
  String get errorExitAppToOpenClash =>
      'Chystáte se opustit aplikaci a otevřít Clash z Clans.';

  @override
  String get playerSearchTitle => 'Hledat hráče';

  @override
  String get playerSearchPlaceholder => 'Jméno nebo značka hráče';

  @override
  String playerLastActive(String date) {
    return 'Poslední aktivní: $date';
  }

  @override
  String get playerNotTracked =>
      'Tento hráč není sledován. Data mohou být nepřesná.';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Váš klan je \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(
      String ratio, String donations, String received) {
    return 'Váš poměr příspěvků je $ratio. Darovali jste $donations a obdrželi jste jednotky $received.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Vaše preference války jsou \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'Máte $stars válečné hvězdy.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'Máš $trophies trofejí. Momentálně jsi v $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Tvá úroveň radnice je $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Tvá úroveň tvého stavitele je $level a máš $trophies trofejí.';
  }

  @override
  String get gameBaseHome => 'Domovská základna';

  @override
  String get gameBaseBuilder => 'Stavitelská základna';

  @override
  String get gameClanCapital => 'Kapitál klanu';

  @override
  String get gameTownHall => 'TH';

  @override
  String get gameTownHallLevel => 'TH úroveň';

  @override
  String gameTownHallLevelNumber(int level) {
    return 'Town Hall $level';
  }

  @override
  String gameTHLevel(int level) {
    return 'TH$level';
  }

  @override
  String get gameExpLevel => 'Úroveň zkušenosti';

  @override
  String get gameTrophies => 'Trofeje';

  @override
  String get gameBuilderBaseTrophies => 'BB trofeje';

  @override
  String get gameDonations => 'Příspěvky';

  @override
  String get gameDonationsReceived => 'Obdržené dary';

  @override
  String get gameDonationsRatio => 'Poměr příspěvku';

  @override
  String gameLevel(int level, int maxLevel) {
    return 'Úroveň: $level/$maxLevel';
  }

  @override
  String get gameHeroes => 'Hrdinové';

  @override
  String get gameEquipment => 'Vybavení';

  @override
  String get gameHeroesEquipments => 'Zařízení hrdinů';

  @override
  String get gameTroops => 'Vojenské jednotky';

  @override
  String get gameActiveSuperTroops => 'Aktivní Super jednotky';

  @override
  String get gamePets => 'Domácí zvířata';

  @override
  String get gameSiegeMachines => 'Obléhací stroje';

  @override
  String get gameSpells => 'Spells';

  @override
  String get gameAchievements => 'Úspěchy';

  @override
  String get gameClanGames => 'Klanové hry';

  @override
  String get gameSeasonPass => 'Sezónní průchod';

  @override
  String get gameCreatorCode => 'Kód tvůrce: ClashKing';

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
  String get clanTitle => 'klan';

  @override
  String get clanSearchTitle => 'Hledat klan';

  @override
  String get clanSearchPlaceholder => 'Jméno klanu';

  @override
  String get clanNone => 'Bez klanu';

  @override
  String get clanJoinToUnlock => 'Připojte se k klanu a odemkněte nové funkce.';

  @override
  String get clanMembers => 'Členové';

  @override
  String get clanWarFrequency => 'Válečná frekvence';

  @override
  String get clanMinimumMembers => 'Minimální počet členů';

  @override
  String get clanMaximumMembers => 'Maximální počet členů';

  @override
  String get clanLocation => 'Poloha';

  @override
  String get clanMinimumPoints => 'Minimální počet bodů klanu';

  @override
  String get clanMinimumLevel => 'Minimální úroveň klanu';

  @override
  String get clanInviteOnly => 'Pouze pozvání';

  @override
  String get clanOpened => 'Otevřeno';

  @override
  String get clanClosed => 'Uzavřeno';

  @override
  String get clanRoleLeader => 'Vůdce';

  @override
  String get clanRoleCoLeader => 'Spoluvůdce';

  @override
  String get clanRoleElder => 'Starší';

  @override
  String get clanRoleMember => 'Člen';

  @override
  String get clanWarFrequencyAlways => 'Vždy';

  @override
  String get clanWarFrequencyNever => 'Nikdy';

  @override
  String get clanWarFrequencyUnknown => 'Neznámý';

  @override
  String get clanWarFrequencyOncePerWeek => '1/týden';

  @override
  String get clanWarFrequencyMoreThanOncePerWeek => 'Více než 1/týden';

  @override
  String get clanWarFrequencyRarely => 'Zřídka';

  @override
  String get timeHourIndicator => 'h';

  @override
  String timeDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String timeDayAgo(int day) {
    return '$day day ago';
  }

  @override
  String timeHourAgo(int hour) {
    return '$hour hodinou';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours hodin';
  }

  @override
  String timeMinuteAgo(int minute) {
    return '$minute minutou';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes minut';
  }

  @override
  String get timeJustNow => 'Právě teď';

  @override
  String get timeEndedJustNow => 'Právě skončilo';

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
    return 'Začíná v $time';
  }

  @override
  String timeStartsAt(String time) {
    return 'Začíná v $time';
  }

  @override
  String timeEndsIn(String time) {
    return 'Končí v $time';
  }

  @override
  String timeEndsAt(String time) {
    return 'Končí v $time';
  }

  @override
  String get legendsTitle => 'Legendární liga';

  @override
  String get legendsNotInLeague => 'Není v legendové ligě';

  @override
  String get legendsNoDataToday =>
      'Nejste v Legend League, ale poslední sezóny jsou k dispozici.';

  @override
  String legendsStartDescription(String trophies) {
    return 'Začal jsi den s $trophies trofejemi.';
  }

  @override
  String legendsNoRankLocalDescription(String country, int trophies) {
    return 'Momentálně nemáš hodnocení ($country) s $trophies trofejemi.';
  }

  @override
  String legendsRankLocalDescription(int rank, String country, int trophies) {
    return 'Momentálně jste v pořadí $rank ($country) s $trophies trofejemi.';
  }

  @override
  String legendsGainDescription(int trophies) {
    return 'Zatím jsi získal $trophies trofejí.';
  }

  @override
  String legendsLossDescription(int trophies) {
    return 'Zatím jsi ztratil $trophies trofejí.';
  }

  @override
  String legendsNoGlobalRankDescription(int trophies) {
    return 'V současné době nemáš globální pořadí s $trophies trofejemi.';
  }

  @override
  String legendsGlobalRankDescription(int rank, int trophies) {
    return 'Momentálně jste $rank globálně s $trophies trofejemi.';
  }

  @override
  String get legendsNoRank => 'Žádné hodnocení';

  @override
  String get legendsBestTrophies => 'Nejlepší trofeje';

  @override
  String get legendsMostAttacks => 'Nejvíce útoků';

  @override
  String get legendsLastSeason => 'Poslední sezóna';

  @override
  String get legendsBestRank => 'Nejlepší globální hodnost';

  @override
  String get legendsTrophiesBySeason => 'Trofeje podle sezóny';

  @override
  String get legendsEosTrophies => 'Konec sezonních trofejí';

  @override
  String get legendsEosDetails => 'Detaily konce sezóny';

  @override
  String get legendsInaccurateTitle => 'Nepřesná data?';

  @override
  String get legendsInaccurateIntro =>
      'Vzhledem k omezením Clash of Clans API nemusí být naše data vždy zcela přesná. Zde je proč:\n';

  @override
  String get legendsInaccurateApiDelayTitle => '1. API zpoždění: ';

  @override
  String get legendsInaccurateApiDelayBody =>
      'Aktualizace API může trvat až 5 minut, což způsobí zaostávání odrážející změny trofeje v reálném čase.\n';

  @override
  String get legendsInaccurateConcurrentTitle => '2. Souběžné změny: \n';

  @override
  String get legendsInaccurateMultipleAttacksTitle => '- Více úderů/obran: ';

  @override
  String get legendsInaccurateMultipleAttacksBody =>
      'Pokud dojde k více útokům nebo obranám v rychlém sledování, může API zobrazit kombinované výsledky (např. +68 nebo -68).\n';

  @override
  String get legendsInaccurateSimultaneousTitle => '- Současný útok a obrana: ';

  @override
  String get legendsInaccurateSimultaneousBody =>
      'Pokud se současně objeví útok a obrana, můžete vidět smíšený výsledek (např. +4).\n';

  @override
  String get legendsInaccurateNetGainTitle => '3. Čistý zisk/ztráta: ';

  @override
  String get legendsInaccurateNetGainBody =>
      'Navzdory problémům s časováním je celkový čistý zisk nebo ztráta za den přesný. ';

  @override
  String get legendsInaccurateConclusion =>
      'Tato omezení jsou běžná pro všechny nástroje, které používají Clash z Clans API. Bohužel to nemůžeme opravit tak, jak je to v Superceleru rukou. Děláme vše, co je v našich silách, abychom tyto limity kompenzovali a poskytovali výsledky co nejblíže realitě. Děkujeme za pochopení!';

  @override
  String get statsSeasonStats => 'Statistiky sezony';

  @override
  String get statsByDay => 'Podle dne';

  @override
  String get statsBySeason => 'Podle sezony';

  @override
  String statsDayIndex(int index) {
    return 'Den $index';
  }

  @override
  String statsIndexDays(int index) {
    return '$index dnů';
  }

  @override
  String statsSeasonDate(String date) {
    return 'sezóna $date';
  }

  @override
  String get statsAllTownHalls => 'Všechny radnice';

  @override
  String get statsMembers => 'Statistiky členů';

  @override
  String get todoTitle => 'Seznam úkolů';

  @override
  String get todoExplanationTitle => 'Výpočet úlohy';

  @override
  String get todoExplanationIntro =>
      'Procentní podíl plnění úkolu se vypočítá na základě následujících činností s konkrétními váhami:';

  @override
  String get todoExplanationLegendsTitle => 'Legendární liga:';

  @override
  String get todoExplanationLegends =>
      'Hmotnost 8 bodů na účet, 1 útok = 1 bod.';

  @override
  String get todoExplanationRaidsTitle => 'Náklady:';

  @override
  String get todoExplanationRaids =>
      'Váha 5 bodů na účet (nebo 6, pokud byl odblokován poslední útok), 1 útok = 1 bod.';

  @override
  String get todoExplanationClanWarsTitle => 'Klanové války:';

  @override
  String get todoExplanationClanWars =>
      'Hmotnost 2 bodů na účet, 1 útok = 1 bod.';

  @override
  String get todoExplanationCwlTitle => 'Klan válečná liga:';

  @override
  String get todoExplanationCwl =>
      'Hmotnost 1 bodu na účet, 1 útok = 1 bod. CWL nemůže být sledována, pokud hráč není v liště.';

  @override
  String get todoExplanationPassAndGamesTitle => 'Hry na sezonu a klany:';

  @override
  String get todoExplanationPassAndGames =>
      'Hmotnost 2 body za každý účet. Poměr je založen na počtu zbývajících dnů (1 měsíc pro průchod a 6 dní pro hry). Zelená = na skladbě, aby dokončila průchod nebo hry, červená = za plánem.';

  @override
  String get todoExplanationConclusion =>
      'Konečný procentní podíl se vypočítá vydělením celkových akcí provedených v průběhu probíhajících akcí celkovým požadovaným akcím. Účty, které jsou neaktivní déle než 14 dní, jsou z výpočtu vyloučeny.';

  @override
  String todoAccountsNumber(int number) {
    return '$number účty';
  }

  @override
  String todoAccountsNumberActive(int number) {
    return '$number aktivní účty';
  }

  @override
  String todoAccountsNumberInactive(int number) {
    return '$number neaktivní účty';
  }

  @override
  String get todoAccountsActive => 'Aktivní účty';

  @override
  String get todoAccountsInactive => 'Neaktivní účty';

  @override
  String get todoAccountsNoInactive => 'Žádné neaktivní účty.';

  @override
  String get todoAccountsNoActive => 'Žádné aktivní účty.';

  @override
  String todoAttacksLeftDescription(int attacks, String type) {
    return 'Zbývá vám $attacks útoků ($type).';
  }

  @override
  String todoDefensesLeftDescription(int defenses, String type) {
    return 'Zbývá vám $defenses obrana ($type).';
  }

  @override
  String todoNoAttacksLeftDescription(String type) {
    return 'Gratulujeme, udělali jste všechny vaše útoky ($type)!';
  }

  @override
  String todoPointsLeftDescription(int points, String type) {
    return 'Zbývá vám $points bodů, abyste se dnes dostali do konce události ($type).';
  }

  @override
  String todoPointsLeftDescriptionNoPoints(String type) {
    return 'Gratulujeme, máte čas získat maximální odměny na konci události ($type)!';
  }

  @override
  String get warTitle => 'Válka';

  @override
  String get warFrequency => 'Válečná frekvence';

  @override
  String get warParticipation => 'Účast na válce';

  @override
  String get warLeague => 'Válka/Liga';

  @override
  String get warHistory => 'Válečná historie';

  @override
  String get warLog => 'Válečný deník';

  @override
  String warLogClosed(String clan) {
    return 'Protokol války ${clan}je uzavřen.';
  }

  @override
  String get warStats => 'Válečné statistiky';

  @override
  String get warOngoing => 'Probíhající válka';

  @override
  String warIsNotInWar(String clan) {
    return '$clan není ve válce.';
  }

  @override
  String get warAskForWar =>
      'Kontaktujte vedoucího nebo druhého vedoucího pro zahájení války.';

  @override
  String get warAskForWarLogOpening =>
      'Kontaktujte vedoucího nebo druhého vůdce pro otevření válečné lodi.';

  @override
  String get warEnded => 'Válka skončila';

  @override
  String get warPreparation => 'Příprava';

  @override
  String get warPerfectWar => 'Dokonalá válka';

  @override
  String get warVictory => 'Vítězství';

  @override
  String get warDefeat => 'Poraz';

  @override
  String get warDraw => 'Nakreslit';

  @override
  String get warTeamSize => 'Velikost týmu';

  @override
  String get warMyTeam => 'Můj tým';

  @override
  String get warEnemiesTeam => 'Enemies';

  @override
  String get warClanDraw => 'Oba klany jsou svázány';

  @override
  String get warStateOfTheWar => 'Stav války';

  @override
  String warStarsNeededToTakeTheLead(
      String clan, int star, int stars2, String percent) {
    return '$clan stále potřebuje $star další hvězdy nebo $stars2 hvězdy a $percent%, aby se ujal vedení.';
  }

  @override
  String warStarsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan stále potřebuje $percent% nebo 1 hvězdičku k převzetí vedení';
  }

  @override
  String get warNoDataAvailableForThisWar =>
      'Pro tuto válku nejsou k dispozici žádná data';

  @override
  String get warCalculatorFast => 'Rychlá kalkulačka';

  @override
  String warCalculatorAnswer(String percentNeeded, String result) {
    return 'K dosažení míry zničení $percentNeeded% je zapotřebí celkem $result%.';
  }

  @override
  String get warCalculatorNeededOverall => '% potřeba celkem';

  @override
  String get warCalculatorCalculate => 'Vypočítat';

  @override
  String get warAttacksTitle => 'Útoky';

  @override
  String get warAttacksNone => 'Zatím žádný útok';

  @override
  String get warAttacksBest => 'Nejlepší útoky';

  @override
  String get warAttacksCount => 'Počet útoků';

  @override
  String get warAttacksMissed => 'Zmeškané útoky';

  @override
  String warAttacksNumber(int number_time, int number_war) {
    return 'Během posledních válek $number_war jsi napadl $number_time krát.';
  }

  @override
  String warAttacksAverageStars(String stars) {
    return 'Za válku máš průměr $stars hvězd.';
  }

  @override
  String warAttacksAverageDestruction(String percent) {
    return 'Za válku došlo v průměru ke zničení $percent%.';
  }

  @override
  String get warDefensesTitle => 'Obrana';

  @override
  String get warDefensesNone => 'Zatím žádná obrana';

  @override
  String get warDefensesBest => 'Nejlepší obrana';

  @override
  String warDefensesBestOutOf(int number) {
    return 'Nejlepší obrana (mimo $number)';
  }

  @override
  String warDefensesNumber(int number_time, int number_war) {
    return 'Během posledních válek $number_war jste bránili $number_time krát.';
  }

  @override
  String warDefensesAverageStars(double stars) {
    return 'Měl jsi průměr $stars hvězd na obranu.';
  }

  @override
  String warDefensesAverageDestruction(String percent) {
    return 'Na obranu máte v průměru hodnotu $percent% destrukce.';
  }

  @override
  String get warStarsTitle => 'Hvězdy';

  @override
  String get warStarsAverage => 'Průměrné hvězdičky';

  @override
  String get warStarsNumber => 'Počet hvězd';

  @override
  String get warStarsOne => '1 hvězdička';

  @override
  String get warStarsTwo => '2 hvězdičky';

  @override
  String get warStarsThree => '3 hvězdičky';

  @override
  String get warStarsZero => '0 hvězdiček';

  @override
  String get warStarsBestPerformance => 'Nejlepší výkon';

  @override
  String get warDestructionTitle => 'Zničení';

  @override
  String get warDestructionAverage => 'Průměrné zničení';

  @override
  String get warDestructionRate => 'Míra zničení';

  @override
  String warHistoryWinsDescription(int wins, String percent) {
    return 'Váš klan vyhrál $wins války ($percent%) z posledních 50 válek.';
  }

  @override
  String warHistoryLossesDescription(int losses, String percent) {
    return 'Váš klan prohrál válku $losses ($percent%) z posledních 50 válek.';
  }

  @override
  String warHistoryDrawsDescription(int draws, String percent) {
    return 'Váš klan měl $draws kreslení ($percent%) z posledních 50 válek.';
  }

  @override
  String warHistoryAverageMembersDescription(int members) {
    return 'Váš klan má průměrnou hodnotu $members členů účastnících se posledních 50 válek.';
  }

  @override
  String warHistoryAverageWarStarsDescription(double stars, String percent) {
    return 'Tvůj klan měl průměr $stars hvězd za válku z posledních 50 válek. Představuje $percent celkových hvězd.';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return 'Tvůj klan měl z posledních 50 válek v průměru $percent% destrukci.';
  }

  @override
  String get warPositionMap => 'Pozice mapy';

  @override
  String get warPositionAbbr => 'Pozice';

  @override
  String get warPositionOrder => 'Objednávka';

  @override
  String get warOpponentTownhall => 'Přihlásit se k TH';

  @override
  String get warOpponentLowerTownhall => 'Dolní TH';

  @override
  String get warOpponentUpperTownhall => 'Horní TH';

  @override
  String get warOpponentEqualThLevel => 'Rovná se TH';

  @override
  String get warOpponentSelectMembersThLevel => 'Členové TH úroveň';

  @override
  String get warOpponentSelectOpponentsThLevel => 'Odpůrci TH úroveň';

  @override
  String warFiltersLastXwars(int number) {
    return 'Poslední $number války';
  }

  @override
  String get warFiltersFriendly => 'Přátelské';

  @override
  String get warFiltersRandom => 'Náhodný';

  @override
  String get warVisibilityToggleTownHall =>
      'Skrýt/zobrazit statistiky z dřívějších TH úrovní';

  @override
  String get warEventsTitle => 'Události';

  @override
  String get warEventsNewest => 'Nejnovější';

  @override
  String get warEventsOldest => 'Nejstarší';

  @override
  String get warStatusReady => 'Přihlášen';

  @override
  String get warStatusUnready => 'Vybráno';

  @override
  String get warStatusMissed => 'Zmeškané';

  @override
  String get warAbbreviationAvg => 'Prům.';

  @override
  String get warAbbreviationAvgPercentage => 'Prům. %';

  @override
  String get cwlTitle => 'CWL';

  @override
  String get cwlClanWarLeague => 'Válečná liga klanu';

  @override
  String get cwlOngoing => 'Probíhající CWL';

  @override
  String get cwlRounds => 'Kola';

  @override
  String cwlRoundNumber(int number) {
    return 'Kolo $number';
  }

  @override
  String cwlCurrentRound(int round) {
    return 'Aktuální kolo (Kolo $round)';
  }

  @override
  String cwlRank(int rank) {
    return 'Váš klan je v současné době v žebříčku $rank.';
  }

  @override
  String cwlStars(int stars) {
    return 'Váš klan má celkem $stars hvězd.';
  }

  @override
  String cwlDestructionPercentage(String percent) {
    return 'Tvůj klan má celkovou destrukci $percent%.';
  }

  @override
  String cwlTotalAttacks(int attacks, int totalAttacks) {
    return 'Váš klan má celkem útok $attacks z možných útoků $totalAttacks.';
  }

  @override
  String get joinLeaveTitle => 'Připojit/odejít logy (příchozí sezona)';

  @override
  String get joinLeaveJoin => 'Připojit se';

  @override
  String get joinLeaveLeave => 'Opustit';

  @override
  String get joinLeaveReset => 'Reset';

  @override
  String get joinLeaveJoins => 'Připojit se';

  @override
  String get joinLeaveLeaves => 'Listová zelenina a čerstvé bylinky';

  @override
  String get joinLeaveUniquePlayers => 'Unikátní hráči';

  @override
  String get joinLeaveMovingPlayers => 'Přesouvání hráčů';

  @override
  String get joinLeaveMostMovingPlayers => 'Nejvíce se pohybující hráči';

  @override
  String get joinLeaveStillInClan => 'Stále v klanu';

  @override
  String get joinLeaveLeftForever => 'Vždy vlevo';

  @override
  String get joinLeaveRejoinedPlayers => 'Odmítnutí hráči';

  @override
  String get joinLeaveAvgTimeJoinLeave => 'Prům. čas připojení/odchodu';

  @override
  String get joinLeavePeakHour => 'Nejaktivnější Hodina';

  @override
  String joinLeaveNumberDescription(int number, String date) {
    return 'Události $number se odehrály během aktuální sezóny ($date).';
  }

  @override
  String joinLeaveJoinNumberDescription(int number, String date) {
    return 'Během aktuální sezóny ($date ) se objevily události $number.';
  }

  @override
  String joinLeaveMovingNumberDescription(int number, String date) {
    return '$number hráči vlevo a znovu se připojili ke klanu během aktuální sezóny ($date).';
  }

  @override
  String joinLeaveUniqueNumberDescription(int number, String date) {
    return '$number unikátní hráč se připojil/opustil klan během aktuální sezóny ($date).';
  }

  @override
  String joinLeaveStillInClanNumberDescription(int number) {
    return '$number hráči se připojili a jsou stále v klanu.';
  }

  @override
  String joinLeaveLeftClanNumberDescription(int number) {
    return '$number hráči se připojili, poté opustili klan a nikdy se nepřipojili.';
  }

  @override
  String joinLeaveLeftOnAt(String date, String time) {
    return 'Vlevo na $date v $time.';
  }

  @override
  String joinLeaveJoinedOnAt(String date, String time) {
    return 'Přidal/a se na $date v $time.';
  }

  @override
  String get raidsTitle => 'Nájezdy';

  @override
  String get raidsLast => 'Poslední nájezdy';

  @override
  String get raidsOngoing => 'Probíhající srážky';

  @override
  String get raidsDistrictsDestroyed => 'Okresy zničeny';

  @override
  String get raidsCompleted => 'Plnění nájezdů';

  @override
  String get searchNoResult => 'Bez výsledku.';

  @override
  String get maintenanceTitle => 'Údržba';

  @override
  String get maintenanceDescription =>
      'Stlačení Clans je v současné době v údržbě, takže nemůžeme přistupovat k API. Zkuste to prosím později.';

  @override
  String get downloadTooltip => 'Stáhnout shrnutí CWL';

  @override
  String get downloadInProgress =>
      'Stahování souboru... Může to trvat několik sekund...';

  @override
  String downloadSuccess(String path) {
    return 'Soubor byl úspěšně uložen v $path';
  }

  @override
  String get downloadError => 'Nepodařilo se stáhnout soubor';

  @override
  String get dashboardTitle => 'Nástěnka';

  @override
  String get toolsTitle => 'Nástroje a nářadí';

  @override
  String get navigationTeam => 'Týmy';

  @override
  String get navigationStatistics => 'Statistiky';

  @override
  String get versionDevice => 'Verze & Zařízení';

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
  String get betaFeature => 'Beta funkce';

  @override
  String get betaLabel => 'BETA';

  @override
  String get betaDescription =>
      'Tato funkce je momentálně v beta verzi, může mít nějaké chyby nebo být neúplná. Aktivně pracujeme na vylepšení a vítáme vaši zpětnou vazbu. Prosím, sdílejte své nápady a nahlaste jakékoliv problémy na našem Discord serveru, abyste nám pomohli je zlepšit.';

  @override
  String get settingsLanguage => 'Jazyk';

  @override
  String get settingsSelectLanguage => 'Vyberte jazyk';

  @override
  String get settingsToggleTheme => 'Přepnout motiv';

  @override
  String get faqTitle => 'Nejčastější dotazy';

  @override
  String get faqSubtitle => 'Často kladené otázky';

  @override
  String get faqIsThisFromSupercell => 'Je tato aplikace z Supercellu?';

  @override
  String get faqFanContentPolicy =>
      'Tento materiál je neoficiální a není podporován aplikací Supercell. Další informace naleznete v Zásadách obsahu Supercell\'s Fan: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate => 'Proč jsou data někdy nepřesná nebo chybí?';

  @override
  String get faqClanNotTracked => 'Klan není sledován';

  @override
  String get faqClanNotTrackedAnswer =>
      'ClashKing může načíst tyto informace pouze v případě, že je klan sledován. Pokud tvůj klan není sledován, pozvej ClashKing Bot na tvůj Discord server a použij příkaz /addclan. Pracujeme na tom, aby byla tato funkce brzy k dispozici v aplikaci.';

  @override
  String get faqTrackingDown => 'Sledování dolů';

  @override
  String get faqTrackingDownAnswer =>
      'Sledování může přestat fungovat po určitou dobu. Proto někdy můžete mít díry ve svých údajích. Pracujeme na tom, abychom to zlepšili.';

  @override
  String get faqApiLimitation => 'Střet omezení Clans API';

  @override
  String get faqApiLimitationAnswer =>
      'Některá data poskytuje Clash of Clans a jejich API mají určitá omezení. To je případ legendy sledování, občas je to trofej zisk a ztráta, jako by to byl jediný útok. To je také důvod, proč nemáme žádné informace o vaší úrovni budov.';

  @override
  String get faqSupportWork => 'Jak mohu podpořit vaši práci?';

  @override
  String get faqSupportWorkAnswer =>
      'Existuje několik způsobů, jak nás podpořit:';

  @override
  String get faqUseCodeClashKing => 'Použít kód \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Podpořte nás na Patreonu';

  @override
  String get faqShareTheApp => 'Sdílejte aplikaci s přáteli';

  @override
  String get faqRateTheApp => 'Ohodnoťte aplikaci v obchodě';

  @override
  String get faqHelpUsTranslate => 'Pomozte nám přeložit aplikaci';

  @override
  String get faqHowToInviteTheBot =>
      'Jak mohu pozvat tvého bota na můj Discord server?';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'Můžete pozvat našeho bota na váš server kliknutím na tlačítko níže. Pro přidání bota budete potřebovat oprávnění \"Manage Server\".';

  @override
  String get faqInviteTheBot => 'Invite ClashKing Bot';

  @override
  String get faqNeedHelp =>
      'Potřebuji pomoc, nebo bych chtěl něco navrhnout. Jak vás mohu kontaktovat?';

  @override
  String get faqNeedHelpAnswer =>
      'You can join our Discord Server to ask for help or to provide feedback, or you can email us at devs@clashk.ing. Please only write in English or French.';

  @override
  String get faqSendEmail => 'Poslat e-mail';

  @override
  String get faqJoinDiscord => 'Připojte se k našemu Discord serveru';

  @override
  String get faqCannotOpenMailClient =>
      'Z některých důvodů nemůžeme otevřít Vašeho poštovního klienta. Zkopírovali jsme pro Vás e-mailovou adresu. Můžete napsat e-mail a vložit adresu do pole příjemce.';

  @override
  String get translationHelpUsTranslate => 'Pomozte nám s překladem';

  @override
  String get translationSuggestFeatures => 'Navrhnout funkce';

  @override
  String get translationThankYou => 'Děkujeme!';

  @override
  String get translationThankYouContent =>
      'Velice vám děkuji všem našim úžasným překladatelům, kteří nám pomáhají zpřístupnit tuto aplikaci více lidí po celém světě!';

  @override
  String get translationHelpTranslateContent =>
      'Můžete nám pomoci přeložit aplikaci na Crowdin. Pokud tvůj jazyk není k dispozici na Crowdinu, neváhej se o něj požádat na našem Discord serveru. Mnohokrát ti děkujeme za pomoc!';

  @override
  String get translationHelpTranslateButton => 'Pomozte přeložit na Crowdin';

  @override
  String get translationCurrentTranslators => 'Aktuální překladatelé';
}
