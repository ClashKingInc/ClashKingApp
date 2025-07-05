// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'ClashKing';

  @override
  String get appDescription =>
      'Dein ultimativer Clash of Clans Begleiter zum Verfolgen von Statistiken, Verwalten von Clans und Analysieren der Leistung.';

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
  String get generalRetry => 'Wiederholen';

  @override
  String get generalTryAgain => 'Versuche es später nochmal';

  @override
  String get generalCancel => 'Abbrechen';

  @override
  String get generalOk => 'OK';

  @override
  String get generalApply => 'Anwenden';

  @override
  String get generalConfirm => 'Bestätigen';

  @override
  String get generalManage => 'Verwalten';

  @override
  String get generalSettings => 'Einstellungen';

  @override
  String get generalCopiedToClipboard => 'In die Zwischenablage kopiert';

  @override
  String get generalComingSoon => 'Bald verfügbar!';

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
  String get generalTotal => 'Insgesamt';

  @override
  String get generalBest => 'Beste';

  @override
  String get generalWorst => 'Schlechteste';

  @override
  String get generalAverage => 'Durchschnitt';

  @override
  String get generalRemaining => 'Verbleibend';

  @override
  String get generalActive => 'Aktiv';

  @override
  String get generalInactive => 'Inaktiv';

  @override
  String get generalStarted => 'Begonnen';

  @override
  String get generalEnded => 'Beendet';

  @override
  String get generalRole => 'Rolle';

  @override
  String get generalStats => 'Statistiken';

  @override
  String get generalFullStats => 'Vollständige Statistiken';

  @override
  String get generalDetails => 'Details';

  @override
  String get generalHistory => 'Verlauf';

  @override
  String get generalFilters => 'Filter';

  @override
  String get generalNotSet => 'Nicht festgelegt';

  @override
  String get generalWarning => 'Warnung';

  @override
  String get generalNoDataAvailable => 'Keine Daten verfügbar.';

  @override
  String get authSignUp => 'Registrieren';

  @override
  String get authLogin => 'Anmelden';

  @override
  String get authLogout => 'Abmelden';

  @override
  String get authCreateAccount => 'Konto erstellen';

  @override
  String get authJoinClashKing => 'ClashKing beitreten';

  @override
  String get authCreateClashKingAccount => 'ClashKing-Konto erstellen';

  @override
  String get authCreateAccountToGetStarted =>
      'Erstelle dein Konto, um zu beginnen';

  @override
  String get authAlreadyHaveAccount =>
      'Du hast bereits ein Konto? Melde dich an';

  @override
  String get authConfirmLogout =>
      'Bist du dir sicher, dass du dich abmelden möchtest?';

  @override
  String get authDiscordTitle => 'Discord';

  @override
  String get authDiscordSignIn => 'Mit Discord anmelden';

  @override
  String get authDiscordContinue => 'Mit Discord fortfahren';

  @override
  String get authDiscordDescription =>
      'Synchronisiere deine Daten mit dem ClashKing Bot und entfalte das volle Potenzial von ClashKing!';

  @override
  String get authEmailTitle => 'E-Mail';

  @override
  String get authEmailDescription =>
      'Verwende E-Mail, wenn du nicht auf Discord zugreifen kannst oder nur App-Funktionen bevorzugst';

  @override
  String get authEmailRequired => 'Bitte gib deine E-Mail ein';

  @override
  String get authEmailInvalid => 'Bitte gib eine gültige E-Mail ein';

  @override
  String get authPasswordLabel => 'Passwort';

  @override
  String get authPasswordConfirm => 'Passwort bestätigen';

  @override
  String get authPasswordRequired => 'Bitte gib dein Passwort ein';

  @override
  String get authPasswordConfirmRequired => 'Bitte bestätige dein Passwort';

  @override
  String get authPasswordMismatch => 'Passwörter stimmen nicht überein';

  @override
  String get authPasswordTooShort =>
      'Passwort muss mindestens 8 Zeichen lang sein';

  @override
  String get authPasswordRequirements =>
      'Passwort muss enthalten: Großbuchstaben, Kleinbuchstaben, Ziffer und Sonderzeichen';

  @override
  String get authPasswordForgot => 'Passwort vergessen?';

  @override
  String get authUsernameLabel => 'Benutzername';

  @override
  String get authUsernameRequired => 'Bitte gib einen Benutzernamen ein';

  @override
  String get authUsernameTooShort =>
      'Benutzername muss mindestens 3 Zeichen lang sein';

  @override
  String get authErrorConnection =>
      'Es ist ein Fehler aufgetreten. Bitte überprüfe deine Internetverbindung und versuche es erneut.';

  @override
  String get authErrorConnectionRelaunch =>
      'Es ist ein Fehler aufgetreten. Bitte überprüfe deine Internetverbindung und starte die App erneut.';

  @override
  String get authAccountManagement => 'Kontoverwaltung';

  @override
  String get authAccountConnected => 'Verbundene Konten';

  @override
  String get authAccountConnectedStatus => 'Verbunden';

  @override
  String get authAccountNotConnected => 'Nicht verbunden';

  @override
  String get authAccountEmailAndPassword => 'E-Mail & Passwort';

  @override
  String get authAccountSecured =>
      'Dein Konto ist mit mehreren Authentifizierungsmethoden gesichert';

  @override
  String get authAccountLinkEmail => 'E-Mail-Konto verknüpfen';

  @override
  String get authAccountAddEmailAuth =>
      'Füge E-Mail- & Passwort-Authentifizierung zu deinem Konto für zusätzliche Sicherheit hinzu.';

  @override
  String get authAccountEmailLinkedSuccess =>
      'E-Mail-Konto erfolgreich verknüpft!';

  @override
  String get helpTitle => 'Brauchst du Hilfe?';

  @override
  String get helpJoinDiscord => 'Discord beitreten';

  @override
  String get helpEmailUs => 'E-Mail an uns';

  @override
  String get accountsWelcome => 'Willkommen!';

  @override
  String get accountsWelcomeMessage =>
      'Bitte füge ein oder mehrere Clash of Clans Konten zu deinem Profil hinzu. Du kannst später weitere Konten hinzufügen oder entfernen.';

  @override
  String get accountsManageTitle => 'Verwalte deine Konten';

  @override
  String get accountsNoneFound =>
      'Kein mit deinem Profil verknüpftes Konto gefunden';

  @override
  String get accountsPlayerTag => 'Player Tag (#ABC123)';

  @override
  String get accountsEnterPlayerTag => 'Spielertag eingeben';

  @override
  String get accountsAdd => 'Konto hinzufügen';

  @override
  String get accountsDelete => 'Konto löschen';

  @override
  String get accountsApiToken => 'Konto API-Token';

  @override
  String get accountsEnterApiToken =>
      'Bitte gib einen API-Token ein, um zu bestätigen, dass das Konto dir gehört. Du findest ihn in Clash of Clans unter Einstellungen > Weitere Einstellungen > API-Token.';

  @override
  String get accountsFillAllFields => 'Bitte fülle alle Felder aus.';

  @override
  String get accountsErrorTagNotExists =>
      'Der eingegebene Spielertag existiert nicht.';

  @override
  String accountsErrorAlreadyLinked(Object tag) {
    return 'Dieser Spielertag ist bereits mit jemand anderem verknüpft.';
  }

  @override
  String get accountsErrorAlreadyLinkedToYou =>
      'Der Spielertag ist bereits mit dir verknüpft.';

  @override
  String get accountsErrorWrongApiToken =>
      'Der eingegebene API-Token ist falsch';

  @override
  String get accountsErrorFailedToAdd =>
      'Konto konnte nicht hinzugefügt werden. Bitte versuche es später erneut.';

  @override
  String get accountsErrorFailedToDelete =>
      'Fehler beim Löschen der Verknüpfung. Bitte versuche es später erneut.';

  @override
  String get accountsErrorFailedToUpdateOrder =>
      'Reihenfolge der Konten konnte nicht aktualisiert werden.';

  @override
  String get errorTitle =>
      'Ups! Unsere Server haben vielleicht einen Feuerball ins Gesicht bekommen! Wir sprechen einen Heilzauber... Versuche es in einem Moment erneut.';

  @override
  String get errorSubtitle =>
      'Wenn das Problem weiterhin besteht, schaue auf unserem Discord-Server nach, ob wir davon wissen.';

  @override
  String get errorLoadingVersion => 'Fehler beim Laden der Version';

  @override
  String get errorCannotOpenLink => 'Wir können diesen Link nicht öffnen.';

  @override
  String get errorExitAppToOpenClash =>
      'Du verlässt die App, um Clash of Clans zu öffnen.';

  @override
  String get playerSearchTitle => 'Spieler suchen';

  @override
  String get playerSearchPlaceholder => 'Name oder Spielertag';

  @override
  String playerLastActive(String date) {
    return 'Zuletzt aktiv: $date';
  }

  @override
  String get playerNotTracked =>
      'Spieler wurde nicht erfasst. Die Daten könnten falsch sein.';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Dein Clan ist \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(
      String ratio, String donations, String received) {
    return 'Dein Spendenverhältnis beträgt $ratio. Du hast $donations Truppen gespendet und $received Truppen erhalten.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Deine Kriegspräferenz ist \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'Du hast $stars Kriegssterne.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'Du hast $trophies Trophäen. Du bist derzeit in der $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Dein Rathauslevel ist $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Dein Meisterhüttenlevel ist $level und du hast $trophies Trophäen.';
  }

  @override
  String get gameBaseHome => 'Heimatbasis';

  @override
  String get gameBaseBuilder => 'Bauarbeiterbasis';

  @override
  String get gameClanCapital => 'Clanstadt';

  @override
  String get gameTownHall => 'RH';

  @override
  String get gameTownHallLevel => 'RH Level';

  @override
  String gameTownHallLevelNumber(int level) {
    return 'Rathaus $level';
  }

  @override
  String gameTHLevel(int level) {
    return 'TH$level';
  }

  @override
  String get gameExpLevel => 'Erfahrungslevel';

  @override
  String get gameTrophies => 'Trophäen';

  @override
  String get gameBuilderBaseTrophies => 'BB-Trophäen';

  @override
  String get gameDonations => 'Gespendet';

  @override
  String get gameDonationsReceived => 'Spenden erhalten';

  @override
  String get gameDonationsRatio => 'Spendenverhältnis';

  @override
  String gameLevel(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get gameHeroes => 'Helden';

  @override
  String get gameEquipment => 'Ausrüstung';

  @override
  String get gameHeroesEquipments => 'Heldenausrüstung';

  @override
  String get gameTroops => 'Truppen';

  @override
  String get gameActiveSuperTroops => 'Aktive Supertruppen';

  @override
  String get gamePets => 'Begleiter';

  @override
  String get gameSiegeMachines => 'Belagerungsmaschinen';

  @override
  String get gameSpells => 'Zauber';

  @override
  String get gameAchievements => 'Errungenschaften';

  @override
  String get gameClanGames => 'Clan Games';

  @override
  String get gameSeasonPass => 'Season Pass';

  @override
  String get gameCreatorCode => 'Creator-Code: ClashKing';

  @override
  String get gameCreatorCodeDescription =>
      'Tippen für Info • Unterstütze uns kostenlos!';

  @override
  String get gameCreatorCodeDialogTitle => 'ClashKing unterstützen';

  @override
  String get gameCreatorCodeDialogDescription =>
      'Die Verwendung unseres Creator-Codes hilft bei der Finanzierung der Entwicklung, hält die App & Bot für alle kostenlos und ermöglicht es uns, neue Features hinzuzufügen.\n\nWir erhalten 5% von dem, was du im Spiel ausgibst, aber es kostet dich nichts extra - verwende einfach \"ClashKing\" als Creator-Code im Clash of Clans Shop!';

  @override
  String get gameCreatorCodeDialogButton => 'Creator-Code verwenden';

  @override
  String get clanTitle => 'Clan';

  @override
  String get clanSearchTitle => 'Clan suchen';

  @override
  String get clanSearchPlaceholder => 'Clanname';

  @override
  String get clanNone => 'Kein Clan';

  @override
  String get clanJoinToUnlock =>
      'Tritt einem Clan bei, um neue Funktionen freizuschalten.';

  @override
  String get clanMembers => 'Mitglieder';

  @override
  String get clanWarFrequency => 'Kriegshäufigkeit';

  @override
  String get clanMinimumMembers => 'Mindestanzahl von Mitgliedern';

  @override
  String get clanMaximumMembers => 'Maximale Anzahl von Mitgliedern';

  @override
  String get clanLocation => 'Standort';

  @override
  String get clanMinimumPoints => 'Minimale Clanpunkte';

  @override
  String get clanMinimumLevel => 'Erforderlicher Clanlevel';

  @override
  String get clanInviteOnly => 'Nur auf Einladung';

  @override
  String get clanOpened => 'Geöffnet';

  @override
  String get clanClosed => 'Geschlossen';

  @override
  String get clanRoleLeader => 'Anführer';

  @override
  String get clanRoleCoLeader => 'Vize-Anführer';

  @override
  String get clanRoleElder => 'Ältester';

  @override
  String get clanRoleMember => 'Mitglied';

  @override
  String get clanWarFrequencyAlways => 'Immer';

  @override
  String get clanWarFrequencyNever => 'Nie';

  @override
  String get clanWarFrequencyUnknown => 'Unbekannt';

  @override
  String get clanWarFrequencyOncePerWeek => 'Einmal pro Woche';

  @override
  String get clanWarFrequencyMoreThanOncePerWeek => 'Mehr als 1/Woche';

  @override
  String get clanWarFrequencyRarely => 'Selten';

  @override
  String get timeHourIndicator => 'Std.';

  @override
  String timeDaysAgo(int days) {
    return 'vor $days Tagen';
  }

  @override
  String timeDayAgo(int day) {
    return 'Vor $day Tag(en)';
  }

  @override
  String timeHourAgo(int hour) {
    return 'Vor $hour Stunde(n)';
  }

  @override
  String timeHoursAgo(int hours) {
    return 'vor $hours Stunden';
  }

  @override
  String timeMinuteAgo(int minute) {
    return 'Vor $minute Minute(n)';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return 'vor $minutes Minuten';
  }

  @override
  String get timeJustNow => 'Gerade eben';

  @override
  String get timeEndedJustNow => 'Gerade eben beendet';

  @override
  String timeEndedMinutesAgo(int minutes) {
    return 'Vor $minutes Minuten beendet';
  }

  @override
  String timeEndedHoursAgo(int hours) {
    return 'Vor $hours Stunden beendet';
  }

  @override
  String timeEndedDaysAgo(int days) {
    return 'Vor $days Tagen beendet';
  }

  @override
  String timeStartsIn(String time) {
    return 'Beginnt in $time';
  }

  @override
  String timeStartsAt(String time) {
    return 'Beginnt um $time';
  }

  @override
  String timeEndsIn(String time) {
    return 'Endet in $time';
  }

  @override
  String timeEndsAt(String time) {
    return 'Endet um $time';
  }

  @override
  String get legendsTitle => 'Falsche Daten?';

  @override
  String get legendsNotInLeague => 'Nicht in der Legenden-Liga';

  @override
  String get legendsNoDataToday =>
      'Du bist nicht in der Legenden-Liga, aber vergangene Saisons sind verfügbar.';

  @override
  String legendsStartDescription(String trophies) {
    return 'Du hast den Tag mit $trophies Trophäen begonnen.';
  }

  @override
  String legendsNoRankLocalDescription(String country, int trophies) {
    return 'Du hast derzeit keinen Rang ($country) mit $trophies Trophäen.';
  }

  @override
  String legendsRankLocalDescription(int rank, String country, int trophies) {
    return 'Du befindest dich derzeit auf Rang $rank ($country) mit $trophies Trophäen.';
  }

  @override
  String legendsGainDescription(int trophies) {
    return 'Du hast bisher $trophies Trophäen gewonnen.';
  }

  @override
  String legendsLossDescription(int trophies) {
    return 'Du hast bisher $trophies Trophäen verloren.';
  }

  @override
  String legendsNoGlobalRankDescription(int trophies) {
    return 'Du hast derzeit keinen globalen Rang mit $trophies Trophäen.';
  }

  @override
  String legendsGlobalRankDescription(int rank, int trophies) {
    return 'Du bist derzeit auf Rang $rank global mit $trophies Trophäen.';
  }

  @override
  String get legendsNoRank => 'Kein Ranking';

  @override
  String get legendsBestTrophies => 'Beste Trophäen';

  @override
  String get legendsMostAttacks => 'Meiste Angriffe';

  @override
  String get legendsLastSeason => 'Letzte Saison';

  @override
  String get legendsBestRank => 'Bester globaler Rang';

  @override
  String get legendsTrophiesBySeason => 'Trophäen nach Saison';

  @override
  String get legendsEosTrophies => 'Trophäen nach Saisonende';

  @override
  String get legendsEosDetails => 'Details zum Saisonende';

  @override
  String get legendsInaccurateTitle => 'Ungenaue Daten?';

  @override
  String get legendsInaccurateIntro =>
      'Aufgrund der begrenzten Clash of Clans API könnten unsere Daten nicht immer genau sein. Warum du hier siehst:\n';

  @override
  String get legendsInaccurateApiDelayTitle => '1. API-Verzögerung: ';

  @override
  String get legendsInaccurateApiDelayBody =>
      'Die API kann bis zu 5 Minuten für die Aktualisierung benötigen, was zu einer Verzögerung bei der Abbildung von Echtzeit-Trophäenänderungen führt.\n';

  @override
  String get legendsInaccurateConcurrentTitle =>
      '2. Gleichzeitige Änderungen: \n';

  @override
  String get legendsInaccurateMultipleAttacksTitle =>
      '- Mehrere Angriffe/Verteidigungen: ';

  @override
  String get legendsInaccurateMultipleAttacksBody =>
      'Wenn mehrere Angriffe oder Verteidigungen schnell hintereinander auftreten, kann die API kombinierte Ergebnisse anzeigen (z. B. +68 oder -68).\n';

  @override
  String get legendsInaccurateSimultaneousTitle =>
      '- Gleichzeitiger Angriff und Verteidigung: ';

  @override
  String get legendsInaccurateSimultaneousBody =>
      'Wenn ein Angriff und eine Verteidigung gleichzeitig auftreten, siehst du möglicherweise ein gemischtes Ergebnis (z.B. +4).\n';

  @override
  String get legendsInaccurateNetGainTitle => '3. Netto-Gewinn/Verlust: ';

  @override
  String get legendsInaccurateNetGainBody =>
      'Trotz zeitlicher Probleme ist der Netto-Gewinn/Verlust des Tages korrekt. ';

  @override
  String get legendsInaccurateConclusion =>
      'Diese Einschränkungen sind bei allen Tools, die die Clash of Clans API verwenden, üblich. Leider können wir das nicht beheben, da es in den Händen von Supercell liegt. Wir tun unser Bestes, um diese Grenzen auszugleichen und Ergebnisse so nah wie möglich an der Realität zu liefern. Vielen Dank für dein Verständnis!';

  @override
  String get statsSeasonStats => 'Saison-Statistiken';

  @override
  String get statsByDay => 'Nach Tag';

  @override
  String get statsBySeason => 'Nach Saison';

  @override
  String statsDayIndex(int index) {
    return 'Tag $index';
  }

  @override
  String statsIndexDays(int index) {
    return '$index Tage';
  }

  @override
  String statsSeasonDate(String date) {
    return '$date Saison';
  }

  @override
  String get statsAllTownHalls => 'Alle Rathäuser';

  @override
  String get statsMembers => 'Mitglieder Statistik';

  @override
  String get todoTitle => 'To-do-Liste';

  @override
  String get todoExplanationTitle => 'Aufgabenberechnung';

  @override
  String get todoExplanationIntro =>
      'Der Prozentsatz der Aufgabenvervollständigung wird anhand der folgenden Aktivitäten mit spezifischen Gewichtungen berechnet:';

  @override
  String get todoExplanationLegendsTitle => 'Legenden-Liga:';

  @override
  String get todoExplanationLegends =>
      'Gewicht von 8 Punkten pro Konto, 1 Angriff = 1 Punkt.';

  @override
  String get todoExplanationRaidsTitle => 'Überfälle:';

  @override
  String get todoExplanationRaids =>
      'Gewicht von 5 Punkten pro Konto (oder 6, wenn der letzte Angriff freigeschaltet wurde), 1 Angriff = 1 Punkt.';

  @override
  String get todoExplanationClanWarsTitle => 'Clan-Kriege:';

  @override
  String get todoExplanationClanWars =>
      'Gewicht von 2 Punkten pro Konto, 1 Angriff = 1 Punkt.';

  @override
  String get todoExplanationCwlTitle => 'Clankriegsliga:';

  @override
  String get todoExplanationCwl =>
      'Gewicht von 1 Punkt pro Konto, 1 Angriff = 1 Punkt. Clankriegsliga kann nicht verfolgt werden, wenn der Spieler nicht in seinem Ligaclan ist.';

  @override
  String get todoExplanationPassAndGamesTitle => 'Saisonpass & Clanspiele:';

  @override
  String get todoExplanationPassAndGames =>
      'Gewicht von jeweils 2 Punkten pro Konto. Das Verhältnis basiert auf der Anzahl der verbleibenden Tage (1 Monat für den Pass und 6 Tage für die Spiele). Grün = dabei, den Pass oder die Spiele abzuschließen, rot = hinter dem Zeitplan.';

  @override
  String get todoExplanationConclusion =>
      'Der endgültige Prozentsatz wird berechnet, indem die Gesamtanzahl der während laufender Ereignisse abgeschlossenen Aktionen durch die Gesamtanzahl der erforderlichen Aktionen geteilt wird. Konten, die seit mehr als 14 Tagen inaktiv sind, werden von der Berechnung ausgeschlossen.';

  @override
  String todoAccountsNumber(int number) {
    return '$number Konten';
  }

  @override
  String todoAccountsNumberActive(int number) {
    return '$number aktive Konten';
  }

  @override
  String todoAccountsNumberInactive(int number) {
    return '$number inaktive Konten';
  }

  @override
  String get todoAccountsActive => 'Aktive Konten';

  @override
  String get todoAccountsInactive => 'Inaktive Konten';

  @override
  String get todoAccountsNoInactive => 'Keine inaktiven Konten.';

  @override
  String get todoAccountsNoActive => 'Keine aktiven Konten.';

  @override
  String todoAttacksLeftDescription(int attacks, String type) {
    return 'Du hast noch $attacks Angriff(e) übrig ($type).';
  }

  @override
  String todoDefensesLeftDescription(int defenses, String type) {
    return 'Du hast noch $defenses Verteidigung(en) übrig ($type).';
  }

  @override
  String todoNoAttacksLeftDescription(String type) {
    return 'Glückwunsch, du hast alle deine Angriffe gemacht ($type)!';
  }

  @override
  String todoPointsLeftDescription(int points, String type) {
    return 'Du musst heute noch $points Punkte erreichen, um rechtzeitig für das Ende des Events zu sein ($type).';
  }

  @override
  String todoPointsLeftDescriptionNoPoints(String type) {
    return 'Glückwunsch, du bist rechtzeitig, um die maximalen Belohnungen am Ende des Events zu erhalten ($type)!';
  }

  @override
  String get warTitle => 'Krieg';

  @override
  String get warFrequency => 'Kriegshäufigkeit';

  @override
  String get warParticipation => 'Kriegsbeteiligung';

  @override
  String get warLeague => 'Krieg/Clankriegsliga';

  @override
  String get warHistory => 'Kriegsgeschichte';

  @override
  String get warLog => 'Kriegslog';

  @override
  String warLogClosed(String clan) {
    return '${clan}s Kriegslog ist geschlossen.';
  }

  @override
  String get warStats => 'Kriegsstatistiken';

  @override
  String get warOngoing => 'Laufender Krieg';

  @override
  String warIsNotInWar(String clan) {
    return '$clan befindet sich nicht im Krieg.';
  }

  @override
  String get warAskForWar =>
      'Kontaktiere den Anführer oder einen Vize-Anführer, um einen Krieg zu starten.';

  @override
  String get warAskForWarLogOpening =>
      'Kontaktiere den Anführer oder einen Vize-Anführer, um den Kriegslog öffentlich zu machen.';

  @override
  String get warEnded => 'Krieg beendet';

  @override
  String get warPreparation => 'Vorbereitung';

  @override
  String get warPerfectWar => 'Perfekter Krieg';

  @override
  String get warVictory => 'Sieg';

  @override
  String get warDefeat => 'Niederlage';

  @override
  String get warDraw => 'Unentschieden';

  @override
  String get warTeamSize => 'Teamgröße';

  @override
  String get warMyTeam => 'Mein Team';

  @override
  String get warEnemiesTeam => 'Gegner';

  @override
  String get warClanDraw => 'Die beiden Clans sind gleichauf';

  @override
  String get warStateOfTheWar => 'Kriegsstand';

  @override
  String warStarsNeededToTakeTheLead(
      String clan, int star, int stars2, String percent) {
    return '$clan benötigt noch $star Stern(e) oder $stars2 Stern(e) und $percent%, um die Führung zu übernehmen.';
  }

  @override
  String warStarsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan benötigt noch $percent% oder 1 Stern, um die Führung zu übernehmen';
  }

  @override
  String get warNoDataAvailableForThisWar =>
      'Keine Daten für diesen Krieg verfügbar';

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
  String get warAttacksTitle => 'Angriffe';

  @override
  String get warAttacksNone => 'Noch kein Angriff';

  @override
  String get warAttacksBest => 'Beste Angriffe';

  @override
  String get warAttacksCount => 'Anzahl Angriffe';

  @override
  String get warAttacksMissed => 'Verpasste Angriffe';

  @override
  String warAttacksNumber(int number_time, int number_war) {
    return 'Du hast $number_time mal in den letzten $number_war Kriegen angegriffen.';
  }

  @override
  String warAttacksAverageStars(String stars) {
    return 'Du hattest durchschnittlich $stars Sterne pro Krieg.';
  }

  @override
  String warAttacksAverageDestruction(String percent) {
    return 'Du hattest eine durchschnittliche Zerstörungsrate von $percent% pro Krieg.';
  }

  @override
  String get warDefensesTitle => 'Verteidigungen';

  @override
  String get warDefensesNone => 'Noch keine Verteidigung';

  @override
  String get warDefensesBest => 'Beste Verteidigungen';

  @override
  String warDefensesBestOutOf(int number) {
    return 'Beste Verteidigung (von $number)';
  }

  @override
  String warDefensesNumber(int number_time, int number_war) {
    return 'Du hast $number_time mal in den letzten $number_war Kriegen verteidigt.';
  }

  @override
  String warDefensesAverageStars(double stars) {
    return 'Du hattest durchschnittlich $stars Sterne pro Verteidigung.';
  }

  @override
  String warDefensesAverageDestruction(String percent) {
    return 'Du hattest eine durchschnittliche Zerstörungsrate von $percent% pro Verteidigung.';
  }

  @override
  String get warStarsTitle => 'Sterne';

  @override
  String get warStarsAverage => 'Durchschnittliche Sterne';

  @override
  String get warStarsNumber => 'Anzahl der Sterne';

  @override
  String get warStarsOne => '1 Stern';

  @override
  String get warStarsTwo => '2 Sterne';

  @override
  String get warStarsThree => '3 Sterne';

  @override
  String get warStarsZero => '0 Sterne';

  @override
  String get warStarsBestPerformance => 'Beste Leistung';

  @override
  String get warDestructionTitle => 'Zerstörung';

  @override
  String get warDestructionAverage => 'Durchschnittliche Zerstörung';

  @override
  String get warDestructionRate => 'Zerstörungsrate';

  @override
  String warHistoryWinsDescription(int wins, String percent) {
    return 'Dein Clan hat $wins Kriege ($percent%) der letzten 50 Kriege gewonnen.';
  }

  @override
  String warHistoryLossesDescription(int losses, String percent) {
    return 'Dein Clan hat $losses Kriege ($percent%) der letzten 50 Kriege verloren.';
  }

  @override
  String warHistoryDrawsDescription(int draws, String percent) {
    return 'Dein Clan hat $draws Kriege ($percent%) der letzten 50 Kriege unentschieden gespielt.';
  }

  @override
  String warHistoryAverageMembersDescription(int members) {
    return 'In deinem Clan haben durchschnittlich $members Mitglieder an den letzten 50 Kriegen teilgenommen.';
  }

  @override
  String warHistoryAverageWarStarsDescription(double stars, String percent) {
    return 'Dein Clan hatte im Durchschnitt $stars Sterne pro Krieg in den letzten 50 Kriegen. Das entspricht $percent% der Gesamtsterne.';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return 'Dein Clan hatte eine durchschnittliche Zerstörungsrate von $percent% in den letzten 50 Kriegen.';
  }

  @override
  String get warPositionMap => 'Kartenposition';

  @override
  String get warPositionAbbr => 'Pos';

  @override
  String get warPositionOrder => 'Reihenfolge';

  @override
  String get warOpponentTownhall => 'Gegner RH';

  @override
  String get warOpponentLowerTownhall => 'Niedrigeres RH';

  @override
  String get warOpponentUpperTownhall => 'Höheres RH';

  @override
  String get warOpponentEqualThLevel => 'Equal TH';

  @override
  String get warOpponentSelectMembersThLevel => 'Members TH Level';

  @override
  String get warOpponentSelectOpponentsThLevel => 'Opponents TH Level';

  @override
  String warFiltersLastXwars(int number) {
    return 'Letzte $number Kriege';
  }

  @override
  String get warFiltersFriendly => 'Freundschaftsspiel';

  @override
  String get warFiltersRandom => 'Zufällig';

  @override
  String get warVisibilityToggleTownHall => 'Statistik früherer Rathauslevel';

  @override
  String get warEventsTitle => 'Ereignisse';

  @override
  String get warEventsNewest => 'Neueste';

  @override
  String get warEventsOldest => 'Älteste';

  @override
  String get warStatusReady => 'Angemeldet';

  @override
  String get warStatusUnready => 'Abgemeldet';

  @override
  String get warStatusMissed => 'Verpasst';

  @override
  String get warAbbreviationAvg => 'Ø';

  @override
  String get warAbbreviationAvgPercentage => 'Ø %';

  @override
  String get cwlTitle => 'Clankriegsliga';

  @override
  String get cwlClanWarLeague => 'Clankriegsliga';

  @override
  String get cwlOngoing => 'Laufende Clankriegsliga';

  @override
  String get cwlRounds => 'Runden';

  @override
  String cwlRoundNumber(int number) {
    return 'Runde $number';
  }

  @override
  String cwlCurrentRound(int round) {
    return 'Es ist aktuell Runde $round.';
  }

  @override
  String cwlRank(int rank) {
    return 'Dein Clan ist aktuell auf Rang $rank.';
  }

  @override
  String cwlStars(int stars) {
    return 'Dein Clan hat insgesamt $stars Sterne.';
  }

  @override
  String cwlDestructionPercentage(String percent) {
    return 'Dein Clan hat eine Zerstörungsrate von $percent%.';
  }

  @override
  String cwlTotalAttacks(int attacks, int totalAttacks) {
    return 'Dein Clan hat insgesamt $attacks Angriffe von $totalAttacks möglichen Angriffen.';
  }

  @override
  String get joinLeaveTitle => 'Beitritts-/Austritts-Logs (Aktuelle Saison)';

  @override
  String get joinLeaveJoin => 'Beigetreten';

  @override
  String get joinLeaveLeave => 'Verlassen';

  @override
  String get joinLeaveReset => 'Zurücksetzen';

  @override
  String get joinLeaveJoins => 'Beitritte';

  @override
  String get joinLeaveLeaves => 'Austritte';

  @override
  String get joinLeaveUniquePlayers => 'Einzigartige Spieler';

  @override
  String get joinLeaveMovingPlayers => 'Wechselnde Spieler';

  @override
  String get joinLeaveMostMovingPlayers => 'Meist wechselnde Spieler';

  @override
  String get joinLeaveStillInClan => 'Noch im Clan';

  @override
  String get joinLeaveLeftForever => 'Für immer gegangen';

  @override
  String get joinLeaveRejoinedPlayers => 'Wieder beigetretene Spieler';

  @override
  String get joinLeaveAvgTimeJoinLeave => 'Ø Beitritts-/Austrittszeit';

  @override
  String get joinLeavePeakHour => 'Aktivste Stunde';

  @override
  String joinLeaveNumberDescription(int number, String date) {
    return '$number Austritts-Ereignisse traten während der aktuellen Saison auf ($date).';
  }

  @override
  String joinLeaveJoinNumberDescription(int number, String date) {
    return '$number Beitritts-Ereignisse traten während der aktuellen Saison auf ($date).';
  }

  @override
  String joinLeaveMovingNumberDescription(int number, String date) {
    return '$number Spieler verließen den Clan und traten während der aktuellen Saison wieder bei ($date).';
  }

  @override
  String joinLeaveUniqueNumberDescription(int number, String date) {
    return '$number einzigartige Spieler traten dem Clan bei/verließen ihn während der aktuellen Saison ($date).';
  }

  @override
  String joinLeaveStillInClanNumberDescription(int number) {
    return '$number Spieler traten bei und sind noch im Clan.';
  }

  @override
  String joinLeaveLeftClanNumberDescription(int number) {
    return '$number Spieler traten bei, verließen dann den Clan und traten nie wieder bei.';
  }

  @override
  String joinLeaveLeftOnAt(String date, String time) {
    return 'Verlassen am $date um $time.';
  }

  @override
  String joinLeaveJoinedOnAt(String date, String time) {
    return 'Beigetreten am $date um $time.';
  }

  @override
  String get raidsTitle => 'Überfälle';

  @override
  String get raidsLast => 'Letzte Überfälle';

  @override
  String get raidsOngoing => 'Aktuelle Überfälle';

  @override
  String get raidsDistrictsDestroyed => 'Zerstörte Bezirke';

  @override
  String get raidsCompleted => 'Abgeschlossene Überfälle';

  @override
  String get searchNoResult => 'Kein Ergebnis.';

  @override
  String get maintenanceTitle => 'Wartung';

  @override
  String get maintenanceDescription =>
      'Clash of Clans ist derzeit in Wartung, daher können wir nicht auf die API zugreifen. Bitte schaue später wieder vorbei.';

  @override
  String get downloadTooltip => 'CWL-Zusammenfassung herunterladen';

  @override
  String get downloadInProgress =>
      'Datei wird heruntergeladen... Das kann ein paar Sekunden dauern...';

  @override
  String downloadSuccess(String path) {
    return 'Datei erfolgreich in $path gespeichert';
  }

  @override
  String get downloadError => 'Fehler beim Herunterladen der Datei';

  @override
  String get dashboardTitle => 'Übersicht';

  @override
  String get toolsTitle => 'Werkzeuge';

  @override
  String get navigationTeam => 'Teams';

  @override
  String get navigationStatistics => 'Statistics';

  @override
  String get versionDevice => 'Version & Gerät';

  @override
  String get settingsLicenses => 'Open Source Licenses';

  @override
  String get settingsLicensesSubtitle =>
      'View licenses for third-party libraries';

  @override
  String get betaFeature => 'Beta-Funktion';

  @override
  String get betaLabel => 'BETA';

  @override
  String get betaDescription =>
      'Diese Option ist aktuell in der Beta, es kann also zu Fehlern kommen oder unvollständig sein. Wir arbeiten aktiv an Verbesserungen und sind dankbar für dein Feedback. Bitte teile uns deine Ideen sowie Fragen und Probleme auf unserem Discord-Server mit, damit wir es besser machen können.';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsSelectLanguage => 'Wähle eine Sprache aus';

  @override
  String get settingsToggleTheme => 'Design wechseln';

  @override
  String get faqTitle => 'FAQ';

  @override
  String get faqSubtitle => 'Häufig gestellte Fragen';

  @override
  String get faqIsThisFromSupercell => 'Ist diese App von Supercell?';

  @override
  String get faqFanContentPolicy =>
      'Dieses Material ist nicht offiziell und nicht von Supercell bewilligt. Weitere Informationen findest du in Supercells Richtlinien für Fan-Content unter https://supercell.com/en/fan-content-policy/de';

  @override
  String get faqWhyNotAccurate =>
      'Warum sind die Daten manchmal ungenau oder fehlen?';

  @override
  String get faqClanNotTracked => 'Clan wird nicht getrackt';

  @override
  String get faqClanNotTrackedAnswer =>
      'ClashKing kann diese Informationen nur abrufen, wenn der Clan erfasst ist. Wenn dein Clan nicht erfasst ist, lade bitte den ClashKing Bot auf deinen Discord-Server ein und benutze den Befehl /addclan. Wir arbeiten daran, diese Funktion bald in der App verfügbar zu machen.';

  @override
  String get faqTrackingDown => 'Tracking nicht aktiv';

  @override
  String get faqTrackingDownAnswer =>
      'Das Tracking kann für eine gewisse Zeit nicht funktionieren. Deshalb kann es manchmal Lücken in den Daten geben. Wir arbeiten daran, dies zu verbessern.';

  @override
  String get faqApiLimitation => 'Clash of Clans API-Einschränkung';

  @override
  String get faqApiLimitationAnswer =>
      'Einige Daten werden von Clash of Clans bereitgestellt und ihre API hat gewisse Limitierungen. Dies ist der Fall beim Legenden-Tracking, bei dem manchmal Trophäen-Gewinne und -Verluste verrechnet werden, als wäre es ein einzelner Angriff. Das ist auch der Grund, warum wir keine Daten über die Level deiner Gebäude haben.';

  @override
  String get faqSupportWork => 'Wie kann ich eure Arbeit unterstützen?';

  @override
  String get faqSupportWorkAnswer =>
      'Es gibt mehrere Möglichkeiten, uns zu unterstützen:';

  @override
  String get faqUseCodeClashKing => 'Creator-Code \"ClashKing\" verwenden';

  @override
  String get faqSupportUsOnPatreon => 'Unterstütze uns auf Patreon';

  @override
  String get faqShareTheApp => 'Teile die App mit deinen Freunden';

  @override
  String get faqRateTheApp => 'Bewerte die App im Store';

  @override
  String get faqHelpUsTranslate => 'Hilf uns, die App zu übersetzen';

  @override
  String get faqHowToInviteTheBot =>
      'Wie kann ich euren Bot zu meinem Discord-Server einladen?';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'Du kannst unseren Bot auf deinen Server einladen, indem du auf den unten stehenden Button klickst. Du benötigst die Berechtigung \"Server verwalten\", um den Bot hinzuzufügen.';

  @override
  String get faqInviteTheBot => 'ClashKing Bot einladen';

  @override
  String get faqNeedHelp =>
      'Ich brauche Hilfe oder möchte einen Vorschlag machen. Wie kann ich euch erreichen?';

  @override
  String get faqNeedHelpAnswer =>
      'Du kannst unserem Discord-Server beitreten und dort um Hilfe bitten, oder Feedback geben oder uns eine E-Mail an devs@clashk.ing senden. Bitte schreib uns, wenn möglich, nur auf Englisch oder Französisch.';

  @override
  String get faqSendEmail => 'E-Mail senden';

  @override
  String get faqJoinDiscord => 'Unserem Discord-Server beitreten';

  @override
  String get faqCannotOpenMailClient =>
      'Aus irgendeinem Grund können wir deinen E-Mail-Client nicht öffnen. Wir haben die E-Mail-Adresse für dich kopiert. Du kannst eine E-Mail schreiben und die Adresse im Empfängerfeld einfügen.';

  @override
  String get translationHelpUsTranslate => 'Hilf uns bei der Übersetzung';

  @override
  String get translationSuggestFeatures => 'Funktion vorschlagen';

  @override
  String get translationThankYou => 'Vielen Dank!';

  @override
  String get translationThankYouContent =>
      'Ein großes Dankeschön an all unsere großartigen Übersetzer, die uns helfen, diese App mehr Menschen auf der ganzen Welt zugänglich zu machen!';

  @override
  String get translationHelpTranslateContent =>
      'Du kannst uns helfen, die App auf Crowdin zu übersetzen. Wenn deine Sprache auf Crowdin nicht verfügbar ist, kannst du diese gerne auf unserem Discord-Server anfordern. Vielen Dank für deine Hilfe!';

  @override
  String get translationHelpTranslateButton =>
      'Hilf bei der Übersetzung auf Crowdin';

  @override
  String get translationCurrentTranslators => 'Aktuelle Übersetzer';
}
