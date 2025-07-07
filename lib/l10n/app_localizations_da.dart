// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appTitle => 'ClashKing';

  @override
  String get appDescription =>
      'Din ultimative sammenstød mellem klaner følgesvend til sporing statistik, styring klaner og analyse af ydeevne.';

  @override
  String get generalLoading => 'Indlæser...';

  @override
  String get loadingVillages => 'Indlæser dine landsbyer...';

  @override
  String get loadingClanData => 'Henter klan data...';

  @override
  String get loadingWarStats => 'Analyserer krigsstatistik...';

  @override
  String get loadingLegendsData => 'Forbereder sagndata...';

  @override
  String get loadingCapitalRaids => 'Indlæser store razziaer...';

  @override
  String get loadingAlmostReady => 'Næsten klar...';

  @override
  String get accountVerificationTitle => 'Bekræft Konto';

  @override
  String get accountVerificationMessage =>
      'Indtast dit API-token for at bekræfte at du ejer denne konto. Du kan finde det i Sammenstød mellem klaner indstillinger > Flere indstillinger > API Token.';

  @override
  String get accountVerified => 'Konto bekræftet';

  @override
  String get accountNotVerified => 'Konto ikke bekræftet';

  @override
  String get accountVerifyButton => 'Verificér';

  @override
  String get accountVerificationSuccess => 'Konto bekræftet!';

  @override
  String get accountVerificationFailed =>
      'Bekræftelse mislykkedes. Tjek venligst din API-token.';

  @override
  String get generalRetry => 'Forsøg igen';

  @override
  String get generalTryAgain => 'Prøv igen';

  @override
  String get generalCancel => 'Annuller';

  @override
  String get generalOk => 'Ok';

  @override
  String get generalApply => 'Anvend';

  @override
  String get generalConfirm => 'Bekræft';

  @override
  String get generalManage => 'Administrer';

  @override
  String get generalSettings => 'Indstillinger';

  @override
  String get generalCopiedToClipboard => 'Kopieret til udklipsholder';

  @override
  String get generalComingSoon => 'Kommer snart!';

  @override
  String generalLastRefresh(String time) {
    return 'Seneste opdatering: $time';
  }

  @override
  String generalRefreshFailed(String error) {
    return 'Opdatering mislykkedes: $error';
  }

  @override
  String get generalAll => 'Alle';

  @override
  String get generalTotal => 'I Alt';

  @override
  String get generalBest => 'Bedste';

  @override
  String get generalWorst => 'Værst';

  @override
  String get generalAverage => 'Gennemsnit';

  @override
  String get generalRemaining => 'Resterende';

  @override
  String get generalActive => 'Aktiv';

  @override
  String get generalInactive => 'Inaktiv';

  @override
  String get generalStarted => 'Startet';

  @override
  String get generalEnded => 'Afsluttet';

  @override
  String get generalRole => 'Rolle';

  @override
  String get generalStats => 'Statistik';

  @override
  String get generalFullStats => 'Fuld Statistik';

  @override
  String get generalDetails => 'Detaljer';

  @override
  String get generalHistory => 'Historik';

  @override
  String get generalFilters => 'Filtre';

  @override
  String get generalNotSet => 'Ikke angivet';

  @override
  String get generalWarning => 'Advarsel';

  @override
  String get generalNoDataAvailable => 'Ingen tilgængelige data.';

  @override
  String get authSignUp => 'Tilmeld dig';

  @override
  String get authLogin => 'Login';

  @override
  String get authLogout => 'Log ud';

  @override
  String get authCreateAccount => 'Opret Konto';

  @override
  String get authJoinClashKing => 'Deltag I ClashKing';

  @override
  String get authCreateClashKingAccount => 'Opret ClashKing Konto';

  @override
  String get authCreateAccountToGetStarted =>
      'Opret din konto for at komme i gang';

  @override
  String get authAlreadyHaveAccount => 'Har du allerede en konto? Log ind';

  @override
  String get authConfirmLogout => 'Er du sikker på, at du vil logge ud?';

  @override
  String get authDiscordTitle => 'Uenighed';

  @override
  String get authDiscordSignIn => 'Log ind med Discord';

  @override
  String get authDiscordContinue => 'Fortsæt med Discord';

  @override
  String get authDiscordDescription =>
      'Synkroniser dine data med ClashKing Bot og lås op for det fulde potentiale af ClashKing!';

  @override
  String get authEmailTitle => 'E-mail';

  @override
  String get authEmailDescription =>
      'Brug e-mail, hvis du ikke kan få adgang til Discord eller foretrækker app-only funktioner';

  @override
  String get authEmailRequired => 'Indtast venligst din e-mail';

  @override
  String get authEmailInvalid => 'Indtast venligst en gyldig e-mail';

  @override
  String get authPasswordLabel => 'Adgangskode';

  @override
  String get authPasswordConfirm => 'Bekræft Adgangskode';

  @override
  String get authPasswordRequired => 'Indtast venligst din adgangskode';

  @override
  String get authPasswordConfirmRequired => 'Bekræft venligst din adgangskode';

  @override
  String get authPasswordMismatch => 'Adgangskoder stemmer ikke overens';

  @override
  String get authPasswordTooShort => 'Adgangskoden skal være på mindst 8 tegn';

  @override
  String get authPasswordRequirements =>
      'Adgangskoden skal indeholde: store bogstaver, små bogstaver, tal og specialtegn';

  @override
  String get authPasswordForgot => 'Glemt adgangskode?';

  @override
  String get authUsernameLabel => 'Brugernavn';

  @override
  String get authUsernameRequired => 'Indtast venligst et brugernavn';

  @override
  String get authUsernameTooShort => 'Brugernavn skal være på mindst 3 tegn';

  @override
  String get authErrorConnection =>
      'Der opstod en fejl. Kontroller din internetforbindelse og prøv igen.';

  @override
  String get authErrorConnectionRelaunch =>
      'Der opstod en fejl. Kontroller din internetforbindelse og genstart appen.';

  @override
  String get authAccountManagement =>
      'Tilføj, fjern og genbestil dine Clash of Clans konti. Bekræft dine konti for at få adgang til alle funktioner.';

  @override
  String get authAccountConnected => 'Tilsluttede Konti';

  @override
  String get authAccountConnectedStatus => 'Forbundet';

  @override
  String get authAccountNotConnected => 'Ikke forbundet';

  @override
  String get authAccountEmailAndPassword => 'Email & Adgangskode';

  @override
  String get authAccountSecured =>
      'Din konto er sikret med flere godkendelsesmetoder';

  @override
  String get authAccountLinkEmail => 'Link E-Mail Konto';

  @override
  String get authAccountAddEmailAuth =>
      'Tilføj godkendelse af e- mail og kodeord til din konto for yderligere sikkerhed.';

  @override
  String get authAccountEmailLinkedSuccess => 'E-mail-konto linket sammen!';

  @override
  String get helpTitle => 'Brug for hjælp?';

  @override
  String get helpJoinDiscord => 'Deltag I Discord';

  @override
  String get helpEmailUs => 'E-mail Os';

  @override
  String get accountsWelcome => 'Velkommen!';

  @override
  String get accountsWelcomeMessage =>
      'Tilføj venligst en eller flere Clash of Clans konti til din profil. Du kan tilføje eller fjerne konti senere.';

  @override
  String get accountsManageTitle => 'Administrer dine konti';

  @override
  String get accountsNoneFound => 'Ingen konto forbundet til din profil fundet';

  @override
  String get accountsPlayerTag => 'Spiller Tag (# ABC123)';

  @override
  String get accountsEnterPlayerTag => 'Indtast en spiller tag';

  @override
  String get accountsAdd => 'Tilføj konto';

  @override
  String get accountsDelete => 'Slet konto';

  @override
  String get accountsApiToken => 'Konto API Token';

  @override
  String get accountsEnterApiToken =>
      'Indtast venligst konto API token for at bekræfte det er din. Du kan finde det i Sammenstød mellem klaner indstillinger > Flere indstillinger > API Token.';

  @override
  String get accountsFillAllFields => 'Udfyld venligst alle felter.';

  @override
  String get accountsErrorTagNotExists =>
      'Det indtastede afspiller-tag eksisterer ikke.';

  @override
  String accountsErrorAlreadyLinked(Object tag) {
    return 'Spilleren tag er allerede knyttet til nogen.';
  }

  @override
  String get accountsErrorAlreadyLinkedToYou =>
      'Spilleren tag er allerede knyttet til dig.';

  @override
  String get accountsErrorWrongApiToken =>
      'Den indtastede API-token er forkert';

  @override
  String get accountsErrorFailedToAdd =>
      'Kunne ikke tilføje kontoen. Prøv igen senere.';

  @override
  String get accountsErrorFailedToDelete =>
      'Kunne ikke slette linket. Prøv igen senere.';

  @override
  String get accountsErrorFailedToUpdateOrder =>
      'Kunne ikke opdatere rækkefølgen af konti.';

  @override
  String get errorTitle =>
      'Ups! Vores servere har måske taget en ildkugle til ansigtet! Vi kaster en healing magi ... Prøv igen om et øjeblik.';

  @override
  String get errorSubtitle =>
      'Hvis problemet fortsætter, tjek vores Discord Server for at se, om vi er klar over det.';

  @override
  String get errorLoadingVersion => 'Fejl under indlæsning af version';

  @override
  String get errorCannotOpenLink => 'Vi kan ikke åbne dette link.';

  @override
  String get errorExitAppToOpenClash =>
      'Du er ved at forlade appen for at åbne Clash of Clans.';

  @override
  String get playerSearchTitle => 'Søg spiller';

  @override
  String get playerSearchPlaceholder => 'Spillerens navn eller tag';

  @override
  String playerLastActive(String date) {
    return 'Seneste aktiv: $date';
  }

  @override
  String get playerNotTracked =>
      'Denne spiller er ikke sporet. Data kan være unøjagtige.';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Din klan er \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(
      String ratio, String donations, String received) {
    return 'Dit donationsforhold er $ratio. Du har doneret $donations tropper og modtaget $received tropper.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Din krigspræference er \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'Du har $stars krigsstjerner.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'Du har $trophies trofæer. Du er i øjeblikket $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Dit rådhusniveau er $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Dit Builder Hall niveau er $level og du har $trophies trofæer.';
  }

  @override
  String get gameBaseHome => 'Hjemme Base';

  @override
  String get gameBaseBuilder => 'Builder Base';

  @override
  String get gameClanCapital => 'Klan Kapital';

  @override
  String get gameTownHall => 'TH';

  @override
  String get gameTownHallLevel => 'TH Niveau';

  @override
  String gameTownHallLevelNumber(int level) {
    return 'Rådhuset $level';
  }

  @override
  String gameTHLevel(int level) {
    return 'TH$level';
  }

  @override
  String get gameExpLevel => 'Oplevelses Niveau';

  @override
  String get gameTrophies => 'Trofæer';

  @override
  String get gameBuilderBaseTrophies => 'BB Trofæer';

  @override
  String get gameDonations => 'Donationer';

  @override
  String get gameDonationsReceived => 'Donationer Modtaget';

  @override
  String get gameDonationsRatio => 'Donationsforhold';

  @override
  String gameLevel(int level, int maxLevel) {
    return 'Niveau: $level/$maxLevel';
  }

  @override
  String get gameHeroes => 'Helte';

  @override
  String get gameEquipment => 'Udstyr';

  @override
  String get gameHeroesEquipments => 'Helt udstyr';

  @override
  String get gameTroops => 'Tropper';

  @override
  String get gameActiveSuperTroops => 'Aktive Supertropper';

  @override
  String get gamePets => 'Kæledyr';

  @override
  String get gameSiegeMachines => 'Belejningsmaskiner';

  @override
  String get gameSpells => 'Spells';

  @override
  String get gameAchievements => 'Bedrifter';

  @override
  String get gameClanGames => 'Klan Spil';

  @override
  String get gameSeasonPass => 'Sæson Pass';

  @override
  String get gameCreatorCode => 'Skaber Kode: Sammenstød';

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
  String get clanTitle => 'Klan';

  @override
  String get clanSearchTitle => 'Søg klan';

  @override
  String get clanSearchPlaceholder => 'Klans navn';

  @override
  String get clanNone => 'Ingen klan';

  @override
  String get clanJoinToUnlock =>
      'Deltag i en klan for at låse op for nye funktioner.';

  @override
  String get clanMembers => 'Medlemmer';

  @override
  String get clanWarFrequency => 'Krig frekvens';

  @override
  String get clanMinimumMembers => 'Minimum medlemmer';

  @override
  String get clanMaximumMembers => 'Maksimum medlemmer';

  @override
  String get clanLocation => 'Placering';

  @override
  String get clanMinimumPoints => 'Minimum klan punkter';

  @override
  String get clanMinimumLevel => 'Mindste klan niveau';

  @override
  String get clanInviteOnly => 'Kun Invitation';

  @override
  String get clanOpened => 'Åbnet';

  @override
  String get clanClosed => 'Lukket';

  @override
  String get clanRoleLeader => 'Leder';

  @override
  String get clanRoleCoLeader => 'Medleder';

  @override
  String get clanRoleElder => 'Ældre';

  @override
  String get clanRoleMember => 'Medlem';

  @override
  String get clanWarFrequencyAlways => 'Altid';

  @override
  String get clanWarFrequencyNever => 'Aldrig';

  @override
  String get clanWarFrequencyUnknown => 'Ukendt';

  @override
  String get clanWarFrequencyOncePerWeek => '1/uge';

  @override
  String get clanWarFrequencyMoreThanOncePerWeek => 'Mere end 1/uge';

  @override
  String get clanWarFrequencyRarely => 'Sjældent';

  @override
  String get timeHourIndicator => 'h';

  @override
  String timeDaysAgo(int days) {
    return '$days dage siden';
  }

  @override
  String timeDayAgo(int day) {
    return '$day dag siden';
  }

  @override
  String timeHourAgo(int hour) {
    return '$hour time siden';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours timer siden';
  }

  @override
  String timeMinuteAgo(int minute) {
    return '$minute minut siden';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes minutter siden';
  }

  @override
  String get timeJustNow => 'Lige Nu';

  @override
  String get timeEndedJustNow => 'Sluttede lige nu';

  @override
  String timeEndedMinutesAgo(int minutes) {
    return 'Sluttede $minutes minutter siden';
  }

  @override
  String timeEndedHoursAgo(int hours) {
    return 'Sluttede $hours timer siden';
  }

  @override
  String timeEndedDaysAgo(int days) {
    return 'Afsluttede $days dage siden';
  }

  @override
  String timeStartsIn(String time) {
    return 'Starter i $time';
  }

  @override
  String timeStartsAt(String time) {
    return 'Starter ved $time';
  }

  @override
  String timeEndsIn(String time) {
    return 'Slutter i $time';
  }

  @override
  String timeEndsAt(String time) {
    return 'Slutter på $time';
  }

  @override
  String get legendsTitle => 'Forklarende Liga';

  @override
  String get legendsNotInLeague => 'Ikke i Legend League';

  @override
  String get legendsNoDataToday =>
      'Du er ikke i Legend League, men tidligere årstider er tilgængelige.';

  @override
  String legendsStartDescription(String trophies) {
    return 'Du startede dagen med $trophies trofæer.';
  }

  @override
  String legendsNoRankLocalDescription(String country, int trophies) {
    return 'Du er i øjeblikket ikke rangeret ($country) med $trophies trofæer.';
  }

  @override
  String legendsRankLocalDescription(int rank, String country, int trophies) {
    return 'Du er i øjeblikket rangeret $rank ($country) med $trophies trofæer.';
  }

  @override
  String legendsGainDescription(int trophies) {
    return 'Du fik $trophies trofæer for nu.';
  }

  @override
  String legendsLossDescription(int trophies) {
    return 'Du har mistet $trophies trofæer for nu.';
  }

  @override
  String legendsNoGlobalRankDescription(int trophies) {
    return 'Du er i øjeblikket ikke rangeret globalt med $trophies trofæer.';
  }

  @override
  String legendsGlobalRankDescription(int rank, int trophies) {
    return 'Du er i øjeblikket rangeret $rank globalt med $trophies trofæer.';
  }

  @override
  String get legendsNoRank => 'Ingen placering';

  @override
  String get legendsBestTrophies => 'Bedste Trofæer';

  @override
  String get legendsMostAttacks => 'Flest Angreb';

  @override
  String get legendsLastSeason => 'Sidste Sæson';

  @override
  String get legendsBestRank => 'Bedste Globale Rang';

  @override
  String get legendsTrophiesBySeason => 'Trofæer efter sæson';

  @override
  String get legendsEosTrophies => 'Afslutning Af Sæson Trofæer';

  @override
  String get legendsEosDetails => 'Afslutning Af Sæson Detaljer';

  @override
  String get legendsInaccurateTitle => 'Unøjagtige data?';

  @override
  String get legendsInaccurateIntro =>
      'På grund af begrænsninger i sammenstød mellem klaner API, vores data måske ikke altid være helt nøjagtige. Her er hvorfor:\n';

  @override
  String get legendsInaccurateApiDelayTitle => '1. Api Forsinkelse: ';

  @override
  String get legendsInaccurateApiDelayBody =>
      'API kan tage op til 5 minutter at opdatere, hvilket forårsager en forsinkelse i afspejler real-time trofæ ændringer.\n';

  @override
  String get legendsInaccurateConcurrentTitle => '2. Samtidige Ændringer: \n';

  @override
  String get legendsInaccurateMultipleAttacksTitle =>
      '- Flere Angreb/Forsvar: ';

  @override
  String get legendsInaccurateMultipleAttacksBody =>
      'Hvis flere angreb eller forsvar sker i hurtig rækkefølge, API kan vise kombinerede resultater (f.eks. +68 eller -68).\n';

  @override
  String get legendsInaccurateSimultaneousTitle =>
      '- Samtidig angreb og forsvar: ';

  @override
  String get legendsInaccurateSimultaneousBody =>
      'Hvis et angreb og forsvar opstår på samme tid, kan du se et blandet resultat (fx, +4).\n';

  @override
  String get legendsInaccurateNetGainTitle => '3. Nettogevinst/-tab: ';

  @override
  String get legendsInaccurateNetGainBody =>
      'Trods timing problemer, den samlede netto gevinst eller tab for dagen er nøjagtig. ';

  @override
  String get legendsInaccurateConclusion =>
      'Disse begrænsninger er fælles på tværs af alle værktøjer ved hjælp af Clash of Clans API. Vi kan desværre ikke ordne det, som det er i Supercell\'s hænder. Vi gør vores bedste for at kompensere for disse grænser og give resultater så tæt på virkeligheden som muligt. Tak for forståelsen!';

  @override
  String get statsSeasonStats => 'Sæson Statistik';

  @override
  String get statsByDay => 'Efter Dag';

  @override
  String get statsBySeason => 'Efter Sæson';

  @override
  String statsDayIndex(int index) {
    return 'Dag $index';
  }

  @override
  String statsIndexDays(int index) {
    return '$index dage';
  }

  @override
  String statsSeasonDate(String date) {
    return '$date sæson';
  }

  @override
  String get statsAllTownHalls => 'Alle Rådhuse';

  @override
  String get statsMembers => 'Medlems Statistik';

  @override
  String get todoTitle => 'Gøremålsliste';

  @override
  String get todoExplanationTitle => 'Beregning Af Opgave';

  @override
  String get todoExplanationIntro =>
      'Procentdelen for afslutning af opgaven beregnes ud fra følgende aktiviteter med specifikke vægtninger:';

  @override
  String get todoExplanationLegendsTitle => 'Forklarende Liga:';

  @override
  String get todoExplanationLegends =>
      'Vægt på 8 point pr. konto, 1 angreb = 1 point.';

  @override
  String get todoExplanationRaidsTitle => 'Raids:';

  @override
  String get todoExplanationRaids =>
      'Vægt på 5 point pr. konto (eller 6 hvis det sidste angreb er blevet låst), 1 angreb = 1 point.';

  @override
  String get todoExplanationClanWarsTitle => 'Klan Krig:';

  @override
  String get todoExplanationClanWars =>
      'Vægt på 2 point pr. konto, 1 angreb = 1 point.';

  @override
  String get todoExplanationCwlTitle => 'Klan Krigsliga:';

  @override
  String get todoExplanationCwl =>
      'Vægt på 1 point pr. konto, 1 angreb = 1 point. CWL kan ikke spores, hvis spilleren ikke er i deres liga klan.';

  @override
  String get todoExplanationPassAndGamesTitle => 'Sæson Pass & Klan Spil:';

  @override
  String get todoExplanationPassAndGames =>
      'Vægt på 2 point pr. konto. Forholdet er baseret på antallet af dage, der er tilbage (1 måned for pass og 6 dage for spillet). Grøn = på sporet for at fuldføre passet eller spillet, rød = bag tidsplanen.';

  @override
  String get todoExplanationConclusion =>
      'Den endelige procentdel beregnes ved at dividere de samlede handlinger, der er gennemført under igangværende begivenheder, med de samlede påkrævede handlinger. Konti inaktiv i mere end 14 dage er udelukket fra beregningen.';

  @override
  String todoAccountsNumber(int number) {
    return '$number konti';
  }

  @override
  String todoAccountsNumberActive(int number) {
    return '$number aktive konti';
  }

  @override
  String todoAccountsNumberInactive(int number) {
    return '$number inaktive konti';
  }

  @override
  String get todoAccountsActive => 'Aktive konti';

  @override
  String get todoAccountsInactive => 'Inaktive konti';

  @override
  String get todoAccountsNoInactive => 'Ingen inaktive konti.';

  @override
  String get todoAccountsNoActive => 'Ingen aktive konti.';

  @override
  String todoAttacksLeftDescription(int attacks, String type) {
    return 'Du har $attacks angreb tilbage ($type).';
  }

  @override
  String todoDefensesLeftDescription(int defenses, String type) {
    return 'Du har $defenses defense(s) tilbage ($type).';
  }

  @override
  String todoNoAttacksLeftDescription(String type) {
    return 'Tillykke, du har gjort alle dine angreb ($type)!';
  }

  @override
  String todoPointsLeftDescription(int points, String type) {
    return 'Du har $points point tilbage for at komme i dag til at være i tide til afslutningen af begivenheden ($type).';
  }

  @override
  String todoPointsLeftDescriptionNoPoints(String type) {
    return 'Tillykke, du er på tide til at få de maksimale belønninger i slutningen af begivenheden ($type)!';
  }

  @override
  String get warTitle => 'Krig';

  @override
  String get warFrequency => 'Krig frekvens';

  @override
  String get warParticipation => 'Krig Deltagelse';

  @override
  String get warLeague => 'Krig/Liga';

  @override
  String get warHistory => 'Krig Historie';

  @override
  String get warLog => 'Krigslog';

  @override
  String warLogClosed(String clan) {
    return '$clan\'s krigslog er lukket.';
  }

  @override
  String get warStats => 'Krig Statistik';

  @override
  String get warOngoing => 'Igangværende krig';

  @override
  String warIsNotInWar(String clan) {
    return '$clan er ikke i krig.';
  }

  @override
  String get warAskForWar =>
      'Kontakt lederen eller en medleder for at starte en krig.';

  @override
  String get warAskForWarLogOpening =>
      'Kontakt en leder eller en medleder for at åbne krigsloggen.';

  @override
  String get warEnded => 'Krig sluttede';

  @override
  String get warPreparation => 'Forberedelse';

  @override
  String get warPerfectWar => 'Perfekt krig';

  @override
  String get warVictory => 'Sejr';

  @override
  String get warDefeat => 'Besejr';

  @override
  String get warDraw => 'Tegn';

  @override
  String get warTeamSize => 'Hold størrelse';

  @override
  String get warMyTeam => 'Mit team';

  @override
  String get warEnemiesTeam => 'Enemies';

  @override
  String get warClanDraw => 'De to klaner er bundet';

  @override
  String get warStateOfTheWar => 'Tilstand af krigen';

  @override
  String warStarsNeededToTakeTheLead(
      String clan, int star, int stars2, String percent) {
    return '$clan har stadig brug for $star flere stjerne(r) eller $stars2 stjerne(r) og $percent% for at tage føringen.';
  }

  @override
  String warStarsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan har stadig brug for $percent% eller 1 stjerne til at tage føringen';
  }

  @override
  String get warNoDataAvailableForThisWar =>
      'Ingen tilgængelige data for denne krig';

  @override
  String get warCalculatorFast => 'Hurtig lommeregner';

  @override
  String warCalculatorAnswer(String percentNeeded, String result) {
    return 'For at opnå en ødelæggelsesrate på $percentNeeded%, er der brug for i alt $result%.';
  }

  @override
  String get warCalculatorNeededOverall => '% Behøver samlet';

  @override
  String get warCalculatorCalculate => 'Beregn';

  @override
  String get warAttacksTitle => 'Angreb';

  @override
  String get warAttacksNone => 'Intet angreb endnu';

  @override
  String get warAttacksBest => 'Bedste angreb';

  @override
  String get warAttacksCount => 'Angrib Antal';

  @override
  String get warAttacksMissed => 'Ubesvarede Angreb';

  @override
  String warAttacksNumber(int number_time, int number_war) {
    return 'Du angreb $number_time tid under de sidste $number_war krige.';
  }

  @override
  String warAttacksAverageStars(String stars) {
    return 'Du havde i gennemsnit $stars stjerner pr. krig.';
  }

  @override
  String warAttacksAverageDestruction(String percent) {
    return 'Du havde et gennemsnit af $percent% ødelæggelse per krig.';
  }

  @override
  String get warDefensesTitle => 'Forsvar';

  @override
  String get warDefensesNone => 'Intet forsvar endnu';

  @override
  String get warDefensesBest => 'Bedste forsvar';

  @override
  String warDefensesBestOutOf(int number) {
    return 'Bedste forsvar (ud af $number)';
  }

  @override
  String warDefensesNumber(int number_time, int number_war) {
    return 'Du forsvarede $number_time tid under de sidste $number_war krige.';
  }

  @override
  String warDefensesAverageStars(double stars) {
    return 'Du havde et gennemsnit af $stars stjerner pr. forsvar.';
  }

  @override
  String warDefensesAverageDestruction(String percent) {
    return 'Du havde i gennemsnit $percent% destruktionsrate pr. forsvar.';
  }

  @override
  String get warStarsTitle => 'Stjerner';

  @override
  String get warStarsAverage => 'Gennemsnitlige stjerner';

  @override
  String get warStarsNumber => 'Antal stjerner';

  @override
  String get warStarsOne => '1 stjerne';

  @override
  String get warStarsTwo => '2 stjerner';

  @override
  String get warStarsThree => '3 stjerner';

  @override
  String get warStarsZero => '0 Stjerne';

  @override
  String get warStarsBestPerformance => 'Bedste ydeevne';

  @override
  String get warDestructionTitle => 'Destruktion';

  @override
  String get warDestructionAverage => 'Gennemsnitlig destruktion';

  @override
  String get warDestructionRate => 'Destruktionssats';

  @override
  String warHistoryWinsDescription(int wins, String percent) {
    return 'Din klan vandt $wins krige ($percent%) ud af de sidste 50 krige.';
  }

  @override
  String warHistoryLossesDescription(int losses, String percent) {
    return 'Din klan mistede $losses krige ($percent%) ud af de sidste 50 krige.';
  }

  @override
  String warHistoryDrawsDescription(int draws, String percent) {
    return 'Din klan havde $draws trækker ($percent%) ud af de sidste 50 krige.';
  }

  @override
  String warHistoryAverageMembersDescription(int members) {
    return 'Din klan har i gennemsnit $members medlemmer, der deltager ud af de sidste 50 krige.';
  }

  @override
  String warHistoryAverageWarStarsDescription(double stars, String percent) {
    return 'Din klan havde i gennemsnit $stars stjerner per krig fra de sidste 50 krige. Den repræsenterer $percent af de samlede stjerner.';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return 'Din klan havde i gennemsnit $percent% destruktionsrate fra de sidste 50 krige.';
  }

  @override
  String get warPositionMap => 'Kort Position';

  @override
  String get warPositionAbbr => 'Pos';

  @override
  String get warPositionOrder => 'Ordre';

  @override
  String get warOpponentTownhall => 'Opp TH';

  @override
  String get warOpponentLowerTownhall => 'Nedre TH';

  @override
  String get warOpponentUpperTownhall => 'Øvre TH';

  @override
  String get warOpponentEqualThLevel => 'Lig Med TH';

  @override
  String get warOpponentSelectMembersThLevel => 'Medlemmer TH Niveau';

  @override
  String get warOpponentSelectOpponentsThLevel => 'Modstandere TH Niveau';

  @override
  String warFiltersLastXwars(int number) {
    return 'Seneste $number krige';
  }

  @override
  String get warFiltersFriendly => 'Venlig';

  @override
  String get warFiltersRandom => 'Tilfældig';

  @override
  String get warVisibilityToggleTownHall =>
      'Skjul/Vis statistik fra tidligere TH-niveauer';

  @override
  String get warEventsTitle => 'Begivenheder';

  @override
  String get warEventsNewest => 'Nyeste';

  @override
  String get warEventsOldest => 'Ældste';

  @override
  String get warStatusReady => 'Valgt Ind';

  @override
  String get warStatusUnready => 'Valgt Ud';

  @override
  String get warStatusMissed => 'Ubesvaret';

  @override
  String get warAbbreviationAvg => 'Gns';

  @override
  String get warAbbreviationAvgPercentage => 'Gns. %';

  @override
  String get cwlTitle => 'CWL';

  @override
  String get cwlClanWarLeague => 'Klan Krigsliga';

  @override
  String get cwlOngoing => 'Igangværende CWL';

  @override
  String get cwlRounds => 'Runder';

  @override
  String cwlRoundNumber(int number) {
    return 'Runde $number';
  }

  @override
  String cwlCurrentRound(int round) {
    return 'Aktuel runde (Round $round)';
  }

  @override
  String cwlRank(int rank) {
    return 'Din klan er i øjeblikket rangeret $rank.';
  }

  @override
  String cwlStars(int stars) {
    return 'Din klan har i alt $stars stjerner.';
  }

  @override
  String cwlDestructionPercentage(String percent) {
    return 'Din klan har en total ødelæggelse på $percent%.';
  }

  @override
  String cwlTotalAttacks(int attacks, int totalAttacks) {
    return 'Din klan har i alt $attacks angreb ud af $totalAttacks mulige angreb.';
  }

  @override
  String get joinLeaveTitle => 'Tilmeld/Forlad Logfiler (periodevis)';

  @override
  String get joinLeaveJoin => 'Deltag';

  @override
  String get joinLeaveLeave => 'Forlad';

  @override
  String get joinLeaveReset => 'Reset';

  @override
  String get joinLeaveJoins => 'Deltager';

  @override
  String get joinLeaveLeaves => 'Blade';

  @override
  String get joinLeaveUniquePlayers => 'Unikke Spillere';

  @override
  String get joinLeaveMovingPlayers => 'Flytter Spillere';

  @override
  String get joinLeaveMostMovingPlayers => 'Mest Bevægende Spillere';

  @override
  String get joinLeaveStillInClan => 'Stadig i klan';

  @override
  String get joinLeaveLeftForever => 'Venstre For Evigt';

  @override
  String get joinLeaveRejoinedPlayers => 'Gentilsluttede Spillere';

  @override
  String get joinLeaveAvgTimeJoinLeave => 'Gns Tilmeld/Forlad Tid';

  @override
  String get joinLeavePeakHour => 'Mest Aktive Time';

  @override
  String joinLeaveNumberDescription(int number, String date) {
    return '$number leave events occurred during the current season ($date).';
  }

  @override
  String joinLeaveJoinNumberDescription(int number, String date) {
    return '$number join begivenheder opstod i den aktuelle sæson ($date).';
  }

  @override
  String joinLeaveMovingNumberDescription(int number, String date) {
    return '$number spiller(e) til venstre og tilsluttede sig klanen i den aktuelle sæson ($date).';
  }

  @override
  String joinLeaveUniqueNumberDescription(int number, String date) {
    return '$number unikke spiller(e) tilsluttede/forlod klanen i den aktuelle sæson ($date).';
  }

  @override
  String joinLeaveStillInClanNumberDescription(int number) {
    return '$number spiller(e) tilsluttede sig og er stadig i klanen.';
  }

  @override
  String joinLeaveLeftClanNumberDescription(int number) {
    return '$number spiller(e) tilsluttede, så forlod klanen og blev aldrig genoprettet.';
  }

  @override
  String joinLeaveLeftOnAt(String date, String time) {
    return 'Venstre på $date på $time.';
  }

  @override
  String joinLeaveJoinedOnAt(String date, String time) {
    return 'Tilmeldt $date på $time.';
  }

  @override
  String get raidsTitle => 'Raids';

  @override
  String get raidsLast => 'Sidste razziaer';

  @override
  String get raidsOngoing => 'Igangværende razziaer';

  @override
  String get raidsDistrictsDestroyed => 'Distrikter ødelagt';

  @override
  String get raidsCompleted => 'Raids fuldført';

  @override
  String get searchNoResult => 'Intet resultat.';

  @override
  String get maintenanceTitle => 'Vedligeholdelse';

  @override
  String get maintenanceDescription =>
      'Sammenstød af klaner er i øjeblikket under vedligeholdelse, så vi kan ikke få adgang til API\'en. Tjek venligst tilbage senere.';

  @override
  String get downloadTooltip => 'Download CWL resumé';

  @override
  String get downloadInProgress =>
      'Downloader fil... Det kan tage et par sekunder...';

  @override
  String downloadSuccess(String path) {
    return 'Filen blev gemt i $path';
  }

  @override
  String get downloadError => 'Download af fil mislykkedes';

  @override
  String get dashboardTitle => 'Instrumentbræt';

  @override
  String get toolsTitle => 'Værktøjer';

  @override
  String get navigationTeam => 'Hold';

  @override
  String get navigationStatistics => 'Statistik';

  @override
  String get versionDevice => 'Version & Enhed';

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
  String get betaFeature => 'Beta Funktion';

  @override
  String get betaLabel => 'INDSATS';

  @override
  String get betaDescription =>
      'Denne funktion er i øjeblikket i beta, den kan have nogle fejl eller være ufuldstændig. Vi arbejder aktivt på forbedringer og hilser din feedback velkommen. Del dine ideer og rapporter eventuelle problemer i vores Discord Server for at hjælpe os med at gøre det bedre.';

  @override
  String get settingsLanguage => 'Sprog';

  @override
  String get settingsSelectLanguage => 'Vælg et sprog';

  @override
  String get settingsToggleTheme => 'Skift Tema';

  @override
  String get faqTitle => 'OSS';

  @override
  String get faqSubtitle => 'Ofte Stillede Spørgsmål';

  @override
  String get faqIsThisFromSupercell => 'Er denne app fra Supercell?';

  @override
  String get faqFanContentPolicy =>
      'Dette materiale er uofficielt og er ikke godkendt af Supercell. For mere information se Supercell\'s Fan Content Policy: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate =>
      'Hvorfor mangler dataene nogle gange unøjagtigt?';

  @override
  String get faqClanNotTracked => 'Klan ikke sporet';

  @override
  String get faqClanNotTrackedAnswer =>
      'ClashKing kan kun hente denne info hvis klanen er sporet. Hvis din klan ikke spores, bedes du invitere ClashKing Bot til din Discord Server og bruge kommandoen /addclan. Vi arbejder på at gøre denne funktion tilgængelig i appen snart.';

  @override
  String get faqTrackingDown => 'Sporing ned';

  @override
  String get faqTrackingDownAnswer =>
      'Sporingen kan stoppe med at arbejde i en vis periode. Det er derfor, du nogle gange kan have huller i dine data. Vi arbejder på at forbedre dette.';

  @override
  String get faqApiLimitation => 'Sammenstød mellem klaner API begrænsning';

  @override
  String get faqApiLimitationAnswer =>
      'Nogle data leveres af Clash of Clans og deres API har nogle begrænsninger. Dette er tilfældet for legender tracking, det undertiden stakker trofæet gevinst og tab, som om det var et enkelt angreb. Det er også derfor, vi ikke har nogen oplysninger om din bygning niveauer.';

  @override
  String get faqSupportWork => 'Hvordan kan jeg støtte dit arbejde?';

  @override
  String get faqSupportWorkAnswer => 'Der er flere måder at støtte os:';

  @override
  String get faqUseCodeClashKing => 'Brug koden \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Støt os på Patreon';

  @override
  String get faqShareTheApp => 'Del appen med dine venner';

  @override
  String get faqRateTheApp => 'Bedøm appen i butikken';

  @override
  String get faqHelpUsTranslate => 'Hjælp os med at oversætte appen';

  @override
  String get faqHowToInviteTheBot =>
      'Hvordan kan jeg invitere din bot til min Discord Server?';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'Du kan invitere vores bot til din server ved at klikke på knappen nedenfor. Du skal bruge tilladelsen \"Administrer Server\" for at tilføje bot.';

  @override
  String get faqInviteTheBot => 'Invite ClashKing Bot';

  @override
  String get faqNeedHelp =>
      'Jeg har brug for hjælp, eller jeg vil gerne komme med et forslag. Hvordan kan jeg kontakte dig?';

  @override
  String get faqNeedHelpAnswer =>
      'You can join our Discord Server to ask for help or to provide feedback, or you can email us at devs@clashk.ing. Please only write in English or French.';

  @override
  String get faqSendEmail => 'Send en e-mail';

  @override
  String get faqJoinDiscord => 'Tilmeld dig vores Discord Server';

  @override
  String get faqCannotOpenMailClient =>
      'Af nogle grunde kan vi ikke åbne din mailklient. Vi kopierede e-mailadressen for dig. Du kan skrive en e-mail og indsætte adressen i modtagerfeltet.';

  @override
  String get translationHelpUsTranslate => 'Hjælp os med at oversætte';

  @override
  String get translationSuggestFeatures => 'Foreslå funktioner';

  @override
  String get translationThankYou => 'Mange tak!';

  @override
  String get translationThankYouContent =>
      'En stor tak til alle vores fantastiske oversættere, der hjælper os med at gøre denne app tilgængelig for flere mennesker rundt om i verden!';

  @override
  String get translationHelpTranslateContent =>
      'Du kan hjælpe os med at oversætte appen på Crowdin. Hvis dit sprog ikke er tilgængeligt på Crowdin, er du velkommen til at anmode om det i vores Discord Server. Tak for din hjælp!';

  @override
  String get translationHelpTranslateButton =>
      'Hjælp med at oversætte til Crowdin';

  @override
  String get translationCurrentTranslators => 'Nuværende Oversættere';
}
