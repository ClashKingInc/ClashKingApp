// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'ClashKing';

  @override
  String get appDescription =>
      'Ton compagnon Clash of Clans préféré pour suivre tes statistiques, gérer tes clans et analyser tes performances.';

  @override
  String get generalLoading => 'Chargement...';

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
  String get generalRetry => 'Réessayer';

  @override
  String get generalTryAgain => 'Réessayer';

  @override
  String get generalCancel => 'Annuler';

  @override
  String get generalOk => 'OK';

  @override
  String get generalApply => 'Appliquer';

  @override
  String get generalConfirm => 'Confirmer';

  @override
  String get generalManage => 'Gérer';

  @override
  String get generalSettings => 'Paramètres';

  @override
  String get generalCopiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String get generalComingSoon => 'Bientôt disponible !';

  @override
  String generalLastRefresh(String time) {
    return 'Last refresh: $time';
  }

  @override
  String generalRefreshFailed(String error) {
    return 'Refresh failed: $error';
  }

  @override
  String get generalAll => 'Tous';

  @override
  String get generalTotal => 'Total';

  @override
  String get generalBest => 'Meilleur';

  @override
  String get generalWorst => 'Pire';

  @override
  String get generalAverage => 'Moyenne';

  @override
  String get generalRemaining => 'Restant';

  @override
  String get generalActive => 'Actif';

  @override
  String get generalInactive => 'Inactif';

  @override
  String get generalStarted => 'Début';

  @override
  String get generalEnded => 'Fin';

  @override
  String get generalRole => 'Rôle';

  @override
  String get generalStats => 'Statistiques';

  @override
  String get generalFullStats => 'Statistiques complètes';

  @override
  String get generalDetails => 'Détails';

  @override
  String get generalHistory => 'Historique';

  @override
  String get generalFilters => 'Filtres';

  @override
  String get generalNotSet => 'Non défini';

  @override
  String get generalWarning => 'Attention';

  @override
  String get generalNoDataAvailable => 'Aucune donnée disponible.';

  @override
  String get authSignUp => 'Inscription';

  @override
  String get authLogin => 'Connexion';

  @override
  String get authLogout => 'Déconnexion';

  @override
  String get authCreateAccount => 'Créer un compte';

  @override
  String get authJoinClashKing => 'Rejoindre ClashKing';

  @override
  String get authCreateClashKingAccount => 'Créer un compte ClashKing';

  @override
  String get authCreateAccountToGetStarted => 'Crée ton compte pour commencer';

  @override
  String get authAlreadyHaveAccount => 'Tu as déjà un compte ? Connecte-toi';

  @override
  String get authConfirmLogout => 'Es-tu sûr de vouloir te déconnecter ?';

  @override
  String get authDiscordTitle => 'Discord';

  @override
  String get authDiscordSignIn => 'Connexion avec Discord';

  @override
  String get authDiscordContinue => 'Continuer avec Discord';

  @override
  String get authDiscordDescription =>
      'Synchronise tes données avec le Bot ClashKing et débloque le plein potentiel de ClashKing !';

  @override
  String get authEmailTitle => 'E-mail';

  @override
  String get authEmailDescription =>
      'Utilise ton adresse email si tu ne peux pas accéder à Discord ou que tu veux utiliser l\'application seulement';

  @override
  String get authEmailRequired => 'Saisis ton email';

  @override
  String get authEmailInvalid => 'Saisis un email valide';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authPasswordConfirm => 'Confirmer le mot de passe';

  @override
  String get authPasswordRequired => 'Saisis ton mot de passe';

  @override
  String get authPasswordConfirmRequired => 'Confirme ton mot de passe';

  @override
  String get authPasswordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get authPasswordTooShort =>
      'Le mot de passe doit comporter au moins 8 caractères';

  @override
  String get authPasswordRequirements =>
      'Le mot de passe doit contenir : majuscule, minuscule, chiffre et caractère spécial';

  @override
  String get authPasswordForgot => 'Mot de passe oublié ?';

  @override
  String get authUsernameLabel => 'Nom d\'utilisateur';

  @override
  String get authUsernameRequired => 'Saisis un nom d\'utilisateur';

  @override
  String get authUsernameTooShort =>
      'Le nom d\'utilisateur doit contenir au moins 3 caractères';

  @override
  String get authErrorConnection =>
      'Une erreur est survenue. Vérifie ta connexion internet et réessaye.';

  @override
  String get authErrorConnectionRelaunch =>
      'Une erreur s\'est produite, vérifie ta connexion internet et relance l\'application.';

  @override
  String get authAccountManagement => 'Gestion des comptes';

  @override
  String get authAccountConnected => 'Comptes connectés';

  @override
  String get authAccountConnectedStatus => 'Connecté';

  @override
  String get authAccountNotConnected => 'Non connecté';

  @override
  String get authAccountEmailAndPassword => 'Email et mot de passe';

  @override
  String get authAccountSecured =>
      'Ton compte est sécurisé avec plusieurs méthodes d\'authentification';

  @override
  String get authAccountLinkEmail => 'Lier un compte email';

  @override
  String get authAccountAddEmailAuth =>
      'Ajouter une authentification email/mot de passe';

  @override
  String get authAccountEmailLinkedSuccess => 'Compte email lié avec succès';

  @override
  String get helpTitle => 'Besoin d\'aide ?';

  @override
  String get helpJoinDiscord => 'Rejoindre Discord';

  @override
  String get helpEmailUs => 'Nous envoyer un email';

  @override
  String get accountsWelcome => 'Bienvenue !';

  @override
  String get accountsWelcomeMessage =>
      'Pour commencer, ajoute un ou plusieurs comptes Clash of Clans à ton profil. Tu pourras en ajouter ou en supprimer à tout moment.';

  @override
  String get accountsManageTitle => 'Gérer les comptes';

  @override
  String get accountsNoneFound =>
      'Aucun compte lié à ton profil n\'a été trouvé.';

  @override
  String get accountsPlayerTag => 'Tag du joueur';

  @override
  String get accountsEnterPlayerTag => 'Saisir le tag du joueur';

  @override
  String get accountsAdd => 'Ajouter';

  @override
  String get accountsDelete => 'Supprimer';

  @override
  String get accountsApiToken => 'Jeton API du compte';

  @override
  String get accountsEnterApiToken =>
      'Saisis le jeton API du compte pour confirmer que tu en es propriétaire. Tu peux le trouver dans les paramètres de Clash of Clans > Paramètres supplémentaires > Jeton API.';

  @override
  String get accountsFillAllFields => 'Merci de remplir tous les champs.';

  @override
  String get accountsErrorTagNotExists => 'Le tag du joueur n\'existe pas.';

  @override
  String accountsErrorAlreadyLinked(Object tag) {
    return 'Ce compte est déjà lié à un utilisateur.';
  }

  @override
  String get accountsErrorAlreadyLinkedToYou =>
      'Ce compte est déjà lié à ton profil.';

  @override
  String get accountsErrorWrongApiToken => 'Le jeton API saisi est incorrect.';

  @override
  String get accountsErrorFailedToAdd =>
      'Échec de l\'ajout du compte. Réessaie plus tard.';

  @override
  String get accountsErrorFailedToDelete =>
      'Échec de la suppression du compte. Réessaie plus tard.';

  @override
  String get accountsErrorFailedToUpdateOrder =>
      'Échec de la mise à jour de l\'ordre. Réessaie plus tard.';

  @override
  String get errorTitle => 'Erreur';

  @override
  String get errorSubtitle => 'Une erreur s\'est produite';

  @override
  String get errorLoadingVersion => 'Erreur du chargement de la version';

  @override
  String get errorCannotOpenLink => 'Impossible d\'ouvrir le lien.';

  @override
  String get errorExitAppToOpenClash =>
      'Tu es sur le point de quitter l\'application pour ouvrir Clash of Clans.';

  @override
  String get playerSearchTitle => 'Rechercher un joueur';

  @override
  String get playerSearchPlaceholder => 'Nom ou tag du joueur';

  @override
  String playerLastActive(String date) {
    return 'Dernière activité : $date';
  }

  @override
  String get playerNotTracked =>
      'Ce joueur n\'est pas suivi. Les données peuvent être inexactes.';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Ton clan est \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(
      String ratio, String donations, String received) {
    return 'Ton ratio de dons est $ratio. Tu as donné $donations troupes et reçu $received troupes.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Ta préférence de guerre est «$preference».';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'Tu as $stars étoiles de guerres.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'Tu as $trophies trophées. Tu es actuellement en ligue $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Ton hôtel de ville est niveau $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Ta maison des ouvriers est niveau $level et tu as $trophies trophées.';
  }

  @override
  String get gameBaseHome => 'Village principal';

  @override
  String get gameBaseBuilder => 'Base des ouvriers';

  @override
  String get gameClanCapital => 'Capitale de clan';

  @override
  String get gameTownHall => 'HDV';

  @override
  String get gameTownHallLevel => 'Niveau d\'HDV';

  @override
  String gameTownHallLevelNumber(int level) {
    return 'Hôtel de ville $level';
  }

  @override
  String gameTHLevel(int level) {
    return 'HDV$level';
  }

  @override
  String get gameExpLevel => 'Niveau d\'expérience';

  @override
  String get gameTrophies => 'Trophées';

  @override
  String get gameBuilderBaseTrophies => 'Trophées MDO';

  @override
  String get gameDonations => 'Dons';

  @override
  String get gameDonationsReceived => 'Dons reçus';

  @override
  String get gameDonationsRatio => 'Ratio de dons';

  @override
  String gameLevel(int level, int maxLevel) {
    return 'Niveau : $level/$maxLevel';
  }

  @override
  String get gameHeroes => 'Héros';

  @override
  String get gameEquipment => 'Équipements';

  @override
  String get gameHeroesEquipments => 'Équipements de héros';

  @override
  String get gameTroops => 'Troupes';

  @override
  String get gameActiveSuperTroops => 'Super Troupes Actives';

  @override
  String get gamePets => 'Familiers';

  @override
  String get gameSiegeMachines => 'Engins de siège';

  @override
  String get gameSpells => 'Sorts';

  @override
  String get gameAchievements => 'Succès';

  @override
  String get gameClanGames => 'Jeux de clan';

  @override
  String get gameSeasonPass => 'Pass de saison';

  @override
  String get gameCreatorCode => 'Code créateur : ClashKing';

  @override
  String get gameCreatorCodeDescription =>
      'Touchez pour info • Soutenez-nous gratuitement !';

  @override
  String get gameCreatorCodeDialogTitle => 'Soutenir ClashKing';

  @override
  String get gameCreatorCodeDialogDescription =>
      'Utiliser notre code créateur aide à financer le développement, garde l\'app & bot gratuits pour tous, et nous permet d\'ajouter de nouvelles fonctionnalités.\n\nNous recevons 5% de ce que vous dépensez en jeu, mais cela ne vous coûte rien de plus - utilisez simplement \"ClashKing\" comme code créateur dans la boutique Clash of Clans !';

  @override
  String get gameCreatorCodeDialogButton => 'Utiliser le Code Créateur';

  @override
  String get clanTitle => 'Clan';

  @override
  String get clanSearchTitle => 'Rechercher un clan';

  @override
  String get clanSearchPlaceholder => 'Nom ou tag du clan';

  @override
  String get clanNone => 'Aucun clan';

  @override
  String get clanJoinToUnlock =>
      'Rejoins un clan pour débloquer de nouvelles fonctionnalités.';

  @override
  String get clanMembers => 'Membres';

  @override
  String get clanWarFrequency => 'Fréquence de guerre';

  @override
  String get clanMinimumMembers => 'Membres minimum';

  @override
  String get clanMaximumMembers => 'Membres maximum';

  @override
  String get clanLocation => 'Localisation';

  @override
  String get clanMinimumPoints => 'Points de clan minimum';

  @override
  String get clanMinimumLevel => 'Niveau de clan minimum';

  @override
  String get clanInviteOnly => 'Invitation uniquement';

  @override
  String get clanOpened => 'Ouvert';

  @override
  String get clanClosed => 'Fermé';

  @override
  String get clanRoleLeader => 'Chef';

  @override
  String get clanRoleCoLeader => 'Adjoint';

  @override
  String get clanRoleElder => 'Aîné';

  @override
  String get clanRoleMember => 'Membre';

  @override
  String get clanWarFrequencyAlways => 'Toujours';

  @override
  String get clanWarFrequencyNever => 'Jamais';

  @override
  String get clanWarFrequencyUnknown => 'Inconnu';

  @override
  String get clanWarFrequencyOncePerWeek => '1/semaine';

  @override
  String get clanWarFrequencyMoreThanOncePerWeek => 'Plus de 1/semaine';

  @override
  String get clanWarFrequencyRarely => 'Rarement';

  @override
  String get timeHourIndicator => 'h';

  @override
  String timeDaysAgo(int days) {
    return 'Il y a $days jours';
  }

  @override
  String timeDayAgo(int day) {
    return 'Il y a $day jour';
  }

  @override
  String timeHourAgo(int hour) {
    return 'Il y a $hour heure';
  }

  @override
  String timeHoursAgo(int hours) {
    return 'Il y a $hours heures';
  }

  @override
  String timeMinuteAgo(int minute) {
    return 'Il y a $minute minute';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return 'Il y a $minutes minutes';
  }

  @override
  String get timeJustNow => 'À l\'instant';

  @override
  String get timeEndedJustNow => 'Terminé à l\'instant';

  @override
  String timeEndedMinutesAgo(int minutes) {
    return 'Terminé depuis $minutes minutes';
  }

  @override
  String timeEndedHoursAgo(int hours) {
    return 'Terminé depuis $hours heures';
  }

  @override
  String timeEndedDaysAgo(int days) {
    return 'Terminé depuis $days jours';
  }

  @override
  String timeStartsIn(String time) {
    return 'Début dans $time';
  }

  @override
  String timeStartsAt(String time) {
    return 'Débute à $time';
  }

  @override
  String timeEndsIn(String time) {
    return 'Fin dans $time';
  }

  @override
  String timeEndsAt(String time) {
    return 'Se termine à $time';
  }

  @override
  String get legendsTitle => 'Ligue légende';

  @override
  String get legendsNotInLeague => 'Pas en ligue légende';

  @override
  String get legendsNoDataToday =>
      'Pas de données pour la ligue légende aujourd\'hui';

  @override
  String legendsStartDescription(String trophies) {
    return 'Tu as commencé la journée avec $trophies trophées.';
  }

  @override
  String legendsNoRankLocalDescription(String country, int trophies) {
    return 'Tu n\'es actuellement pas classé ($country) avec $trophies trophées.';
  }

  @override
  String legendsRankLocalDescription(int rank, String country, int trophies) {
    return 'Tu es actuellement classé $rank ($country) avec $trophies trophées.';
  }

  @override
  String legendsGainDescription(int trophies) {
    return 'Tu as gagné $trophies trophées aujourd\'hui.';
  }

  @override
  String legendsLossDescription(int trophies) {
    return 'Tu as perdu $trophies trophées aujourd\'hui.';
  }

  @override
  String legendsNoGlobalRankDescription(int trophies) {
    return 'Tu n\'es actuellement pas classé mondialement avec $trophies trophées.';
  }

  @override
  String legendsGlobalRankDescription(int rank, int trophies) {
    return 'Tu es actuellement classé $rank mondialement avec $trophies trophées.';
  }

  @override
  String get legendsNoRank => 'Non classé';

  @override
  String get legendsBestTrophies => 'Plus haut trophées';

  @override
  String get legendsMostAttacks => 'Plus d\'attaques';

  @override
  String get legendsLastSeason => 'Dernière saison';

  @override
  String get legendsBestRank => 'Meilleur classement';

  @override
  String get legendsTrophiesBySeason => 'Trophées par saison';

  @override
  String get legendsEosTrophies => 'Trophées en fin de saison';

  @override
  String get legendsEosDetails => 'Détails de fin de saison';

  @override
  String get legendsInaccurateTitle => 'Données erronnées ?';

  @override
  String get legendsInaccurateIntro =>
      'En raison des limitations de l\'API de Clash of Clans, nos données peuvent ne pas toujours être parfaitement précises. Voici pourquoi :\n';

  @override
  String get legendsInaccurateApiDelayTitle => '1. Délai de l\'API : ';

  @override
  String get legendsInaccurateApiDelayBody =>
      'L\'API peut prendre jusqu\'à 5 minutes pour se mettre à jour, ce qui provoque un décalage dans l\'affichage des changements de trophées en temps réel.\n';

  @override
  String get legendsInaccurateConcurrentTitle =>
      '2. Changements simultanés : \n';

  @override
  String get legendsInaccurateMultipleAttacksTitle =>
      '- Attaques/Défenses multiples : ';

  @override
  String get legendsInaccurateMultipleAttacksBody =>
      'Si plusieurs attaques ou défenses se produisent en succession rapide, l\'API peut afficher des résultats combinés (par exemple, +68 ou -68).\n';

  @override
  String get legendsInaccurateSimultaneousTitle =>
      '- Attaque et défense simultanées : ';

  @override
  String get legendsInaccurateSimultaneousBody =>
      'Si une attaque et une défense se produisent en même temps, tu pourrais voir un résultat mixte (par exemple, +4).\n';

  @override
  String get legendsInaccurateNetGainTitle => '3. Gain/Perte net(te) : ';

  @override
  String get legendsInaccurateNetGainBody =>
      'Malgré les problèmes de synchronisation, le gain ou la perte net(te) pour la journée est précis(e). ';

  @override
  String get legendsInaccurateConclusion =>
      'Ces limitations sont communes à tous les outils utilisant l\'API de Clash of Clans. Nous ne pouvons malheureusement pas résoudre ce problème car cela dépend de Supercell. Nous faisons de notre mieux pour compenser ces limites et fournir des résultats les plus proches de la réalité possible. Merci de ta compréhension !';

  @override
  String get statsSeasonStats => 'Statistiques de saison';

  @override
  String get statsByDay => 'Par jour';

  @override
  String get statsBySeason => 'Par saison';

  @override
  String statsDayIndex(int index) {
    return 'Jour $index';
  }

  @override
  String statsIndexDays(int index) {
    return '$index jours';
  }

  @override
  String statsSeasonDate(String date) {
    return 'Saison $date';
  }

  @override
  String get statsAllTownHalls => 'Tous Hôtels de ville';

  @override
  String get statsMembers => 'Statistiques des membres';

  @override
  String get todoTitle => 'Tâches du jour';

  @override
  String get todoExplanationTitle => 'Le calcul des tâches';

  @override
  String get todoExplanationIntro =>
      'Le pourcentage de réalisation des tâches est calculé en fonction des activités suivantes avec des pondérations spécifiques :';

  @override
  String get todoExplanationLegendsTitle => 'Ligue légende :';

  @override
  String get todoExplanationLegends =>
      'Poids de 8 points par compte, 1 attaque = 1 point.';

  @override
  String get todoExplanationRaidsTitle => 'Raids :';

  @override
  String get todoExplanationRaids =>
      'Poids de 5 points par compte (ou 6 si la dernière attaque a été débloquée), 1 attaque = 1 point.';

  @override
  String get todoExplanationClanWarsTitle => 'Guerres de Clan :';

  @override
  String get todoExplanationClanWars =>
      'Poids de 2 points par compte, 1 attaque = 1 point.';

  @override
  String get todoExplanationCwlTitle => 'Ligue de Clan :';

  @override
  String get todoExplanationCwl =>
      'Poids de 1 point par compte, 1 attaque = 1 point. La ligue ne peut pas être suivie si le joueur n\'est pas dans son clan de ligue.';

  @override
  String get todoExplanationPassAndGamesTitle =>
      'Pass de Saison & Jeux de clans :';

  @override
  String get todoExplanationPassAndGames =>
      'Poids de 2 points chacun par compte. Le ratio est basé sur le nombre de jours restants (1 mois pour le pass et 6 jours pour les jeux). En vert = dans les temps pour finir le pass ou les jeux, en rouge = en retard.';

  @override
  String get todoExplanationConclusion =>
      'Le pourcentage final est calculé en divisant le total des actions réalisées pendant les événements en cours par le total des actions requises. Les comptes inactifs depuis plus de 14 jours sont exclus du calcul.';

  @override
  String todoAccountsNumber(int number) {
    return '$number comptes';
  }

  @override
  String todoAccountsNumberActive(int number) {
    return '$number comptes actifs';
  }

  @override
  String todoAccountsNumberInactive(int number) {
    return '$number comptes inactifs';
  }

  @override
  String get todoAccountsActive => 'Comptes actifs';

  @override
  String get todoAccountsInactive => 'Comptes inactifs';

  @override
  String get todoAccountsNoInactive => 'Aucun compte inactif.';

  @override
  String get todoAccountsNoActive => 'Aucun compte actif.';

  @override
  String todoAttacksLeftDescription(int attacks, String type) {
    return 'Attaques restantes';
  }

  @override
  String todoDefensesLeftDescription(int defenses, String type) {
    return 'Défenses restantes';
  }

  @override
  String todoNoAttacksLeftDescription(String type) {
    return 'Aucune attaque restante';
  }

  @override
  String todoPointsLeftDescription(int points, String type) {
    return 'Points restants';
  }

  @override
  String todoPointsLeftDescriptionNoPoints(String type) {
    return 'Aucun point restant';
  }

  @override
  String get warTitle => 'Guerre';

  @override
  String get warFrequency => 'Fréquence de guerre';

  @override
  String get warParticipation => 'Participation à la guerre';

  @override
  String get warLeague => 'Guerre/Ligue';

  @override
  String get warHistory => 'Historique de guerre';

  @override
  String get warLog => 'Journal';

  @override
  String warLogClosed(String clan) {
    return 'Le journal de guerre est privé.';
  }

  @override
  String get warStats => 'Statistiques de guerre';

  @override
  String get warOngoing => 'Guerre en cours';

  @override
  String warIsNotInWar(String clan) {
    return '$clan n\'est pas en guerre.';
  }

  @override
  String get warAskForWar =>
      'Contacte le chef ou un adjoint pour lancer une guerre.';

  @override
  String get warAskForWarLogOpening =>
      'Contacte un chef ou un adjoint pour ouvrir le journal de guerre.';

  @override
  String get warEnded => 'Terminée';

  @override
  String get warPreparation => 'Préparation';

  @override
  String get warPerfectWar => 'Perf map';

  @override
  String get warVictory => 'Victoire';

  @override
  String get warDefeat => 'Défaite';

  @override
  String get warDraw => 'Égalité';

  @override
  String get warTeamSize => 'Taille de l\'équipe';

  @override
  String get warMyTeam => 'Mon équipe';

  @override
  String get warEnemiesTeam => 'Ennemis';

  @override
  String get warClanDraw => 'Les deux clans sont à égalité';

  @override
  String get warStateOfTheWar => 'État de la guerre';

  @override
  String warStarsNeededToTakeTheLead(
      String clan, int star, int stars2, String percent) {
    return '$clan a besoin de $star étoile(s) supplémentaire(s) ou $stars2 étoiles et $percent% pour prendre l\'avantage.';
  }

  @override
  String warStarsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan a besoin de $percent% ou 1 étoile supplémentaire pour prendre l\'avantage';
  }

  @override
  String get warNoDataAvailableForThisWar =>
      'Aucune donnée disponible pour cette guerre';

  @override
  String get warCalculatorFast => 'Calculatrice rapide';

  @override
  String warCalculatorAnswer(String percentNeeded, String result) {
    return 'Pour obtenir un taux de destruction de $percentNeeded%, un total de $result% est nécessaire.';
  }

  @override
  String get warCalculatorNeededOverall => '% total nécessaire';

  @override
  String get warCalculatorCalculate => 'Calculer';

  @override
  String get warAttacksTitle => 'Attaques';

  @override
  String get warAttacksNone => 'Aucune attaque';

  @override
  String get warAttacksBest => 'Meilleures attaques';

  @override
  String get warAttacksCount => 'Nombre d\'attaques';

  @override
  String get warAttacksMissed => 'Attaques manquées';

  @override
  String warAttacksNumber(int number_time, int number_war) {
    return 'Nombre d\'attaques';
  }

  @override
  String warAttacksAverageStars(String stars) {
    return 'Moyenne d\'étoiles d\'attaque : $stars';
  }

  @override
  String warAttacksAverageDestruction(String percent) {
    return 'Moyenne de destruction d\'attaque : $percent%';
  }

  @override
  String get warDefensesTitle => 'Défenses';

  @override
  String get warDefensesNone => 'Aucune défense';

  @override
  String get warDefensesBest => 'Meilleures défenses';

  @override
  String warDefensesBestOutOf(int number) {
    return 'Meilleure défense sur $number';
  }

  @override
  String warDefensesNumber(int number_time, int number_war) {
    return 'Nombre de défenses';
  }

  @override
  String warDefensesAverageStars(double stars) {
    return 'Moyenne d\'étoiles de défense : $stars';
  }

  @override
  String warDefensesAverageDestruction(String percent) {
    return 'Moyenne de destruction de défense : $percent%';
  }

  @override
  String get warStarsTitle => 'Étoiles';

  @override
  String get warStarsAverage => 'Moyenne d\'étoiles';

  @override
  String get warStarsNumber => 'Nombre d\'étoiles';

  @override
  String get warStarsOne => '1 étoile';

  @override
  String get warStarsTwo => '2 étoiles';

  @override
  String get warStarsThree => '3 étoiles';

  @override
  String get warStarsZero => '0 étoile';

  @override
  String get warStarsBestPerformance => 'Meilleure performance';

  @override
  String get warDestructionTitle => 'Destruction';

  @override
  String get warDestructionAverage => 'Moyenne de destruction';

  @override
  String get warDestructionRate => 'Taux de destruction';

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
    return 'Ton clan a une moyenne de $stars étoiles par attaque pour les 50 dernières guerres. Cela représente $percent% des étoiles possibles.';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return 'Ton clan a une moyenne de $percent% de taux de destruction pour les 50 dernières guerres.';
  }

  @override
  String get warPositionMap => 'Position sur la carte';

  @override
  String get warPositionAbbr => 'Pos';

  @override
  String get warPositionOrder => 'Ordre';

  @override
  String get warOpponentTownhall => 'HDV adversaire';

  @override
  String get warOpponentLowerTownhall => 'HDV inférieur';

  @override
  String get warOpponentUpperTownhall => 'HDV supérieur';

  @override
  String get warOpponentEqualThLevel => 'Niveau d\'HDV égal';

  @override
  String get warOpponentSelectMembersThLevel => 'Niveau d\'HDV des membres';

  @override
  String get warOpponentSelectOpponentsThLevel =>
      'Niveau d\'HDV des adversaires';

  @override
  String warFiltersLastXwars(int number) {
    return 'Dernières $number guerres';
  }

  @override
  String get warFiltersFriendly => 'Amicale';

  @override
  String get warFiltersRandom => 'Classique';

  @override
  String get warVisibilityToggleTownHall =>
      'Cacher/Afficher les stats des anciens niveaux d\'HDV';

  @override
  String get warEventsTitle => 'Événements';

  @override
  String get warEventsNewest => 'Plus récente';

  @override
  String get warEventsOldest => 'Plus ancienne';

  @override
  String get warStatusReady => 'Participe';

  @override
  String get warStatusUnready => 'Ne participe pas';

  @override
  String get warStatusMissed => 'Manquée';

  @override
  String get warAbbreviationAvg => 'Moy';

  @override
  String get warAbbreviationAvgPercentage => 'Moy%';

  @override
  String get cwlTitle => 'LDC';

  @override
  String get cwlClanWarLeague => 'Ligue de clan';

  @override
  String get cwlOngoing => 'Ligue en cours';

  @override
  String get cwlRounds => 'Tours';

  @override
  String cwlRoundNumber(int number) {
    return 'Tour $number';
  }

  @override
  String cwlCurrentRound(int round) {
    return 'Nous sommes actuellement au tour $round.';
  }

  @override
  String cwlRank(int rank) {
    return 'Ton clan est actuellement classé numéro $rank.';
  }

  @override
  String cwlStars(int stars) {
    return 'Ton clan a un total de $stars étoiles.';
  }

  @override
  String cwlDestructionPercentage(String percent) {
    return 'Ton clan a un taux de destruction de $percent%.';
  }

  @override
  String cwlTotalAttacks(int attacks, int totalAttacks) {
    return 'Attaques totales : $attacks/$totalAttacks';
  }

  @override
  String get joinLeaveTitle => 'Historique d\'arrivées/départs';

  @override
  String get joinLeaveJoin => 'Arrivée';

  @override
  String get joinLeaveLeave => 'Départ';

  @override
  String get joinLeaveReset => 'Réinitialiser';

  @override
  String get joinLeaveJoins => 'Arrivées';

  @override
  String get joinLeaveLeaves => 'Départs';

  @override
  String get joinLeaveUniquePlayers => 'Joueurs uniques';

  @override
  String get joinLeaveMovingPlayers => 'Joueurs mobiles';

  @override
  String get joinLeaveMostMovingPlayers => 'Joueurs les plus mobiles';

  @override
  String get joinLeaveStillInClan => 'Toujours dans le clan';

  @override
  String get joinLeaveLeftForever => 'Parti définitivement';

  @override
  String get joinLeaveRejoinedPlayers => 'Joueurs revenus';

  @override
  String get joinLeaveAvgTimeJoinLeave => 'Temps moyen entre arrivée/départ';

  @override
  String get joinLeavePeakHour => 'Heure de pointe';

  @override
  String joinLeaveNumberDescription(int number, String date) {
    return '$number joueurs ont quitté le clan durant la saison actuelle ($date).';
  }

  @override
  String joinLeaveJoinNumberDescription(int number, String date) {
    return '$number joueurs ont rejoint le clan durant la saison actuelle ($date).';
  }

  @override
  String joinLeaveMovingNumberDescription(int number, String date) {
    return 'Joueurs mobiles';
  }

  @override
  String joinLeaveUniqueNumberDescription(int number, String date) {
    return 'Joueurs uniques';
  }

  @override
  String joinLeaveStillInClanNumberDescription(int number) {
    return 'Toujours dans le clan';
  }

  @override
  String joinLeaveLeftClanNumberDescription(int number) {
    return 'Ont quitté le clan';
  }

  @override
  String joinLeaveLeftOnAt(String date, String time) {
    return 'Est parti le $date à $time.';
  }

  @override
  String joinLeaveJoinedOnAt(String date, String time) {
    return 'A rejoint le $date à $time.';
  }

  @override
  String get raidsTitle => 'Raids';

  @override
  String get raidsLast => 'Derniers raids';

  @override
  String get raidsOngoing => 'Raids en cours';

  @override
  String get raidsDistrictsDestroyed => 'Districts détruits';

  @override
  String get raidsCompleted => 'Raids complétés';

  @override
  String get searchNoResult => 'Aucun résultat.';

  @override
  String get maintenanceTitle => 'Maintenance';

  @override
  String get maintenanceDescription =>
      'L\'application est actuellement en maintenance. Merci de réessayer plus tard.';

  @override
  String get downloadTooltip => 'Télécharger';

  @override
  String get downloadInProgress => 'Téléchargement en cours...';

  @override
  String downloadSuccess(String path) {
    return 'Téléchargement réussi';
  }

  @override
  String get downloadError => 'Erreur de téléchargement';

  @override
  String get dashboardTitle => 'Tableau de bord';

  @override
  String get toolsTitle => 'Outils';

  @override
  String get navigationTeam => 'Équipes';

  @override
  String get navigationStatistics => 'Statistiques';

  @override
  String get versionDevice => 'Version & Appareil';

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
  String get betaFeature => 'Fonctionnalité Bêta';

  @override
  String get betaLabel => 'BÊTA';

  @override
  String get betaDescription =>
      'Cette fonctionnalité est actuellement en version bêta, elle peut donc contenir des bugs ou être incomplète. Nous travaillons activement sur des améliorations et vos retours sont les bienvenus. N\'hésitez pas à partager vos idées et à signaler tout problème sur notre serveur Discord pour nous aider à l\'améliorer.';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsSelectLanguage => 'Sélectionne une langue';

  @override
  String get settingsToggleTheme => 'Changer de thème';

  @override
  String get faqTitle => 'FAQ';

  @override
  String get faqSubtitle => 'Foire aux questions';

  @override
  String get faqIsThisFromSupercell =>
      'Est-ce que cette application a été créée par Supercell ?';

  @override
  String get faqFanContentPolicy =>
      'Ce matériel n\'est pas officiel et n\'est pas approuvé par Supercell. Pour plus d\'informations, consultez la politique relative au contenu des fans de Supercell : www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate =>
      'Pourquoi les données ne sont-elles pas toujours exactes ou manquantes ?';

  @override
  String get faqClanNotTracked => 'Clan non suivi';

  @override
  String get faqClanNotTrackedAnswer =>
      'ClashKing ne peut obtenir ces informations que si le clan est suivi. Si ton clan ne semble pas être suivi, merci de l\'inviter sur un serveur Discord et d\'utiliser la commande /addclan. Nous espérons rendre cette fonctionnalité bientôt disponible dans l\'application.';

  @override
  String get faqTrackingDown => 'Suivi en panne';

  @override
  String get faqTrackingDownAnswer =>
      'Le tracking peut cesser de fonctionner pendant un certain temps. C\'est pourquoi il peut parfois y avoir des trous dans vos données. Nous faisons de notre mieux pour améliorer cela.';

  @override
  String get faqApiLimitation => 'Limitation de l\'API Clash of Clans';

  @override
  String get faqApiLimitationAnswer =>
      'Certaines données sont fournies par Clash of Clans et leur API présente certaines limitations. C\'est le cas du suivi des légendes où il regroupe parfois les gains et les pertes de trophées comme s\'il s\'agissait d\'une seule et même attaque. Ou encore, pourquoi nous n\'avons aucune information sur le niveau de vos bâtiments.';

  @override
  String get faqSupportWork => 'Comment puis-je soutenir votre travail ?';

  @override
  String get faqSupportWorkAnswer =>
      'Il existe plusieurs façons de nous soutenir :';

  @override
  String get faqUseCodeClashKing => 'Utilise le code \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Soutiens-nous sur Patreon';

  @override
  String get faqShareTheApp => 'Partage l\'application avec tes amis';

  @override
  String get faqRateTheApp => 'Note l\'application sur le store';

  @override
  String get faqHelpUsTranslate => 'Aide-nous à traduire l\'application';

  @override
  String get faqHowToInviteTheBot =>
      'Comment puis-je inviter votre bot sur mon serveur Discord ?';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'Tu peux inviter notre bot sur ton serveur en cliquant sur le bouton ci-dessous. Tu devras disposer de l\'autorisation \"Gérer le serveur\" pour ajouter le bot.';

  @override
  String get faqInviteTheBot => 'Inviter le bot ClashKing';

  @override
  String get faqNeedHelp =>
      'J\'ai besoin d\'aide ou j\'aimerais faire une suggestion. Comment puis-je vous contacter ?';

  @override
  String get faqNeedHelpAnswer =>
      'Tu peux rejoindre notre serveur Discord et demander de l\'aide, y faire un retour ou nous envoyer un e-mail à devs@clashk.ing. Tu peux nous écrire en français ou en anglais !';

  @override
  String get faqSendEmail => 'Envoyer un e-mail';

  @override
  String get faqJoinDiscord => 'Rejoindre le serveur Discord';

  @override
  String get faqCannotOpenMailClient =>
      'Pour une raison quelconque, nous ne pouvons pas ouvrir ton client de messagerie. Nous avons copié l\'adresse e-mail pour toi. Tu peux rédiger un e-mail et coller l\'adresse dans le champ du destinataire.';

  @override
  String get translationHelpUsTranslate => 'Nous aider à traduire';

  @override
  String get translationSuggestFeatures => 'Proposer des fonctionnalités';

  @override
  String get translationThankYou => 'Merci !';

  @override
  String get translationThankYouContent =>
      'Un grand merci à tous nos incroyables traducteurs qui nous aident à rendre cette application accessible à plus de personnes à travers le monde !';

  @override
  String get translationHelpTranslateContent =>
      'Tu peux nous aider à traduire l\'application sur Crowdin. Si ta langue n\'est pas disponible sur Crowdin, n\'hésite pas à la demander sur notre serveur Discord. Merci beaucoup pour ton aide !';

  @override
  String get translationHelpTranslateButton => 'Aider à traduire sur Crowdin';

  @override
  String get translationCurrentTranslators => 'Traducteurs actuels';
}
