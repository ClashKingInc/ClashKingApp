// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'ClashKing';

  @override
  String get appDescription => '您的终极部落冲突伴侣，用于追踪统计数据、管理部落和分析性能。';

  @override
  String get generalLoading => '加载中...';

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
  String get generalRetry => '重试';

  @override
  String get generalTryAgain => '再试一次';

  @override
  String get generalCancel => '取消';

  @override
  String get generalOk => '确定';

  @override
  String get generalApply => '需要申请';

  @override
  String get generalConfirm => '确认';

  @override
  String get generalManage => '管理';

  @override
  String get generalSettings => '设置';

  @override
  String get generalCopiedToClipboard => '复制到剪贴板';

  @override
  String get generalComingSoon => '敬请期待！';

  @override
  String generalLastRefresh(String time) {
    return 'Last refresh: $time';
  }

  @override
  String generalRefreshFailed(String error) {
    return 'Refresh failed: $error';
  }

  @override
  String get generalAll => '所有';

  @override
  String get generalTotal => '总计';

  @override
  String get generalBest => '最佳';

  @override
  String get generalWorst => '最差';

  @override
  String get generalAverage => '平均水平';

  @override
  String get generalRemaining => '剩余时间';

  @override
  String get generalActive => '活跃';

  @override
  String get generalInactive => '非活跃';

  @override
  String get generalStarted => '已激活';

  @override
  String get generalEnded => '已结束';

  @override
  String get generalRole => '职位';

  @override
  String get generalStats => '统计数据';

  @override
  String get generalFullStats => '完整统计';

  @override
  String get generalDetails => '详细信息';

  @override
  String get generalHistory => '历史记录';

  @override
  String get generalFilters => '筛选器';

  @override
  String get generalNotSet => '未设置';

  @override
  String get generalWarning => '警告';

  @override
  String get generalNoDataAvailable => '没有可用数据';

  @override
  String get authSignUp => '注册';

  @override
  String get authLogin => '登录';

  @override
  String get authLogout => '注销';

  @override
  String get authCreateAccount => '创建账户';

  @override
  String get authJoinClashKing => '加入 ClashKing';

  @override
  String get authCreateClashKingAccount => '创建 ClashKing 账户';

  @override
  String get authCreateAccountToGetStarted => '创建您的账户以开始';

  @override
  String get authAlreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get authConfirmLogout => '确定要退出登录吗？';

  @override
  String get authDiscordTitle => 'Discord';

  @override
  String get authDiscordSignIn => '使用Discord登录';

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
  String get authUsernameLabel => '用户名';

  @override
  String get authUsernameRequired => '请输入用户名';

  @override
  String get authUsernameTooShort => 'Username must be at least 3 characters';

  @override
  String get authErrorConnection => '发生错误，请检查网络连接并重试。';

  @override
  String get authErrorConnectionRelaunch => '发生错误，请检查网络连接并重新启动应用。';

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
  String get accountsWelcome => '欢迎！';

  @override
  String get accountsWelcomeMessage => '请将一个或多个部落冲突帐户添加到您的个人资料中。您可以稍后添加或删除帐户。';

  @override
  String get accountsManageTitle => 'Manage your accounts';

  @override
  String get accountsNoneFound => '未找到与你的个人资料关联的账号';

  @override
  String get accountsPlayerTag => 'Player Tag (#ABC123)';

  @override
  String get accountsEnterPlayerTag => '输入一个玩家标签';

  @override
  String get accountsAdd => '添加账户';

  @override
  String get accountsDelete => '删除账户';

  @override
  String get accountsApiToken => '帐户 API 令牌';

  @override
  String get accountsEnterApiToken =>
      '请输入帐户API令牌以确认您的身份。您可以在部落冲突设置>更多设置>API令牌中找到它。';

  @override
  String get accountsFillAllFields => 'Please fill all fields.';

  @override
  String get accountsErrorTagNotExists => '输入的村庄标签不存在。';

  @override
  String accountsErrorAlreadyLinked(Object tag) {
    return '村庄标签已经链接到某人。';
  }

  @override
  String get accountsErrorAlreadyLinkedToYou => '您已连接玩家标签';

  @override
  String get accountsErrorWrongApiToken => '输入的 API 令牌不正确';

  @override
  String get accountsErrorFailedToAdd =>
      'Failed to add the account. Please try again later.';

  @override
  String get accountsErrorFailedToDelete => '删除链接失败。请稍后再试。';

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
  String get errorLoadingVersion => '加载版本时出错';

  @override
  String get errorCannotOpenLink => '我们无法打开此链接';

  @override
  String get errorExitAppToOpenClash => '您即将离开应用程序打开部落冲突';

  @override
  String get playerSearchTitle => '搜索玩家';

  @override
  String get playerSearchPlaceholder => '村庄名称或标签';

  @override
  String playerLastActive(String date) {
    return '上次活跃：$date';
  }

  @override
  String get playerNotTracked => '该玩家未被跟踪。数据可能不准确。';

  @override
  String playerClanDescription(String clan, String tag) {
    return '您的部落是“$clan”（$tag）';
  }

  @override
  String playerRatioDescription(
      String ratio, String donations, String received) {
    return '您的捐兵比例为$ratio。你们已经捐赠了$donations人口的部队，并接收了$received人口的部队。';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return '您的部落对战偏好是“$preference”。';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return '您拥有$stars胜利之星。';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return '您拥有$trophies奖杯。你目前在$league杯段。';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return '您的大本营等级是$level';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return '您的大本等级为$level，您的奖杯数为：$trophies。';
  }

  @override
  String get gameBaseHome => '家乡';

  @override
  String get gameBaseBuilder => '夜世界';

  @override
  String get gameClanCapital => '部落都城';

  @override
  String get gameTownHall => '大本等级';

  @override
  String get gameTownHallLevel => '大本等级';

  @override
  String gameTownHallLevelNumber(int level) {
    return '大本营 $level';
  }

  @override
  String gameTHLevel(int level) {
    return '$level级大本';
  }

  @override
  String get gameExpLevel => '经验等级';

  @override
  String get gameTrophies => '奖杯';

  @override
  String get gameBuilderBaseTrophies => '建筑大师奖杯';

  @override
  String get gameDonations => '增援';

  @override
  String get gameDonationsReceived => '收到的增援';

  @override
  String get gameDonationsRatio => '捐收比例';

  @override
  String gameLevel(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get gameHeroes => '英雄';

  @override
  String get gameEquipment => '装备';

  @override
  String get gameHeroesEquipments => '英雄装备';

  @override
  String get gameTroops => '部队';

  @override
  String get gameActiveSuperTroops => '已启用的超级部队';

  @override
  String get gamePets => '宠物';

  @override
  String get gameSiegeMachines => '攻城机器';

  @override
  String get gameSpells => '法术';

  @override
  String get gameAchievements => '成就';

  @override
  String get gameClanGames => 'Clan Games';

  @override
  String get gameSeasonPass => 'Season Pass';

  @override
  String get gameCreatorCode => '创作者代码：ClashKing';

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
  String get clanTitle => '部落';

  @override
  String get clanSearchTitle => '搜索部落';

  @override
  String get clanSearchPlaceholder => 'Clan\'s name';

  @override
  String get clanNone => '无部落信息';

  @override
  String get clanJoinToUnlock => '加入一个部落来解锁新功能。';

  @override
  String get clanMembers => '成员';

  @override
  String get clanWarFrequency => '对战频率';

  @override
  String get clanMinimumMembers => '最小成员数';

  @override
  String get clanMaximumMembers => '最大成员数';

  @override
  String get clanLocation => '位置';

  @override
  String get clanMinimumPoints => '最低部落奖杯总数';

  @override
  String get clanMinimumLevel => '最低部落等级';

  @override
  String get clanInviteOnly => '仅限邀请';

  @override
  String get clanOpened => '开放';

  @override
  String get clanClosed => '已关闭';

  @override
  String get clanRoleLeader => '首领';

  @override
  String get clanRoleCoLeader => '副首领';

  @override
  String get clanRoleElder => '长老';

  @override
  String get clanRoleMember => '成员';

  @override
  String get clanWarFrequencyAlways => '总是';

  @override
  String get clanWarFrequencyNever => '从不';

  @override
  String get clanWarFrequencyUnknown => '未知';

  @override
  String get clanWarFrequencyOncePerWeek => '1次/周';

  @override
  String get clanWarFrequencyMoreThanOncePerWeek => 'More than 1/week';

  @override
  String get clanWarFrequencyRarely => '很少';

  @override
  String get timeHourIndicator => '小时';

  @override
  String timeDaysAgo(int days) {
    return '$days 天前';
  }

  @override
  String timeDayAgo(int day) {
    return '$day天之前';
  }

  @override
  String timeHourAgo(int hour) {
    return '$hour小时之前';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours 小时前';
  }

  @override
  String timeMinuteAgo(int minute) {
    return '$minute分钟之前';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes分钟之前';
  }

  @override
  String get timeJustNow => '刚刚';

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
    return '开始时间（$time后';
  }

  @override
  String timeStartsAt(String time) {
    return '开始时间（$time）';
  }

  @override
  String timeEndsIn(String time) {
    return '结束于$time';
  }

  @override
  String timeEndsAt(String time) {
    return '结束于$time';
  }

  @override
  String get legendsTitle => '数据不准确？';

  @override
  String get legendsNotInLeague => '不在传奇联赛中';

  @override
  String get legendsNoDataToday =>
      'You\'re not in Legend League, but past seasons are available.';

  @override
  String legendsStartDescription(String trophies) {
    return '您以$trophies奖杯开始了新的一天。';
  }

  @override
  String legendsNoRankLocalDescription(String country, int trophies) {
    return '您目前没有获得$trophies奖杯的排名（$country）。';
  }

  @override
  String legendsRankLocalDescription(int rank, String country, int trophies) {
    return '您目前拥有$trophies奖杯，排名$rank（$country）。';
  }

  @override
  String legendsGainDescription(int trophies) {
    return '您获得了$trophies奖杯。';
  }

  @override
  String legendsLossDescription(int trophies) {
    return '您失去了$trophies奖杯。';
  }

  @override
  String legendsNoGlobalRankDescription(int trophies) {
    return '您目前没有在全国范围内获得排名（$trophies）。';
  }

  @override
  String legendsGlobalRankDescription(int rank, int trophies) {
    return 'You are currently ranked $rank globally with $trophies trophies.';
  }

  @override
  String get legendsNoRank => '暂无排名';

  @override
  String get legendsBestTrophies => '最高奖杯';

  @override
  String get legendsMostAttacks => '最多进攻次数';

  @override
  String get legendsLastSeason => '上一赛季';

  @override
  String get legendsBestRank => '最佳全球等级';

  @override
  String get legendsTrophiesBySeason => '每赛季的奖杯数';

  @override
  String get legendsEosTrophies => '赛季结束前的奖杯数';

  @override
  String get legendsEosDetails => 'End Of Season Details';

  @override
  String get legendsInaccurateTitle => '数据不准确？';

  @override
  String get legendsInaccurateIntro =>
      '由于Clans API分类的限制，我们的数据可能并不总是完全准确。可能有以下原因：';

  @override
  String get legendsInaccurateApiDelayTitle => '1. API 延迟： ';

  @override
  String get legendsInaccurateApiDelayBody =>
      'API可能需要长达5分钟的时间进行更新，从而导致反映实时奖杯变化的滞后。';

  @override
  String get legendsInaccurateConcurrentTitle => '2.合并奖杯：';

  @override
  String get legendsInaccurateMultipleAttacksTitle => '- 多次攻击/防御： ';

  @override
  String get legendsInaccurateMultipleAttacksBody =>
      '如果连续发生多次攻击或防御，API可能会显示合并结果(如+68 或 -68)。\n';

  @override
  String get legendsInaccurateSimultaneousTitle => '- 同时攻击和防御： ';

  @override
  String get legendsInaccurateSimultaneousBody =>
      '如果同时发生攻击和防御，你可能会看到好坏参半的结果(例如+4。\n';

  @override
  String get legendsInaccurateNetGainTitle => '3. 净增益： ';

  @override
  String get legendsInaccurateNetGainBody => '尽管时间安排有问题，但这一天的净损益总额是准确的。 ';

  @override
  String get legendsInaccurateConclusion =>
      '这些限制在使用部落冲突API的所有工具上都很常见。遗憾的是，我们无法修复这个问题，因为它的所有权是在Supercell的手中。 我们尽最大努力弥补这些限制，提供尽可能接近现实的结果。谢谢你们的理解！';

  @override
  String get statsSeasonStats => '赛季数据';

  @override
  String get statsByDay => '按天';

  @override
  String get statsBySeason => '按赛季';

  @override
  String statsDayIndex(int index) {
    return '第$index天';
  }

  @override
  String statsIndexDays(int index) {
    return '$index天';
  }

  @override
  String statsSeasonDate(String date) {
    return '$date赛季';
  }

  @override
  String get statsAllTownHalls => '所有大本营';

  @override
  String get statsMembers => '成员统计';

  @override
  String get todoTitle => '待办事宜列表';

  @override
  String get todoExplanationTitle => '任务计算方法';

  @override
  String get todoExplanationIntro => '任务完成率是根据下列具有特定权重的活动计算出来的：';

  @override
  String get todoExplanationLegendsTitle => '传奇联赛';

  @override
  String get todoExplanationLegends => '每个账户的权重为8分，1次攻击=1分。';

  @override
  String get todoExplanationRaidsTitle => '突袭：';

  @override
  String get todoExplanationRaids => '每个账户的权重为5分（如果上次攻击已解锁，则为6分），1次攻击=1分。';

  @override
  String get todoExplanationClanWarsTitle => '部落战：';

  @override
  String get todoExplanationClanWars => '每个账户2分的权重，1次攻击=1分。';

  @override
  String get todoExplanationCwlTitle => '部落联赛';

  @override
  String get todoExplanationCwl => '每个账户的权重为1分，1次攻击=1分。如果玩家不在他们的部落中，则无法跟踪部落联赛。';

  @override
  String get todoExplanationPassAndGamesTitle => '月卡和部落游戏';

  @override
  String get todoExplanationPassAndGames =>
      '每个账户的权重为2分。该比率基于剩余天数（通行证为1个月，比赛为6天）。绿色=按计划完成传球或比赛，红色=落后于计划。';

  @override
  String get todoExplanationConclusion =>
      '最终百分比是通过将正在进行的事件中完成的总操作除以所需的总操作来计算的。超过14天未活动的帐户不在计算范围内。';

  @override
  String todoAccountsNumber(int number) {
    return '$number账户';
  }

  @override
  String todoAccountsNumberActive(int number) {
    return '$number活账户';
  }

  @override
  String todoAccountsNumberInactive(int number) {
    return '$number不活跃账户';
  }

  @override
  String get todoAccountsActive => '活跃帐户';

  @override
  String get todoAccountsInactive => '不活跃账户';

  @override
  String get todoAccountsNoInactive => '没有不活跃的帐户。';

  @override
  String get todoAccountsNoActive => '没有活跃的帐户。';

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
  String get warTitle => '部落战';

  @override
  String get warFrequency => '对战频率';

  @override
  String get warParticipation => '参战';

  @override
  String get warLeague => '部落战/联赛';

  @override
  String get warHistory => '部落对战历史';

  @override
  String get warLog => '对战日志';

  @override
  String warLogClosed(String clan) {
    return '对战日志已关闭。';
  }

  @override
  String get warStats => '部落战统计';

  @override
  String get warOngoing => '正在进行的部落战';

  @override
  String warIsNotInWar(String clan) {
    return '$clan 当前未参与部落战。';
  }

  @override
  String get warAskForWar => '请联系首领或副首领发起一场部落战。';

  @override
  String get warAskForWarLogOpening => '请联系首领或副首领开启对战日志。';

  @override
  String get warEnded => '部落战已结束';

  @override
  String get warPreparation => '准备阶段';

  @override
  String get warPerfectWar => '满星部落战';

  @override
  String get warVictory => '胜利';

  @override
  String get warDefeat => '失败';

  @override
  String get warDraw => '平局';

  @override
  String get warTeamSize => '队伍规模';

  @override
  String get warMyTeam => '我的部落';

  @override
  String get warEnemiesTeam => '敌方部落';

  @override
  String get warClanDraw => '双方部落战成平局';

  @override
  String get warStateOfTheWar => '部落战状态';

  @override
  String warStarsNeededToTakeTheLead(
      String clan, int star, int stars2, String percent) {
    return '$clan 仍需 $star 颗星，或 $stars2 颗星加上 $percent% 的摧毁率才能取得领先';
  }

  @override
  String warStarsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan 仍需 $percent% 或再获得 1 颗星才能取得领先';
  }

  @override
  String get warNoDataAvailableForThisWar => '此场部落战暂无数据';

  @override
  String get warCalculatorFast => '快速计算';

  @override
  String warCalculatorAnswer(String percentNeeded, String result) {
    return '要达到 $percentNeeded% 的摧毁率，总共需要 $result%。';
  }

  @override
  String get warCalculatorNeededOverall => '所需总百分比';

  @override
  String get warCalculatorCalculate => '计算';

  @override
  String get warAttacksTitle => '进攻记录';

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
  String get warDefensesTitle => '防御记录';

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
  String get warStarsTitle => '星数';

  @override
  String get warStarsAverage => '平均胜利之星';

  @override
  String get warStarsNumber => '获得的星数';

  @override
  String get warStarsOne => '1 胜利之星';

  @override
  String get warStarsTwo => '2 胜利之星';

  @override
  String get warStarsThree => '3 胜利之星';

  @override
  String get warStarsZero => '0 Star';

  @override
  String get warStarsBestPerformance => 'Best performance';

  @override
  String get warDestructionTitle => 'Destruction';

  @override
  String get warDestructionAverage => '平均摧毁';

  @override
  String get warDestructionRate => '摧毁率';

  @override
  String warHistoryWinsDescription(int wins, String percent) {
    return '在过去50场部落战中，您的部落赢得$wins场($percent%)';
  }

  @override
  String warHistoryLossesDescription(int losses, String percent) {
    return '在过去的50 场部落战中，您的部落失败$losses场($percent%)';
  }

  @override
  String warHistoryDrawsDescription(int draws, String percent) {
    return '在过去50场部落战中，您的部落平局$draws场($percent%)';
  }

  @override
  String warHistoryAverageMembersDescription(int members) {
    return '在过去50场部落战中，您的部落平均有$members人参战';
  }

  @override
  String warHistoryAverageWarStarsDescription(double stars, String percent) {
    return '在过去 50 场战争中，您的部落平均每场战争获得 $stars 颗星星，占比 $percent';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return '您的部落在过去 50 场战争中的平均摧毁率为 $percent%';
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
  String get warOpponentEqualThLevel => '大本等级相同';

  @override
  String get warOpponentSelectMembersThLevel => '成员大本等级';

  @override
  String get warOpponentSelectOpponentsThLevel => '队友大本等级';

  @override
  String warFiltersLastXwars(int number) {
    return '最后$number场战争';
  }

  @override
  String get warFiltersFriendly => '友好';

  @override
  String get warFiltersRandom => '随机';

  @override
  String get warVisibilityToggleTownHall => '显示/隐藏前大本等级统计';

  @override
  String get warEventsTitle => '事件';

  @override
  String get warEventsNewest => '最新';

  @override
  String get warEventsOldest => '最早';

  @override
  String get warStatusReady => '参战';

  @override
  String get warStatusUnready => '退出';

  @override
  String get warStatusMissed => 'Missed';

  @override
  String get warAbbreviationAvg => 'Avg';

  @override
  String get warAbbreviationAvgPercentage => 'Avg %';

  @override
  String get cwlTitle => '部落联赛';

  @override
  String get cwlClanWarLeague => '部落战联赛';

  @override
  String get cwlOngoing => '正在进行的部落联赛';

  @override
  String get cwlRounds => '轮次';

  @override
  String cwlRoundNumber(int number) {
    return 'Round $number';
  }

  @override
  String cwlCurrentRound(int round) {
    return '当前是第 $round 轮。';
  }

  @override
  String cwlRank(int rank) {
    return '你的部落当前排名第 $rank。';
  }

  @override
  String cwlStars(int stars) {
    return '你的部落共获得 $stars 颗星。';
  }

  @override
  String cwlDestructionPercentage(String percent) {
    return '你的部落的总摧毁率为 $percent%。';
  }

  @override
  String cwlTotalAttacks(int attacks, int totalAttacks) {
    return 'Your clan has a total of $attacks attacks out of $totalAttacks possible attacks.';
  }

  @override
  String get joinLeaveTitle => 'Join/Leave Logs (Current Season)';

  @override
  String get joinLeaveJoin => '加入';

  @override
  String get joinLeaveLeave => '退出';

  @override
  String get joinLeaveReset => '重置';

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
    return '于 $date 的 $time 离开。';
  }

  @override
  String joinLeaveJoinedOnAt(String date, String time) {
    return '于 $date 的 $time 加入。';
  }

  @override
  String get raidsTitle => 'Raids';

  @override
  String get raidsLast => '历史突袭记录';

  @override
  String get raidsOngoing => '进行中的突袭';

  @override
  String get raidsDistrictsDestroyed => '摧毁的都城';

  @override
  String get raidsCompleted => '已完成突袭';

  @override
  String get searchNoResult => '没有找到该查询的结果';

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
  String get dashboardTitle => '主页';

  @override
  String get toolsTitle => '工具';

  @override
  String get navigationTeam => '部落';

  @override
  String get navigationStatistics => '统计数据';

  @override
  String get versionDevice => '版本&设备';

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
  String get betaFeature => 'Beta功能';

  @override
  String get betaLabel => 'BETA';

  @override
  String get betaDescription =>
      '此功能目前处于测试阶段，可能存在一些错误或不完整。我们正在积极改进，欢迎您的反馈。请在我们的Discord服务器中分享您的想法并报告任何问题，以帮助我们做得更好。';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsSelectLanguage => '搜索语言';

  @override
  String get settingsToggleTheme => '切换主题';

  @override
  String get faqTitle => 'FAQ';

  @override
  String get faqSubtitle => '常见问题回答';

  @override
  String get faqIsThisFromSupercell => '这个应用程序是Supercell的吗？';

  @override
  String get faqFanContentPolicy =>
      '此材料是非官方的，未得到Supercell的认可。有关更多信息，请参阅Supercell的粉丝内容政策：www.Supercell.com/Fan-Content-Policy';

  @override
  String get faqWhyNotAccurate => '为什么数据有时不准确或缺失？';

  @override
  String get faqClanNotTracked => '部落未被追踪';

  @override
  String get faqClanNotTrackedAnswer =>
      '只有当部落被追踪时，ClashKing才能检索此信息。如果你的部落没有被追踪，请邀请ClashKing机器人到你的Discord服务器，并使用命令/addclan。我们正在努力尽快在应用程序中提供此功能。';

  @override
  String get faqTrackingDown => '跟踪';

  @override
  String get faqTrackingDownAnswer =>
      '跟踪可以在一段时间内停止工作。这就是为什么你的数据有时会有漏洞。我们正在努力改进这一点。';

  @override
  String get faqApiLimitation => '部落冲突API限制';

  @override
  String get faqApiLimitationAnswer =>
      '一些数据是由部落冲突提供的，他们的API有一些限制。传奇杯追踪就是这种情况，它有时会像一次攻击一样叠加奖杯的得失。这也是为什么我们没有关于您基地的任何信息。';

  @override
  String get faqSupportWork => '我如何支持你的工作？';

  @override
  String get faqSupportWorkAnswer => '有几种方法可以支持我们：';

  @override
  String get faqUseCodeClashKing => '使用创作者代码“ClashKing”';

  @override
  String get faqSupportUsOnPatreon => '在Patreon上支持我们';

  @override
  String get faqShareTheApp => '与朋友分享应用程序';

  @override
  String get faqRateTheApp => '对商店中的应用程序进行评分';

  @override
  String get faqHelpUsTranslate => '帮助我们翻译应用程序';

  @override
  String get faqHowToInviteTheBot => '我如何邀请您的机器人加入我的Discord服务器？';

  @override
  String get faqHowToInviteTheBotAnswer =>
      '您可以通过单击下面的按钮邀请我们的机器人到您的服务器。您需要“管理服务器”权限才能添加机器人。';

  @override
  String get faqInviteTheBot => '邀请ClashKing机器人';

  @override
  String get faqNeedHelp => '我需要帮助，或者我想提个建议。我怎样才能联系到你？';

  @override
  String get faqNeedHelpAnswer =>
      '您可以加入我们的Discord服务器以寻求帮助或提供反馈，也可以发送电子邮件至devs@clashk.ing.请用英语或法语书写。';

  @override
  String get faqSendEmail => '发送电子邮件';

  @override
  String get faqJoinDiscord => '加入我们的Discord服务器';

  @override
  String get faqCannotOpenMailClient =>
      '由于某些原因，我们无法打开您的邮件客户端。我们为您复制了电子邮件地址。您可以编写电子邮件并将地址粘贴到收件人字段中。';

  @override
  String get translationHelpUsTranslate => '帮助我们翻译';

  @override
  String get translationSuggestFeatures => '建议功能';

  @override
  String get translationThankYou => '感谢您！';

  @override
  String get translationThankYouContent =>
      '非常感谢我们所有出色的翻译人员，他们帮助我们让世界各地的更多人可以访问这个应用程序！';

  @override
  String get translationHelpTranslateContent =>
      '您可以在Crowdin上帮助我们翻译应用程序。如果您的语言在Crowdin上不可用，请随时在我们的Discord服务器上请求。非常感谢你的帮助！';

  @override
  String get translationHelpTranslateButton => '在Crowdin上帮助翻译';

  @override
  String get translationCurrentTranslators => '当前翻译员';
}
