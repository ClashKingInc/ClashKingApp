// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appDescription =>
      'आंकड़ों को ट्रैक करने, क्लैन्स का प्रबंधन करने और प्रदर्शन का विश्लेषण करने के लिए आपका अंतिम Clash of Clans साथी।';

  @override
  String get generalLoading => 'लोड हो रहा है...';

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
  String get generalRetry => 'पुनः प्रयास करें';

  @override
  String get generalTryAgain => 'फिर से कोशिश करें';

  @override
  String get generalCancel => 'रद्द करना';

  @override
  String get generalOk => 'ठीक है';

  @override
  String get generalApply => 'आवेदन करना';

  @override
  String get generalConfirm => 'Confirm';

  @override
  String get generalManage => 'प्रबंधित करना';

  @override
  String get generalSettings => 'सेटिंग्स';

  @override
  String get generalCopiedToClipboard => 'क्लिपबोर्ड पर कॉपी किया गया';

  @override
  String get generalComingSoon => 'जल्द आ रहा है!';

  @override
  String generalLastRefresh(String time) {
    return 'Last refresh: $time';
  }

  @override
  String generalRefreshFailed(String error) {
    return 'Refresh failed: $error';
  }

  @override
  String get generalAll => 'सभी';

  @override
  String get generalTotal => 'कुल';

  @override
  String get generalBest => 'श्रेष्ठ';

  @override
  String get generalWorst => 'बहुत बुरा';

  @override
  String get generalAverage => 'औसत';

  @override
  String get generalRemaining => 'शेष  ';

  @override
  String get generalActive => 'Active';

  @override
  String get generalInactive => 'Inactive';

  @override
  String get generalStarted => 'शुरू कर दिया';

  @override
  String get generalEnded => 'समाप्त';

  @override
  String get generalRole => 'भूमिका';

  @override
  String get generalStats => 'आँकड़े';

  @override
  String get generalFullStats => 'Full Stats';

  @override
  String get generalDetails => 'विवरण';

  @override
  String get generalHistory => 'इतिहास';

  @override
  String get generalFilters => 'फिल्टर';

  @override
  String get generalNotSet => 'सेट नहीं';

  @override
  String get generalWarning => 'चेतावनी ';

  @override
  String get generalNoDataAvailable => 'कोई डेटा मौजूद नहीं ';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authLogin => 'लॉग इन करें';

  @override
  String get authLogout => 'लॉग आउट';

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
  String get authConfirmLogout => 'क्या आप लॉग आउट करना चाहते हैं?';

  @override
  String get authDiscordTitle => 'Discord';

  @override
  String get authDiscordSignIn => 'Discord के साथ साइन इन करें.';

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
  String get authUsernameLabel => 'उपयोगकर्ता नाम';

  @override
  String get authUsernameRequired => 'कृपया उपयोगकर्ता नाम दर्ज करें';

  @override
  String get authUsernameTooShort => 'Username must be at least 3 characters';

  @override
  String get authErrorConnection =>
      'एक त्रुटि हुई। कृपया अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get authErrorConnectionRelaunch =>
      'एक त्रुटि हुई। कृपया अपना इंटरनेट कनेक्शन जांचें और ऐप पुनः लॉन्च करें।';

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
  String get accountsWelcome => 'स्वागत!';

  @override
  String get accountsWelcomeMessage =>
      'कृपया अपनी प्रोफ़ाइल में एक या अधिक Clash of Clans खाते जोड़ें। आप बाद में खाते जोड़ या हटा सकते हैं।';

  @override
  String get accountsManageTitle => 'Manage your accounts';

  @override
  String get accountsNoneFound => 'आपकी प्रोफ़ाइल से जुड़ा कोई खाता नहीं मिला';

  @override
  String get accountsPlayerTag => 'Player Tag (#ABC123)';

  @override
  String get accountsEnterPlayerTag => 'खिलाड़ी टैग दर्ज करें';

  @override
  String get accountsAdd => 'खाता जोड़ें ';

  @override
  String get accountsDelete => 'खाता हटा दो ';

  @override
  String get accountsApiToken => 'खाता API टोकन';

  @override
  String get accountsEnterApiToken =>
      'कृपया अकाउंट API टोकन दर्ज करें ताकि पुष्टि हो सके कि यह आपका है। आप इसे क्लैश ऑफ़ क्लैंस सेटिंग्स > अधिक सेटिंग्स > API टोकन में पा सकते हैं।';

  @override
  String get accountsFillAllFields => 'Please fill all fields.';

  @override
  String get accountsErrorTagNotExists =>
      'प्रविष्ट किया गया खिलाड़ी टैग मौजूद नहीं है.';

  @override
  String accountsErrorAlreadyLinked(Object tag) {
    return 'खिलाड़ी टैग पहले से ही किसी से जुड़ा हुआ है।';
  }

  @override
  String get accountsErrorAlreadyLinkedToYou =>
      'खिलाड़ी टैग पहले से ही आपसे जुड़ा हुआ है.';

  @override
  String get accountsErrorWrongApiToken => 'दर्ज किया गया API टोकन ग़लत है';

  @override
  String get accountsErrorFailedToAdd =>
      'Failed to add the account. Please try again later.';

  @override
  String get accountsErrorFailedToDelete =>
      'लिंक हटाने में विफल। कृपया बाद में पुनः प्रयास करें।';

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
  String get errorLoadingVersion => 'संस्करण लोड करने में त्रुटि';

  @override
  String get errorCannotOpenLink => 'हम यह लिंक नहीं खोल सकते.';

  @override
  String get errorExitAppToOpenClash =>
      'आप क्लैश ऑफ क्लैंस खोलने के लिए ऐप छोड़ने वाले हैं।';

  @override
  String get playerSearchTitle => 'खिलाड़ी खोजें';

  @override
  String get playerSearchPlaceholder => 'खिलाड़ी का नाम या टैग';

  @override
  String playerLastActive(String date) {
    return 'अंतिम सक्रिय: $date';
  }

  @override
  String get playerNotTracked =>
      'इस खिलाड़ी को ट्रैक नहीं किया गया है। डेटा गलत हो सकता है।';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'आपका कबीला \"$clan\" ($tag) है.';
  }

  @override
  String playerRatioDescription(
      String ratio, String donations, String received) {
    return 'आपका दान अनुपात $received है। आपने $donations सैनिक दान किए हैं और $ratio सैनिक प्राप्त किए हैं।';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'आपकी युद्ध वरीयता \"$preference\" है.';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'आपके पास $stars युद्ध सितारे हैं।';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'आपके पास $trophies ट्रॉफियां हैं। आप वर्तमान में $league में हैं।';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'आपका टाउन हॉल स्तर $level है';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'आपका बिल्डर हॉल स्तर $level है और आपके पास $trophies ट्रॉफियां हैं।';
  }

  @override
  String get gameBaseHome => 'घर आधार';

  @override
  String get gameBaseBuilder => 'बिल्डर बेस';

  @override
  String get gameClanCapital => 'कबीले की राजधानी';

  @override
  String get gameTownHall => 'वां';

  @override
  String get gameTownHallLevel => 'TH स्तर';

  @override
  String gameTownHallLevelNumber(int level) {
    return 'टाउन हॉल $level';
  }

  @override
  String gameTHLevel(int level) {
    return 'TH$level';
  }

  @override
  String get gameExpLevel => 'अनुभव स्तर';

  @override
  String get gameTrophies => 'ट्राफी';

  @override
  String get gameBuilderBaseTrophies => 'बी बी ट्रॉफियां';

  @override
  String get gameDonations => 'दान';

  @override
  String get gameDonationsReceived => 'प्राप्त दान';

  @override
  String get gameDonationsRatio => 'दान अनुपात';

  @override
  String gameLevel(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get gameHeroes => 'नायकों';

  @override
  String get gameEquipment => 'उपकरणों';

  @override
  String get gameHeroesEquipments => 'हीरो उपकरण';

  @override
  String get gameTroops => 'सैनिकों';

  @override
  String get gameActiveSuperTroops => 'सक्रिय सुपर सैनिक';

  @override
  String get gamePets => 'पालतू जानवर';

  @override
  String get gameSiegeMachines => 'घेराबंदी मशीनें ';

  @override
  String get gameSpells => 'मंत्र';

  @override
  String get gameAchievements => 'उपलब्धियों ';

  @override
  String get gameClanGames => 'Clan Games';

  @override
  String get gameSeasonPass => 'Season Pass';

  @override
  String get gameCreatorCode => 'क्रिएटर कोड: ClashKing';

  @override
  String get clanTitle => 'कबेला';

  @override
  String get clanSearchTitle => 'कबीला खोजें';

  @override
  String get clanSearchPlaceholder => 'Clan\'s name';

  @override
  String get clanNone => 'कोई कबेला नहीं';

  @override
  String get clanJoinToUnlock =>
      'नई सुविधाओं को अनलॉक करने के लिए एक कबीले में शामिल हों।';

  @override
  String get clanMembers => 'सदस्यों';

  @override
  String get clanWarFrequency => 'युद्ध आवृत्ति';

  @override
  String get clanMinimumMembers => 'न्यूनतम सदस्य';

  @override
  String get clanMaximumMembers => 'अधिकतम सदस्य';

  @override
  String get clanLocation => 'जगह';

  @override
  String get clanMinimumPoints => 'न्यूनतम कबीले अंक';

  @override
  String get clanMinimumLevel => 'न्यूनतम कबीले स्तर';

  @override
  String get clanInviteOnly => 'केवल आमंत्रित';

  @override
  String get clanOpened => 'खोला गया';

  @override
  String get clanClosed => 'बंद किया हुआ';

  @override
  String get clanRoleLeader => 'नेता ';

  @override
  String get clanRoleCoLeader => 'सह-मुखिया';

  @override
  String get clanRoleElder => 'ज्येष्ठ';

  @override
  String get clanRoleMember => 'सदस्य';

  @override
  String get clanWarFrequencyAlways => 'हमेशा';

  @override
  String get clanWarFrequencyNever => 'कभी नहीं';

  @override
  String get clanWarFrequencyUnknown => 'अज्ञात';

  @override
  String get clanWarFrequencyOncePerWeek => '1/सप्ताह';

  @override
  String get clanWarFrequencyMoreThanOncePerWeek => 'More than 1/week';

  @override
  String get clanWarFrequencyRarely => 'कभी-कभार';

  @override
  String get timeHourIndicator => 'एच';

  @override
  String timeDaysAgo(int days) {
    return '$days दिन पहले';
  }

  @override
  String timeDayAgo(int day) {
    return '$day दिन पहले';
  }

  @override
  String timeHourAgo(int hour) {
    return '$hour घंटा पहले';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours घंटे पहले';
  }

  @override
  String timeMinuteAgo(int minute) {
    return '$minute मिनट पहले';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes मिनट पहले';
  }

  @override
  String get timeJustNow => 'बस अब';

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
    return '$time में शुरू होगा';
  }

  @override
  String timeStartsAt(String time) {
    return '$time पर शुरू होगा';
  }

  @override
  String timeEndsIn(String time) {
    return '$time में समाप्त होगा';
  }

  @override
  String timeEndsAt(String time) {
    return '$time पर समाप्त होगा';
  }

  @override
  String get legendsTitle => 'गलत डेटा?';

  @override
  String get legendsNotInLeague => 'लीजेंड लीग में नहीं ';

  @override
  String get legendsNoDataToday =>
      'You\'re not in Legend League, but past seasons are available.';

  @override
  String legendsStartDescription(String trophies) {
    return 'आपने दिन की शुरुआत $trophies ट्रॉफियों के साथ की।';
  }

  @override
  String legendsNoRankLocalDescription(String country, int trophies) {
    return 'आप वर्तमान में $trophies ट्रॉफियों के साथ ($country) रैंक पर नहीं हैं।';
  }

  @override
  String legendsRankLocalDescription(int rank, String country, int trophies) {
    return 'आप वर्तमान में $rank ($country) रैंक पर हैं और $trophies ट्रॉफियां हैं।';
  }

  @override
  String legendsGainDescription(int trophies) {
    return 'आपने अभी के लिए $trophies ट्रॉफियां हासिल की हैं।';
  }

  @override
  String legendsLossDescription(int trophies) {
    return 'आपने अभी के लिए $trophies ट्रॉफियां खो दी हैं।';
  }

  @override
  String legendsNoGlobalRankDescription(int trophies) {
    return 'वर्तमान में आप $trophies ट्रॉफियों के साथ वैश्विक स्तर पर रैंक नहीं किए गए हैं।';
  }

  @override
  String legendsGlobalRankDescription(int rank, int trophies) {
    return 'You are currently ranked $rank globally with $trophies trophies.';
  }

  @override
  String get legendsNoRank => 'कोई रैंकिंग नहीं';

  @override
  String get legendsBestTrophies => 'सर्वश्रेष्ठ ट्रॉफियां';

  @override
  String get legendsMostAttacks => 'सर्वाधिक हमले';

  @override
  String get legendsLastSeason => 'पिछला सीज़न';

  @override
  String get legendsBestRank => 'सर्वश्रेष्ठ वैश्विक रैंक';

  @override
  String get legendsTrophiesBySeason => 'सीज़न के अनुसार ट्रॉफियाँ';

  @override
  String get legendsEosTrophies => 'सीज़न के अंत की ट्रॉफियाँ';

  @override
  String get legendsEosDetails => 'End Of Season Details';

  @override
  String get legendsInaccurateTitle => 'गलत डेटा?';

  @override
  String get legendsInaccurateIntro =>
      'क्लैश ऑफ़ क्लैंस API की सीमाओं के कारण, हमारा डेटा हमेशा पूरी तरह सटीक नहीं हो सकता है। इसका कारण यह है:';

  @override
  String get legendsInaccurateApiDelayTitle => 'एपीआई विलंब:';

  @override
  String get legendsInaccurateApiDelayBody =>
      'एपीआई को अपडेट होने में 5 मिनट तक का समय लग सकता है, जिससे वास्तविक समय में ट्रॉफी में होने वाले परिवर्तनों को दर्शाने में देरी हो सकती है।';

  @override
  String get legendsInaccurateConcurrentTitle => 'समवर्ती परिवर्तन:';

  @override
  String get legendsInaccurateMultipleAttacksTitle => '- बहुविध आक्रमण/रक्षा: ';

  @override
  String get legendsInaccurateMultipleAttacksBody =>
      'यदि एक के बाद एक कई हमले या बचाव होते हैं, तो API संयुक्त परिणाम दिखा सकता है (उदाहरण के लिए, +68 या -68)।';

  @override
  String get legendsInaccurateSimultaneousTitle => 'एक साथ आक्रमण और बचाव:';

  @override
  String get legendsInaccurateSimultaneousBody =>
      'यदि आक्रमण और बचाव एक ही समय पर होते हैं, तो आपको मिश्रित परिणाम दिखाई दे सकता है (उदाहरण के लिए, +4)।';

  @override
  String get legendsInaccurateNetGainTitle => '3. शुद्ध लाभ/हानि:';

  @override
  String get legendsInaccurateNetGainBody =>
      'समय संबंधी मुद्दों के बावजूद, दिन का समग्र शुद्ध लाभ या हानि सटीक है।';

  @override
  String get legendsInaccurateConclusion =>
      'ये सीमाएँ क्लैश ऑफ़ क्लैंस API का उपयोग करने वाले सभी टूल में आम हैं। दुख की बात है कि हम इसे ठीक नहीं कर सकते क्योंकि यह सुपरसेल के हाथों में है। हम इन सीमाओं की भरपाई करने और यथासंभव वास्तविकता के करीब परिणाम प्रदान करने के लिए अपना सर्वश्रेष्ठ प्रयास करते हैं। समझने के लिए धन्यवाद!';

  @override
  String get statsSeasonStats => 'सीज़न आँकड़े';

  @override
  String get statsByDay => 'दिन होने तक';

  @override
  String get statsBySeason => 'मौसम के अनुसार';

  @override
  String statsDayIndex(int index) {
    return 'दिन $index';
  }

  @override
  String statsIndexDays(int index) {
    return '$index दिन';
  }

  @override
  String statsSeasonDate(String date) {
    return '$date सीज़न';
  }

  @override
  String get statsAllTownHalls => 'सभी टाउन हॉल';

  @override
  String get statsMembers => 'सदस्य आँकड़े';

  @override
  String get todoTitle => 'करने के लिए सूची';

  @override
  String get todoExplanationTitle => 'कार्य गणना';

  @override
  String get todoExplanationIntro =>
      'कार्य पूर्णता प्रतिशत की गणना विशिष्ट भार के साथ निम्नलिखित गतिविधियों के आधार पर की जाती है:';

  @override
  String get todoExplanationLegendsTitle => 'लीजेंड लीग';

  @override
  String get todoExplanationLegends =>
      'प्रति खाता 8 अंक का भार, 1 हमला = 1 अंक.';

  @override
  String get todoExplanationRaidsTitle => 'छापे:';

  @override
  String get todoExplanationRaids =>
      'Weight of 5 points per account (or 6 if the last attack has been unlocked), 1 attack = 1 point.';

  @override
  String get todoExplanationClanWarsTitle => 'कबीले युद्ध:';

  @override
  String get todoExplanationClanWars =>
      'प्रति खाता 2 अंक का भार, 1 आक्रमण = 1 अंक.';

  @override
  String get todoExplanationCwlTitle => 'वंश युद्ध लीग:';

  @override
  String get todoExplanationCwl =>
      'प्रति खाता 1 अंक का भार, 1 हमला = 1 अंक। यदि खिलाड़ी अपने लीग कबीले में नहीं है तो CWL को ट्रैक नहीं किया जा सकता है।';

  @override
  String get todoExplanationPassAndGamesTitle => 'सीज़न पास और कबीले खेल:';

  @override
  String get todoExplanationPassAndGames =>
      'प्रत्येक खाते के लिए 2 अंक का भार। अनुपात शेष दिनों की संख्या पर आधारित है (पास के लिए 1 महीना और खेलों के लिए 6 दिन)। हरा = पास या खेल पूरा करने के लिए ट्रैक पर, लाल = समय से पीछे।';

  @override
  String get todoExplanationConclusion =>
      'अंतिम प्रतिशत की गणना चल रहे आयोजनों के दौरान पूरी की गई कुल क्रियाओं को कुल आवश्यक क्रियाओं से विभाजित करके की जाती है। 14 दिनों से अधिक समय तक निष्क्रिय रहने वाले खातों को गणना से बाहर रखा जाता है।';

  @override
  String todoAccountsNumber(int number) {
    return '$number खाते';
  }

  @override
  String todoAccountsNumberActive(int number) {
    return '$number सक्रिय खाते';
  }

  @override
  String todoAccountsNumberInactive(int number) {
    return '$number निष्क्रिय खाते';
  }

  @override
  String get todoAccountsActive => 'सक्रिय खाते';

  @override
  String get todoAccountsInactive => 'निष्क्रिय खाते';

  @override
  String get todoAccountsNoInactive => 'कोई निष्क्रिय खाता नहीं';

  @override
  String get todoAccountsNoActive => 'कोई सक्रिय खाता नहीं';

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
  String get warTitle => 'युद्ध';

  @override
  String get warFrequency => 'युद्ध आवृत्ति';

  @override
  String get warParticipation => 'युद्ध में भागीदारी';

  @override
  String get warLeague => 'युद्ध/लीग';

  @override
  String get warHistory => 'युद्ध इतिहास';

  @override
  String get warLog => 'युद्ध लॉग';

  @override
  String warLogClosed(String clan) {
    return 'युद्ध लॉग बंद';
  }

  @override
  String get warStats => 'युद्ध आँकड़े';

  @override
  String get warOngoing => 'जारी युद्ध';

  @override
  String warIsNotInWar(String clan) {
    return '$clan युद्ध में नहीं है';
  }

  @override
  String get warAskForWar =>
      'युद्ध शुरू करने के लिए नेता या सह-नेता से संपर्क करें।';

  @override
  String get warAskForWarLogOpening =>
      'युद्ध लॉग खोलने के लिए किसी नेता या सह-नेता से संपर्क करें।';

  @override
  String get warEnded => 'युद्ध समाप्त';

  @override
  String get warPreparation => 'तैयारी';

  @override
  String get warPerfectWar => 'उत्तम युद्ध';

  @override
  String get warVictory => 'विजय';

  @override
  String get warDefeat => 'हराना';

  @override
  String get warDraw => 'खींचना';

  @override
  String get warTeamSize => 'टीम का आकार';

  @override
  String get warMyTeam => 'मेरी टीम';

  @override
  String get warEnemiesTeam => 'दुश्मन';

  @override
  String get warClanDraw => 'दोनों कुल आपस में बंधे हुए हैं';

  @override
  String get warStateOfTheWar => 'युद्ध की स्थिति';

  @override
  String warStarsNeededToTakeTheLead(
      String clan, int star, int stars2, String percent) {
    return '$clan को अभी भी बढ़त लेने के लिए $star अधिक सितारों या $stars2 सितारों और $percent% की आवश्यकता है।';
  }

  @override
  String warStarsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan को अभी भी बढ़त लेने के लिए $percent% या 1 और स्टार की आवश्यकता है';
  }

  @override
  String get warNoDataAvailableForThisWar =>
      'इस युद्ध के लिए कोई डेटा उपलब्ध नहीं है ';

  @override
  String get warCalculatorFast => 'तेज़ कैलकुलेटर ';

  @override
  String warCalculatorAnswer(String percentNeeded, String result) {
    return '$percentNeeded% की विनाश दर प्राप्त करने के लिए, कुल $result% की आवश्यकता होती है';
  }

  @override
  String get warCalculatorNeededOverall => 'कुल मिलाकर % की आवश्यकता';

  @override
  String get warCalculatorCalculate => 'गणना';

  @override
  String get warAttacksTitle => 'आक्रमण';

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
  String get warDefensesTitle => 'गढ़';

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
  String get warStarsTitle => 'सितारे';

  @override
  String get warStarsAverage => 'औसत सितारे';

  @override
  String get warStarsNumber => 'सितारों की संख्या';

  @override
  String get warStarsOne => '1 सितारा';

  @override
  String get warStarsTwo => '2 सितारे';

  @override
  String get warStarsThree => '3 सितारे';

  @override
  String get warStarsZero => '0 Star';

  @override
  String get warStarsBestPerformance => 'Best performance';

  @override
  String get warDestructionTitle => 'Destruction';

  @override
  String get warDestructionAverage => 'औसत विनाश';

  @override
  String get warDestructionRate => 'विनाश दर';

  @override
  String warHistoryWinsDescription(int wins, String percent) {
    return 'आपके कबीले ने पिछले 50 युद्धों में से $wins युद्ध ($percent%) जीते हैं।';
  }

  @override
  String warHistoryLossesDescription(int losses, String percent) {
    return 'आपके कबीले ने पिछले 50 युद्धों में से $losses युद्ध ($percent%) हारे हैं।';
  }

  @override
  String warHistoryDrawsDescription(int draws, String percent) {
    return 'आपके कबीले ने पिछले 50 युद्धों में से $draws ($percent%) में जीत हासिल की थी।';
  }

  @override
  String warHistoryAverageMembersDescription(int members) {
    return 'आपके कबीले के पिछले 50 युद्धों में औसतन $members सदस्यों ने भाग लिया है।';
  }

  @override
  String warHistoryAverageWarStarsDescription(double stars, String percent) {
    return 'आपके कबीले को पिछले 50 युद्धों में हर युद्ध में औसतन $stars सितारे मिले थे। यह कुल सितारों का $percent दर्शाता है।';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return 'पिछले 50 युद्धों में आपके कबीले की विनाश दर औसतन $percent% थी।';
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
  String get warOpponentEqualThLevel => 'बराबर TH';

  @override
  String get warOpponentSelectMembersThLevel => 'सदस्य TH स्तर';

  @override
  String get warOpponentSelectOpponentsThLevel => 'प्रतिद्वंदी TH स्तर';

  @override
  String warFiltersLastXwars(int number) {
    return 'पिछले $number युद्ध';
  }

  @override
  String get warFiltersFriendly => 'दोस्ताना';

  @override
  String get warFiltersRandom => 'यादृच्छिक';

  @override
  String get warVisibilityToggleTownHall =>
      'पूर्व TH स्तरों से आँकड़े छिपाएँ/दिखाएँ';

  @override
  String get warEventsTitle => 'घटनाक्रम';

  @override
  String get warEventsNewest => 'नवीनतम';

  @override
  String get warEventsOldest => 'सबसे पुराने';

  @override
  String get warStatusReady => 'ऑप्ट इन';

  @override
  String get warStatusUnready => 'बाहर जाने का विकल्प चुना';

  @override
  String get warStatusMissed => 'Missed';

  @override
  String get warAbbreviationAvg => 'Avg';

  @override
  String get warAbbreviationAvgPercentage => 'Avg %';

  @override
  String get cwlTitle => 'CWL';

  @override
  String get cwlClanWarLeague => 'वंश युद्ध लीग';

  @override
  String get cwlOngoing => 'चल रही सी.डब्लू.एल.';

  @override
  String get cwlRounds => 'राउंड';

  @override
  String cwlRoundNumber(int number) {
    return 'Round $number';
  }

  @override
  String cwlCurrentRound(int round) {
    return 'यह वर्तमान में गोल $round है।';
  }

  @override
  String cwlRank(int rank) {
    return 'आपका कबीला वर्तमान में $rank पर है.';
  }

  @override
  String cwlStars(int stars) {
    return 'आपके कबीले में कुल $stars सितारे हैं';
  }

  @override
  String cwlDestructionPercentage(String percent) {
    return 'आपके कबीले की कुल विनाश दर $percent% है।';
  }

  @override
  String cwlTotalAttacks(int attacks, int totalAttacks) {
    return 'Your clan has a total of $attacks attacks out of $totalAttacks possible attacks.';
  }

  @override
  String get joinLeaveTitle => 'Join/Leave Logs (Current Season)';

  @override
  String get joinLeaveJoin => 'जोड़ना';

  @override
  String get joinLeaveLeave => 'छुट्टी';

  @override
  String get joinLeaveReset => 'रीसेट करें';

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
    return '$date को $time पर छोड़ा गया.\n';
  }

  @override
  String joinLeaveJoinedOnAt(String date, String time) {
    return '$date को $time पर शामिल हुए.';
  }

  @override
  String get raidsTitle => 'Raids';

  @override
  String get raidsLast => 'अंतिम छापे';

  @override
  String get raidsOngoing => 'जारी छापे';

  @override
  String get raidsDistrictsDestroyed => 'नष्ट हुए जिले';

  @override
  String get raidsCompleted => 'छापे पूरे हुए';

  @override
  String get searchNoResult => 'कोई परिणाम नहीं';

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
  String get dashboardTitle => 'डैशबोर्ड';

  @override
  String get toolsTitle => 'औजार';

  @override
  String get navigationTeam => 'टीमें';

  @override
  String get navigationStatistics => 'आंकड़े';

  @override
  String get versionDevice => 'संस्करण और डिवाइस';

  @override
  String get betaFeature => 'बीटा सुविधा';

  @override
  String get betaLabel => 'बीटा';

  @override
  String get betaDescription =>
      'यह सुविधा अभी बीटा में है, इसमें कुछ बग हो सकते हैं या यह अधूरी हो सकती है। हम सक्रिय रूप से सुधार पर काम कर रहे हैं और आपकी प्रतिक्रिया का स्वागत करते हैं। कृपया अपने विचार साझा करें और हमारे डिस्कॉर्ड सर्वर में किसी भी समस्या की रिपोर्ट करें ताकि हमें इसे बेहतर बनाने में मदद मिल सके।';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get settingsSelectLanguage => 'भाषा चुनें';

  @override
  String get settingsToggleTheme => 'थीम टॉगल करें';

  @override
  String get faqTitle => 'सामान्य प्रश्न';

  @override
  String get faqSubtitle => 'अक्सर पूछे जाने वाले प्रश्नों';

  @override
  String get faqIsThisFromSupercell => 'क्या यह ऐप सुपरसेल का है?';

  @override
  String get faqFanContentPolicy =>
      'यह सामग्री अनौपचारिक है और सुपरसेल द्वारा समर्थित नहीं है। अधिक जानकारी के लिए सुपरसेल की प्रशंसक सामग्री नीति देखें: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate => 'कभी-कभी डेटा गलत या गायब क्यों होता है?';

  @override
  String get faqClanNotTracked => 'कबीले का पता नहीं लगाया जा सका';

  @override
  String get faqClanNotTrackedAnswer =>
      'क्लैशकिंग केवल तभी यह जानकारी प्राप्त कर सकता है जब कबीले को ट्रैक किया गया हो। यदि आपका कबीला ट्रैक नहीं किया गया है, तो कृपया क्लैशकिंग बॉट को अपने डिस्कॉर्ड सर्वर पर आमंत्रित करें और /addclan कमांड का उपयोग करें। हम इसे बनाने पर काम कर रहे हैं';

  @override
  String get faqTrackingDown => 'ट्रैकिंग';

  @override
  String get faqTrackingDownAnswer =>
      'ट्रैकिंग कुछ समय के लिए काम करना बंद कर सकती है। यही कारण है कि कभी-कभी आपके डेटा में छेद हो सकते हैं। हम इसे सुधारने पर काम कर रहे हैं।';

  @override
  String get faqApiLimitation => 'क्लैश ऑफ क्लैंस एपीआई सीमा';

  @override
  String get faqApiLimitationAnswer =>
      'कुछ डेटा क्लैश ऑफ़ क्लैंस द्वारा प्रदान किया जाता है और उनके API में कुछ सीमाएँ हैं। यह लीजेंड ट्रैकिंग के मामले में है, यह कभी-कभी ट्रॉफी के लाभ और हानि को इस तरह से स्टैक करता है जैसे कि यह एक ही हमला था। यही कारण है कि हमारे पास आपके भवन के स्तर के बारे में कोई जानकारी नहीं है।';

  @override
  String get faqSupportWork => 'मैं आपके काम का समर्थन कैसे कर सकता हूं?';

  @override
  String get faqSupportWorkAnswer => 'हमारा समर्थन करने के कई तरीके हैं:';

  @override
  String get faqUseCodeClashKing => 'कोड \"ClashKing\" का उपयोग करें';

  @override
  String get faqSupportUsOnPatreon => 'पैट्रियन पर हमारा समर्थन करें';

  @override
  String get faqShareTheApp => 'इस ऐप को अपने दोस्तों के साथ साझा करें ';

  @override
  String get faqRateTheApp => 'स्टोर में ऐप को रेटिंग दें ';

  @override
  String get faqHelpUsTranslate => 'ऐप का अनुवाद करने में हमारी सहायता करें ';

  @override
  String get faqHowToInviteTheBot =>
      'मैं आपके बॉट को अपने डिस्कॉर्ड सर्वर पर कैसे आमंत्रित कर सकता हूं?';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'आप नीचे दिए गए बटन पर क्लिक करके हमारे बॉट को अपने सर्वर पर आमंत्रित कर सकते हैं। बॉट को जोड़ने के लिए आपको \"सर्वर प्रबंधित करें\" अनुमति की आवश्यकता होगी।';

  @override
  String get faqInviteTheBot => 'क्लैशकिंग बॉट को आमंत्रित करें';

  @override
  String get faqNeedHelp =>
      'मुझे मदद चाहिए या मैं कोई सुझाव देना चाहता हूँ। मैं आपसे कैसे संपर्क कर सकता हूँ?';

  @override
  String get faqNeedHelpAnswer =>
      'आप मदद मांगने या प्रतिक्रिया देने के लिए हमारे डिस्कॉर्ड सर्वर से जुड़ सकते हैं, या आप हमें devs@clashkingbot.com पर ईमेल कर सकते हैं। कृपया केवल अंग्रेज़ी या फ़्रेंच में ही लिखें।';

  @override
  String get faqSendEmail => 'हमें एक ईमेल भेजो';

  @override
  String get faqJoinDiscord => 'हमारे डिस्कॉर्ड सर्वर से जुड़ें';

  @override
  String get faqCannotOpenMailClient =>
      'कुछ कारणों से हम आपका मेल क्लाइंट नहीं खोल पा रहे हैं। हमने आपके लिए ईमेल पता कॉपी कर लिया है। आप ईमेल लिखकर प्राप्तकर्ता फ़ील्ड में पता पेस्ट कर सकते हैं।';

  @override
  String get translationHelpUsTranslate => 'अनुवाद करने में हमारी सहायता करें ';

  @override
  String get translationSuggestFeatures => 'सुविधाएँ सुझाएँ';

  @override
  String get translationThankYou => 'धन्यवाद!';

  @override
  String get translationThankYouContent =>
      'हमारे सभी अद्भुत अनुवादकों को बहुत-बहुत धन्यवाद, जो इस ऐप को दुनिया भर के अधिक लोगों तक पहुंचाने में हमारी मदद करते हैं!';

  @override
  String get translationHelpTranslateContent =>
      'आप क्राउडिन पर ऐप का अनुवाद करने में हमारी मदद कर सकते हैं। अगर आपकी भाषा क्राउडिन पर उपलब्ध नहीं है, तो बेझिझक हमारे डिस्कॉर्ड सर्वर पर इसका अनुरोध करें। आपकी मदद के लिए बहुत-बहुत धन्यवाद!';

  @override
  String get translationHelpTranslateButton =>
      'क्राउडिन पर अनुवाद में सहायता करें';

  @override
  String get translationCurrentTranslators => 'वर्तमान अनुवादक';
}
