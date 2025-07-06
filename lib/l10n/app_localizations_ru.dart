// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'ClashKing';

  @override
  String get appDescription =>
      'Ваш идеальный спутник Clash of Clans для отслеживания статистики, управления кланами и анализа производительности.';

  @override
  String get generalLoading => 'Загрузка...';

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
  String get generalRetry => 'Повторить';

  @override
  String get generalTryAgain => 'Попробовать снова';

  @override
  String get generalCancel => 'Отмена';

  @override
  String get generalOk => 'OK';

  @override
  String get generalApply => 'Применить';

  @override
  String get generalConfirm => 'Подтвердить';

  @override
  String get generalManage => 'Управление';

  @override
  String get generalSettings => 'Настройки';

  @override
  String get generalCopiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get generalComingSoon => 'Скоро!';

  @override
  String generalLastRefresh(String time) {
    return 'Last refresh: $time';
  }

  @override
  String generalRefreshFailed(String error) {
    return 'Refresh failed: $error';
  }

  @override
  String get generalAll => 'Все';

  @override
  String get generalTotal => 'Всего';

  @override
  String get generalBest => 'Лучший';

  @override
  String get generalWorst => 'Наихудший';

  @override
  String get generalAverage => 'Средний';

  @override
  String get generalRemaining => 'Осталось';

  @override
  String get generalActive => 'Активный';

  @override
  String get generalInactive => 'Неактивный';

  @override
  String get generalStarted => 'Запущен';

  @override
  String get generalEnded => 'Завершен';

  @override
  String get generalRole => 'Роль';

  @override
  String get generalStats => 'Статистика';

  @override
  String get generalFullStats => 'Полная статистика';

  @override
  String get generalDetails => 'Детали';

  @override
  String get generalHistory => 'Журнал';

  @override
  String get generalFilters => 'Фильтры';

  @override
  String get generalNotSet => 'Не установлено';

  @override
  String get generalWarning => 'Внимание';

  @override
  String get generalNoDataAvailable => 'Данные отсутствуют.';

  @override
  String get authSignUp => 'Регистрация';

  @override
  String get authLogin => 'Вход';

  @override
  String get authLogout => 'Выход';

  @override
  String get authCreateAccount => 'Создать аккаунт';

  @override
  String get authJoinClashKing => 'Присоединиться к ClashKing';

  @override
  String get authCreateClashKingAccount => 'Создать аккаунт ClashKing';

  @override
  String get authCreateAccountToGetStarted =>
      'Создайте свой аккаунт, чтобы начать';

  @override
  String get authAlreadyHaveAccount => 'Уже есть аккаунт? Войдите';

  @override
  String get authConfirmLogout => 'Вы уверены, что хотите выйти?';

  @override
  String get authDiscordTitle => 'Discord';

  @override
  String get authDiscordSignIn => 'Вход через Discord';

  @override
  String get authDiscordContinue => 'Продолжить с Discord';

  @override
  String get authDiscordDescription =>
      'Синхронизируйте свои данные с ClashKing Bot и раскройте весь потенциал ClashKing!';

  @override
  String get authEmailTitle => 'Электронная почта';

  @override
  String get authEmailDescription =>
      'Используйте электронную почту, если вы не можете получить доступ к Discord или предпочитаете функции только приложения';

  @override
  String get authEmailRequired => 'Пожалуйста, введите ваш email';

  @override
  String get authEmailInvalid => 'Пожалуйста, введите действительный email';

  @override
  String get authPasswordLabel => 'Пароль';

  @override
  String get authPasswordConfirm => 'Подтвердите пароль';

  @override
  String get authPasswordRequired => 'Пожалуйста, введите ваш пароль';

  @override
  String get authPasswordConfirmRequired =>
      'Пожалуйста, подтвердите ваш пароль';

  @override
  String get authPasswordMismatch => 'Пароли не совпадают';

  @override
  String get authPasswordTooShort =>
      'Пароль должен содержать не менее 8 символов';

  @override
  String get authPasswordRequirements =>
      'Пароль должен содержать: заглавные буквы, строчные буквы, цифры и специальные символы';

  @override
  String get authPasswordForgot => 'Забыли пароль?';

  @override
  String get authUsernameLabel => 'Имя пользователя';

  @override
  String get authUsernameRequired => 'Пожалуйста, введите имя пользователя';

  @override
  String get authUsernameTooShort =>
      'Имя пользователя должно содержать не менее 3 символов';

  @override
  String get authErrorConnection =>
      'Произошла ошибка. Пожалуйста, проверьте ваше интернет-соединение и попробуйте снова.';

  @override
  String get authErrorConnectionRelaunch =>
      'Произошла ошибка. Пожалуйста, проверьте ваше интернет-соединение и перезапустите приложение.';

  @override
  String get authAccountManagement => 'Управление аккаунтом';

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
  String get accountsWelcome => 'Добро пожаловать!';

  @override
  String get accountsWelcomeMessage =>
      'Пожалуйста, добавьте один или несколько аккаунтов Clash of Clans в свой профиль. Вы сможете добавлять или удалять аккаунты позже.';

  @override
  String get accountsManageTitle => 'Manage your accounts';

  @override
  String get accountsNoneFound => 'No account linked to your profile found';

  @override
  String get accountsPlayerTag => 'Player Tag (#ABC123)';

  @override
  String get accountsEnterPlayerTag => 'Введите тег игрока';

  @override
  String get accountsAdd => 'Добавить аккаунт';

  @override
  String get accountsDelete => 'Удалить аккаунт';

  @override
  String get accountsApiToken => 'Аккаунт API Токен';

  @override
  String get accountsEnterApiToken =>
      'Введите API-токен учетной записи, чтобы подтвердить, что он ваш. Вы можете найти его в настройках Clash of Clans > Дополнительные настройки > API-токен.';

  @override
  String get accountsFillAllFields => 'Please fill all fields.';

  @override
  String get accountsErrorTagNotExists => 'Введенный тег игрока не существует.';

  @override
  String accountsErrorAlreadyLinked(Object tag) {
    return 'Тег игрока уже связан с кем-то.';
  }

  @override
  String get accountsErrorAlreadyLinkedToYou =>
      'Тег игрока уже привязан к вам.';

  @override
  String get accountsErrorWrongApiToken => 'Тег игрока уже привязан к вм.';

  @override
  String get accountsErrorFailedToAdd =>
      'Failed to add the account. Please try again later.';

  @override
  String get accountsErrorFailedToDelete =>
      'Не удалось добавить ссылку. Пожалуйста, повторите попытку позже.';

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
  String get errorLoadingVersion => 'Ошибка загрузки версии';

  @override
  String get errorCannotOpenLink => 'We can\'t open this link.';

  @override
  String get errorExitAppToOpenClash =>
      'Вам следует выйти из приложения, чтобы открыть Clash of Clans.';

  @override
  String get playerSearchTitle => 'Найти игрока';

  @override
  String get playerSearchPlaceholder => 'Имя или тег игрока';

  @override
  String playerLastActive(String date) {
    return 'Last active: $date';
  }

  @override
  String get playerNotTracked =>
      'This player is not tracked. Data may be inaccurate.';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Ваш клан — «$clan» ($tag).';
  }

  @override
  String playerRatioDescription(
      String ratio, String donations, String received) {
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
  String get gameBaseHome => 'Родная деревня';

  @override
  String get gameBaseBuilder => 'Деревня Строителя';

  @override
  String get gameClanCapital => 'Столица клана';

  @override
  String get gameTownHall => 'ТХ';

  @override
  String get gameTownHallLevel => 'TH Level';

  @override
  String gameTownHallLevelNumber(int level) {
    return 'Town Hall $level';
  }

  @override
  String gameTHLevel(int level) {
    return 'TH$level';
  }

  @override
  String get gameExpLevel => 'Experience Level';

  @override
  String get gameTrophies => 'Trophies';

  @override
  String get gameBuilderBaseTrophies => 'BB Trophies';

  @override
  String get gameDonations => 'Donations';

  @override
  String get gameDonationsReceived => 'Donations Received';

  @override
  String get gameDonationsRatio => 'Donation Ratio';

  @override
  String gameLevel(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get gameHeroes => 'Герои';

  @override
  String get gameEquipment => 'Снаряжение';

  @override
  String get gameHeroesEquipments => 'Hero equipments';

  @override
  String get gameTroops => 'Войны';

  @override
  String get gameActiveSuperTroops => 'Active Super Troops';

  @override
  String get gamePets => 'Животные';

  @override
  String get gameSiegeMachines => 'Осадные машины';

  @override
  String get gameSpells => 'Заклинания';

  @override
  String get gameAchievements => 'Список достижений';

  @override
  String get gameClanGames => 'Clan Games';

  @override
  String get gameSeasonPass => 'Season Pass';

  @override
  String get gameCreatorCode => 'Код Создателя: ClashKing';

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
  String get clanTitle => 'Clan';

  @override
  String get clanSearchTitle => 'Найти клан';

  @override
  String get clanSearchPlaceholder => 'Clan\'s name';

  @override
  String get clanNone => 'Без клана';

  @override
  String get clanJoinToUnlock =>
      'Присоединитесь к Клану для разблокировки новых функций.';

  @override
  String get clanMembers => 'Members';

  @override
  String get clanWarFrequency => 'War frequency';

  @override
  String get clanMinimumMembers => 'Минимум участников';

  @override
  String get clanMaximumMembers => 'Максимум участников';

  @override
  String get clanLocation => 'Расположение';

  @override
  String get clanMinimumPoints => 'Минимальные очки клана';

  @override
  String get clanMinimumLevel => 'Минимальный уровень клана';

  @override
  String get clanInviteOnly => 'Invite Only';

  @override
  String get clanOpened => 'Opened';

  @override
  String get clanClosed => 'Закрыт';

  @override
  String get clanRoleLeader => 'Глава';

  @override
  String get clanRoleCoLeader => 'Соруководитель';

  @override
  String get clanRoleElder => 'Старейшина';

  @override
  String get clanRoleMember => 'Участник';

  @override
  String get clanWarFrequencyAlways => 'Always';

  @override
  String get clanWarFrequencyNever => 'Never';

  @override
  String get clanWarFrequencyUnknown => 'Unknown';

  @override
  String get clanWarFrequencyOncePerWeek => '1/week';

  @override
  String get clanWarFrequencyMoreThanOncePerWeek => 'More than 1/week';

  @override
  String get clanWarFrequencyRarely => 'Rarely';

  @override
  String get timeHourIndicator => 'ч';

  @override
  String timeDaysAgo(int days) {
    return '$days дн. назад';
  }

  @override
  String timeDayAgo(int day) {
    return '$day день назад';
  }

  @override
  String timeHourAgo(int hour) {
    return '$hour час назад';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours часов назад';
  }

  @override
  String timeMinuteAgo(int minute) {
    return '$minute минуту назад';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes минут назад';
  }

  @override
  String get timeJustNow => 'Сейчас';

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
    return 'Starts in $time';
  }

  @override
  String timeStartsAt(String time) {
    return 'Starts at $time';
  }

  @override
  String timeEndsIn(String time) {
    return 'Ends in $time';
  }

  @override
  String timeEndsAt(String time) {
    return 'Ends at $time';
  }

  @override
  String get legendsTitle => 'Inaccurate data?';

  @override
  String get legendsNotInLeague => 'Not in Legend League';

  @override
  String get legendsNoDataToday =>
      'You\'re not in Legend League, but past seasons are available.';

  @override
  String legendsStartDescription(String trophies) {
    return 'You started the day with $trophies trophies.';
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
    return 'You gained $trophies trophies for now.';
  }

  @override
  String legendsLossDescription(int trophies) {
    return 'You lost $trophies trophies for now.';
  }

  @override
  String legendsNoGlobalRankDescription(int trophies) {
    return 'You are currently not ranked globally with $trophies trophies.';
  }

  @override
  String legendsGlobalRankDescription(int rank, int trophies) {
    return 'You are currently ranked $rank globally with $trophies trophies.';
  }

  @override
  String get legendsNoRank => 'Нет рейтингов';

  @override
  String get legendsBestTrophies => 'Best Trophies';

  @override
  String get legendsMostAttacks => 'Most Attacks';

  @override
  String get legendsLastSeason => 'Последний сезон';

  @override
  String get legendsBestRank => 'Best Global Rank';

  @override
  String get legendsTrophiesBySeason => 'Trophies by season';

  @override
  String get legendsEosTrophies => 'Трофеи конца сезона';

  @override
  String get legendsEosDetails => 'End Of Season Details';

  @override
  String get legendsInaccurateTitle => 'Inaccurate data?';

  @override
  String get legendsInaccurateIntro =>
      'Due to limitations of the Clash of Clans API, our data might not always be perfectly accurate. Here\'s why:\n';

  @override
  String get legendsInaccurateApiDelayTitle => '1. API Delay: ';

  @override
  String get legendsInaccurateApiDelayBody =>
      'The API can take up to 5 minutes to update, causing a lag in reflecting real-time trophy changes.\n';

  @override
  String get legendsInaccurateConcurrentTitle => '2. Concurrent Changes: \n';

  @override
  String get legendsInaccurateMultipleAttacksTitle =>
      '- Multiple Attacks/Defenses: ';

  @override
  String get legendsInaccurateMultipleAttacksBody =>
      'If multiple attacks or defenses happen in quick succession, the API might show combined results (e.g., +68 or -68).\n';

  @override
  String get legendsInaccurateSimultaneousTitle =>
      '- Simultaneous Attack and Defense: ';

  @override
  String get legendsInaccurateSimultaneousBody =>
      'If an attack and defense occur at the same time, you might see a mixed result (e.g., +4).\n';

  @override
  String get legendsInaccurateNetGainTitle => '3. Net Gain/Loss: ';

  @override
  String get legendsInaccurateNetGainBody =>
      'Despite timing issues, the overall net gain or loss for the day is accurate. ';

  @override
  String get legendsInaccurateConclusion =>
      'These limitations are common across all tools using the Clash of Clans API. We sadly can\'t fix that as it is in Supercell\'s hands. We do our best to compensate for these limits and provide results as close to reality as possible. Thank you for understanding!';

  @override
  String get statsSeasonStats => 'Статистика сезона';

  @override
  String get statsByDay => 'За день';

  @override
  String get statsBySeason => 'By Season';

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
  String get statsAllTownHalls => 'All Town Halls';

  @override
  String get statsMembers => 'Members Stats';

  @override
  String get todoTitle => 'To-do list';

  @override
  String get todoExplanationTitle => 'Task Calculation';

  @override
  String get todoExplanationIntro =>
      'The task completion percentage is calculated based on the following activities with specific weightings:';

  @override
  String get todoExplanationLegendsTitle => 'Legend League:';

  @override
  String get todoExplanationLegends =>
      'Weight of 8 points per account, 1 attack = 1 point.';

  @override
  String get todoExplanationRaidsTitle => 'Raids:';

  @override
  String get todoExplanationRaids =>
      'Weight of 5 points per account (or 6 if the last attack has been unlocked), 1 attack = 1 point.';

  @override
  String get todoExplanationClanWarsTitle => 'Clan Wars:';

  @override
  String get todoExplanationClanWars =>
      'Weight of 2 points per account, 1 attack = 1 point.';

  @override
  String get todoExplanationCwlTitle => 'Clan War League:';

  @override
  String get todoExplanationCwl =>
      'Weight of 1 point per account, 1 attack = 1 point. CWL cannot be tracked if the player is not in their league clan.';

  @override
  String get todoExplanationPassAndGamesTitle => 'Season Pass & Clan Games:';

  @override
  String get todoExplanationPassAndGames =>
      'Weight of 2 points each per account. The ratio is based on the number of days remaining (1 month for the pass and 6 days for the games). Green = on track to complete the pass or games, red = behind schedule.';

  @override
  String get todoExplanationConclusion =>
      'The final percentage is calculated by dividing the total actions completed during ongoing events by the total required actions. Accounts inactive for more than 14 days are excluded from the calculation.';

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
  String get warPerfectWar => 'Идеальная война';

  @override
  String get warVictory => 'Победа';

  @override
  String get warDefeat => 'Поражение';

  @override
  String get warDraw => 'Ничья';

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
  String get searchNoResult => 'Нет результатов.';

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
  String get dashboardTitle => 'Панель управления';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get navigationTeam => 'Teams';

  @override
  String get navigationStatistics => 'Statistics';

  @override
  String get versionDevice => 'Версия и устройство';

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
  String get betaFeature => 'Бета-Функция';

  @override
  String get betaLabel => 'Бета';

  @override
  String get betaDescription =>
      'Эта функция в настоящее время находится в стадии бета-тестирования, она может содержать некоторые ошибки или быть неполной. Мы активно работаем над улучшениями и приветствуем ваши отзывы. Пожалуйста, делитесь своими идеями и сообщайте о любых проблемах на нашем сервере Дискорд, чтобы помочь нам сделать его лучше.';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsSelectLanguage => 'Выберите язык';

  @override
  String get settingsToggleTheme => 'Переключить тему';

  @override
  String get faqTitle => 'Ответы на частые вопросы';

  @override
  String get faqSubtitle => 'Часто задаваемые вопросы';

  @override
  String get faqIsThisFromSupercell => 'Это приложение от Supercell?';

  @override
  String get faqFanContentPolicy =>
      'Этот материал неофициальный и не одобрен Supercell. Для получения дополнительной информации просмотрите Политику Supercell в отношении контента для фанатов: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate =>
      'Почему данные иногда неточны или отсутствуют?';

  @override
  String get faqClanNotTracked => 'Клан не отслеживается';

  @override
  String get faqClanNotTrackedAnswer =>
      'ClashKing может получить эту информацию только если клан отслеживается. Если ваш клан не отслеживается, пригласите бота ClashKing на свой сервер Discord и используйте команду /addclan. Мы работаем над тем, чтобы сделать эту функцию доступной в приложении в ближайшее время.';

  @override
  String get faqTrackingDown => 'Отслеживаем';

  @override
  String get faqTrackingDownAnswer =>
      'Отслеживание может перестать работать на определенный период времени. Вот почему иногда в ваших данных могут быть дыры. Мы работаем над улучшением этого.';

  @override
  String get faqApiLimitation => 'Clash of Clans API ограничение';

  @override
  String get faqApiLimitationAnswer =>
      'Некоторые данные предоставлены Clash of Clans, и их API имеет некоторые ограничения. Это касается отслеживания легенд, иногда оно суммирует получение и потерю трофеев, как если бы это была одна атака. Вот почему у нас нет никакой информации об уровнях ваших зданий.';

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
  String get faqHowToInviteTheBot =>
      'Как мне пригласить вашего бота на мой сервер Discord?';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'Вы можете пригласить нашего бота на свой сервер, нажав на кнопку ниже. Вам понадобится разрешение «Управление сервером», чтобы добавить бота.';

  @override
  String get faqInviteTheBot => 'Пригласить бота ClashKing';

  @override
  String get faqNeedHelp =>
      'Мне нужна помощь или я хотел бы внести предложение. Как я могу связаться с вами?';

  @override
  String get faqNeedHelpAnswer =>
      'Вы можете присоединиться к нашему Discord-серверу, чтобы попросить о помощи или оставить отзыв, или вы можете написать нам по адресу devs@clashk.ing. Пожалуйста, пишите только на английском или французском языке.';

  @override
  String get faqSendEmail => 'Отправить e-mail';

  @override
  String get faqJoinDiscord => 'Присоединяйтесь к нашему Discord серверу';

  @override
  String get faqCannotOpenMailClient =>
      'По некоторым причинам мы не можем открыть ваш почтовый клиент. Мы скопировали адрес электронной почты для вас. Вы можете написать письмо и вставить адрес в поле получателя.';

  @override
  String get translationHelpUsTranslate => 'Помогите нам с переводом';

  @override
  String get translationSuggestFeatures => 'Предложить особенности';

  @override
  String get translationThankYou => 'Спасибо!';

  @override
  String get translationThankYouContent =>
      'Огромное спасибо всем нашим замечательным переводчикам, которые помогают нам сделать это приложение доступным для большего количества людей по всему миру!';

  @override
  String get translationHelpTranslateContent =>
      'Вы можете помочь нам перевести приложение на Crowdin. Если ваш язык недоступен на Crowdin, смело запрашивайте его на нашем сервере Discord. Большое спасибо за вашу помощь!';

  @override
  String get translationHelpTranslateButton =>
      'Помогите с переводом на Crowdin';

  @override
  String get translationCurrentTranslators => 'Текущие Переводчики';
}
