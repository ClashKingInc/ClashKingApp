// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'ClashKing';

  @override
  String get appDescription =>
      'Ваш кращий супутник Clash of Clans для відстеження статистики, управління кланами та аналізу продуктивності.';

  @override
  String get generalLoading => 'Завантаження...';

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
  String get generalRetry => 'Повторити';

  @override
  String get generalTryAgain => 'Спробуйте ще раз';

  @override
  String get generalCancel => 'Скасувати';

  @override
  String get generalOk => 'ОК';

  @override
  String get generalApply => 'Застосувати';

  @override
  String get generalConfirm => 'Confirm';

  @override
  String get generalManage => 'Керувати';

  @override
  String get generalSettings => 'Налаштування';

  @override
  String get generalCopiedToClipboard => 'Скопійовано в буфер обміну';

  @override
  String get generalComingSoon => 'Незабаром!';

  @override
  String generalLastRefresh(String time) {
    return 'Last refresh: $time';
  }

  @override
  String generalRefreshFailed(String error) {
    return 'Refresh failed: $error';
  }

  @override
  String get generalAll => 'Всі';

  @override
  String get generalTotal => 'Всього';

  @override
  String get generalBest => 'Найкращий';

  @override
  String get generalWorst => 'Найгірший';

  @override
  String get generalAverage => 'Середнє значення';

  @override
  String get generalRemaining => 'Залишилося';

  @override
  String get generalActive => 'Active';

  @override
  String get generalInactive => 'Inactive';

  @override
  String get generalStarted => 'Почато';

  @override
  String get generalEnded => 'Завершено';

  @override
  String get generalRole => 'Роль';

  @override
  String get generalStats => 'Статистика';

  @override
  String get generalFullStats => 'Full Stats';

  @override
  String get generalDetails => 'Детальніше';

  @override
  String get generalHistory => 'Історія';

  @override
  String get generalFilters => 'Фільтри';

  @override
  String get generalNotSet => 'Не вибрано';

  @override
  String get generalWarning => 'Попередження';

  @override
  String get generalNoDataAvailable => 'Дані відсутні.';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authLogin => 'Увійти';

  @override
  String get authLogout => 'Вийти';

  @override
  String get authCreateAccount => 'Create Account';

  @override
  String get authJoinClashKing => 'Join ClashKing';

  @override
  String get authCreateClashKingAccount => 'Create ClashKing Account';

  @override
  String get authCreateAccountToGetStarted =>
      'Create your account to get started';

  @override
  String get authAlreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get authConfirmLogout => 'Впевнені, що хочете вийти?';

  @override
  String get authDiscordTitle => 'Discord';

  @override
  String get authDiscordSignIn => 'Увійти за допомогою Discord';

  @override
  String get authDiscordContinue => 'Continue with Discord';

  @override
  String get authDiscordDescription =>
      'Sync your data with ClashKing Bot and unlock the full potential of ClashKing!';

  @override
  String get authEmailTitle => 'Email';

  @override
  String get authEmailDescription =>
      'Use email if you can\'t access Discord or prefer app-only features';

  @override
  String get authEmailRequired => 'Please enter your email';

  @override
  String get authEmailInvalid => 'Please enter a valid email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordConfirm => 'Confirm Password';

  @override
  String get authPasswordRequired => 'Please enter your password';

  @override
  String get authPasswordConfirmRequired => 'Please confirm your password';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get authPasswordRequirements =>
      'Password must contain: uppercase, lowercase, digit, and special character';

  @override
  String get authPasswordForgot => 'Forgot password?';

  @override
  String get authUsernameLabel => 'Ім\'я користувача';

  @override
  String get authUsernameRequired => 'Будь ласка, введіть ім\'я користувача';

  @override
  String get authUsernameTooShort => 'Username must be at least 3 characters';

  @override
  String get authErrorConnection =>
      'Сталася помилка. Перевірте підключення до Інтернету та спробуйте ще раз.';

  @override
  String get authErrorConnectionRelaunch =>
      'Сталася помилка. Будь ласка, перевірте підключення до Інтернету та перезапустіть додаток.';

  @override
  String get authAccountManagement => 'Account Management';

  @override
  String get authAccountConnected => 'Connected Accounts';

  @override
  String get authAccountConnectedStatus => 'Connected';

  @override
  String get authAccountNotConnected => 'Not connected';

  @override
  String get authAccountEmailAndPassword => 'Email & Password';

  @override
  String get authAccountSecured =>
      'Your account is secured with multiple authentication methods';

  @override
  String get authAccountLinkEmail => 'Link Email Account';

  @override
  String get authAccountAddEmailAuth =>
      'Add email & password authentication to your account for additional security.';

  @override
  String get authAccountEmailLinkedSuccess =>
      'Email account successfully linked!';

  @override
  String get helpTitle => 'Need help?';

  @override
  String get helpJoinDiscord => 'Join Discord';

  @override
  String get helpEmailUs => 'Email Us';

  @override
  String get accountsWelcome => 'Вітаємо!';

  @override
  String get accountsWelcomeMessage =>
      'Будь ласка, додайте один або кілька облікових записів Clash of Clans до свого профілю. Ви можете додати або видалити облікові записи пізніше.';

  @override
  String get accountsManageTitle => 'Manage your accounts';

  @override
  String get accountsNoneFound =>
      'Не знайдено облікового запису, пов\'язаного з вашим профілем';

  @override
  String get accountsPlayerTag => 'Player Tag (#ABC123)';

  @override
  String get accountsEnterPlayerTag => 'Введіть тег гравця';

  @override
  String get accountsAdd => 'Додати обліковий запис';

  @override
  String get accountsDelete => 'Видалити обліковий запис';

  @override
  String get accountsApiToken => 'API-токен облікового запису';

  @override
  String get accountsEnterApiToken =>
      'Будь ласка, введіть ключ API для облікового запису. Його можна знайти у налаштуваннях Clash of Clans > Додаткові Налаштування > Токен API.';

  @override
  String get accountsFillAllFields => 'Please fill all fields.';

  @override
  String get accountsErrorTagNotExists =>
      'Тег гравця, який був введений, не існує.';

  @override
  String accountsErrorAlreadyLinked(Object tag) {
    return 'Тег гравця вже зв\'язаний з кимось.';
  }

  @override
  String get accountsErrorAlreadyLinkedToYou =>
      'Тег гравця вже прив\'язаний до вас.';

  @override
  String get accountsErrorWrongApiToken => 'Введений токен API невірний';

  @override
  String get accountsErrorFailedToAdd =>
      'Failed to add the account. Please try again later.';

  @override
  String get accountsErrorFailedToDelete =>
      'Не вдалося видалити посилання. Будь ласка, повторіть спробу пізніше.';

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
  String get errorLoadingVersion => 'Помилка при завантаженні версії';

  @override
  String get errorCannotOpenLink => 'Ми не можемо відкрити це посилання.';

  @override
  String get errorExitAppToOpenClash =>
      'Ви збираєтеся вийти з програми для відкриття Clash of Clans.';

  @override
  String get playerSearchTitle => 'Пошук гравця';

  @override
  String get playerSearchPlaceholder => 'Ім\'я гравця або тег';

  @override
  String playerLastActive(String date) {
    return 'Остання активність: $date';
  }

  @override
  String get playerNotTracked =>
      'Цей гравець не відстежується. Дані можуть бути неточні.';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Ваш клан \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(
      String ratio, String donations, String received) {
    return 'Ваш коефіцієнт підкріплення $ratio. Ви пожертвували війська $donations та отримали $received військ.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Ваші налаштування війни \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'У вас $stars військових зірок.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'У вас $trophies трофеїв. Ви зараз у $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Ваш рівень ратуші – $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Ваша ратуша будівельника $level рівня, і ви маєте $trophies трофеїв.';
  }

  @override
  String get gameBaseHome => 'Домашня база';

  @override
  String get gameBaseBuilder => 'База будівельника';

  @override
  String get gameClanCapital => 'Столиця клану';

  @override
  String get gameTownHall => 'ТХ';

  @override
  String get gameTownHallLevel => 'Рівень ратуші';

  @override
  String gameTownHallLevelNumber(int level) {
    return 'Ратуша $level';
  }

  @override
  String gameTHLevel(int level) {
    return 'ТХ$level';
  }

  @override
  String get gameExpLevel => 'Рівень досвіду';

  @override
  String get gameTrophies => 'Трофеї';

  @override
  String get gameBuilderBaseTrophies => 'ББ Трофеї';

  @override
  String get gameDonations => 'Пожертви';

  @override
  String get gameDonationsReceived => 'Пожертв отримано';

  @override
  String get gameDonationsRatio => 'Співвідношення пожертв';

  @override
  String gameLevel(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get gameHeroes => 'Герої';

  @override
  String get gameEquipment => 'Спорядження';

  @override
  String get gameHeroesEquipments => 'Спорядження героя';

  @override
  String get gameTroops => 'Війська';

  @override
  String get gameActiveSuperTroops => 'Активні Супер Війська';

  @override
  String get gamePets => 'Тварини';

  @override
  String get gameSiegeMachines => 'Облогові машини';

  @override
  String get gameSpells => 'Заклинання';

  @override
  String get gameAchievements => 'Досягнення';

  @override
  String get gameClanGames => 'Clan Games';

  @override
  String get gameSeasonPass => 'Season Pass';

  @override
  String get gameCreatorCode => 'Код Творця: ClashKing';

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
  String get clanTitle => 'Клан';

  @override
  String get clanSearchTitle => 'Пошук клану';

  @override
  String get clanSearchPlaceholder => 'Clan\'s name';

  @override
  String get clanNone => 'Без клану';

  @override
  String get clanJoinToUnlock =>
      'Приєднуйтеся до клану, щоб розблокувати нові можливості.';

  @override
  String get clanMembers => 'Учасники';

  @override
  String get clanWarFrequency => 'Частота війн';

  @override
  String get clanMinimumMembers => 'Мінімальна кількість учасників';

  @override
  String get clanMaximumMembers => 'Максимальна кількість учасників';

  @override
  String get clanLocation => 'Розташування';

  @override
  String get clanMinimumPoints => 'Мінімальні очки клану';

  @override
  String get clanMinimumLevel => 'Мінімальний рівень клану';

  @override
  String get clanInviteOnly => 'За запрошенням';

  @override
  String get clanOpened => 'Відчинено';

  @override
  String get clanClosed => 'Закрито';

  @override
  String get clanRoleLeader => 'Лідер';

  @override
  String get clanRoleCoLeader => 'Спів-лідер';

  @override
  String get clanRoleElder => 'Старійшина';

  @override
  String get clanRoleMember => 'Учасник';

  @override
  String get clanWarFrequencyAlways => 'Завжди';

  @override
  String get clanWarFrequencyNever => 'Ніколи';

  @override
  String get clanWarFrequencyUnknown => 'Невизначено';

  @override
  String get clanWarFrequencyOncePerWeek => '1/тиждень';

  @override
  String get clanWarFrequencyMoreThanOncePerWeek => 'More than 1/week';

  @override
  String get clanWarFrequencyRarely => 'Рідко';

  @override
  String get timeHourIndicator => 'год';

  @override
  String timeDaysAgo(int days) {
    return '$days Днів тому';
  }

  @override
  String timeDayAgo(int day) {
    return '$day День тому';
  }

  @override
  String timeHourAgo(int hour) {
    return '$hour Годину тому';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours Годин тому';
  }

  @override
  String timeMinuteAgo(int minute) {
    return '$minute Хвилину тому';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes Хвилин тому';
  }

  @override
  String get timeJustNow => 'Щойно';

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
    return 'Розпочнеться через $time';
  }

  @override
  String timeStartsAt(String time) {
    return 'Починається о $time';
  }

  @override
  String timeEndsIn(String time) {
    return 'Закінчиться через $time';
  }

  @override
  String timeEndsAt(String time) {
    return 'Закінчується о $time';
  }

  @override
  String get legendsTitle => 'Некоректні дані?';

  @override
  String get legendsNotInLeague => 'Не в Легендарній Лізі';

  @override
  String get legendsNoDataToday =>
      'You\'re not in Legend League, but past seasons are available.';

  @override
  String legendsStartDescription(String trophies) {
    return 'Ви розпочали день з $trophies трофеїв.';
  }

  @override
  String legendsNoRankLocalDescription(String country, int trophies) {
    return 'Наразі вас немає в рейтингу ($country) з $trophies трофеями.';
  }

  @override
  String legendsRankLocalDescription(int rank, String country, int trophies) {
    return 'Зараз ви займаєте $rank місце в топі ($country) з $trophies трофеями.';
  }

  @override
  String legendsGainDescription(int trophies) {
    return 'Зараз ви отримали $trophies трофеїв.';
  }

  @override
  String legendsLossDescription(int trophies) {
    return 'Зараз ви втратили $trophies трофеїв.';
  }

  @override
  String legendsNoGlobalRankDescription(int trophies) {
    return 'Наразі ви не в глобальному рейтингу з $trophies трофеями.';
  }

  @override
  String legendsGlobalRankDescription(int rank, int trophies) {
    return 'You are currently ranked $rank globally with $trophies trophies.';
  }

  @override
  String get legendsNoRank => 'Немає рейтингу';

  @override
  String get legendsBestTrophies => 'Кращі Трофеї';

  @override
  String get legendsMostAttacks => 'Найбільша кількість атак';

  @override
  String get legendsLastSeason => 'Минулий сезон';

  @override
  String get legendsBestRank => 'Найкращий глобальний ранг';

  @override
  String get legendsTrophiesBySeason => 'Трофеї за сезон';

  @override
  String get legendsEosTrophies => 'Трофеї в кінці сезону';

  @override
  String get legendsEosDetails => 'End Of Season Details';

  @override
  String get legendsInaccurateTitle => 'Некоректні дані?';

  @override
  String get legendsInaccurateIntro =>
      'Через обмеження Clash of Clans API, наші дані можуть бути не завжди точними. Ось чому:\n';

  @override
  String get legendsInaccurateApiDelayTitle => '1. Затримка API: ';

  @override
  String get legendsInaccurateApiDelayBody =>
      'API може оновлюватися до 5 хвилин, що спричиняє затримку у зображенні змін трофеїв в реальному часі.\n';

  @override
  String get legendsInaccurateConcurrentTitle => '2. Можливі зміни: \n';

  @override
  String get legendsInaccurateMultipleAttacksTitle =>
      '- Кілька нападів/Захистів: ';

  @override
  String get legendsInaccurateMultipleAttacksBody =>
      'Якщо декілька атак або захистів відбуваються одна за одною швидко, API може показати комбіновані результати (наприклад, +68 або -68).\n';

  @override
  String get legendsInaccurateSimultaneousTitle =>
      '- Одночасна атака та оборона: ';

  @override
  String get legendsInaccurateSimultaneousBody =>
      'Якщо напад та захист відбуваються одночасно, ви можете побачити змішаний результат (наприклад, +4).\n';

  @override
  String get legendsInaccurateNetGainTitle => '3. Чистий прибуток/збиток: ';

  @override
  String get legendsInaccurateNetGainBody =>
      'Всупереч проблемі з часом, загальний чистий приріст або втрата за день точні. ';

  @override
  String get legendsInaccurateConclusion =>
      'Ці обмеження поширені у всіх інструментах, які використовують API гри Clash of Clans. Нам дуже шкода, що ми не можемо це виправити, оскільки це у руках Supercell. Ми робимо все можливе, щоб компенсувати ці обмеження та надати результати якомога ближчі до реальності. Дякуємо за розуміння!';

  @override
  String get statsSeasonStats => 'Статистика сезону';

  @override
  String get statsByDay => 'За день';

  @override
  String get statsBySeason => 'За сезон';

  @override
  String statsDayIndex(int index) {
    return 'День $index';
  }

  @override
  String statsIndexDays(int index) {
    return '$index Днів';
  }

  @override
  String statsSeasonDate(String date) {
    return 'Сезон $date';
  }

  @override
  String get statsAllTownHalls => 'Всі ратуші';

  @override
  String get statsMembers => 'Статистика учасників';

  @override
  String get todoTitle => 'Список справ';

  @override
  String get todoExplanationTitle => 'Розрахунок завдання';

  @override
  String get todoExplanationIntro =>
      'Відсоток завершення завдання обчислюється на основі наступних дій з конкретними ваговими коефіцієнтами:';

  @override
  String get todoExplanationLegendsTitle => 'Легендарна Ліга:';

  @override
  String get todoExplanationLegends =>
      'Вага 8 очок за обліковий запис, 1 атака = 1 очко.';

  @override
  String get todoExplanationRaidsTitle => 'Рейди:';

  @override
  String get todoExplanationRaids =>
      'Вага 5 балів за обліковий запис (або 6, якщо останню атаку розблоковано), 1 атака = 1 бал.';

  @override
  String get todoExplanationClanWarsTitle => 'Кланові Війни:';

  @override
  String get todoExplanationClanWars =>
      'Вага 2 бали на рахунок, 1 атака = 1 бал.';

  @override
  String get todoExplanationCwlTitle => 'Ліга Війни Кланів:';

  @override
  String get todoExplanationCwl =>
      'Вага 1 бал за обліковий запис, 1 напад = 1 бал. CWL не може бути відстежено, якщо гравець не перебуває у своєму клані ліги.';

  @override
  String get todoExplanationPassAndGamesTitle =>
      'Сезонний пропуск та кланові ігри:';

  @override
  String get todoExplanationPassAndGames =>
      'Вага по 2 бали кожен на рахунок. Співвідношення ґрунтується на залишку днів (1 місяць на пропуск і 6 днів на ігри). Зелений = на шляху до завершення пропуску або ігор, червоний = позаду графіка.';

  @override
  String get todoExplanationConclusion =>
      'Загальний відсоток обчислюється шляхом ділення загальної кількості виконаних дій під час поточних подій на загальну кількість необхідних дій. Обліковий запис, неактивний протягом більш як 14 днів, виключаються з розрахунку.';

  @override
  String todoAccountsNumber(int number) {
    return '$number Облікових записів';
  }

  @override
  String todoAccountsNumberActive(int number) {
    return '$number Активних облікових записів';
  }

  @override
  String todoAccountsNumberInactive(int number) {
    return '$number Неактивних облікових записів';
  }

  @override
  String get todoAccountsActive => 'Активні облікові записи';

  @override
  String get todoAccountsInactive => 'Неактивні облікові записи';

  @override
  String get todoAccountsNoInactive => 'Немає неактивних облікових записів.';

  @override
  String get todoAccountsNoActive => 'Немає активних облікових записів.';

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
  String get warTitle => 'Війна';

  @override
  String get warFrequency => 'Частота війн';

  @override
  String get warParticipation => 'Участь у війні';

  @override
  String get warLeague => 'Війна/Ліга';

  @override
  String get warHistory => 'Історія війн';

  @override
  String get warLog => 'Журнал війн';

  @override
  String warLogClosed(String clan) {
    return 'Журнал війн закритий.';
  }

  @override
  String get warStats => 'Статистика війни';

  @override
  String get warOngoing => 'Поточна війна';

  @override
  String warIsNotInWar(String clan) {
    return '$clan Не знаходиться у війні.';
  }

  @override
  String get warAskForWar =>
      'Звертайтеся до лідера або спів-лідера, щоб розпочати війну.';

  @override
  String get warAskForWarLogOpening =>
      'Звертайтеся до лідера або спів-лідера, аби відкрити журнал бою.';

  @override
  String get warEnded => 'Війна завершилася';

  @override
  String get warPreparation => 'Підготовка';

  @override
  String get warPerfectWar => 'Ідеальна війна';

  @override
  String get warVictory => 'Перемога';

  @override
  String get warDefeat => 'Поразка';

  @override
  String get warDraw => 'Нічия';

  @override
  String get warTeamSize => 'Розмір команди';

  @override
  String get warMyTeam => 'Моя команда';

  @override
  String get warEnemiesTeam => 'Вороги';

  @override
  String get warClanDraw => 'Два клани зв\'язані';

  @override
  String get warStateOfTheWar => 'Стан війни';

  @override
  String warStarsNeededToTakeTheLead(
      String clan, int star, int stars2, String percent) {
    return '$clan Все ще потребує $star зірок або $stars2 зірки та $percent%, щоб вийти вперед.';
  }

  @override
  String warStarsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan Все ще потребує $percent% або ще 1 зірку, щоб взяти на себе ініціативу';
  }

  @override
  String get warNoDataAvailableForThisWar => 'Дані недоступні для цієї війни';

  @override
  String get warCalculatorFast => 'Розрахунок %';

  @override
  String warCalculatorAnswer(String percentNeeded, String result) {
    return 'Для досягнення рівня руйнування $percentNeeded%, необхідно підсумок $result%.';
  }

  @override
  String get warCalculatorNeededOverall => '% Потрібно загалом';

  @override
  String get warCalculatorCalculate => 'Розрахувати';

  @override
  String get warAttacksTitle => 'Атаки';

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
  String get warDefensesTitle => 'Захисти';

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
  String get warStarsTitle => 'Зірки';

  @override
  String get warStarsAverage => 'Середні зірки';

  @override
  String get warStarsNumber => 'Кількість зірок';

  @override
  String get warStarsOne => '1 зірка';

  @override
  String get warStarsTwo => '2 зірки';

  @override
  String get warStarsThree => '3 зірки';

  @override
  String get warStarsZero => '0 Star';

  @override
  String get warStarsBestPerformance => 'Best performance';

  @override
  String get warDestructionTitle => 'Destruction';

  @override
  String get warDestructionAverage => 'Середнє знищення';

  @override
  String get warDestructionRate => 'Рівень руйнування';

  @override
  String warHistoryWinsDescription(int wins, String percent) {
    return 'Ваш клан виграв $wins війн ($percent%) з останніх 50 війн.';
  }

  @override
  String warHistoryLossesDescription(int losses, String percent) {
    return 'Ваш клан програв $losses війн ($percent%) з останніх 50 війн.';
  }

  @override
  String warHistoryDrawsDescription(int draws, String percent) {
    return 'У вашому клані було $draws нічиїх ($percent%) з останніх 50 війн.';
  }

  @override
  String warHistoryAverageMembersDescription(int members) {
    return 'У вашому клані в середньому бере участь $members учасників з останніх 50 війн.';
  }

  @override
  String warHistoryAverageWarStarsDescription(double stars, String percent) {
    return 'Ваш клан мав у середньому $stars зірок за війну з останніх 50 війн. Це становить $percent від загальної кількості зірок.';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return 'Ваш клан мав середній показник знищення на рівні $percent% з останніх 50 війн.';
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
  String get warOpponentEqualThLevel => 'Рівний ТХ';

  @override
  String get warOpponentSelectMembersThLevel => 'Рівень ТХ учасників';

  @override
  String get warOpponentSelectOpponentsThLevel => 'Рівень ТХ противників';

  @override
  String warFiltersLastXwars(int number) {
    return 'Останні $number війн';
  }

  @override
  String get warFiltersFriendly => 'Дружні';

  @override
  String get warFiltersRandom => 'Глобальні';

  @override
  String get warVisibilityToggleTownHall =>
      'Приховати/Показати Статистику з колишніх рівнів Ратуші';

  @override
  String get warEventsTitle => 'Події';

  @override
  String get warEventsNewest => 'Найновіший';

  @override
  String get warEventsOldest => 'Найстаріший';

  @override
  String get warStatusReady => 'Готов';

  @override
  String get warStatusUnready => 'Не готов';

  @override
  String get warStatusMissed => 'Missed';

  @override
  String get warAbbreviationAvg => 'Avg';

  @override
  String get warAbbreviationAvgPercentage => 'Avg %';

  @override
  String get cwlTitle => 'ЛВК';

  @override
  String get cwlClanWarLeague => 'Ліга Війн Кланів';

  @override
  String get cwlOngoing => 'Поточна ЛВК';

  @override
  String get cwlRounds => 'Раунди';

  @override
  String cwlRoundNumber(int number) {
    return 'Round $number';
  }

  @override
  String cwlCurrentRound(int round) {
    return 'Наразі триває раунд $round.';
  }

  @override
  String cwlRank(int rank) {
    return 'Ваш клан наразі займає $rank місце.';
  }

  @override
  String cwlStars(int stars) {
    return 'Ваш клан має загально $stars зірок.';
  }

  @override
  String cwlDestructionPercentage(String percent) {
    return 'Ваш клан має загальний рівень знищення $percent%.';
  }

  @override
  String cwlTotalAttacks(int attacks, int totalAttacks) {
    return 'Your clan has a total of $attacks attacks out of $totalAttacks possible attacks.';
  }

  @override
  String get joinLeaveTitle => 'Join/Leave Logs (Current Season)';

  @override
  String get joinLeaveJoin => 'Приєднатися';

  @override
  String get joinLeaveLeave => 'Залишити';

  @override
  String get joinLeaveReset => 'Скинути';

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
    return 'Покинув $date о $time.';
  }

  @override
  String joinLeaveJoinedOnAt(String date, String time) {
    return 'Приєднався $date о $time.';
  }

  @override
  String get raidsTitle => 'Raids';

  @override
  String get raidsLast => 'Останні рейди';

  @override
  String get raidsOngoing => 'Поточні рейди';

  @override
  String get raidsDistrictsDestroyed => 'Знищені райони';

  @override
  String get raidsCompleted => 'Завершені рейди';

  @override
  String get searchNoResult => 'Нічого не знайдено.';

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
  String get dashboardTitle => 'Панель керування';

  @override
  String get toolsTitle => 'Інструменти';

  @override
  String get navigationTeam => 'Команди';

  @override
  String get navigationStatistics => 'Статистика';

  @override
  String get versionDevice => 'Версія та пристрій';

  @override
  String get settingsLicenses => 'Open Source Licenses';

  @override
  String get settingsLicensesSubtitle =>
      'View licenses for third-party libraries';

  @override
  String get betaFeature => 'Бета-функції';

  @override
  String get betaLabel => 'Бета';

  @override
  String get betaDescription =>
      'Ця функція наразі знаходиться в бета-версії, може містити деякі помилки або бути неповною. Ми активно працюємо над удосконаленнями й раді вашому зворотному зв\'язку. Будь ласка, поділіться своїми ідеями та повідомте про будь-які проблеми на нашому сервері Discord, щоб допомогти нам зробити це краще.';

  @override
  String get settingsLanguage => 'Мова';

  @override
  String get settingsSelectLanguage => 'Оберіть мову';

  @override
  String get settingsToggleTheme => 'Перемкнути тему';

  @override
  String get faqTitle => 'Питання та відповіді';

  @override
  String get faqSubtitle => 'Найбільш поширенні питання';

  @override
  String get faqIsThisFromSupercell => 'Чи це додаток від Supercell?';

  @override
  String get faqFanContentPolicy =>
      'Цей матеріал є неофіційним і не є схваленим Supercell. Для отримання більш докладної інформації перегляньте політику відносно вмісту фан-сайтів Supercell: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate => 'Чому дані іноді невірні або відсутні?';

  @override
  String get faqClanNotTracked => 'Клан не відстежується';

  @override
  String get faqClanNotTrackedAnswer =>
      'ClashKing може отримати цю інформацію лише у випадку, якщо клан відстежується. Якщо ваш клан не відстежується, будь ласка, запросіть ClashKing Bot на свій сервер Discord і використовуйте команду /addclan. Ми працюємо над тим, щоб ця функція була доступна у додатку.';

  @override
  String get faqTrackingDown => 'Відстеження';

  @override
  String get faqTrackingDownAnswer =>
      'Відстеження може припинити працювати в певний проміжок часу. Ось чому іноді у вас є дірки у ваших даних. Ми працюємо над удосконаленням цього.';

  @override
  String get faqApiLimitation => 'Обмеження Clash of Clans API';

  @override
  String get faqApiLimitationAnswer =>
      'Деякі дані надаються Clash of Clans, а їх API має деякі обмеження. Це стосується відстеження легенд, де іноді накопичується приріст і втрата кубків, ніби це був один напад. Це також пояснює, чому ми не маємо жодної інформації про ваші рівні будівель.';

  @override
  String get faqSupportWork => 'Як я можу підтримати вашу роботу?';

  @override
  String get faqSupportWorkAnswer => 'Існує декілька способів підтримати нас:';

  @override
  String get faqUseCodeClashKing => 'Використовуйте код \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Підтримайте нас на Patreon';

  @override
  String get faqShareTheApp => 'Поділитися додатком зі своїми друзями';

  @override
  String get faqRateTheApp => 'Оцініть додаток в магазині';

  @override
  String get faqHelpUsTranslate => 'Допоможіть нам перекласти додаток';

  @override
  String get faqHowToInviteTheBot =>
      'Як я можу запросити вашого бота на мій сервер Discord?';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'Ви можете запросити нашого бота на свій сервер, натиснувши на кнопку нижче. Вам знадобиться дозвіл \"Керування сервером\", щоб додати бота.';

  @override
  String get faqInviteTheBot => 'Запросити бота ClashKing';

  @override
  String get faqNeedHelp =>
      'Мені потрібна допомога або я хочу зробити пропозицію. Як я можу з вами зв\'язатися?';

  @override
  String get faqNeedHelpAnswer =>
      'Ви можете приєднатися до нашого Discord-серверу, щоб попросити допомоги або надати відгук, або ви можете написати нам за адресою devs@clashk.ing. Будь ласка, пишіть тільки англійською або французькою.';

  @override
  String get faqSendEmail => 'Відправити e-mail';

  @override
  String get faqJoinDiscord => 'Приєднуйтеся до нашого сервера Discord';

  @override
  String get faqCannotOpenMailClient =>
      'З деяких причин ми не можемо відкрити клієнт вашої пошти. Ми скопіювали адресу електронної пошти для вас. Ви можете написати лист і вставити адресу у поле одержувача.';

  @override
  String get translationHelpUsTranslate => 'Допомогти з перекладом';

  @override
  String get translationSuggestFeatures => 'Запропонувати можливості';

  @override
  String get translationThankYou => 'Дякуємо!';

  @override
  String get translationThankYouContent =>
      'Величезна подяка всім нашим неймовірним перекладачам, які допомагають нам зробити цей додаток доступним для більшої кількості людей по всьому світу!';

  @override
  String get translationHelpTranslateContent =>
      'Ви можете допомогти нам перекласти додаток на Crowdin. Якщо вашої мови немає на Crowdin, не соромтеся запитати її на нашому сервері Discord. Дуже вдячні за вашу допомогу!';

  @override
  String get translationHelpTranslateButton =>
      'Допоможіть перекласти на Crowdin';

  @override
  String get translationCurrentTranslators => 'Поточні перекладачі';
}
