// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'ClashKing';

  @override
  String get appDescription =>
      'A végső Clash of Clans társád a statisztikák követéséhez, klánok kezeléséhez és teljesítmény elemzéséhez.';

  @override
  String get generalLoading => 'Betöltés...';

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
  String get generalRetry => 'Újrapróbálás';

  @override
  String get generalTryAgain => 'Próbáld újra';

  @override
  String get generalCancel => 'Mégse';

  @override
  String get generalOk => 'OK';

  @override
  String get generalApply => 'Alkalmaz';

  @override
  String get generalConfirm => 'Megerősítés';

  @override
  String get generalManage => 'Kezelés';

  @override
  String get generalSettings => 'Beállítások';

  @override
  String get generalCopiedToClipboard => 'Vágólapra másolva';

  @override
  String get generalComingSoon => 'Hamarosan!';

  @override
  String generalLastRefresh(String time) {
    return 'Last refresh: $time';
  }

  @override
  String generalRefreshFailed(String error) {
    return 'Refresh failed: $error';
  }

  @override
  String get generalAll => 'Összes';

  @override
  String get generalTotal => 'Összes';

  @override
  String get generalBest => 'Legjobb';

  @override
  String get generalWorst => 'Legrosszabb';

  @override
  String get generalAverage => 'Átlag';

  @override
  String get generalRemaining => 'Hátralévő idő';

  @override
  String get generalActive => 'Aktív';

  @override
  String get generalInactive => 'Inaktív';

  @override
  String get generalStarted => 'Elkezdődött';

  @override
  String get generalEnded => 'Befejezve';

  @override
  String get generalRole => 'Szerepkör';

  @override
  String get generalStats => 'Statisztikák';

  @override
  String get generalFullStats => 'Teljes statisztikák';

  @override
  String get generalDetails => 'Részletek';

  @override
  String get generalHistory => 'Előzmények';

  @override
  String get generalFilters => 'Szűrők';

  @override
  String get generalNotSet => 'Nincs beállítva';

  @override
  String get generalWarning => 'Figyelmeztetés';

  @override
  String get generalNoDataAvailable => 'Nincs rendelkezésre álló adat.';

  @override
  String get authSignUp => 'Regisztráció';

  @override
  String get authLogin => 'Bejelentkezés';

  @override
  String get authLogout => 'Kijelentkezés';

  @override
  String get authCreateAccount => 'Fiók létrehozása';

  @override
  String get authJoinClashKing => 'Csatlakozz a ClashKing-hez';

  @override
  String get authCreateClashKingAccount => 'ClashKing fiók létrehozása';

  @override
  String get authCreateAccountToGetStarted =>
      'Hozd létre a fiókodat az induláshoz';

  @override
  String get authAlreadyHaveAccount => 'Már van fiókod? Jelentkezz be';

  @override
  String get authConfirmLogout => 'Biztosan ki szeretnél jelentkezni?';

  @override
  String get authDiscordTitle => 'Discord';

  @override
  String get authDiscordSignIn => 'Bejelentkezés Discord-dal';

  @override
  String get authDiscordContinue => 'Folytatás Discord-dal';

  @override
  String get authDiscordDescription =>
      'Szinkronizáld az adataidat a ClashKing Bot-tal és oldja fel a ClashKing teljes potenciálját!';

  @override
  String get authEmailTitle => 'E-mail';

  @override
  String get authEmailDescription =>
      'Használj e-mailt, ha nem férsz hozzá a Discord-hoz, vagy inkább csak az alkalmazás funkcióit szeretnéd';

  @override
  String get authEmailRequired => 'Kérjük, add meg az e-mail címedet';

  @override
  String get authEmailInvalid => 'Kérjük, adj meg egy érvényes e-mail címet';

  @override
  String get authPasswordLabel => 'Jelszó';

  @override
  String get authPasswordConfirm => 'Jelszó megerősítése';

  @override
  String get authPasswordRequired => 'Kérjük, add meg a jelszavadat';

  @override
  String get authPasswordConfirmRequired =>
      'Kérjük, erősítsd meg a jelszavadat';

  @override
  String get authPasswordMismatch => 'A jelszavak nem egyeznek';

  @override
  String get authPasswordTooShort =>
      'A jelszónak legalább 8 karakterből kell állnia';

  @override
  String get authPasswordRequirements =>
      'A jelszónak tartalmaznia kell: nagybetűt, kisbetűt, számot és speciális karaktert';

  @override
  String get authPasswordForgot => 'Elfelejtett jelszó?';

  @override
  String get authUsernameLabel => 'Felhasználónév';

  @override
  String get authUsernameRequired => 'Kérjük, adja meg a felhasználónevet';

  @override
  String get authUsernameTooShort =>
      'A felhasználónévnek legalább 3 karakterből kell állnia';

  @override
  String get authErrorConnection =>
      'Hiba történt. Kérjük, ellenőrizd az internetkapcsolatodat és próbáld újra.';

  @override
  String get authErrorConnectionRelaunch =>
      'Hiba történt. Kérjük, ellenőrizd az internetkapcsolatodat és indítsd újra az alkalmazást.';

  @override
  String get authAccountManagement => 'Fiókkezelés';

  @override
  String get authAccountConnected => 'Csatlakoztatott fiókok';

  @override
  String get authAccountConnectedStatus => 'Csatlakoztatva';

  @override
  String get authAccountNotConnected => 'Nincs csatlakoztatva';

  @override
  String get authAccountEmailAndPassword => 'E-mail és jelszó';

  @override
  String get authAccountSecured =>
      'A fiókod több hitelesítési módszerrel van biztosítva';

  @override
  String get authAccountLinkEmail => 'E-mail fiók csatlakoztatása';

  @override
  String get authAccountAddEmailAuth =>
      'Adj hozzá e-mail és jelszó hitelesítést a fiókodhoz a további biztonság érdekében.';

  @override
  String get authAccountEmailLinkedSuccess =>
      'E-mail fiók sikeresen csatlakoztatva!';

  @override
  String get helpTitle => 'Segítségre van szükséged?';

  @override
  String get helpJoinDiscord => 'Csatlakozz a Discord-hoz';

  @override
  String get helpEmailUs => 'Írj nekünk e-mailt';

  @override
  String get accountsWelcome => 'Üdv!';

  @override
  String get accountsWelcomeMessage =>
      'Kérjük adj egy vagy több Clash Of Clans fiókot a profilodhoz. Később tudsz további fiókokat hozzáadni.';

  @override
  String get accountsManageTitle => 'Kezeld a fiókjaidat';

  @override
  String get accountsNoneFound => 'A profilhoz nem található csatolt fiók';

  @override
  String get accountsPlayerTag => 'Player Tag (#ABC123)';

  @override
  String get accountsEnterPlayerTag => 'Adjon meg egy játékos tag-et';

  @override
  String get accountsAdd => 'Fiók hozzáadása';

  @override
  String get accountsDelete => 'Fiók törlése';

  @override
  String get accountsApiToken => 'Account API Token';

  @override
  String get accountsEnterApiToken =>
      'Please enter the account API token to confirm it\'s yours. You can find it in Clash of Clans Settings > More Settings > API Token.';

  @override
  String get accountsFillAllFields => 'Please fill all fields.';

  @override
  String get accountsErrorTagNotExists => 'A megadott játékos tag nem létezik.';

  @override
  String accountsErrorAlreadyLinked(Object tag) {
    return 'A játékos tag-je már csatolva van valakihez.';
  }

  @override
  String get accountsErrorAlreadyLinkedToYou =>
      'The player tag is already linked to you.';

  @override
  String get accountsErrorWrongApiToken => 'The API token entered is incorrect';

  @override
  String get accountsErrorFailedToAdd =>
      'Failed to add the account. Please try again later.';

  @override
  String get accountsErrorFailedToDelete =>
      'A kapcsolat törlése nem sikerült. Kérjük, próbálja meg később újra.';

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
  String get errorLoadingVersion => 'Hiba verzió betöltése közben';

  @override
  String get errorCannotOpenLink => 'We can\'t open this link.';

  @override
  String get errorExitAppToOpenClash =>
      'You are about to leave the app to open Clash of Clans.';

  @override
  String get playerSearchTitle => 'Játékos keresése';

  @override
  String get playerSearchPlaceholder => 'Player\'s name or tag';

  @override
  String playerLastActive(String date) {
    return 'Last active: $date';
  }

  @override
  String get playerNotTracked =>
      'This player is not tracked. Data may be inaccurate.';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Your clan is \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(
      String ratio, String donations, String received) {
    return 'Your donation ratio is $ratio. You have donated $donations troops and received $received troops.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Your war preference is \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'You have $stars war stars.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'You have $trophies trophies. You\'re currently in $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Your Town Hall level is $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Your Builder Hall level is $level and you have $trophies trophies.';
  }

  @override
  String get gameBaseHome => 'Fő bázis';

  @override
  String get gameBaseBuilder => 'Építő Bázis';

  @override
  String get gameClanCapital => 'Klán Főváros';

  @override
  String get gameTownHall => 'TH';

  @override
  String get gameTownHallLevel => 'TH szint';

  @override
  String gameTownHallLevelNumber(int level) {
    return 'Town Hall $level';
  }

  @override
  String gameTHLevel(int level) {
    return 'TH$level';
  }

  @override
  String get gameExpLevel => 'Tapasztalati szint';

  @override
  String get gameTrophies => 'Kupák';

  @override
  String get gameBuilderBaseTrophies => 'BB kupák';

  @override
  String get gameDonations => 'Adományok';

  @override
  String get gameDonationsReceived => 'Adományok Fogadva';

  @override
  String get gameDonationsRatio => 'Adományok aránya';

  @override
  String gameLevel(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get gameHeroes => 'Hősök';

  @override
  String get gameEquipment => 'Felszerelések';

  @override
  String get gameHeroesEquipments => 'Hero equipments';

  @override
  String get gameTroops => 'Csapatok';

  @override
  String get gameActiveSuperTroops => 'Active Super Troops';

  @override
  String get gamePets => 'Háziállatok';

  @override
  String get gameSiegeMachines => 'Ostromgépek';

  @override
  String get gameSpells => 'Varázs szerek';

  @override
  String get gameAchievements => 'Mérföldkövek';

  @override
  String get gameClanGames => 'Clan Games';

  @override
  String get gameSeasonPass => 'Season Pass';

  @override
  String get gameCreatorCode => 'Alkotói kód: ClashKing';

  @override
  String get gameCreatorCodeDescription =>
      'Tap for info • Support us for free!';

  @override
  String get gameCreatorCodeDialogTitle => 'Support ClashKing';

  @override
  String get gameCreatorCodeDialogDescription =>
      'Using our creator code helps fund development, keeps the app & bot free for all, and allows us to add new features.\n\nWe get 5% of what you spend in-game, but it doesn\'t cost you anything extra - just use \"ClashKing\" as your creator code in the Clash of Clans shop!';

  @override
  String get gameCreatorCodeDialogButton => 'Use Creator Code';

  @override
  String get clanTitle => 'Klán';

  @override
  String get clanSearchTitle => 'Klán keresése';

  @override
  String get clanSearchPlaceholder => 'Clan\'s name';

  @override
  String get clanNone => 'Nincs klán';

  @override
  String get clanJoinToUnlock =>
      'Csatlakozz egy klánhoz az új funkciók feloldásához.';

  @override
  String get clanMembers => 'Tagok';

  @override
  String get clanWarFrequency => 'Háború gyakorisága';

  @override
  String get clanMinimumMembers => 'Minimum tagok';

  @override
  String get clanMaximumMembers => 'Maximum tagok';

  @override
  String get clanLocation => 'Tartózkodási hely';

  @override
  String get clanMinimumPoints => 'Minimális klán pontok';

  @override
  String get clanMinimumLevel => 'Minimális klán szint';

  @override
  String get clanInviteOnly => 'Csak meghívással';

  @override
  String get clanOpened => 'Megnyitva';

  @override
  String get clanClosed => 'Bezárva';

  @override
  String get clanRoleLeader => 'Vezető';

  @override
  String get clanRoleCoLeader => 'Társvezető';

  @override
  String get clanRoleElder => 'Segítő';

  @override
  String get clanRoleMember => 'Tag';

  @override
  String get clanWarFrequencyAlways => 'Mindig';

  @override
  String get clanWarFrequencyNever => 'Soha';

  @override
  String get clanWarFrequencyUnknown => 'Ismeretlen';

  @override
  String get clanWarFrequencyOncePerWeek => '1/hét';

  @override
  String get clanWarFrequencyMoreThanOncePerWeek => 'More than 1/week';

  @override
  String get clanWarFrequencyRarely => 'Ritkán';

  @override
  String get timeHourIndicator => 'ó';

  @override
  String timeDaysAgo(int days) {
    return '$days napja';
  }

  @override
  String timeDayAgo(int day) {
    return '$day napja';
  }

  @override
  String timeHourAgo(int hour) {
    return '$hour órája';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours órája';
  }

  @override
  String timeMinuteAgo(int minute) {
    return '$minute perce';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes perce';
  }

  @override
  String get timeJustNow => 'Épp most';

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
  String get legendsTitle => 'Inaccurate data?';

  @override
  String get legendsNotInLeague => 'Not in Legend League';

  @override
  String get legendsNoDataToday =>
      'You\'re not in Legend League, but past seasons are available.';

  @override
  String legendsStartDescription(String trophies) {
    return 'You started the day with $trophies trophies.';
  }

  @override
  String legendsNoRankLocalDescription(String country, int trophies) {
    return 'You are currently not ranked ($country) with $trophies trophies.';
  }

  @override
  String legendsRankLocalDescription(int rank, String country, int trophies) {
    return 'You are currently ranked $rank ($country) with $trophies trophies.';
  }

  @override
  String legendsGainDescription(int trophies) {
    return 'You gained $trophies trophies for now.';
  }

  @override
  String legendsLossDescription(int trophies) {
    return 'You lost $trophies trophies for now.';
  }

  @override
  String legendsNoGlobalRankDescription(int trophies) {
    return 'You are currently not ranked globally with $trophies trophies.';
  }

  @override
  String legendsGlobalRankDescription(int rank, int trophies) {
    return 'You are currently ranked $rank globally with $trophies trophies.';
  }

  @override
  String get legendsNoRank => 'Nincs rangsorolás';

  @override
  String get legendsBestTrophies => 'Best Trophies';

  @override
  String get legendsMostAttacks => 'Most Attacks';

  @override
  String get legendsLastSeason => 'Last Season';

  @override
  String get legendsBestRank => 'Best Global Rank';

  @override
  String get legendsTrophiesBySeason => 'Trophies by season';

  @override
  String get legendsEosTrophies => 'Szezonvégi kupák';

  @override
  String get legendsEosDetails => 'End Of Season Details';

  @override
  String get legendsInaccurateTitle => 'Inaccurate data?';

  @override
  String get legendsInaccurateIntro =>
      'Due to limitations of the Clash of Clans API, our data might not always be perfectly accurate. Here\'s why:\n';

  @override
  String get legendsInaccurateApiDelayTitle => '1. API Delay: ';

  @override
  String get legendsInaccurateApiDelayBody =>
      'The API can take up to 5 minutes to update, causing a lag in reflecting real-time trophy changes.\n';

  @override
  String get legendsInaccurateConcurrentTitle => '2. Concurrent Changes: \n';

  @override
  String get legendsInaccurateMultipleAttacksTitle =>
      '- Multiple Attacks/Defenses: ';

  @override
  String get legendsInaccurateMultipleAttacksBody =>
      'If multiple attacks or defenses happen in quick succession, the API might show combined results (e.g., +68 or -68).\n';

  @override
  String get legendsInaccurateSimultaneousTitle =>
      '- Simultaneous Attack and Defense: ';

  @override
  String get legendsInaccurateSimultaneousBody =>
      'If an attack and defense occur at the same time, you might see a mixed result (e.g., +4).\n';

  @override
  String get legendsInaccurateNetGainTitle => '3. Net Gain/Loss: ';

  @override
  String get legendsInaccurateNetGainBody =>
      'Despite timing issues, the overall net gain or loss for the day is accurate. ';

  @override
  String get legendsInaccurateConclusion =>
      'These limitations are common across all tools using the Clash of Clans API. We sadly can\'t fix that as it is in Supercell\'s hands. We do our best to compensate for these limits and provide results as close to reality as possible. Thank you for understanding!';

  @override
  String get statsSeasonStats => 'Season Stats';

  @override
  String get statsByDay => 'Naponta';

  @override
  String get statsBySeason => 'By Season';

  @override
  String statsDayIndex(int index) {
    return 'Day $index';
  }

  @override
  String statsIndexDays(int index) {
    return '$index days';
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
  String get todoTitle => 'To-do list';

  @override
  String get todoExplanationTitle => 'Task Calculation';

  @override
  String get todoExplanationIntro =>
      'The task completion percentage is calculated based on the following activities with specific weightings:';

  @override
  String get todoExplanationLegendsTitle => 'Legend League:';

  @override
  String get todoExplanationLegends =>
      'Weight of 8 points per account, 1 attack = 1 point.';

  @override
  String get todoExplanationRaidsTitle => 'Raids:';

  @override
  String get todoExplanationRaids =>
      'Weight of 5 points per account (or 6 if the last attack has been unlocked), 1 attack = 1 point.';

  @override
  String get todoExplanationClanWarsTitle => 'Clan Wars:';

  @override
  String get todoExplanationClanWars =>
      'Weight of 2 points per account, 1 attack = 1 point.';

  @override
  String get todoExplanationCwlTitle => 'Clan War League:';

  @override
  String get todoExplanationCwl =>
      'Weight of 1 point per account, 1 attack = 1 point. CWL cannot be tracked if the player is not in their league clan.';

  @override
  String get todoExplanationPassAndGamesTitle => 'Season Pass & Clan Games:';

  @override
  String get todoExplanationPassAndGames =>
      'Weight of 2 points each per account. The ratio is based on the number of days remaining (1 month for the pass and 6 days for the games). Green = on track to complete the pass or games, red = behind schedule.';

  @override
  String get todoExplanationConclusion =>
      'The final percentage is calculated by dividing the total actions completed during ongoing events by the total required actions. Accounts inactive for more than 14 days are excluded from the calculation.';

  @override
  String todoAccountsNumber(int number) {
    return '$number accounts';
  }

  @override
  String todoAccountsNumberActive(int number) {
    return '$number active accounts';
  }

  @override
  String todoAccountsNumberInactive(int number) {
    return '$number inactive accounts';
  }

  @override
  String get todoAccountsActive => 'Active accounts';

  @override
  String get todoAccountsInactive => 'Inactive accounts';

  @override
  String get todoAccountsNoInactive => 'No inactive accounts.';

  @override
  String get todoAccountsNoActive => 'No active accounts.';

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
  String get warTitle => 'Háború';

  @override
  String get warFrequency => 'Háború gyakorisága';

  @override
  String get warParticipation => 'War Participation';

  @override
  String get warLeague => 'Háború/Rang';

  @override
  String get warHistory => 'Háború lista';

  @override
  String get warLog => 'Háború napló';

  @override
  String warLogClosed(String clan) {
    return 'Háborúnapló lezárva.';
  }

  @override
  String get warStats => 'Háború Statisztika';

  @override
  String get warOngoing => 'Ongoing war';

  @override
  String warIsNotInWar(String clan) {
    return 'A(z) $clan nincs háborúban.';
  }

  @override
  String get warAskForWar =>
      'Lépj kapcsolatba egy vezetővel vagy egy társvezetővel, hogy háborút indíts.';

  @override
  String get warAskForWarLogOpening =>
      'Lépj kapcsolatba egy vezetővel vagy egy társvezetővel, hogy megnyisd a háború naplót.';

  @override
  String get warEnded => 'Háború véget ért';

  @override
  String get warPreparation => 'Felkészülés';

  @override
  String get warPerfectWar => 'Tökéletes háború';

  @override
  String get warVictory => 'Győzelem';

  @override
  String get warDefeat => 'Vereség';

  @override
  String get warDraw => 'Döntetlen';

  @override
  String get warTeamSize => 'Csapat mérete';

  @override
  String get warMyTeam => 'Csapatom';

  @override
  String get warEnemiesTeam => 'Ellenségek';

  @override
  String get warClanDraw => 'A klánok fej-fej mellett vannak';

  @override
  String get warStateOfTheWar => 'Háború állapota';

  @override
  String warStarsNeededToTakeTheLead(
      String clan, int star, int stars2, String percent) {
    return '$clan még $star csillagot vagy $stars2 csillagot és $percent%-ot kell szereznie az élre kerüléshez.';
  }

  @override
  String warStarsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan még $percent%-ot vagy még 1 csillagot kell szereznie az élre kerüléshez';
  }

  @override
  String get warNoDataAvailableForThisWar =>
      'Nem áll rendelkezésre adat ehhez a háborúhoz';

  @override
  String get warCalculatorFast => 'Gyors számológép';

  @override
  String warCalculatorAnswer(String percentNeeded, String result) {
    return 'To achieve a destruction rate of $percentNeeded%, a total of $result% is needed.';
  }

  @override
  String get warCalculatorNeededOverall => '% Szükséges összesen';

  @override
  String get warCalculatorCalculate => 'Számítás';

  @override
  String get warAttacksTitle => 'Támadások';

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
  String get warDefensesTitle => 'Védekezések';

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
  String get warStarsTitle => 'Csillagok';

  @override
  String get warStarsAverage => 'Average stars';

  @override
  String get warStarsNumber => 'Csillagok száma';

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
  String get warDestructionRate => 'Elpusztítási arány';

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
  String get warEventsTitle => 'Események';

  @override
  String get warEventsNewest => 'Legújabb';

  @override
  String get warEventsOldest => 'Legidősebb';

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
  String get cwlRounds => 'Körök';

  @override
  String cwlRoundNumber(int number) {
    return 'Round $number';
  }

  @override
  String cwlCurrentRound(int round) {
    return 'It\'s currently round $round.';
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
  String get raidsCompleted => 'Sikeres portyázások';

  @override
  String get searchNoResult => 'Nincs találat.';

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
  String get dashboardTitle => 'Vezérlőpult';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get navigationTeam => 'Csapatok';

  @override
  String get navigationStatistics => 'Statisztikák';

  @override
  String get versionDevice => 'Verzió & Eszköz';

  @override
  String get settingsLicenses => 'Open Source Licenses';

  @override
  String get settingsLicensesSubtitle =>
      'View licenses for third-party libraries';

  @override
  String get betaFeature => 'Béta Funkció';

  @override
  String get betaLabel => 'BÉTA';

  @override
  String get betaDescription =>
      'Ez a funkció jelenleg báta fázisban van, lehetnek benne hibák vagy lehet nincs befejezve. Aktívan dolgozunk a javításokon és szívesen fogadunk megjegyzéseket. Kérjük oszd meg az ötleteided vagy jelentsd a hibákat a Discord szerverünkön hogy segíts minket.';

  @override
  String get settingsLanguage => 'Nyelv';

  @override
  String get settingsSelectLanguage => 'Nyelv kiválasztása';

  @override
  String get settingsToggleTheme => 'Téma váltása';

  @override
  String get faqTitle => 'GYIK';

  @override
  String get faqSubtitle => 'Gyakran Ismételt Kérdések';

  @override
  String get faqIsThisFromSupercell =>
      'Ez az alkalmazás a Supercelltől származik?';

  @override
  String get faqFanContentPolicy =>
      'Ez az anyag nem hivatalos, és nem kapott jóváhagyást Supercelltől. További információért lásd a Supercell rajongói tartalomra vonatkozó irányelveit: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate =>
      'Miért nem pontos néha az adat, vagy miért hiányos?';

  @override
  String get faqClanNotTracked => 'Klán nincs követve';

  @override
  String get faqClanNotTrackedAnswer =>
      'ClashKing csak úgy éri el az információt, ha a klán követve van. Ha a klán nincs követve, hívd meg a ClashKing bot-ot a Discord szerveredre es használd az /addclan parancsot. Reméljük hamarosan ez a funkció az alkalmazásban is jelen lesz.';

  @override
  String get faqTrackingDown => 'Lekövetés';

  @override
  String get faqTrackingDownAnswer =>
      'A követés néha megállhat, emiatt lehet hiányos az adat. Dolgozunk azon, hogy ez javítva legyen.';

  @override
  String get faqApiLimitation => 'Clash of Clans API korlát';

  @override
  String get faqApiLimitationAnswer =>
      'Az adat egy része a Clash of Clans API-tól van, és ennek vannak korlátjai. Például a Legends League követés, a támadással és védéssel járó kupák összekeverednek. És emiatt nincs információnk az épületek szintjéről.';

  @override
  String get faqSupportWork => 'Hogyan tudom támogatni a munkádat?';

  @override
  String get faqSupportWorkAnswer =>
      'Számos mód van arra, hogy támogass minket:';

  @override
  String get faqUseCodeClashKing => 'Használd a \"ClashKing\" alkotói kódot';

  @override
  String get faqSupportUsOnPatreon => 'Támogass minket a Patreon-on';

  @override
  String get faqShareTheApp => 'Oszd meg az alkalmazást a barátaiddal';

  @override
  String get faqRateTheApp => 'Értékelj minket az áruházban';

  @override
  String get faqHelpUsTranslate => 'Segíts lefordítani az appot';

  @override
  String get faqHowToInviteTheBot =>
      'Hogyan tudom a ClashKinget Discordon meghívni?';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'Meg tudod hívni a bot-ot a lent lévő gomb megnyomásával. Ehhez \"Manage Server\" joghoz van szükséged.';

  @override
  String get faqInviteTheBot => 'Hívd meg a ClashKing bot-ot';

  @override
  String get faqNeedHelp =>
      'Segítségre van szükségem, vagy szeretnék egy javaslatot tenni. Hogyan tudok kapcsolatba lépni?';

  @override
  String get faqNeedHelpAnswer =>
      'Csatlakozhatsz a Discord szerverünkhöz és kérhetsz segítset, vagy küldhetsz emailt a devs@clashk.ing címre.\nKérjük csak angolul vagy franciául írj.';

  @override
  String get faqSendEmail => 'Küldjön egy e-mailt';

  @override
  String get faqJoinDiscord => 'Csatlakozz a Discord szerverünkhöz';

  @override
  String get faqCannotOpenMailClient =>
      'Valamijen oknál fogva nem tudtuk a levelező kliensedet kinyitni. Vágólapra másoltuk a címet. Irhatsz egy emailt és bemásolhatod a címet.';

  @override
  String get translationHelpUsTranslate => 'Segíts a fordításban';

  @override
  String get translationSuggestFeatures => 'Funkció ajánlása';

  @override
  String get translationThankYou => 'Köszönjük!';

  @override
  String get translationThankYouContent =>
      'Hatalmas köszönet a rendkívüli fordítóknak, akik segítenek hogy az app minél több embernek világszerte elérhető legyen!';

  @override
  String get translationHelpTranslateContent =>
      'Segíthetsz a fordításban Crowdin-en. Ha a nyelved nem elérhető Crowdin-en, nyugodtan kérd a Discord szerverünkön. Nagyon köszönjük a segítségedet!';

  @override
  String get translationHelpTranslateButton => 'Segíts fordítani Crowdin-en';

  @override
  String get translationCurrentTranslators => 'Jelenlegi Fordítók';
}
