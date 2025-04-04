// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get creatorCode => 'Κωδικός Δημιουργού: ClashKing';

  @override
  String get errorTitle => 'Oops! Our servers might have taken a fireball to the face! We\'re casting a healing spell... Try again in a moment.';

  @override
  String get errorSubtitle => 'If the issue persists, check our Discord Server to see if we\'re aware of it.';

  @override
  String get retry => 'Retry';

  @override
  String get signInWithDiscord => 'Είσοδος με Discord';

  @override
  String get guestMode => 'Συνέχεια ως Επισκέπτης';

  @override
  String get needHelpJoinDiscord => 'Χρειάζεστε βοήθεια; Βρείτε μας στο Discord.';

  @override
  String get loginError => 'An error occurred while logging in. Please try again later.';

  @override
  String get createGuestProfile => 'Δημιουργήστε το προφίλ επισκέπτη σας';

  @override
  String doesNotExist(String tag) {
    return 'Ο χρήστης $tag δεν υπάρχει.';
  }

  @override
  String isAlreadyLinked(String tag) {
    return 'Ο χρήστης $tag είναι ήδη συνδεδεμένος σε κάποιον.';
  }

  @override
  String get username => 'Όνομα Χρήστη';

  @override
  String get pleaseEnterUsername => 'Παρακαλώ εισάγετε το όνομα χρήστη σας';

  @override
  String get playerTag => 'Player Tag (#ABC123)';

  @override
  String get playerTags => 'Λογαριασμοί Παίχτη';

  @override
  String get linkedAccounts => 'Linked Accounts';

  @override
  String followingTagsDoNotExist(String tags) {
    return 'Οι ακόλουθοι λογαριασμοί δεν υπάρχουν: $tags.';
  }

  @override
  String followingTagsAreAlreadyLinked(String tags) {
    return 'Οι ακόλουθοι λογαριασμοί είναι ήδη συνδεδεμένοι σε κάποιον: $tags.';
  }

  @override
  String get welcome => 'Καλώς Ήλθατε!';

  @override
  String get welcomeMessage => 'Παρακαλώ προσθέστε έναν ή περισσότερους λογαριασμούς \"Clash Of Clans\" στο προφίλ σας. Μπορείτε να προσθέσετε ή να αφαιρέσετε λογαριασμούς αργότερα.';

  @override
  String get login => 'Είσοδος';

  @override
  String get logout => 'Έξοδος';

  @override
  String get language => 'Γλώσσα';

  @override
  String get settings => 'Ρυθμίσεις';

  @override
  String get toggleTheme => 'Εμφάνιση';

  @override
  String get selectLanguage => 'Επιλέξτε μία γλώσσα';

  @override
  String get faq => 'FAQ';

  @override
  String get faqSubtitle => 'Συχνές Ερωτήσεις';

  @override
  String get faqIsThisFromSupercell => 'Η εφαρμογή ανήκει στη Supercell;';

  @override
  String get faqFanContentPolicy => 'Η εφαρμογή είναι ανεπίσημη και δεν υποστηρίζεται από τη Supercell. Για περισσότερες πληροφορίες δείτε την Πολιτική Δημιουργίας για Θαυμαστές της Supercell: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate => 'Γιατί τα δεδομένα είναι μερικές φορές ανακριβή ή ελλιπή;';

  @override
  String get faqClanNotTracked => 'Δεν εμφανίζει την ομάδα';

  @override
  String get faqClanNotTrackedAnswer => 'Το ClashKing μπορεί να καταγράφει αυτές τις πληροφορίες μόνο όταν η ομάδα είναι ήδη καταγεγραμμένη. Εάν η ομάδα δεν είναι καταγεγραμμένη, παρακαλώ προσθέστε το εργαλείο ClashKing στη σελίδα του Discord σας και χρησιμοποιείστε την εντολή /addclan. Δουλεύουμε για να φέρουμε αυτό το χαρακτηριστικό στην εφαρμογή σύντομα.';

  @override
  String get faqTrackingDown => 'Σταμάτησε η καταγραφή';

  @override
  String get faqTrackingDownAnswer => 'Η καταγραφή μπορεί να σταματήσει για ένα συγκεκριμένο χρονικό διάστημα. Για αυτόν τον λόγο μπορεί μερικές φορές να μην είναι ολοκληρωμένα τα δεδομένα σας. Δουλεύουμε για να το βελτιώσουμε.';

  @override
  String get faqApiLimitation => 'Όρια του Clash Of Clans API';

  @override
  String get faqApiLimitationAnswer => 'Some data are provided by Clash of Clans and their API has some limitations. This is the case for legend tracking where it sometimes stack the trophy gain and loss as if it was one attack. It is also why we do not have any information on your buildings levels.';

  @override
  String get faqSupportWork => 'Πώς μπορώ να υποστηρίξω το έργο σας;';

  @override
  String get faqSupportWorkAnswer => 'Υπάρχουν αρκετοί τρόποι για να μας υποστηρίξετε:';

  @override
  String get faqUseCodeClashKing => 'Χρησιμοποιήστε τον κωδικό δημιουργού \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Υποστηρίξτε μας στο Patreon';

  @override
  String get faqShareTheApp => 'Μοιραστείτε την εφαρμογή με τους φίλους σας';

  @override
  String get faqRateTheApp => 'Αξιολογείστε την εφαρμογή';

  @override
  String get faqHelpUsTranslate => 'Βοηθήστε μας να μεταφράσουμε την εφαρμογή';

  @override
  String get faqHowToInviteTheBot => 'Πώς μπορώ να προσθέσω το εργαλείο ClashKing στην ομάδα μου στο Discord;';

  @override
  String get faqHowToInviteTheBotAnswer => 'Μπορείτε να προσθέσετε το εργαλείο Clashking στην ομάδα σας πατώντας το παρακάτω κουμπί. Θα χρειαστεί να επιτρέψετε την άδεια \"Διαχείριση Ομάδας\" για να προσθέσετε το εργαλείο.';

  @override
  String get faqInviteTheBot => 'Προσθέστε το εργαλείο Clashking';

  @override
  String get faqNeedHelp => 'Χρειάζομαι βοήθεια ή θα ήθελα να κάνω μία πρόταση. Πώς μπορώ να επικοινωνήσω μαζί σας;';

  @override
  String get faqNeedHelpAnswer => 'Μπορείτε να μας βρείτε στην ομάδα μας στο Discord για να ζητήσετε βοήθεια ή να μας μεταφέρετε τα σχόλιά σας, αλλιώς μπορείτε να μας στείλετε ένα email στο devs@clashkingbot.com. Σας παρακαλούμε να γράφετε μόνο στα Αγγλικά ή στα Γαλλικά.';

  @override
  String get faqSendEmail => 'Στείλτε μας ένα email';

  @override
  String get faqJoinDiscord => 'Εισέλθετε στην ομάδα μας στο Discord';

  @override
  String get faqCannotOpenMailClient => 'Για κάποιους λόγους δεν μπορέσαμε να ανοίξουμε το mail σας. Έχουμε αντιγράψει τη διεύθυνση ηλεκτρονικού ταχυδρομείου για εσάς. Μπορείτε να γράψετε ένα email και να αποκολλήσετε τη διεύθυνση στο πεδίο του παραλήπτη.';

  @override
  String get helpUsTranslate => 'Βοηθήστε μας να μεταφράσουμε';

  @override
  String get suggestFeatures => 'Προτείνετε χαρακτηριστικά';

  @override
  String get thankYou => 'Σας ευχαριστούμε!';

  @override
  String get thankYouContent => 'Ένα τεράστιο ευχαριστώ σε όλους τους εξαιρετικούς μεταφραστές μας που μας βοηθάνε να κάνουμε την εφαρμογή προσβάσιμη σε περισσότερους ανθρώπους σε όλο τον κόσμο!';

  @override
  String get helpTranslateContent => 'Μπορείτε να μας βοηθήσετε να μεταφράσουμε την εφαρμογή στο Crowdin. Εάν η γλώσσα σας δεν είναι διαθέσιμη στο Crowdin, παρακαλώ ζητείστε το στην ομάδα μας στο Discord. Σας ευχαριστούμε πολύ για τη βοήθεια!';

  @override
  String get helpTranslateButton => 'Βοηθήστε μας στη μετάφραση στο Crowdin';

  @override
  String get versionDevice => 'Εκδοχή & Συσκευή';

  @override
  String get loading => 'Φορτώνει...';

  @override
  String get errorLoadingVersion => 'Σφάλμα στη φόρτωσης της εκδοχής';

  @override
  String get currentTranslators => 'Τωρινοί μεταφραστές';

  @override
  String get betaFeature => 'Χαρακτηριστικό εκδοχής Beta';

  @override
  String get beta => 'BETA';

  @override
  String get betaDescription => 'Αυτό το χαρακτηριστικό βρίσκεται ακόμη στην εκδοχή beta, οπότε μπορεί να αντιμετωπίσετε μερικά σφάλματα ή να μην είναι ολοκληρωμένο. Δουλεύουμε ενεργά για τη βελτίωση της εφαρμογής και σας προσκαλούμε, να μοιραστείτε τις ιδέες σας και να αναφέρετε οποιαδήποτε σφάλματα αντιμετωπίζετε, στην ομάδα μας στο Discord.';

  @override
  String get copiedToClipboard => 'Αντιγράφηκε στο πρόχειρο';

  @override
  String get all => 'Όλα';

  @override
  String get hourIndicator => 'ω';

  @override
  String get minIndicator => 'λ';

  @override
  String get noDataAvailable => 'Δεν υπάρχουν διαθέσιμα δεδομένα.';

  @override
  String get close => 'Κλείσιμο';

  @override
  String get closed => 'Έκλεισε';

  @override
  String get error => 'Σφάλμα';

  @override
  String get player => 'Παίχτης';

  @override
  String notFoundOrNotLinkedToOurSystem(String player) {
    return '$player δε βρέθηκε ή δεν έχει συνδεθεί στο σύστημά μας.';
  }

  @override
  String get tryAnotherNameOrTagOrLinkIt => 'Δοκιμάστε διαφορετικό όνομα/αριθμό λογαριασμού ή συνδέστε το.';

  @override
  String get playerNotFound => 'Παίχτης δε βρέθηκε';

  @override
  String get noValueEntered => 'Δεν εντοπίστηκε αξία';

  @override
  String get manage => 'Διαχείριση';

  @override
  String get enterPlayerTag => 'Εισάγετε έναν αριθμό λογαριασμού';

  @override
  String get add => 'Προσθέσετε';

  @override
  String get delete => 'Διαγράψτε';

  @override
  String get addAccount => 'Προσθέστε λογαριασμό';

  @override
  String get deleteAccount => 'Διαγράψτε λογαριασμό';

  @override
  String get playerTagNotExists => 'Ο αριθμός λογαριασμού που καταγράψατε δεν υπάρχει.';

  @override
  String accountAlreadyLinked(Object tag) {
    return 'Ο αριθμός λογαριασμού είναι ήδη συνδεδεμένος σε κάποιον.';
  }

  @override
  String get enterApiToken => 'Παρακαλώ εισάγετε το κλειδί API του λογαριασμού σας για να επιβεβαιώσετε ότι είναι δικός σας. Μπορείτε να το βρείτε στο Clash of Clans > Settings > More Settings > API Token.';

  @override
  String get wrongApiToken => 'Το κλειδί API που εισάγατε είναι λάθος';

  @override
  String get accountAlreadyLinkedToYou => 'Ο αριθμός λογαριασμού είναι ήδη συνδεδεμένος σε εσάς.';

  @override
  String get apiToken => 'Κλειδί API λογαριασμού';

  @override
  String get failedToAddTryAgain => 'Σφάλμα στην προσθήκη της σύνδεσης. Παρακαλώ προσπαθήστε ξανά αργότερα.';

  @override
  String get fillAllFields => 'Please fill all fields.';

  @override
  String get failedToDeleteTryAgain => 'Σφάλμα στη διαγραφή της σύνδεσης. Παρακαλώ προσπαθήστε ξανά αργότερα.';

  @override
  String get enterPlayerTagWarning => 'Εισάγετε έναν αριθμό λογαριασμού και πιέσετε το κουμπί \"+\" για να συνεχίσετε.';

  @override
  String get failedToLoadAccountData => 'Failed to load accounts data.';

  @override
  String get loadAccountData => 'Load accounts data';

  @override
  String get search => 'Αναζήτηση';

  @override
  String get warning => 'Προειδοποίηση';

  @override
  String get exitAppToOpenClash => 'Πρόκειται να βγείτε από την εφαρμογή για να ανοίξετε το Clash of Clans.';

  @override
  String get confirmLogout => 'Είστε σίγουροι ότι θέλετε να κάνετε έξοδο από τον λογαριασμό σας;';

  @override
  String get tagOrNamePlayer => 'Αριθμός λογαριασμού ή όνομα';

  @override
  String get searchPlayer => 'Αναζήτηση παίχτη';

  @override
  String get nameOrTagPlayer => 'Όνομα παίχτη ή αριθμός λογαριασμού';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Η ομάδα σας είναι η \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(String ratio, String donations, String received) {
    return 'Η αναλογία δωρεάς σας είναι $ratio. Έχετε δωρίσει $donations στρατιώτες και έχετε λάβει $received.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Η προτίμηση πολέμου σας είναι \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'Έχετε $stars αστέρια πολέμου.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'Διαθέτετε $trophies τρόπαια. Βρίσκεστε στο επίπεδο $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Το επίπεδο του Δημαρχείου σας είναι $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Το επίπεδο του Δημαρχείου Χτίστη σας είναι $level και διαθέτετε $trophies τρόπαια.';
  }

  @override
  String get dashboard => 'Πίνακας Ελέγχου';

  @override
  String get homeBase => 'Κύρια Βάση';

  @override
  String get th => 'Δ';

  @override
  String get builderBase => 'Βάση Χτίστη';

  @override
  String get bh => 'ΔΧ';

  @override
  String get clanCapital => 'Πρωτεύουσα Ομάδας';

  @override
  String get leader => 'Αρχηγός';

  @override
  String get coLeader => 'Συν-Αρχηγός';

  @override
  String get elder => 'Επίτιμο Μέλος';

  @override
  String get member => 'Μέλος';

  @override
  String get ready => 'Θέλω να συμμετέχω';

  @override
  String get unready => 'Δε θέλω να συμμετέχω';

  @override
  String level(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get heroes => 'Ήρωες';

  @override
  String get equipment => 'Εξοπλισμός';

  @override
  String get troops => 'Στρατός';

  @override
  String get superTroops => 'Σούπερ Στρατός';

  @override
  String get activeSuperTroops => 'Ενεργός Σούπερ Στρατός';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get pets => 'Κατοικίδια';

  @override
  String get siegeMachines => 'Μηχανές Πολιορκίας';

  @override
  String get spells => 'Ξόρκια';

  @override
  String get achievements => 'Επιτεύγματα';

  @override
  String get byDay => 'Με τη μέρα';

  @override
  String get bySeason => 'Με τη σεζόν';

  @override
  String dayIndex(int index) {
    return 'Μέρα $index';
  }

  @override
  String indexDays(int index) {
    return '$index Μέρες';
  }

  @override
  String get bestTrophies => 'Υψηλότερα Τρόπαια';

  @override
  String get mostAttacks => 'Περισσότερες Επιθέσεις';

  @override
  String get lastSeason => 'Τελευταία Σεζόν';

  @override
  String get bestRank => 'Υψηλότερη Παγκόσμια Θέση';

  @override
  String daysLeft(int days) {
    return '$days ημέρες ακόμη';
  }

  @override
  String get date => 'Ημερομηνία';

  @override
  String get stats => 'Στατιστικά';

  @override
  String get details => 'Λεπτομέρειες';

  @override
  String get seasonStats => 'Στατιστικά Σεζόν';

  @override
  String get charts => 'Διαγράμματα';

  @override
  String get history => 'Ιστορικό';

  @override
  String get legendLeague => 'Επίπεδο Θρύλων';

  @override
  String get notInLegendLeague => 'Not in Legend League';

  @override
  String get noLegendData => 'No Legend Data Found for today';

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
  String get noStars => '0 star';

  @override
  String get oneStar => '1 star';

  @override
  String get twoStars => '2 stars';

  @override
  String get threeStars => '3 stars';

  @override
  String get warParticipation => 'War Participation';

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
  String joinLeaveDifferenceUpDescription(int number, String date) {
    return 'Your clan has gained $number new member(s) this season ($date).';
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
  String get attack => 'Attack';

  @override
  String get attacks => 'Attacks';

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
