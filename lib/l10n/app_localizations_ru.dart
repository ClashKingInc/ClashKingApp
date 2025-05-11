// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get creatorCode => 'Код Создателя: ClashKing';

  @override
  String get errorTitle => 'Oops! Our servers might have taken a fireball to the face! We\'re casting a healing spell... Try again in a moment.';

  @override
  String get errorSubtitle => 'If the issue persists, check our Discord Server to see if we\'re aware of it.';

  @override
  String get retry => 'Retry';

  @override
  String get signInWithDiscord => 'Вход через Discord';

  @override
  String get guestMode => 'Режим \"Гость\"';

  @override
  String get needHelpJoinDiscord => 'Нужна помощь? Присоединяйтесь к нам в Discord.';

  @override
  String get loginError => 'An error occurred while logging in. Please try again later.';

  @override
  String doesNotExist(String tag) {
    return '$tag не существует.';
  }

  @override
  String isAlreadyLinked(String tag) {
    return '$tag уже связан с кем-то.';
  }

  @override
  String get username => 'Имя пользователя';

  @override
  String get playerTag => 'Player Tag (#ABC123)';

  @override
  String get playerTags => 'Теги игрока';

  @override
  String get linkedAccounts => 'Linked Accounts';

  @override
  String followingTagsDoNotExist(String tags) {
    return 'Следующие теги не существуют: $tags.';
  }

  @override
  String followingTagsAreAlreadyLinked(String tags) {
    return 'Следующие теги уже связаны с кем-то: $tags.';
  }

  @override
  String get welcome => 'Добро пожаловать!';

  @override
  String get welcomeMessage => 'Пожалуйста, добавьте один или несколько аккаунтов Clash of Clans в свой профиль. Вы сможете добавлять или удалять аккаунты позже.';

  @override
  String get login => 'Вход';

  @override
  String get logout => 'Выход';

  @override
  String get language => 'Язык';

  @override
  String get settings => 'Настройки';

  @override
  String get toggleTheme => 'Переключить тему';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get faq => 'Ответы на частые вопросы';

  @override
  String get faqSubtitle => 'Часто задаваемые вопросы';

  @override
  String get faqIsThisFromSupercell => 'Это приложение от Supercell?';

  @override
  String get faqFanContentPolicy => 'Этот материал неофициальный и не одобрен Supercell. Для получения дополнительной информации просмотрите Политику Supercell в отношении контента для фанатов: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate => 'Почему данные иногда неточны или отсутствуют?';

  @override
  String get faqClanNotTracked => 'Клан не отслеживается';

  @override
  String get faqClanNotTrackedAnswer => 'ClashKing может получить эту информацию только если клан отслеживается. Если ваш клан не отслеживается, пригласите бота ClashKing на свой сервер Discord и используйте команду /addclan. Мы работаем над тем, чтобы сделать эту функцию доступной в приложении в ближайшее время.';

  @override
  String get faqTrackingDown => 'Отслеживаем';

  @override
  String get faqTrackingDownAnswer => 'Отслеживание может перестать работать на определенный период времени. Вот почему иногда в ваших данных могут быть дыры. Мы работаем над улучшением этого.';

  @override
  String get faqApiLimitation => 'Clash of Clans API ограничение';

  @override
  String get faqApiLimitationAnswer => 'Некоторые данные предоставлены Clash of Clans, и их API имеет некоторые ограничения. Это касается отслеживания легенд, иногда оно суммирует получение и потерю трофеев, как если бы это была одна атака. Вот почему у нас нет никакой информации об уровнях ваших зданий.';

  @override
  String get faqSupportWork => 'Как я могу поддержать вашу работу?';

  @override
  String get faqSupportWorkAnswer => 'Есть несколько способов поддержать нас:';

  @override
  String get faqUseCodeClashKing => 'Используйте код \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Поддержать нас в Patreon';

  @override
  String get faqShareTheApp => 'Поделитесь этим приложением со своими друзьями';

  @override
  String get faqRateTheApp => 'Предложить особенности';

  @override
  String get faqHelpUsTranslate => 'Помогите нам перевести это приложение';

  @override
  String get faqHowToInviteTheBot => 'Как мне пригласить вашего бота на мой сервер Discord?';

  @override
  String get faqHowToInviteTheBotAnswer => 'Вы можете пригласить нашего бота на свой сервер, нажав на кнопку ниже. Вам понадобится разрешение «Управление сервером», чтобы добавить бота.';

  @override
  String get faqInviteTheBot => 'Пригласить бота ClashKing';

  @override
  String get faqNeedHelp => 'Мне нужна помощь или я хотел бы внести предложение. Как я могу связаться с вами?';

  @override
  String get faqNeedHelpAnswer => 'Вы можете присоединиться к нашему Discord-серверу, чтобы попросить о помощи или оставить отзыв, или вы можете написать нам по адресу devs@clashkingbot.com. Пожалуйста, пишите только на английском или французском языке.';

  @override
  String get faqSendEmail => 'Отправить e-mail';

  @override
  String get faqJoinDiscord => 'Присоединяйтесь к нашему Discord серверу';

  @override
  String get faqCannotOpenMailClient => 'По некоторым причинам мы не можем открыть ваш почтовый клиент. Мы скопировали адрес электронной почты для вас. Вы можете написать письмо и вставить адрес в поле получателя.';

  @override
  String get helpUsTranslate => 'Помогите нам с переводом';

  @override
  String get suggestFeatures => 'Предложить особенности';

  @override
  String get thankYou => 'Спасибо!';

  @override
  String get thankYouContent => 'Огромное спасибо всем нашим замечательным переводчикам, которые помогают нам сделать это приложение доступным для большего количества людей по всему миру!';

  @override
  String get helpTranslateContent => 'Вы можете помочь нам перевести приложение на Crowdin. Если ваш язык недоступен на Crowdin, смело запрашивайте его на нашем сервере Discord. Большое спасибо за вашу помощь!';

  @override
  String get helpTranslateButton => 'Помогите с переводом на Crowdin';

  @override
  String get versionDevice => 'Версия и устройство';

  @override
  String get loading => 'Загрузка...';

  @override
  String get errorLoadingVersion => 'Ошибка загрузки версии';

  @override
  String get currentTranslators => 'Текущие Переводчики';

  @override
  String get betaFeature => 'Бета-Функция';

  @override
  String get beta => 'Бета';

  @override
  String get betaDescription => 'Эта функция в настоящее время находится в стадии бета-тестирования, она может содержать некоторые ошибки или быть неполной. Мы активно работаем над улучшениями и приветствуем ваши отзывы. Пожалуйста, делитесь своими идеями и сообщайте о любых проблемах на нашем сервере Дискорд, чтобы помочь нам сделать его лучше.';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get all => 'Все';

  @override
  String get hourIndicator => 'ч';

  @override
  String get minIndicator => 'м';

  @override
  String get noDataAvailable => 'Данные отсутствуют.';

  @override
  String get close => 'Закрыть';

  @override
  String get closed => 'Закрыт';

  @override
  String get error => 'Ошибка';

  @override
  String get player => 'Игрок';

  @override
  String notFoundOrNotLinkedToOurSystem(String player) {
    return '$player не найден или не связан с нашей системой.';
  }

  @override
  String get tryAnotherNameOrTagOrLinkIt => 'Попробуйте другое имя/тег или привяжите его.';

  @override
  String get playerNotFound => 'Игрок не найден';

  @override
  String get noValueEntered => 'Значение не введено';

  @override
  String get manage => 'Управление';

  @override
  String get enterPlayerTag => 'Введите тег игрока';

  @override
  String get add => 'Добавить';

  @override
  String get delete => 'Удалить';

  @override
  String get addAccount => 'Добавить аккаунт';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get playerTagNotExists => 'Введенный тег игрока не существует.';

  @override
  String accountAlreadyLinked(Object tag) {
    return 'Тег игрока уже связан с кем-то.';
  }

  @override
  String get enterApiToken => 'Введите API-токен учетной записи, чтобы подтвердить, что он ваш. Вы можете найти его в настройках Clash of Clans > Дополнительные настройки > API-токен.';

  @override
  String get wrongApiToken => 'Тег игрока уже привязан к вм.';

  @override
  String get accountAlreadyLinkedToYou => 'Тег игрока уже привязан к вам.';

  @override
  String get apiToken => 'Аккаунт API Токен';

  @override
  String get failedToAddTryAgain => 'Не удалось добавить ссылку. Пожалуйста, повторите попытку позже.';

  @override
  String get fillAllFields => 'Please fill all fields.';

  @override
  String get failedToDeleteTryAgain => 'Не удалось добавить ссылку. Пожалуйста, повторите попытку позже.';

  @override
  String get enterPlayerTagWarning => 'Вам необходимо ввести тег игрока и нажать «+», чтобы продолжить.';

  @override
  String get failedToLoadAccountData => 'Failed to load accounts data.';

  @override
  String get loadAccountData => 'Load accounts data';

  @override
  String get search => 'Поиск';

  @override
  String get warning => 'Внимание';

  @override
  String get exitAppToOpenClash => 'Вам следует выйти из приложения, чтобы открыть Clash of Clans.';

  @override
  String get confirmLogout => 'Вы уверены, что хотите выйти?';

  @override
  String get tagOrNamePlayer => 'Тег или имя игрока';

  @override
  String get searchPlayer => 'Найти игрока';

  @override
  String get nameOrTagPlayer => 'Имя или тег игрока';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Ваш клан — «$clan» ($tag).';
  }

  @override
  String playerRatioDescription(String ratio, String donations, String received) {
    return 'Ваш коэффициент пожертвования составляет $ratio. Вы пожертвовали $donations войск и получили $received войск.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Ваши военные предпочтения: \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'У вас есть $stars боевых звезд.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'You have $trophies trophies. You\'re currently in $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Your Town Hall level is $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Your Builder Hall level is $level and you have $trophies trophies.';
  }

  @override
  String get dashboard => 'Панель управления';

  @override
  String get homeBase => 'Родная деревня';

  @override
  String get th => 'ТХ';

  @override
  String get builderBase => 'Деревня Строителя';

  @override
  String get bh => 'ДС';

  @override
  String get clanCapital => 'Столица клана';

  @override
  String get leader => 'Глава';

  @override
  String get coLeader => 'Соруководитель';

  @override
  String get elder => 'Старейшина';

  @override
  String get member => 'Участник';

  @override
  String get ready => 'Opted In';

  @override
  String get unready => 'Opted Out';

  @override
  String level(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get heroes => 'Герои';

  @override
  String get equipment => 'Снаряжение';

  @override
  String get troops => 'Войны';

  @override
  String get superTroops => 'Супервойны';

  @override
  String get activeSuperTroops => 'Active Super Troops';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get pets => 'Животные';

  @override
  String get siegeMachines => 'Осадные машины';

  @override
  String get spells => 'Заклинания';

  @override
  String get achievements => 'Список достижений';

  @override
  String get byDay => 'За день';

  @override
  String get bySeason => 'By Season';

  @override
  String dayIndex(int index) {
    return 'Day $index';
  }

  @override
  String indexDays(int index) {
    return '$index days';
  }

  @override
  String get bestTrophies => 'Best Trophies';

  @override
  String get mostAttacks => 'Most Attacks';

  @override
  String get lastSeason => 'Последний сезон';

  @override
  String get bestRank => 'Best Global Rank';

  @override
  String daysLeft(int days) {
    return '$days days left';
  }

  @override
  String get date => 'Дата';

  @override
  String get stats => 'Статистика';

  @override
  String get fullStats => 'Full Stats';

  @override
  String get details => 'Детали';

  @override
  String get seasonStats => 'Статистика сезона';

  @override
  String get charts => 'Диаграммы';

  @override
  String get history => 'Журнал';

  @override
  String get legendLeague => 'Легендарная лига';

  @override
  String get notInLegendLeague => 'Not in Legend League';

  @override
  String get noLegendsDataToday => 'You\'re not in Legend League, but past seasons are available.';

  @override
  String legendStartDescription(String trophies) {
    return 'You started the day with $trophies trophies.';
  }

  @override
  String legendNoRankLocalDescription(String country, int trophies) {
    return 'You are currently not ranked ($country) with $trophies trophies.';
  }

  @override
  String legendRankLocalDescription(Object country, Object rank, Object trophies) {
    return 'You are currently ranked $rank ($country) with $trophies trophies.';
  }

  @override
  String legendGainDescription(int trophies) {
    return 'You gained $trophies trophies for now.';
  }

  @override
  String legendLossDescription(int trophies) {
    return 'You lost $trophies trophies for now.';
  }

  @override
  String legendNoGlobalRankDescription(int trophies) {
    return 'You are currently not ranked globally with $trophies trophies.';
  }

  @override
  String legendGlobalRankDescription(int rank, Object trophies) {
    return 'You are currently ranked $rank globally.';
  }

  @override
  String get noRank => 'Нет рейтингов';

  @override
  String get started => 'Запущен';

  @override
  String get ended => 'Завершен';

  @override
  String get average => 'Средний';

  @override
  String get remaining => 'Осталось';

  @override
  String get legendsTitle => 'Inaccurate data?';

  @override
  String get legendsExplanation_intro => 'Due to limitations of the Clash of Clans API, our data might not always be perfectly accurate. Here\'s why:\n';

  @override
  String get legendsExplanation_api_delay_title => '1. API Delay: ';

  @override
  String get legendsExplanation_api_delay_body => 'The API can take up to 5 minutes to update, causing a lag in reflecting real-time trophy changes.\n';

  @override
  String get legendsExplanation_concurrent_changes_title => '2. Concurrent Changes: \n';

  @override
  String get legendsExplanation_multiple_attacks_defenses_title => '- Multiple Attacks/Defenses: ';

  @override
  String get legendsExplanation_multiple_attacks_defenses_body => 'If multiple attacks or defenses happen in quick succession, the API might show combined results (e.g., +68 or -68).\n';

  @override
  String get legendsExplanation_simultaneous_attack_defense_title => '- Simultaneous Attack and Defense: ';

  @override
  String get legendsExplanation_simultaneous_attack_defense_body => 'If an attack and defense occur at the same time, you might see a mixed result (e.g., +4).\n';

  @override
  String get legendsExplanation_net_gain_loss_title => '3. Net Gain/Loss: ';

  @override
  String get legendsExplanation_net_gain_loss_body => 'Despite timing issues, the overall net gain or loss for the day is accurate. ';

  @override
  String get legendsExplanation_conclusion => 'These limitations are common across all tools using the Clash of Clans API. We sadly can\'t fix that as it is in Supercell\'s hands. We do our best to compensate for these limits and provide results as close to reality as possible. Thank you for understanding!';

  @override
  String get toDoList => 'To-do list';

  @override
  String get clanGames => 'Clan Games';

  @override
  String get seasonPass => 'Season Pass';

  @override
  String lastActive(String date) {
    return 'Last active: $date';
  }

  @override
  String get playerNotTracked => 'This player is not tracked. Data may be inaccurate.';

  @override
  String numberAccounts(int number) {
    return '$number accounts';
  }

  @override
  String numberActiveAccounts(int number) {
    return '$number active accounts';
  }

  @override
  String numberInactiveAccounts(int number) {
    return '$number inactive accounts';
  }

  @override
  String get activeAccounts => 'Active accounts';

  @override
  String get inactiveAccounts => 'Inactive accounts';

  @override
  String get noInactiveAccounts => 'No inactive accounts.';

  @override
  String get noActiveAccounts => 'No active accounts.';

  @override
  String get todoExplanation_title => 'Task Calculation';

  @override
  String get todoExplanation_intro => 'The task completion percentage is calculated based on the following activities with specific weightings:';

  @override
  String get todoExplanation_legends_title => 'Legend League:';

  @override
  String get todoExplanation_legends => 'Weight of 8 points per account, 1 attack = 1 point.';

  @override
  String get todoExplanation_raids_title => 'Raids:';

  @override
  String get todoExplanation_raids => 'Weight of 5 points per account (or 6 if the last attack has been unlocked), 1 attack = 1 point.';

  @override
  String get todoExplanation_clanWars_title => 'Clan Wars:';

  @override
  String get todoExplanation_clanWars => 'Weight of 2 points per account, 1 attack = 1 point.';

  @override
  String get todoExplanation_cwl_title => 'Clan War League:';

  @override
  String get todoExplanation_cwl => 'Weight of 1 point per account, 1 attack = 1 point. CWL cannot be tracked if the player is not in their league clan.';

  @override
  String get todoExplanation_passAndGames_title => 'Season Pass & Clan Games:';

  @override
  String get todoExplanation_passAndGames => 'Weight of 2 points each per account. The ratio is based on the number of days remaining (1 month for the pass and 6 days for the games). Green = on track to complete the pass or games, red = behind schedule.';

  @override
  String get todoExplanation_conclusion => 'The final percentage is calculated by dividing the total actions completed during ongoing events by the total required actions. Accounts inactive for more than 14 days are excluded from the calculation.';

  @override
  String get worst => 'Наихудший';

  @override
  String get best => 'Лучший';

  @override
  String get total => 'Всего';

  @override
  String get heroesEquipments => 'Hero equipments';

  @override
  String daysAgo(int days) {
    return '$days дн. назад';
  }

  @override
  String dayAgo(int day) {
    return '$day день назад';
  }

  @override
  String hourAgo(int hour) {
    return '$hour час назад';
  }

  @override
  String hoursAgo(int hours, Object Hours) {
    return '$hours часов назад';
  }

  @override
  String minuteAgo(int minute) {
    return '$minute минуту назад';
  }

  @override
  String minutesAgo(int minutes) {
    return '$minutes минут назад';
  }

  @override
  String secondAgo(int seconds) {
    return '$seconds сек. назад';
  }

  @override
  String get justNow => 'Сейчас';

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
  String get trophiesByMonth => 'Трофеи по месяцам';

  @override
  String get trophiesBySeason => 'Trophies by season';

  @override
  String get eosTrophies => 'Трофеи конца сезона';

  @override
  String get eosDetails => 'End Of Season Details';

  @override
  String get searchClan => 'Найти клан';

  @override
  String get clanName => 'Clan\'s name';

  @override
  String get nameOrTagClan => 'Clan\'s name or tag';

  @override
  String get noResult => 'Нет результатов.';

  @override
  String get filters => 'Фильтры';

  @override
  String get whatever => 'Не важно';

  @override
  String get any => 'Any';

  @override
  String get notSet => 'Not set';

  @override
  String get warFrequency => 'War frequency';

  @override
  String get minimumMembers => 'Минимум участников';

  @override
  String get maximumMembers => 'Максимум участников';

  @override
  String get location => 'Расположение';

  @override
  String get minimumClanPoints => 'Минимальные очки клана';

  @override
  String get minimumClanLevel => 'Минимальный уровень клана';

  @override
  String get noClan => 'Без клана';

  @override
  String get joinClanToUnlockNewFeatures => 'Присоединитесь к Клану для разблокировки новых функций.';

  @override
  String get apply => 'Применить';

  @override
  String get opened => 'Opened';

  @override
  String get inviteOnly => 'Invite Only';

  @override
  String get cancel => 'Cancel';

  @override
  String get clan => 'Clan';

  @override
  String get clans => 'Clans';

  @override
  String get members => 'Members';

  @override
  String get role => 'Role';

  @override
  String get expLevel => 'Experience Level';

  @override
  String get townHallLevel => 'TH Level';

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
    return 'Town Hall $level';
  }

  @override
  String get byNumberOfWars => 'By number of wars';

  @override
  String get ok => 'OK';

  @override
  String get byDateRange => 'By date range';

  @override
  String get selectSeason => 'Select a season';

  @override
  String get year => 'Year';

  @override
  String get month => 'Month';

  @override
  String get allTownHalls => 'All Town Halls';

  @override
  String seasonDate(String date) {
    return '$date season';
  }

  @override
  String lastXwars(int number) {
    return 'Last $number wars';
  }

  @override
  String get friendly => 'Friendly';

  @override
  String get cwl => 'CWL';

  @override
  String get random => 'Random';

  @override
  String get selectMembersThLevel => 'Members TH Level';

  @override
  String get selectOpponentsThLevel => 'Opponents TH Level';

  @override
  String get equalThLevel => 'Equal TH';

  @override
  String get builderBaseTrophies => 'BB Trophies';

  @override
  String get donations => 'Donations';

  @override
  String get donationsReceived => 'Donations Received';

  @override
  String get donationsRatio => 'Donation Ratio';

  @override
  String get trophies => 'Trophies';

  @override
  String get always => 'Always';

  @override
  String get never => 'Never';

  @override
  String get unknown => 'Unknown';

  @override
  String get oncePerWeek => '1/week';

  @override
  String get twicePerWeek => '2/week';

  @override
  String get rarely => 'Rarely';

  @override
  String get warLeague => 'War/League';

  @override
  String get war => 'War';

  @override
  String get league => 'League';

  @override
  String get wars => 'Wars';

  @override
  String get ongoingWar => 'Ongoing war';

  @override
  String get ongoingCwl => 'Ongoing CWL';

  @override
  String get cantOpenLink => 'We can\'t open this link.';

  @override
  String get notInWar => 'Not in war';

  @override
  String get warHistory => 'War History';

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
  String warHistoryAverageClanStarsPerMember(Object stars) {
    return 'Your clan had an average of $stars stars per member from the last 50 wars.';
  }

  @override
  String warHistoryAverageMembers(int members) {
    return '~$members members per war';
  }

  @override
  String attacksLeftDescription(int attacks, String type) {
    return 'You have $attacks attack(s) left ($type).';
  }

  @override
  String defensesLeftDescription(int defenses, String type) {
    return 'You have $defenses defense(s) left ($type).';
  }

  @override
  String noAttacksLeftDescription(String type) {
    return 'Congratulations, you have done all your attacks ($type)!';
  }

  @override
  String noDefensesLeftDescription(Object type) {
    return 'You have taken all your defenses ($type)!';
  }

  @override
  String pointsLeftDescription(int points, String type) {
    return 'You have $points points left to get today to be in time for the end of the event ($type).';
  }

  @override
  String pointsLeftDescriptionNoPoints(String type) {
    return 'Congratulations, you are on time to get the maximum rewards at the end of the event ($type)!';
  }

  @override
  String get averageStars => 'Average stars';

  @override
  String get averageDestruction => 'Average destruction';

  @override
  String get oneStar => '1 star';

  @override
  String get twoStars => '2 stars';

  @override
  String get threeStars => '3 stars';

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
  String get warParticipation => 'War Participation';

  @override
  String get missed => 'Missed';

  @override
  String get totalStars => 'Total';

  @override
  String get destruction => 'Destruction';

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
  String get toggleTownHallVisibility => 'Hide/Show stats from former TH levels';

  @override
  String get warLog => 'War Log';

  @override
  String get publicWarLog => 'Public War Log';

  @override
  String get privateWarLog => 'Private War Log';

  @override
  String startsIn(String time) {
    return 'Starts in $time';
  }

  @override
  String startsAt(String time) {
    return 'Starts at $time';
  }

  @override
  String endsIn(String time) {
    return 'Ends in $time';
  }

  @override
  String endsAt(String time) {
    return 'Ends at $time';
  }

  @override
  String get joinLeaveLogs => 'Join/Leave Logs';

  @override
  String get join => 'Join';

  @override
  String get leave => 'Leave';

  @override
  String get reset => 'Reset';

  @override
  String get joins => 'Joins';

  @override
  String get leaves => 'Leaves';

  @override
  String get uniquePlayers => 'Unique Players';

  @override
  String get movingPlayers => 'Moving Players';

  @override
  String get mostMovingPlayers => 'Most Moving Players';

  @override
  String get stillInClan => 'Still in Clan';

  @override
  String get leftForever => 'Left Forever';

  @override
  String get rejoinedPlayers => 'Rejoined Players';

  @override
  String get avgTimeJoinLeave => 'Avg Join/Leave Time';

  @override
  String get peakHour => 'Most Active Hour';

  @override
  String leaveNumberDescription(int number, String date) {
    return '$number player(s) left the clan during the current season ($date).';
  }

  @override
  String joinNumberDescription(int number, String date) {
    return '$number player(s) joined the clan during the current season ($date).';
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
    return 'Your clan has lost $number member(s) this season ($date).';
  }

  @override
  String joinLeaveDifferenceEqualDescription(String date) {
    return 'Your clan has the same number of members as at the beginning of the season ($date).';
  }

  @override
  String leftOnAt(String date, String time) {
    return 'Left on $date at $time.';
  }

  @override
  String joinedOnAt(String date, String time) {
    return 'Joined on $date at $time.';
  }

  @override
  String get statistics => 'Statistics';

  @override
  String get stars => 'Stars';

  @override
  String get numberOfStars => 'Number of stars';

  @override
  String get destructionRate => 'Destruction rate';

  @override
  String get events => 'Events';

  @override
  String get team => 'Teams';

  @override
  String get myTeam => 'My team';

  @override
  String get enemiesTeam => 'Enemies';

  @override
  String get defense => 'Defense';

  @override
  String get defenses => 'Defenses';

  @override
  String get bestDefenses => 'Best defenses';

  @override
  String bestDefenseOutOf(int number) {
    return 'Best defense (out of $number)';
  }

  @override
  String get attack => 'Attack';

  @override
  String get attacks => 'Attacks';

  @override
  String get bestAttacks => 'Best attacks';

  @override
  String get noAttackYet => 'No attack yet';

  @override
  String get noDefenseYet => 'No defense yet';

  @override
  String get bestPerformance => 'Best performance';

  @override
  String get victory => 'Победа';

  @override
  String get defeat => 'Поражение';

  @override
  String get draw => 'Ничья';

  @override
  String get perfectWar => 'Идеальная война';

  @override
  String get newest => 'Newest';

  @override
  String get oldest => 'Oldest';

  @override
  String get warEnded => 'War ended';

  @override
  String get preparation => 'Preparation';

  @override
  String isNotInWar(String clan) {
    return '$clan is not in war.';
  }

  @override
  String warLogIsClosed(String clan) {
    return '$clan\'s war log is closed.';
  }

  @override
  String get askForWar => 'Contact the leader or a co-leader to start a war.';

  @override
  String get askForWarLogOpening => 'Contact a leader or a co-leader to open the war log.';

  @override
  String get warLogClosed => 'War log closed.';

  @override
  String get rounds => 'Rounds';

  @override
  String roundNumber(int number) {
    return 'Round $number';
  }

  @override
  String currentRound(int number) {
    return 'Current round (Round $number)';
  }

  @override
  String get noDataAvailableForThisWar => 'No data available for this war';

  @override
  String get stateOfTheWar => 'State of the war';

  @override
  String starsNeededToTakeTheLead(String clan, int star, int star2, String percent, Object stars2) {
    return '$clan still need $star more star(s) or $stars2 star(s) and $percent% to take the lead.';
  }

  @override
  String starsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan still need $percent% or 1 more star to take the lead';
  }

  @override
  String get clanDraw => 'The two clans are tied';

  @override
  String get fastCalculator => 'Fast calculator';

  @override
  String fastCalculatorAnswer(String percentNeedeed, String result, Object percentNeeded) {
    return 'To achieve a destruction rate of $percentNeeded%, a total of $result% is needed.';
  }

  @override
  String get teamSize => 'Team size';

  @override
  String get neededOverall => '% Needed overall';

  @override
  String get calculate => 'Calculate';

  @override
  String get warStats => 'War Stats';

  @override
  String warAttacksNumber(int number_time, int number_war) {
    return 'You attacked $number_time time(s) during the last $number_war wars.';
  }

  @override
  String warDefensesNumber(int number_time, int number_war) {
    return 'You defended $number_time time(s) during the last $number_war wars.';
  }

  @override
  String warAverageStars(String stars) {
    return 'You had an average of $stars stars per war.';
  }

  @override
  String warAverageDestruction(String percent) {
    return 'You had an average of $percent% destruction rate per war.';
  }

  @override
  String warAverageStarsDefense(double stars) {
    return 'You had an average of $stars stars per defense.';
  }

  @override
  String warAverageDestructionDefense(Object percent) {
    return 'You had an average of $percent% destruction rate per defense.';
  }

  @override
  String get membersStats => 'Members Stats';

  @override
  String get clanWarLeague => 'Clan War League';

  @override
  String cwlRank(int rank) {
    return 'Your clan is currently ranked $rank.';
  }

  @override
  String cwlStars(int stars) {
    return 'Your clan has a total of $stars stars.';
  }

  @override
  String cwlMissingStarsFromNext(int stars) {
    return 'Your clan is missing $stars stars to catch up with the next clan.';
  }

  @override
  String cwlMissingStarsFromFirst(int stars) {
    return 'Your clan is missing $stars stars to catch up with the first clan.';
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
  String cwlCurrentRound(int round) {
    return 'It\'s currently round $round.';
  }

  @override
  String get noAccountLinkedToYourProfileFound => 'No account linked to your profile found';

  @override
  String get management => 'Management';

  @override
  String get comingSoon => 'Coming soon!';

  @override
  String get connectionError => 'An error occurred. Please check your internet connection and try again.';

  @override
  String get connectionErrorRelaunch => 'An error occurred. Please check your internet connection and relaunch the app.';

  @override
  String updatedAt(String time) {
    return 'Updated at $time';
  }

  @override
  String get tools => 'Tools';

  @override
  String get community => 'Community';

  @override
  String get raids => 'Raids';

  @override
  String get lastRaids => 'Last raids';

  @override
  String get ongoingRaids => 'Ongoing raids';

  @override
  String get districtsDestroyed => 'Districts destroyed';

  @override
  String get raidsCompleted => 'Raids completed';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get maintenanceDescription => 'Clash of Clans is currently under maintenance, so we can\'t access the API. Please check back later.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get downloadTooltip => 'Download CWL summary';

  @override
  String get downloadInProgress => 'Downloading file... It can take a few seconds...';

  @override
  String downloadSuccess(String path) {
    return 'File saved successfully in \$$path';
  }

  @override
  String get downloadError => 'Failed to download file';
}
