// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get creatorCode => 'Code créateur : ClashKing';

  @override
  String get errorTitle =>
      'Oops! Our servers might have taken a fireball to the face! We\'re casting a healing spell... Try again in a moment.';

  @override
  String get errorSubtitle =>
      'If the issue persists, check our Discord Server to see if we\'re aware of it.';

  @override
  String get retry => 'Retry';

  @override
  String get signInWithDiscord => 'Connexion avec Discord';

  @override
  String get guestMode => 'Mode invité';

  @override
  String get needHelpJoinDiscord =>
      'Besoin d\'aide ? Rejoins-nous sur Discord.';

  @override
  String get loginError =>
      'An error occurred while logging in. Please try again later.';

  @override
  String doesNotExist(String tag) {
    return '$tag n\'existe pas.';
  }

  @override
  String isAlreadyLinked(String tag) {
    return '$tag est déjà lié à un compte.';
  }

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get playerTag => 'Player Tag (#ABC123)';

  @override
  String get playerTags => 'Tags de joueur';

  @override
  String get linkedAccounts => 'Linked Accounts';

  @override
  String followingTagsDoNotExist(String tags) {
    return 'Les tags suivants n\'existent pas : $tags.';
  }

  @override
  String followingTagsAreAlreadyLinked(String tags) {
    return 'Les tags suivants sont déjà liés à un compte : $tags.';
  }

  @override
  String get welcome => 'Bienvenue !';

  @override
  String get welcomeMessage =>
      'Pour commencer, ajoute un ou plusieurs compte Clash of clans à ton profil. Tu pourras en ajouter ou en supprimer à tout moment.';

  @override
  String get login => 'Connexion';

  @override
  String get logout => 'Déconnexion';

  @override
  String get language => 'Langue';

  @override
  String get settings => 'Paramètres';

  @override
  String get toggleTheme => 'Changer de thème';

  @override
  String get selectLanguage => 'Sélectionnez une langue';

  @override
  String get faq => 'FAQ';

  @override
  String get faqSubtitle => 'Foire aux questions';

  @override
  String get faqIsThisFromSupercell =>
      'Est-ce que cette application a été créée par Supercell ?';

  @override
  String get faqFanContentPolicy =>
      'Ce matériel n\'est pas officiel et n\'est pas approuvé par Supercell. Pour plus d\'informations, consultez la politique relative au contenu des fans de Supercell : www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate =>
      'Pourquoi les données ne sont-elles pas toujours exactes ou manquantes ?';

  @override
  String get faqClanNotTracked => 'Clan non suivi';

  @override
  String get faqClanNotTrackedAnswer =>
      'ClashKing ne peut obtenir ces informations que si le clan est suivi. Si votre clan ne semble pas être suivi, veuillez l\'inviter sur un serveur Discord et utiliser la commande /addclan. Nous espérons rendre cette fonctionnalité bientôt disponible dans l\'application.';

  @override
  String get faqTrackingDown => 'Suivi en panne';

  @override
  String get faqTrackingDownAnswer =>
      'Le tracking peut cesser de fonctionner pendant un certain temps. C\'est pourquoi il peut parfois y avoir des trous dans vos données. Nous faisons de notre mieux pour améliorer cela.';

  @override
  String get faqApiLimitation => 'Limitation de l\'API Clash of Clans';

  @override
  String get faqApiLimitationAnswer =>
      'Certaines données sont fournies par Clash of Clans et leur API présente certaines limitations. C\'est le cas du suivi des légendes où il regroupe parfois les gains et les pertes de trophées comme s\'il s\'agissait d\'une seule et même attaque. Ou encore, pourquoi nous n\'avons aucune informations sur le niveau de vos batiments.';

  @override
  String get faqSupportWork => 'Comment puis-je soutenir votre travail ?';

  @override
  String get faqSupportWorkAnswer =>
      'Il existe plusieurs façons de nous soutenir :';

  @override
  String get faqUseCodeClashKing => 'Utilisez le code \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Soutenez nous sur Patreon';

  @override
  String get faqShareTheApp => 'Partagez l\'applications avec vos amis';

  @override
  String get faqRateTheApp => 'Notez l\'application sur le store';

  @override
  String get faqHelpUsTranslate => 'Aidez nous à traduire l\'application';

  @override
  String get faqHowToInviteTheBot =>
      'Comment puis-je inviter votre bot sur mon serveur Discord ?';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'Vous pouvez inviter notre bot sur votre serveur en cliquant sur le bouton ci-dessous. Vous devrez disposer de l\'autorisation \"Gérer le serveur\" pour ajouter le bot.';

  @override
  String get faqInviteTheBot => 'Inviter le bot ClashKing';

  @override
  String get faqNeedHelp =>
      'J\'ai besoin d\'aide ou j\'aimerais faire une suggestion. Comment puis-je vous contacter?';

  @override
  String get faqNeedHelpAnswer =>
      'Vous pouvez rejoindre notre serveur Discord et demander de l\'aide, y faire un retour ou nous envoyer un e-mail à devs@clashkingbot.com. Tu peux nous écrire en français ou en anglais !';

  @override
  String get faqSendEmail => 'Envoyer un e-mail';

  @override
  String get faqJoinDiscord => 'Rejoindre le serveur Discord';

  @override
  String get faqCannotOpenMailClient =>
      'Pour une raison quelconque, nous ne pouvons pas ouvrir ton client de messagerie. Nous avons copié l\'adresse e-mail pour toi. Tu peux rédiger un e-mail et de coller l\'adresse dans le champ du destinataire.';

  @override
  String get helpUsTranslate => 'Nous aider à traduire';

  @override
  String get suggestFeatures => 'Proposer des fonctionnalités';

  @override
  String get thankYou => 'Merci !';

  @override
  String get thankYouContent =>
      'Un grand merci à tous nos incroyables traducteurs qui nous aident à rendre cette application accessible à plus de personnes à travers le monde !';

  @override
  String get helpTranslateContent =>
      'Tu peux nous aider à traduire l\'application sur Crowdin. Si ta langue n\'est pas disponible sur Crowdin, n\'hésite pas à la demander sur notre serveur Discord. Merci beaucoup pour ton aide !';

  @override
  String get helpTranslateButton => 'Aider à traduire sur Crowdin';

  @override
  String get versionDevice => 'Version & Appareil';

  @override
  String get loading => 'Chargement...';

  @override
  String get errorLoadingVersion => 'Erreur du chargement de la version';

  @override
  String get currentTranslators => 'Traducteurs actuels';

  @override
  String get betaFeature => 'Fonctionnalité Bêta';

  @override
  String get beta => 'BÊTA';

  @override
  String get betaDescription =>
      'Cette fonctionnalité est actuellement en version bêta, elle peut donc contenir des bugs ou être incomplète. Nous travaillons activement sur des améliorations et tes retours sont les bienvenus. N\'hésite pas à partager tes idées et à signaler tout problème sur notre serveur Discord pour nous aider à l\'améliorer.';

  @override
  String get copiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String get all => 'Tous';

  @override
  String get hourIndicator => 'h';

  @override
  String get minIndicator => 'm';

  @override
  String get noDataAvailable => 'Aucune donnée disponible.';

  @override
  String get close => 'Fermer';

  @override
  String get closed => 'Fermé';

  @override
  String get error => 'Erreur';

  @override
  String get player => 'Joueur';

  @override
  String notFoundOrNotLinkedToOurSystem(String player) {
    return 'introuvable ou non lié à notre système.';
  }

  @override
  String get tryAnotherNameOrTagOrLinkIt =>
      'Essayez un autre nom/tag ou liez le.';

  @override
  String get playerNotFound => 'Joueur introuvable';

  @override
  String get noValueEntered => 'Aucune valeur saisie';

  @override
  String get manage => 'Gérer';

  @override
  String get enterPlayerTag => 'Saisir le tag du joueur';

  @override
  String get add => 'Ajouter';

  @override
  String get delete => 'Supprimer';

  @override
  String get addAccount => 'Ajouter le compte';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get playerTagNotExists => 'Le tag du joueur n\'existe pas.';

  @override
  String accountAlreadyLinked(Object tag) {
    return 'Ce compte est déjà lié à un utilisateur.';
  }

  @override
  String get enterApiToken =>
      'Saisis le jeton API du compte pour confirmer que tu en es propriétaire. Tu peux le trouver dans les paramètres de Clash of Clans > Paramètres supplémentaires > Jeton API.';

  @override
  String get wrongApiToken => 'Le jeton API saisi est incorrect.';

  @override
  String get accountAlreadyLinkedToYou =>
      'Ce compte est déjà lié à ton profil.';

  @override
  String get apiToken => 'Jeton API du compte';

  @override
  String get failedToAddTryAgain =>
      'Échec de l\'ajout du compte. Veuillez réessayer plus tard.';

  @override
  String get fillAllFields => 'Please fill all fields.';

  @override
  String get failedToDeleteTryAgain =>
      'Échec de la suppression du compte. Veuillez réessayer plus tard.';

  @override
  String get enterPlayerTagWarning =>
      'Tu dois saisir un tag de joueur et cliquer sur \"+\" pour continuer.';

  @override
  String get failedToLoadAccountData => 'Failed to load accounts data.';

  @override
  String get failedToUpdateOrder => 'Failed to update the order of accounts.';

  @override
  String get loadAccountData => 'Load accounts data';

  @override
  String get syncAccounts => 'Sync Accounts';

  @override
  String get confirm => 'Confirm';

  @override
  String get warning => 'Attention';

  @override
  String get exitAppToOpenClash =>
      'Tu es sur le point de quitter l\'application pour ouvrir Clash of Clans.';

  @override
  String get confirmLogout => 'Es-tu sûr de vouloir te déconnecter ?';

  @override
  String get tagOrNamePlayer => 'Tag ou nom du joueur';

  @override
  String get searchPlayer => 'Rechercher un joueur';

  @override
  String get nameOrTagPlayer => 'Nom ou tag du joueur';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Ton clan est \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(
      String ratio, String donations, String received) {
    return 'Ton ratio de dons est de $ratio. Tu as donné $donations troupes et reçu $received troupes.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Ta préférence de guerre est \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'Tu as obtenu $stars étoiles en guerre';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'Tu as $trophies trophées en $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Tu es HDV $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Ta maison des ouvriers est niveau $level et tu as $trophies trophées.';
  }

  @override
  String get dashboard => 'Profil';

  @override
  String get homeBase => 'Village principal';

  @override
  String get th => 'HDV';

  @override
  String get builderBase => 'Base des ouvriers';

  @override
  String get bh => 'MDO';

  @override
  String get clanCapital => 'Capitale de clan';

  @override
  String get leader => 'Chef';

  @override
  String get coLeader => 'Adjoint';

  @override
  String get elder => 'Aîné';

  @override
  String get member => 'Membre';

  @override
  String get ready => 'Participe';

  @override
  String get unready => 'Ne participe pas';

  @override
  String level(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get heroes => 'Héros';

  @override
  String get equipment => 'Équipements';

  @override
  String get troops => 'Troupes';

  @override
  String get superTroops => 'Super Troupes';

  @override
  String get activeSuperTroops => 'Super Troupes Actives';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get pets => 'Familiers';

  @override
  String get siegeMachines => 'Engins de siège';

  @override
  String get spells => 'Sorts';

  @override
  String get achievements => 'Succès';

  @override
  String get byDay => 'Par jour';

  @override
  String get bySeason => 'Par saison';

  @override
  String dayIndex(int index) {
    return 'Jour $index';
  }

  @override
  String indexDays(int index) {
    return '$index jours';
  }

  @override
  String get bestTrophies => 'Plus haut trophées';

  @override
  String get mostAttacks => 'Plus d\'attaques';

  @override
  String get lastSeason => 'Dernière saison';

  @override
  String get bestRank => 'Meilleur classement';

  @override
  String daysLeft(int days) {
    return '$days jours restants';
  }

  @override
  String get date => 'Date';

  @override
  String get stats => 'Statistiques';

  @override
  String get fullStats => 'Full Stats';

  @override
  String get details => 'Détails';

  @override
  String get seasonStats => 'Statistiques de saison';

  @override
  String get charts => 'Graphs';

  @override
  String get history => 'Historique';

  @override
  String get legendLeague => 'Ligue légende';

  @override
  String get notInLegendLeague => 'Pas en ligue légende';

  @override
  String get noLegendsDataToday =>
      'You\'re not in Legend League, but past seasons are available.';

  @override
  String legendStartDescription(String trophies) {
    return 'Tu as commencé la journée avec $trophies trophées.';
  }

  @override
  String legendNoRankLocalDescription(String country, int trophies) {
    return 'Tu n\'es actuellement pas classé ($country) avec $trophies trophées.';
  }

  @override
  String legendRankLocalDescription(
      Object country, Object rank, Object trophies) {
    return 'Tu es actuellement classé $rank ($country) avec $trophies trophées.';
  }

  @override
  String legendGainDescription(int trophies) {
    return 'Tu as gagné $trophies trophées aujourd\'hui.';
  }

  @override
  String legendLossDescription(int trophies) {
    return 'Tu as perdu $trophies trophées aujourd\'hui.';
  }

  @override
  String legendNoGlobalRankDescription(int trophies) {
    return 'Tu n\'es actuellement pas classé monde avec $trophies trophées.';
  }

  @override
  String legendGlobalRankDescription(int rank, Object trophies) {
    return 'Tu es actuellement classé $rank monde avec $trophies trophées';
  }

  @override
  String get noRank => 'Non classé';

  @override
  String get started => 'Début';

  @override
  String get ended => 'Fin';

  @override
  String get average => 'Moyenne';

  @override
  String get remaining => 'Restant';

  @override
  String get legendsTitle => 'Données erronnées ?';

  @override
  String get legendsExplanation_intro =>
      'En raison des limitations de l\'API de Clash of Clans, nos données peuvent ne pas toujours être parfaitement précises. Voici pourquoi :\n';

  @override
  String get legendsExplanation_api_delay_title => '1. Délai de l\'API : ';

  @override
  String get legendsExplanation_api_delay_body =>
      'L\'API peut prendre jusqu\'à 5 minutes pour se mettre à jour, ce qui provoque un décalage dans l\'affichage des changements de trophées en temps réel.\n';

  @override
  String get legendsExplanation_concurrent_changes_title =>
      '2. Changements simultanés : \n';

  @override
  String get legendsExplanation_multiple_attacks_defenses_title =>
      '- Attaques/Défenses multiples : ';

  @override
  String get legendsExplanation_multiple_attacks_defenses_body =>
      'Si plusieurs attaques ou défenses se produisent en succession rapide, l\'API peut afficher des résultats combinés (par exemple, +68 ou -68).\n';

  @override
  String get legendsExplanation_simultaneous_attack_defense_title =>
      '- Attaque et défense simultanées : ';

  @override
  String get legendsExplanation_simultaneous_attack_defense_body =>
      'Si une attaque et une défense se produisent en même temps, vous pourriez voir un résultat mixte (par exemple, +4).\n';

  @override
  String get legendsExplanation_net_gain_loss_title =>
      '3. Gain/Perte net(te) : ';

  @override
  String get legendsExplanation_net_gain_loss_body =>
      'Malgré les problèmes de synchronisation, le gain ou la perte net(te) pour la journée est précis(e). ';

  @override
  String get legendsExplanation_conclusion =>
      'Ces limitations sont communes à tous les outils utilisant l\'API de Clash of Clans. Nous ne pouvons malheureusement pas résoudre ce problème car cela dépend de Supercell. Nous faisons de notre mieux pour compenser ces limites et fournir des résultats les plus proches de la réalité possible. Merci de votre compréhension !';

  @override
  String get toDoList => 'Tâches du jour';

  @override
  String get clanGames => 'Clan Games';

  @override
  String get seasonPass => 'Season Pass';

  @override
  String lastActive(String date) {
    return 'Dernière activité : $date';
  }

  @override
  String get playerNotTracked =>
      'Ce joueur n\'est pas suivi. Les données peuvent être inexactes.';

  @override
  String numberAccounts(int number) {
    return '$number comptes';
  }

  @override
  String numberActiveAccounts(int number) {
    return '$number comptes actifs';
  }

  @override
  String numberInactiveAccounts(int number) {
    return '$number comptes inactifs';
  }

  @override
  String get activeAccounts => 'Comptes actifs';

  @override
  String get inactiveAccounts => 'Comptes inactifs';

  @override
  String get noInactiveAccounts => 'Aucun compte inactif.';

  @override
  String get noActiveAccounts => 'Aucun compte actif.';

  @override
  String get todoExplanation_title => 'Le calcul des tâches';

  @override
  String get todoExplanation_intro =>
      'Le pourcentage de réalisation des tâches est calculé en fonction des activités suivantes avec des pondérations spécifiques :';

  @override
  String get todoExplanation_legends_title => 'Ligue légende :';

  @override
  String get todoExplanation_legends =>
      'Poids de 8 points par compte, 1 attaque = 1 point.';

  @override
  String get todoExplanation_raids_title => 'Raids :';

  @override
  String get todoExplanation_raids =>
      'Poids de 5 points par compte (ou 6 si la dernière attaque a été débloquée), 1 attaque = 1 point.';

  @override
  String get todoExplanation_clanWars_title => 'Guerres de Clan :';

  @override
  String get todoExplanation_clanWars =>
      'Poids de 2 points par compte, 1 attaque = 1 point.';

  @override
  String get todoExplanation_cwl_title => 'Ligue de Clan :';

  @override
  String get todoExplanation_cwl =>
      'Poids de 1 point par compte, 1 attaque = 1 point. La ligue ne peut pas être suivie si le joueur n\'est pas dans son clan de ligue.';

  @override
  String get todoExplanation_passAndGames_title =>
      'Pass de Saison & Jeux de clans :';

  @override
  String get todoExplanation_passAndGames =>
      'Poids de 2 points chacun par compte. Le ratio est basé sur le nombre de jours restants (1 mois pour le pass et 6 jours pour les jeux). En vert = dans les temps pour finir le pass ou les jeux, en rouge = en retard.';

  @override
  String get todoExplanation_conclusion =>
      'Le pourcentage final est calculé en divisant le total des actions réalisées pendant les événements en cours par le total des actions requises. Les comptes inactifs depuis plus de 14 jours sont exclus du calcul.';

  @override
  String get worst => 'Pire';

  @override
  String get best => 'Meilleur';

  @override
  String get total => 'Total';

  @override
  String get heroesEquipments => 'Équipements de héros';

  @override
  String daysAgo(int days) {
    return 'Il y a $days jours';
  }

  @override
  String dayAgo(int day) {
    return 'Il y a $day jour';
  }

  @override
  String hourAgo(int hour) {
    return 'Il y a $hour heure';
  }

  @override
  String hoursAgo(int hours, Object Hours) {
    return 'Il y a $hours heures';
  }

  @override
  String minuteAgo(int minute) {
    return 'Il y a $minute minute';
  }

  @override
  String minutesAgo(int minutes) {
    return 'Il y a $minutes minutes';
  }

  @override
  String secondAgo(int seconds) {
    return 'Il y a ${seconds}s';
  }

  @override
  String get justNow => 'À l\'instant';

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
  String get trophiesByMonth => 'Trophées par mois';

  @override
  String get trophiesBySeason => 'Trophées par saison';

  @override
  String get eosTrophies => 'Trophées en fin de saison';

  @override
  String get eosDetails => 'End Of Season Details';

  @override
  String get searchClan => 'Rechercher un clan';

  @override
  String get clanName => 'Clan\'s name';

  @override
  String get nameOrTagClan => 'Nom ou tag du clan';

  @override
  String get noResult => 'Aucun résultat.';

  @override
  String get filters => 'Filtres';

  @override
  String get whatever => 'Peu importe';

  @override
  String get any => 'Tous';

  @override
  String get notSet => 'Non défini';

  @override
  String get warFrequency => 'Fréquence de guerre';

  @override
  String get minimumMembers => 'Membres minimum';

  @override
  String get maximumMembers => 'Membres maximum';

  @override
  String get location => 'Localisation';

  @override
  String get minimumClanPoints => 'Points de clan minimum';

  @override
  String get minimumClanLevel => 'Niveau de clan minimum';

  @override
  String get noClan => 'Aucun clan';

  @override
  String get joinClanToUnlockNewFeatures =>
      'Rejoignez un clan pour débloquer de nouvelles fonctionnalités.';

  @override
  String get apply => 'Appliquer';

  @override
  String get opened => 'Ouvert';

  @override
  String get inviteOnly => 'Invitation';

  @override
  String get cancel => 'Annuler';

  @override
  String get clan => 'Clan';

  @override
  String get clans => 'Clans';

  @override
  String get members => 'Membres';

  @override
  String get role => 'Rôle';

  @override
  String get expLevel => 'Niveau d\'expérience';

  @override
  String get townHallLevel => 'Niveau d\'HDV';

  @override
  String thLevel(int level) {
    return 'HDV$level';
  }

  @override
  String bhLevel(int level) {
    return 'MDO$level';
  }

  @override
  String townHallLevelLevel(int level) {
    return 'Hôtel de ville $level';
  }

  @override
  String get byNumberOfWars => 'Par nombre de guerres';

  @override
  String get ok => 'OK';

  @override
  String get byDateRange => 'Par plage de dates';

  @override
  String get selectSeason => 'Selectionne une saison';

  @override
  String get year => 'Année';

  @override
  String get month => 'Mois';

  @override
  String get allTownHalls => 'Tous Hôtels de ville';

  @override
  String seasonDate(String date) {
    return 'Saison $date';
  }

  @override
  String lastXwars(int number) {
    return 'Dernières $number guerres';
  }

  @override
  String get friendly => 'Amicale';

  @override
  String get cwl => 'LDC';

  @override
  String get random => 'Classique';

  @override
  String get selectMembersThLevel => 'Niveau d\'HDV des membres';

  @override
  String get selectOpponentsThLevel => 'Niveau d\'HDV des adversaires';

  @override
  String get equalThLevel => 'Niveau d\'HDV égal';

  @override
  String get builderBaseTrophies => 'Trophées MDO';

  @override
  String get donations => 'Dons';

  @override
  String get donationsReceived => 'Don reçus';

  @override
  String get donationsRatio => 'Ratio de dons';

  @override
  String get trophies => 'Trophées';

  @override
  String get always => 'Toujours';

  @override
  String get never => 'Jamais';

  @override
  String get unknown => 'Inconnu';

  @override
  String get oncePerWeek => '1/semaine';

  @override
  String get twicePerWeek => '2/semaine';

  @override
  String get rarely => 'Rarement';

  @override
  String get warLeague => 'Guerre/Ligue';

  @override
  String get war => 'Guerre';

  @override
  String get league => 'Ligue';

  @override
  String get wars => 'Guerres';

  @override
  String get ongoingWar => 'Guerre en cours';

  @override
  String get ongoingCwl => 'Ligue en cours';

  @override
  String get cantOpenLink => 'Impossible d\'ouvrir le lien.';

  @override
  String get notInWar => 'Pas en guerre';

  @override
  String get warHistory => 'Historique de guerre';

  @override
  String warHistoryWinsDescription(int wins, String percent) {
    return 'Ton clan a gagné $wins guerres ($percent%) parmi les 50 dernières guerres.';
  }

  @override
  String warHistoryLossesDescription(int losses, String percent) {
    return 'Ton clan a perdu $losses guerres ($percent%) parmi les 50 dernières guerres.';
  }

  @override
  String warHistoryDrawsDescription(int draws, String percent) {
    return 'Ton clan a fait $draws égalités ($percent%) parmi les 50 dernières guerres.';
  }

  @override
  String warHistoryAverageMembersDescription(int members) {
    return 'Ton clan a une moyenne de $members membres participants pour les 50 dernières guerres.';
  }

  @override
  String warHistoryAverageWarStarsDescription(double stars, String percent) {
    return 'Ton clan a une moyenne de $stars étoiles par attaque pour les 50 dernières guerres. Ca représente $percent % des étoiles possibles.';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return 'Ton clan a une moyenne de $percent % de taux de destruction pour les 50 dernières guerres.';
  }

  @override
  String warHistoryAverageClanStarsPerMember(Object stars) {
    return 'Moyenne d\'étoiles par membre';
  }

  @override
  String warHistoryAverageMembers(int members) {
    return '~$members membres par guerre';
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
  String get averageStars => 'Moyenne d\'étoiles';

  @override
  String get averageDestruction => 'Moyenne de destruction';

  @override
  String get oneStar => '1 étoile';

  @override
  String get twoStars => '2 étoiles';

  @override
  String get threeStars => '3 étoiles';

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
  String get warParticipation => 'Participation à la guerre';

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
  String get toggleTownHallVisibility =>
      'Cacher/Afficher les stats des anciens niveaux d\'HDV';

  @override
  String get warLog => 'Journal';

  @override
  String get publicWarLog => 'Journal de guerre public';

  @override
  String get privateWarLog => 'Journal de guerre privé';

  @override
  String startsIn(String time) {
    return 'Début dans $time';
  }

  @override
  String startsAt(String time) {
    return 'Débute à $time';
  }

  @override
  String endsIn(String time) {
    return 'Fin dans $time';
  }

  @override
  String endsAt(String time) {
    return 'Se termine à $time';
  }

  @override
  String get joinLeaveLogs => 'Historique d\'arrivées/départs';

  @override
  String get join => 'Arrivée';

  @override
  String get leave => 'Départ';

  @override
  String get reset => 'Réinitialiser';

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
    return '$number joueurs ont quitté le clan durant la saison actuelle ($date).';
  }

  @override
  String joinNumberDescription(int number, String date) {
    return '$number joueurs ont rejoint le clan durant la saison actuelle ($date).';
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
    return 'Ton clan a perdu $number membres durant la saison actuelle ($date).';
  }

  @override
  String joinLeaveDifferenceEqualDescription(String date) {
    return 'Ton clan a maintenu son nombre de membres durant la saison actuelle ($date).';
  }

  @override
  String leftOnAt(String date, String time) {
    return 'Est parti le $date à $time.';
  }

  @override
  String joinedOnAt(String date, String time) {
    return 'A rejoint le $date à $time.';
  }

  @override
  String get statistics => 'Statistiques';

  @override
  String get stars => 'Étoiles';

  @override
  String get numberOfStars => 'Nombre d\'étoiles';

  @override
  String get destructionRate => 'Taux de destruction';

  @override
  String get events => 'Événements';

  @override
  String get team => 'Équipes';

  @override
  String get myTeam => 'Mon équipe';

  @override
  String get enemiesTeam => 'Ennemis';

  @override
  String get defense => 'Défense';

  @override
  String get defenses => 'Défenses';

  @override
  String get bestDefenses => 'Best defenses';

  @override
  String bestDefenseOutOf(int number) {
    return 'Best defense (out of $number)';
  }

  @override
  String get attack => 'Attaque';

  @override
  String get attacks => 'Attaques';

  @override
  String get bestAttacks => 'Best attacks';

  @override
  String get noAttackYet => 'No attack yet';

  @override
  String get noDefenseYet => 'No defense yet';

  @override
  String get bestPerformance => 'Best performance';

  @override
  String get victory => 'Victoire';

  @override
  String get defeat => 'Défaite';

  @override
  String get draw => 'Égalité';

  @override
  String get perfectWar => 'Perf map';

  @override
  String get newest => 'Plus récente';

  @override
  String get oldest => 'Plus ancienne';

  @override
  String get warEnded => 'Terminée';

  @override
  String get preparation => 'Préparation';

  @override
  String isNotInWar(String clan) {
    return '$clan n\'est pas en guerre.';
  }

  @override
  String warLogIsClosed(String clan) {
    return '$clan a son journal de guerre privé.';
  }

  @override
  String get askForWar =>
      'Contactez le chef ou un adjoint pour lancer une guerre.';

  @override
  String get askForWarLogOpening =>
      'Contactez un chef ou un adjoint pour ouvrir le journal de guerre.';

  @override
  String get warLogClosed => 'Le journal de guerre est privé.';

  @override
  String get rounds => 'Tours';

  @override
  String roundNumber(int number) {
    return 'Round $number';
  }

  @override
  String currentRound(int number) {
    return 'Current round (Round $number)';
  }

  @override
  String get noDataAvailableForThisWar =>
      'Aucune donnée disponible pour cette guerre';

  @override
  String get stateOfTheWar => 'État de la guerre';

  @override
  String starsNeededToTakeTheLead(
      String clan, int star, int star2, String percent, Object stars2) {
    return '$clan a besoin de $star étoile(s) supplémentaire(s) ou $star2 étoiles et $percent% pour prendre l\'avantage.';
  }

  @override
  String starsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan a besoin de $percent% ou 1 étoile supplémentaire pour prendre l\'avantage';
  }

  @override
  String get clanDraw => 'Les deux clans sont à égalité';

  @override
  String get fastCalculator => 'Calculatrice rapide';

  @override
  String fastCalculatorAnswer(
      String percentNeedeed, String result, Object percentNeeded) {
    return 'Pour obtenir un taux de destruction de $percentNeeded%, un total de $result% est nécessaire.';
  }

  @override
  String get teamSize => 'Taille de l\'équipe';

  @override
  String get neededOverall => '% total nécessaire';

  @override
  String get calculate => 'Calculer';

  @override
  String get warStats => 'Statistiques de guerre';

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
  String get membersStats => 'Statistiques des membres';

  @override
  String get clanWarLeague => 'Ligue de clan';

  @override
  String cwlRank(int rank) {
    return 'Ton clan est actuellement classé numéro $rank.';
  }

  @override
  String cwlStars(int stars) {
    return 'Ton clan a un total de $stars étoiles.';
  }

  @override
  String cwlMissingStarsFromNext(int stars) {
    return 'Ton clan a besoin de $stars étoiles pour rattraper le clan suivant.';
  }

  @override
  String cwlMissingStarsFromFirst(int stars) {
    return 'Ton clan a besoin de $stars étoiles pour rattraper le premier.';
  }

  @override
  String cwlDestructionPercentage(String percent) {
    return 'Ton clan a un taux de destruction de $percent%.';
  }

  @override
  String cwlTotalAttacks(int attacks, int totalAttacks) {
    return 'Your clan has a total of $attacks attacks out of $totalAttacks possible attacks.';
  }

  @override
  String cwlCurrentRound(int round) {
    return 'Nous sommes actuellement au tour $round.';
  }

  @override
  String get noAccountLinkedToYourProfileFound =>
      'Aucun compte lié à votre profil n\'a été trouvé.';

  @override
  String get management => 'Gestion';

  @override
  String get comingSoon => 'Bientôt disponible !';

  @override
  String get connectionError =>
      'Une erreur s\'est produite. Veuillez vérifier votre connexion internet et réessayer.';

  @override
  String get connectionErrorRelaunch =>
      'Une erreur est survenue. Veuillez vérifier votre connexion internet et relancer l\'application.';

  @override
  String updatedAt(String time) {
    return 'Mis à jour à $time';
  }

  @override
  String get tools => 'Outils';

  @override
  String get community => 'Communauté';

  @override
  String get raids => 'Raids';

  @override
  String get lastRaids => 'Derniers raids';

  @override
  String get ongoingRaids => 'Raids en cours';

  @override
  String get districtsDestroyed => 'Districts détruits';

  @override
  String get raidsCompleted => 'Raids complétés';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get maintenanceDescription =>
      'Clash of Clans is currently under maintenance, so we can\'t access the API. Please check back later.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get downloadTooltip => 'Download CWL summary';

  @override
  String get downloadInProgress =>
      'Downloading file... It can take a few seconds...';

  @override
  String downloadSuccess(String path) {
    return 'File saved successfully in \$$path';
  }

  @override
  String get downloadError => 'Failed to download file';
}
