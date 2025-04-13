// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get creatorCode => '创作者代码：ClashKing';

  @override
  String get errorTitle => 'Oops! Our servers might have taken a fireball to the face! We\'re casting a healing spell... Try again in a moment.';

  @override
  String get errorSubtitle => 'If the issue persists, check our Discord Server to see if we\'re aware of it.';

  @override
  String get retry => 'Retry';

  @override
  String get signInWithDiscord => '使用Discord登录';

  @override
  String get guestMode => '访客模式';

  @override
  String get needHelpJoinDiscord => '需要帮助？请加入我们的Discord频道。';

  @override
  String get loginError => 'An error occurred while logging in. Please try again later.';

  @override
  String get createGuestProfile => '创建您的访客形象';

  @override
  String doesNotExist(String tag) {
    return '$tag不存在。';
  }

  @override
  String isAlreadyLinked(String tag) {
    return '$tag此标签已被绑定。';
  }

  @override
  String get username => '用户名';

  @override
  String get pleaseEnterUsername => '请输入用户名';

  @override
  String get playerTag => 'Player Tag (#ABC123)';

  @override
  String get playerTags => '玩家标签';

  @override
  String get linkedAccounts => 'Linked Accounts';

  @override
  String followingTagsDoNotExist(String tags) {
    return '以下标签不存在：$tags。';
  }

  @override
  String followingTagsAreAlreadyLinked(String tags) {
    return '以下标签已被绑定：$tags。';
  }

  @override
  String get welcome => '欢迎！';

  @override
  String get welcomeMessage => '请将一个或多个部落冲突帐户添加到您的个人资料中。您可以稍后添加或删除帐户。';

  @override
  String get login => '登录';

  @override
  String get logout => '注销';

  @override
  String get language => '语言';

  @override
  String get settings => '设置';

  @override
  String get toggleTheme => '切换主题';

  @override
  String get selectLanguage => '搜索语言';

  @override
  String get faq => 'FAQ';

  @override
  String get faqSubtitle => '常见问题回答';

  @override
  String get faqIsThisFromSupercell => '这个应用程序是Supercell的吗？';

  @override
  String get faqFanContentPolicy => '此材料是非官方的，未得到Supercell的认可。有关更多信息，请参阅Supercell的粉丝内容政策：www.Supercell.com/Fan-Content-Policy';

  @override
  String get faqWhyNotAccurate => '为什么数据有时不准确或缺失？';

  @override
  String get faqClanNotTracked => '部落未被追踪';

  @override
  String get faqClanNotTrackedAnswer => '只有当部落被追踪时，ClashKing才能检索此信息。如果你的部落没有被追踪，请邀请ClashKing机器人到你的Discord服务器，并使用命令/addclan。我们正在努力尽快在应用程序中提供此功能。';

  @override
  String get faqTrackingDown => '跟踪';

  @override
  String get faqTrackingDownAnswer => '跟踪可以在一段时间内停止工作。这就是为什么你的数据有时会有漏洞。我们正在努力改进这一点。';

  @override
  String get faqApiLimitation => '部落冲突API限制';

  @override
  String get faqApiLimitationAnswer => '一些数据是由部落冲突提供的，他们的API有一些限制。传奇杯追踪就是这种情况，它有时会像一次攻击一样叠加奖杯的得失。这也是为什么我们没有关于您基地的任何信息。';

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
  String get faqHowToInviteTheBotAnswer => '您可以通过单击下面的按钮邀请我们的机器人到您的服务器。您需要“管理服务器”权限才能添加机器人。';

  @override
  String get faqInviteTheBot => '邀请ClashKing机器人';

  @override
  String get faqNeedHelp => '我需要帮助，或者我想提个建议。我怎样才能联系到你？';

  @override
  String get faqNeedHelpAnswer => '您可以加入我们的Discord服务器以寻求帮助或提供反馈，也可以发送电子邮件至devs@clashkingbot.com.请用英语或法语书写。';

  @override
  String get faqSendEmail => '发送电子邮件';

  @override
  String get faqJoinDiscord => '加入我们的Discord服务器';

  @override
  String get faqCannotOpenMailClient => '由于某些原因，我们无法打开您的邮件客户端。我们为您复制了电子邮件地址。您可以编写电子邮件并将地址粘贴到收件人字段中。';

  @override
  String get helpUsTranslate => '帮助我们翻译';

  @override
  String get suggestFeatures => '建议功能';

  @override
  String get thankYou => '感谢您！';

  @override
  String get thankYouContent => '非常感谢我们所有出色的翻译人员，他们帮助我们让世界各地的更多人可以访问这个应用程序！';

  @override
  String get helpTranslateContent => '您可以在Crowdin上帮助我们翻译应用程序。如果您的语言在Crowdin上不可用，请随时在我们的Discord服务器上请求。非常感谢你的帮助！';

  @override
  String get helpTranslateButton => '在Crowdin上帮助翻译';

  @override
  String get versionDevice => '版本&设备';

  @override
  String get loading => '加载中...';

  @override
  String get errorLoadingVersion => '加载版本时出错';

  @override
  String get currentTranslators => '当前翻译员';

  @override
  String get betaFeature => 'Beta功能';

  @override
  String get beta => 'BETA';

  @override
  String get betaDescription => '此功能目前处于测试阶段，可能存在一些错误或不完整。我们正在积极改进，欢迎您的反馈。请在我们的Discord服务器中分享您的想法并报告任何问题，以帮助我们做得更好。';

  @override
  String get copiedToClipboard => '复制到剪贴板';

  @override
  String get all => '所有';

  @override
  String get hourIndicator => '小时';

  @override
  String get minIndicator => '分钟';

  @override
  String get noDataAvailable => '没有可用数据';

  @override
  String get close => '关闭';

  @override
  String get closed => '已关闭';

  @override
  String get error => '出错';

  @override
  String get player => '玩家';

  @override
  String notFoundOrNotLinkedToOurSystem(String player) {
    return '$player未被找到或未链接到我们的系统。';
  }

  @override
  String get tryAnotherNameOrTagOrLinkIt => '尝试其他名称/标签或链接它。';

  @override
  String get playerNotFound => '未找到玩家';

  @override
  String get noValueEntered => '未输入有效值';

  @override
  String get manage => '管理';

  @override
  String get enterPlayerTag => '输入一个玩家标签';

  @override
  String get add => '添加';

  @override
  String get delete => '删除';

  @override
  String get addAccount => '添加账户';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get playerTagNotExists => '输入的村庄标签不存在。';

  @override
  String accountAlreadyLinked(Object tag) {
    return '村庄标签已经链接到某人。';
  }

  @override
  String get enterApiToken => '请输入帐户API令牌以确认您的身份。您可以在部落冲突设置>更多设置>API令牌中找到它。';

  @override
  String get wrongApiToken => '输入的 API 令牌不正确';

  @override
  String get accountAlreadyLinkedToYou => '您已连接玩家标签';

  @override
  String get apiToken => '帐户 API 令牌';

  @override
  String get failedToAddTryAgain => '无法添加链接。请稍后再试。';

  @override
  String get fillAllFields => 'Please fill all fields.';

  @override
  String get failedToDeleteTryAgain => '删除链接失败。请稍后再试。';

  @override
  String get enterPlayerTagWarning => '您必须输入村庄标签，然后点击“+”继续。';

  @override
  String get failedToLoadAccountData => 'Failed to load accounts data.';

  @override
  String get loadAccountData => 'Load accounts data';

  @override
  String get search => '搜索';

  @override
  String get warning => '警告';

  @override
  String get exitAppToOpenClash => '您即将离开应用程序打开部落冲突';

  @override
  String get confirmLogout => '确定要退出登录吗？';

  @override
  String get tagOrNamePlayer => '村庄的标签或村庄名称';

  @override
  String get searchPlayer => '搜索玩家';

  @override
  String get nameOrTagPlayer => '村庄名称或标签';

  @override
  String playerClanDescription(String clan, String tag) {
    return '您的部落是“$clan”（$tag）';
  }

  @override
  String playerRatioDescription(String ratio, String donations, String received) {
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
  String get dashboard => '主页';

  @override
  String get homeBase => '家乡';

  @override
  String get th => '大本等级';

  @override
  String get builderBase => '夜世界';

  @override
  String get bh => '夜本等级';

  @override
  String get clanCapital => '部落都城';

  @override
  String get leader => '首领';

  @override
  String get coLeader => '副首领';

  @override
  String get elder => '长老';

  @override
  String get member => '成员';

  @override
  String get ready => '参战';

  @override
  String get unready => '退出';

  @override
  String level(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get heroes => '英雄';

  @override
  String get equipment => '装备';

  @override
  String get troops => '部队';

  @override
  String get superTroops => '超级部队';

  @override
  String get activeSuperTroops => '已启用的超级部队';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get pets => '宠物';

  @override
  String get siegeMachines => '攻城机器';

  @override
  String get spells => '法术';

  @override
  String get achievements => '成就';

  @override
  String get byDay => '按天';

  @override
  String get bySeason => '按赛季';

  @override
  String dayIndex(int index) {
    return 'Day $index';
  }

  @override
  String indexDays(int index) {
    return '$index days';
  }

  @override
  String get bestTrophies => '最高奖杯';

  @override
  String get mostAttacks => '最多进攻次数';

  @override
  String get lastSeason => '上一赛季';

  @override
  String get bestRank => '最佳全球等级';

  @override
  String daysLeft(int days) {
    return '$days days left';
  }

  @override
  String get date => '日期';

  @override
  String get stats => '统计数据';

  @override
  String get fullStats => 'Full Stats';

  @override
  String get details => '详细信息';

  @override
  String get seasonStats => '赛季数据';

  @override
  String get charts => '统计图';

  @override
  String get history => '历史记录';

  @override
  String get legendLeague => '传奇联赛';

  @override
  String get notInLegendLeague => '不在传奇联赛中';

  @override
  String get noLegendsDataToday => 'You\'re not in Legend League, but past seasons are available.';

  @override
  String legendStartDescription(String trophies) {
    return '您以$trophies奖杯开始了新的一天。';
  }

  @override
  String legendNoRankLocalDescription(String country, int trophies) {
    return '您目前没有获得$trophies奖杯的排名（$country）。';
  }

  @override
  String legendRankLocalDescription(Object country, Object rank, Object trophies) {
    return '您目前拥有$trophies奖杯，排名$rank（$country）。';
  }

  @override
  String legendGainDescription(int trophies) {
    return '您获得了$trophies奖杯。';
  }

  @override
  String legendLossDescription(int trophies) {
    return '您失去了$trophies奖杯。';
  }

  @override
  String legendNoGlobalRankDescription(int trophies) {
    return '您目前没有在全国范围内获得排名（$trophies）。';
  }

  @override
  String legendGlobalRankDescription(int rank, Object trophies) {
    return '您目前在全球排名$rank。';
  }

  @override
  String get noRank => '暂无排名';

  @override
  String get started => '已激活';

  @override
  String get ended => '已结束';

  @override
  String get average => '平均水平';

  @override
  String get remaining => '剩余时间';

  @override
  String get legendsTitle => '数据不准确？';

  @override
  String get legendsExplanation_intro => '由于Clans API分类的限制，我们的数据可能并不总是完全准确。可能有以下原因：';

  @override
  String get legendsExplanation_api_delay_title => '1. API 延迟： ';

  @override
  String get legendsExplanation_api_delay_body => 'API可能需要长达5分钟的时间进行更新，从而导致反映实时奖杯变化的滞后。';

  @override
  String get legendsExplanation_concurrent_changes_title => '2.合并奖杯：';

  @override
  String get legendsExplanation_multiple_attacks_defenses_title => '- 多次攻击/防御： ';

  @override
  String get legendsExplanation_multiple_attacks_defenses_body => '如果连续发生多次攻击或防御，API可能会显示合并结果(如+68 或 -68)。\n';

  @override
  String get legendsExplanation_simultaneous_attack_defense_title => '- 同时攻击和防御： ';

  @override
  String get legendsExplanation_simultaneous_attack_defense_body => '如果同时发生攻击和防御，你可能会看到好坏参半的结果(例如+4。\n';

  @override
  String get legendsExplanation_net_gain_loss_title => '3. 净增益： ';

  @override
  String get legendsExplanation_net_gain_loss_body => '尽管时间安排有问题，但这一天的净损益总额是准确的。 ';

  @override
  String get legendsExplanation_conclusion => '这些限制在使用部落冲突API的所有工具上都很常见。遗憾的是，我们无法修复这个问题，因为它的所有权是在Supercell的手中。 我们尽最大努力弥补这些限制，提供尽可能接近现实的结果。谢谢你们的理解！';

  @override
  String get toDoList => '待办事宜列表';

  @override
  String lastActive(String date) {
    return '上次活跃：$date';
  }

  @override
  String get playerNotTracked => '该玩家未被跟踪。数据可能不准确。';

  @override
  String numberAccounts(int number) {
    return '$number账户';
  }

  @override
  String numberActiveAccounts(int number) {
    return '$number活账户';
  }

  @override
  String numberInactiveAccounts(int number) {
    return '$number不活跃账户';
  }

  @override
  String get activeAccounts => '活跃帐户';

  @override
  String get inactiveAccounts => '不活跃账户';

  @override
  String get noInactiveAccounts => '没有不活跃的帐户。';

  @override
  String get noActiveAccounts => '没有活跃的帐户。';

  @override
  String get todoExplanation_title => '任务计算方法';

  @override
  String get todoExplanation_intro => '任务完成率是根据下列具有特定权重的活动计算出来的：';

  @override
  String get todoExplanation_legends_title => '传奇联赛';

  @override
  String get todoExplanation_legends => '每个账户的权重为8分，1次攻击=1分。';

  @override
  String get todoExplanation_raids_title => '突袭：';

  @override
  String get todoExplanation_raids => '每个账户的权重为5分（如果上次攻击已解锁，则为6分），1次攻击=1分。';

  @override
  String get todoExplanation_clanWars_title => '部落战：';

  @override
  String get todoExplanation_clanWars => '每个账户2分的权重，1次攻击=1分。';

  @override
  String get todoExplanation_cwl_title => '部落联赛';

  @override
  String get todoExplanation_cwl => '每个账户的权重为1分，1次攻击=1分。如果玩家不在他们的部落中，则无法跟踪部落联赛。';

  @override
  String get todoExplanation_passAndGames_title => '月卡和部落游戏';

  @override
  String get todoExplanation_passAndGames => '每个账户的权重为2分。该比率基于剩余天数（通行证为1个月，比赛为6天）。绿色=按计划完成传球或比赛，红色=落后于计划。';

  @override
  String get todoExplanation_conclusion => '最终百分比是通过将正在进行的事件中完成的总操作除以所需的总操作来计算的。超过14天未活动的帐户不在计算范围内。';

  @override
  String get worst => '最差';

  @override
  String get best => '最佳';

  @override
  String get total => '总计';

  @override
  String get heroesEquipments => '英雄装备';

  @override
  String daysAgo(int days) {
    return '$days 天前';
  }

  @override
  String dayAgo(int day) {
    return '$day天之前';
  }

  @override
  String hourAgo(int hour) {
    return '$hour小时之前';
  }

  @override
  String hoursAgo(int hours, Object Hours) {
    return '$Hours 小时前';
  }

  @override
  String minuteAgo(int minute) {
    return '$minute分钟之前';
  }

  @override
  String minutesAgo(int minutes) {
    return '$minutes分钟之前';
  }

  @override
  String secondAgo(int seconds) {
    return '$seconds秒之前';
  }

  @override
  String get justNow => '刚刚';

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
  String get trophiesByMonth => '每月奖杯';

  @override
  String get trophiesBySeason => '每赛季的奖杯数';

  @override
  String get eosTrophies => '赛季结束前的奖杯数';

  @override
  String get eosDetails => 'End Of Season Details';

  @override
  String get searchClan => '搜索部落';

  @override
  String get clanName => 'Clan\'s name';

  @override
  String get nameOrTagClan => '村庄名称或标签';

  @override
  String get noResult => '没有找到该查询的结果';

  @override
  String get filters => '筛选器';

  @override
  String get whatever => '任何';

  @override
  String get any => '任何 ';

  @override
  String get notSet => '未设置';

  @override
  String get warFrequency => '对战频率';

  @override
  String get minimumMembers => '最小成员数';

  @override
  String get maximumMembers => '最大成员数';

  @override
  String get location => '位置';

  @override
  String get minimumClanPoints => '最低部落奖杯总数';

  @override
  String get minimumClanLevel => '最低部落等级';

  @override
  String get noClan => '无部落信息';

  @override
  String get joinClanToUnlockNewFeatures => '加入一个部落来解锁新功能。';

  @override
  String get apply => '需要申请';

  @override
  String get opened => '开放';

  @override
  String get inviteOnly => '仅限邀请';

  @override
  String get cancel => '取消';

  @override
  String get clan => '部落';

  @override
  String get clans => '部落';

  @override
  String get members => '成员';

  @override
  String get role => '职位';

  @override
  String get expLevel => '经验等级';

  @override
  String get townHallLevel => '大本等级';

  @override
  String thLevel(int level) {
    return '$level级大本';
  }

  @override
  String bhLevel(int level) {
    return '$level级夜本';
  }

  @override
  String townHallLevelLevel(int level) {
    return '大本营 $level';
  }

  @override
  String get byNumberOfWars => '按进攻次数排序';

  @override
  String get ok => '确定';

  @override
  String get byDateRange => '按日期范围';

  @override
  String get selectSeason => '选择一个赛季';

  @override
  String get year => '年';

  @override
  String get month => '月';

  @override
  String get allTownHalls => '所有大本营';

  @override
  String seasonDate(String date) {
    return '$date赛季';
  }

  @override
  String lastXwars(int number) {
    return '最后$number场战争';
  }

  @override
  String get friendly => '友好';

  @override
  String get cwl => '部落联赛';

  @override
  String get random => '随机';

  @override
  String get selectMembersThLevel => '成员大本等级';

  @override
  String get selectOpponentsThLevel => '队友大本等级';

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
  String get warParticipation => 'War Participation';

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
    return '$number player(s) are still in the clan.';
  }

  @override
  String leftClanNumberDescription(int number) {
    return '$number player(s) left the clan.';
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
  String bestDefenseOutOf(int number) {
    return 'Best defense (out of $number)';
  }

  @override
  String get attack => 'Attack';

  @override
  String get attacks => 'Attacks';

  @override
  String get noAttackYet => 'No attack yet';

  @override
  String get noDefenseYet => 'No defense yet';

  @override
  String get victory => 'Victory';

  @override
  String get defeat => 'Defeat';

  @override
  String get draw => 'Draw';

  @override
  String get perfectWar => 'Perfect war';

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
  String get lastRaids => 'Last raids';

  @override
  String get ongoingRaids => 'Ongoing raids';

  @override
  String get districtsDestroyed => 'Districts destroyed';

  @override
  String get raidsCompleted => 'Raids completed';
}
