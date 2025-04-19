// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get creatorCode => 'Kod twórcy: ClashKing';

  @override
  String get errorTitle => 'Oops! Our servers might have taken a fireball to the face! We\'re casting a healing spell... Try again in a moment.';

  @override
  String get errorSubtitle => 'If the issue persists, check our Discord Server to see if we\'re aware of it.';

  @override
  String get retry => 'Retry';

  @override
  String get signInWithDiscord => 'Zaloguj się za pomocą Discorda';

  @override
  String get guestMode => 'Tryb gościa';

  @override
  String get needHelpJoinDiscord => 'Potrzebujesz pomocy? Dołącz do nas na Discordzie.';

  @override
  String get loginError => 'An error occurred while logging in. Please try again later.';

  @override
  String get createGuestProfile => 'Utwórz swój profil gościa';

  @override
  String doesNotExist(String tag) {
    return '$tag nie istnieje.';
  }

  @override
  String isAlreadyLinked(String tag) {
    return '$tag jest już powiązany z kimś innym.';
  }

  @override
  String get username => 'Nazwa użytkownika';

  @override
  String get pleaseEnterUsername => 'Wprowadź nazwę użytkownika';

  @override
  String get playerTag => 'Player Tag (#ABC123)';

  @override
  String get playerTags => 'Tagi gracza';

  @override
  String get linkedAccounts => 'Linked Accounts';

  @override
  String followingTagsDoNotExist(String tags) {
    return 'Następujące znaczniki nie istnieją: $tags.';
  }

  @override
  String followingTagsAreAlreadyLinked(String tags) {
    return 'Następujące tagi są już powiązane z kimś innym: $tags.';
  }

  @override
  String get welcome => 'Witamy!';

  @override
  String get welcomeMessage => 'Proszę dodać jeden lub więcej kont Clash Of Clans do swojego profilu. Możesz później dodać lub usunąć konta.';

  @override
  String get login => 'Zaloguj się';

  @override
  String get logout => 'Wyloguj';

  @override
  String get language => 'Język';

  @override
  String get settings => 'Ustawienia';

  @override
  String get toggleTheme => 'Zmień motyw';

  @override
  String get selectLanguage => 'Wybierz język';

  @override
  String get faq => 'FAQ';

  @override
  String get faqSubtitle => 'Najczęściej zadawane pytania';

  @override
  String get faqIsThisFromSupercell => 'Czy ta aplikacja pochodzi od Supercell?';

  @override
  String get faqFanContentPolicy => 'Ten materiał jest nieoficjalny i nie jest popierany przez Supercell. Aby uzyskać więcej informacji, zobacz Politykę treści twórców Supercell: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate => 'Dlaczego dane czasami są niedokładne lub brakujące?';

  @override
  String get faqClanNotTracked => 'Klan nieśledzony';

  @override
  String get faqClanNotTrackedAnswer => 'ClashKing może uzyskać te informacje tylko jeśli klan jest śledzony. Jeśli twój klan nie jest śledzony, zaproś bota ClashKing na swój serwer Discord i użyj komendy /addclan. Pracujemy nad udostępnieniem tej funkcji w aplikacji wkrótce.';

  @override
  String get faqTrackingDown => 'Śledzenie';

  @override
  String get faqTrackingDownAnswer => 'Śledzenie może przestać działać przez pewien okres czasu. Dlatego czasami możesz mieć dziury w swoich danych. Pracujemy nad ich poprawą.';

  @override
  String get faqApiLimitation => 'Ograniczenie interfejsu API Clash of Clans';

  @override
  String get faqApiLimitationAnswer => 'Niektóre dane są dostarczane przez Clash of Clans, a ich API ma pewne ograniczenia. Tak jest w przypadku śledzenia legend, gdzie czasami zbiera się zysk i stratę pucharów, jakby był to pojedynczy atak. To także dlatego nie mamy żadnych informacji na temat poziomów twoich budynków.';

  @override
  String get faqSupportWork => 'Jak mogę wesprzeć Twoją pracę?';

  @override
  String get faqSupportWorkAnswer => 'Istnieje kilka sposobów, aby nas wesprzeć:';

  @override
  String get faqUseCodeClashKing => 'Użyj kodu \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Wesprzyj nas na Patreonie';

  @override
  String get faqShareTheApp => 'Udostępnij aplikację znajomym';

  @override
  String get faqRateTheApp => 'Oceń aplikację w sklepie';

  @override
  String get faqHelpUsTranslate => 'Pomóż nam przetłumaczyć aplikację';

  @override
  String get faqHowToInviteTheBot => 'Jak mogę zaprosić twojego bota na mój serwer Discord?';

  @override
  String get faqHowToInviteTheBotAnswer => 'Możesz zaprosić naszego bota na swój serwer, klikając poniższy przycisk. Będziesz musiał mieć uprawnienie \"Zarządzaj serwerem\", aby dodać bota.';

  @override
  String get faqInviteTheBot => 'Zaproś Bota ClashKing';

  @override
  String get faqNeedHelp => 'Potrzebuję pomocy lub chciałbym złożyć sugestię. Jak mogę się z Tobą skontaktować?';

  @override
  String get faqNeedHelpAnswer => 'Możesz dołączyć do naszego serwera Discord, aby poprosić o pomoc lub przekazać informacje zwrotne, lub możesz napisać do nas e-maila na adres devs@clashkingbot.com. Prosimy pisać tylko po angielsku lub francusku.';

  @override
  String get faqSendEmail => 'Wyślij wiadomość e-mail';

  @override
  String get faqJoinDiscord => 'Dołącz do naszego Discorda';

  @override
  String get faqCannotOpenMailClient => 'Z jakiegoś powodu nie możemy otworzyć twojego klienta poczty. Skopiowaliśmy dla ciebie adres e-mail. Możesz napisać e-mail i wkleić adres w polu odbiorcy.';

  @override
  String get helpUsTranslate => 'Pomóż w tłumaczeniu';

  @override
  String get suggestFeatures => 'Zaproponuj funkcje';

  @override
  String get thankYou => 'Dziękujemy!';

  @override
  String get thankYouContent => 'Wielkie dzięki dla wszystkich naszych niesamowitych tłumaczy, którzy pomagają nam uczynić tę aplikację dostępną dla większej liczby ludzi na całym świecie!';

  @override
  String get helpTranslateContent => 'Możesz nam pomóc przetłumaczyć aplikację na Crowdin. Jeśli Twojego języka nie ma na Crowdin, śmiało poproś o niego na naszym serwerze Discord. Bardzo dziękujemy za pomoc!';

  @override
  String get helpTranslateButton => 'Pomóż przetłumaczyć na Crowdin';

  @override
  String get versionDevice => 'Wersja i Urządzenie';

  @override
  String get loading => 'Wczytywanie...';

  @override
  String get errorLoadingVersion => 'Błąd ładowania wersji';

  @override
  String get currentTranslators => 'Aktualni tłumacze';

  @override
  String get betaFeature => 'Funkcja Beta';

  @override
  String get beta => 'BETA';

  @override
  String get betaDescription => 'Ta funkcja jest obecnie w wersji beta, więc może zawierać pewne błędy lub być niekompletna. Aktywnie pracujemy nad ulepszeniami i z przyjemnością przyjmujemy opinie. Prosimy o dzielenie się pomysłami oraz zgłaszanie wszelkich problemów na naszym serwerze Discord, aby pomóc nam ją udoskonalić.';

  @override
  String get copiedToClipboard => 'Skopiowano do schowka';

  @override
  String get all => 'Wszystkie';

  @override
  String get hourIndicator => 'g';

  @override
  String get minIndicator => 'm';

  @override
  String get noDataAvailable => 'Brak dostępnych danych.';

  @override
  String get close => 'Zamknij';

  @override
  String get closed => 'Zamknięte';

  @override
  String get error => 'Błąd';

  @override
  String get player => 'Gracz';

  @override
  String notFoundOrNotLinkedToOurSystem(String player) {
    return '$player nie został znaleziony lub nie jest powiązany z naszym systemem.';
  }

  @override
  String get tryAnotherNameOrTagOrLinkIt => 'Spróbuj innego nazwy/tagu lub go połącz.';

  @override
  String get playerNotFound => 'Gracz nie znaleziony';

  @override
  String get noValueEntered => 'Nie wprowadzono wartości';

  @override
  String get manage => 'Zarządzaj';

  @override
  String get enterPlayerTag => 'Wprowadź tag gracza';

  @override
  String get add => 'Dodaj';

  @override
  String get delete => 'Usuń';

  @override
  String get addAccount => 'Dodaj konto';

  @override
  String get deleteAccount => 'Usuń konto';

  @override
  String get playerTagNotExists => 'Wprowadzony tag gracza nie istnieje.';

  @override
  String accountAlreadyLinked(Object tag) {
    return '$tag jest już powiązany z kimś innym.';
  }

  @override
  String get enterApiToken => 'Proszę wprowadzić token API konta, aby potwierdzić, że należy do Ciebie. Możesz znaleźć go w ustawieniach Clash of Clans > Więcej ustawień > Token API.';

  @override
  String get wrongApiToken => 'Wprowadzony token API jest nieprawidłowy';

  @override
  String get accountAlreadyLinkedToYou => 'Tag gracza jest już z tobą powiązany.';

  @override
  String get apiToken => 'Token API konta';

  @override
  String get failedToAddTryAgain => 'Nie udało się dodać linku. Spróbuj ponownie później.';

  @override
  String get fillAllFields => 'Please fill all fields.';

  @override
  String get failedToDeleteTryAgain => 'Nie udało się usunąć linku. Spróbuj ponownie później.';

  @override
  String get enterPlayerTagWarning => 'Musisz wpisać tag gracza i kliknąć na \"+\", aby kontynuować.';

  @override
  String get failedToLoadAccountData => 'Failed to load accounts data.';

  @override
  String get loadAccountData => 'Load accounts data';

  @override
  String get search => 'Wyszukaj';

  @override
  String get warning => 'Ostrzeżenie';

  @override
  String get exitAppToOpenClash => 'Zamierzasz opuścić aplikację, aby otworzyć Clash of Clans.';

  @override
  String get confirmLogout => 'Czy na pewno chcesz się wylogować?';

  @override
  String get tagOrNamePlayer => 'Tag lub nazwa gracza';

  @override
  String get searchPlayer => 'Wyszukaj gracza';

  @override
  String get nameOrTagPlayer => 'Nazwa gracza lub tag';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Twój klan to \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(String ratio, String donations, String received) {
    return 'Stosunek twojej dotacji wynosi $ratio. Przekazałeś $donations oddziałów i otrzymałeś $received oddziałów.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Twoje preferencje wojenne to \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'Masz $stars gwiazdek wojennych.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'Masz $trophies puszek. Aktualnie jesteś w $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Twój poziom ratusza to $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Twój poziom Ratusza Budowniczego to $level, a masz $trophies pucharów.';
  }

  @override
  String get dashboard => 'Pulpit';

  @override
  String get homeBase => 'Baza główna';

  @override
  String get th => 'TH';

  @override
  String get builderBase => 'Baza Budowniczego';

  @override
  String get bh => 'BH';

  @override
  String get clanCapital => 'Stolica Klanu';

  @override
  String get leader => 'Lider';

  @override
  String get coLeader => 'Co-Lider';

  @override
  String get elder => 'Starszy';

  @override
  String get member => 'Członek';

  @override
  String get ready => 'Wyrażono zgodę na udział';

  @override
  String get unready => 'Nie wyrażono zgody';

  @override
  String level(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get heroes => 'Bohaterowie';

  @override
  String get equipment => 'Wyposażenie';

  @override
  String get troops => 'Jednostki';

  @override
  String get superTroops => 'Super Jednostki';

  @override
  String get activeSuperTroops => 'Aktywne Super Jednostki';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get pets => 'Pety';

  @override
  String get siegeMachines => 'Maszyny oblężnicze';

  @override
  String get spells => 'Zaklęcia';

  @override
  String get achievements => 'Osiągnięcia';

  @override
  String get byDay => 'Wg dnia';

  @override
  String get bySeason => 'Wg sezonu';

  @override
  String dayIndex(int index) {
    return 'Dzień $index';
  }

  @override
  String indexDays(int index) {
    return '$index dni';
  }

  @override
  String get bestTrophies => 'Najlepsze Puszki';

  @override
  String get mostAttacks => 'Najwięcej Ataków';

  @override
  String get lastSeason => 'Ostatni Sezon';

  @override
  String get bestRank => 'Najlepszy Globalny Ranking';

  @override
  String daysLeft(int days) {
    return 'Pozostało $days dni';
  }

  @override
  String get date => 'Data';

  @override
  String get stats => 'Statystyki';

  @override
  String get fullStats => 'Full Stats';

  @override
  String get details => 'Szczegóły';

  @override
  String get seasonStats => 'Statystyki sezonowe';

  @override
  String get charts => 'Wykresy';

  @override
  String get history => 'Historia';

  @override
  String get legendLeague => 'Liga Legendarna';

  @override
  String get notInLegendLeague => 'Nie w Lidze Legendarnej';

  @override
  String get noLegendsDataToday => 'You\'re not in Legend League, but past seasons are available.';

  @override
  String legendStartDescription(String trophies) {
    return 'Zacząłeś dzień z $trophies pucharów.';
  }

  @override
  String legendNoRankLocalDescription(String country, int trophies) {
    return 'Obecnie nie jesteś w rankingu ($country) z $trophies puszkami.';
  }

  @override
  String legendRankLocalDescription(Object country, Object rank, Object trophies) {
    return 'Obecnie nie jesteś w rankingu $rank ($country) z $trophies puszkami.';
  }

  @override
  String legendGainDescription(int trophies) {
    return 'Zdobyłeś na razie $trophies puszek.';
  }

  @override
  String legendLossDescription(int trophies) {
    return 'Straciłeś $trophies puszek na razie.';
  }

  @override
  String legendNoGlobalRankDescription(int trophies) {
    return 'Obecnie nie jesteś w rankingu globalnym z $trophies puszkami.';
  }

  @override
  String legendGlobalRankDescription(int rank, Object trophies) {
    return 'Jesteś obecnie sklasyfikowany jako $rank globalnie.';
  }

  @override
  String get noRank => 'Brak rankingu';

  @override
  String get started => 'Rozpoczęto';

  @override
  String get ended => 'Zakończony';

  @override
  String get average => 'Średnia';

  @override
  String get remaining => 'Pozostało';

  @override
  String get legendsTitle => 'Nieprecyzyjne dane?';

  @override
  String get legendsExplanation_intro => 'Ze względu na ograniczenia w API Clash of Clans, nasze dane mogą czasami nie być całkowicie dokładne. Dlaczego tak się dzieje:\n';

  @override
  String get legendsExplanation_api_delay_title => '1. Opóźnienie interfejsu API: ';

  @override
  String get legendsExplanation_api_delay_body => 'API może zaktualizować się maksymalnie do 5 minut, co powoduje opóźnienie w odzwierciedleniu zmian w czasie rzeczywistym w puszkach.\n';

  @override
  String get legendsExplanation_concurrent_changes_title => '2. Zmiany jednoczesne: \n';

  @override
  String get legendsExplanation_multiple_attacks_defenses_title => '- Wielokrotne Ataki/Obrony: ';

  @override
  String get legendsExplanation_multiple_attacks_defenses_body => 'Jeśli następuje kilka ataków lub obron w szybkiej kolejności, API może pokazać połączone wyniki (np. +68 lub -68).\n';

  @override
  String get legendsExplanation_simultaneous_attack_defense_title => '- Atak i obrona jednocześnie: ';

  @override
  String get legendsExplanation_simultaneous_attack_defense_body => 'Jeśli atak i obrona wystąpią jednocześnie, możesz zobaczyć mieszany wynik (np. +4).\n';

  @override
  String get legendsExplanation_net_gain_loss_title => '3. Zysk/Strata: ';

  @override
  String get legendsExplanation_net_gain_loss_body => 'Mimo problemów z czasem ogólny zysk lub strata netto za dzień są dokładne. ';

  @override
  String get legendsExplanation_conclusion => 'Te ograniczenia są powszechne we wszystkich narzędziach korzystających z API Clash of Clans. Niestety nie możemy tego naprawić, ponieważ znajduje się to w rękach Supercell. Robimy wszystko, aby zrekompensować te ograniczenia i dostarczyć wyniki możliwie najbliższe rzeczywistości. Dziękujemy za zrozumienie!';

  @override
  String get toDoList => 'Lista rzeczy do zrobienia';

  @override
  String lastActive(String date) {
    return 'Ostatnio aktywny: $date';
  }

  @override
  String get playerNotTracked => 'Ten gracz nie jest śledzony. Dane mogą być niedokładne.';

  @override
  String numberAccounts(int number) {
    return '$number kont';
  }

  @override
  String numberActiveAccounts(int number) {
    return '$number aktywnych kont';
  }

  @override
  String numberInactiveAccounts(int number) {
    return '$number nieaktywnych kont';
  }

  @override
  String get activeAccounts => 'Aktywne konta';

  @override
  String get inactiveAccounts => 'Niektywne konta';

  @override
  String get noInactiveAccounts => 'Brak nieaktywnych kont.';

  @override
  String get noActiveAccounts => 'Brak aktywnych kont.';

  @override
  String get todoExplanation_title => 'Obliczenia zadania';

  @override
  String get todoExplanation_intro => 'Odsetek ukończenia zadania jest obliczany na podstawie następujących działań z określonymi wagami:';

  @override
  String get todoExplanation_legends_title => 'Liga Legendarna:';

  @override
  String get todoExplanation_legends => 'Waga 8 punktów na konto, 1 atak = 1 punkt.';

  @override
  String get todoExplanation_raids_title => 'Rajdy:';

  @override
  String get todoExplanation_raids => 'Waga 5 punktów na konto (lub 6, jeśli ostatni atak został odblokowany), 1 atak = 1 punkt.';

  @override
  String get todoExplanation_clanWars_title => 'Klanowa wojna:';

  @override
  String get todoExplanation_clanWars => 'Waga 2 punktów na konto, 1 atak = 1 punkt.';

  @override
  String get todoExplanation_cwl_title => 'Wojna Ligowa:';

  @override
  String get todoExplanation_cwl => 'Waga 1 punktu na konto, 1 atak = 1 punkt. CWL nie może być śledzone, jeśli gracz nie jest w swoim klanie ligowym.';

  @override
  String get todoExplanation_passAndGames_title => 'Przepustka Sezonowa i Gry Klanowe:';

  @override
  String get todoExplanation_passAndGames => 'Waga 2 punktów każdy na konto. Stosunek opiera się na liczbie pozostałych dni (1 miesiąc dla przepustki i 6 dni dla gier). Zielony = na dobrej drodze do ukończenia przepustki lub gier, czerwony = opóźnienie w harmonogramie.';

  @override
  String get todoExplanation_conclusion => 'Ostateczny procent jest obliczany poprzez podzielenie łącznej liczby akcji wykonanych podczas trwających wydarzeń przez całkowitą liczbę wymaganych akcji. Konta nieaktywne przez ponad 14 dni są wykluczone z obliczeń.';

  @override
  String get worst => 'Najgorszy';

  @override
  String get best => 'Najlepszy';

  @override
  String get total => 'Ogółem';

  @override
  String get heroesEquipments => 'Wyposażenie bohaterów';

  @override
  String daysAgo(int days) {
    return '$days dni temu';
  }

  @override
  String dayAgo(int day) {
    return '$day dzień temu';
  }

  @override
  String hourAgo(int hour) {
    return '$hour godzinę temu';
  }

  @override
  String hoursAgo(int hours, Object Hours) {
    return '$hours godzin temu';
  }

  @override
  String minuteAgo(int minute) {
    return '$minute minutę temu';
  }

  @override
  String minutesAgo(int minutes) {
    return '$minutes minut temu';
  }

  @override
  String secondAgo(int seconds) {
    return '$seconds sekund temu';
  }

  @override
  String get justNow => 'Właśnie teraz';

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
  String get trophiesByMonth => 'Puchary według miesiąca';

  @override
  String get trophiesBySeason => 'Puchary według sezonu';

  @override
  String get eosTrophies => 'Puszki Na Koniec Sezonu';

  @override
  String get eosDetails => 'End Of Season Details';

  @override
  String get searchClan => 'Wyszukaj klan';

  @override
  String get clanName => 'Clan\'s name';

  @override
  String get nameOrTagClan => 'Nazwa klanu lub tag';

  @override
  String get noResult => 'Brak wyników.';

  @override
  String get filters => 'Filtry';

  @override
  String get whatever => 'Cokolwiek';

  @override
  String get any => 'Dowolny';

  @override
  String get notSet => 'Nie ustawione';

  @override
  String get warFrequency => 'Częstotliwość wojny';

  @override
  String get minimumMembers => 'Minimalna liczba członków';

  @override
  String get maximumMembers => 'Maksymalna liczba członków';

  @override
  String get location => 'Lokalizacja';

  @override
  String get minimumClanPoints => 'Minimalna liczba punktów klanowych';

  @override
  String get minimumClanLevel => 'Minimalny poziom klanu';

  @override
  String get noClan => 'Brak klanu';

  @override
  String get joinClanToUnlockNewFeatures => 'Dołącz do klanu, aby odblokować nowe funkcje.';

  @override
  String get apply => 'Zastosuj';

  @override
  String get opened => 'Otwarty';

  @override
  String get inviteOnly => 'Tylko na zaproszenie';

  @override
  String get cancel => 'Anuluj';

  @override
  String get clan => 'Klan';

  @override
  String get clans => 'Klany';

  @override
  String get members => 'Członkowie';

  @override
  String get role => 'Rola';

  @override
  String get expLevel => 'Poziom doświadczenia';

  @override
  String get townHallLevel => 'Poziom ratusza';

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
    return 'Ratusz $level';
  }

  @override
  String get byNumberOfWars => 'Według liczby wojen';

  @override
  String get ok => 'Ok';

  @override
  String get byDateRange => 'Według zakresu dat';

  @override
  String get selectSeason => 'Wybierz sezon';

  @override
  String get year => 'Rok';

  @override
  String get month => 'Miesiąc';

  @override
  String get allTownHalls => 'Wszystkie Ratusze';

  @override
  String seasonDate(String date) {
    return 'sezon $date';
  }

  @override
  String lastXwars(int number) {
    return 'Ostatnie $number wojen';
  }

  @override
  String get friendly => 'Przyjazne';

  @override
  String get cwl => 'CWL';

  @override
  String get random => 'Losowe';

  @override
  String get selectMembersThLevel => 'Poziomy TH członków';

  @override
  String get selectOpponentsThLevel => 'Poziomy TH przeciwnika';

  @override
  String get equalThLevel => 'Równy TH';

  @override
  String get builderBaseTrophies => 'BB Puszki';

  @override
  String get donations => 'Dotacje';

  @override
  String get donationsReceived => 'Otrzymane Dotacje';

  @override
  String get donationsRatio => 'Wskaźnik dotacji';

  @override
  String get trophies => 'Puchary';

  @override
  String get always => 'Zawsze';

  @override
  String get never => 'Nigdy';

  @override
  String get unknown => 'Nieznane';

  @override
  String get oncePerWeek => '1/tydzień';

  @override
  String get twicePerWeek => '2/tydzień';

  @override
  String get rarely => 'Rzadko';

  @override
  String get warLeague => 'Wojna/Liga';

  @override
  String get war => 'Wojna';

  @override
  String get league => 'Liga';

  @override
  String get wars => 'Wojny';

  @override
  String get ongoingWar => 'Trwająca wojna';

  @override
  String get ongoingCwl => 'Trwające CWL';

  @override
  String get cantOpenLink => 'Nie możemy otworzyć tego linku.';

  @override
  String get notInWar => 'Nie jest na wojnie';

  @override
  String get warHistory => 'Historia wojen';

  @override
  String warHistoryWinsDescription(int wins, String percent) {
    return 'Twój klan wygrał $wins wojen ($percent%) w ostatnich 50 wojnach.';
  }

  @override
  String warHistoryLossesDescription(int losses, String percent) {
    return 'Twój klan przegrał $losses wojen ($percent%) w ostatnich 50 wojnach.';
  }

  @override
  String warHistoryDrawsDescription(int draws, String percent) {
    return 'Twój klan miał $draws remisów ($percent proc.) w ostatnich 50 wojnach.';
  }

  @override
  String warHistoryAverageMembersDescription(int members) {
    return 'Twój klan ma średnio $members członków uczestniczących w ostatnich 50 wojnach.';
  }

  @override
  String warHistoryAverageWarStarsDescription(double stars, String percent) {
    return 'Twój klan ma średnio $stars gwiazdek na końcu ostatnich 50 wojen. Odpowiada to $percent wszystkich gwiazdek.';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return 'Twój klan ma średni wskaźnik zniszczenia $percent na koniec ostatnich 50 wojen.';
  }

  @override
  String warHistoryAverageClanStarsPerMember(Object stars) {
    return 'Twój klan ma średnio $stars gwiazdek na członka w ostatnich 50 wojnach.';
  }

  @override
  String warHistoryAverageMembers(int members) {
    return '~$members członków na wojnę';
  }

  @override
  String get averageStars => 'Średnie gwiazdki';

  @override
  String get averageDestruction => 'Średnie zniszczenia';

  @override
  String get oneStar => '1 gwiazdka';

  @override
  String get twoStars => '2 gwiazdki';

  @override
  String get threeStars => '3 gwiazdki';

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
  String get defZeroStar => '0 Star (def)';

  @override
  String get defOneStar => '1 Star (def)';

  @override
  String get defTwoStars => '2 Stars (def)';

  @override
  String get defThreeStars => '3 Stars (def)';

  @override
  String get lowerTownHallAttack => 'Lower TH Attack';

  @override
  String get upperTownHallAttack => 'Upper TH Attack';

  @override
  String get lowerTownHallDefense => 'Lower TH Defense';

  @override
  String get upperTownHallDefense => 'Upper TH Defense';

  @override
  String get warParticipation => 'Udział w wojnie';

  @override
  String get missed => 'Missed';

  @override
  String get totalStars => 'Total';

  @override
  String get averageAbbr => 'Avg';

  @override
  String get destruction => 'Destruction';

  @override
  String get averageDestructionAbbr => 'Avg %';

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
  String get toggleTownHallVisibility => 'Ukryj/pokaż statystyki z poprzednich poziomów TH';

  @override
  String get warLog => 'Dziennik wojenny';

  @override
  String get publicWarLog => 'Publiczny Dziennik Wojny';

  @override
  String get privateWarLog => 'Prywatny dziennik Wojny';

  @override
  String startsIn(String time) {
    return 'Zaczyna się za $time';
  }

  @override
  String startsAt(String time) {
    return 'Zaczyna się o $time';
  }

  @override
  String endsIn(String time) {
    return 'Kończy się za $time';
  }

  @override
  String endsAt(String time) {
    return 'Kończy się o $time';
  }

  @override
  String get joinLeaveLogs => 'Dołącz / opuść dziennik';

  @override
  String get join => 'Dołącz';

  @override
  String get leave => 'Opuść';

  @override
  String get reset => 'Zresetuj';

  @override
  String leaveNumberDescription(int number, String date) {
    return '$number graczy opuściło klan w trakcie obecnego sezonu ($date).';
  }

  @override
  String joinNumberDescription(int number, String date) {
    return '$number graczy dołączyło do klanu w trakcie obecnego sezonu ($date).';
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
    return 'Twój klan stracił $number członków w tym sezonie ($date).';
  }

  @override
  String joinLeaveDifferenceEqualDescription(String date) {
    return 'Twój klan ma tę samą liczbę członków, co na początku sezonu ($date).';
  }

  @override
  String leftOnAt(String date, String time) {
    return 'Opuścił $date o $time.';
  }

  @override
  String joinedOnAt(String date, String time) {
    return 'Dołączono w dniu $date o godz. $time.';
  }

  @override
  String get statistics => 'Statystyki';

  @override
  String get stars => 'Gwiazdki';

  @override
  String get numberOfStars => 'Liczba gwiazdek';

  @override
  String get destructionRate => 'Wskaźnik zniszczeń';

  @override
  String get events => 'Wydarzenia';

  @override
  String get team => 'Drużyny';

  @override
  String get myTeam => 'Moja drużyna';

  @override
  String get enemiesTeam => 'Przeciwnicy';

  @override
  String get defense => 'Obrona';

  @override
  String get defenses => 'Obrona';

  @override
  String get bestDefenses => 'Best defenses';

  @override
  String bestDefenseOutOf(int number) {
    return 'Best defense (out of $number)';
  }

  @override
  String get attack => 'Atak';

  @override
  String get attacks => 'Ataki';

  @override
  String get bestAttacks => 'Best attacks';

  @override
  String get noAttackYet => 'No attack yet';

  @override
  String get noDefenseYet => 'No defense yet';

  @override
  String get bestPerformance => 'Best performance';

  @override
  String get victory => 'Zwycięstwo';

  @override
  String get defeat => 'Przegrana';

  @override
  String get draw => 'Remis';

  @override
  String get perfectWar => 'Perfekcyjna wojna';

  @override
  String get newest => 'Najnowszy';

  @override
  String get oldest => 'Najstarszy';

  @override
  String get warEnded => 'Zakończyła się wojna';

  @override
  String get preparation => 'Przygotowanie';

  @override
  String isNotInWar(String clan) {
    return '$clan nie jest na wojnie.';
  }

  @override
  String warLogIsClosed(String clan) {
    return 'Dziennik wojenny $clan jest zamknięty.';
  }

  @override
  String get askForWar => 'Skontaktuj się z liderem lub co-liderem, aby rozpocząć wojnę.';

  @override
  String get askForWarLogOpening => 'Skontaktuj się z liderem lub co-liderem, aby otworzyć dziennik wojenny.';

  @override
  String get warLogClosed => 'Dziennik wojenny jest zamknięty.';

  @override
  String get rounds => 'Rundy';

  @override
  String roundNumber(int number) {
    return 'Round $number';
  }

  @override
  String currentRound(int number) {
    return 'Current round (Round $number)';
  }

  @override
  String get noDataAvailableForThisWar => 'Brak dostępnych danych dla tej wojny';

  @override
  String get stateOfTheWar => 'Stan wojny';

  @override
  String starsNeededToTakeTheLead(String clan, int star, int star2, String percent, Object stars2) {
    return '$clan wciąż potrzebuje $star więcej gwiazdek lub $stars2 gwiazdek i $percent% aby objąć prowadzenie.';
  }

  @override
  String starsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan wciąż potrzebuje $percent% albo jeszcze 1 gwiazdkę, aby objąć prowadzenie';
  }

  @override
  String get clanDraw => 'Oba klany zremisowały';

  @override
  String get fastCalculator => 'Szybki kalkulator';

  @override
  String fastCalculatorAnswer(String percentNeedeed, String result, Object percentNeeded) {
    return 'Aby osiągnąć wskaźnik zniszczenia $percentNeeded%, potrzebne jest łącznie $result%.';
  }

  @override
  String get teamSize => 'Rozmiar drużyny';

  @override
  String get neededOverall => '% Potrzebne ogółem';

  @override
  String get calculate => 'Oblicz';

  @override
  String get warStats => 'Statystyki wojenne';

  @override
  String get membersStats => 'Statystyki członków';

  @override
  String get clanWarLeague => 'Wojna Ligowa';

  @override
  String cwlRank(int rank) {
    return 'Twój klan jest obecnie sklasyfikowany jako $rank.';
  }

  @override
  String cwlStars(int stars) {
    return 'Twój klan ma ogólnie $stars gwiazd.';
  }

  @override
  String cwlMissingStarsFromNext(int stars) {
    return 'W Twoim klanie brakuje $stars gwiazd, aby dogonić kolejny klan.';
  }

  @override
  String cwlMissingStarsFromFirst(int stars) {
    return 'Twój klan potrzebuje $stars gwiazd, aby dogonić pierwszy klan.';
  }

  @override
  String cwlDestructionPercentage(String percent) {
    return 'Twój klan ma ogólny wskaźnik zniszczenia wynoszący $percent%.';
  }

  @override
  String cwlTotalAttacks(int attacks, int totalAttacks) {
    return 'Your clan has a total of $attacks attacks out of $totalAttacks possible attacks.';
  }

  @override
  String cwlCurrentRound(int round) {
    return 'Obecnie jest runda $round.';
  }

  @override
  String get noAccountLinkedToYourProfileFound => 'Nie znaleziono konta powiązanego z Twoim profilem';

  @override
  String get management => 'Zarządzanie';

  @override
  String get comingSoon => 'Dostępne wkrótce!';

  @override
  String get connectionError => 'Wystąpił błąd. Sprawdź swoje połączenie internetowe i spróbuj ponownie.';

  @override
  String get connectionErrorRelaunch => 'Wystąpił błąd. Sprawdź swoje połączenie internetowe i uruchom aplikację ponownie.';

  @override
  String updatedAt(String time) {
    return 'Zaktualizowano o $time';
  }

  @override
  String get tools => 'Narzędzia';

  @override
  String get community => 'Społeczność';

  @override
  String get lastRaids => 'Ostatnie rajdy';

  @override
  String get ongoingRaids => 'Trwające rajdy';

  @override
  String get districtsDestroyed => 'Dzielnice zniszczone';

  @override
  String get raidsCompleted => 'Ukończone rajdy';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get maintenanceDescription => 'Clash of Clans is currently under maintenance, so we can\'t access the API. Please check back later.';

  @override
  String get tryAgain => 'Try again';
}
