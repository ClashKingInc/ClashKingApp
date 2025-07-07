// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'ClashKing';

  @override
  String get appDescription =>
      'Il tuo ultimo compagno Clash of Clans per tracciare le statistiche, gestire i clan e analizzare le prestazioni.';

  @override
  String get generalLoading => 'Caricamento...';

  @override
  String get loadingVillages => 'Caricamento dei villaggi...';

  @override
  String get loadingClanData => 'Recupero dati clan...';

  @override
  String get loadingWarStats => 'Analisi delle statistiche di guerra...';

  @override
  String get loadingLegendsData => 'Preparazione dei dati legenda...';

  @override
  String get loadingCapitalRaids => 'Caricamento raid di capitale...';

  @override
  String get loadingAlmostReady => 'Quasi pronto...';

  @override
  String get accountVerificationTitle => 'Verifica Account';

  @override
  String get accountVerificationMessage =>
      'Inserisci il tuo token API per verificare il tuo account. Puoi trovarlo in Impostazioni di Clash of Clans > Altre impostazioni > Token API.';

  @override
  String get accountVerified => 'Account verificato';

  @override
  String get accountNotVerified => 'Account non verificato';

  @override
  String get accountVerifyButton => 'Verifica';

  @override
  String get accountVerificationSuccess => 'Account verificato con successo!';

  @override
  String get accountVerificationFailed =>
      'Verifica non riuscita. Controlla il tuo token API.';

  @override
  String get generalRetry => 'Riprova';

  @override
  String get generalTryAgain => 'Riprova';

  @override
  String get generalCancel => 'Annulla';

  @override
  String get generalOk => 'OK';

  @override
  String get generalApply => 'Applica';

  @override
  String get generalConfirm => 'Conferma';

  @override
  String get generalManage => 'Gestisci';

  @override
  String get generalSettings => 'Impostazioni';

  @override
  String get generalCopiedToClipboard => 'Copiato negli appunti';

  @override
  String get generalComingSoon => 'In arrivo!';

  @override
  String generalLastRefresh(String time) {
    return 'Ultimo aggiornamento: $time';
  }

  @override
  String generalRefreshFailed(String error) {
    return 'Aggiornamento non riuscito: $error';
  }

  @override
  String get generalAll => 'Tutti';

  @override
  String get generalTotal => 'Totale';

  @override
  String get generalBest => 'Migliore';

  @override
  String get generalWorst => 'Peggiore';

  @override
  String get generalAverage => 'Media';

  @override
  String get generalRemaining => 'Rimanente';

  @override
  String get generalActive => 'Attivo';

  @override
  String get generalInactive => 'Inattivo';

  @override
  String get generalStarted => 'Iniziato';

  @override
  String get generalEnded => 'Terminato';

  @override
  String get generalRole => 'Ruolo';

  @override
  String get generalStats => 'Statistiche';

  @override
  String get generalFullStats => 'Statistiche Completa';

  @override
  String get generalDetails => 'Dettagli';

  @override
  String get generalHistory => 'Storico';

  @override
  String get generalFilters => 'Filtri';

  @override
  String get generalNotSet => 'Non impostato';

  @override
  String get generalWarning => 'Attenzione';

  @override
  String get generalNoDataAvailable => 'Nessun dato disponibile.';

  @override
  String get authSignUp => 'Registrati';

  @override
  String get authLogin => 'Accedi';

  @override
  String get authLogout => 'Log out';

  @override
  String get authCreateAccount => 'Crea Account';

  @override
  String get authJoinClashKing => 'Unisciti A ClashKing';

  @override
  String get authCreateClashKingAccount => 'Crea Account ClashKing';

  @override
  String get authCreateAccountToGetStarted =>
      'Crea il tuo account per iniziare';

  @override
  String get authAlreadyHaveAccount => 'Hai già un account? Accedi';

  @override
  String get authConfirmLogout => 'Sei sicuro di voler uscire?';

  @override
  String get authDiscordTitle => 'Discord';

  @override
  String get authDiscordSignIn => 'Accedi con Discord';

  @override
  String get authDiscordContinue => 'Continua con Discord';

  @override
  String get authDiscordDescription =>
      'Sincronizza i tuoi dati con ClashKing Bot e sblocca tutto il potenziale di ClashKing!';

  @override
  String get authEmailTitle => 'Email';

  @override
  String get authEmailDescription =>
      'Usa email se non riesci ad accedere a Discord o preferisci le funzionalità di sola app';

  @override
  String get authEmailRequired => 'Inserisci la tua email';

  @override
  String get authEmailInvalid => 'Inserisci un\'email valida';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordConfirm => 'Conferma Password';

  @override
  String get authPasswordRequired => 'Inserisci la tua password';

  @override
  String get authPasswordConfirmRequired => 'Conferma la tua password';

  @override
  String get authPasswordMismatch => 'Le password non corrispondono';

  @override
  String get authPasswordTooShort =>
      'La password deve contenere almeno 8 caratteri';

  @override
  String get authPasswordRequirements =>
      'La password deve contenere: maiuscolo, minuscolo, cifra e carattere speciale';

  @override
  String get authPasswordForgot => 'Password dimenticata?';

  @override
  String get authUsernameLabel => 'Username';

  @override
  String get authUsernameRequired => 'Inserisci un nome utente';

  @override
  String get authUsernameTooShort =>
      'Il nome utente deve contenere almeno 3 caratteri';

  @override
  String get authErrorConnection =>
      'Si è verificato un errore. Si prega di controllare la connessione internet e riprovare.';

  @override
  String get authErrorConnectionRelaunch =>
      'Si è verificato un errore. Controlla la tua connessione internet e riavvia l\'app.';

  @override
  String get authAccountManagement =>
      'Aggiungi, rimuovi e riordina i tuoi account Clash of Clans. Verifica i tuoi account per accedere a tutte le funzionalità.';

  @override
  String get authAccountConnected => 'Account Connessi';

  @override
  String get authAccountConnectedStatus => 'Connesso';

  @override
  String get authAccountNotConnected => 'Non connesso';

  @override
  String get authAccountEmailAndPassword => 'Email E Password';

  @override
  String get authAccountSecured =>
      'Il tuo account è protetto con più metodi di autenticazione';

  @override
  String get authAccountLinkEmail => 'Collega Account Email';

  @override
  String get authAccountAddEmailAuth =>
      'Aggiungi l\'autenticazione email e password al tuo account per maggiore sicurezza.';

  @override
  String get authAccountEmailLinkedSuccess =>
      'Account email collegato con successo!';

  @override
  String get helpTitle => 'Hai bisogno di aiuto?';

  @override
  String get helpJoinDiscord => 'Unisciti A Discord';

  @override
  String get helpEmailUs => 'Mandaci Una Email';

  @override
  String get accountsWelcome => 'Benvenuto!';

  @override
  String get accountsWelcomeMessage =>
      'Aggiungi uno o più account Clash of Clans al tuo profilo. Puoi aggiungere o rimuovere account in seguito.';

  @override
  String get accountsManageTitle => 'Gestisci i tuoi account';

  @override
  String get accountsNoneFound =>
      'Nessun account collegato al tuo profilo trovato';

  @override
  String get accountsPlayerTag => 'Tag Del Giocatore (#Abc123)';

  @override
  String get accountsEnterPlayerTag => 'Inserisci un tag giocatore';

  @override
  String get accountsAdd => 'Aggiungi account';

  @override
  String get accountsDelete => 'Elimina account';

  @override
  String get accountsApiToken => 'Account API Token';

  @override
  String get accountsEnterApiToken =>
      'Inserisci il token API dell\'account per confermare che è tuo. Puoi trovarlo in Impostazioni di Clash of Clans > Altre impostazioni > Token API.';

  @override
  String get accountsFillAllFields => 'Riempire tutti i campi.';

  @override
  String get accountsErrorTagNotExists =>
      'Il tag del giocatore inserito non esiste.';

  @override
  String accountsErrorAlreadyLinked(Object tag) {
    return 'Il tag del giocatore è già collegato a qualcuno.';
  }

  @override
  String get accountsErrorAlreadyLinkedToYou =>
      'Il tag del giocatore è già collegato a te.';

  @override
  String get accountsErrorWrongApiToken =>
      'Il token API inserito non è corretto';

  @override
  String get accountsErrorFailedToAdd =>
      'Impossibile aggiungere l\'account. Riprova più tardi.';

  @override
  String get accountsErrorFailedToDelete =>
      'Impossibile eliminare il link. Riprova più tardi.';

  @override
  String get accountsErrorFailedToUpdateOrder =>
      'Impossibile aggiornare l\'ordine degli account.';

  @override
  String get errorTitle =>
      'Ops! I nostri server potrebbero aver preso una palla di fuoco in faccia! Stiamo lanciando un incantesimo di guarigione... Riprova tra un attimo.';

  @override
  String get errorSubtitle =>
      'Se il problema persiste, controllare il nostro Server Discord per vedere se ne siamo a conoscenza.';

  @override
  String get errorLoadingVersion => 'Errore nel caricamento della versione';

  @override
  String get errorCannotOpenLink => 'Non possiamo aprire questo link.';

  @override
  String get errorExitAppToOpenClash =>
      'Stai per lasciare l\'applicazione per aprire Clash of Clans.';

  @override
  String get playerSearchTitle => 'Cerca giocatore';

  @override
  String get playerSearchPlaceholder => 'Nome o tag del giocatore';

  @override
  String playerLastActive(String date) {
    return 'Ultimo attivo: $date';
  }

  @override
  String get playerNotTracked =>
      'Questo giocatore non è tracciato. I dati potrebbero essere imprecisi.';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Il tuo clan è \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(
      String ratio, String donations, String received) {
    return 'Your donation ratio is $ratio. You have donated $donations troops and received $received troops.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'La tua preferenza di guerra è \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'You have $stars war stars.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'Hai trofei $trophies . Attualmente sei in $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Your Town Hall level is $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Il tuo livello di Sala del Costruttore è $level e hai dei trofei $trophies.';
  }

  @override
  String get gameBaseHome => 'Home Base';

  @override
  String get gameBaseBuilder => 'Base Del Costruttore';

  @override
  String get gameClanCapital => 'Capitale Del Clan';

  @override
  String get gameTownHall => 'TH';

  @override
  String get gameTownHallLevel => 'Livello TH';

  @override
  String gameTownHallLevelNumber(int level) {
    return 'Municipio $level';
  }

  @override
  String gameTHLevel(int level) {
    return 'TH$level';
  }

  @override
  String get gameExpLevel => 'Livello Di Esperienza';

  @override
  String get gameTrophies => 'Trofei';

  @override
  String get gameBuilderBaseTrophies => 'Trofei BB';

  @override
  String get gameDonations => 'Donazioni';

  @override
  String get gameDonationsReceived => 'Donazioni Ricevute';

  @override
  String get gameDonationsRatio => 'Rapporto Donazioni';

  @override
  String gameLevel(int level, int maxLevel) {
    return 'Livello: $level/$maxLevel';
  }

  @override
  String get gameHeroes => 'Eroi';

  @override
  String get gameEquipment => 'Attrezzature';

  @override
  String get gameHeroesEquipments => 'Equipaggiamenti eroe';

  @override
  String get gameTroops => 'Truppe';

  @override
  String get gameActiveSuperTroops => 'Super Truppe Attive';

  @override
  String get gamePets => 'Animali';

  @override
  String get gameSiegeMachines => 'Macchine D\'Assedio';

  @override
  String get gameSpells => 'Spells';

  @override
  String get gameAchievements => 'Risultati';

  @override
  String get gameClanGames => 'Clan Games';

  @override
  String get gameSeasonPass => 'Season Pass';

  @override
  String get gameCreatorCode => 'Codice Creatore: ClashKing';

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
  String get clanSearchTitle => 'Cerca clan';

  @override
  String get clanSearchPlaceholder => 'Nome del Clan';

  @override
  String get clanNone => 'Nessun clan';

  @override
  String get clanJoinToUnlock =>
      'Unisciti a un clan per sbloccare nuove funzionalità.';

  @override
  String get clanMembers => 'Membri';

  @override
  String get clanWarFrequency => 'Frequenza di guerra';

  @override
  String get clanMinimumMembers => 'Membri minimi';

  @override
  String get clanMaximumMembers => 'Numero massimo di membri';

  @override
  String get clanLocation => 'Posizione';

  @override
  String get clanMinimumPoints => 'Punti di clan minimi';

  @override
  String get clanMinimumLevel => 'Livello minimo di clan';

  @override
  String get clanInviteOnly => 'Solo Invito';

  @override
  String get clanOpened => 'Aperto';

  @override
  String get clanClosed => 'Chiuso';

  @override
  String get clanRoleLeader => 'Leader';

  @override
  String get clanRoleCoLeader => 'Co-Leader';

  @override
  String get clanRoleElder => 'Anziano';

  @override
  String get clanRoleMember => 'Membro';

  @override
  String get clanWarFrequencyAlways => 'Sempre';

  @override
  String get clanWarFrequencyNever => 'Mai';

  @override
  String get clanWarFrequencyUnknown => 'Sconosciuto';

  @override
  String get clanWarFrequencyOncePerWeek => '1/settimana';

  @override
  String get clanWarFrequencyMoreThanOncePerWeek => 'Più di una settimana';

  @override
  String get clanWarFrequencyRarely => 'Raramente';

  @override
  String get timeHourIndicator => 'h';

  @override
  String timeDaysAgo(int days) {
    return '$days giorni fa';
  }

  @override
  String timeDayAgo(int day) {
    return '$day giorno fa';
  }

  @override
  String timeHourAgo(int hour) {
    return '$hour ora fa';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours ore fa';
  }

  @override
  String timeMinuteAgo(int minute) {
    return '$minute minuto fa';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes minuti fa';
  }

  @override
  String get timeJustNow => 'Solo Ora';

  @override
  String get timeEndedJustNow => 'Finito proprio ora';

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
    return 'Inizia in $time';
  }

  @override
  String timeStartsAt(String time) {
    return 'Starts at $time';
  }

  @override
  String timeEndsIn(String time) {
    return 'Termina in $time';
  }

  @override
  String timeEndsAt(String time) {
    return 'Termina ad $time';
  }

  @override
  String get legendsTitle => 'Leggenda League';

  @override
  String get legendsNotInLeague => 'Non in Leggenda League';

  @override
  String get legendsNoDataToday =>
      'Non sei in Legend League, ma le passate stagioni sono disponibili.';

  @override
  String legendsStartDescription(String trophies) {
    return 'Hai iniziato la giornata con i trofei $trophies.';
  }

  @override
  String legendsNoRankLocalDescription(String country, int trophies) {
    return 'Attualmente non sei classificato ($country) con i trofei $trophies.';
  }

  @override
  String legendsRankLocalDescription(int rank, String country, int trophies) {
    return 'Attualmente sei classificato $rank ($country) con trofei $trophies.';
  }

  @override
  String legendsGainDescription(int trophies) {
    return 'Hai guadagnato trofei $trophies per ora.';
  }

  @override
  String legendsLossDescription(int trophies) {
    return 'Hai perso i trofei $trophies per ora.';
  }

  @override
  String legendsNoGlobalRankDescription(int trophies) {
    return 'Attualmente non sei classificato globalmente con i trofei $trophies.';
  }

  @override
  String legendsGlobalRankDescription(int rank, int trophies) {
    return 'You are currently ranked $rank globally with $trophies trophies.';
  }

  @override
  String get legendsNoRank => 'Nessuna classifica';

  @override
  String get legendsBestTrophies => 'Migliori Trofei';

  @override
  String get legendsMostAttacks => 'Più Attacchi';

  @override
  String get legendsLastSeason => 'Ultima Stagione';

  @override
  String get legendsBestRank => 'Miglior Rango Globale';

  @override
  String get legendsTrophiesBySeason => 'Trofei per stagione';

  @override
  String get legendsEosTrophies => 'Trofei Di Fine Stagione';

  @override
  String get legendsEosDetails => 'Dettagli Di Fine Stagione';

  @override
  String get legendsInaccurateTitle => 'Dati inaccurati?';

  @override
  String get legendsInaccurateIntro =>
      'A causa delle limitazioni dell\'API Clash of Clans, i nostri dati potrebbero non essere sempre perfettamente accurati. Ecco perché:\n';

  @override
  String get legendsInaccurateApiDelayTitle => '1. Ritardo Api: ';

  @override
  String get legendsInaccurateApiDelayBody =>
      'L\'API può richiedere fino a 5 minuti per aggiornare, causando un ritardo nel riflettere i cambiamenti del trofeo in tempo reale.\n';

  @override
  String get legendsInaccurateConcurrentTitle => '2. Modifiche Concorrenti: \n';

  @override
  String get legendsInaccurateMultipleAttacksTitle =>
      '- Attacchi Multipli/Difese: ';

  @override
  String get legendsInaccurateMultipleAttacksBody =>
      'Se più attacchi o difese avvengono in rapida successione, l\'API potrebbe mostrare risultati combinati (ad esempio, +68 o -68).\n';

  @override
  String get legendsInaccurateSimultaneousTitle =>
      '- Attacco e difesa simultanea: ';

  @override
  String get legendsInaccurateSimultaneousBody =>
      'Se un attacco e una difesa si verificano allo stesso tempo, si potrebbe vedere un risultato misto (ad esempio, +4).\n';

  @override
  String get legendsInaccurateNetGainTitle => '3. Guadagno Netto: ';

  @override
  String get legendsInaccurateNetGainBody =>
      'Nonostante i problemi di tempistica, il guadagno netto complessivo o la perdita per il giorno è accurato. ';

  @override
  String get legendsInaccurateConclusion =>
      'Queste limitazioni sono comuni a tutti gli strumenti che utilizzano l\'API Clash of Clans. Purtroppo non possiamo risolvere questo problema come è nelle mani di Supercell. Facciamo del nostro meglio per compensare questi limiti e fornire risultati il più vicino possibile alla realtà. Grazie per la comprensione!';

  @override
  String get statsSeasonStats => 'Statistiche Stagione';

  @override
  String get statsByDay => 'Per Giorno';

  @override
  String get statsBySeason => 'Per Stagione';

  @override
  String statsDayIndex(int index) {
    return 'Giorno $index';
  }

  @override
  String statsIndexDays(int index) {
    return '$index giorni';
  }

  @override
  String statsSeasonDate(String date) {
    return '$date stagione';
  }

  @override
  String get statsAllTownHalls => 'Tutti I Municipi';

  @override
  String get statsMembers => 'Statistiche Membri';

  @override
  String get todoTitle => 'Elenco cose da fare';

  @override
  String get todoExplanationTitle => 'Calcolo Attività';

  @override
  String get todoExplanationIntro =>
      'La percentuale di completamento del compito è calcolata sulla base delle seguenti attività con ponderazioni specifiche:';

  @override
  String get todoExplanationLegendsTitle => 'Leggenda Legenda:';

  @override
  String get todoExplanationLegends =>
      'Peso di 8 punti per account, 1 attacco = 1 punto.';

  @override
  String get todoExplanationRaidsTitle => 'Corsi:';

  @override
  String get todoExplanationRaids =>
      'Peso di 5 punti per conto (o 6 se l\'ultimo attacco è stato sbloccato), 1 attacco = 1 punto.';

  @override
  String get todoExplanationClanWarsTitle => 'Guerre Del Clan:';

  @override
  String get todoExplanationClanWars =>
      'Peso di 2 punti per account, 1 attacco = 1 punto.';

  @override
  String get todoExplanationCwlTitle => 'Campionato Di Guerra Del Clan:';

  @override
  String get todoExplanationCwl =>
      'Peso di 1 punto per account, 1 attacco = 1 punto. CWL non può essere tracciato se il giocatore non è nel loro clan di campionato.';

  @override
  String get todoExplanationPassAndGamesTitle => 'Season Pass & Clan Games:';

  @override
  String get todoExplanationPassAndGames =>
      'Peso di 2 punti ciascuno per conto. Il rapporto si basa sul numero di giorni rimanenti (1 mese per il pass e 6 giorni per i giochi). Verde = in pista per completare il passaggio o i giochi, rosso = in ritardo.';

  @override
  String get todoExplanationConclusion =>
      'La percentuale finale è calcolata dividendo le azioni totali completate durante gli eventi in corso per il totale delle azioni richieste. I conti inattivi per più di 14 giorni sono esclusi dal calcolo.';

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
  String get todoAccountsActive => 'Account attivi';

  @override
  String get todoAccountsInactive => 'Account inattivi';

  @override
  String get todoAccountsNoInactive => 'Nessun account inattivo.';

  @override
  String get todoAccountsNoActive => 'Nessun account attivo.';

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
    return 'Congratulazioni, hai fatto tutti i tuoi attacchi ($type)!';
  }

  @override
  String todoPointsLeftDescription(int points, String type) {
    return 'You have $points points left to get today to be in time for the end of the event ($type).';
  }

  @override
  String todoPointsLeftDescriptionNoPoints(String type) {
    return 'Congratulazioni, sei in tempo per ottenere i premi massimi alla fine dell\'evento ($type)!';
  }

  @override
  String get warTitle => 'Guerra';

  @override
  String get warFrequency => 'Frequenza di guerra';

  @override
  String get warParticipation => 'Partecipazione Guerra';

  @override
  String get warLeague => 'Guerra/Lega';

  @override
  String get warHistory => 'Cronologia Guerra';

  @override
  String get warLog => 'Registro Di Guerra';

  @override
  String warLogClosed(String clan) {
    return 'Il registro di guerra di $clanè chiuso.';
  }

  @override
  String get warStats => 'Statistiche Di Guerra';

  @override
  String get warOngoing => 'Guerra in corso';

  @override
  String warIsNotInWar(String clan) {
    return '$clan non è in guerra.';
  }

  @override
  String get warAskForWar =>
      'Contatta il leader o un co-leader per iniziare una guerra.';

  @override
  String get warAskForWarLogOpening =>
      'Contatta un leader o un co-leader per aprire il registro di guerra.';

  @override
  String get warEnded => 'Guerra terminata';

  @override
  String get warPreparation => 'Preparazione';

  @override
  String get warPerfectWar => 'Guerra perfetta';

  @override
  String get warVictory => 'Vittoria';

  @override
  String get warDefeat => 'Sconfitta';

  @override
  String get warDraw => 'Disegna';

  @override
  String get warTeamSize => 'Dimensione della squadra';

  @override
  String get warMyTeam => 'La mia squadra';

  @override
  String get warEnemiesTeam => 'Enemies';

  @override
  String get warClanDraw => 'I due clan sono legati';

  @override
  String get warStateOfTheWar => 'Stato della guerra';

  @override
  String warStarsNeededToTakeTheLead(
      String clan, int star, int stars2, String percent) {
    return '$clan ha ancora bisogno di $star più stelle o $stars2 stelle e $percent% per prendere il comando.';
  }

  @override
  String warStarsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan ha ancora bisogno di $percent% o 1 stella in più per prendere il comando';
  }

  @override
  String get warNoDataAvailableForThisWar =>
      'Nessun dato disponibile per questa guerra';

  @override
  String get warCalculatorFast => 'Calcolatrice veloce';

  @override
  String warCalculatorAnswer(String percentNeeded, String result) {
    return 'Per ottenere un tasso di distruzione di $percentNeeded%, è necessario un totale di $result%.';
  }

  @override
  String get warCalculatorNeededOverall => '% complessivo necessario';

  @override
  String get warCalculatorCalculate => 'Calcola';

  @override
  String get warAttacksTitle => 'Attacchi';

  @override
  String get warAttacksNone => 'Ancora nessun attacco';

  @override
  String get warAttacksBest => 'Migliori attacchi';

  @override
  String get warAttacksCount => 'Conteggio Attacchi';

  @override
  String get warAttacksMissed => 'Attacchi Persi';

  @override
  String warAttacksNumber(int number_time, int number_war) {
    return 'You attacked $number_time time(s) during the last $number_war wars.';
  }

  @override
  String warAttacksAverageStars(String stars) {
    return 'Hai avuto una media di $stars stelle per guerra.';
  }

  @override
  String warAttacksAverageDestruction(String percent) {
    return 'Hai avuto una media di $percent% tasso di distruzione per guerra.';
  }

  @override
  String get warDefensesTitle => 'Difese';

  @override
  String get warDefensesNone => 'Ancora nessuna difesa';

  @override
  String get warDefensesBest => 'Migliori difese';

  @override
  String warDefensesBestOutOf(int number) {
    return 'Migliore difesa (fuori da $number)';
  }

  @override
  String warDefensesNumber(int number_time, int number_war) {
    return 'You defended $number_time time(s) during the last $number_war wars.';
  }

  @override
  String warDefensesAverageStars(double stars) {
    return 'Hai avuto una media di $stars stelle per difesa.';
  }

  @override
  String warDefensesAverageDestruction(String percent) {
    return 'Hai avuto una media di $percent% tasso di distruzione per difesa.';
  }

  @override
  String get warStarsTitle => 'Stelle';

  @override
  String get warStarsAverage => 'Stelle medie';

  @override
  String get warStarsNumber => 'Numero di stelle';

  @override
  String get warStarsOne => '1 stella';

  @override
  String get warStarsTwo => '2 stelle';

  @override
  String get warStarsThree => '3 stelle';

  @override
  String get warStarsZero => '0 Stella';

  @override
  String get warStarsBestPerformance => 'Migliori prestazioni';

  @override
  String get warDestructionTitle => 'Distruzione';

  @override
  String get warDestructionAverage => 'Distruzione media';

  @override
  String get warDestructionRate => 'Tasso di distruzione';

  @override
  String warHistoryWinsDescription(int wins, String percent) {
    return 'Il tuo clan ha vinto le guerre $wins ($percent%) sulle ultime 50 guerre.';
  }

  @override
  String warHistoryLossesDescription(int losses, String percent) {
    return 'Il tuo clan ha perso le guerre di $losses ($percent%) sulle ultime 50 guerre.';
  }

  @override
  String warHistoryDrawsDescription(int draws, String percent) {
    return 'Il tuo clan aveva $draws disegna ($percent%) sulle ultime 50 guerre.';
  }

  @override
  String warHistoryAverageMembersDescription(int members) {
    return 'Il tuo clan ha una media di $members membri che partecipano alle ultime 50 guerre.';
  }

  @override
  String warHistoryAverageWarStarsDescription(double stars, String percent) {
    return 'Il tuo clan aveva una media di $stars stelle per guerra dalle ultime 50 guerre. Rappresenta $percent delle stelle totali.';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return 'Il tuo clan ha avuto una media di $percent% tasso di distruzione dalle ultime 50 guerre.';
  }

  @override
  String get warPositionMap => 'Posizione Mappa';

  @override
  String get warPositionAbbr => 'Pos';

  @override
  String get warPositionOrder => 'Ordine';

  @override
  String get warOpponentTownhall => 'Opp TH';

  @override
  String get warOpponentLowerTownhall => 'TH Inferiore';

  @override
  String get warOpponentUpperTownhall => 'Th Superiore';

  @override
  String get warOpponentEqualThLevel => 'Uguale TH';

  @override
  String get warOpponentSelectMembersThLevel => 'Livello Membri Th';

  @override
  String get warOpponentSelectOpponentsThLevel => 'Avversari Livello Th';

  @override
  String warFiltersLastXwars(int number) {
    return 'Last $number wars';
  }

  @override
  String get warFiltersFriendly => 'Amichevole';

  @override
  String get warFiltersRandom => 'Casuale';

  @override
  String get warVisibilityToggleTownHall =>
      'Mostra/nascondi le statistiche dai livelli TH precedenti';

  @override
  String get warEventsTitle => 'Eventi';

  @override
  String get warEventsNewest => 'Più Recenti';

  @override
  String get warEventsOldest => 'Vecchio';

  @override
  String get warStatusReady => 'Opted In';

  @override
  String get warStatusUnready => 'Opted Out';

  @override
  String get warStatusMissed => 'Perso';

  @override
  String get warAbbreviationAvg => 'Media';

  @override
  String get warAbbreviationAvgPercentage => 'Media %';

  @override
  String get cwlTitle => 'CWL';

  @override
  String get cwlClanWarLeague => 'Lega Di Guerra Del Clan';

  @override
  String get cwlOngoing => 'Cwl In Corso';

  @override
  String get cwlRounds => 'Proiettili';

  @override
  String cwlRoundNumber(int number) {
    return 'Round $number';
  }

  @override
  String cwlCurrentRound(int round) {
    return 'Round corrente ( $round)';
  }

  @override
  String cwlRank(int rank) {
    return 'Il tuo clan è attualmente classificato $rank.';
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
  String get joinLeaveTitle => 'Registri Di Entrata/Uscita (Stagione Attuale)';

  @override
  String get joinLeaveJoin => 'Entra';

  @override
  String get joinLeaveLeave => 'Abbandona';

  @override
  String get joinLeaveReset => 'Reset';

  @override
  String get joinLeaveJoins => 'Partecipa';

  @override
  String get joinLeaveLeaves => 'Foglie';

  @override
  String get joinLeaveUniquePlayers => 'Giocatori Unici';

  @override
  String get joinLeaveMovingPlayers => 'Giocatori In Movimento';

  @override
  String get joinLeaveMostMovingPlayers => 'Più Giocatori In Movimento';

  @override
  String get joinLeaveStillInClan => 'Ancora in clan';

  @override
  String get joinLeaveLeftForever => 'Sinistra Per Sempre';

  @override
  String get joinLeaveRejoinedPlayers => 'Giocatori Rientrati';

  @override
  String get joinLeaveAvgTimeJoinLeave => 'Tempo Media Di Entrata/Uscita';

  @override
  String get joinLeavePeakHour => 'Ora Più Attiva';

  @override
  String joinLeaveNumberDescription(int number, String date) {
    return '$number lascia gli eventi durante la stagione corrente ($date).';
  }

  @override
  String joinLeaveJoinNumberDescription(int number, String date) {
    return '$number join events occurred during the current season ($date).';
  }

  @override
  String joinLeaveMovingNumberDescription(int number, String date) {
    return '$number giocatore(i) partito(i) e rientrato nel clan durante la stagione corrente ($date).';
  }

  @override
  String joinLeaveUniqueNumberDescription(int number, String date) {
    return '$number giocatori unici si sono uniti/hanno lasciato il clan durante la stagione corrente ($date).';
  }

  @override
  String joinLeaveStillInClanNumberDescription(int number) {
    return '$number giocatore/i entrato/i e sono ancora nel clan.';
  }

  @override
  String joinLeaveLeftClanNumberDescription(int number) {
    return '$number giocatore(i) entrato, poi ha lasciato il clan e non si è mai rientrato.';
  }

  @override
  String joinLeaveLeftOnAt(String date, String time) {
    return 'Sinistra su $date a $time.';
  }

  @override
  String joinLeaveJoinedOnAt(String date, String time) {
    return 'Entrato il $date a $time.';
  }

  @override
  String get raidsTitle => 'Incursori';

  @override
  String get raidsLast => 'Ultimi raid';

  @override
  String get raidsOngoing => 'Incursioni in corso';

  @override
  String get raidsDistrictsDestroyed => 'Distretti distrutti';

  @override
  String get raidsCompleted => 'Incursioni completate';

  @override
  String get searchNoResult => 'Nessun risultato.';

  @override
  String get maintenanceTitle => 'Manutenzione';

  @override
  String get maintenanceDescription =>
      'Clash of Clans è attualmente in manutenzione, quindi non possiamo accedere all\'API. Per favore riprova più tardi.';

  @override
  String get downloadTooltip => 'Scarica sommario CWL';

  @override
  String get downloadInProgress =>
      'Scaricamento file... Ci possono volere alcuni secondi...';

  @override
  String downloadSuccess(String path) {
    return 'File salvato correttamente in $path';
  }

  @override
  String get downloadError => 'Impossibile scaricare il file';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get toolsTitle => 'Strumenti';

  @override
  String get navigationTeam => 'Team';

  @override
  String get navigationStatistics => 'Statistiche';

  @override
  String get versionDevice => 'Versione E Dispositivo';

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
  String get betaFeature => 'Funzione Beta';

  @override
  String get betaLabel => 'BETA';

  @override
  String get betaDescription =>
      'Questa funzione è attualmente in beta, potrebbe avere alcuni bug o essere incompleta. Stiamo lavorando attivamente ai miglioramenti e accogliamo con favore il tuo feedback. Condividere le proprie idee e segnalare eventuali problemi nel nostro Server Discord per aiutarci a migliorarle.';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsSelectLanguage => 'Seleziona una lingua';

  @override
  String get settingsToggleTheme => 'Attiva/Disattiva Tema';

  @override
  String get faqTitle => 'FAQ';

  @override
  String get faqSubtitle => 'Domande Frequenti';

  @override
  String get faqIsThisFromSupercell => 'Questa app è da Supercell?';

  @override
  String get faqFanContentPolicy =>
      'Questo materiale non è ufficiale e non è approvato da Supercell. Per maggiori informazioni consulta la Politica dei Contenuti di Ventilatore di Supercell: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate =>
      'Perché i dati sono talvolta inesatti o mancanti?';

  @override
  String get faqClanNotTracked => 'Clan non tracciato';

  @override
  String get faqClanNotTrackedAnswer =>
      'ClashKing può recuperare queste informazioni solo se il clan viene tracciato. Se il tuo clan non è tracciato, invita il ClashKing Bot al tuo Server Discord e utilizza il comando /addclan. Stiamo lavorando per rendere questa funzione disponibile nell\'app presto.';

  @override
  String get faqTrackingDown => 'Tracciamento giù';

  @override
  String get faqTrackingDownAnswer =>
      'Il tracciamento può smettere di funzionare per un certo periodo di tempo. Questo è il motivo per cui a volte si possono avere buchi nei tuoi dati. Stiamo lavorando per migliorare questo.';

  @override
  String get faqApiLimitation => 'Limitazione API Clash of Clans';

  @override
  String get faqApiLimitationAnswer =>
      'Alcuni dati sono forniti da Clash of Clans e le loro API hanno alcune limitazioni. Questo è il caso per il tracciamento delle leggende, a volte impila il guadagno e la perdita del trofeo come se fosse un singolo attacco. Questo è anche il motivo per cui non abbiamo alcuna informazione sui livelli di edificio.';

  @override
  String get faqSupportWork => 'Come posso sostenere il vostro lavoro?';

  @override
  String get faqSupportWorkAnswer => 'Ci sono diversi modi per sostenerci:';

  @override
  String get faqUseCodeClashKing => 'Usa il codice \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Sostienici su Patreon';

  @override
  String get faqShareTheApp => 'Condividi l\'app con i tuoi amici';

  @override
  String get faqRateTheApp => 'Vota l\'app nel negozio';

  @override
  String get faqHelpUsTranslate => 'Aiutaci a tradurre l\'app';

  @override
  String get faqHowToInviteTheBot =>
      'Come posso invitare il tuo bot al mio Server Discord?';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'Puoi invitare il nostro bot al tuo server cliccando sul pulsante qui sotto. Avrai bisogno dell\'autorizzazione \"Gestisci server\" per aggiungere il bot.';

  @override
  String get faqInviteTheBot => 'Invite ClashKing Bot';

  @override
  String get faqNeedHelp =>
      'Ho bisogno di aiuto o vorrei fare un suggerimento. Come posso contattarti?';

  @override
  String get faqNeedHelpAnswer =>
      'You can join our Discord Server to ask for help or to provide feedback, or you can email us at devs@clashk.ing. Please only write in English or French.';

  @override
  String get faqSendEmail => 'Invia un\'email';

  @override
  String get faqJoinDiscord => 'Unisciti al nostro Server Discord';

  @override
  String get faqCannotOpenMailClient =>
      'Per alcuni motivi non possiamo aprire il tuo client di posta. Abbiamo copiato l\'indirizzo email per te. È possibile scrivere una e-mail e incollare l\'indirizzo nel campo destinatario.';

  @override
  String get translationHelpUsTranslate => 'Aiutaci a tradurre';

  @override
  String get translationSuggestFeatures => 'Suggerisci funzionalità';

  @override
  String get translationThankYou => 'Grazie!';

  @override
  String get translationThankYouContent =>
      'Un grazie enorme a tutti i nostri incredibili traduttori che ci aiutano a rendere questa app accessibile a più persone in tutto il mondo!';

  @override
  String get translationHelpTranslateContent =>
      'Puoi aiutarci a tradurre l\'app su Crowdin. Se la tua lingua non è disponibile su Crowdin, sentiti libero di richiederla nel nostro Server Discord. Grazie mille per il tuo aiuto!';

  @override
  String get translationHelpTranslateButton => 'Aiuta a tradurre su Crowdin';

  @override
  String get translationCurrentTranslators => 'Traduttori Attuali';
}
