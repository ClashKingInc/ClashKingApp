// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get creatorCode => 'Creator Code: ClashKing';

  @override
  String get errorTitle => 'Oops! Our servers might have taken a fireball to the face! We\'re casting a healing spell... Try again in a moment.';

  @override
  String get errorSubtitle => 'If the issue persists, check our Discord Server to see if we\'re aware of it.';

  @override
  String get retry => 'Retry';

  @override
  String get signInWithDiscord => 'Sign In with Discord';

  @override
  String get guestMode => 'Guest Mode';

  @override
  String get needHelpJoinDiscord => 'Need help? Join us on Discord.';

  @override
  String get loginError => 'An error occurred while logging in. Please try again later.';

  @override
  String get createGuestProfile => 'Create your guest profile';

  @override
  String doesNotExist(String tag) {
    return '$tag does not exist.';
  }

  @override
  String isAlreadyLinked(String tag) {
    return '$tag is already linked to someone.';
  }

  @override
  String get username => 'Username';

  @override
  String get pleaseEnterUsername => 'Please enter a username';

  @override
  String get playerTag => 'Player Tag (#ABC123)';

  @override
  String get playerTags => 'Player Tags';

  @override
  String get linkedAccounts => 'Linked Accounts';

  @override
  String followingTagsDoNotExist(String tags) {
    return 'The following tags do not exist: $tags.';
  }

  @override
  String followingTagsAreAlreadyLinked(String tags) {
    return 'The following tags are already linked to someone: $tags.';
  }

  @override
  String get welcome => 'Welcome!';

  @override
  String get welcomeMessage => 'Please add one or more Clash of Clans accounts to your profile. You can add or remove accounts later.';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Log out';

  @override
  String get language => 'Language';

  @override
  String get settings => 'Settings';

  @override
  String get toggleTheme => 'Toggle Theme';

  @override
  String get selectLanguage => 'Select a language';

  @override
  String get faq => 'FAQ';

  @override
  String get faqSubtitle => 'Frequently Asked Questions';

  @override
  String get faqIsThisFromSupercell => 'Is this App from Supercell?';

  @override
  String get faqFanContentPolicy => 'This material is unofficial and is not endorsed by Supercell. For more information see Supercell\'s Fan Content Policy: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate => 'Why is the data sometimes inaccurate or missing?';

  @override
  String get faqClanNotTracked => 'Clan not tracked';

  @override
  String get faqClanNotTrackedAnswer => 'ClashKing can only retrieve this info if the clan is tracked. If your clan isn\'t tracked, please invite the ClashKing Bot to your Discord Server and use the command /addclan. We are working on making this feature available in the app soon.';

  @override
  String get faqTrackingDown => 'Tracking down';

  @override
  String get faqTrackingDownAnswer => 'The tracking can stop working for a certain period of time. This is why you can sometimes have holes in your data. We are working on improving this.';

  @override
  String get faqApiLimitation => 'Clash of Clans API limitation';

  @override
  String get faqApiLimitationAnswer => 'Some data is provided by Clash of Clans and their API have some limitations. This is the case for legends tracking, it sometimes stacks the trophy gain and loss as if it was a single attack. This is also why we don\'t have any information on your building levels.';

  @override
  String get faqSupportWork => 'How can I support your work?';

  @override
  String get faqSupportWorkAnswer => 'There are several ways to support us:';

  @override
  String get faqUseCodeClashKing => 'Use code \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Support us on Patreon';

  @override
  String get faqShareTheApp => 'Share the app with your friends';

  @override
  String get faqRateTheApp => 'Rate the app in the store';

  @override
  String get faqHelpUsTranslate => 'Help us translate the app';

  @override
  String get faqHowToInviteTheBot => 'How can I invite your bot to my Discord Server?';

  @override
  String get faqHowToInviteTheBotAnswer => 'You can invite our bot to your server by clicking on the button below. You will need the \"Manage Server\" permission to add the bot.';

  @override
  String get faqInviteTheBot => 'Invite ClashKing Bot';

  @override
  String get faqNeedHelp => 'I need help or I would like to make a suggestion. How can I contact you?';

  @override
  String get faqNeedHelpAnswer => 'You can join our Discord Server to ask for help or to provide feedback, or you can email us at devs@clashkingbot.com. Please only write in English or French.';

  @override
  String get faqSendEmail => 'Send an email';

  @override
  String get faqJoinDiscord => 'Join our Discord Server';

  @override
  String get faqCannotOpenMailClient => 'For some reasons we can\'t open your mail client. We copied the email address for you. You can write an email and paste the address in the recipient field.';

  @override
  String get helpUsTranslate => 'Help us translate';

  @override
  String get suggestFeatures => 'Suggest features';

  @override
  String get thankYou => 'Thank you!';

  @override
  String get thankYouContent => 'A huge thank you to all our amazing translators who help us make this app accessible to more people around the world!';

  @override
  String get helpTranslateContent => 'You can help us translate the app on Crowdin. If your language is not available on Crowdin, feel free to request it in our Discord Server. Thank you so much for your help!';

  @override
  String get helpTranslateButton => 'Help Translate on Crowdin';

  @override
  String get versionDevice => 'Version & Device';

  @override
  String get loading => 'Loading...';

  @override
  String get errorLoadingVersion => 'Error loading version';

  @override
  String get currentTranslators => 'Current Translators';

  @override
  String get betaFeature => 'Beta Feature';

  @override
  String get beta => 'BETA';

  @override
  String get betaDescription => 'This feature is currently in beta, it may have some bugs or be incomplete. We are actively working on improvements and welcome your feedback. Please share your ideas and report any issues in our Discord Server to help us make it better.';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get all => 'All';

  @override
  String get hourIndicator => 'h';

  @override
  String get minIndicator => 'm';

  @override
  String get noDataAvailable => 'No data available.';

  @override
  String get close => 'Close';

  @override
  String get closed => 'Closed';

  @override
  String get error => 'Error';

  @override
  String get player => 'Player';

  @override
  String notFoundOrNotLinkedToOurSystem(String player) {
    return '$player not found or not linked to our system.';
  }

  @override
  String get tryAnotherNameOrTagOrLinkIt => 'Try another name/tag or link it.';

  @override
  String get playerNotFound => 'Player not found';

  @override
  String get noValueEntered => 'No value entered';

  @override
  String get manage => 'Manage';

  @override
  String get enterPlayerTag => 'Enter a player tag';

  @override
  String get add => 'Add';

  @override
  String get delete => 'Delete';

  @override
  String get addAccount => 'Add account';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get playerTagNotExists => 'The player tag entered does not exist.';

  @override
  String accountAlreadyLinked(Object tag) {
    return 'The player tag is already linked to someone.';
  }

  @override
  String get enterApiToken => 'Please enter the account API token to confirm it\'s yours. You can find it in Clash of Clans Settings > More Settings > API Token.';

  @override
  String get wrongApiToken => 'The API token entered is incorrect';

  @override
  String get accountAlreadyLinkedToYou => 'The player tag is already linked to you.';

  @override
  String get apiToken => 'Account API Token';

  @override
  String get failedToAddTryAgain => 'Failed to add link. Please try again later.';

  @override
  String get fillAllFields => 'Please fill all fields.';

  @override
  String get failedToDeleteTryAgain => 'Failed to delete link. Please try again later.';

  @override
  String get enterPlayerTagWarning => 'You must enter a player tag and click on the \"+\" to continue.';

  @override
  String get failedToLoadAccountData => 'Failed to load accounts data.';

  @override
  String get loadAccountData => 'Load accounts data';

  @override
  String get search => 'Search';

  @override
  String get warning => 'Warning';

  @override
  String get exitAppToOpenClash => 'You are about to leave the app to open Clash of Clans.';

  @override
  String get confirmLogout => 'Are you sure you want to log out?';

  @override
  String get tagOrNamePlayer => 'Player\'s tag or name';

  @override
  String get searchPlayer => 'Search player';

  @override
  String get nameOrTagPlayer => 'Player\'s name or tag';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Your clan is \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(String ratio, String donations, String received) {
    return 'Your donation ratio is $ratio. You have donated $donations troops and received $received troops.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Your war preference is \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'You have $stars war stars.';
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
  String get dashboard => 'Dashboard';

  @override
  String get homeBase => 'Home Base';

  @override
  String get th => 'TH';

  @override
  String get builderBase => 'Builder Base';

  @override
  String get bh => 'BH';

  @override
  String get clanCapital => 'Clan Capital';

  @override
  String get leader => 'Leader';

  @override
  String get coLeader => 'Co-Leader';

  @override
  String get elder => 'Elder';

  @override
  String get member => 'Member';

  @override
  String get ready => 'Opted In';

  @override
  String get unready => 'Opted Out';

  @override
  String level(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get heroes => 'Heroes';

  @override
  String get equipment => 'Equipments';

  @override
  String get troops => 'Troops';

  @override
  String get superTroops => 'Super Troops';

  @override
  String get activeSuperTroops => 'Active Super Troops';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get pets => 'Pets';

  @override
  String get siegeMachines => 'Siege Machines';

  @override
  String get spells => 'Spells';

  @override
  String get achievements => 'Achievements';

  @override
  String get byDay => 'By Day';

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
  String get lastSeason => 'Last Season';

  @override
  String get bestRank => 'Best Global Rank';

  @override
  String daysLeft(int days) {
    return '$days days left';
  }

  @override
  String get date => 'Date';

  @override
  String get stats => 'Stats';

  @override
  String get fullStats => 'Full Stats';

  @override
  String get details => 'Details';

  @override
  String get seasonStats => 'Season Stats';

  @override
  String get charts => 'Charts';

  @override
  String get history => 'History';

  @override
  String get legendLeague => 'Legend League';

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
  String get noRank => 'No ranking';

  @override
  String get started => 'Started';

  @override
  String get ended => 'Ended';

  @override
  String get average => 'Average';

  @override
  String get remaining => 'Remaining';

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
  String get worst => 'Worst';

  @override
  String get best => 'Best';

  @override
  String get total => 'Total';

  @override
  String get heroesEquipments => 'Hero equipments';

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String dayAgo(int day) {
    return '$day day ago';
  }

  @override
  String hourAgo(int hour) {
    return '$hour hour ago';
  }

  @override
  String hoursAgo(int hours, Object Hours) {
    return '$hours hours ago';
  }

  @override
  String minuteAgo(int minute) {
    return '$minute minute ago';
  }

  @override
  String minutesAgo(int minutes) {
    return '$minutes minutes ago';
  }

  @override
  String secondAgo(int seconds) {
    return '${seconds}s ago';
  }

  @override
  String get justNow => 'Just Now';

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
  String get trophiesByMonth => 'Trophies by month';

  @override
  String get trophiesBySeason => 'Trophies by season';

  @override
  String get eosTrophies => 'End Of Season Trophies';

  @override
  String get eosDetails => 'End Of Season Details';

  @override
  String get searchClan => 'Search clan';

  @override
  String get clanName => 'Clan\'s name';

  @override
  String get nameOrTagClan => 'Clan\'s name or tag';

  @override
  String get noResult => 'No result.';

  @override
  String get filters => 'Filters';

  @override
  String get whatever => 'Whatever';

  @override
  String get any => 'Any';

  @override
  String get notSet => 'Not set';

  @override
  String get warFrequency => 'War frequency';

  @override
  String get minimumMembers => 'Minimum members';

  @override
  String get maximumMembers => 'Maximum members';

  @override
  String get location => 'Location';

  @override
  String get minimumClanPoints => 'Minimum clan points';

  @override
  String get minimumClanLevel => 'Minimum clan level';

  @override
  String get noClan => 'No clan';

  @override
  String get joinClanToUnlockNewFeatures => 'Join a clan to unlock new features.';

  @override
  String get apply => 'Apply';

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
