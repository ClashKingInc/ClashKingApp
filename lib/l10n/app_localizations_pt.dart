// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'ClashKing';

  @override
  String get appDescription =>
      'Your ultimate Clash of Clans companion for tracking stats, managing clans, and analyzing performance.';

  @override
  String get generalLoading => 'Carregando...';

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
  String get generalRetry => 'Retry';

  @override
  String get generalTryAgain => 'Try again';

  @override
  String get generalCancel => 'Cancel';

  @override
  String get generalOk => 'OK';

  @override
  String get generalApply => 'Aplicar';

  @override
  String get generalConfirm => 'Confirm';

  @override
  String get generalManage => 'Gerir';

  @override
  String get generalSettings => 'Definições';

  @override
  String get generalCopiedToClipboard => 'Copiado para a área de transferência';

  @override
  String get generalComingSoon => 'Em breve!';

  @override
  String generalLastRefresh(String time) {
    return 'Last refresh: $time';
  }

  @override
  String generalRefreshFailed(String error) {
    return 'Refresh failed: $error';
  }

  @override
  String get generalAll => 'Tudo';

  @override
  String get generalTotal => 'Total';

  @override
  String get generalBest => 'Melhor';

  @override
  String get generalWorst => 'Pior';

  @override
  String get generalAverage => 'Média';

  @override
  String get generalRemaining => 'Restantes';

  @override
  String get generalActive => 'Active';

  @override
  String get generalInactive => 'Inactive';

  @override
  String get generalStarted => 'Começado';

  @override
  String get generalEnded => 'Terminou';

  @override
  String get generalRole => 'Cargo';

  @override
  String get generalStats => 'Estatísticas';

  @override
  String get generalFullStats => 'Full Stats';

  @override
  String get generalDetails => 'Detalhes';

  @override
  String get generalHistory => 'Histórico';

  @override
  String get generalFilters => 'Filtros';

  @override
  String get generalNotSet => 'Não definido';

  @override
  String get generalWarning => 'Atenção';

  @override
  String get generalNoDataAvailable => 'Sem dados disponíveis.';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authLogin => 'Iniciar Sessão';

  @override
  String get authLogout => 'Terminar sessão';

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
  String get authConfirmLogout => 'Are you sure you want to log out?';

  @override
  String get authDiscordTitle => 'Discord';

  @override
  String get authDiscordSignIn => 'Iniciar sessão com Discord';

  @override
  String get authDiscordContinue => 'Continue with Discord';

  @override
  String get authDiscordDescription =>
      'Sync your data with ClashKing Bot and unlock the full potential of ClashKing!';

  @override
  String get authEmailTitle => 'Email';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'Enter your email address';

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
  String get authPasswordHint => 'Enter your password';

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
  String get authPasswordForgotDescription =>
      'Enter your email address and we\'ll send you a 6-digit code to reset your password.';

  @override
  String get authPasswordResetSend => 'Send Reset Code';

  @override
  String get authPasswordResetSent => 'Code Sent!';

  @override
  String get authPasswordResetSentDescription =>
      'We\'ve sent a 6-digit reset code to your email address. Please check your inbox and use the code to reset your password.';

  @override
  String get authPasswordReset => 'Reset Password';

  @override
  String get authPasswordResetDescription =>
      'Enter your email, the 6-digit code from the email, and your new password below.';

  @override
  String get authPasswordNew => 'New Password';

  @override
  String get authPasswordConfirmHint => 'Re-enter your new password';

  @override
  String get authPasswordResetConfirm => 'Reset Password';

  @override
  String get authPasswordResetSuccess =>
      'Password reset successful! You can now log in.';

  @override
  String get authPasswordResetContinue => 'Continue to Reset Password';

  @override
  String get authPasswordResetCode => 'Reset Code';

  @override
  String get authPasswordResetCodeHint =>
      'Enter the 6-digit code from your email';

  @override
  String get authPasswordResetCodeRequired => 'Please enter the reset code';

  @override
  String get authPasswordResetCodeInvalid =>
      'Please enter a valid 6-digit code';

  @override
  String get authBackToLogin => 'Back to Login';

  @override
  String get authUsernameLabel => 'Nome de utilizador';

  @override
  String get authUsernameRequired => 'Por favor, insira um nome de utilizador';

  @override
  String get authUsernameTooShort => 'Username must be at least 3 characters';

  @override
  String get authErrorConnection =>
      'Ocorreu um erro. Por favor, verifique a sua conexão de internet e tente novamente.';

  @override
  String get authErrorConnectionRelaunch =>
      'Ocorreu um erro. Por favor, verifique a sua conexão de internet e reinicie a aplicação.';

  @override
  String get authErrorEmailAlreadyRegistered =>
      'This email is already registered. Please try logging in instead.';

  @override
  String get authErrorEmailAlreadyPending =>
      'A verification email was already sent to this address. Please check your email or try resending.';

  @override
  String get authErrorEmailInvalidFormat =>
      'Please enter a valid email address.';

  @override
  String get authErrorPasswordWeak =>
      'Password is too weak. Please use a stronger password.';

  @override
  String get authErrorUsernameInvalid =>
      'Username is invalid. Please use only letters, numbers, and underscores.';

  @override
  String get authErrorUsernameExists =>
      'This username is already taken. Please choose a different one.';

  @override
  String get authErrorRegistrationFailed =>
      'Registration failed. Please try again later.';

  @override
  String get authErrorEmailSendFailed =>
      'Failed to send verification email. Please try again later.';

  @override
  String get authErrorRateLimited =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get authErrorServerUnavailable =>
      'Server is temporarily unavailable. Please try again later.';

  @override
  String get authAccountManagement =>
      'Add, remove, and reorder your Clash of Clans accounts. Verify your accounts to access all features.';

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
  String get authEmailVerificationTitle => 'Verify Email';

  @override
  String get authEmailVerificationCheckEmail => 'Check Your Email';

  @override
  String get authEmailVerificationSentTo =>
      'We\'ve sent a verification email to:';

  @override
  String get authEmailVerificationInstructions =>
      'Click the link in the email to verify your account. If you don\'t see the email, check your spam folder.';

  @override
  String get authEmailVerificationResend => 'Resend Verification Email';

  @override
  String get authEmailVerificationResendSuccess =>
      'Verification email resent successfully! Please check your email.';

  @override
  String get authEmailVerificationResendFailed =>
      'Failed to resend verification email. Please try again.';

  @override
  String get authEmailVerificationBackToLogin => 'Back to Login';

  @override
  String get authEmailVerificationDevToken =>
      'I have a verification token (Dev)';

  @override
  String get authEmailVerificationDevMode =>
      'Development Mode - Manual Token Input:';

  @override
  String get authEmailVerificationTokenLabel => 'Verification Token';

  @override
  String get authEmailVerificationTokenRequired =>
      'Verification token is required';

  @override
  String get authEmailVerificationVerifyButton => 'Verify Email';

  @override
  String get authEmailVerificationExpired =>
      'Verification expired. Please register again.';

  @override
  String get authEmailVerificationAlreadyVerified =>
      'This email is already verified. Please try logging in instead.';

  @override
  String get authEmailVerificationNoToken =>
      'No pending verification found. Please register first.';

  @override
  String get authEmailVerificationVerifying => 'Verifying your email...';

  @override
  String get authEmailVerificationCodeInstructions =>
      'Enter the 6-digit code sent to your email:';

  @override
  String get authEmailVerificationCodeRequired =>
      'Please enter the 6-digit verification code';

  @override
  String get authEmailVerificationVerify => 'Verify Code';

  @override
  String get helpTitle => 'Need help?';

  @override
  String get helpJoinDiscord => 'Join Discord';

  @override
  String get helpEmailUs => 'Email Us';

  @override
  String get accountsWelcome => 'Bem-vindo!';

  @override
  String get accountsWelcomeMessage =>
      'Por favor, adicione uma ou mais contas de Clash of Clans ao seu perfil. Pode adicionar ou remover contas depois.';

  @override
  String get accountsManageTitle => 'Manage your accounts';

  @override
  String get accountsNoneFound =>
      'Nenhuma conta vinculada ao seu perfil foi encontrada';

  @override
  String get accountsPlayerTag => 'Player Tag (#ABC123)';

  @override
  String get accountsEnterPlayerTag => 'Introduza a tag de jogador';

  @override
  String get accountsAdd => 'Adicionar conta';

  @override
  String get accountsDelete => 'Apagar conta';

  @override
  String get accountsApiToken => 'Token API de conta';

  @override
  String get accountsEnterApiToken =>
      'Por favor, insira o token de API da conta para confirmar ser sua. Pode encontrá-lo no jogo em Configurações > Mais configurações > Token de API.';

  @override
  String get accountsFillAllFields => 'Please fill all fields.';

  @override
  String get accountsErrorTagNotExists =>
      'A tag de jogador inserida não existe.';

  @override
  String accountsErrorAlreadyLinked(Object tag) {
    return 'A tag de jogador já está vinculada a alguém.';
  }

  @override
  String get accountsErrorAlreadyLinkedToYou =>
      'A tag de jogador já está vinculada a si.';

  @override
  String get accountsErrorWrongApiToken =>
      'O token da API inserido está incorreto';

  @override
  String get accountsErrorFailedToAdd =>
      'Failed to add the account. Please try again later.';

  @override
  String get accountsErrorFailedToDelete =>
      'Falha ao apagar link. Por favor, tente novamente mais tarde.';

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
  String get errorLoadingVersion => 'Erro ao carregar versão';

  @override
  String get errorCannotOpenLink => 'Não podemos abrir este link.';

  @override
  String get errorExitAppToOpenClash =>
      'Está prestes a sair da aplicação para abrir Clash of Clans.';

  @override
  String get playerSearchTitle => 'Procurar jogador';

  @override
  String get playerSearchPlaceholder => 'Nome ou tag de jogador';

  @override
  String playerLastActive(String date) {
    return 'Última vez ativo: $date';
  }

  @override
  String get playerNotTracked =>
      'Este jogador não está rastreado. Dados poderão ser imprecisos.';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'O seu clã é \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(
      String ratio, String donations, String received) {
    return 'A sua proporção de doações é $ratio. Doou $donations tropas e recebeu $received tropas.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'A sua preferência de guerra é \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'Tem $stars estrelas de guerra.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'Tem $trophies troféus. Está atualmente em $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'O seu centro de vila é $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'A sua casa do construtor é nível $level e tem $trophies troféus.';
  }

  @override
  String get gameBaseHome => 'Base principal';

  @override
  String get gameBaseBuilder => 'Base do Construtor';

  @override
  String get gameClanCapital => 'Capital do clã';

  @override
  String get gameTownHall => 'CV';

  @override
  String get gameTownHallLevel => 'Nível do CV';

  @override
  String gameTownHallLevelNumber(int level) {
    return 'Centro de vila $level';
  }

  @override
  String gameTHLevel(int level) {
    return 'CV$level';
  }

  @override
  String get gameExpLevel => 'Nível de experiência';

  @override
  String get gameTrophies => 'Troféus';

  @override
  String get gameBuilderBaseTrophies => 'Troféus da CC';

  @override
  String get gameDonations => 'Doações';

  @override
  String get gameDonationsReceived => 'Doações recebidas';

  @override
  String get gameDonationsRatio => 'Proporção de doações';

  @override
  String gameLevel(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get gameHeroes => 'Heróis';

  @override
  String get gameEquipment => 'Equipamentos';

  @override
  String get gameHeroesEquipments => 'Equipamentos de Heróis';

  @override
  String get gameTroops => 'Tropas';

  @override
  String get gameActiveSuperTroops => 'Supertropas ativas';

  @override
  String get gamePets => 'Animais';

  @override
  String get gameSiegeMachines => 'Máquinas de Cerco';

  @override
  String get gameSpells => 'Feitiços';

  @override
  String get gameAchievements => 'Conquistas';

  @override
  String get gameClanGames => 'Clan Games';

  @override
  String get gameSeasonPass => 'Season Pass';

  @override
  String get gameCreatorCode => 'Código de Criador: ClashKing';

  @override
  String get gameCreatorCodeDescription =>
      'Tap for info • Support us for free!';

  @override
  String get gameCreatorCodeDialogTitle => 'Support ClashKing';

  @override
  String get gameCreatorCodeDialogDescription =>
      'When you use our creator code, you help fund development, keep the app and bot free for everyone, and support the addition of new features.\n\nWe receive 5% of your in-game purchases at no extra cost to you — just enter \"ClashKing\" in the shop of any Supercell game.\n\nThank you for your support!';

  @override
  String get gameCreatorCodeDialogButton => 'Use Creator Code';

  @override
  String get clanTitle => 'Clã';

  @override
  String get clanSearchTitle => 'Procurar clã';

  @override
  String get clanSearchPlaceholder => 'Clan\'s name';

  @override
  String get clanNone => 'Sem clã';

  @override
  String get clanJoinToUnlock =>
      'Entre num clã para desbloquear novos recursos.';

  @override
  String get clanMembers => 'Membros';

  @override
  String get clanWarFrequency => 'Frequência de guerra';

  @override
  String get clanMinimumMembers => 'Membros mínimos';

  @override
  String get clanMaximumMembers => 'Membros máximos';

  @override
  String get clanLocation => 'Localização';

  @override
  String get clanMinimumPoints => 'Pontos de clã mínimos';

  @override
  String get clanMinimumLevel => 'Nível mínimo de clã';

  @override
  String get clanInviteOnly => 'Convite apenas';

  @override
  String get clanOpened => 'Aberto';

  @override
  String get clanClosed => 'Fechado';

  @override
  String get clanRoleLeader => 'Líder';

  @override
  String get clanRoleCoLeader => 'Colíder';

  @override
  String get clanRoleElder => 'Ancião';

  @override
  String get clanRoleMember => 'Membro';

  @override
  String get clanWarFrequencyAlways => 'Sempre';

  @override
  String get clanWarFrequencyNever => 'Nunca';

  @override
  String get clanWarFrequencyUnknown => 'Desconhecido';

  @override
  String get clanWarFrequencyOncePerWeek => '1/semana';

  @override
  String get clanWarFrequencyMoreThanOncePerWeek => 'More than 1/week';

  @override
  String get clanWarFrequencyRarely => 'Raramente';

  @override
  String get timeHourIndicator => 'h';

  @override
  String timeDaysAgo(int days) {
    return '$days dias atrás';
  }

  @override
  String timeDayAgo(int day) {
    return '$day dia atrás';
  }

  @override
  String timeHourAgo(int hour) {
    return '$hour hora atrás';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours horas atrás';
  }

  @override
  String timeMinuteAgo(int minute) {
    return '$minute minuto atrás';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes minutos atrás';
  }

  @override
  String get timeJustNow => 'Agora mesmo';

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
    return 'Começa em $time';
  }

  @override
  String timeStartsAt(String time) {
    return 'Começa às $time';
  }

  @override
  String timeEndsIn(String time) {
    return 'Termina em $time';
  }

  @override
  String timeEndsAt(String time) {
    return 'Termina às $time';
  }

  @override
  String get legendsTitle => 'Dados imprecisos?';

  @override
  String get legendsNotInLeague => 'Não está na Liga Lendária';

  @override
  String get legendsNoDataToday =>
      'You\'re not in Legend League, but past seasons are available.';

  @override
  String legendsStartDescription(String trophies) {
    return 'Começou o dia com $trophies troféus.';
  }

  @override
  String legendsNoRankLocalDescription(String country, int trophies) {
    return 'Não está atualmente classificado ($country) com $trophies troféus.';
  }

  @override
  String legendsRankLocalDescription(int rank, String country, int trophies) {
    return 'Está atualmente classificado $rank ($country) com $trophies troféus.';
  }

  @override
  String legendsGainDescription(int trophies) {
    return 'Ganhou $trophies troféus por agora.';
  }

  @override
  String legendsLossDescription(int trophies) {
    return 'Perdeu $trophies troféus por agora.';
  }

  @override
  String legendsNoGlobalRankDescription(int trophies) {
    return 'Não está atualmente classificado globalmente com $trophies troféus.';
  }

  @override
  String legendsGlobalRankDescription(int rank, int trophies) {
    return 'You are currently ranked $rank globally with $trophies trophies.';
  }

  @override
  String get legendsNoRank => 'Sem classificação';

  @override
  String get legendsBestTrophies => 'Melhores troféus';

  @override
  String get legendsMostAttacks => 'Maior número de ataques';

  @override
  String get legendsLastSeason => 'Última temporada';

  @override
  String get legendsBestRank => 'Melhor Rank Global';

  @override
  String get legendsTrophiesBySeason => 'Troféus por temporada';

  @override
  String get legendsEosTrophies => 'Troféus de fim de temporada';

  @override
  String get legendsEosDetails => 'End Of Season Details';

  @override
  String get legendsInaccurateTitle => 'Dados imprecisos?';

  @override
  String get legendsInaccurateIntro =>
      'Devido às limitações da API do Clash of Clãs, nossos dados nem sempre podem ser perfeitamente precisos. Veja o porque:\n';

  @override
  String get legendsInaccurateApiDelayTitle => '1. Atraso da API: ';

  @override
  String get legendsInaccurateApiDelayBody =>
      'A API pode demorar até 5 minutos para atualizar, causando um atraso na reflexão das mudanças de troféus em tempo real.\n';

  @override
  String get legendsInaccurateConcurrentTitle =>
      '2. Alterações simultâneas: \n';

  @override
  String get legendsInaccurateMultipleAttacksTitle =>
      '- Múltiplos Ataques/Defesas: ';

  @override
  String get legendsInaccurateMultipleAttacksBody =>
      'Se múltiplos ataques ou defesas acontecerem em rápida sucessão, a API pode mostrar resultados combinados (Ex., +68 ou -68).\n';

  @override
  String get legendsInaccurateSimultaneousTitle =>
      '- Ataques e Defesas simultâneas: ';

  @override
  String get legendsInaccurateSimultaneousBody =>
      'Se um ataque e uma defesa ocorrerem em simultâneo, poderá ver um resultado misto (Ex., +4).\n';

  @override
  String get legendsInaccurateNetGainTitle => 'Ganho/Perda Líquida: ';

  @override
  String get legendsInaccurateNetGainBody =>
      'Apesar dos problemas de tempo, o ganho ou perda líquida geral do dia é precisa. ';

  @override
  String get legendsInaccurateConclusion =>
      'Estas limitações são comuns em todas as ferramentas que usam a API do Clash of Clans. Nós, infelizmente, não podemos arrumar o que está nas mãos da Supercell. Nós fazemos o nosso melhor para compensar estes limites e providenciar os resultados mais próximos possíveis da realidade. Obrigado pela sua compreensão!';

  @override
  String get statsSeasonStats => 'Estatísticas de temporada';

  @override
  String get statsByDay => 'Por dia';

  @override
  String get statsBySeason => 'Por temporada';

  @override
  String statsDayIndex(int index) {
    return 'Dia $index';
  }

  @override
  String statsIndexDays(int index) {
    return '$index dias';
  }

  @override
  String statsSeasonDate(String date) {
    return 'Temporada $date';
  }

  @override
  String get statsAllTownHalls => 'Todos os centros de vila';

  @override
  String get statsMembers => 'Estatísticas de membros';

  @override
  String get todoTitle => 'Lista de tarefas';

  @override
  String get todoExplanationTitle => 'Cálculo de tarefa';

  @override
  String get todoExplanationIntro =>
      'A percentagem de conclusão da tarefa é calculada com base nas seguintes atividades com ponderações específicas:';

  @override
  String get todoExplanationLegendsTitle => 'Liga Lendária:';

  @override
  String get todoExplanationLegends =>
      'Peso de 8 pontos por conta, 1 ataque = 1 ponto.';

  @override
  String get todoExplanationRaidsTitle => 'Raides:';

  @override
  String get todoExplanationRaids =>
      'Peso de 5 pontos por conta (ou 6 se o último ataque foi desbloqueado), 1 ataque = 1 ponto.';

  @override
  String get todoExplanationClanWarsTitle => 'Guerras de clã:';

  @override
  String get todoExplanationClanWars =>
      'Peso de 2 pontos por conta, 1 ataque = 1 ponto.';

  @override
  String get todoExplanationCwlTitle => 'Liga de Guerra de Clãs:';

  @override
  String get todoExplanationCwl =>
      'Peso de 1 ponto por conta, 1 ataque = 1 ponto. CWL não pode ser rastreada se o jogador não está no seu clã da liga.';

  @override
  String get todoExplanationPassAndGamesTitle =>
      'Passe de temporada & Jogos do Clã:';

  @override
  String get todoExplanationPassAndGames =>
      'Peso de 2 pontos por conta. A razão baseia-se no número de dias restantes (1 mês para o passe e 6 dias para os jogos de clã). Verde = no caminho certo para completar o passe ou os jogos, vermelho = atrasado.';

  @override
  String get todoExplanationConclusion =>
      'A percentagem final é calculada a dividir o total de ações concluídas durante os eventos em curso pelo total de ações necessárias. As contas inativas por mais de 14 dias são excluídas do cálculo.';

  @override
  String todoAccountsNumber(int number) {
    return '$number contas';
  }

  @override
  String todoAccountsNumberActive(int number) {
    return '$number contas ativas';
  }

  @override
  String todoAccountsNumberInactive(int number) {
    return '$number contas inativas';
  }

  @override
  String get todoAccountsActive => 'Contas ativas';

  @override
  String get todoAccountsInactive => 'Contas inativas';

  @override
  String get todoAccountsNoInactive => 'Sem contas inativas.';

  @override
  String get todoAccountsNoActive => 'Sem contas ativas.';

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
  String get warTitle => 'Guerra';

  @override
  String get warFrequency => 'Frequência de guerra';

  @override
  String get warParticipation => 'Participação na guerra';

  @override
  String get warLeague => 'Guerra/Liga';

  @override
  String get warHistory => 'Histórico de guerra';

  @override
  String get warLog => 'Registo de guerra';

  @override
  String warLogClosed(String clan) {
    return 'Registo de guerra fechado.';
  }

  @override
  String get warStats => 'Estatísticas de guerra';

  @override
  String get warOngoing => 'Guerra em curso';

  @override
  String warIsNotInWar(String clan) {
    return '$clan não está em guerra.';
  }

  @override
  String get warAskForWar =>
      'Contacta o líder ou colíder para começar a guerra.';

  @override
  String get warAskForWarLogOpening =>
      'Contacta o líder ou colíder para abrir os registos de guerra.';

  @override
  String get warEnded => 'Guerra acabou';

  @override
  String get warPreparation => 'Preparação';

  @override
  String get warPerfectWar => 'Guerra perfeita';

  @override
  String get warVictory => 'Vitória';

  @override
  String get warDefeat => 'Derrota';

  @override
  String get warDraw => 'Empate';

  @override
  String get warTeamSize => 'Tamanho da equipa';

  @override
  String get warMyTeam => 'A minha equipa';

  @override
  String get warEnemiesTeam => 'Inimigos';

  @override
  String get warClanDraw => 'Os dois clãs estão empatados';

  @override
  String get warStateOfTheWar => 'Estado da guerra';

  @override
  String warStarsNeededToTakeTheLead(
      String clan, int star, int stars2, String percent) {
    return '$clan ainda precisa de $star estrela(s) ou $stars2 estrela(s) e $percent% para assumir a liderança.';
  }

  @override
  String warStarsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan ainda precisa de $percent% ou mais 1 estrela para assumir a liderança';
  }

  @override
  String get warNoDataAvailableForThisWar =>
      'Não há dados disponíveis para esta guerra';

  @override
  String get warCalculatorFast => 'Calculadora rápida';

  @override
  String warCalculatorAnswer(String percentNeeded, String result) {
    return 'Para conquistar uma taxa de destruição de $percentNeeded%, um resultado total de $result% é preciso.';
  }

  @override
  String get warCalculatorNeededOverall => '% Necessário, em geral';

  @override
  String get warCalculatorCalculate => 'Calcular';

  @override
  String get warAttacksTitle => 'Ataques';

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
  String get warStarsTitle => 'Estrelas';

  @override
  String get warStarsAverage => 'Estrelas médias';

  @override
  String get warStarsNumber => 'Número de estrelas';

  @override
  String get warStarsOne => '1 estrela';

  @override
  String get warStarsTwo => '2 estrelas';

  @override
  String get warStarsThree => '3 estrelas';

  @override
  String get warStarsZero => '0 Star';

  @override
  String get warStarsBestPerformance => 'Best performance';

  @override
  String get warDestructionTitle => 'Destruction';

  @override
  String get warDestructionAverage => 'Destruição média';

  @override
  String get warDestructionRate => 'Taxa de destruição';

  @override
  String warHistoryWinsDescription(int wins, String percent) {
    return 'O seu clã ganhou $wins guerras ($percent%) nas últimas 50 guerras.';
  }

  @override
  String warHistoryLossesDescription(int losses, String percent) {
    return 'O seu clã perdeu $losses guerras ($percent%) nas últimas 50 guerras.';
  }

  @override
  String warHistoryDrawsDescription(int draws, String percent) {
    return 'O seu clã teve $draws empates ($percent%) nas últimas 50 guerras.';
  }

  @override
  String warHistoryAverageMembersDescription(int members) {
    return 'O seu clã tem uma média de $members membros participantes das últimas 50 guerras.';
  }

  @override
  String warHistoryAverageWarStarsDescription(double stars, String percent) {
    return 'O seu clã teve uma média de $stars estrelas por guerra das últimas 50 guerras. Representa $percent das estrelas totais.';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return 'O seu clã teve uma média de $percent% de taxa de destruição nas últimas 50 guerras.';
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
  String get warOpponentEqualThLevel => 'Mesmo CV';

  @override
  String get warOpponentSelectMembersThLevel => 'Nível CV de membros';

  @override
  String get warOpponentSelectOpponentsThLevel => 'Nível CV de oponentes';

  @override
  String warFiltersLastXwars(int number) {
    return 'Últimas $number guerras';
  }

  @override
  String get warFiltersFriendly => 'Amigável';

  @override
  String get warFiltersRandom => 'Aleatório';

  @override
  String get warVisibilityToggleTownHall =>
      'Ocultar/Mostrar estatísticas de níveis de CV antigos';

  @override
  String get warEventsTitle => 'Eventos';

  @override
  String get warEventsNewest => 'Mais novo';

  @override
  String get warEventsOldest => 'Mais velho';

  @override
  String get warStatusReady => 'Optou em';

  @override
  String get warStatusUnready => 'Optou fora';

  @override
  String get warStatusMissed => 'Missed';

  @override
  String get warAbbreviationAvg => 'Avg';

  @override
  String get warAbbreviationAvgPercentage => 'Avg %';

  @override
  String get cwlTitle => 'CWL';

  @override
  String get cwlClanWarLeague => 'Liga de Guerra de Clãs';

  @override
  String get cwlOngoing => 'CWL em curso';

  @override
  String get cwlRounds => 'Rondas';

  @override
  String cwlRoundNumber(int number) {
    return 'Round $number';
  }

  @override
  String cwlCurrentRound(int round) {
    return 'Atualmente é a ronda $round.';
  }

  @override
  String cwlRank(int rank) {
    return 'O seu clã está atualmente classificado $rank.';
  }

  @override
  String cwlStars(int stars) {
    return 'O seu clã têm um total de $stars estrelas.';
  }

  @override
  String cwlDestructionPercentage(String percent) {
    return 'O seu clã têm uma taxa total de destruição de $percent%.';
  }

  @override
  String cwlTotalAttacks(int attacks, int totalAttacks) {
    return 'Your clan has a total of $attacks attacks out of $totalAttacks possible attacks.';
  }

  @override
  String get joinLeaveTitle => 'Join/Leave Logs (Current Season)';

  @override
  String get joinLeaveJoin => 'Entrar';

  @override
  String get joinLeaveLeave => 'Sair';

  @override
  String get joinLeaveReset => 'Reiniciar';

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
    return 'Saiu a $date às $time.';
  }

  @override
  String joinLeaveJoinedOnAt(String date, String time) {
    return 'Entrou a $date às $time.';
  }

  @override
  String get raidsTitle => 'Raids';

  @override
  String get raidsLast => 'Últimos raides';

  @override
  String get raidsOngoing => 'Raides em curso';

  @override
  String get raidsDistrictsDestroyed => 'Distritos destruídos';

  @override
  String get raidsCompleted => 'Raides finalizados';

  @override
  String get searchNoResult => 'Sem resultado.';

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
  String get dashboardTitle => 'Painel';

  @override
  String get toolsTitle => 'Ferramentas';

  @override
  String get navigationTeam => 'Equipas';

  @override
  String get navigationStatistics => 'Estatísticas';

  @override
  String get versionDevice => 'Versão & Dispositivo';

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
  String get betaFeature => 'Recurso Beta';

  @override
  String get betaLabel => 'BETA';

  @override
  String get betaDescription =>
      'Esta funcionalidade está atualmente em versão beta, então pode ter alguns bugs ou estar incompleta. Estamos a trabalhar ativamente em melhorias e agradecemos os seus comentários. Por favor, compartilhe as suas ideias e relate qualquer problema no nosso servidor do Discord para nos ajudar a melhorá-lo.';

  @override
  String get settingsLanguage => 'Linguagem';

  @override
  String get settingsSelectLanguage => 'Seleciona a linguagem';

  @override
  String get settingsToggleTheme => 'Alternar tema';

  @override
  String get faqTitle => 'FAQ';

  @override
  String get faqSubtitle => 'Perguntas frequentes';

  @override
  String get faqIsThisFromSupercell => 'Esta aplicação é da Supercell?';

  @override
  String get faqFanContentPolicy =>
      'Este material não é oficial e não é endossado pela Supercell. Para obter mais informações, consulte a Política de Conteúdo de Fãs da Supercell: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate =>
      'Por que razão os dados são por vezes imprecisos ou inexistentes?';

  @override
  String get faqClanNotTracked => 'Clã não rastreado';

  @override
  String get faqClanNotTrackedAnswer =>
      'O ClashKing apenas pode recuperar esta informação se o seu clã for rastreado. Se o seu clã não for rastreado, convide o bot ClashKing para o seu servidor de Discord e use o comando /addclan. Trabalhamos para disponibilizar esta funcionalidade na aplicação em breve.';

  @override
  String get faqTrackingDown => 'Rastreando';

  @override
  String get faqTrackingDownAnswer =>
      'O rastreamento pode parar de funcionar por um certo período. Esta é a razão ao qual pode existir falhas nos seus dados. Estamos a trabalhar para melhorar esta situação.';

  @override
  String get faqApiLimitation => 'Limitação da API do Clash of Clans';

  @override
  String get faqApiLimitationAnswer =>
      'Alguns dados são fornecidos pelo Clash of Clans e a sua API tem algumas limitações. Este é o caso do rastreamento da liga lendária, onde às vezes acumula o ganho e perda de troféus como se fosse um único ataque. É também por isso que não temos alguma informação acerca dos seus níveis de construções.';

  @override
  String get faqSupportWork => 'Como posso ajudar o seu trabalho?';

  @override
  String get faqSupportWorkAnswer => 'Existem várias maneiras de nos apoiar:';

  @override
  String get faqUseCodeClashKing => 'Usa o código \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Apoie-nos no Patreon';

  @override
  String get faqShareTheApp => 'Compartilha a aplicação com os seus amigos';

  @override
  String get faqRateTheApp => 'Avalia a aplicação na loja';

  @override
  String get faqHelpUsTranslate => 'Ajude-nos a traduzir a aplicação';

  @override
  String get faqHowToInviteTheBot =>
      'Como posso convidar o bot para o meu servidor de Discord?';

  @override
  String get faqHowToInviteTheBotAnswer =>
      'Pode convidar o nosso bot para o seu servidor de Discord, clicando no botão abaixo. É preciso ter a permissão \"Gerir Servidor\" para adicionar o bot.';

  @override
  String get faqInviteTheBot => 'Convide o bot ClashKing';

  @override
  String get faqNeedHelp =>
      'Preciso de ajuda ou gostaria de fazer uma sugestão. Como posso contactar-vos?';

  @override
  String get faqNeedHelpAnswer =>
      'You can join our Discord Server to ask for help or to provide feedback, or you can email us at devs@clashk.ing. Please only write in English or French.';

  @override
  String get faqSendEmail => 'Envie um e-mail';

  @override
  String get faqJoinDiscord => 'Entra no nosso servidor de Discord';

  @override
  String get faqCannotOpenMailClient =>
      'Por algumas razões, não podemos abrir o seu cliente de e-mail. Copiamos o endereço de e-mail para você. Pode escrever um e-mail e colar o endereço no campo do destinatário.';

  @override
  String get translationHelpUsTranslate => 'Ajude-nos a traduzir';

  @override
  String get translationSuggestFeatures => 'Sugerir funcionalidades';

  @override
  String get translationThankYou => 'Obrigado!';

  @override
  String get translationThankYouContent =>
      'Um enorme obrigado a todos os nossos incríveis tradutores que nos ajudam a tornar este aplicativo acessível a mais pessoas ao redor do mundo!';

  @override
  String get translationHelpTranslateContent =>
      'Pode ajudar-nos a traduzir a aplicação no Crowdin. Se a sua linguagem não está disponível no Crowdin, sinta-se à vontade para pedi-la no nosso servidor de Discord. Muito obrigado pela sua ajuda!';

  @override
  String get translationHelpTranslateButton =>
      'Ajude-nos a traduzir no Crowdin';

  @override
  String get translationCurrentTranslators => 'Atuais tradutores';
}
