// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get appTitle => 'ClashKing';

  @override
  String get appDescription =>
      'Sinun lopullinen Clash of klaanit kumppani seuranta tilastoja, hallita klaaneja, ja analysoida suorituskykyä.';

  @override
  String get generalLoading => 'Ladataan...';

  @override
  String get loadingVillages => 'Ladataan kyliäsi...';

  @override
  String get loadingClanData => 'Haetaan klaanin tietoja...';

  @override
  String get loadingWarStats => 'Analysoidaan sotatilastoja...';

  @override
  String get loadingLegendsData => 'Valmistellaan legendojen tietoja...';

  @override
  String get loadingCapitalRaids => 'Ladataan pääoman raideja...';

  @override
  String get loadingAlmostReady => 'Melkein valmis...';

  @override
  String get accountVerificationTitle => 'Vahvista Tili';

  @override
  String get accountVerificationMessage =>
      'Syötä API-tunniste varmistaaksesi tämän tilin. Löydät sen osoitteesta Clash of klaanit Asetukset > Lisää Asetukset > API Token.';

  @override
  String get accountVerified => 'Tili vahvistettu';

  @override
  String get accountNotVerified => 'Tiliä ei ole vahvistettu';

  @override
  String get accountVerifyButton => 'Vahvista';

  @override
  String get accountVerificationSuccess => 'Tili vahvistettu onnistuneesti!';

  @override
  String get accountVerificationFailed =>
      'Vahvistus epäonnistui. Tarkista API token.';

  @override
  String get generalRetry => 'Yritä Uudelleen';

  @override
  String get generalTryAgain => 'Yritä uudelleen';

  @override
  String get generalCancel => 'Peruuta';

  @override
  String get generalOk => 'Ok';

  @override
  String get generalApply => 'Käytä';

  @override
  String get generalConfirm => 'Vahvista';

  @override
  String get generalManage => 'Hallitse';

  @override
  String get generalSettings => 'Asetukset';

  @override
  String get generalCopiedToClipboard => 'Kopioitu leikepöydälle';

  @override
  String get generalComingSoon => 'Tulossa pian!';

  @override
  String generalLastRefresh(String time) {
    return 'Viimeisin päivitys: $time';
  }

  @override
  String generalRefreshFailed(String error) {
    return 'Refresh failed: $error';
  }

  @override
  String get generalAll => 'Kaikki';

  @override
  String get generalTotal => 'Yhteensä';

  @override
  String get generalBest => 'Paras';

  @override
  String get generalWorst => 'Huonoin';

  @override
  String get generalAverage => 'Keskiarvo';

  @override
  String get generalRemaining => 'Jäljellä';

  @override
  String get generalActive => 'Aktiivinen';

  @override
  String get generalInactive => 'Passiivinen';

  @override
  String get generalStarted => 'Aloitettu';

  @override
  String get generalEnded => 'Päättynyt';

  @override
  String get generalRole => 'Rooli';

  @override
  String get generalStats => 'Tilastot';

  @override
  String get generalFullStats => 'Täydet Tilastot';

  @override
  String get generalDetails => 'Yksityiskohdat';

  @override
  String get generalHistory => 'Historia';

  @override
  String get generalFilters => 'Suodattimet';

  @override
  String get generalNotSet => 'Ei asetettu';

  @override
  String get generalWarning => 'Varoitus';

  @override
  String get generalNoDataAvailable => 'Tietoja ei ole saatavilla.';

  @override
  String get authSignUp => 'Rekisteröidy nyt';

  @override
  String get authLogin => 'Kirjaudu';

  @override
  String get authLogout => 'Kirjaudu ulos';

  @override
  String get authCreateAccount => 'Luo Tili';

  @override
  String get authJoinClashKing => 'Liity ClashKingiin';

  @override
  String get authCreateClashKingAccount => 'Luo ClashKing -tili';

  @override
  String get authCreateAccountToGetStarted => 'Luo tilisi päästäksesi alkuun';

  @override
  String get authAlreadyHaveAccount => 'Onko sinulla jo tili? Kirjaudu sisään';

  @override
  String get authConfirmLogout => 'Oletko varma, että haluat kirjautua ulos?';

  @override
  String get authDiscordTitle => 'Discord';

  @override
  String get authDiscordSignIn => 'Kirjaudu sisään Discordilla';

  @override
  String get authDiscordContinue => 'Jatka Discordin avulla';

  @override
  String get authDiscordDescription =>
      'Synkronoi tietosi ClashKing Botin kanssa ja avaa ClashKingin koko potentiaali!';

  @override
  String get authEmailTitle => 'Sähköposti';

  @override
  String get authEmailDescription =>
      'Käytä sähköpostia jos et voi käyttää Discordia tai suosia vain sovelluksessa olevia ominaisuuksia';

  @override
  String get authEmailRequired => 'Ole hyvä ja syötä sähköpostiosoitteesi';

  @override
  String get authEmailInvalid => 'Syötä voimassa oleva sähköpostiosoite';

  @override
  String get authPasswordLabel => 'Salasana';

  @override
  String get authPasswordConfirm => 'Vahvista Salasana';

  @override
  String get authPasswordRequired => 'Anna salasanasi';

  @override
  String get authPasswordConfirmRequired => 'Ole hyvä ja vahvista salasana';

  @override
  String get authPasswordMismatch => 'Salasanat eivät täsmää';

  @override
  String get authPasswordTooShort =>
      'Salasanan tulee olla vähintään 8 merkkiä pitkä';

  @override
  String get authPasswordRequirements =>
      'Salasanan tulee sisältää: isot kirjaimet, pienet kirjaimet, numerot ja erikoismerkit';

  @override
  String get authPasswordForgot => 'Unohditko salasanasi?';

  @override
  String get authUsernameLabel => 'Käyttäjätunnus';

  @override
  String get authUsernameRequired => 'Ole hyvä ja anna käyttäjänimi';

  @override
  String get authUsernameTooShort =>
      'Käyttäjänimen tulee olla vähintään 3 merkkiä pitkä';

  @override
  String get authErrorConnection =>
      'Tapahtui virhe. Tarkista internet-yhteytesi ja yritä uudelleen.';

  @override
  String get authErrorConnectionRelaunch =>
      'Tapahtui virhe. Tarkista internet-yhteytesi ja käynnistä sovellus uudelleen.';

  @override
  String get authAccountManagement =>
      'Lisää, poista ja järjestä uudelleen Clash of klaanit -tilit. Tarkista tilisi käyttääksesi kaikkia ominaisuuksia.';

  @override
  String get authAccountConnected => 'Yhdistetyt Tilit';

  @override
  String get authAccountConnectedStatus => 'Yhdistetty';

  @override
  String get authAccountNotConnected => 'Ei yhdistetty';

  @override
  String get authAccountEmailAndPassword => 'Sähköposti Ja Salasana';

  @override
  String get authAccountSecured =>
      'Tilisi on suojattu useilla tunnistautumistavoilla';

  @override
  String get authAccountLinkEmail => 'Linkitä Sähköpostitili';

  @override
  String get authAccountAddEmailAuth =>
      'Lisää sähköpostin ja salasanan todennus tilillesi lisäturvallisuuden takaamiseksi.';

  @override
  String get authAccountEmailLinkedSuccess =>
      'Sähköposti tili onnistuneesti linkitetty!';

  @override
  String get helpTitle => 'Tarvitsetko apua?';

  @override
  String get helpJoinDiscord => 'Liity Discordiin';

  @override
  String get helpEmailUs => 'Lähetä Meille Sähköpostia';

  @override
  String get accountsWelcome => 'Tervetuloa!';

  @override
  String get accountsWelcomeMessage =>
      'Lisää profiiliisi yksi tai useampi Clash of Clans -tili. Voit lisätä tai poistaa tilejä myöhemmin.';

  @override
  String get accountsManageTitle => 'Hallinnoi tilejäsi';

  @override
  String get accountsNoneFound => 'Profiiliisi linkitettyä tiliä ei löytynyt';

  @override
  String get accountsPlayerTag => 'Pelaajan Tagi (#ABC123)';

  @override
  String get accountsEnterPlayerTag => 'Syötä pelaajan tagi';

  @override
  String get accountsAdd => 'Lisää tili';

  @override
  String get accountsDelete => 'Poista tili';

  @override
  String get accountsApiToken => 'Tilin API-tunniste';

  @override
  String get accountsEnterApiToken =>
      'Syötä tili API-tunniste vahvistaaksesi sen sinun. Löydät sen osoitteesta Clash of klaanit Asetukset > Lisää Asetukset > API Token.';

  @override
  String get accountsFillAllFields => 'Täytä kaikki kentät.';

  @override
  String get accountsErrorTagNotExists =>
      'Syötettyä soittimen tunnusta ei ole olemassa.';

  @override
  String accountsErrorAlreadyLinked(Object tag) {
    return 'Pelaajan tagi on jo linkitetty jokuun.';
  }

  @override
  String get accountsErrorAlreadyLinkedToYou =>
      'Pelaajatunnus on jo linkitetty sinuun.';

  @override
  String get accountsErrorWrongApiToken =>
      'Syötetty API-tunniste on virheellinen';

  @override
  String get accountsErrorFailedToAdd =>
      'Tilin lisääminen epäonnistui. Yritä myöhemmin uudelleen.';

  @override
  String get accountsErrorFailedToDelete =>
      'Linkin poistaminen epäonnistui. Yritä myöhemmin uudelleen.';

  @override
  String get accountsErrorFailedToUpdateOrder =>
      'Tilien järjestyksen päivittäminen epäonnistui.';

  @override
  String get errorTitle =>
      'Hups! Palvelimemme ovat saattaneet viedä tulipallon kasvoille! Me heitämme parantavaa loitsua... Yritä hetken kuluttua uudelleen.';

  @override
  String get errorSubtitle =>
      'Jos ongelma jatkuu, tarkista Discord-palvelimemme nähdäksemme, onko se tiedossa.';

  @override
  String get errorLoadingVersion => 'Error loading version';

  @override
  String get errorCannotOpenLink => 'Tätä linkkiä ei voi avata.';

  @override
  String get errorExitAppToOpenClash =>
      'Olet poistumassa sovelluksesta avataksesi Clash of Clans.';

  @override
  String get playerSearchTitle => 'Etsi pelaajaa';

  @override
  String get playerSearchPlaceholder => 'Pelaajan nimi tai tagi';

  @override
  String playerLastActive(String date) {
    return 'Viimeisin aktiivinen: $date';
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
    return 'Sota etusija on \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'Sinulla on $stars sotaa tähteä.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'You have $trophies trophies. You\'re currently in $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Kaupunkihallin taso on $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Your Builder Hall level is $level and you have $trophies trophies.';
  }

  @override
  String get gameBaseHome => 'Koti Pohja';

  @override
  String get gameBaseBuilder => 'Rakentajan Pohja';

  @override
  String get gameClanCapital => 'Clan Capital';

  @override
  String get gameTownHall => 'TH';

  @override
  String get gameTownHallLevel => 'Th Taso';

  @override
  String gameTownHallLevelNumber(int level) {
    return 'Kaupunginhalli $level';
  }

  @override
  String gameTHLevel(int level) {
    return 'Th$level';
  }

  @override
  String get gameExpLevel => 'Kokemuksen Taso';

  @override
  String get gameTrophies => 'Palkinnot';

  @override
  String get gameBuilderBaseTrophies => 'Bb Palkinnot';

  @override
  String get gameDonations => 'Lahjoitukset';

  @override
  String get gameDonationsReceived => 'Lahjoitukset Vastaanotettu';

  @override
  String get gameDonationsRatio => 'Lahjoituksen Suhde';

  @override
  String gameLevel(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get gameHeroes => 'Heroes';

  @override
  String get gameEquipment => 'Laitteet';

  @override
  String get gameHeroesEquipments => 'Sankarin laitteet';

  @override
  String get gameTroops => 'Joukot';

  @override
  String get gameActiveSuperTroops => 'Aktiiviset Super Joukot';

  @override
  String get gamePets => 'Lemmikit';

  @override
  String get gameSiegeMachines => 'Siege Machines';

  @override
  String get gameSpells => 'Spells';

  @override
  String get gameAchievements => 'Saavutukset';

  @override
  String get gameClanGames => 'Klaani Pelit';

  @override
  String get gameSeasonPass => 'Kauden Pass';

  @override
  String get gameCreatorCode => 'Luojan Koodi: ClashKing';

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
  String get clanTitle => 'Klaani';

  @override
  String get clanSearchTitle => 'Hae klaania';

  @override
  String get clanSearchPlaceholder => 'Klaanin nimi';

  @override
  String get clanNone => 'Ei klaania';

  @override
  String get clanJoinToUnlock =>
      'Liity klaaniin avataksesi uusia ominaisuuksia.';

  @override
  String get clanMembers => 'Jäsenet';

  @override
  String get clanWarFrequency => 'Sodan taajuus';

  @override
  String get clanMinimumMembers => 'Minimi jäsenet';

  @override
  String get clanMaximumMembers => 'Jäsenten enimmäismäärä';

  @override
  String get clanLocation => 'Sijainti';

  @override
  String get clanMinimumPoints => 'Klaanipisteiden vähimmäismäärä';

  @override
  String get clanMinimumLevel => 'Klaanin vähimmäistaso';

  @override
  String get clanInviteOnly => 'Vain Kutsu';

  @override
  String get clanOpened => 'Avattu';

  @override
  String get clanClosed => 'Suljettu';

  @override
  String get clanRoleLeader => 'Johtaja';

  @override
  String get clanRoleCoLeader => 'Apulaisjohtaja';

  @override
  String get clanRoleElder => 'Vanhempi';

  @override
  String get clanRoleMember => 'Jäsen';

  @override
  String get clanWarFrequencyAlways => 'Aina';

  @override
  String get clanWarFrequencyNever => 'Ei Koskaan';

  @override
  String get clanWarFrequencyUnknown => 'Tuntematon';

  @override
  String get clanWarFrequencyOncePerWeek => '1/viikko';

  @override
  String get clanWarFrequencyMoreThanOncePerWeek => 'Yli 1 viikko';

  @override
  String get clanWarFrequencyRarely => 'Harvoin';

  @override
  String get timeHourIndicator => 'h';

  @override
  String timeDaysAgo(int days) {
    return '$days päivää sitten';
  }

  @override
  String timeDayAgo(int day) {
    return '$day päivää sitten';
  }

  @override
  String timeHourAgo(int hour) {
    return '$hour tuntia sitten';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours tuntia sitten';
  }

  @override
  String timeMinuteAgo(int minute) {
    return '$minute minuuttia sitten';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes minuuttia sitten';
  }

  @override
  String get timeJustNow => 'Juuri Nyt';

  @override
  String get timeEndedJustNow => 'Päättyi juuri nyt';

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
    return 'Aloittaa $time kuluttua';
  }

  @override
  String timeStartsAt(String time) {
    return 'Aloittaa nimellä $time';
  }

  @override
  String timeEndsIn(String time) {
    return 'Päättyy $time';
  }

  @override
  String timeEndsAt(String time) {
    return 'Ends at $time';
  }

  @override
  String get legendsTitle => 'Legend League';

  @override
  String get legendsNotInLeague => 'Ei Legend League -pelissä';

  @override
  String get legendsNoDataToday =>
      'Et ole Legend League, mutta edelliset vuodenajat ovat käytettävissä.';

  @override
  String legendsStartDescription(String trophies) {
    return 'Aloitit päivän $trophies palkalla.';
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
    return 'Olet voittanut $trophies palkinnot toistaiseksi.';
  }

  @override
  String legendsLossDescription(int trophies) {
    return 'Olet menettänyt $trophies pokaalia toistaiseksi.';
  }

  @override
  String legendsNoGlobalRankDescription(int trophies) {
    return 'Et ole tällä hetkellä maailmanlaajuisesti listattuna $trophies palkalla.';
  }

  @override
  String legendsGlobalRankDescription(int rank, int trophies) {
    return 'You are currently ranked $rank globally with $trophies trophies.';
  }

  @override
  String get legendsNoRank => 'Ei sijoitusta';

  @override
  String get legendsBestTrophies => 'Parhaat Palkinnat';

  @override
  String get legendsMostAttacks => 'Eniten Hyökkäyksiä';

  @override
  String get legendsLastSeason => 'Viime Kausi';

  @override
  String get legendsBestRank => 'Paras Maailmanlaajuinen Sijoitus';

  @override
  String get legendsTrophiesBySeason => 'Palkinnot kauden mukaan';

  @override
  String get legendsEosTrophies => 'Kauden Palkinnot Päättyvät';

  @override
  String get legendsEosDetails => 'Kauden Loppu Yksityiskohdat';

  @override
  String get legendsInaccurateTitle => 'Epätarkkoja tietoja?';

  @override
  String get legendsInaccurateIntro =>
      'Due to limitations of the Clash of Clans API, our data might not always be perfectly accurate. Here\'s why:\n';

  @override
  String get legendsInaccurateApiDelayTitle => '1. Api Viive: ';

  @override
  String get legendsInaccurateApiDelayBody =>
      'API voi kestää jopa 5 minuuttia päivittää, aiheuttaa viive heijastaa reaaliaikaisen pokaalin muutoksia.\n';

  @override
  String get legendsInaccurateConcurrentTitle =>
      '2. Samanaikaiset Muutokset: \n';

  @override
  String get legendsInaccurateMultipleAttacksTitle =>
      '- Useita Hyökkäyksiä/Puolustuksia: ';

  @override
  String get legendsInaccurateMultipleAttacksBody =>
      'Jos useita hyökkäyksiä tai puolustuksia tapahtuu nopeasti peräkkäin, API voi näyttää yhdistetyt tulokset (esim. +68 tai -68).\n';

  @override
  String get legendsInaccurateSimultaneousTitle =>
      '- Samanaikainen hyökkäys ja puolustus: ';

  @override
  String get legendsInaccurateSimultaneousBody =>
      'Jos hyökkäys ja puolustus tapahtuu samaan aikaan, saatat nähdä sekoitettu tulos (esim. +4).\n';

  @override
  String get legendsInaccurateNetGainTitle => '3. Netto Voitto/tappio: ';

  @override
  String get legendsInaccurateNetGainBody =>
      'Aika-asioista huolimatta päivän nettovoitto tai tappio on tarkka. ';

  @override
  String get legendsInaccurateConclusion =>
      'Nämä rajoitukset ovat yleisiä kaikissa työkaluissa käyttäen Clash of klaanit APIa. Valitettavasti emme voi korjata sitä, koska se on Supercellin käsissä. Teemme parhaamme kompensoidaksemme nämä rajat ja tuottaaksemme tuloksia mahdollisimman lähellä todellisuutta. Kiitos ymmärryksestäsi!';

  @override
  String get statsSeasonStats => 'Kauden Tilastot';

  @override
  String get statsByDay => 'Päivän Mukaan';

  @override
  String get statsBySeason => 'Kauden Mukaan';

  @override
  String statsDayIndex(int index) {
    return 'Päivä $index';
  }

  @override
  String statsIndexDays(int index) {
    return '$index päivää';
  }

  @override
  String statsSeasonDate(String date) {
    return '$date kausi';
  }

  @override
  String get statsAllTownHalls => 'Kaikki Kaupungit';

  @override
  String get statsMembers => 'Jäsenten Tilastot';

  @override
  String get todoTitle => 'Tehtäväluettelo';

  @override
  String get todoExplanationTitle => 'Tehtävän Laskeminen';

  @override
  String get todoExplanationIntro =>
      'Tehtävän suorittamisen prosenttiosuus lasketaan seuraavien erityisten painotusten avulla seuraavien toimintojen perusteella:';

  @override
  String get todoExplanationLegendsTitle => 'Legend League:';

  @override
  String get todoExplanationLegends =>
      'Paino 8 pistettä per tili, 1 hyökkäys = 1 piste.';

  @override
  String get todoExplanationRaidsTitle => 'Raidat:';

  @override
  String get todoExplanationRaids =>
      'Paino 5 pistettä per tili (tai 6, jos viimeinen hyökkäys on avattu), 1 hyökkäys = 1 piste.';

  @override
  String get todoExplanationClanWarsTitle => 'Klaanisodat:';

  @override
  String get todoExplanationClanWars =>
      'Paino 2 pistettä per tili, 1 hyökkäys = 1 piste.';

  @override
  String get todoExplanationCwlTitle => 'Clan Sota League:';

  @override
  String get todoExplanationCwl =>
      'Paino 1 pisteen per tili, 1 hyökkäys = 1 piste. CWL ei voi seurata, jos pelaaja ei ole liigan klaanissa.';

  @override
  String get todoExplanationPassAndGamesTitle => 'Kauden Pass Ja Clan Pelit:';

  @override
  String get todoExplanationPassAndGames =>
      'Paino 2 pistettä per tili. Suhde perustuu niiden päivien lukumäärään, jotka ovat jäljellä (1 kuukausi solan osalta ja 6 päivää pelien osalta). Vihreä = raiteella suorittaa sola tai pelejä, punainen = takana aikataulu.';

  @override
  String get todoExplanationConclusion =>
      'Lopullinen prosenttiosuus lasketaan jakamalla meneillään olevien tapahtumien aikana toteutettujen toimien kokonaismäärä tarvittavilla toimilla. Tilejä, jotka eivät ole toiminnassa yli 14 päivän ajan, ei oteta huomioon laskennassa.';

  @override
  String todoAccountsNumber(int number) {
    return '$number tiliä';
  }

  @override
  String todoAccountsNumberActive(int number) {
    return '$number aktiivista tiliä';
  }

  @override
  String todoAccountsNumberInactive(int number) {
    return '$number passiivista tiliä';
  }

  @override
  String get todoAccountsActive => 'Aktiiviset tilit';

  @override
  String get todoAccountsInactive => 'Passiiviset tilit';

  @override
  String get todoAccountsNoInactive => 'Ei epäaktiivisia tilejä.';

  @override
  String get todoAccountsNoActive => 'Ei aktiivisia tilejä.';

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
    return 'Onnittelut, olet tehnyt kaikki hyökkäyksesi ($type)!';
  }

  @override
  String todoPointsLeftDescription(int points, String type) {
    return 'Sinulla on $points pistettä jäljellä päästäksesi tänään olemaan ajoissa tapahtuman päättymiseen ($type).';
  }

  @override
  String todoPointsLeftDescriptionNoPoints(String type) {
    return 'Onneksi olkoon, sinulla on aikaa saada maksimi palkkiot tapahtuman lopussa ($type)!';
  }

  @override
  String get warTitle => 'Sota';

  @override
  String get warFrequency => 'Sodan taajuus';

  @override
  String get warParticipation => 'Sota Osallistuminen';

  @override
  String get warLeague => 'Sota/Liitto';

  @override
  String get warHistory => 'Sota Historia';

  @override
  String get warLog => 'Sota Loki';

  @override
  String warLogClosed(String clan) {
    return '$clan\'s sota loki on suljettu.';
  }

  @override
  String get warStats => 'Sodan Tilastot';

  @override
  String get warOngoing => 'Käynnissä oleva sota';

  @override
  String warIsNotInWar(String clan) {
    return '$clan ei ole sodassa.';
  }

  @override
  String get warAskForWar =>
      'Ota yhteyttä johtajaan tai yhteisjohtajaan aloittaaksesi sodan.';

  @override
  String get warAskForWarLogOpening =>
      'Ota yhteyttä johtajaan tai yhteisjohtajaan avataksesi sotalokin.';

  @override
  String get warEnded => 'Sota päättyi';

  @override
  String get warPreparation => 'Valmistelu';

  @override
  String get warPerfectWar => 'Täydellinen sota';

  @override
  String get warVictory => 'Voitto';

  @override
  String get warDefeat => 'Tappio';

  @override
  String get warDraw => 'Piirrä';

  @override
  String get warTeamSize => 'Tiimin koko';

  @override
  String get warMyTeam => 'Minun tiimini';

  @override
  String get warEnemiesTeam => 'Enemies';

  @override
  String get warClanDraw => 'Molemmat klaanit ovat sidottuja';

  @override
  String get warStateOfTheWar => 'Sodan tila';

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
  String get warNoDataAvailableForThisWar =>
      'Ei tietoja saatavilla tälle sodalle';

  @override
  String get warCalculatorFast => 'Nopea laskin';

  @override
  String warCalculatorAnswer(String percentNeeded, String result) {
    return 'To achieve a destruction rate of $percentNeeded%, a total of $result% is needed.';
  }

  @override
  String get warCalculatorNeededOverall => '% Tarvitaan yhteensä';

  @override
  String get warCalculatorCalculate => 'Laske';

  @override
  String get warAttacksTitle => 'Hyökkäykset';

  @override
  String get warAttacksNone => 'Ei hyökkäystä vielä';

  @override
  String get warAttacksBest => 'Parhaat hyökkäykset';

  @override
  String get warAttacksCount => 'Hyökkäysten Määrä';

  @override
  String get warAttacksMissed => 'Vastaamattomat Hyökkäykset';

  @override
  String warAttacksNumber(int number_time, int number_war) {
    return 'You attacked $number_time time(s) during the last $number_war wars.';
  }

  @override
  String warAttacksAverageStars(String stars) {
    return 'Sinulla oli keskimäärin $stars tähteä sotaa kohden.';
  }

  @override
  String warAttacksAverageDestruction(String percent) {
    return 'Sinulla oli keskimäärin $percent% tuhoa sotaa kohden.';
  }

  @override
  String get warDefensesTitle => 'Puolustukset';

  @override
  String get warDefensesNone => 'Ei vielä puolustusta';

  @override
  String get warDefensesBest => 'Parhaat puolustukset';

  @override
  String warDefensesBestOutOf(int number) {
    return 'Paras puolustus (tyhjästä $number)';
  }

  @override
  String warDefensesNumber(int number_time, int number_war) {
    return 'You defended $number_time time(s) during the last $number_war wars.';
  }

  @override
  String warDefensesAverageStars(double stars) {
    return 'Sinulla oli keskimäärin $stars tähteä per puolustus.';
  }

  @override
  String warDefensesAverageDestruction(String percent) {
    return 'Sinulla oli keskimäärin $percent% tuhoa per puolustus.';
  }

  @override
  String get warStarsTitle => 'Tähdet';

  @override
  String get warStarsAverage => 'Keskimääräiset tähdet';

  @override
  String get warStarsNumber => 'Number of stars';

  @override
  String get warStarsOne => '1 tähti';

  @override
  String get warStarsTwo => '2 tähteä';

  @override
  String get warStarsThree => '3 tähteä';

  @override
  String get warStarsZero => '0 Tähti';

  @override
  String get warStarsBestPerformance => 'Paras suorituskyky';

  @override
  String get warDestructionTitle => 'Hävittäminen';

  @override
  String get warDestructionAverage => 'Keskimääräinen tuhoaminen';

  @override
  String get warDestructionRate => 'Hävittämisaste';

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
    return 'klaanissasi on keskimäärin $members jäsentä, jotka osallistuvat viimeisten 50 sodan loppuun.';
  }

  @override
  String warHistoryAverageWarStarsDescription(double stars, String percent) {
    return 'Your clan had an average of $stars stars per war from the last 50 wars. It represents $percent of the total stars.';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return 'Kantasi hävitti keskimäärin $percent% viimeisen 50 sodan aikana.';
  }

  @override
  String get warPositionMap => 'Kartan Sijainti';

  @override
  String get warPositionAbbr => 'Pos';

  @override
  String get warPositionOrder => 'Tilaus';

  @override
  String get warOpponentTownhall => 'Opp TH';

  @override
  String get warOpponentLowerTownhall => 'Alempi TH';

  @override
  String get warOpponentUpperTownhall => 'Ylempi TH';

  @override
  String get warOpponentEqualThLevel => 'Yhtäläinen TH';

  @override
  String get warOpponentSelectMembersThLevel => 'Jäsenten Th Taso';

  @override
  String get warOpponentSelectOpponentsThLevel => 'Vastustajien Th Taso';

  @override
  String warFiltersLastXwars(int number) {
    return 'Last $number wars';
  }

  @override
  String get warFiltersFriendly => 'Ystävällinen';

  @override
  String get warFiltersRandom => 'Satunnainen';

  @override
  String get warVisibilityToggleTownHall =>
      'Piilota/Näytä tilastot entisiltä TH-tasoilta';

  @override
  String get warEventsTitle => 'Tapahtumat';

  @override
  String get warEventsNewest => 'Uusin';

  @override
  String get warEventsOldest => 'Vanhin';

  @override
  String get warStatusReady => 'Valittu Sisään';

  @override
  String get warStatusUnready => 'Valittu Ulos';

  @override
  String get warStatusMissed => 'Vastaamaton';

  @override
  String get warAbbreviationAvg => 'Keskiarvo';

  @override
  String get warAbbreviationAvgPercentage => 'Keskim.';

  @override
  String get cwlTitle => 'CWL';

  @override
  String get cwlClanWarLeague => 'Klaani Sota Liiga';

  @override
  String get cwlOngoing => 'CWL On Käynnissä';

  @override
  String get cwlRounds => 'Kierrokset';

  @override
  String cwlRoundNumber(int number) {
    return 'Pyöreä $number';
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
    return 'Sinun klaanissasi on yhteensä $stars tähteä.';
  }

  @override
  String cwlDestructionPercentage(String percent) {
    return 'Sinun klaani tuhoamisaste on $percent%.';
  }

  @override
  String cwlTotalAttacks(int attacks, int totalAttacks) {
    return 'Klaanillasi on yhteensä $attacks hyökkäystä $totalAttacks mahdollisesta hyökkäyksestä.';
  }

  @override
  String get joinLeaveTitle => 'Join/Jätä Lokit (Nykyinen Kausi)';

  @override
  String get joinLeaveJoin => 'Liity';

  @override
  String get joinLeaveLeave => 'Poistu';

  @override
  String get joinLeaveReset => 'Reset';

  @override
  String get joinLeaveJoins => 'Liitännäiset';

  @override
  String get joinLeaveLeaves => 'Lehdet';

  @override
  String get joinLeaveUniquePlayers => 'Ainutlaatuiset Pelaajat';

  @override
  String get joinLeaveMovingPlayers => 'Siirretään Pelaajia';

  @override
  String get joinLeaveMostMovingPlayers => 'Eniten Liikkuvat Pelaajat';

  @override
  String get joinLeaveStillInClan => 'Vielä klaanissa';

  @override
  String get joinLeaveLeftForever => 'Vasemmalle Ikuisesti';

  @override
  String get joinLeaveRejoinedPlayers => 'Liitynyt Pelaajiin';

  @override
  String get joinLeaveAvgTimeJoinLeave => 'Keskim. Keskim. Poissaoloaika';

  @override
  String get joinLeavePeakHour => 'Aktiivisin Tunti';

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
    return '$number pelaajaa liittyi ja on edelleen klaanissa.';
  }

  @override
  String joinLeaveLeftClanNumberDescription(int number) {
    return '$number pelaajaa liittyi, sitten lähti klaanista eikä koskaan liittynyt.';
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
  String get raidsTitle => 'Raidat';

  @override
  String get raidsLast => 'Viimeiset hyökkäykset';

  @override
  String get raidsOngoing => 'Käynnissä olevat hyökkäykset';

  @override
  String get raidsDistrictsDestroyed => 'Tuhoutuneet alueet';

  @override
  String get raidsCompleted => 'Raidat valmiit';

  @override
  String get searchNoResult => 'Ei tuloksia.';

  @override
  String get maintenanceTitle => 'Huolto';

  @override
  String get maintenanceDescription =>
      'Yhteentörmäyksestä klaanit ovat tällä hetkellä kunnossapidossa, joten emme voi käyttää APIa. Tarkista myöhemmin.';

  @override
  String get downloadTooltip => 'Lataa CWL yhteenveto';

  @override
  String get downloadInProgress =>
      'Ladataan tiedostoa... Se voi kestää muutaman sekunnin...';

  @override
  String downloadSuccess(String path) {
    return 'Tiedosto tallennettu onnistuneesti $path';
  }

  @override
  String get downloadError => 'Tiedoston lataaminen epäonnistui';

  @override
  String get dashboardTitle => 'Hallintapaneeli';

  @override
  String get toolsTitle => 'Työkalut';

  @override
  String get navigationTeam => 'Tiimit';

  @override
  String get navigationStatistics => 'Tilastot';

  @override
  String get versionDevice => 'Versio Ja Laite';

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
  String get betaFeature => 'Beta Ominaisuus';

  @override
  String get betaLabel => 'BETA';

  @override
  String get betaDescription =>
      'Tämä ominaisuus on tällä hetkellä beta, se voi olla joitakin vikoja tai olla epätäydellinen. Työskentelemme aktiivisesti parannusten parissa ja tervetuloa palautteesi. Ole hyvä ja jaa ideasi ja raportoi kaikista Discord-palvelimellamme olevista ongelmista auttaaksesi meitä parantamaan sitä.';

  @override
  String get settingsLanguage => 'Kieli';

  @override
  String get settingsSelectLanguage => 'Valitse kieli';

  @override
  String get settingsToggleTheme => 'Vaihda Teemaa';

  @override
  String get faqTitle => 'UKK';

  @override
  String get faqSubtitle => 'Usein Kysytyt Kysymykset';

  @override
  String get faqIsThisFromSupercell => 'Onko tämä sovellus Supercellistä?';

  @override
  String get faqFanContentPolicy =>
      'Tämä materiaali on epävirallista eikä Supercellin hyväksymä aineisto. Lisätietoja on Supercellin fanisisällön käytännössä: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate =>
      'Miksi tiedot joskus ovat virheellisiä tai puuttuvat?';

  @override
  String get faqClanNotTracked => 'Klaania ei seurata';

  @override
  String get faqClanNotTrackedAnswer =>
      'ClashKing voi hakea tämän tiedon vain, jos klaania seurataan. Jos klaania ei seurata, ole hyvä ja kutsu ClashKing Bot Discord-palvelimellesi ja käytä komentoa /addclan. Työskentelemme sen eteen, että tämä ominaisuus on saatavilla pian sovelluksessa.';

  @override
  String get faqTrackingDown => 'Seuranta alas';

  @override
  String get faqTrackingDownAnswer =>
      'Seuranta voi lakata toimimasta tietyn ajan. Siksi voit joskus olla reikiä tietojasi. Pyrimme parantamaan tätä.';

  @override
  String get faqApiLimitation => 'Yhteentörmäyksestä klaanit API rajoitus';

  @override
  String get faqApiLimitationAnswer =>
      'Joitakin tietoja on toimittanut Clash of klaanit ja niiden API on joitakin rajoituksia. Tämä pätee legendoja seuranta, se joskus pinot pokaalin voitto ja menetys ikään kuin se oli yksi hyökkäys. Tämän vuoksi meillä ei myöskään ole mitään tietoa rakennuksestasi.';

  @override
  String get faqSupportWork => 'Miten voin tukea työtäsi?';

  @override
  String get faqSupportWorkAnswer => 'On olemassa useita tapoja tukea meitä:';

  @override
  String get faqUseCodeClashKing => 'Käytä koodia \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Tue meitä Patreonissa';

  @override
  String get faqShareTheApp => 'Jaa sovellus ystäviesi kanssa';

  @override
  String get faqRateTheApp => 'Arvostele sovellus kaupassa';

  @override
  String get faqHelpUsTranslate => 'Auta meitä kääntämään sovellus';

  @override
  String get faqHowToInviteTheBot =>
      'Miten voin kutsua botti minun Discord-palvelimeeni?';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'Voit kutsua botin palvelimellesi klikkaamalla alla olevaa painiketta. Tarvitset \"Manage Server\" -oikeudet lisätäksesi bootin.';

  @override
  String get faqInviteTheBot => 'Invite ClashKing Bot';

  @override
  String get faqNeedHelp =>
      'Tarvitsen apua tai haluaisin tehdä ehdotuksen. Miten voin ottaa sinuun yhteyttä?';

  @override
  String get faqNeedHelpAnswer =>
      'You can join our Discord Server to ask for help or to provide feedback, or you can email us at devs@clashk.ing. Please only write in English or French.';

  @override
  String get faqSendEmail => 'Lähetä sähköposti';

  @override
  String get faqJoinDiscord => 'Liity Discord-palvelimeemme';

  @override
  String get faqCannotOpenMailClient =>
      'Jostain syystä emme voi avata sähköpostiohjelmaasi. Kopioimme sähköpostiosoitteen sinua varten. Voit kirjoittaa sähköpostin ja liittää osoitteen vastaanottajan kenttään.';

  @override
  String get translationHelpUsTranslate => 'Auta meitä kääntämään';

  @override
  String get translationSuggestFeatures => 'Ehdota ominaisuuksia';

  @override
  String get translationThankYou => 'Kiitos!';

  @override
  String get translationThankYouContent =>
      'Valtava kiitos kaikille uskomattomille kääntäjille, jotka auttavat meitä tekemään tämän sovelluksen useampien ihmisten saataville ympäri maailmaa!';

  @override
  String get translationHelpTranslateContent =>
      'Voit auttaa meitä kääntämään sovelluksen Crowdinissa. Jos kielesi ei ole käytettävissä Crowdinissa, voit vapaasti pyytää sitä meidän Discord-palvelimella. Kiitos paljon avustasi!';

  @override
  String get translationHelpTranslateButton => 'Auta kääntämään Crowdinia';

  @override
  String get translationCurrentTranslators => 'Nykyiset Kääntäjät';
}
