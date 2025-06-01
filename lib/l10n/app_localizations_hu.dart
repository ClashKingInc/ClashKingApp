// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get creatorCode => 'Creator Code: ClashKing';

  @override
  String get errorTitle =>
      'Oops! Our servers might have taken a fireball to the face! We\'re casting a healing spell... Try again in a moment.';

  @override
  String get errorSubtitle =>
      'If the issue persists, check our Discord Server to see if we\'re aware of it.';

  @override
  String get retry => 'Retry';

  @override
  String get signInWithDiscord => 'Bejelentkezés Discord-dal';

  @override
  String get guestMode => 'Vendég mód';

  @override
  String get needHelpJoinDiscord =>
      'Szükség van segítségre? Érj el minket Discordon.';

  @override
  String get loginError =>
      'An error occurred while logging in. Please try again later.';

  @override
  String doesNotExist(String tag) {
    return '$tag nem létezik.';
  }

  @override
  String isAlreadyLinked(String tag) {
    return '$tag már csatolva van.';
  }

  @override
  String get username => 'Felhasználónév';

  @override
  String get playerTag => 'Player Tag (#ABC123)';

  @override
  String get playerTags => 'Játékos tag';

  @override
  String get linkedAccounts => 'Linked Accounts';

  @override
  String followingTagsDoNotExist(String tags) {
    return 'Ezek a tag-ek nem léteznek: $tags.';
  }

  @override
  String followingTagsAreAlreadyLinked(String tags) {
    return 'Ezek a tag-ek már csatolva vannak: $tags.';
  }

  @override
  String get welcome => 'Üdv!';

  @override
  String get welcomeMessage =>
      'Please add one or more Clash of Clans accounts to your profile. You can add or remove accounts later.';

  @override
  String get login => 'Bejelentkezés';

  @override
  String get logout => 'Kijelentkezés';

  @override
  String get language => 'Nyelv';

  @override
  String get settings => 'Beállítások';

  @override
  String get toggleTheme => 'Téma váltása';

  @override
  String get selectLanguage => 'Nyelv kiválasztása';

  @override
  String get faq => 'GYIK';

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
  String get faqClanNotTracked => 'Clan not tracked';

  @override
  String get faqClanNotTrackedAnswer =>
      'ClashKing can only retrieve this info if the clan is tracked. If your clan isn\'t tracked, please invite the ClashKing Bot to your Discord Server and use the command /addclan. We are working on making this feature available in the app soon.';

  @override
  String get faqTrackingDown => 'Tracking down';

  @override
  String get faqTrackingDownAnswer =>
      'The tracking can stop working for a certain period of time. This is why you can sometimes have holes in your data. We are working on improving this.';

  @override
  String get faqApiLimitation => 'Clash of Clans API limitation';

  @override
  String get faqApiLimitationAnswer =>
      'Some data is provided by Clash of Clans and their API have some limitations. This is the case for legends tracking, it sometimes stacks the trophy gain and loss as if it was a single attack. This is also why we don\'t have any information on your building levels.';

  @override
  String get faqSupportWork => 'Hogyan tudom támogatni a munkádat?';

  @override
  String get faqSupportWorkAnswer => 'There are several ways to support us:';

  @override
  String get faqUseCodeClashKing => 'Használd a \"ClashKing\" alkotói kódot';

  @override
  String get faqSupportUsOnPatreon => 'Támogass minket a Patreon-on';

  @override
  String get faqShareTheApp => 'Oszd meg az alkalmazást a barátaiddal';

  @override
  String get faqRateTheApp => 'Rate the app in the store';

  @override
  String get faqHelpUsTranslate => 'Segíts lefordítani az appot';

  @override
  String get faqHowToInviteTheBot =>
      'How can I invite your bot to my Discord Server?';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'You can invite our bot to your server by clicking on the button below. You will need the \"Manage Server\" permission to add the bot.';

  @override
  String get faqInviteTheBot => 'Hívd meg a ClashKing bot-ot';

  @override
  String get faqNeedHelp =>
      'Segítségre van szükségem, vagy szeretnék egy javaslatot tenni. Hogyan tudok kapcsolatba lépni?';

  @override
  String get faqNeedHelpAnswer =>
      'You can join our Discord Server to ask for help or to provide feedback, or you can email us at devs@clashkingbot.com. Please only write in English or French.';

  @override
  String get faqSendEmail => 'Küldjön egy e-mailt';

  @override
  String get faqJoinDiscord => 'Csatlakozz a Discord szerverünkhöz';

  @override
  String get faqCannotOpenMailClient =>
      'For some reasons we can\'t open your mail client. We copied the email address for you. You can write an email and paste the address in the recipient field.';

  @override
  String get helpUsTranslate => 'Segíts a fordításban';

  @override
  String get suggestFeatures => 'Suggest features';

  @override
  String get thankYou => 'Thank you!';

  @override
  String get thankYouContent =>
      'A huge thank you to all our amazing translators who help us make this app accessible to more people around the world!';

  @override
  String get helpTranslateContent =>
      'You can help us translate the app on Crowdin. If your language is not available on Crowdin, feel free to request it in our Discord Server. Thank you so much for your help!';

  @override
  String get helpTranslateButton => 'Help Translate on Crowdin';

  @override
  String get versionDevice => 'Version & Device';

  @override
  String get loading => 'Loading...';

  @override
  String get errorLoadingVersion => 'Error loading version';

  @override
  String get currentTranslators => 'Current Translators';

  @override
  String get betaFeature => 'Beta Feature';

  @override
  String get beta => 'BETA';

  @override
  String get betaDescription =>
      'This feature is currently in beta, it may have some bugs or be incomplete. We are actively working on improvements and welcome your feedback. Please share your ideas and report any issues in our Discord Server to help us make it better.';

  @override
  String get copiedToClipboard => 'Vágólapra másolva';

  @override
  String get all => 'Összes';

  @override
  String get hourIndicator => 'ó';

  @override
  String get minIndicator => 'p';

  @override
  String get noDataAvailable => 'Nincs rendelkezésre álló adat.';

  @override
  String get close => 'Bezárás';

  @override
  String get closed => 'Bezárva';

  @override
  String get error => 'Hiba';

  @override
  String get player => 'Játékos';

  @override
  String notFoundOrNotLinkedToOurSystem(String player) {
    return '$player nem található vagy nincs kapcsolva a rendszerünkhöz.';
  }

  @override
  String get tryAnotherNameOrTagOrLinkIt =>
      'Próbáljon meg egy másik nevet/tag-et vagy linkelj.';

  @override
  String get playerNotFound => 'Játékos nem található';

  @override
  String get noValueEntered => 'Nincs érték megadva';

  @override
  String get manage => 'Kezelés';

  @override
  String get enterPlayerTag => 'Adjon meg egy játékos tag-et';

  @override
  String get add => 'Hozzáadás';

  @override
  String get delete => 'Törlés';

  @override
  String get addAccount => 'Fiók hozzáadása';

  @override
  String get deleteAccount => 'Fiók törlése';

  @override
  String get playerTagNotExists => 'A megadott játékos tag nem létezik.';

  @override
  String accountAlreadyLinked(Object tag) {
    return 'A játékos tag-je már csatolva van valakihez.';
  }

  @override
  String get enterApiToken =>
      'Please enter the account API token to confirm it\'s yours. You can find it in Clash of Clans Settings > More Settings > API Token.';

  @override
  String get wrongApiToken => 'The API token entered is incorrect';

  @override
  String get accountAlreadyLinkedToYou =>
      'The player tag is already linked to you.';

  @override
  String get apiToken => 'Account API Token';

  @override
  String get failedToAddTryAgain =>
      'Nem sikerült hozzákapcsolni. Kérjük, próbálja újra később.';

  @override
  String get fillAllFields => 'Please fill all fields.';

  @override
  String get failedToDeleteTryAgain =>
      'A kapcsolat törlése nem sikerült. Kérjük, próbálja meg később újra.';

  @override
  String get enterPlayerTagWarning =>
      'You must enter a player tag and click on the \"+\" to continue.';

  @override
  String get failedToLoadAccountData => 'Failed to load accounts data.';

  @override
  String get failedToUpdateOrder => 'Failed to update the order of accounts.';

  @override
  String get loadAccountData => 'Load accounts data';

  @override
  String get syncAccounts => 'Sync Accounts';

  @override
  String get confirm => 'Confirm';

  @override
  String get warning => 'Warning';

  @override
  String get exitAppToOpenClash =>
      'You are about to leave the app to open Clash of Clans.';

  @override
  String get confirmLogout => 'Are you sure you want to log out?';

  @override
  String get tagOrNamePlayer => 'Játékos tag-je vagy neve';

  @override
  String get searchPlayer => 'Játékos keresése';

  @override
  String get nameOrTagPlayer => 'Player\'s name or tag';

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
  String get dashboard => 'Vezérlőpult';

  @override
  String get homeBase => 'Fő bázis';

  @override
  String get th => 'TH';

  @override
  String get builderBase => 'Építő Bázis';

  @override
  String get bh => 'BH';

  @override
  String get clanCapital => 'Klán Főváros';

  @override
  String get leader => 'Vezető';

  @override
  String get coLeader => 'Társvezető';

  @override
  String get elder => 'Segítő';

  @override
  String get member => 'Tag';

  @override
  String get ready => 'Opted In';

  @override
  String get unready => 'Opted Out';

  @override
  String level(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get heroes => 'Hősök';

  @override
  String get equipment => 'Felszerelések';

  @override
  String get troops => 'Csapatok';

  @override
  String get superTroops => 'Szuper katonák';

  @override
  String get activeSuperTroops => 'Active Super Troops';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get pets => 'Háziállatok';

  @override
  String get siegeMachines => 'Ostromgépek';

  @override
  String get spells => 'Varázs szerek';

  @override
  String get achievements => 'Mérföldkövek';

  @override
  String get byDay => 'Naponta';

  @override
  String get bySeason => 'By Season';

  @override
  String dayIndex(int index) {
    return 'Day $index';
  }

  @override
  String indexDays(int index) {
    return '$index days';
  }

  @override
  String get bestTrophies => 'Best Trophies';

  @override
  String get mostAttacks => 'Most Attacks';

  @override
  String get lastSeason => 'Last Season';

  @override
  String get bestRank => 'Best Global Rank';

  @override
  String daysLeft(int days) {
    return '$days days left';
  }

  @override
  String get date => 'Date';

  @override
  String get stats => 'Stats';

  @override
  String get fullStats => 'Full Stats';

  @override
  String get details => 'Details';

  @override
  String get seasonStats => 'Season Stats';

  @override
  String get charts => 'Diagramok';

  @override
  String get history => 'Előzmények';

  @override
  String get legendLeague => 'Legenda liga';

  @override
  String get notInLegendLeague => 'Not in Legend League';

  @override
  String get noLegendsDataToday =>
      'You\'re not in Legend League, but past seasons are available.';

  @override
  String legendStartDescription(String trophies) {
    return 'You started the day with $trophies trophies.';
  }

  @override
  String legendNoRankLocalDescription(String country, int trophies) {
    return 'You are currently not ranked ($country) with $trophies trophies.';
  }

  @override
  String legendRankLocalDescription(
      Object country, Object rank, Object trophies) {
    return 'You are currently ranked $rank ($country) with $trophies trophies.';
  }

  @override
  String legendGainDescription(int trophies) {
    return 'You gained $trophies trophies for now.';
  }

  @override
  String legendLossDescription(int trophies) {
    return 'You lost $trophies trophies for now.';
  }

  @override
  String legendNoGlobalRankDescription(int trophies) {
    return 'You are currently not ranked globally with $trophies trophies.';
  }

  @override
  String legendGlobalRankDescription(int rank, Object trophies) {
    return 'You are currently ranked $rank globally.';
  }

  @override
  String get noRank => 'Nincs rangsorolás';

  @override
  String get started => 'Elkezdődött';

  @override
  String get ended => 'Befejezve';

  @override
  String get average => 'Átlag';

  @override
  String get remaining => 'Hátralévő idő';

  @override
  String get legendsTitle => 'Inaccurate data?';

  @override
  String get legendsExplanation_intro =>
      'Due to limitations of the Clash of Clans API, our data might not always be perfectly accurate. Here\'s why:\n';

  @override
  String get legendsExplanation_api_delay_title => '1. API Delay: ';

  @override
  String get legendsExplanation_api_delay_body =>
      'The API can take up to 5 minutes to update, causing a lag in reflecting real-time trophy changes.\n';

  @override
  String get legendsExplanation_concurrent_changes_title =>
      '2. Concurrent Changes: \n';

  @override
  String get legendsExplanation_multiple_attacks_defenses_title =>
      '- Multiple Attacks/Defenses: ';

  @override
  String get legendsExplanation_multiple_attacks_defenses_body =>
      'If multiple attacks or defenses happen in quick succession, the API might show combined results (e.g., +68 or -68).\n';

  @override
  String get legendsExplanation_simultaneous_attack_defense_title =>
      '- Simultaneous Attack and Defense: ';

  @override
  String get legendsExplanation_simultaneous_attack_defense_body =>
      'If an attack and defense occur at the same time, you might see a mixed result (e.g., +4).\n';

  @override
  String get legendsExplanation_net_gain_loss_title => '3. Net Gain/Loss: ';

  @override
  String get legendsExplanation_net_gain_loss_body =>
      'Despite timing issues, the overall net gain or loss for the day is accurate. ';

  @override
  String get legendsExplanation_conclusion =>
      'These limitations are common across all tools using the Clash of Clans API. We sadly can\'t fix that as it is in Supercell\'s hands. We do our best to compensate for these limits and provide results as close to reality as possible. Thank you for understanding!';

  @override
  String get toDoList => 'To-do list';

  @override
  String get clanGames => 'Clan Games';

  @override
  String get seasonPass => 'Season Pass';

  @override
  String lastActive(String date) {
    return 'Last active: $date';
  }

  @override
  String get playerNotTracked =>
      'This player is not tracked. Data may be inaccurate.';

  @override
  String numberAccounts(int number) {
    return '$number accounts';
  }

  @override
  String numberActiveAccounts(int number) {
    return '$number active accounts';
  }

  @override
  String numberInactiveAccounts(int number) {
    return '$number inactive accounts';
  }

  @override
  String get activeAccounts => 'Active accounts';

  @override
  String get inactiveAccounts => 'Inactive accounts';

  @override
  String get noInactiveAccounts => 'No inactive accounts.';

  @override
  String get noActiveAccounts => 'No active accounts.';

  @override
  String get todoExplanation_title => 'Task Calculation';

  @override
  String get todoExplanation_intro =>
      'The task completion percentage is calculated based on the following activities with specific weightings:';

  @override
  String get todoExplanation_legends_title => 'Legend League:';

  @override
  String get todoExplanation_legends =>
      'Weight of 8 points per account, 1 attack = 1 point.';

  @override
  String get todoExplanation_raids_title => 'Raids:';

  @override
  String get todoExplanation_raids =>
      'Weight of 5 points per account (or 6 if the last attack has been unlocked), 1 attack = 1 point.';

  @override
  String get todoExplanation_clanWars_title => 'Clan Wars:';

  @override
  String get todoExplanation_clanWars =>
      'Weight of 2 points per account, 1 attack = 1 point.';

  @override
  String get todoExplanation_cwl_title => 'Clan War League:';

  @override
  String get todoExplanation_cwl =>
      'Weight of 1 point per account, 1 attack = 1 point. CWL cannot be tracked if the player is not in their league clan.';

  @override
  String get todoExplanation_passAndGames_title => 'Season Pass & Clan Games:';

  @override
  String get todoExplanation_passAndGames =>
      'Weight of 2 points each per account. The ratio is based on the number of days remaining (1 month for the pass and 6 days for the games). Green = on track to complete the pass or games, red = behind schedule.';

  @override
  String get todoExplanation_conclusion =>
      'The final percentage is calculated by dividing the total actions completed during ongoing events by the total required actions. Accounts inactive for more than 14 days are excluded from the calculation.';

  @override
  String get worst => 'Legrosszabb';

  @override
  String get best => 'Legjobb';

  @override
  String get total => 'Összes';

  @override
  String get heroesEquipments => 'Hero equipments';

  @override
  String daysAgo(int days) {
    return '$days napja';
  }

  @override
  String dayAgo(int day) {
    return '$day napja';
  }

  @override
  String hourAgo(int hour) {
    return '$hour órája';
  }

  @override
  String hoursAgo(int hours, Object Hours) {
    return '$hours órája';
  }

  @override
  String minuteAgo(int minute) {
    return '$minute perce';
  }

  @override
  String minutesAgo(int minutes) {
    return '$minutes perce';
  }

  @override
  String secondAgo(int seconds) {
    return '$seconds másodperce';
  }

  @override
  String get justNow => 'Épp most';

  @override
  String get endedJustNow => 'Ended just now';

  @override
  String endedMinutesAgo(int minutes) {
    return 'Ended $minutes minutes ago';
  }

  @override
  String endedHoursAgo(int hours) {
    return 'Ended $hours hours ago';
  }

  @override
  String endedDaysAgo(int days) {
    return 'Ended $days days ago';
  }

  @override
  String get trophiesByMonth => 'Kupák hónap szerint';

  @override
  String get trophiesBySeason => 'Trophies by season';

  @override
  String get eosTrophies => 'Szezonvégi kupák';

  @override
  String get eosDetails => 'End Of Season Details';

  @override
  String get searchClan => 'Klán keresése';

  @override
  String get clanName => 'Clan\'s name';

  @override
  String get nameOrTagClan => 'Clan\'s name or tag';

  @override
  String get noResult => 'Nincs találat.';

  @override
  String get filters => 'Szűrők';

  @override
  String get whatever => 'Mindegy';

  @override
  String get any => 'Bármely';

  @override
  String get notSet => 'Not set';

  @override
  String get warFrequency => 'Háború gyakorisága';

  @override
  String get minimumMembers => 'Minimum tagok';

  @override
  String get maximumMembers => 'Maximum tagok';

  @override
  String get location => 'Tartózkodási hely';

  @override
  String get minimumClanPoints => 'Minimális klán pontok';

  @override
  String get minimumClanLevel => 'Minimális klán szint';

  @override
  String get noClan => 'Nincs klán';

  @override
  String get joinClanToUnlockNewFeatures =>
      'Csatlakozz egy klánhoz az új funkciók feloldásához.';

  @override
  String get apply => 'Jelentkezés';

  @override
  String get opened => 'Megnyitva';

  @override
  String get inviteOnly => 'Csak meghívással';

  @override
  String get cancel => 'Mégse';

  @override
  String get clan => 'Klán';

  @override
  String get clans => 'Klánok';

  @override
  String get members => 'Tagok';

  @override
  String get role => 'Szerepkör';

  @override
  String get expLevel => 'Tapasztalati szint';

  @override
  String get townHallLevel => 'TH szint';

  @override
  String thLevel(int level) {
    return 'TH$level';
  }

  @override
  String bhLevel(int level) {
    return 'BH$level';
  }

  @override
  String townHallLevelLevel(int level) {
    return 'Town Hall $level';
  }

  @override
  String get byNumberOfWars => 'By number of wars';

  @override
  String get ok => 'OK';

  @override
  String get byDateRange => 'By date range';

  @override
  String get selectSeason => 'Select a season';

  @override
  String get year => 'Year';

  @override
  String get month => 'Month';

  @override
  String get allTownHalls => 'All Town Halls';

  @override
  String seasonDate(String date) {
    return '$date season';
  }

  @override
  String lastXwars(int number) {
    return 'Last $number wars';
  }

  @override
  String get friendly => 'Friendly';

  @override
  String get cwl => 'CWL';

  @override
  String get random => 'Random';

  @override
  String get selectMembersThLevel => 'Members TH Level';

  @override
  String get selectOpponentsThLevel => 'Opponents TH Level';

  @override
  String get equalThLevel => 'Equal TH';

  @override
  String get builderBaseTrophies => 'BB kupák';

  @override
  String get donations => 'Adományok';

  @override
  String get donationsReceived => 'Adományok Fogadva';

  @override
  String get donationsRatio => 'Adományok aránya';

  @override
  String get trophies => 'Kupák';

  @override
  String get always => 'Mindig';

  @override
  String get never => 'Soha';

  @override
  String get unknown => 'Ismeretlen';

  @override
  String get oncePerWeek => '1/hét';

  @override
  String get twicePerWeek => '2/hét';

  @override
  String get rarely => 'Ritkán';

  @override
  String get warLeague => 'Háború/Rang';

  @override
  String get war => 'Háború';

  @override
  String get league => 'Rangok';

  @override
  String get wars => 'Háborúk';

  @override
  String get ongoingWar => 'Ongoing war';

  @override
  String get ongoingCwl => 'Ongoing CWL';

  @override
  String get cantOpenLink => 'We can\'t open this link.';

  @override
  String get notInWar => 'Not in war';

  @override
  String get warHistory => 'Háború lista';

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
  String warHistoryAverageClanStarsPerMember(Object stars) {
    return 'Your clan had an average of $stars stars per member from the last 50 wars.';
  }

  @override
  String warHistoryAverageMembers(int members) {
    return '~$members members per war';
  }

  @override
  String attacksLeftDescription(int attacks, String type) {
    return 'You have $attacks attack(s) left ($type).';
  }

  @override
  String defensesLeftDescription(int defenses, String type) {
    return 'You have $defenses defense(s) left ($type).';
  }

  @override
  String noAttacksLeftDescription(String type) {
    return 'Congratulations, you have done all your attacks ($type)!';
  }

  @override
  String noDefensesLeftDescription(Object type) {
    return 'You have taken all your defenses ($type)!';
  }

  @override
  String pointsLeftDescription(int points, String type) {
    return 'You have $points points left to get today to be in time for the end of the event ($type).';
  }

  @override
  String pointsLeftDescriptionNoPoints(String type) {
    return 'Congratulations, you are on time to get the maximum rewards at the end of the event ($type)!';
  }

  @override
  String get averageStars => 'Average stars';

  @override
  String get averageDestruction => 'Average destruction';

  @override
  String get oneStar => '1 star';

  @override
  String get twoStars => '2 stars';

  @override
  String get threeStars => '3 stars';

  @override
  String get highDestruction => 'High destruction';

  @override
  String get lowDestruction => 'Low destruction';

  @override
  String get avg => 'Avg';

  @override
  String get avgPercentage => 'Avg %';

  @override
  String get attackCount => 'Attack Count';

  @override
  String get missedAttacks => 'Missed Attacks';

  @override
  String get order => 'Order';

  @override
  String get defenseStars => 'Defense Stars';

  @override
  String get defenseDestruction => 'Defense Destruction';

  @override
  String get defenseAverageStars => 'Defense Avg Stars';

  @override
  String get defenseAverageDestruction => 'Defense Avg Destruction';

  @override
  String get zeroStar => '0 Star';

  @override
  String get warParticipation => 'War Participation';

  @override
  String get missed => 'Missed';

  @override
  String get totalStars => 'Total';

  @override
  String get destruction => 'Destruction';

  @override
  String get mapPosition => 'Map Position';

  @override
  String get pos => 'Pos';

  @override
  String get oppTownhall => 'Opp TH';

  @override
  String get lowerTownhall => 'Lower TH';

  @override
  String get upperTownhall => 'Upper TH';

  @override
  String get toggleTownHallVisibility =>
      'Hide/Show stats from former TH levels';

  @override
  String get warLog => 'Háború napló';

  @override
  String get publicWarLog => 'Public War Log';

  @override
  String get privateWarLog => 'Private War Log';

  @override
  String startsIn(String time) {
    return 'Starts in $time';
  }

  @override
  String startsAt(String time) {
    return 'Starts at $time';
  }

  @override
  String endsIn(String time) {
    return 'Ends in $time';
  }

  @override
  String endsAt(String time) {
    return 'Ends at $time';
  }

  @override
  String get joinLeaveLogs => 'Join/Leave Logs';

  @override
  String get join => 'Join';

  @override
  String get leave => 'Leave';

  @override
  String get reset => 'Reset';

  @override
  String get joins => 'Joins';

  @override
  String get leaves => 'Leaves';

  @override
  String get uniquePlayers => 'Unique Players';

  @override
  String get movingPlayers => 'Moving Players';

  @override
  String get mostMovingPlayers => 'Most Moving Players';

  @override
  String get stillInClan => 'Still in Clan';

  @override
  String get leftForever => 'Left Forever';

  @override
  String get rejoinedPlayers => 'Rejoined Players';

  @override
  String get avgTimeJoinLeave => 'Avg Join/Leave Time';

  @override
  String get peakHour => 'Most Active Hour';

  @override
  String leaveNumberDescription(int number, String date) {
    return '$number player(s) left the clan during the current season ($date).';
  }

  @override
  String joinNumberDescription(int number, String date) {
    return '$number player(s) joined the clan during the current season ($date).';
  }

  @override
  String movingNumberDescription(int number, String date) {
    return '$number player(s) left and rejoined the clan during the current season ($date).';
  }

  @override
  String uniqueNumberDescription(int number, String date) {
    return '$number unique player(s) joined/left the clan during the current season ($date).';
  }

  @override
  String mostMovingHourDescription(int hour) {
    return '${hour}h is usually the hour with the most join/leave activity.';
  }

  @override
  String stillInClanNumberDescription(int number) {
    return '$number player(s) joined and are still in the clan.';
  }

  @override
  String leftClanNumberDescription(int number) {
    return '$number player(s) joined, then left the clan and never rejoined.';
  }

  @override
  String joinLeaveDifferenceDownDescription(int number, String date) {
    return 'Your clan has lost $number member(s) this season ($date).';
  }

  @override
  String joinLeaveDifferenceEqualDescription(String date) {
    return 'Your clan has the same number of members as at the beginning of the season ($date).';
  }

  @override
  String leftOnAt(String date, String time) {
    return 'Left on $date at $time.';
  }

  @override
  String joinedOnAt(String date, String time) {
    return 'Joined on $date at $time.';
  }

  @override
  String get statistics => 'Statisztikák';

  @override
  String get stars => 'Csillagok';

  @override
  String get numberOfStars => 'Csillagok száma';

  @override
  String get destructionRate => 'Elpusztítási arány';

  @override
  String get events => 'Események';

  @override
  String get team => 'Csapatok';

  @override
  String get myTeam => 'Csapatom';

  @override
  String get enemiesTeam => 'Ellenségek';

  @override
  String get defense => 'Védelem';

  @override
  String get defenses => 'Védekezések';

  @override
  String get bestDefenses => 'Best defenses';

  @override
  String bestDefenseOutOf(int number) {
    return 'Best defense (out of $number)';
  }

  @override
  String get attack => 'Támadás';

  @override
  String get attacks => 'Támadások';

  @override
  String get bestAttacks => 'Best attacks';

  @override
  String get noAttackYet => 'No attack yet';

  @override
  String get noDefenseYet => 'No defense yet';

  @override
  String get bestPerformance => 'Best performance';

  @override
  String get victory => 'Győzelem';

  @override
  String get defeat => 'Vereség';

  @override
  String get draw => 'Döntetlen';

  @override
  String get perfectWar => 'Tökéletes háború';

  @override
  String get newest => 'Legújabb';

  @override
  String get oldest => 'Legidősebb';

  @override
  String get warEnded => 'Háború véget ért';

  @override
  String get preparation => 'Felkészülés';

  @override
  String isNotInWar(String clan) {
    return 'A(z) $clan nincs háborúban.';
  }

  @override
  String warLogIsClosed(String clan) {
    return 'A(z) $clan hadnaplója le van zárva.';
  }

  @override
  String get askForWar =>
      'Lépj kapcsolatba egy vezetővel vagy egy társvezetővel, hogy háborút indíts.';

  @override
  String get askForWarLogOpening =>
      'Lépj kapcsolatba egy vezetővel vagy egy társvezetővel, hogy megnyisd a háború naplót.';

  @override
  String get warLogClosed => 'Háborúnapló lezárva.';

  @override
  String get rounds => 'Körök';

  @override
  String roundNumber(int number) {
    return 'Round $number';
  }

  @override
  String currentRound(int number) {
    return 'Current round (Round $number)';
  }

  @override
  String get noDataAvailableForThisWar =>
      'Nem áll rendelkezésre adat ehhez a háborúhoz';

  @override
  String get stateOfTheWar => 'Háború állapota';

  @override
  String starsNeededToTakeTheLead(
      String clan, int star, int star2, String percent, Object stars2) {
    return '$clan még $star csillagot vagy $stars2 csillagot és $percent%-ot kell szereznie az élre kerüléshez.';
  }

  @override
  String starsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan még $percent%-ot vagy még 1 csillagot kell szereznie az élre kerüléshez';
  }

  @override
  String get clanDraw => 'A klánok fej-fej mellett vannak';

  @override
  String get fastCalculator => 'Gyors számológép';

  @override
  String fastCalculatorAnswer(
      String percentNeedeed, String result, Object percentNeeded) {
    return 'To achieve a destruction rate of $percentNeeded%, a total of $result% is needed.';
  }

  @override
  String get teamSize => 'Csapat mérete';

  @override
  String get neededOverall => '% Szükséges összesen';

  @override
  String get calculate => 'Számítás';

  @override
  String get warStats => 'Háború Statisztika';

  @override
  String warAttacksNumber(int number_time, int number_war) {
    return 'You attacked $number_time time(s) during the last $number_war wars.';
  }

  @override
  String warDefensesNumber(int number_time, int number_war) {
    return 'You defended $number_time time(s) during the last $number_war wars.';
  }

  @override
  String warAverageStars(String stars) {
    return 'You had an average of $stars stars per war.';
  }

  @override
  String warAverageDestruction(String percent) {
    return 'You had an average of $percent% destruction rate per war.';
  }

  @override
  String warAverageStarsDefense(double stars) {
    return 'You had an average of $stars stars per defense.';
  }

  @override
  String warAverageDestructionDefense(Object percent) {
    return 'You had an average of $percent% destruction rate per defense.';
  }

  @override
  String get membersStats => 'Members Stats';

  @override
  String get clanWarLeague => 'Clan War League';

  @override
  String cwlRank(int rank) {
    return 'Your clan is currently ranked $rank.';
  }

  @override
  String cwlStars(int stars) {
    return 'Your clan has a total of $stars stars.';
  }

  @override
  String cwlMissingStarsFromNext(int stars) {
    return 'Your clan is missing $stars stars to catch up with the next clan.';
  }

  @override
  String cwlMissingStarsFromFirst(int stars) {
    return 'Your clan is missing $stars stars to catch up with the first clan.';
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
  String cwlCurrentRound(int round) {
    return 'It\'s currently round $round.';
  }

  @override
  String get noAccountLinkedToYourProfileFound =>
      'A profilhoz nem található csatolt fiók';

  @override
  String get management => 'Kezelés';

  @override
  String get comingSoon => 'Hamarosan!';

  @override
  String get connectionError =>
      'An error occurred. Please check your internet connection and try again.';

  @override
  String get connectionErrorRelaunch =>
      'An error occurred. Please check your internet connection and relaunch the app.';

  @override
  String updatedAt(String time) {
    return 'Updated at $time';
  }

  @override
  String get tools => 'Tools';

  @override
  String get community => 'Community';

  @override
  String get raids => 'Raids';

  @override
  String get lastRaids => 'Last raids';

  @override
  String get ongoingRaids => 'Ongoing raids';

  @override
  String get districtsDestroyed => 'Districts destroyed';

  @override
  String get raidsCompleted => 'Raids completed';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get maintenanceDescription =>
      'Clash of Clans is currently under maintenance, so we can\'t access the API. Please check back later.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get downloadTooltip => 'Download CWL summary';

  @override
  String get downloadInProgress =>
      'Downloading file... It can take a few seconds...';

  @override
  String downloadSuccess(String path) {
    return 'File saved successfully in \$$path';
  }

  @override
  String get downloadError => 'Failed to download file';
}
