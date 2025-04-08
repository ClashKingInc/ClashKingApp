// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get creatorCode => 'Код Творця: ClashKing';

  @override
  String get errorTitle => 'Oops! Our servers might have taken a fireball to the face! We\'re casting a healing spell... Try again in a moment.';

  @override
  String get errorSubtitle => 'If the issue persists, check our Discord Server to see if we\'re aware of it.';

  @override
  String get retry => 'Retry';

  @override
  String get signInWithDiscord => 'Увійти за допомогою Discord';

  @override
  String get guestMode => 'Режим гостя';

  @override
  String get needHelpJoinDiscord => 'Потрібна допомога? Приєднуйтесь до нас у Discord.';

  @override
  String get loginError => 'An error occurred while logging in. Please try again later.';

  @override
  String get createGuestProfile => 'Створити свій гостьовий профіль';

  @override
  String doesNotExist(String tag) {
    return '$tag Не існує.';
  }

  @override
  String isAlreadyLinked(String tag) {
    return '$tag Вже зв\'язаний з кимось.';
  }

  @override
  String get username => 'Ім\'я користувача';

  @override
  String get pleaseEnterUsername => 'Будь ласка, введіть ім\'я користувача';

  @override
  String get playerTag => 'Player Tag (#ABC123)';

  @override
  String get playerTags => 'Тег гравця';

  @override
  String get linkedAccounts => 'Linked Accounts';

  @override
  String followingTagsDoNotExist(String tags) {
    return 'Наступні теги не існують: $tags.';
  }

  @override
  String followingTagsAreAlreadyLinked(String tags) {
    return 'Наступні теги вже з\'єднані з кимось: $tags.';
  }

  @override
  String get welcome => 'Вітаємо!';

  @override
  String get welcomeMessage => 'Будь ласка, додайте один або кілька облікових записів Clash of Clans до свого профілю. Ви можете додати або видалити облікові записи пізніше.';

  @override
  String get login => 'Увійти';

  @override
  String get logout => 'Вийти';

  @override
  String get language => 'Мова';

  @override
  String get settings => 'Налаштування';

  @override
  String get toggleTheme => 'Перемкнути тему';

  @override
  String get selectLanguage => 'Оберіть мову';

  @override
  String get faq => 'Питання та відповіді';

  @override
  String get faqSubtitle => 'Найбільш поширенні питання';

  @override
  String get faqIsThisFromSupercell => 'Чи це додаток від Supercell?';

  @override
  String get faqFanContentPolicy => 'Цей матеріал є неофіційним і не є схваленим Supercell. Для отримання більш докладної інформації перегляньте політику відносно вмісту фан-сайтів Supercell: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate => 'Чому дані іноді невірні або відсутні?';

  @override
  String get faqClanNotTracked => 'Клан не відстежується';

  @override
  String get faqClanNotTrackedAnswer => 'ClashKing може отримати цю інформацію лише у випадку, якщо клан відстежується. Якщо ваш клан не відстежується, будь ласка, запросіть ClashKing Bot на свій сервер Discord і використовуйте команду /addclan. Ми працюємо над тим, щоб ця функція була доступна у додатку.';

  @override
  String get faqTrackingDown => 'Відстеження';

  @override
  String get faqTrackingDownAnswer => 'Відстеження може припинити працювати в певний проміжок часу. Ось чому іноді у вас є дірки у ваших даних. Ми працюємо над удосконаленням цього.';

  @override
  String get faqApiLimitation => 'Обмеження Clash of Clans API';

  @override
  String get faqApiLimitationAnswer => 'Деякі дані надаються Clash of Clans, а їх API має деякі обмеження. Це стосується відстеження легенд, де іноді накопичується приріст і втрата кубків, ніби це був один напад. Це також пояснює, чому ми не маємо жодної інформації про ваші рівні будівель.';

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
  String get faqHowToInviteTheBot => 'Як я можу запросити вашого бота на мій сервер Discord?';

  @override
  String get faqHowToInviteTheBotAnswer => 'Ви можете запросити нашого бота на свій сервер, натиснувши на кнопку нижче. Вам знадобиться дозвіл \"Керування сервером\", щоб додати бота.';

  @override
  String get faqInviteTheBot => 'Запросити бота ClashKing';

  @override
  String get faqNeedHelp => 'Мені потрібна допомога або я хочу зробити пропозицію. Як я можу з вами зв\'язатися?';

  @override
  String get faqNeedHelpAnswer => 'Ви можете приєднатися до нашого Discord-серверу, щоб попросити допомоги або надати відгук, або ви можете написати нам за адресою devs@clashkingbot.com. Будь ласка, пишіть тільки англійською або французькою.';

  @override
  String get faqSendEmail => 'Відправити e-mail';

  @override
  String get faqJoinDiscord => 'Приєднуйтеся до нашого сервера Discord';

  @override
  String get faqCannotOpenMailClient => 'З деяких причин ми не можемо відкрити клієнт вашої пошти. Ми скопіювали адресу електронної пошти для вас. Ви можете написати лист і вставити адресу у поле одержувача.';

  @override
  String get helpUsTranslate => 'Допомогти з перекладом';

  @override
  String get suggestFeatures => 'Запропонувати можливості';

  @override
  String get thankYou => 'Дякуємо!';

  @override
  String get thankYouContent => 'Величезна подяка всім нашим неймовірним перекладачам, які допомагають нам зробити цей додаток доступним для більшої кількості людей по всьому світу!';

  @override
  String get helpTranslateContent => 'Ви можете допомогти нам перекласти додаток на Crowdin. Якщо вашої мови немає на Crowdin, не соромтеся запитати її на нашому сервері Discord. Дуже вдячні за вашу допомогу!';

  @override
  String get helpTranslateButton => 'Допоможіть перекласти на Crowdin';

  @override
  String get versionDevice => 'Версія та пристрій';

  @override
  String get loading => 'Завантаження...';

  @override
  String get errorLoadingVersion => 'Помилка при завантаженні версії';

  @override
  String get currentTranslators => 'Поточні перекладачі';

  @override
  String get betaFeature => 'Бета-функції';

  @override
  String get beta => 'Бета';

  @override
  String get betaDescription => 'Ця функція наразі знаходиться в бета-версії, може містити деякі помилки або бути неповною. Ми активно працюємо над удосконаленнями й раді вашому зворотному зв\'язку. Будь ласка, поділіться своїми ідеями та повідомте про будь-які проблеми на нашому сервері Discord, щоб допомогти нам зробити це краще.';

  @override
  String get copiedToClipboard => 'Скопійовано в буфер обміну';

  @override
  String get all => 'Всі';

  @override
  String get hourIndicator => 'год';

  @override
  String get minIndicator => 'хв';

  @override
  String get noDataAvailable => 'Дані відсутні.';

  @override
  String get close => 'Закрити';

  @override
  String get closed => 'Закрито';

  @override
  String get error => 'Помилка';

  @override
  String get player => 'Гравець';

  @override
  String notFoundOrNotLinkedToOurSystem(String player) {
    return '$player Не знайдено або не пов\'язано з нашою системою.';
  }

  @override
  String get tryAnotherNameOrTagOrLinkIt => 'Спробуйте інше ім\'я/тег або посилання на нього.';

  @override
  String get playerNotFound => 'Гравця не знайдено';

  @override
  String get noValueEntered => 'Не введено жодного значення';

  @override
  String get manage => 'Керувати';

  @override
  String get enterPlayerTag => 'Введіть тег гравця';

  @override
  String get add => 'Додати';

  @override
  String get delete => 'Видалити';

  @override
  String get addAccount => 'Додати обліковий запис';

  @override
  String get deleteAccount => 'Видалити обліковий запис';

  @override
  String get playerTagNotExists => 'Тег гравця, який був введений, не існує.';

  @override
  String accountAlreadyLinked(Object tag) {
    return 'Тег гравця вже зв\'язаний з кимось.';
  }

  @override
  String get enterApiToken => 'Будь ласка, введіть ключ API для облікового запису. Його можна знайти у налаштуваннях Clash of Clans > Додаткові Налаштування > Токен API.';

  @override
  String get wrongApiToken => 'Введений токен API невірний';

  @override
  String get accountAlreadyLinkedToYou => 'Тег гравця вже прив\'язаний до вас.';

  @override
  String get apiToken => 'API-токен облікового запису';

  @override
  String get failedToAddTryAgain => 'Не вдалося додати посилання. Будь ласка, повторіть спробу пізніше.';

  @override
  String get fillAllFields => 'Please fill all fields.';

  @override
  String get failedToDeleteTryAgain => 'Не вдалося видалити посилання. Будь ласка, повторіть спробу пізніше.';

  @override
  String get enterPlayerTagWarning => 'Вам потрібно ввести тег гравця та натиснути на знак \"+\", щоб продовжити.';

  @override
  String get failedToLoadAccountData => 'Failed to load accounts data.';

  @override
  String get loadAccountData => 'Load accounts data';

  @override
  String get search => 'Пошук';

  @override
  String get warning => 'Попередження';

  @override
  String get exitAppToOpenClash => 'Ви збираєтеся вийти з програми для відкриття Clash of Clans.';

  @override
  String get confirmLogout => 'Впевнені, що хочете вийти?';

  @override
  String get tagOrNamePlayer => 'Тег гравця або ім\'я';

  @override
  String get searchPlayer => 'Пошук гравця';

  @override
  String get nameOrTagPlayer => 'Ім\'я гравця або тег';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Ваш клан \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(String ratio, String donations, String received) {
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
  String get dashboard => 'Панель керування';

  @override
  String get homeBase => 'Домашня база';

  @override
  String get th => 'ТХ';

  @override
  String get builderBase => 'База будівельника';

  @override
  String get bh => 'ББ';

  @override
  String get clanCapital => 'Столиця клану';

  @override
  String get leader => 'Лідер';

  @override
  String get coLeader => 'Спів-лідер';

  @override
  String get elder => 'Старійшина';

  @override
  String get member => 'Учасник';

  @override
  String get ready => 'Готов';

  @override
  String get unready => 'Не готов';

  @override
  String level(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get heroes => 'Герої';

  @override
  String get equipment => 'Спорядження';

  @override
  String get troops => 'Війська';

  @override
  String get superTroops => 'Супер Війська';

  @override
  String get activeSuperTroops => 'Активні Супер Війська';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get pets => 'Тварини';

  @override
  String get siegeMachines => 'Облогові машини';

  @override
  String get spells => 'Заклинання';

  @override
  String get achievements => 'Досягнення';

  @override
  String get byDay => 'За день';

  @override
  String get bySeason => 'За сезон';

  @override
  String dayIndex(int index) {
    return 'День $index';
  }

  @override
  String indexDays(int index) {
    return '$index Днів';
  }

  @override
  String get bestTrophies => 'Кращі Трофеї';

  @override
  String get mostAttacks => 'Найбільша кількість атак';

  @override
  String get lastSeason => 'Минулий сезон';

  @override
  String get bestRank => 'Найкращий глобальний ранг';

  @override
  String daysLeft(int days) {
    return 'Лишилось днів $days';
  }

  @override
  String get date => 'Дата';

  @override
  String get stats => 'Статистика';

  @override
  String get fullStats => 'Full Stats';

  @override
  String get details => 'Детальніше';

  @override
  String get seasonStats => 'Статистика сезону';

  @override
  String get charts => 'Графіки';

  @override
  String get history => 'Історія';

  @override
  String get legendLeague => 'Легендарна Ліга';

  @override
  String get notInLegendLeague => 'Не в Легендарній Лізі';

  @override
  String get noLegendData => 'Дані легенди не знайдено на сьогодні';

  @override
  String legendStartDescription(String trophies) {
    return 'Ви розпочали день з $trophies трофеїв.';
  }

  @override
  String legendNoRankLocalDescription(String country, int trophies) {
    return 'Наразі вас немає в рейтингу ($country) з $trophies трофеями.';
  }

  @override
  String legendRankLocalDescription(Object country, Object rank, Object trophies) {
    return 'Зараз ви займаєте $rank місце в топі ($country) з $trophies трофеями.';
  }

  @override
  String legendGainDescription(int trophies) {
    return 'Зараз ви отримали $trophies трофеїв.';
  }

  @override
  String legendLossDescription(int trophies) {
    return 'Зараз ви втратили $trophies трофеїв.';
  }

  @override
  String legendNoGlobalRankDescription(int trophies) {
    return 'Наразі ви не в глобальному рейтингу з $trophies трофеями.';
  }

  @override
  String legendGlobalRankDescription(int rank, Object trophies) {
    return 'Ви знаходитесь на $rank місці в глобальному рейтингу.';
  }

  @override
  String get noRank => 'Немає рейтингу';

  @override
  String get started => 'Почато';

  @override
  String get ended => 'Завершено';

  @override
  String get average => 'Середнє значення';

  @override
  String get remaining => 'Залишилося';

  @override
  String get legendsTitle => 'Некоректні дані?';

  @override
  String get legendsExplanation_intro => 'Через обмеження Clash of Clans API, наші дані можуть бути не завжди точними. Ось чому:\n';

  @override
  String get legendsExplanation_api_delay_title => '1. Затримка API: ';

  @override
  String get legendsExplanation_api_delay_body => 'API може оновлюватися до 5 хвилин, що спричиняє затримку у зображенні змін трофеїв в реальному часі.\n';

  @override
  String get legendsExplanation_concurrent_changes_title => '2. Можливі зміни: \n';

  @override
  String get legendsExplanation_multiple_attacks_defenses_title => '- Кілька нападів/Захистів: ';

  @override
  String get legendsExplanation_multiple_attacks_defenses_body => 'Якщо декілька атак або захистів відбуваються одна за одною швидко, API може показати комбіновані результати (наприклад, +68 або -68).\n';

  @override
  String get legendsExplanation_simultaneous_attack_defense_title => '- Одночасна атака та оборона: ';

  @override
  String get legendsExplanation_simultaneous_attack_defense_body => 'Якщо напад та захист відбуваються одночасно, ви можете побачити змішаний результат (наприклад, +4).\n';

  @override
  String get legendsExplanation_net_gain_loss_title => '3. Чистий прибуток/збиток: ';

  @override
  String get legendsExplanation_net_gain_loss_body => 'Всупереч проблемі з часом, загальний чистий приріст або втрата за день точні. ';

  @override
  String get legendsExplanation_conclusion => 'Ці обмеження поширені у всіх інструментах, які використовують API гри Clash of Clans. Нам дуже шкода, що ми не можемо це виправити, оскільки це у руках Supercell. Ми робимо все можливе, щоб компенсувати ці обмеження та надати результати якомога ближчі до реальності. Дякуємо за розуміння!';

  @override
  String get toDoList => 'Список справ';

  @override
  String lastActive(String date) {
    return 'Остання активність: $date';
  }

  @override
  String get playerNotTracked => 'Цей гравець не відстежується. Дані можуть бути неточні.';

  @override
  String numberAccounts(int number) {
    return '$number Облікових записів';
  }

  @override
  String numberActiveAccounts(int number) {
    return '$number Активних облікових записів';
  }

  @override
  String numberInactiveAccounts(int number) {
    return '$number Неактивних облікових записів';
  }

  @override
  String get activeAccounts => 'Активні облікові записи';

  @override
  String get inactiveAccounts => 'Неактивні облікові записи';

  @override
  String get noInactiveAccounts => 'Немає неактивних облікових записів.';

  @override
  String get noActiveAccounts => 'Немає активних облікових записів.';

  @override
  String get todoExplanation_title => 'Розрахунок завдання';

  @override
  String get todoExplanation_intro => 'Відсоток завершення завдання обчислюється на основі наступних дій з конкретними ваговими коефіцієнтами:';

  @override
  String get todoExplanation_legends_title => 'Легендарна Ліга:';

  @override
  String get todoExplanation_legends => 'Вага 8 очок за обліковий запис, 1 атака = 1 очко.';

  @override
  String get todoExplanation_raids_title => 'Рейди:';

  @override
  String get todoExplanation_raids => 'Вага 5 балів за обліковий запис (або 6, якщо останню атаку розблоковано), 1 атака = 1 бал.';

  @override
  String get todoExplanation_clanWars_title => 'Кланові Війни:';

  @override
  String get todoExplanation_clanWars => 'Вага 2 бали на рахунок, 1 атака = 1 бал.';

  @override
  String get todoExplanation_cwl_title => 'Ліга Війни Кланів:';

  @override
  String get todoExplanation_cwl => 'Вага 1 бал за обліковий запис, 1 напад = 1 бал. CWL не може бути відстежено, якщо гравець не перебуває у своєму клані ліги.';

  @override
  String get todoExplanation_passAndGames_title => 'Сезонний пропуск та кланові ігри:';

  @override
  String get todoExplanation_passAndGames => 'Вага по 2 бали кожен на рахунок. Співвідношення ґрунтується на залишку днів (1 місяць на пропуск і 6 днів на ігри). Зелений = на шляху до завершення пропуску або ігор, червоний = позаду графіка.';

  @override
  String get todoExplanation_conclusion => 'Загальний відсоток обчислюється шляхом ділення загальної кількості виконаних дій під час поточних подій на загальну кількість необхідних дій. Обліковий запис, неактивний протягом більш як 14 днів, виключаються з розрахунку.';

  @override
  String get worst => 'Найгірший';

  @override
  String get best => 'Найкращий';

  @override
  String get total => 'Всього';

  @override
  String get heroesEquipments => 'Спорядження героя';

  @override
  String daysAgo(int days) {
    return '$days Днів тому';
  }

  @override
  String dayAgo(int day) {
    return '$day День тому';
  }

  @override
  String hourAgo(int hour) {
    return '$hour Годину тому';
  }

  @override
  String hoursAgo(int hours, Object Hours) {
    return '$hours Годин тому';
  }

  @override
  String minuteAgo(int minute) {
    return '$minute Хвилину тому';
  }

  @override
  String minutesAgo(int minutes) {
    return '$minutes Хвилин тому';
  }

  @override
  String secondAgo(int seconds) {
    return '$seconds Секунд тому';
  }

  @override
  String get justNow => 'Щойно';

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
  String get trophiesByMonth => 'Трофеї за місяць';

  @override
  String get trophiesBySeason => 'Трофеї за сезон';

  @override
  String get eosTrophies => 'Трофеї в кінці сезону';

  @override
  String get eosDetails => 'End Of Season Details';

  @override
  String get searchClan => 'Пошук клану';

  @override
  String get nameOrTagClan => 'Назва клану або тег';

  @override
  String get noResult => 'Нічого не знайдено.';

  @override
  String get filters => 'Фільтри';

  @override
  String get whatever => 'Будь-що';

  @override
  String get any => 'Будь-які';

  @override
  String get notSet => 'Не вибрано';

  @override
  String get warFrequency => 'Частота війн';

  @override
  String get minimumMembers => 'Мінімальна кількість учасників';

  @override
  String get maximumMembers => 'Максимальна кількість учасників';

  @override
  String get location => 'Розташування';

  @override
  String get minimumClanPoints => 'Мінімальні очки клану';

  @override
  String get minimumClanLevel => 'Мінімальний рівень клану';

  @override
  String get noClan => 'Без клану';

  @override
  String get joinClanToUnlockNewFeatures => 'Приєднуйтеся до клану, щоб розблокувати нові можливості.';

  @override
  String get apply => 'Застосувати';

  @override
  String get opened => 'Відчинено';

  @override
  String get inviteOnly => 'За запрошенням';

  @override
  String get cancel => 'Скасувати';

  @override
  String get clan => 'Клан';

  @override
  String get clans => 'Клани';

  @override
  String get members => 'Учасники';

  @override
  String get role => 'Роль';

  @override
  String get expLevel => 'Рівень досвіду';

  @override
  String get townHallLevel => 'Рівень ратуші';

  @override
  String thLevel(int level) {
    return 'ТХ$level';
  }

  @override
  String bhLevel(int level) {
    return 'ББ$level';
  }

  @override
  String townHallLevelLevel(int level) {
    return 'Ратуша $level';
  }

  @override
  String get byNumberOfWars => 'За кількістю війн';

  @override
  String get ok => 'ОК';

  @override
  String get byDateRange => 'За діапазоном дат';

  @override
  String get selectSeason => 'Виберіть сезон';

  @override
  String get year => 'Рік';

  @override
  String get month => 'Місяць';

  @override
  String get allTownHalls => 'Всі ратуші';

  @override
  String seasonDate(String date) {
    return 'Сезон $date';
  }

  @override
  String lastXwars(int number) {
    return 'Останні $number війн';
  }

  @override
  String get friendly => 'Дружні';

  @override
  String get cwl => 'ЛВК';

  @override
  String get random => 'Глобальні';

  @override
  String get selectMembersThLevel => 'Рівень ТХ учасників';

  @override
  String get selectOpponentsThLevel => 'Рівень ТХ противників';

  @override
  String get equalThLevel => 'Рівний ТХ';

  @override
  String get builderBaseTrophies => 'ББ Трофеї';

  @override
  String get donations => 'Пожертви';

  @override
  String get donationsReceived => 'Пожертв отримано';

  @override
  String get donationsRatio => 'Співвідношення пожертв';

  @override
  String get trophies => 'Трофеї';

  @override
  String get always => 'Завжди';

  @override
  String get never => 'Ніколи';

  @override
  String get unknown => 'Невизначено';

  @override
  String get oncePerWeek => '1/тиждень';

  @override
  String get twicePerWeek => '2/тиждень';

  @override
  String get rarely => 'Рідко';

  @override
  String get warLeague => 'Війна/Ліга';

  @override
  String get war => 'Війна';

  @override
  String get league => 'Ліга';

  @override
  String get wars => 'Війни';

  @override
  String get ongoingWar => 'Поточна війна';

  @override
  String get ongoingCwl => 'Поточна ЛВК';

  @override
  String get cantOpenLink => 'Ми не можемо відкрити це посилання.';

  @override
  String get notInWar => 'Не в стані війни';

  @override
  String get warHistory => 'Історія війн';

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
  String warHistoryAverageClanStarsPerMember(Object stars) {
    return 'Ваш клан мав у середньому $stars зірок на кожного учасника з останніх 50 війн.';
  }

  @override
  String warHistoryAverageMembers(int members) {
    return '~$members учасників на війну';
  }

  @override
  String get averageStars => 'Середні зірки';

  @override
  String get averageDestruction => 'Середнє знищення';

  @override
  String get oneStar => '1 зірка';

  @override
  String get twoStars => '2 зірки';

  @override
  String get threeStars => '3 зірки';

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
  String get warParticipation => 'Участь у війні';

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
  String get toggleTownHallVisibility => 'Приховати/Показати Статистику з колишніх рівнів Ратуші';

  @override
  String get warLog => 'Журнал війн';

  @override
  String get publicWarLog => 'Відкритий журнал війн';

  @override
  String get privateWarLog => 'Закритий журнал війн';

  @override
  String startsIn(String time) {
    return 'Розпочнеться через $time';
  }

  @override
  String startsAt(String time) {
    return 'Починається о $time';
  }

  @override
  String endsIn(String time) {
    return 'Закінчиться через $time';
  }

  @override
  String endsAt(String time) {
    return 'Закінчується о $time';
  }

  @override
  String get joinLeaveLogs => 'Журнал вступу/виходу';

  @override
  String get join => 'Приєднатися';

  @override
  String get leave => 'Залишити';

  @override
  String get reset => 'Скинути';

  @override
  String leaveNumberDescription(int number, String date) {
    return '$number Гравців покинули клан під час поточного сезону ($date).';
  }

  @override
  String joinNumberDescription(int number, String date) {
    return '$number Гравців приєдналися до клану під час поточного сезону ($date).';
  }

  @override
  String joinLeaveDifferenceUpDescription(int number, String date) {
    return 'Ваш клан отримав $number нових учасників цього сезону ($date).';
  }

  @override
  String joinLeaveDifferenceDownDescription(int number, String date) {
    return 'Ваш клан втратив учасників $number в цьому сезоні ($date).';
  }

  @override
  String joinLeaveDifferenceEqualDescription(String date) {
    return 'У вашому клані стільки ж учасників, що на початку сезону ($date).';
  }

  @override
  String leftOnAt(String date, String time) {
    return 'Покинув $date о $time.';
  }

  @override
  String joinedOnAt(String date, String time) {
    return 'Приєднався $date о $time.';
  }

  @override
  String get statistics => 'Статистика';

  @override
  String get stars => 'Зірки';

  @override
  String get numberOfStars => 'Кількість зірок';

  @override
  String get destructionRate => 'Рівень руйнування';

  @override
  String get events => 'Події';

  @override
  String get team => 'Команди';

  @override
  String get myTeam => 'Моя команда';

  @override
  String get enemiesTeam => 'Вороги';

  @override
  String get defense => 'Захист';

  @override
  String get defenses => 'Захисти';

  @override
  String bestDefenseOutOf(int number) {
    return 'Best defense (out of $number)';
  }

  @override
  String get attack => 'Атака';

  @override
  String get attacks => 'Атаки';

  @override
  String get noAttackYet => 'No attack yet';

  @override
  String get noDefenseYet => 'No defense yet';

  @override
  String get victory => 'Перемога';

  @override
  String get defeat => 'Поразка';

  @override
  String get draw => 'Нічия';

  @override
  String get perfectWar => 'Ідеальна війна';

  @override
  String get newest => 'Найновіший';

  @override
  String get oldest => 'Найстаріший';

  @override
  String get warEnded => 'Війна завершилася';

  @override
  String get preparation => 'Підготовка';

  @override
  String isNotInWar(String clan) {
    return '$clan Не знаходиться у війні.';
  }

  @override
  String warLogIsClosed(String clan) {
    return 'Журнал війн $clan закритий.';
  }

  @override
  String get askForWar => 'Звертайтеся до лідера або спів-лідера, щоб розпочати війну.';

  @override
  String get askForWarLogOpening => 'Звертайтеся до лідера або спів-лідера, аби відкрити журнал бою.';

  @override
  String get warLogClosed => 'Журнал війн закритий.';

  @override
  String get rounds => 'Раунди';

  @override
  String roundNumber(int number) {
    return 'Round $number';
  }

  @override
  String currentRound(int number) {
    return 'Current round (Round $number)';
  }

  @override
  String get noDataAvailableForThisWar => 'Дані недоступні для цієї війни';

  @override
  String get stateOfTheWar => 'Стан війни';

  @override
  String starsNeededToTakeTheLead(String clan, int star, int star2, String percent, Object stars2) {
    return '$clan Все ще потребує $star зірок або $stars2 зірки та $percent%, щоб вийти вперед.';
  }

  @override
  String starsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan Все ще потребує $percent% або ще 1 зірку, щоб взяти на себе ініціативу';
  }

  @override
  String get clanDraw => 'Два клани зв\'язані';

  @override
  String get fastCalculator => 'Розрахунок %';

  @override
  String fastCalculatorAnswer(String percentNeedeed, String result, Object percentNeeded) {
    return 'Для досягнення рівня руйнування $percentNeeded%, необхідно підсумок $result%.';
  }

  @override
  String get teamSize => 'Розмір команди';

  @override
  String get neededOverall => '% Потрібно загалом';

  @override
  String get calculate => 'Розрахувати';

  @override
  String get warStats => 'Статистика війни';

  @override
  String get membersStats => 'Статистика учасників';

  @override
  String get clanWarLeague => 'Ліга Війн Кланів';

  @override
  String cwlRank(int rank) {
    return 'Ваш клан наразі займає $rank місце.';
  }

  @override
  String cwlStars(int stars) {
    return 'Ваш клан має загально $stars зірок.';
  }

  @override
  String cwlMissingStarsFromNext(int stars) {
    return 'Ваш клан відстає на $stars зірок, щоб наздогнати наступний клан.';
  }

  @override
  String cwlMissingStarsFromFirst(int stars) {
    return 'Ваш клан відстає на $stars зірок, щоб наздогнати перший клан.';
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
  String cwlCurrentRound(int round) {
    return 'Наразі триває раунд $round.';
  }

  @override
  String get noAccountLinkedToYourProfileFound => 'Не знайдено облікового запису, пов\'язаного з вашим профілем';

  @override
  String get management => 'Керування';

  @override
  String get comingSoon => 'Незабаром!';

  @override
  String get connectionError => 'Сталася помилка. Перевірте підключення до Інтернету та спробуйте ще раз.';

  @override
  String get connectionErrorRelaunch => 'Сталася помилка. Будь ласка, перевірте підключення до Інтернету та перезапустіть додаток.';

  @override
  String updatedAt(String time) {
    return 'Оновлено о $time';
  }

  @override
  String get tools => 'Інструменти';

  @override
  String get community => 'Спільнота';

  @override
  String get lastRaids => 'Останні рейди';

  @override
  String get ongoingRaids => 'Поточні рейди';

  @override
  String get districtsDestroyed => 'Знищені райони';

  @override
  String get raidsCompleted => 'Завершені рейди';
}
