// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Afrikaans (`af`).
class AppLocalizationsAf extends AppLocalizations {
  AppLocalizationsAf([String locale = 'af']) : super(locale);

  @override
  String get appDescription =>
      'Jou uiteindelike Clash of Clans metgesel vir die navolg van statistieke, bestuur van klans, en analisering van prestasie.';

  @override
  String get generalLoading => 'Laai...';

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
  String get generalRetry => 'Probeer weer';

  @override
  String get generalTryAgain => 'Probeer weer';

  @override
  String get generalCancel => 'Kanselleer';

  @override
  String get generalOk => 'OK';

  @override
  String get generalApply => 'Pas toe';

  @override
  String get generalConfirm => 'Bevestig';

  @override
  String get generalManage => 'Bestuur';

  @override
  String get generalSettings => 'Instellings';

  @override
  String get generalCopiedToClipboard => 'Gekopieer na knipbord';

  @override
  String get generalComingSoon => 'Kom binnekort!';

  @override
  String generalLastRefresh(String time) {
    return 'Last refresh: $time';
  }

  @override
  String generalRefreshFailed(String error) {
    return 'Refresh failed: $error';
  }

  @override
  String get generalAll => 'Alles';

  @override
  String get generalTotal => 'Totaal';

  @override
  String get generalBest => 'Beste';

  @override
  String get generalWorst => 'Slegste';

  @override
  String get generalAverage => 'Gemiddeld';

  @override
  String get generalRemaining => 'Oorblywend';

  @override
  String get generalActive => 'Aktief';

  @override
  String get generalInactive => 'Onaktief';

  @override
  String get generalStarted => 'Begin';

  @override
  String get generalEnded => 'Geëindig';

  @override
  String get generalRole => 'Rol';

  @override
  String get generalStats => 'Statistieke';

  @override
  String get generalFullStats => 'Volledige Statistieke';

  @override
  String get generalDetails => 'Besonderhede';

  @override
  String get generalHistory => 'Geskiedenis';

  @override
  String get generalFilters => 'Filters';

  @override
  String get generalNotSet => 'Nie gestel nie';

  @override
  String get generalWarning => 'Waarskuwing';

  @override
  String get generalNoDataAvailable => 'Geen data beskikbaar nie.';

  @override
  String get authSignUp => 'Registreer';

  @override
  String get authLogin => 'Meld aan';

  @override
  String get authLogout => 'Meld af';

  @override
  String get authCreateAccount => 'Skep Rekening';

  @override
  String get authJoinClashKing => 'Sluit aan by ClashKing';

  @override
  String get authCreateClashKingAccount => 'Skep ClashKing Rekening';

  @override
  String get authCreateAccountToGetStarted => 'Skep jou rekening om te begin';

  @override
  String get authAlreadyHaveAccount => 'Het jy reeds \'n rekening? Meld aan';

  @override
  String get authConfirmLogout => 'Is jy seker jy wil afmeld?';

  @override
  String get authDiscordTitle => 'Discord';

  @override
  String get authDiscordSignIn => 'Meld aan met Discord';

  @override
  String get authDiscordContinue => 'Gaan voort met Discord';

  @override
  String get authDiscordDescription =>
      'Sinchroniseer jou data met ClashKing Bot en ontsluit die volle potensiaal van ClashKing!';

  @override
  String get authEmailTitle => 'E-pos';

  @override
  String get authEmailDescription =>
      'Gebruik e-pos as jy nie Discord kan bereik nie of slegs app-funksies verkies';

  @override
  String get authEmailRequired => 'Voer asseblief jou e-pos in';

  @override
  String get authEmailInvalid => 'Voer asseblief \'n geldige e-pos in';

  @override
  String get authPasswordLabel => 'Wagwoord';

  @override
  String get authPasswordConfirm => 'Bevestig Wagwoord';

  @override
  String get authPasswordRequired => 'Voer asseblief jou wagwoord in';

  @override
  String get authPasswordConfirmRequired => 'Bevestig asseblief jou wagwoord';

  @override
  String get authPasswordMismatch => 'Wagwoorde stem nie ooreen nie';

  @override
  String get authPasswordTooShort => 'Wagwoord moet minstens 8 karakters wees';

  @override
  String get authPasswordRequirements =>
      'Wagwoord moet bevat: hoofletter, kleinletter, syfer, en spesiale karakter';

  @override
  String get authPasswordForgot => 'Wagwoord vergeet?';

  @override
  String get authUsernameLabel => 'Gebruikersnaam';

  @override
  String get authUsernameRequired => 'Voer asseblief \'n gebruikersnaam in';

  @override
  String get authUsernameTooShort =>
      'Gebruikersnaam moet minstens 3 karakters wees';

  @override
  String get authErrorConnection =>
      '\'n Fout het voorgekom. Gaan jou internetverbinding na en probeer weer.';

  @override
  String get authErrorConnectionRelaunch =>
      '\'n Fout het voorgekom. Gaan jou internetverbinding na en herlaai die app.';

  @override
  String get authAccountManagement => 'Rekeningbestuur';

  @override
  String get authAccountConnected => 'Gekoppelde Rekeninge';

  @override
  String get authAccountConnectedStatus => 'Gekoppel';

  @override
  String get authAccountNotConnected => 'Nie gekoppel nie';

  @override
  String get authAccountEmailAndPassword => 'E-pos & Wagwoord';

  @override
  String get authAccountSecured =>
      'Jou rekening is beveilig met veelvuldige verifikasie metodes';

  @override
  String get authAccountLinkEmail => 'Koppel E-pos Rekening';

  @override
  String get authAccountAddEmailAuth =>
      'Voeg e-pos & wagwoord verifikasie by jou rekening vir addisionele sekuriteit.';

  @override
  String get authAccountEmailLinkedSuccess =>
      'E-pos rekening suksesvol gekoppel!';

  @override
  String get helpTitle => 'Benodig hulp?';

  @override
  String get helpJoinDiscord => 'Sluit aan by Discord';

  @override
  String get helpEmailUs => 'Stuur vir ons \'n E-pos';

  @override
  String get accountsWelcome => 'Welkom!';

  @override
  String get accountsWelcomeMessage =>
      'Voeg asseblief een of meer Clash of Clans rekeninge by jou profiel. Jy kan later rekeninge byvoeg of verwyder.';

  @override
  String get accountsManageTitle => 'Bestuur jou rekeninge';

  @override
  String get accountsNoneFound =>
      'Geen rekening gekoppel aan jou profiel gevind nie';

  @override
  String get accountsPlayerTag => 'Speler Etiket (#ABC123)';

  @override
  String get accountsEnterPlayerTag => 'Voer \'n speler etiket in';

  @override
  String get accountsAdd => 'Voeg rekening by';

  @override
  String get accountsDelete => 'Skrap rekening';

  @override
  String get accountsApiToken => 'Rekening API Sleutel';

  @override
  String get accountsEnterApiToken =>
      'Voer asseblief die rekening API sleutel in om te bevestig dit is joune. Jy kan dit vind in Clash of Clans Instellings > Meer Instellings > API Sleutel.';

  @override
  String get accountsFillAllFields => 'Vul asseblief alle velde in.';

  @override
  String get accountsErrorTagNotExists =>
      'Die speler etiket wat ingevoer is bestaan nie.';

  @override
  String accountsErrorAlreadyLinked(Object tag) {
    return 'Die speler etiket is reeds aan iemand gekoppel.';
  }

  @override
  String get accountsErrorAlreadyLinkedToYou =>
      'Die speler etiket is reeds aan jou gekoppel.';

  @override
  String get accountsErrorWrongApiToken =>
      'Die API sleutel wat ingevoer is is verkeerd';

  @override
  String get accountsErrorFailedToAdd =>
      'Kon nie die rekening byvoeg nie. Probeer asseblief later weer.';

  @override
  String get accountsErrorFailedToDelete =>
      'Kon nie die skakel skrap nie. Probeer asseblief later weer.';

  @override
  String get accountsErrorFailedToUpdateOrder =>
      'Kon nie die volgorde van rekeninge opdateer nie.';

  @override
  String get errorTitle =>
      'Oeps! Ons bedieners het dalk \'n vuurbal in die gesig gekry! Ons toor \'n genesing betowering... Probeer oor \'n rukkie weer.';

  @override
  String get errorSubtitle =>
      'As die probleem voortduur, gaan kyk op ons Discord Bediener om te sien of ons daarvan bewus is.';

  @override
  String get errorLoadingVersion => 'Fout met laai van weergawe';

  @override
  String get errorCannotOpenLink => 'Ons kan nie hierdie skakel oopmaak nie.';

  @override
  String get errorExitAppToOpenClash =>
      'Jy gaan die app verlaat om Clash of Clans oop te maak.';

  @override
  String get playerSearchTitle => 'Soek speler';

  @override
  String get playerSearchPlaceholder => 'Speler se naam of etiket';

  @override
  String playerLastActive(String date) {
    return 'Laas aktief: $date';
  }

  @override
  String get playerNotTracked =>
      'Hierdie speler word nie nagevolg nie. Data mag onakkuraat wees.';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Jou klan is \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(
      String ratio, String donations, String received) {
    return 'Jou skenkingsverhouding is $ratio. Jy het $donations troepe geskenk en $received troepe ontvang.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Jou oorlogsvoorkeur is \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'Jy het $stars oorlogsterre.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'Jy het $trophies trofees. Jy is tans in $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Jou Stadsaal vlak is $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Jou Bouersaal vlak is $level en jy het $trophies trofees.';
  }

  @override
  String get gameBaseHome => 'Tuisbasis';

  @override
  String get gameBaseBuilder => 'Bouerbasis';

  @override
  String get gameClanCapital => 'Klanhoofstad';

  @override
  String get gameTownHall => 'TH';

  @override
  String get gameTownHallLevel => 'SS Vlak';

  @override
  String gameTownHallLevelNumber(int level) {
    return 'Stadsaal $level';
  }

  @override
  String gameTHLevel(int level) {
    return 'TH$level';
  }

  @override
  String get gameExpLevel => 'Ervaringsvlak';

  @override
  String get gameTrophies => 'Trofees';

  @override
  String get gameBuilderBaseTrophies => 'BB Trofees';

  @override
  String get gameDonations => 'Skenkings';

  @override
  String get gameDonationsReceived => 'Skenkings Ontvang';

  @override
  String get gameDonationsRatio => 'Skenkingsverhouding';

  @override
  String gameLevel(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get gameHeroes => 'Helde';

  @override
  String get gameEquipment => 'Toerusting';

  @override
  String get gameHeroesEquipments => 'Held toerusting';

  @override
  String get gameTroops => 'Troepe';

  @override
  String get gameActiveSuperTroops => 'Aktiewe Super Troepe';

  @override
  String get gamePets => 'Troeteldiere';

  @override
  String get gameSiegeMachines => 'Beleëringsmasjiene';

  @override
  String get gameSpells => 'Towerspreuke';

  @override
  String get gameAchievements => 'Prestasies';

  @override
  String get gameClanGames => 'Klanspele';

  @override
  String get gameSeasonPass => 'Seisoenkaartjie';

  @override
  String get gameCreatorCode => 'Creator Code: ClashKing';

  @override
  String get clanTitle => 'Klan';

  @override
  String get clanSearchTitle => 'Soek klan';

  @override
  String get clanSearchPlaceholder => 'Klan se naam';

  @override
  String get clanNone => 'Geen klan';

  @override
  String get clanJoinToUnlock =>
      'Sluit aan by \'n klan om nuwe funksies te ontsluit.';

  @override
  String get clanMembers => 'Lede';

  @override
  String get clanWarFrequency => 'Oorlogsfrekwensie';

  @override
  String get clanMinimumMembers => 'Minimum lede';

  @override
  String get clanMaximumMembers => 'Maksimum lede';

  @override
  String get clanLocation => 'Ligging';

  @override
  String get clanMinimumPoints => 'Minimum klanpunte';

  @override
  String get clanMinimumLevel => 'Minimum klanvlak';

  @override
  String get clanInviteOnly => 'Slegs op uitnodiging';

  @override
  String get clanOpened => 'Oop';

  @override
  String get clanClosed => 'Gesluit';

  @override
  String get clanRoleLeader => 'Leier';

  @override
  String get clanRoleCoLeader => 'Mede-leier';

  @override
  String get clanRoleElder => 'Ouderling';

  @override
  String get clanRoleMember => 'Lid';

  @override
  String get clanWarFrequencyAlways => 'Altyd';

  @override
  String get clanWarFrequencyNever => 'Nooit';

  @override
  String get clanWarFrequencyUnknown => 'Onbekend';

  @override
  String get clanWarFrequencyOncePerWeek => '1/week';

  @override
  String get clanWarFrequencyMoreThanOncePerWeek => 'More than 1/week';

  @override
  String get clanWarFrequencyRarely => 'Selde';

  @override
  String get timeHourIndicator => 'h';

  @override
  String timeDaysAgo(int days) {
    return '$days dae gelede';
  }

  @override
  String timeDayAgo(int day) {
    return '$day dag gelede';
  }

  @override
  String timeHourAgo(int hour) {
    return '$hour uur gelede';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours ure gelede';
  }

  @override
  String timeMinuteAgo(int minute) {
    return '$minute minuut gelede';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes minute gelede';
  }

  @override
  String get timeJustNow => 'Nou net';

  @override
  String get timeEndedJustNow => 'Geëindig nou net';

  @override
  String timeEndedMinutesAgo(int minutes) {
    return 'Geëindig $minutes minute gelede';
  }

  @override
  String timeEndedHoursAgo(int hours) {
    return 'Geëindig $hours ure gelede';
  }

  @override
  String timeEndedDaysAgo(int days) {
    return 'Geëindig $days dae gelede';
  }

  @override
  String timeStartsIn(String time) {
    return 'Begin oor $time';
  }

  @override
  String timeStartsAt(String time) {
    return 'Begin om $time';
  }

  @override
  String timeEndsIn(String time) {
    return 'Eindig oor $time';
  }

  @override
  String timeEndsAt(String time) {
    return 'Eindig om $time';
  }

  @override
  String get legendsTitle => 'Onakkurate data?';

  @override
  String get legendsNotInLeague => 'Nie in Legende Liga nie';

  @override
  String get legendsNoDataToday =>
      'Jy is nie in Legende Liga nie, maar vorige seisoene is beskikbaar.';

  @override
  String legendsStartDescription(String trophies) {
    return 'Jy het die dag begin met $trophies trofees.';
  }

  @override
  String legendsNoRankLocalDescription(String country, int trophies) {
    return 'Jy is tans nie gerangskik nie ($country) met $trophies trofees.';
  }

  @override
  String legendsRankLocalDescription(int rank, String country, int trophies) {
    return 'Jy is tans gerangskik $rank ($country) met $trophies trofees.';
  }

  @override
  String legendsGainDescription(int trophies) {
    return 'Jy het $trophies trofees vir nou gewen.';
  }

  @override
  String legendsLossDescription(int trophies) {
    return 'Jy het $trophies trofees vir nou verloor.';
  }

  @override
  String legendsNoGlobalRankDescription(int trophies) {
    return 'Jy is tans nie wêreldwyd gerangskik nie met $trophies trofees.';
  }

  @override
  String legendsGlobalRankDescription(int rank, int trophies) {
    return 'Jy is tans gerangskik $rank wêreldwyd met $trophies trofees.';
  }

  @override
  String get legendsNoRank => 'Geen rangskikking';

  @override
  String get legendsBestTrophies => 'Beste Trofees';

  @override
  String get legendsMostAttacks => 'Meeste Aanvalle';

  @override
  String get legendsLastSeason => 'Laaste Seisoen';

  @override
  String get legendsBestRank => 'Beste Wêreldrangskikking';

  @override
  String get legendsTrophiesBySeason => 'Trofees per seisoen';

  @override
  String get legendsEosTrophies => 'Einde van Seisoen Trofees';

  @override
  String get legendsEosDetails => 'Einde van Seisoen Besonderhede';

  @override
  String get legendsInaccurateTitle => 'Onakkurate data?';

  @override
  String get legendsInaccurateIntro =>
      'Weens beperkings van die Clash of Clans API, mag ons data nie altyd perfek akkuraat wees nie. Hier is hoekom:\n';

  @override
  String get legendsInaccurateApiDelayTitle => '1. API Vertraging: ';

  @override
  String get legendsInaccurateApiDelayBody =>
      'Die API kan tot 5 minute neem om op te dateer, wat \'n vertraging veroorsaak in die weerspieëling van intydse trofee veranderinge.\n';

  @override
  String get legendsInaccurateConcurrentTitle =>
      '2. Gelyktydige Veranderinge: \n';

  @override
  String get legendsInaccurateMultipleAttacksTitle =>
      '- Veelvuldige Aanvalle/Verdedigings: ';

  @override
  String get legendsInaccurateMultipleAttacksBody =>
      'As veelvuldige aanvalle of verdedigings vinnig op mekaar volg, mag die API gekombineerde resultate toon (bv. +68 of -68).\n';

  @override
  String get legendsInaccurateSimultaneousTitle =>
      '- Gelyktydige Aanval en Verdediging: ';

  @override
  String get legendsInaccurateSimultaneousBody =>
      'As \'n aanval en verdediging op dieselfde tyd plaasvind, kan jy \'n gemengde resultaat sien (bv. +4).\n';

  @override
  String get legendsInaccurateNetGainTitle => '3. Netto Wins/Verlies: ';

  @override
  String get legendsInaccurateNetGainBody =>
      'Ten spyte van tydberekening probleme, is die algehele netto wins of verlies vir die dag akkuraat. ';

  @override
  String get legendsInaccurateConclusion =>
      'Hierdie beperkings is algemeen onder alle instrumente wat die Clash of Clans API gebruik. Ons kan dit ongelukkig nie regmaak nie aangesien dit in Supercell se hande is. Ons doen ons beste om vir hierdie beperkings te kompenseer en resultate so na as moontlik aan die werklikheid te verskaf. Dankie vir jou begrip!';

  @override
  String get statsSeasonStats => 'Seisoen Statistieke';

  @override
  String get statsByDay => 'Per Dag';

  @override
  String get statsBySeason => 'Per Seisoen';

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
  String get statsAllTownHalls => 'Alle Stadsale';

  @override
  String get statsMembers => 'Lede Statistieke';

  @override
  String get todoTitle => 'Om-te-doen lys';

  @override
  String get todoExplanationTitle => 'Taak Berekening';

  @override
  String get todoExplanationIntro =>
      'Die taak voltooiingspersentasie word bereken gebaseer op die volgende aktiwiteite met spesifieke wegings:';

  @override
  String get todoExplanationLegendsTitle => 'Legende Liga:';

  @override
  String get todoExplanationLegends =>
      'Gewig van 8 punte per rekening, 1 aanval = 1 punt.';

  @override
  String get todoExplanationRaidsTitle => 'Invalle:';

  @override
  String get todoExplanationRaids =>
      'Gewig van 5 punte per rekening (of 6 indien die laaste aanval ontsluit is), 1 aanval = 1 punt.';

  @override
  String get todoExplanationClanWarsTitle => 'Klanoorloë:';

  @override
  String get todoExplanationClanWars =>
      'Gewig van 2 punte per rekening, 1 aanval = 1 punt.';

  @override
  String get todoExplanationCwlTitle => 'Klanoorlog Liga:';

  @override
  String get todoExplanationCwl =>
      'Gewig van 1 punt per rekening, 1 aanval = 1 punt. KOL kan nie nagevolg word as die speler nie in hul liga klan is nie.';

  @override
  String get todoExplanationPassAndGamesTitle => 'Seisoenkaartjie & Klanspele:';

  @override
  String get todoExplanationPassAndGames =>
      'Gewig van 2 punte elk per rekening. Die verhouding is gebaseer op die aantal dae oor (1 maand vir die kaartjie en 6 dae vir die spele). Groen = op koers om die kaartjie of spele te voltooi, rooi = agter skedule.';

  @override
  String get todoExplanationConclusion =>
      'Die finale persentasie word bereken deur die totale aksies voltooi gedurende voortdurende gebeure te deel deur die totale vereiste aksies. Rekeninge onaktief vir meer as 14 dae word uitgesluit van die berekening.';

  @override
  String todoAccountsNumber(int number) {
    return '$number rekeninge';
  }

  @override
  String todoAccountsNumberActive(int number) {
    return '$number aktiewe rekeninge';
  }

  @override
  String todoAccountsNumberInactive(int number) {
    return '$number onaktiewe rekeninge';
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
    return 'War log closed.';
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
  String get versionDevice => 'Version & Device';

  @override
  String get betaFeature => 'Beta Feature';

  @override
  String get betaLabel => 'BETA';

  @override
  String get betaDescription =>
      'This feature is currently in beta, it may have some bugs or be incomplete. We are actively working on improvements and welcome your feedback. Please share your ideas and report any issues in our Discord Server to help us make it better.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSelectLanguage => 'Select a language';

  @override
  String get settingsToggleTheme => 'Toggle Theme';

  @override
  String get faqTitle => 'FAQ';

  @override
  String get faqSubtitle => 'Frequently Asked Questions';

  @override
  String get faqIsThisFromSupercell => 'Is this App from Supercell?';

  @override
  String get faqFanContentPolicy =>
      'This material is unofficial and is not endorsed by Supercell. For more information see Supercell\'s Fan Content Policy: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate =>
      'Why is the data sometimes inaccurate or missing?';

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
  String get faqSupportWork => 'How can I support your work?';

  @override
  String get faqSupportWorkAnswer => 'There are several ways to support us:';

  @override
  String get faqUseCodeClashKing => 'Use code \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Support us on Patreon';

  @override
  String get faqShareTheApp => 'Share the app with your friends';

  @override
  String get faqRateTheApp => 'Rate the app in the store';

  @override
  String get faqHelpUsTranslate => 'Help us translate the app';

  @override
  String get faqHowToInviteTheBot =>
      'How can I invite your bot to my Discord Server?';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'You can invite our bot to your server by clicking on the button below. You will need the \"Manage Server\" permission to add the bot.';

  @override
  String get faqInviteTheBot => 'Invite ClashKing Bot';

  @override
  String get faqNeedHelp =>
      'I need help or I would like to make a suggestion. How can I contact you?';

  @override
  String get faqNeedHelpAnswer =>
      'You can join our Discord Server to ask for help or to provide feedback, or you can email us at devs@clashkingbot.com. Please only write in English or French.';

  @override
  String get faqSendEmail => 'Send an email';

  @override
  String get faqJoinDiscord => 'Join our Discord Server';

  @override
  String get faqCannotOpenMailClient =>
      'For some reasons we can\'t open your mail client. We copied the email address for you. You can write an email and paste the address in the recipient field.';

  @override
  String get translationHelpUsTranslate => 'Help us translate';

  @override
  String get translationSuggestFeatures => 'Suggest features';

  @override
  String get translationThankYou => 'Thank you!';

  @override
  String get translationThankYouContent =>
      'A huge thank you to all our amazing translators who help us make this app accessible to more people around the world!';

  @override
  String get translationHelpTranslateContent =>
      'You can help us translate the app on Crowdin. If your language is not available on Crowdin, feel free to request it in our Discord Server. Thank you so much for your help!';

  @override
  String get translationHelpTranslateButton => 'Help Translate on Crowdin';

  @override
  String get translationCurrentTranslators => 'Current Translators';
}
