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
      'Seu companheiro definitivo do Clash of Clans para acompanhar estatísticas, gerenciar clãs e analisar desempenho.';

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
  String get generalRetry => 'Tentar novamente';

  @override
  String get generalTryAgain => 'Tente novamente';

  @override
  String get generalCancel => 'Cancelar';

  @override
  String get generalOk => 'OK';

  @override
  String get generalApply => 'Aplicar';

  @override
  String get generalConfirm => 'Confirmar';

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
  String get generalActive => 'Ativo';

  @override
  String get generalInactive => 'Inativo';

  @override
  String get generalStarted => 'Começado';

  @override
  String get generalEnded => 'Terminou';

  @override
  String get generalRole => 'Cargo';

  @override
  String get generalStats => 'Estatísticas';

  @override
  String get generalFullStats => 'Estatísticas Completas';

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
  String get authSignUp => 'Registar';

  @override
  String get authLogin => 'Iniciar Sessão';

  @override
  String get authLogout => 'Terminar sessão';

  @override
  String get authCreateAccount => 'Criar Conta';

  @override
  String get authJoinClashKing => 'Juntar-se ao ClashKing';

  @override
  String get authCreateClashKingAccount => 'Criar Conta ClashKing';

  @override
  String get authCreateAccountToGetStarted => 'Crie a sua conta para começar';

  @override
  String get authAlreadyHaveAccount => 'Já tem uma conta? Iniciar sessão';

  @override
  String get authConfirmLogout =>
      'Tem a certeza de que pretende terminar a sessão?';

  @override
  String get authDiscordTitle => 'Discord';

  @override
  String get authDiscordSignIn => 'Iniciar sessão com Discord';

  @override
  String get authDiscordContinue => 'Continuar com Discord';

  @override
  String get authDiscordDescription =>
      'Sync your data with ClashKing Bot and unlock the full potential of ClashKing!';

  @override
  String get authEmailTitle => 'E-mail';

  @override
  String get authEmailDescription =>
      'Use e-mail se não conseguir aceder ao Discord ou preferir funcionalidades apenas da aplicação';

  @override
  String get authEmailRequired => 'Por favor, insira o seu e-mail';

  @override
  String get authEmailInvalid => 'Por favor, insira um e-mail válido';

  @override
  String get authPasswordLabel => 'Palavra-passe';

  @override
  String get authPasswordConfirm => 'Confirmar Palavra-passe';

  @override
  String get authPasswordRequired => 'Por favor, insira a sua palavra-passe';

  @override
  String get authPasswordConfirmRequired =>
      'Por favor, confirme a sua palavra-passe';

  @override
  String get authPasswordMismatch => 'As palavras-passe não coincidem';

  @override
  String get authPasswordTooShort =>
      'A palavra-passe deve ter pelo menos 8 caracteres';

  @override
  String get authPasswordRequirements =>
      'A palavra-passe deve conter: maiúscula, minúscula, dígito e carácter especial';

  @override
  String get authPasswordForgot => 'Esqueceu-se da palavra-passe?';

  @override
  String get authUsernameLabel => 'Nome de utilizador';

  @override
  String get authUsernameRequired => 'Por favor, insira um nome de utilizador';

  @override
  String get authUsernameTooShort =>
      'O nome de utilizador deve ter pelo menos 3 caracteres';

  @override
  String get authErrorConnection =>
      'Ocorreu um erro. Por favor, verifique a sua conexão de internet e tente novamente.';

  @override
  String get authErrorConnectionRelaunch =>
      'Ocorreu um erro. Por favor, verifique a sua conexão de internet e reinicie a aplicação.';

  @override
  String get authAccountManagement => 'Gestão de Conta';

  @override
  String get authAccountConnected => 'Contas Ligadas';

  @override
  String get authAccountConnectedStatus => 'Ligado';

  @override
  String get authAccountNotConnected => 'Não ligado';

  @override
  String get authAccountEmailAndPassword => 'E-mail e Palavra-passe';

  @override
  String get authAccountSecured =>
      'A sua conta está protegida com múltiplos métodos de autenticação';

  @override
  String get authAccountLinkEmail => 'Ligar Conta de E-mail';

  @override
  String get authAccountAddEmailAuth =>
      'Adicione autenticação por e-mail e palavra-passe à sua conta para segurança adicional.';

  @override
  String get authAccountEmailLinkedSuccess =>
      'Conta de e-mail ligada com sucesso!';

  @override
  String get helpTitle => 'Precisa de ajuda?';

  @override
  String get helpJoinDiscord => 'Juntar-se ao Discord';

  @override
  String get helpEmailUs => 'Envie-nos um E-mail';

  @override
  String get accountsWelcome => 'Bem-vindo!';

  @override
  String get accountsWelcomeMessage =>
      'Por favor, adicione uma ou mais contas de Clash of Clans ao seu perfil. Pode adicionar ou remover contas depois.';

  @override
  String get accountsManageTitle => 'Gerir as suas contas';

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
  String get accountsFillAllFields => 'Por favor, preencha todos os campos.';

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
      'Falha ao adicionar a conta. Por favor, tente novamente mais tarde.';

  @override
  String get accountsErrorFailedToDelete =>
      'Falha ao apagar link. Por favor, tente novamente mais tarde.';

  @override
  String get accountsErrorFailedToUpdateOrder =>
      'Falha ao atualizar a ordem das contas.';

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
    return 'Nível: $level/$maxLevel';
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
  String get gameClanGames => 'Jogos de Clã';

  @override
  String get gameSeasonPass => 'Passe de Temporada';

  @override
  String get gameCreatorCode => 'Código de Criador: ClashKing';

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
  String get clanTitle => 'Clã';

  @override
  String get clanSearchTitle => 'Procurar clã';

  @override
  String get clanSearchPlaceholder => 'Nome do clã';

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
  String get clanWarFrequencyMoreThanOncePerWeek => 'Mais de 1/semana';

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
  String get timeEndedJustNow => 'Terminou agora mesmo';

  @override
  String timeEndedMinutesAgo(int minutes) {
    return 'Terminou há $minutes minutos';
  }

  @override
  String timeEndedHoursAgo(int hours) {
    return 'Terminou há $hours horas';
  }

  @override
  String timeEndedDaysAgo(int days) {
    return 'Terminou há $days dias';
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
      'Não está na Liga Lendária, mas temporadas passadas estão disponíveis.';

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
    return 'Está atualmente classificado $rank globalmente com $trophies troféus.';
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
  String get legendsEosDetails => 'Detalhes do Fim de Temporada';

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
    return 'Tem $attacks ataque(s) restante(s) ($type).';
  }

  @override
  String todoDefensesLeftDescription(int defenses, String type) {
    return 'Tem $defenses defesa(s) restante(s) ($type).';
  }

  @override
  String todoNoAttacksLeftDescription(String type) {
    return 'Parabéns, fez todos os seus ataques ($type)!';
  }

  @override
  String todoPointsLeftDescription(int points, String type) {
    return 'Tem $points pontos restantes para obter hoje para estar a tempo do fim do evento ($type).';
  }

  @override
  String todoPointsLeftDescriptionNoPoints(String type) {
    return 'Parabéns, está a tempo de obter as recompensas máximas no fim do evento ($type)!';
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
  String get warAttacksNone => 'Ainda sem ataques';

  @override
  String get warAttacksBest => 'Melhores ataques';

  @override
  String get warAttacksCount => 'Contagem de Ataques';

  @override
  String get warAttacksMissed => 'Ataques Perdidos';

  @override
  String warAttacksNumber(int number_time, int number_war) {
    return 'Atacou $number_time vez(es) durante as últimas $number_war guerras.';
  }

  @override
  String warAttacksAverageStars(String stars) {
    return 'Teve uma média de $stars estrelas por guerra.';
  }

  @override
  String warAttacksAverageDestruction(String percent) {
    return 'Teve uma média de $percent% de taxa de destruição por guerra.';
  }

  @override
  String get warDefensesTitle => 'Defesas';

  @override
  String get warDefensesNone => 'Ainda sem defesas';

  @override
  String get warDefensesBest => 'Melhores defesas';

  @override
  String warDefensesBestOutOf(int number) {
    return 'Melhor defesa (de $number)';
  }

  @override
  String warDefensesNumber(int number_time, int number_war) {
    return 'Defendeu $number_time vez(es) durante as últimas $number_war guerras.';
  }

  @override
  String warDefensesAverageStars(double stars) {
    return 'Teve uma média de $stars estrelas por defesa.';
  }

  @override
  String warDefensesAverageDestruction(String percent) {
    return 'Teve uma média de $percent% de taxa de destruição por defesa.';
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
  String get warStarsZero => '0 Estrelas';

  @override
  String get warStarsBestPerformance => 'Melhor desempenho';

  @override
  String get warDestructionTitle => 'Destruição';

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
  String get warPositionMap => 'Posição no Mapa';

  @override
  String get warPositionAbbr => 'Pos';

  @override
  String get warPositionOrder => 'Ordem';

  @override
  String get warOpponentTownhall => 'Opp TH';

  @override
  String get warOpponentLowerTownhall => 'CV Inferior';

  @override
  String get warOpponentUpperTownhall => 'CV Superior';

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
  String get warStatusMissed => 'Perdido';

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
    return 'O seu clã tem um total de $attacks ataques de $totalAttacks ataques possíveis.';
  }

  @override
  String get joinLeaveTitle => 'Registos de Entrada/Saída (Temporada Atual)';

  @override
  String get joinLeaveJoin => 'Entrar';

  @override
  String get joinLeaveLeave => 'Sair';

  @override
  String get joinLeaveReset => 'Reiniciar';

  @override
  String get joinLeaveJoins => 'Entradas';

  @override
  String get joinLeaveLeaves => 'Saídas';

  @override
  String get joinLeaveUniquePlayers => 'Jogadores Únicos';

  @override
  String get joinLeaveMovingPlayers => 'Jogadores em Movimento';

  @override
  String get joinLeaveMostMovingPlayers => 'Jogadores que Mais se Movem';

  @override
  String get joinLeaveStillInClan => 'Ainda no Clã';

  @override
  String get joinLeaveLeftForever => 'Saíram para Sempre';

  @override
  String get joinLeaveRejoinedPlayers => 'Jogadores que Voltaram';

  @override
  String get joinLeaveAvgTimeJoinLeave => 'Tempo Médio de Entrada/Saída';

  @override
  String get joinLeavePeakHour => 'Hora Mais Ativa';

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
  String get raidsTitle => 'Ataques';

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
  String get maintenanceTitle => 'Manutenção';

  @override
  String get maintenanceDescription =>
      'Clash of Clans está atualmente em manutenção, portanto não conseguimos aceder à API. Por favor, volte mais tarde.';

  @override
  String get downloadTooltip => 'Descarregar resumo CWL';

  @override
  String get downloadInProgress =>
      'A descarregar ficheiro... Pode demorar alguns segundos...';

  @override
  String downloadSuccess(String path) {
    return 'Ficheiro guardado com sucesso em $path';
  }

  @override
  String get downloadError => 'Falha ao descarregar ficheiro';

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
      'Pode entrar no nosso servidor de Discord para pedir ajuda ou fornecer opiniões, ou pode enviar um e-mail para devs@clashk.ing. Por favor, escreva apenas em Inglês ou Francês.';

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
