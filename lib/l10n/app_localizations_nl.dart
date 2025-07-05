// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'ClashKing';

  @override
  String get appDescription =>
      'Jouw ultieme Clash of Clans metgezel voor het bijhouden van statistieken, beheren van clans en analyseren van prestaties.';

  @override
  String get generalLoading => 'Laden...';

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
  String get generalRetry => 'Opnieuw proberen';

  @override
  String get generalTryAgain => 'Probeer het later opnieuw';

  @override
  String get generalCancel => 'Annuleren';

  @override
  String get generalOk => 'Oké';

  @override
  String get generalApply => 'Toepassen';

  @override
  String get generalConfirm => 'Bevestigen';

  @override
  String get generalManage => 'Beheren';

  @override
  String get generalSettings => 'Instellingen';

  @override
  String get generalCopiedToClipboard => 'Gekopieerd naar klembord';

  @override
  String get generalComingSoon => 'Binnenkort beschikbaar!';

  @override
  String generalLastRefresh(String time) {
    return 'Last refresh: $time';
  }

  @override
  String generalRefreshFailed(String error) {
    return 'Refresh failed: $error';
  }

  @override
  String get generalAll => 'Alle';

  @override
  String get generalTotal => 'Totaal';

  @override
  String get generalBest => 'Beste';

  @override
  String get generalWorst => 'Slechtste';

  @override
  String get generalAverage => 'Gemiddelde';

  @override
  String get generalRemaining => 'Resterend';

  @override
  String get generalActive => 'Actief';

  @override
  String get generalInactive => 'Inactief';

  @override
  String get generalStarted => 'Gestart';

  @override
  String get generalEnded => 'Afgelopen';

  @override
  String get generalRole => 'Rol';

  @override
  String get generalStats => 'Statistieken';

  @override
  String get generalFullStats => 'Volledige statistieken';

  @override
  String get generalDetails => 'Details';

  @override
  String get generalHistory => 'Geschiedenis';

  @override
  String get generalFilters => 'Filters';

  @override
  String get generalNotSet => 'Niet ingesteld';

  @override
  String get generalWarning => 'Waarschuwing';

  @override
  String get generalNoDataAvailable => 'Geen gegevens beschikbaar.';

  @override
  String get authSignUp => 'Registreren';

  @override
  String get authLogin => 'Inloggen';

  @override
  String get authLogout => 'Uitloggen';

  @override
  String get authCreateAccount => 'Account aanmaken';

  @override
  String get authJoinClashKing => 'Doe mee met ClashKing';

  @override
  String get authCreateClashKingAccount => 'ClashKing-account aanmaken';

  @override
  String get authCreateAccountToGetStarted =>
      'Maak je account aan om te beginnen';

  @override
  String get authAlreadyHaveAccount => 'Heb je al een account? Log in';

  @override
  String get authConfirmLogout => 'Weet je zeker dat je wilt uitloggen?';

  @override
  String get authDiscordTitle => 'Discord';

  @override
  String get authDiscordSignIn => 'Inloggen met Discord';

  @override
  String get authDiscordContinue => 'Doorgaan met Discord';

  @override
  String get authDiscordDescription =>
      'Synchroniseer je gegevens met ClashKing Bot en ontgrendel het volledige potentieel van ClashKing!';

  @override
  String get authEmailTitle => 'E-mail';

  @override
  String get authEmailDescription =>
      'Gebruik e-mail als je geen toegang hebt tot Discord of alleen app-functies wilt';

  @override
  String get authEmailRequired => 'Voer je e-mail in';

  @override
  String get authEmailInvalid => 'Voer een geldig e-mailadres in';

  @override
  String get authPasswordLabel => 'Wachtwoord';

  @override
  String get authPasswordConfirm => 'Wachtwoord bevestigen';

  @override
  String get authPasswordRequired => 'Voer je wachtwoord in';

  @override
  String get authPasswordConfirmRequired => 'Bevestig je wachtwoord';

  @override
  String get authPasswordMismatch => 'Wachtwoorden komen niet overeen';

  @override
  String get authPasswordTooShort =>
      'Wachtwoord moet minimaal 8 tekens lang zijn';

  @override
  String get authPasswordRequirements =>
      'Wachtwoord moet bevatten: hoofdletter, kleine letter, cijfer en speciaal teken';

  @override
  String get authPasswordForgot => 'Wachtwoord vergeten?';

  @override
  String get authUsernameLabel => 'Gebruikersnaam';

  @override
  String get authUsernameRequired => 'Voer een gebruikersnaam in';

  @override
  String get authUsernameTooShort =>
      'Gebruikersnaam moet minimaal 3 tekens lang zijn';

  @override
  String get authErrorConnection =>
      'Er is een fout opgetreden. Controleer je internetverbinding en probeer het opnieuw.';

  @override
  String get authErrorConnectionRelaunch =>
      'Er is een fout opgetreden. Controleer je internetverbinding en start de app opnieuw op.';

  @override
  String get authAccountManagement => 'Accountbeheer';

  @override
  String get authAccountConnected => 'Verbonden accounts';

  @override
  String get authAccountConnectedStatus => 'Verbonden';

  @override
  String get authAccountNotConnected => 'Niet verbonden';

  @override
  String get authAccountEmailAndPassword => 'E-mail & wachtwoord';

  @override
  String get authAccountSecured =>
      'Je account is beveiligd met meerdere authenticatiemethoden';

  @override
  String get authAccountLinkEmail => 'E-mailaccount koppelen';

  @override
  String get authAccountAddEmailAuth =>
      'Voeg e-mail- en wachtwoordauthenticatie toe aan je account voor extra beveiliging.';

  @override
  String get authAccountEmailLinkedSuccess =>
      'E-mailaccount succesvol gekoppeld!';

  @override
  String get helpTitle => 'Hulp nodig?';

  @override
  String get helpJoinDiscord => 'Doe mee op Discord';

  @override
  String get helpEmailUs => 'E-mail ons';

  @override
  String get accountsWelcome => 'Welkom!';

  @override
  String get accountsWelcomeMessage =>
      'Voeg een of meer Clash of Clans-accounts toe aan je profiel. Je kunt later accounts toevoegen of verwijderen.';

  @override
  String get accountsManageTitle => 'Beheer je accounts';

  @override
  String get accountsNoneFound =>
      'Geen account gekoppeld aan je profiel gevonden';

  @override
  String get accountsPlayerTag => 'Speler Tag (#ABC123)';

  @override
  String get accountsEnterPlayerTag => 'Voer een spelertag in';

  @override
  String get accountsAdd => 'Account toevoegen';

  @override
  String get accountsDelete => 'Account verwijderen';

  @override
  String get accountsApiToken => 'Account API-token';

  @override
  String get accountsEnterApiToken =>
      'Voer het account API-token in om te bevestigen dat het van jou is. Je vindt het in Clash of Clans Instellingen > Meer instellingen > API-token.';

  @override
  String get accountsFillAllFields => 'Vul alle velden in.';

  @override
  String get accountsErrorTagNotExists =>
      'De ingevoerde spelertag bestaat niet.';

  @override
  String accountsErrorAlreadyLinked(Object tag) {
    return 'De spelertag is al gekoppeld aan iemand anders.';
  }

  @override
  String get accountsErrorAlreadyLinkedToYou =>
      'De spelertag is al aan jou gekoppeld.';

  @override
  String get accountsErrorWrongApiToken =>
      'Het ingevoerde API-token is onjuist';

  @override
  String get accountsErrorFailedToAdd =>
      'Account toevoegen mislukt. Probeer het later opnieuw.';

  @override
  String get accountsErrorFailedToDelete =>
      'Link verwijderen mislukt. Probeer het later opnieuw.';

  @override
  String get accountsErrorFailedToUpdateOrder =>
      'Volgorde van accounts bijwerken mislukt.';

  @override
  String get errorTitle =>
      'Oeps! Onze servers hebben misschien een vuurbal in het gezicht gekregen! We spreken een genezing uit... Probeer het over een moment opnieuw.';

  @override
  String get errorSubtitle =>
      'Als het probleem aanhoudt, kijk dan op onze Discord-server of we ervan op de hoogte zijn.';

  @override
  String get errorLoadingVersion => 'Fout bij het laden van de versie';

  @override
  String get errorCannotOpenLink => 'We kunnen deze link niet openen.';

  @override
  String get errorExitAppToOpenClash =>
      'Je verlaat de app om Clash of Clans te openen.';

  @override
  String get playerSearchTitle => 'Zoek speler';

  @override
  String get playerSearchPlaceholder => 'Spelernaam of tag';

  @override
  String playerLastActive(String date) {
    return 'Laatst actief: $date';
  }

  @override
  String get playerNotTracked =>
      'Deze speler wordt niet gevolgd. De gegevens kunnen onnauwkeurig zijn.';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Je clan is \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(
      String ratio, String donations, String received) {
    return 'Je donatieverhouding is $ratio. Je hebt $donations troepen gedoneerd en $received troepen ontvangen.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Je oorlogsvoorkeur is \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'Je hebt $stars oorlogsterren.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'Je hebt $trophies trofeeën. Je zit momenteel in $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Je stadhuisniveau is $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Je Bouwerszaal is level $level en je hebt $trophies trofeeën.';
  }

  @override
  String get gameBaseHome => 'Thuisbasis';

  @override
  String get gameBaseBuilder => 'Bouwerbasis';

  @override
  String get gameClanCapital => 'Clan Hoofdstad';

  @override
  String get gameTownHall => 'SH';

  @override
  String get gameTownHallLevel => 'SH niveau';

  @override
  String gameTownHallLevelNumber(int level) {
    return 'Stadhuis $level';
  }

  @override
  String gameTHLevel(int level) {
    return 'SH$level';
  }

  @override
  String get gameExpLevel => 'Ervaringsniveau';

  @override
  String get gameTrophies => 'Trofeeën';

  @override
  String get gameBuilderBaseTrophies => 'BB Trofeeën';

  @override
  String get gameDonations => 'Donaties';

  @override
  String get gameDonationsReceived => 'Donaties ontvangen';

  @override
  String get gameDonationsRatio => 'Donatieverhouding';

  @override
  String gameLevel(int level, int maxLevel) {
    return 'Niveau: $level/$maxLevel';
  }

  @override
  String get gameHeroes => 'Helden';

  @override
  String get gameEquipment => 'Uitrusting';

  @override
  String get gameHeroesEquipments => 'Heldenuitrusting';

  @override
  String get gameTroops => 'Troepen';

  @override
  String get gameActiveSuperTroops => 'Actieve supertroepen';

  @override
  String get gamePets => 'Huisdieren';

  @override
  String get gameSiegeMachines => 'Belegeringsmachines';

  @override
  String get gameSpells => 'Spreuken';

  @override
  String get gameAchievements => 'Prestaties';

  @override
  String get gameClanGames => 'Clan Spellen';

  @override
  String get gameSeasonPass => 'Seizoenspas';

  @override
  String get gameCreatorCode => 'Makerscode: ClashKing';

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
  String get clanTitle => 'Clan';

  @override
  String get clanSearchTitle => 'Zoek clan';

  @override
  String get clanSearchPlaceholder => 'Clannaam';

  @override
  String get clanNone => 'Geen clan';

  @override
  String get clanJoinToUnlock =>
      'Sluit je aan bij een clan om nieuwe functies te ontgrendelen.';

  @override
  String get clanMembers => 'Leden';

  @override
  String get clanWarFrequency => 'Oorlogfrequentie';

  @override
  String get clanMinimumMembers => 'Minimum aantal leden';

  @override
  String get clanMaximumMembers => 'Maximum aantal leden';

  @override
  String get clanLocation => 'Locatie';

  @override
  String get clanMinimumPoints => 'Minimale clanpunten';

  @override
  String get clanMinimumLevel => 'Minimaal clanniveau';

  @override
  String get clanInviteOnly => 'Op uitnodiging';

  @override
  String get clanOpened => 'Geopend';

  @override
  String get clanClosed => 'Gesloten';

  @override
  String get clanRoleLeader => 'Leider';

  @override
  String get clanRoleCoLeader => 'Co-leider';

  @override
  String get clanRoleElder => 'Oudste';

  @override
  String get clanRoleMember => 'Lid';

  @override
  String get clanWarFrequencyAlways => 'Altijd';

  @override
  String get clanWarFrequencyNever => 'Nooit';

  @override
  String get clanWarFrequencyUnknown => 'Onbekend';

  @override
  String get clanWarFrequencyOncePerWeek => '1/week';

  @override
  String get clanWarFrequencyMoreThanOncePerWeek => 'Meer dan 1/week';

  @override
  String get clanWarFrequencyRarely => 'Zelden';

  @override
  String get timeHourIndicator => 'u';

  @override
  String timeDaysAgo(int days) {
    return '$days dagen geleden';
  }

  @override
  String timeDayAgo(int day) {
    return '$day dag geleden';
  }

  @override
  String timeHourAgo(int hour) {
    return '$hour uur geleden';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours uur geleden';
  }

  @override
  String timeMinuteAgo(int minute) {
    return '$minute minuut geleden';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes minuten geleden';
  }

  @override
  String get timeJustNow => 'Zojuist';

  @override
  String get timeEndedJustNow => 'Zojuist afgelopen';

  @override
  String timeEndedMinutesAgo(int minutes) {
    return '$minutes minuten geleden afgelopen';
  }

  @override
  String timeEndedHoursAgo(int hours) {
    return '$hours uur geleden afgelopen';
  }

  @override
  String timeEndedDaysAgo(int days) {
    return '$days dagen geleden afgelopen';
  }

  @override
  String timeStartsIn(String time) {
    return 'Begint over $time';
  }

  @override
  String timeStartsAt(String time) {
    return 'Begint om $time';
  }

  @override
  String timeEndsIn(String time) {
    return 'Eindigt over $time';
  }

  @override
  String timeEndsAt(String time) {
    return 'Eindigt om $time';
  }

  @override
  String get legendsTitle => 'Legendarische Liga';

  @override
  String get legendsNotInLeague => 'Niet in de Legendarische Liga';

  @override
  String get legendsNoDataToday =>
      'Je zit niet in de Legendarische Liga, maar vorige seizoenen zijn beschikbaar.';

  @override
  String legendsStartDescription(String trophies) {
    return 'Je bent de dag begonnen met $trophies trofeeën.';
  }

  @override
  String legendsNoRankLocalDescription(String country, int trophies) {
    return 'Je staat momenteel niet gerangschikt ($country) met $trophies trofeeën.';
  }

  @override
  String legendsRankLocalDescription(int rank, String country, int trophies) {
    return 'Je staat momenteel op rang $rank ($country) met $trophies trofeeën.';
  }

  @override
  String legendsGainDescription(int trophies) {
    return 'Je hebt tot nu toe $trophies trofeeën verdiend.';
  }

  @override
  String legendsLossDescription(int trophies) {
    return 'Je hebt tot nu toe $trophies trofeeën verloren.';
  }

  @override
  String legendsNoGlobalRankDescription(int trophies) {
    return 'Je staat momenteel niet wereldwijd gerangschikt met $trophies trofeeën.';
  }

  @override
  String legendsGlobalRankDescription(int rank, int trophies) {
    return 'Je staat momenteel op rang $rank wereldwijd met $trophies trofeeën.';
  }

  @override
  String get legendsNoRank => 'Geen ranking';

  @override
  String get legendsBestTrophies => 'Beste trofeeën';

  @override
  String get legendsMostAttacks => 'Meeste aanvallen';

  @override
  String get legendsLastSeason => 'Laatste seizoen';

  @override
  String get legendsBestRank => 'Beste wereldwijde rang';

  @override
  String get legendsTrophiesBySeason => 'Trofeeën per seizoen';

  @override
  String get legendsEosTrophies => 'Einde van seizoen trofeeën';

  @override
  String get legendsEosDetails => 'Einde van seizoen details';

  @override
  String get legendsInaccurateTitle => 'Onjuiste gegevens?';

  @override
  String get legendsInaccurateIntro =>
      'Vanwege beperkingen van de Clash of Clans API zijn onze gegevens mogelijk niet altijd perfect accuraat. Hier is waarom:\n';

  @override
  String get legendsInaccurateApiDelayTitle => '1. API-vertraging: ';

  @override
  String get legendsInaccurateApiDelayBody =>
      'De API kan tot 5 minuten duren om bij te werken, wat een vertraging veroorzaakt bij het weergeven van realtime trofeewijzigingen.\n';

  @override
  String get legendsInaccurateConcurrentTitle =>
      '2. Gelijktijdige wijzigingen: \n';

  @override
  String get legendsInaccurateMultipleAttacksTitle =>
      '- Meerdere aanvallen/verdedigingen: ';

  @override
  String get legendsInaccurateMultipleAttacksBody =>
      'Als meerdere aanvallen of verdedigingen kort na elkaar plaatsvinden, kan de API gecombineerde resultaten weergeven (bijv. +68 of -68).\n';

  @override
  String get legendsInaccurateSimultaneousTitle =>
      '- Gelijktijdige aanval en verdediging: ';

  @override
  String get legendsInaccurateSimultaneousBody =>
      'Als een aanval en verdediging op hetzelfde moment plaatsvinden, zie je mogelijk een gemengd resultaat (bijv. +4).\n';

  @override
  String get legendsInaccurateNetGainTitle => '3. Netto winst/verlies: ';

  @override
  String get legendsInaccurateNetGainBody =>
      'Ondanks timing-problemen is de totale netto winst of verlies voor de dag accuraat. ';

  @override
  String get legendsInaccurateConclusion =>
      'Deze beperkingen zijn gebruikelijk bij alle tools die de Clash of Clans API gebruiken. Helaas kunnen we dat niet oplossen omdat het in handen van Supercell ligt. We doen ons best om deze limieten te compenseren en resultaten te bieden die zo dicht mogelijk bij de werkelijkheid liggen. Bedankt voor je begrip!';

  @override
  String get statsSeasonStats => 'Seizoenstatistieken';

  @override
  String get statsByDay => 'Per dag';

  @override
  String get statsBySeason => 'Per seizoen';

  @override
  String statsDayIndex(int index) {
    return 'Dag $index';
  }

  @override
  String statsIndexDays(int index) {
    return '$index dagen';
  }

  @override
  String statsSeasonDate(String date) {
    return '$date seizoen';
  }

  @override
  String get statsAllTownHalls => 'Alle stadhuizen';

  @override
  String get statsMembers => 'Ledenstatistieken';

  @override
  String get todoTitle => 'Takenlijst';

  @override
  String get todoExplanationTitle => 'Taakberekening';

  @override
  String get todoExplanationIntro =>
      'Het voltooiingspercentage van taken wordt berekend op basis van de volgende activiteiten met specifieke gewichten:';

  @override
  String get todoExplanationLegendsTitle => 'Legendarische Liga:';

  @override
  String get todoExplanationLegends =>
      'Gewicht van 8 punten per account, 1 aanval = 1 punt.';

  @override
  String get todoExplanationRaidsTitle => 'Raids:';

  @override
  String get todoExplanationRaids =>
      'Gewicht van 5 punten per account (of 6 als de laatste aanval is ontgrendeld), 1 aanval = 1 punt.';

  @override
  String get todoExplanationClanWarsTitle => 'Clanoorlogen:';

  @override
  String get todoExplanationClanWars =>
      'Gewicht van 2 punten per account, 1 aanval = 1 punt.';

  @override
  String get todoExplanationCwlTitle => 'Clanoorlogliga:';

  @override
  String get todoExplanationCwl =>
      'Gewicht van 1 punt per account, 1 aanval = 1 punt. CWL kan niet worden gevolgd als de speler niet in zijn ligaclan zit.';

  @override
  String get todoExplanationPassAndGamesTitle => 'Seizoenspas & Clan Spellen:';

  @override
  String get todoExplanationPassAndGames =>
      'Gewicht van elk 2 punten per account. De verhouding is gebaseerd op het aantal resterende dagen (1 maand voor de pas en 6 dagen voor de spellen). Groen = op schema om de pas of spellen te voltooien, rood = achter op schema.';

  @override
  String get todoExplanationConclusion =>
      'Het uiteindelijke percentage wordt berekend door het totaal aantal voltooide acties tijdens lopende evenementen te delen door het totaal aantal vereiste acties. Accounts die langer dan 14 dagen inactief zijn worden uitgesloten van de berekening.';

  @override
  String todoAccountsNumber(int number) {
    return '$number accounts';
  }

  @override
  String todoAccountsNumberActive(int number) {
    return '$number actieve accounts';
  }

  @override
  String todoAccountsNumberInactive(int number) {
    return '$number inactieve accounts';
  }

  @override
  String get todoAccountsActive => 'Actieve accounts';

  @override
  String get todoAccountsInactive => 'Inactieve accounts';

  @override
  String get todoAccountsNoInactive => 'Geen inactieve accounts.';

  @override
  String get todoAccountsNoActive => 'Geen actieve accounts.';

  @override
  String todoAttacksLeftDescription(int attacks, String type) {
    return 'Je hebt nog $attacks aanval(len) over ($type).';
  }

  @override
  String todoDefensesLeftDescription(int defenses, String type) {
    return 'Je hebt nog $defenses verdediging(en) over ($type).';
  }

  @override
  String todoNoAttacksLeftDescription(String type) {
    return 'Gefeliciteerd, je hebt al je aanvallen gedaan ($type)!';
  }

  @override
  String todoPointsLeftDescription(int points, String type) {
    return 'Je moet vandaag nog $points punten behalen om op tijd te zijn voor het einde van het evenement ($type).';
  }

  @override
  String todoPointsLeftDescriptionNoPoints(String type) {
    return 'Gefeliciteerd, je bent op tijd om de maximale beloningen aan het einde van het evenement te krijgen ($type)!';
  }

  @override
  String get warTitle => 'Oorlog';

  @override
  String get warFrequency => 'Oorlogfrequentie';

  @override
  String get warParticipation => 'Oorlogdeelname';

  @override
  String get warLeague => 'Oorlog/Liga';

  @override
  String get warHistory => 'Oorloggeschiedenis';

  @override
  String get warLog => 'Oorloglog';

  @override
  String warLogClosed(String clan) {
    return '${clan}s oorloglog is gesloten.';
  }

  @override
  String get warStats => 'Oorlogstatistieken';

  @override
  String get warOngoing => 'Lopende oorlog';

  @override
  String warIsNotInWar(String clan) {
    return '$clan is niet in oorlog.';
  }

  @override
  String get warAskForWar =>
      'Neem contact op met de leider of een co-leider om een oorlog te starten.';

  @override
  String get warAskForWarLogOpening =>
      'Neem contact op met de leider of een co-leider om het oorloglog te openen.';

  @override
  String get warEnded => 'Oorlog afgelopen';

  @override
  String get warPreparation => 'Voorbereiding';

  @override
  String get warPerfectWar => 'Perfecte oorlog';

  @override
  String get warVictory => 'Overwinning';

  @override
  String get warDefeat => 'Nederlaag';

  @override
  String get warDraw => 'Gelijkspel';

  @override
  String get warTeamSize => 'Teamgrootte';

  @override
  String get warMyTeam => 'Mijn team';

  @override
  String get warEnemiesTeam => 'Vijanden';

  @override
  String get warClanDraw => 'De twee clans staan gelijk';

  @override
  String get warStateOfTheWar => 'Stand van de oorlog';

  @override
  String warStarsNeededToTakeTheLead(
      String clan, int star, int stars2, String percent) {
    return '$clan heeft nog $star meer ster(ren) nodig of $stars2 ster(ren) en $percent% om de leiding te nemen.';
  }

  @override
  String warStarsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan heeft nog $percent% of 1 meer ster nodig om de leiding te nemen';
  }

  @override
  String get warNoDataAvailableForThisWar =>
      'Geen gegevens beschikbaar voor deze oorlog';

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
  String get warAttacksTitle => 'Aanvallen';

  @override
  String get warAttacksNone => 'Nog geen aanval';

  @override
  String get warAttacksBest => 'Beste aanvallen';

  @override
  String get warAttacksCount => 'Aantal aanvallen';

  @override
  String get warAttacksMissed => 'Gemiste aanvallen';

  @override
  String warAttacksNumber(int number_time, int number_war) {
    return 'Je hebt $number_time keer aangevallen tijdens de laatste $number_war oorlogen.';
  }

  @override
  String warAttacksAverageStars(String stars) {
    return 'Je had gemiddeld $stars sterren per oorlog.';
  }

  @override
  String warAttacksAverageDestruction(String percent) {
    return 'Je had een gemiddeld vernietigingspercentage van $percent% per oorlog.';
  }

  @override
  String get warDefensesTitle => 'Verdedigingen';

  @override
  String get warDefensesNone => 'Nog geen verdediging';

  @override
  String get warDefensesBest => 'Beste verdedigingen';

  @override
  String warDefensesBestOutOf(int number) {
    return 'Beste verdediging (van $number)';
  }

  @override
  String warDefensesNumber(int number_time, int number_war) {
    return 'Je hebt $number_time keer verdedigd tijdens de laatste $number_war oorlogen.';
  }

  @override
  String warDefensesAverageStars(double stars) {
    return 'Je had gemiddeld $stars sterren per verdediging.';
  }

  @override
  String warDefensesAverageDestruction(String percent) {
    return 'Je had een gemiddeld vernietigingspercentage van $percent% per verdediging.';
  }

  @override
  String get warStarsTitle => 'Sterren';

  @override
  String get warStarsAverage => 'Gemiddelde sterren';

  @override
  String get warStarsNumber => 'Aantal sterren';

  @override
  String get warStarsOne => '1 ster';

  @override
  String get warStarsTwo => '2 sterren';

  @override
  String get warStarsThree => '3 sterren';

  @override
  String get warStarsZero => '0 sterren';

  @override
  String get warStarsBestPerformance => 'Beste prestatie';

  @override
  String get warDestructionTitle => 'Vernietiging';

  @override
  String get warDestructionAverage => 'Gemiddelde vernietiging';

  @override
  String get warDestructionRate => 'Vernietigingspercentage';

  @override
  String warHistoryWinsDescription(int wins, String percent) {
    return 'Je clan heeft $wins oorlogen gewonnen ($percent%) van de laatste 50 oorlogen.';
  }

  @override
  String warHistoryLossesDescription(int losses, String percent) {
    return 'Je clan heeft $losses oorlogen verloren ($percent%) van de laatste 50 oorlogen.';
  }

  @override
  String warHistoryDrawsDescription(int draws, String percent) {
    return 'Je clan had $draws gelijkspelen ($percent%) van de laatste 50 oorlogen.';
  }

  @override
  String warHistoryAverageMembersDescription(int members) {
    return 'Je clan heeft gemiddeld $members leden die deelnemen aan de laatste 50 oorlogen.';
  }

  @override
  String warHistoryAverageWarStarsDescription(double stars, String percent) {
    return 'Je clan had gemiddeld $stars sterren per oorlog van de laatste 50 oorlogen. Dit vertegenwoordigt $percent% van de totale sterren.';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return 'Je clan had een gemiddeld vernietigingspercentage van $percent% van de laatste 50 oorlogen.';
  }

  @override
  String get warPositionMap => 'Kaartpositie';

  @override
  String get warPositionAbbr => 'Pos';

  @override
  String get warPositionOrder => 'Volgorde';

  @override
  String get warOpponentTownhall => 'Teg SH';

  @override
  String get warOpponentLowerTownhall => 'Lager SH';

  @override
  String get warOpponentUpperTownhall => 'Hoger SH';

  @override
  String get warOpponentEqualThLevel => 'Equal TH';

  @override
  String get warOpponentSelectMembersThLevel => 'Members TH Level';

  @override
  String get warOpponentSelectOpponentsThLevel => 'Opponents TH Level';

  @override
  String warFiltersLastXwars(int number) {
    return 'Laatste $number oorlogen';
  }

  @override
  String get warFiltersFriendly => 'Vriendschappelijk';

  @override
  String get warFiltersRandom => 'Willekeurig';

  @override
  String get warVisibilityToggleTownHall =>
      'Verberg/toon statistieken van voormalige SH-niveaus';

  @override
  String get warEventsTitle => 'Evenementen';

  @override
  String get warEventsNewest => 'Nieuwste';

  @override
  String get warEventsOldest => 'Oudste';

  @override
  String get warStatusReady => 'Aangemeld';

  @override
  String get warStatusUnready => 'Afgemeld';

  @override
  String get warStatusMissed => 'Gemist';

  @override
  String get warAbbreviationAvg => 'Gem';

  @override
  String get warAbbreviationAvgPercentage => 'Gem %';

  @override
  String get cwlTitle => 'CWL';

  @override
  String get cwlClanWarLeague => 'Clanoorlogliga';

  @override
  String get cwlOngoing => 'Lopende CWL';

  @override
  String get cwlRounds => 'Rondes';

  @override
  String cwlRoundNumber(int number) {
    return 'Ronde $number';
  }

  @override
  String cwlCurrentRound(int round) {
    return 'Het is momenteel ronde $round.';
  }

  @override
  String cwlRank(int rank) {
    return 'Je clan staat momenteel op rang $rank.';
  }

  @override
  String cwlStars(int stars) {
    return 'Je clan heeft in totaal $stars sterren.';
  }

  @override
  String cwlDestructionPercentage(String percent) {
    return 'Je clan heeft een totaal vernietigingspercentage van $percent%.';
  }

  @override
  String cwlTotalAttacks(int attacks, int totalAttacks) {
    return 'Je clan heeft in totaal $attacks aanvallen van $totalAttacks mogelijke aanvallen.';
  }

  @override
  String get joinLeaveTitle => 'Toetredings-/uitredingslogs (huidig seizoen)';

  @override
  String get joinLeaveJoin => 'Toetreden';

  @override
  String get joinLeaveLeave => 'Verlaten';

  @override
  String get joinLeaveReset => 'Reset';

  @override
  String get joinLeaveJoins => 'Toetredingen';

  @override
  String get joinLeaveLeaves => 'Uitredingen';

  @override
  String get joinLeaveUniquePlayers => 'Unieke spelers';

  @override
  String get joinLeaveMovingPlayers => 'Wisselende spelers';

  @override
  String get joinLeaveMostMovingPlayers => 'Meest wisselende spelers';

  @override
  String get joinLeaveStillInClan => 'Nog in clan';

  @override
  String get joinLeaveLeftForever => 'Voor altijd vertrokken';

  @override
  String get joinLeaveRejoinedPlayers => 'Weer toegetreden spelers';

  @override
  String get joinLeaveAvgTimeJoinLeave => 'Gem. toetredings-/uitredingstijd';

  @override
  String get joinLeavePeakHour => 'Meest actieve uur';

  @override
  String joinLeaveNumberDescription(int number, String date) {
    return '$number uitredingsgebeurtenissen vonden plaats tijdens het huidige seizoen ($date).';
  }

  @override
  String joinLeaveJoinNumberDescription(int number, String date) {
    return '$number toetredingsgebeurtenissen vonden plaats tijdens het huidige seizoen ($date).';
  }

  @override
  String joinLeaveMovingNumberDescription(int number, String date) {
    return '$number speler(s) verlieten de clan en traden opnieuw toe tijdens het huidige seizoen ($date).';
  }

  @override
  String joinLeaveUniqueNumberDescription(int number, String date) {
    return '$number unieke speler(s) traden toe/verlieten de clan tijdens het huidige seizoen ($date).';
  }

  @override
  String joinLeaveStillInClanNumberDescription(int number) {
    return '$number speler(s) traden toe en zitten nog steeds in de clan.';
  }

  @override
  String joinLeaveLeftClanNumberDescription(int number) {
    return '$number speler(s) traden toe, verlieten vervolgens de clan en traden nooit meer toe.';
  }

  @override
  String joinLeaveLeftOnAt(String date, String time) {
    return 'Vertrokken op $date om $time.';
  }

  @override
  String joinLeaveJoinedOnAt(String date, String time) {
    return 'Toegetreden op $date om $time.';
  }

  @override
  String get raidsTitle => 'Raids';

  @override
  String get raidsLast => 'Laatste raids';

  @override
  String get raidsOngoing => 'Lopende raids';

  @override
  String get raidsDistrictsDestroyed => 'Districten vernietigd';

  @override
  String get raidsCompleted => 'Raids voltooid';

  @override
  String get searchNoResult => 'Geen resultaat.';

  @override
  String get maintenanceTitle => 'Onderhoud';

  @override
  String get maintenanceDescription =>
      'Clash of Clans is momenteel in onderhoud, dus we kunnen geen toegang krijgen tot de API. Kom later terug.';

  @override
  String get downloadTooltip => 'CWL-samenvatting downloaden';

  @override
  String get downloadInProgress =>
      'Bestand downloaden... Dit kan een paar seconden duren...';

  @override
  String downloadSuccess(String path) {
    return 'Bestand succesvol opgeslagen in $path';
  }

  @override
  String get downloadError => 'Bestand downloaden mislukt';

  @override
  String get dashboardTitle => 'Hoofdpaneel';

  @override
  String get toolsTitle => 'Hulpmiddelen';

  @override
  String get navigationTeam => 'Teams';

  @override
  String get navigationStatistics => 'Statistics';

  @override
  String get versionDevice => 'Versie & apparaat';

  @override
  String get settingsLicenses => 'Open Source Licenses';

  @override
  String get settingsLicensesSubtitle =>
      'View licenses for third-party libraries';

  @override
  String get betaFeature => 'Beta-functie';

  @override
  String get betaLabel => 'BETA';

  @override
  String get betaDescription =>
      'Deze functie bevindt zich momenteel in beta, er kunnen bugs in zitten of het kan onvolledig zijn. We werken actief aan verbeteringen en verwelkomen je feedback. Deel je ideeën en meld problemen op onze Discord-server om ons te helpen het beter te maken.';

  @override
  String get settingsLanguage => 'Taal';

  @override
  String get settingsSelectLanguage => 'Selecteer een taal';

  @override
  String get settingsToggleTheme => 'Thema wisselen';

  @override
  String get faqTitle => 'FAQ';

  @override
  String get faqSubtitle => 'Veelgestelde vragen';

  @override
  String get faqIsThisFromSupercell => 'Is deze app van Supercell?';

  @override
  String get faqFanContentPolicy =>
      'Dit materiaal is onofficieel en wordt niet goedgekeurd door Supercell. Voor meer informatie zie Supercells Fan Content Policy: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate =>
      'Waarom zijn de gegevens soms onnauwkeurig of ontbreken ze?';

  @override
  String get faqClanNotTracked => 'Clan niet gevolgd';

  @override
  String get faqClanNotTrackedAnswer =>
      'ClashKing kan deze informatie alleen ophalen als de clan wordt gevolgd. Als je clan niet wordt gevolgd, nodig dan de ClashKing Bot uit op je Discord-server en gebruik het commando /addclan. We werken eraan om deze functie binnenkort beschikbaar te maken in de app.';

  @override
  String get faqTrackingDown => 'Volgen gestopt';

  @override
  String get faqTrackingDownAnswer =>
      'Het volgen kan gedurende een bepaalde periode stoppen met werken. Daarom kun je soms gaten in je gegevens hebben. We werken eraan om dit te verbeteren.';

  @override
  String get faqApiLimitation => 'Clash of Clans API-beperking';

  @override
  String get faqApiLimitationAnswer =>
      'Sommige gegevens worden geleverd door Clash of Clans en hun API heeft enkele beperkingen. Dit is het geval bij legend tracking, waarbij soms trofeewinst en -verlies worden gestapeld alsof het een enkele aanval was. Dit is ook waarom we geen informatie hebben over de niveaus van je gebouwen.';

  @override
  String get faqSupportWork => 'Hoe kan ik jullie werk ondersteunen?';

  @override
  String get faqSupportWorkAnswer =>
      'Er zijn verschillende manieren om ons te ondersteunen:';

  @override
  String get faqUseCodeClashKing => 'Gebruik code \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Steun ons op Patreon';

  @override
  String get faqShareTheApp => 'Deel de app met je vrienden';

  @override
  String get faqRateTheApp => 'Beoordeel de app in de store';

  @override
  String get faqHelpUsTranslate => 'Help ons de app te vertalen';

  @override
  String get faqHowToInviteTheBot =>
      'Hoe kan ik jullie bot uitnodigen op mijn Discord-server?';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'Je kunt onze bot uitnodigen op je server door op de onderstaande knop te klikken. Je hebt de \"Server beheren\" toestemming nodig om de bot toe te voegen.';

  @override
  String get faqInviteTheBot => 'ClashKing Bot uitnodigen';

  @override
  String get faqNeedHelp =>
      'Ik heb hulp nodig of wil graag een suggestie doen. Hoe kan ik contact met jullie opnemen?';

  @override
  String get faqNeedHelpAnswer =>
      'Je kunt lid worden van onze Discord-server om hulp te vragen of feedback te geven, of je kunt ons een e-mail sturen naar devs@clashk.ing. Schrijf alleen in het Engels of Frans.';

  @override
  String get faqSendEmail => 'Stuur een e-mail';

  @override
  String get faqJoinDiscord => 'Word lid van onze Discord-server';

  @override
  String get faqCannotOpenMailClient =>
      'Om een of andere reden kunnen we je mailclient niet openen. We hebben het e-mailadres voor je gekopieerd. Je kunt een e-mail schrijven en het adres plakken in het ontvangerveld.';

  @override
  String get translationHelpUsTranslate => 'Help ons met vertalen';

  @override
  String get translationSuggestFeatures => 'Functies voorstellen';

  @override
  String get translationThankYou => 'Bedankt!';

  @override
  String get translationThankYouContent =>
      'Een enorme dank aan al onze geweldige vertalers die ons helpen deze app toegankelijk te maken voor meer mensen over de hele wereld!';

  @override
  String get translationHelpTranslateContent =>
      'Je kunt ons helpen de app te vertalen op Crowdin. Als je taal niet beschikbaar is op Crowdin, vraag deze dan aan op onze Discord-server. Heel erg bedankt voor je hulp!';

  @override
  String get translationHelpTranslateButton => 'Help vertalen op Crowdin';

  @override
  String get translationCurrentTranslators => 'Huidige vertalers';
}
