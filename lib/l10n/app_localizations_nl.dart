// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get creatorCode => 'Makerscode: ClashKing';

  @override
  String get errorTitle => 'Oops! Our servers might have taken a fireball to the face! We\'re casting a healing spell... Try again in a moment.';

  @override
  String get errorSubtitle => 'If the issue persists, check our Discord Server to see if we\'re aware of it.';

  @override
  String get retry => 'Retry';

  @override
  String get signInWithDiscord => 'Inloggen met Discord';

  @override
  String get guestMode => 'Gastmodus';

  @override
  String get needHelpJoinDiscord => 'Hulp nodig? Doe mee op Discord.';

  @override
  String get loginError => 'An error occurred while logging in. Please try again later.';

  @override
  String get createGuestProfile => 'Maak je gastprofiel aan';

  @override
  String doesNotExist(String tag) {
    return '$tag bestaat niet.';
  }

  @override
  String isAlreadyLinked(String tag) {
    return '$tag is al aan iemand gekoppeld.';
  }

  @override
  String get username => 'Gebruikersnaam';

  @override
  String get pleaseEnterUsername => 'Voer een gebruikersnaam in';

  @override
  String get playerTag => 'Player Tag (#ABC123)';

  @override
  String get playerTags => 'Speler Tags';

  @override
  String get linkedAccounts => 'Linked Accounts';

  @override
  String followingTagsDoNotExist(String tags) {
    return 'De volgende labels bestaan niet: $tags.';
  }

  @override
  String followingTagsAreAlreadyLinked(String tags) {
    return 'De volgende labels zijn al gekoppeld aan iemand: $tags.';
  }

  @override
  String get welcome => 'Welkom!';

  @override
  String get welcomeMessage => 'Voeg alsjeblieft één of meer Clash Of Clans accounts toe aan je profiel. Je kan later accounts toevoegen of verwijderen.';

  @override
  String get login => 'Inloggen';

  @override
  String get logout => 'Uitloggen';

  @override
  String get language => 'Taal';

  @override
  String get settings => 'Instellingen';

  @override
  String get toggleTheme => 'Thema veranderen';

  @override
  String get selectLanguage => 'Selecteer een taal';

  @override
  String get faq => 'FAQ';

  @override
  String get faqSubtitle => 'Veelgestelde Vragen';

  @override
  String get faqIsThisFromSupercell => 'Is deze app van Supercell?';

  @override
  String get faqFanContentPolicy => 'Dit materiaal is onofficieel en wordt niet goedgekeurd door Supercell. Voor meer informatie, zie de Fan Content Policy van Supercell: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate => 'Waarom zijn de gegevens soms onnauwkeurig of ontbreken ze?';

  @override
  String get faqClanNotTracked => 'Clan niet gevolgd';

  @override
  String get faqClanNotTrackedAnswer => 'ClashKing kan deze informatie alleen ophalen als de clan wordt gevolgd. Als je clan niet wordt gevolgd, nodig dan ClashKing uit op je Discord server en gebruik het commando /addclan. We werken eraan om deze functie binnenkort beschikbaar te maken in de app.';

  @override
  String get faqTrackingDown => 'Tracking niet beschikbaar';

  @override
  String get faqTrackingDownAnswer => 'Het volgen kan gedurende een bepaalde periode stoppen met werken. Daarom kunnen er soms gaten in je gegevens zitten. We werken eraan om dit te verbeteren.';

  @override
  String get faqApiLimitation => 'Clash of Clans API limitatie';

  @override
  String get faqApiLimitationAnswer => 'Sommige gegevens worden geleverd door Clash of Clans en hun API heeft enkele beperkingen. Dit is het geval bij het volgen van de legendarisch divisie. De API stapelt soms een trofeeënwimst en -verlies, alsof het één aanval was. Daarom hebben we ook geen informatie over het niveau van je gebouwen.';

  @override
  String get faqSupportWork => 'Hoe kan ik je werk ondersteunen?';

  @override
  String get faqSupportWorkAnswer => 'Er zijn verschillende manieren om ons te steunen:';

  @override
  String get faqUseCodeClashKing => 'Gebruik code \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Steun ons op Patreon';

  @override
  String get faqShareTheApp => 'Deel deze app met je vrienden';

  @override
  String get faqRateTheApp => 'Beoordeel de app in de winkel';

  @override
  String get faqHelpUsTranslate => 'Help ons de app te vertalen';

  @override
  String get faqHowToInviteTheBot => 'Hoe kan ik je bot uitnodigen voor mijn Discord Server?';

  @override
  String get faqHowToInviteTheBotAnswer => 'Je kan onze bot uitnodigen op je server door op de onderstaande knop te klikken. Je moet de toestemming \"Server Beheren\" hebben om de bot toe te voegen.';

  @override
  String get faqInviteTheBot => 'ClashKing Bot uitnodigen';

  @override
  String get faqNeedHelp => 'Ik heb hulp nodig of ik zou graag een suggestie willen doen. Hoe kan ik contact met u opnemen?';

  @override
  String get faqNeedHelpAnswer => 'Je kunt lid worden van onze Discord-server om hulp te vragen of feedback te geven, of je kan ons een e-mail sturen naar devs@clashkingbot.com. Graag alleen in het Engels of Frans schrijven.';

  @override
  String get faqSendEmail => 'Stuur een e-mail';

  @override
  String get faqJoinDiscord => 'Word lid van de Discord server';

  @override
  String get faqCannotOpenMailClient => 'Om wat voor reden dan ook kunnen we je mailclient niet openen. We hebben het e-mailadres voor je gekopieerd. Je kan een e-mail schrijven en het adres plakken in het ontvanger-veld.';

  @override
  String get helpUsTranslate => 'Help ons met vertalen';

  @override
  String get suggestFeatures => 'Een nieuwe functie voorstellen';

  @override
  String get thankYou => 'Bedankt!';

  @override
  String get thankYouContent => 'Hartelijk dank aan al onze geweldige vertalers die ons helpen deze app toegankelijk te maken voor meer mensen over de hele wereld!';

  @override
  String get helpTranslateContent => 'Je kunt ons helpen de app op Crowdin te vertalen. Als je taal niet beschikbaar is op Crowdin, kan je deze aanvragen in onze Discord Server. Heel erg bedankt voor je hulp!';

  @override
  String get helpTranslateButton => 'Help met vertalen op Crowdin';

  @override
  String get versionDevice => 'Versie & Apparaat';

  @override
  String get loading => 'Laden...';

  @override
  String get errorLoadingVersion => 'Fout bij het laden van de versie';

  @override
  String get currentTranslators => 'Huidige vertalers';

  @override
  String get betaFeature => 'Beta-functie';

  @override
  String get beta => 'BETA';

  @override
  String get betaDescription => 'Deze functie bevindt zich momenteel in bèta, het kan wat bugs bevatten of onvolledig zijn. We werken actief aan verbeteringen en verwelkomen je feedback. Deel alstublieft je ideeën en meld eventuele problemen op onze Discord-server om ons te helpen de app te verbeteren.';

  @override
  String get copiedToClipboard => 'Gekopieerd naar klembord';

  @override
  String get all => 'Alle';

  @override
  String get hourIndicator => 'u';

  @override
  String get minIndicator => 'm';

  @override
  String get noDataAvailable => 'Geen gegevens beschikbaar.';

  @override
  String get close => 'Sluiten';

  @override
  String get closed => 'Gesloten';

  @override
  String get error => 'Fout';

  @override
  String get player => 'Speler';

  @override
  String notFoundOrNotLinkedToOurSystem(String player) {
    return '$player niet gevonden of niet gekoppeld aan ons systeem.';
  }

  @override
  String get tryAnotherNameOrTagOrLinkIt => 'Probeer een andere naam/tag of link het.';

  @override
  String get playerNotFound => 'Speler niet gevonden';

  @override
  String get noValueEntered => 'Geen waarde ingevoerd';

  @override
  String get manage => 'Beheren';

  @override
  String get enterPlayerTag => 'Voer een speler-ID in';

  @override
  String get add => 'Toevoegen';

  @override
  String get delete => 'Verwijderen';

  @override
  String get addAccount => 'Account toevoegen';

  @override
  String get deleteAccount => 'Account verwijderen';

  @override
  String get playerTagNotExists => 'Het ingevoerde speler-ID bestaat niet.';

  @override
  String accountAlreadyLinked(Object tag) {
    return 'Het speler-ID is al aan iemand gekoppeld.';
  }

  @override
  String get enterApiToken => 'Voer je account API-token in om te bevestigen dat deze van jou is. Je vindt deze in Clash of Clans Instellingen > Meer instellingen > API Token.';

  @override
  String get wrongApiToken => 'De ingevoerde API-token is onjuist';

  @override
  String get accountAlreadyLinkedToYou => 'Het speler-ID is al aan jou gekoppeld.';

  @override
  String get apiToken => 'Account API Token';

  @override
  String get failedToAddTryAgain => 'Link toevoegen mislukt. Probeer het later opnieuw.';

  @override
  String get fillAllFields => 'Please fill all fields.';

  @override
  String get failedToDeleteTryAgain => 'Link verwijderen mislukt. Probeer het later opnieuw.';

  @override
  String get enterPlayerTagWarning => 'Je moet een spelertag invoeren en op de \"+\" klikken om door te gaan.';

  @override
  String get failedToLoadAccountData => 'Failed to load accounts data.';

  @override
  String get loadAccountData => 'Load accounts data';

  @override
  String get search => 'Zoeken';

  @override
  String get warning => 'Waarschuwing';

  @override
  String get exitAppToOpenClash => 'Je staat op het punt de app te verlaten om Clash of Clans te openen.';

  @override
  String get confirmLogout => 'Weet je zeker dat je wilt uitloggen?';

  @override
  String get tagOrNamePlayer => 'Spelers tag of naam';

  @override
  String get searchPlayer => 'Zoek speler';

  @override
  String get nameOrTagPlayer => 'Spelers-ID of naam';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Je clan is \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(String ratio, String donations, String received) {
    return 'Je donatieverhouding is $ratio. Je hebt $donations troepen gedoneerd en $received troepen ontvangen.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Je oorlogsvoorkeur is \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'Je hebt $stars oorlogssterren.';
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
  String get dashboard => 'Dashboard';

  @override
  String get homeBase => 'Thuisbasis';

  @override
  String get th => 'SH';

  @override
  String get builderBase => 'Bouwerbasis';

  @override
  String get bh => 'BZ';

  @override
  String get clanCapital => 'Clan Hoofdstad';

  @override
  String get leader => 'Leider';

  @override
  String get coLeader => 'Co-Leider';

  @override
  String get elder => 'Oudste';

  @override
  String get member => 'Lid';

  @override
  String get ready => 'Aangemeld';

  @override
  String get unready => 'Afgemeld';

  @override
  String level(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get heroes => 'Helden';

  @override
  String get equipment => 'Uitrusting';

  @override
  String get troops => 'Troepen';

  @override
  String get superTroops => 'Supertroepen';

  @override
  String get activeSuperTroops => 'Actieve Super Troepen';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get pets => 'Huisdieren';

  @override
  String get siegeMachines => 'Belegeringsmachines';

  @override
  String get spells => 'Spreuken';

  @override
  String get achievements => 'Prestaties';

  @override
  String get byDay => 'Per dag';

  @override
  String get bySeason => 'Per Seizoen';

  @override
  String dayIndex(int index) {
    return 'Dag $index';
  }

  @override
  String indexDays(int index) {
    return '$index dagen';
  }

  @override
  String get bestTrophies => 'Beste Trofeeën';

  @override
  String get mostAttacks => 'Meeste Aanvallen';

  @override
  String get lastSeason => 'Laatste Seizoen';

  @override
  String get bestRank => 'Beste Wereldwijde Positie';

  @override
  String daysLeft(int days) {
    return '$days resterende dagen';
  }

  @override
  String get date => 'Datum';

  @override
  String get stats => 'Stats';

  @override
  String get details => 'Details';

  @override
  String get seasonStats => 'Seizoen Stats';

  @override
  String get charts => 'Grafieken';

  @override
  String get history => 'Geschiedenis';

  @override
  String get legendLeague => 'Legendarische Divisie';

  @override
  String get notInLegendLeague => 'Niet in de Legendarische Divisie';

  @override
  String get noLegendData => 'Geen legendarische gegevens gevonden voor vandaag';

  @override
  String legendStartDescription(String trophies) {
    return 'Je bent de dag begonnen met $trophies trofeeën.';
  }

  @override
  String legendNoRankLocalDescription(String country, int trophies) {
    return 'Je bent momenteel niet gerangschikt ($country) met $trophies trofeeën.';
  }

  @override
  String legendRankLocalDescription(Object country, Object rank, Object trophies) {
    return 'Je staat momenteel op rang $rank ($country) met $trophies trofeeën.';
  }

  @override
  String legendGainDescription(int trophies) {
    return 'Je hebt voorlopig $trophies trofeeën verdiend.';
  }

  @override
  String legendLossDescription(int trophies) {
    return 'Je hebt voorlopig $trophies trofeeën verloren.';
  }

  @override
  String legendNoGlobalRankDescription(int trophies) {
    return 'Je staat op dit moment niet wereldwijd gerangschikt met $trophies trofeeën.';
  }

  @override
  String legendGlobalRankDescription(int rank, Object trophies) {
    return 'Je staat momenteel op rang $rank wereldwijd.';
  }

  @override
  String get noRank => 'Geen ranking';

  @override
  String get started => 'Gestart';

  @override
  String get ended => 'Afgelopen';

  @override
  String get average => 'Gemiddelde';

  @override
  String get remaining => 'Resterend';

  @override
  String get legendsTitle => 'Onjuiste gegevens?';

  @override
  String get legendsExplanation_intro => 'Vanwege beperkingen in de Clash of Clans API is onze data mogelijk niet altijd accuraat. Dit zijn de reden:\n';

  @override
  String get legendsExplanation_api_delay_title => '1. API Vertraging: ';

  @override
  String get legendsExplanation_api_delay_body => 'De API kan tot 5 minuten duren om bij te werken, wat een vertraging veroorzaakt bij het weergeven van real-time trofee wijzigingen.\n';

  @override
  String get legendsExplanation_concurrent_changes_title => '2. Gelijktijdige Veranderingen:\n';

  @override
  String get legendsExplanation_multiple_attacks_defenses_title => '- Meerdere Aanvallen/Verdedigingen: ';

  @override
  String get legendsExplanation_multiple_attacks_defenses_body => 'Als meerdere aanvallen of verdedigingen kort na elkaar plaatsvinden, kan de API gecombineerde resultaten weergeven (bijv. +68 of -68).\n';

  @override
  String get legendsExplanation_simultaneous_attack_defense_title => '- Gelijktijdige Aanval en Verdediging: ';

  @override
  String get legendsExplanation_simultaneous_attack_defense_body => 'Als er op hetzelfde moment een aanval en verdediging plaatsvindt, kan je een gemengd resultaat zien (bijv. +4).\n';

  @override
  String get legendsExplanation_net_gain_loss_title => '3. Netto winst/verlies: ';

  @override
  String get legendsExplanation_net_gain_loss_body => 'Ondanks de timing problemen, is het nettoresultaat van de gehele dag wel correct. ';

  @override
  String get legendsExplanation_conclusion => 'Deze beperkingen zijn gebruikelijk bij alle tools die de Clash of Clans API gebruiken. Helaas kunnen we dat niet oplossen omdat het in handen van Supercell ligt. We doen ons best om deze limieten te compenseren en resultaten te bieden die zo dicht mogelijk bij de werkelijkheid liggen. Bedankt voor je begrip!';

  @override
  String get toDoList => 'Takenlijst';

  @override
  String lastActive(String date) {
    return 'Laatst actief: $date';
  }

  @override
  String get playerNotTracked => 'Deze speler wordt niet gevolgd. De gegevens zijn mogelijk onnauwkeurig.';

  @override
  String numberAccounts(int number) {
    return '$number accounts';
  }

  @override
  String numberActiveAccounts(int number) {
    return '$number actieve accounts';
  }

  @override
  String numberInactiveAccounts(int number) {
    return '$number inactieve accounts';
  }

  @override
  String get activeAccounts => 'Actieve accounts';

  @override
  String get inactiveAccounts => 'Inactieve accounts';

  @override
  String get noInactiveAccounts => 'Geen inactieve accounts.';

  @override
  String get noActiveAccounts => 'Geen actieve accounts.';

  @override
  String get todoExplanation_title => 'Taakberekening';

  @override
  String get todoExplanation_intro => 'Het voltooiingspercentage van de taak wordt berekend op basis van de volgende activiteiten met bepaalde gewichten:';

  @override
  String get todoExplanation_legends_title => 'Legendarische Divisie:';

  @override
  String get todoExplanation_legends => 'Gewicht van 8 punten per account, 1 aanval = 1 punt.';

  @override
  String get todoExplanation_raids_title => 'Rooftochten:';

  @override
  String get todoExplanation_raids => 'Gewicht van 5 punten per account (of 6 als de laatste aanval is ontgrendeld), 1 aanval = 1 punt.';

  @override
  String get todoExplanation_clanWars_title => 'Clan Oorlogen:';

  @override
  String get todoExplanation_clanWars => 'Gewicht van 2 punten per account, 1 aanval = 1 punt.';

  @override
  String get todoExplanation_cwl_title => 'Clanoorlogsdivisie:';

  @override
  String get todoExplanation_cwl => 'Gewicht van 1 punt per account, 1 aanval = 1 punt. CWL (clanoorlogdivisie) kan niet worden gevolgd als de speler niet in zijn divisie clan zit.';

  @override
  String get todoExplanation_passAndGames_title => 'Seizoenspas & Clan Games:';

  @override
  String get todoExplanation_passAndGames => 'Gewicht van 2 punten per account. De verhouding is gebaseerd op het aantal resterende dagen (1 maand voor de pas en 6 dagen voor de spellen). Groen = op schema om de pas of spellen te voltooien, rood = achter op schema.';

  @override
  String get todoExplanation_conclusion => 'Het uiteindelijke percentage wordt berekend door het totaal aantal voltooide acties tijdens lopende evenementen te delen door het totaal aantal vereiste acties. Accounts die langer dan 14 dagen inactief zijn worden uitgesloten van de berekening.';

  @override
  String get worst => 'Slechtste';

  @override
  String get best => 'Beste';

  @override
  String get total => 'Totaal';

  @override
  String get heroesEquipments => 'Heldenuitrusting';

  @override
  String daysAgo(int days) {
    return '$days dagen geleden';
  }

  @override
  String dayAgo(int day) {
    return '$day dag geleden';
  }

  @override
  String hourAgo(int hour) {
    return '$hour uur geleden';
  }

  @override
  String hoursAgo(int hours, Object Hours) {
    return '$hours uren geleden';
  }

  @override
  String minuteAgo(int minute) {
    return '$minute minuut geleden';
  }

  @override
  String minutesAgo(int minutes) {
    return '$minutes minuten geleden';
  }

  @override
  String secondAgo(int seconds) {
    return '${seconds}s geleden';
  }

  @override
  String get justNow => 'Zojuist';

  @override
  String get trophiesByMonth => 'Trofeeën per maand';

  @override
  String get trophiesBySeason => 'Trofeeën per seizoen';

  @override
  String get eosTrophies => 'Einde van Seizoen Trofeeën';

  @override
  String get eosDetails => 'End Of Season Details';

  @override
  String get searchClan => 'Zoek clan';

  @override
  String get nameOrTagClan => 'Naam of label van de clan';

  @override
  String get noResult => 'Geen resultaat.';

  @override
  String get filters => 'Filters';

  @override
  String get whatever => 'Wat dan ook';

  @override
  String get any => 'Alle';

  @override
  String get notSet => 'Niet ingesteld';

  @override
  String get warFrequency => 'Oorlog frequentie';

  @override
  String get minimumMembers => 'Minimum aantal leden';

  @override
  String get maximumMembers => 'Maximaal aantal leden';

  @override
  String get location => 'Locatie';

  @override
  String get minimumClanPoints => 'Minimale clan punten';

  @override
  String get minimumClanLevel => 'Minimaal clan niveau';

  @override
  String get noClan => 'Geen clan';

  @override
  String get joinClanToUnlockNewFeatures => 'Sluit je aan bij een clan om nieuwe functies te ontgrendelen.';

  @override
  String get apply => 'Toepassen';

  @override
  String get opened => 'Geopend';

  @override
  String get inviteOnly => 'Op uitnodiging';

  @override
  String get cancel => 'Annuleren';

  @override
  String get clan => 'Clan';

  @override
  String get clans => 'Clans';

  @override
  String get members => 'Leden';

  @override
  String get role => 'Rol';

  @override
  String get expLevel => 'Ervaringsniveau';

  @override
  String get townHallLevel => 'SH level';

  @override
  String thLevel(int level) {
    return 'SH$level';
  }

  @override
  String bhLevel(int level) {
    return 'BH$level';
  }

  @override
  String townHallLevelLevel(int level) {
    return 'Stadhuis $level';
  }

  @override
  String get byNumberOfWars => 'Op aantal oorlogen';

  @override
  String get ok => 'Oké';

  @override
  String get byDateRange => 'Op datumbereik';

  @override
  String get selectSeason => 'Selecteer een seizoen';

  @override
  String get year => 'Jaar';

  @override
  String get month => 'Maand';

  @override
  String get allTownHalls => 'Alle stadhuizen';

  @override
  String seasonDate(String date) {
    return '$date seizoen';
  }

  @override
  String lastXwars(int number) {
    return 'Laatste $number oorlogen';
  }

  @override
  String get friendly => 'Vriendelijk';

  @override
  String get cwl => 'CWL';

  @override
  String get random => 'Willekeurig';

  @override
  String get selectMembersThLevel => 'Leden SH level';

  @override
  String get selectOpponentsThLevel => 'Tegenstanders SH level';

  @override
  String get equalThLevel => 'Hetzelfde SH';

  @override
  String get builderBaseTrophies => 'BB Trofeeën';

  @override
  String get donations => 'Donaties';

  @override
  String get donationsReceived => 'Donaties ontvangen';

  @override
  String get donationsRatio => 'Donatie Verhouding';

  @override
  String get trophies => 'Trofeeën';

  @override
  String get always => 'Altijd';

  @override
  String get never => 'Nooit';

  @override
  String get unknown => 'Onbekend';

  @override
  String get oncePerWeek => '1/week';

  @override
  String get twicePerWeek => '2/week';

  @override
  String get rarely => 'Zelden';

  @override
  String get warLeague => 'Oorlog/Divisies';

  @override
  String get war => 'Oorlog';

  @override
  String get league => 'Competitie';

  @override
  String get wars => 'Oorlogen';

  @override
  String get ongoingWar => 'Lopende oorlog';

  @override
  String get ongoingCwl => 'Lopende CWL';

  @override
  String get cantOpenLink => 'We kunnen deze link niet openen.';

  @override
  String get notInWar => 'Niet in oorlog';

  @override
  String get warHistory => 'Oorlogsgeschiedenis';

  @override
  String warHistoryWinsDescription(int wins, String percent) {
    return 'Je clan heeft $wins oorlogen gewonnen ($percent%) van de laatste 50 oorlogen.';
  }

  @override
  String warHistoryLossesDescription(int losses, String percent) {
    return 'Je clan heeft $losses oorlogen verloren ($percent%) in de laatste 50 oorlogen.';
  }

  @override
  String warHistoryDrawsDescription(int draws, String percent) {
    return 'Je clan had $draws gelijkspel ($percent%) in de laatste 50 oorlogen.';
  }

  @override
  String warHistoryAverageMembersDescription(int members) {
    return 'Je clan heeft gemiddeld $members leden die deelnemen aan de laatste 50 oorlogen.';
  }

  @override
  String warHistoryAverageWarStarsDescription(double stars, String percent) {
    return 'Je clan heeft gemiddeld $stars sterren aan het einde van de laatste 50 oorlogen. Dit vertegenwoordigt $percent van de totale sterren.';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return 'Je clan heeft gemiddeld $percent vernietigingspercentage aan het einde van de laatste 50 oorlogen.';
  }

  @override
  String warHistoryAverageClanStarsPerMember(Object stars) {
    return 'Je clan heeft gemiddeld $stars sterren per lid in de laatste 50 oorlogen.';
  }

  @override
  String warHistoryAverageMembers(int members) {
    return '~$members leden per oorlog';
  }

  @override
  String get averageStars => 'Gemiddelde sterren';

  @override
  String get averageDestruction => 'Gemiddelde vernietiging';

  @override
  String get noStars => '0 ster';

  @override
  String get oneStar => '1 ster';

  @override
  String get twoStars => '2 sterren';

  @override
  String get threeStars => '3 sterren';

  @override
  String get warParticipation => 'Oorlogsdeelname';

  @override
  String get toggleTownHallVisibility => 'Verberg/Toon statistieken van voormalige SH-levels';

  @override
  String get warLog => 'Oorlogs logboek';

  @override
  String get publicWarLog => 'Openbaar Oorlogslogboek';

  @override
  String get privateWarLog => 'Privé Oorlogslogboek';

  @override
  String startsIn(String time) {
    return 'Begint over $time';
  }

  @override
  String startsAt(String time) {
    return 'Begint om $time';
  }

  @override
  String endsIn(String time) {
    return 'Eindigt in $time';
  }

  @override
  String endsAt(String time) {
    return 'Eindigt om $time';
  }

  @override
  String get joinLeaveLogs => 'Deelnemen/Verlaten Logboeken';

  @override
  String get join => 'Deelnemen';

  @override
  String get leave => 'Verlaten';

  @override
  String get reset => 'Reset';

  @override
  String leaveNumberDescription(int number, String date) {
    return '$number speler(s) hebben de clan verlaten tijdens het huidige seizoen ($date).';
  }

  @override
  String joinNumberDescription(int number, String date) {
    return '$number speler(s) zijn lid geworden van de clan tijdens het huidige seizoen ($date).';
  }

  @override
  String joinLeaveDifferenceUpDescription(int number, String date) {
    return 'Je clan heeft $number nieuwe leden gekregen tijdens dit seizoen ($date).';
  }

  @override
  String joinLeaveDifferenceDownDescription(int number, String date) {
    return 'Je clan heeft dit seizoen $number leden verloren ($date).';
  }

  @override
  String joinLeaveDifferenceEqualDescription(String date) {
    return 'Je clan heeft hetzelfde aantal leden als aan het begin van het seizoen ($date).';
  }

  @override
  String leftOnAt(String date, String time) {
    return 'Vertrokken op $date om $time.';
  }

  @override
  String joinedOnAt(String date, String time) {
    return 'Lid geworden op $date om $time.';
  }

  @override
  String get statistics => 'Statistieken';

  @override
  String get stars => 'Sterren';

  @override
  String get numberOfStars => 'Aantal sterren';

  @override
  String get destructionRate => 'Totale vernietiging';

  @override
  String get events => 'Events';

  @override
  String get team => 'Teams';

  @override
  String get myTeam => 'Mijn team';

  @override
  String get enemiesTeam => 'Vijanden';

  @override
  String get defense => 'Verdediging';

  @override
  String get defenses => 'Verdedigingen';

  @override
  String get attack => 'Aanval';

  @override
  String get attacks => 'Aanvallen';

  @override
  String get victory => 'Overwinning';

  @override
  String get defeat => 'Verslagen';

  @override
  String get draw => 'Gelijkspel';

  @override
  String get perfectWar => 'Perfecte oorlog';

  @override
  String get newest => 'Nieuwste';

  @override
  String get oldest => 'Oudste';

  @override
  String get warEnded => 'Oorlog afgelopen';

  @override
  String get preparation => 'Voorbereiding';

  @override
  String isNotInWar(String clan) {
    return '$clan is niet in oorlog.';
  }

  @override
  String warLogIsClosed(String clan) {
    return 'Het oorlogs logboek van $clan is gesloten.';
  }

  @override
  String get askForWar => 'Neem contact op met de leider of een co-leider om een oorlog te starten.';

  @override
  String get askForWarLogOpening => 'Neem contact op met de leider of een co-leider om het oorlogs logsboek te openen.';

  @override
  String get warLogClosed => 'Oorlogs logboek gesloten.';

  @override
  String get rounds => 'Rondes';

  @override
  String get noDataAvailableForThisWar => 'Geen gegevens beschikbaar voor deze oorlog';

  @override
  String get stateOfTheWar => 'Staat van de oorlog';

  @override
  String starsNeededToTakeTheLead(String clan, int star, int star2, String percent, Object stars2) {
    return '$clan heeft nog $star meer ster(ren) nodig of $stars2 ster(ren) en $percent% om de leiding te nemen.';
  }

  @override
  String starsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan heeft nog $percent% of 1 meer ster nodig om de leiding te nemen';
  }

  @override
  String get clanDraw => 'De twee clans staan gelijk';

  @override
  String get fastCalculator => 'Snelle rekenmachine';

  @override
  String fastCalculatorAnswer(String percentNeedeed, String result, Object percentNeeded) {
    return 'Om een vernietigingspercentage van $percentNeeded% te bereiken, heb je in totaal $result% nodig.';
  }

  @override
  String get teamSize => 'Teamgrootte';

  @override
  String get neededOverall => '% Nodig in totaal';

  @override
  String get calculate => 'Berekenen';

  @override
  String get warStats => 'Oorlogstatistieken';

  @override
  String get membersStats => 'Ledenstatistieken';

  @override
  String get clanWarLeague => 'Clanoorlogsdivisie';

  @override
  String cwlRank(int rank) {
    return 'Je clan staat momenteel op rang $rank.';
  }

  @override
  String cwlStars(int stars) {
    return 'Je clan heeft een totaal van $stars sterren.';
  }

  @override
  String cwlMissingStarsFromNext(int stars) {
    return 'Je clan mist $stars sterren om de volgende clans in te halen.';
  }

  @override
  String cwlMissingStarsFromFirst(int stars) {
    return 'Je clan mist $stars sterren om de eerste clan in te halen.';
  }

  @override
  String cwlDestructionPercentage(String percent) {
    return 'Je clan heeft een totaal vernietigingspercentage van $percent%.';
  }

  @override
  String cwlCurrentRound(int round) {
    return 'Het is momenteel ronde $round.';
  }

  @override
  String get noAccountLinkedToYourProfileFound => 'Geen gekoppeld account aan je profiel gevonden';

  @override
  String get management => 'Beheren';

  @override
  String get comingSoon => 'Binnenkort beschikbaar!';

  @override
  String get connectionError => 'Er is een fout opgetreden. Controleer je internetverbinding en probeer het opnieuw.';

  @override
  String get connectionErrorRelaunch => 'Er is een fout opgetreden. Controleer je internetverbinding en start de app opnieuw op.';

  @override
  String updatedAt(String time) {
    return 'Bijgewerkt op $time';
  }

  @override
  String get tools => 'Hulpmiddelen';

  @override
  String get community => 'Gemeenschap';

  @override
  String get lastRaids => 'Laatste raids';

  @override
  String get ongoingRaids => 'Lopende rooftocht';

  @override
  String get districtsDestroyed => 'Districten vernietigd';

  @override
  String get raidsCompleted => 'Rooftochten voltooid';
}
