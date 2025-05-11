// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get creatorCode => 'Código de Criador: ClashKing';

  @override
  String get errorTitle => 'Oops! Our servers might have taken a fireball to the face! We\'re casting a healing spell... Try again in a moment.';

  @override
  String get errorSubtitle => 'If the issue persists, check our Discord Server to see if we\'re aware of it.';

  @override
  String get retry => 'Retry';

  @override
  String get signInWithDiscord => 'Iniciar sessão com Discord';

  @override
  String get guestMode => 'Modo de convidado';

  @override
  String get needHelpJoinDiscord => 'Precisa de ajuda? Junte-se a nós no Discord.';

  @override
  String get loginError => 'An error occurred while logging in. Please try again later.';

  @override
  String doesNotExist(String tag) {
    return '$tag não existe.';
  }

  @override
  String isAlreadyLinked(String tag) {
    return '$tag já está vinculada a alguém.';
  }

  @override
  String get username => 'Nome de utilizador';

  @override
  String get playerTag => 'Player Tag (#ABC123)';

  @override
  String get playerTags => 'Tags de Jogador';

  @override
  String get linkedAccounts => 'Linked Accounts';

  @override
  String followingTagsDoNotExist(String tags) {
    return 'As seguintes tags não existem: $tags.';
  }

  @override
  String followingTagsAreAlreadyLinked(String tags) {
    return 'As seguintes tags já estão vinculadas a alguém: $tags.';
  }

  @override
  String get welcome => 'Bem-vindo!';

  @override
  String get welcomeMessage => 'Por favor, adicione uma ou mais contas de Clash of Clans ao seu perfil. Pode adicionar ou remover contas depois.';

  @override
  String get login => 'Iniciar Sessão';

  @override
  String get logout => 'Terminar sessão';

  @override
  String get language => 'Linguagem';

  @override
  String get settings => 'Definições';

  @override
  String get toggleTheme => 'Alternar tema';

  @override
  String get selectLanguage => 'Seleciona a linguagem';

  @override
  String get faq => 'FAQ';

  @override
  String get faqSubtitle => 'Perguntas frequentes';

  @override
  String get faqIsThisFromSupercell => 'Esta aplicação é da Supercell?';

  @override
  String get faqFanContentPolicy => 'Este material não é oficial e não é endossado pela Supercell. Para obter mais informações, consulte a Política de Conteúdo de Fãs da Supercell: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate => 'Por que razão os dados são por vezes imprecisos ou inexistentes?';

  @override
  String get faqClanNotTracked => 'Clã não rastreado';

  @override
  String get faqClanNotTrackedAnswer => 'O ClashKing apenas pode recuperar esta informação se o seu clã for rastreado. Se o seu clã não for rastreado, convide o bot ClashKing para o seu servidor de Discord e use o comando /addclan. Trabalhamos para disponibilizar esta funcionalidade na aplicação em breve.';

  @override
  String get faqTrackingDown => 'Rastreando';

  @override
  String get faqTrackingDownAnswer => 'O rastreamento pode parar de funcionar por um certo período. Esta é a razão ao qual pode existir falhas nos seus dados. Estamos a trabalhar para melhorar esta situação.';

  @override
  String get faqApiLimitation => 'Limitação da API do Clash of Clans';

  @override
  String get faqApiLimitationAnswer => 'Alguns dados são fornecidos pelo Clash of Clans e a sua API tem algumas limitações. Este é o caso do rastreamento da liga lendária, onde às vezes acumula o ganho e perda de troféus como se fosse um único ataque. É também por isso que não temos alguma informação acerca dos seus níveis de construções.';

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
  String get faqHowToInviteTheBot => 'Como posso convidar o bot para o meu servidor de Discord?';

  @override
  String get faqHowToInviteTheBotAnswer => 'Pode convidar o nosso bot para o seu servidor de Discord, clicando no botão abaixo. É preciso ter a permissão \"Gerir Servidor\" para adicionar o bot.';

  @override
  String get faqInviteTheBot => 'Convide o bot ClashKing';

  @override
  String get faqNeedHelp => 'Preciso de ajuda ou gostaria de fazer uma sugestão. Como posso contactar-vos?';

  @override
  String get faqNeedHelpAnswer => 'Pode entrar no nosso servidor de Discord para pedir ajuda ou fornecer opiniões, ou pode enviar um e-mail para devs@clashkingbot.com. Por favor, escreva apenas em Inglês ou Francês.';

  @override
  String get faqSendEmail => 'Envie um e-mail';

  @override
  String get faqJoinDiscord => 'Entra no nosso servidor de Discord';

  @override
  String get faqCannotOpenMailClient => 'Por algumas razões, não podemos abrir o seu cliente de e-mail. Copiamos o endereço de e-mail para você. Pode escrever um e-mail e colar o endereço no campo do destinatário.';

  @override
  String get helpUsTranslate => 'Ajude-nos a traduzir';

  @override
  String get suggestFeatures => 'Sugerir funcionalidades';

  @override
  String get thankYou => 'Obrigado!';

  @override
  String get thankYouContent => 'Um enorme obrigado a todos os nossos incríveis tradutores que nos ajudam a tornar este aplicativo acessível a mais pessoas ao redor do mundo!';

  @override
  String get helpTranslateContent => 'Pode ajudar-nos a traduzir a aplicação no Crowdin. Se a sua linguagem não está disponível no Crowdin, sinta-se à vontade para pedi-la no nosso servidor de Discord. Muito obrigado pela sua ajuda!';

  @override
  String get helpTranslateButton => 'Ajude-nos a traduzir no Crowdin';

  @override
  String get versionDevice => 'Versão & Dispositivo';

  @override
  String get loading => 'Carregando...';

  @override
  String get errorLoadingVersion => 'Erro ao carregar versão';

  @override
  String get currentTranslators => 'Atuais tradutores';

  @override
  String get betaFeature => 'Recurso Beta';

  @override
  String get beta => 'BETA';

  @override
  String get betaDescription => 'Esta funcionalidade está atualmente em versão beta, então pode ter alguns bugs ou estar incompleta. Estamos a trabalhar ativamente em melhorias e agradecemos os seus comentários. Por favor, compartilhe as suas ideias e relate qualquer problema no nosso servidor do Discord para nos ajudar a melhorá-lo.';

  @override
  String get copiedToClipboard => 'Copiado para a área de transferência';

  @override
  String get all => 'Tudo';

  @override
  String get hourIndicator => 'h';

  @override
  String get minIndicator => 'm';

  @override
  String get noDataAvailable => 'Sem dados disponíveis.';

  @override
  String get close => 'Fechar';

  @override
  String get closed => 'Fechado';

  @override
  String get error => 'Erro';

  @override
  String get player => 'Jogador';

  @override
  String notFoundOrNotLinkedToOurSystem(String player) {
    return '$player não foi encontrado ou não está vinculado ao nosso sistema.';
  }

  @override
  String get tryAnotherNameOrTagOrLinkIt => 'Tente outro nome/tag ou vincule.';

  @override
  String get playerNotFound => 'Jogador não encontrado';

  @override
  String get noValueEntered => 'Nenhum valor introduzido';

  @override
  String get manage => 'Gerir';

  @override
  String get enterPlayerTag => 'Introduza a tag de jogador';

  @override
  String get add => 'Adicionar';

  @override
  String get delete => 'Apagar';

  @override
  String get addAccount => 'Adicionar conta';

  @override
  String get deleteAccount => 'Apagar conta';

  @override
  String get playerTagNotExists => 'A tag de jogador inserida não existe.';

  @override
  String accountAlreadyLinked(Object tag) {
    return 'A tag de jogador já está vinculada a alguém.';
  }

  @override
  String get enterApiToken => 'Por favor, insira o token de API da conta para confirmar ser sua. Pode encontrá-lo no jogo em Configurações > Mais configurações > Token de API.';

  @override
  String get wrongApiToken => 'O token da API inserido está incorreto';

  @override
  String get accountAlreadyLinkedToYou => 'A tag de jogador já está vinculada a si.';

  @override
  String get apiToken => 'Token API de conta';

  @override
  String get failedToAddTryAgain => 'Falha ao adicionar link. Por favor, tente novamente mais tarde.';

  @override
  String get fillAllFields => 'Please fill all fields.';

  @override
  String get failedToDeleteTryAgain => 'Falha ao apagar link. Por favor, tente novamente mais tarde.';

  @override
  String get enterPlayerTagWarning => 'Precisa inserir a tag de jogador e clicar no \"+\" para continuar.';

  @override
  String get failedToLoadAccountData => 'Failed to load accounts data.';

  @override
  String get loadAccountData => 'Load accounts data';

  @override
  String get search => 'Procurar';

  @override
  String get warning => 'Atenção';

  @override
  String get exitAppToOpenClash => 'Está prestes a sair da aplicação para abrir Clash of Clans.';

  @override
  String get confirmLogout => 'Tem a certeza de que pretende terminar a sessão?';

  @override
  String get tagOrNamePlayer => 'Tag de jogador ou nome';

  @override
  String get searchPlayer => 'Procurar jogador';

  @override
  String get nameOrTagPlayer => 'Nome ou tag de jogador';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'O seu clã é \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(String ratio, String donations, String received) {
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
  String get dashboard => 'Painel';

  @override
  String get homeBase => 'Base principal';

  @override
  String get th => 'CV';

  @override
  String get builderBase => 'Base do Construtor';

  @override
  String get bh => 'CC';

  @override
  String get clanCapital => 'Capital do clã';

  @override
  String get leader => 'Líder';

  @override
  String get coLeader => 'Colíder';

  @override
  String get elder => 'Ancião';

  @override
  String get member => 'Membro';

  @override
  String get ready => 'Optou em';

  @override
  String get unready => 'Optou fora';

  @override
  String level(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get heroes => 'Heróis';

  @override
  String get equipment => 'Equipamentos';

  @override
  String get troops => 'Tropas';

  @override
  String get superTroops => 'Supertropas';

  @override
  String get activeSuperTroops => 'Supertropas ativas';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get pets => 'Animais';

  @override
  String get siegeMachines => 'Máquinas de Cerco';

  @override
  String get spells => 'Feitiços';

  @override
  String get achievements => 'Conquistas';

  @override
  String get byDay => 'Por dia';

  @override
  String get bySeason => 'Por temporada';

  @override
  String dayIndex(int index) {
    return 'Dia $index';
  }

  @override
  String indexDays(int index) {
    return '$index dias';
  }

  @override
  String get bestTrophies => 'Melhores troféus';

  @override
  String get mostAttacks => 'Maior número de ataques';

  @override
  String get lastSeason => 'Última temporada';

  @override
  String get bestRank => 'Melhor Rank Global';

  @override
  String daysLeft(int days) {
    return '$days dias restantes';
  }

  @override
  String get date => 'Data';

  @override
  String get stats => 'Estatísticas';

  @override
  String get fullStats => 'Full Stats';

  @override
  String get details => 'Detalhes';

  @override
  String get seasonStats => 'Estatísticas de temporada';

  @override
  String get charts => 'Gráficos';

  @override
  String get history => 'Histórico';

  @override
  String get legendLeague => 'Liga Lendária';

  @override
  String get notInLegendLeague => 'Não está na Liga Lendária';

  @override
  String get noLegendsDataToday => 'You\'re not in Legend League, but past seasons are available.';

  @override
  String legendStartDescription(String trophies) {
    return 'Começou o dia com $trophies troféus.';
  }

  @override
  String legendNoRankLocalDescription(String country, int trophies) {
    return 'Não está atualmente classificado ($country) com $trophies troféus.';
  }

  @override
  String legendRankLocalDescription(Object country, Object rank, Object trophies) {
    return 'Está atualmente classificado $rank ($country) com $trophies troféus.';
  }

  @override
  String legendGainDescription(int trophies) {
    return 'Ganhou $trophies troféus por agora.';
  }

  @override
  String legendLossDescription(int trophies) {
    return 'Perdeu $trophies troféus por agora.';
  }

  @override
  String legendNoGlobalRankDescription(int trophies) {
    return 'Não está atualmente classificado globalmente com $trophies troféus.';
  }

  @override
  String legendGlobalRankDescription(int rank, Object trophies) {
    return 'Está atualmente classificado $rank globalmente.';
  }

  @override
  String get noRank => 'Sem classificação';

  @override
  String get started => 'Começado';

  @override
  String get ended => 'Terminou';

  @override
  String get average => 'Média';

  @override
  String get remaining => 'Restantes';

  @override
  String get legendsTitle => 'Dados imprecisos?';

  @override
  String get legendsExplanation_intro => 'Devido às limitações da API do Clash of Clãs, nossos dados nem sempre podem ser perfeitamente precisos. Veja o porque:\n';

  @override
  String get legendsExplanation_api_delay_title => '1. Atraso da API: ';

  @override
  String get legendsExplanation_api_delay_body => 'A API pode demorar até 5 minutos para atualizar, causando um atraso na reflexão das mudanças de troféus em tempo real.\n';

  @override
  String get legendsExplanation_concurrent_changes_title => '2. Alterações simultâneas: \n';

  @override
  String get legendsExplanation_multiple_attacks_defenses_title => '- Múltiplos Ataques/Defesas: ';

  @override
  String get legendsExplanation_multiple_attacks_defenses_body => 'Se múltiplos ataques ou defesas acontecerem em rápida sucessão, a API pode mostrar resultados combinados (Ex., +68 ou -68).\n';

  @override
  String get legendsExplanation_simultaneous_attack_defense_title => '- Ataques e Defesas simultâneas: ';

  @override
  String get legendsExplanation_simultaneous_attack_defense_body => 'Se um ataque e uma defesa ocorrerem em simultâneo, poderá ver um resultado misto (Ex., +4).\n';

  @override
  String get legendsExplanation_net_gain_loss_title => 'Ganho/Perda Líquida: ';

  @override
  String get legendsExplanation_net_gain_loss_body => 'Apesar dos problemas de tempo, o ganho ou perda líquida geral do dia é precisa. ';

  @override
  String get legendsExplanation_conclusion => 'Estas limitações são comuns em todas as ferramentas que usam a API do Clash of Clans. Nós, infelizmente, não podemos arrumar o que está nas mãos da Supercell. Nós fazemos o nosso melhor para compensar estes limites e providenciar os resultados mais próximos possíveis da realidade. Obrigado pela sua compreensão!';

  @override
  String get toDoList => 'Lista de tarefas';

  @override
  String get clanGames => 'Clan Games';

  @override
  String get seasonPass => 'Season Pass';

  @override
  String lastActive(String date) {
    return 'Última vez ativo: $date';
  }

  @override
  String get playerNotTracked => 'Este jogador não está rastreado. Dados poderão ser imprecisos.';

  @override
  String numberAccounts(int number) {
    return '$number contas';
  }

  @override
  String numberActiveAccounts(int number) {
    return '$number contas ativas';
  }

  @override
  String numberInactiveAccounts(int number) {
    return '$number contas inativas';
  }

  @override
  String get activeAccounts => 'Contas ativas';

  @override
  String get inactiveAccounts => 'Contas inativas';

  @override
  String get noInactiveAccounts => 'Sem contas inativas.';

  @override
  String get noActiveAccounts => 'Sem contas ativas.';

  @override
  String get todoExplanation_title => 'Cálculo de tarefa';

  @override
  String get todoExplanation_intro => 'A percentagem de conclusão da tarefa é calculada com base nas seguintes atividades com ponderações específicas:';

  @override
  String get todoExplanation_legends_title => 'Liga Lendária:';

  @override
  String get todoExplanation_legends => 'Peso de 8 pontos por conta, 1 ataque = 1 ponto.';

  @override
  String get todoExplanation_raids_title => 'Raides:';

  @override
  String get todoExplanation_raids => 'Peso de 5 pontos por conta (ou 6 se o último ataque foi desbloqueado), 1 ataque = 1 ponto.';

  @override
  String get todoExplanation_clanWars_title => 'Guerras de clã:';

  @override
  String get todoExplanation_clanWars => 'Peso de 2 pontos por conta, 1 ataque = 1 ponto.';

  @override
  String get todoExplanation_cwl_title => 'Liga de Guerra de Clãs:';

  @override
  String get todoExplanation_cwl => 'Peso de 1 ponto por conta, 1 ataque = 1 ponto. CWL não pode ser rastreada se o jogador não está no seu clã da liga.';

  @override
  String get todoExplanation_passAndGames_title => 'Passe de temporada & Jogos do Clã:';

  @override
  String get todoExplanation_passAndGames => 'Peso de 2 pontos por conta. A razão baseia-se no número de dias restantes (1 mês para o passe e 6 dias para os jogos de clã). Verde = no caminho certo para completar o passe ou os jogos, vermelho = atrasado.';

  @override
  String get todoExplanation_conclusion => 'A percentagem final é calculada a dividir o total de ações concluídas durante os eventos em curso pelo total de ações necessárias. As contas inativas por mais de 14 dias são excluídas do cálculo.';

  @override
  String get worst => 'Pior';

  @override
  String get best => 'Melhor';

  @override
  String get total => 'Total';

  @override
  String get heroesEquipments => 'Equipamentos de Heróis';

  @override
  String daysAgo(int days) {
    return '$days dias atrás';
  }

  @override
  String dayAgo(int day) {
    return '$day dia atrás';
  }

  @override
  String hourAgo(int hour) {
    return '$hour hora atrás';
  }

  @override
  String hoursAgo(int hours, Object Hours) {
    return '$hours horas atrás';
  }

  @override
  String minuteAgo(int minute) {
    return '$minute minuto atrás';
  }

  @override
  String minutesAgo(int minutes) {
    return '$minutes minutos atrás';
  }

  @override
  String secondAgo(int seconds) {
    return '${seconds}s atrás';
  }

  @override
  String get justNow => 'Agora mesmo';

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
  String get trophiesByMonth => 'Troféus por mês';

  @override
  String get trophiesBySeason => 'Troféus por temporada';

  @override
  String get eosTrophies => 'Troféus de fim de temporada';

  @override
  String get eosDetails => 'End Of Season Details';

  @override
  String get searchClan => 'Procurar clã';

  @override
  String get clanName => 'Clan\'s name';

  @override
  String get nameOrTagClan => 'Nome do clã ou tag';

  @override
  String get noResult => 'Sem resultado.';

  @override
  String get filters => 'Filtros';

  @override
  String get whatever => 'Qualquer que seja';

  @override
  String get any => 'Qualquer';

  @override
  String get notSet => 'Não definido';

  @override
  String get warFrequency => 'Frequência de guerra';

  @override
  String get minimumMembers => 'Membros mínimos';

  @override
  String get maximumMembers => 'Membros máximos';

  @override
  String get location => 'Localização';

  @override
  String get minimumClanPoints => 'Pontos de clã mínimos';

  @override
  String get minimumClanLevel => 'Nível mínimo de clã';

  @override
  String get noClan => 'Sem clã';

  @override
  String get joinClanToUnlockNewFeatures => 'Entre num clã para desbloquear novos recursos.';

  @override
  String get apply => 'Aplicar';

  @override
  String get opened => 'Aberto';

  @override
  String get inviteOnly => 'Convite apenas';

  @override
  String get cancel => 'Cancelar';

  @override
  String get clan => 'Clã';

  @override
  String get clans => 'Clãs';

  @override
  String get members => 'Membros';

  @override
  String get role => 'Cargo';

  @override
  String get expLevel => 'Nível de experiência';

  @override
  String get townHallLevel => 'Nível do CV';

  @override
  String thLevel(int level) {
    return 'CV$level';
  }

  @override
  String bhLevel(int level) {
    return 'CC$level';
  }

  @override
  String townHallLevelLevel(int level) {
    return 'Centro de vila $level';
  }

  @override
  String get byNumberOfWars => 'Por número de guerras';

  @override
  String get ok => 'OK';

  @override
  String get byDateRange => 'Por data';

  @override
  String get selectSeason => 'Selecione a temporada';

  @override
  String get year => 'Ano';

  @override
  String get month => 'Mês';

  @override
  String get allTownHalls => 'Todos os centros de vila';

  @override
  String seasonDate(String date) {
    return 'Temporada $date';
  }

  @override
  String lastXwars(int number) {
    return 'Últimas $number guerras';
  }

  @override
  String get friendly => 'Amigável';

  @override
  String get cwl => 'CWL';

  @override
  String get random => 'Aleatório';

  @override
  String get selectMembersThLevel => 'Nível CV de membros';

  @override
  String get selectOpponentsThLevel => 'Nível CV de oponentes';

  @override
  String get equalThLevel => 'Mesmo CV';

  @override
  String get builderBaseTrophies => 'Troféus da CC';

  @override
  String get donations => 'Doações';

  @override
  String get donationsReceived => 'Doações recebidas';

  @override
  String get donationsRatio => 'Proporção de doações';

  @override
  String get trophies => 'Troféus';

  @override
  String get always => 'Sempre';

  @override
  String get never => 'Nunca';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get oncePerWeek => '1/semana';

  @override
  String get twicePerWeek => '2/semana';

  @override
  String get rarely => 'Raramente';

  @override
  String get warLeague => 'Guerra/Liga';

  @override
  String get war => 'Guerra';

  @override
  String get league => 'Liga';

  @override
  String get wars => 'Guerras';

  @override
  String get ongoingWar => 'Guerra em curso';

  @override
  String get ongoingCwl => 'CWL em curso';

  @override
  String get cantOpenLink => 'Não podemos abrir este link.';

  @override
  String get notInWar => 'Não está em guerra';

  @override
  String get warHistory => 'Histórico de guerra';

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
  String warHistoryAverageClanStarsPerMember(Object stars) {
    return 'O seu clã teve uma média de $stars estrelas por membro nas últimas 50 guerras.';
  }

  @override
  String warHistoryAverageMembers(int members) {
    return '~$members membros por guerra';
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
  String get averageStars => 'Estrelas médias';

  @override
  String get averageDestruction => 'Destruição média';

  @override
  String get oneStar => '1 estrela';

  @override
  String get twoStars => '2 estrelas';

  @override
  String get threeStars => '3 estrelas';

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
  String get warParticipation => 'Participação na guerra';

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
  String get toggleTownHallVisibility => 'Ocultar/Mostrar estatísticas de níveis de CV antigos';

  @override
  String get warLog => 'Registo de guerra';

  @override
  String get publicWarLog => 'Registo de Guerra Público';

  @override
  String get privateWarLog => 'Registo de Guerra privado';

  @override
  String startsIn(String time) {
    return 'Começa em $time';
  }

  @override
  String startsAt(String time) {
    return 'Começa às $time';
  }

  @override
  String endsIn(String time) {
    return 'Termina em $time';
  }

  @override
  String endsAt(String time) {
    return 'Termina às $time';
  }

  @override
  String get joinLeaveLogs => 'Registos de Entrada/Saída';

  @override
  String get join => 'Entrar';

  @override
  String get leave => 'Sair';

  @override
  String get reset => 'Reiniciar';

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
    return '$number jogador(es) saíram do clã durante a temporada atual ($date).';
  }

  @override
  String joinNumberDescription(int number, String date) {
    return '$number jogador(es) entraram no clã durante a temporada atual ($date).';
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
    return 'O seu clã perdeu $number membro(s) esta temporada ($date).';
  }

  @override
  String joinLeaveDifferenceEqualDescription(String date) {
    return 'O seu clã tem o mesmo número de membros que no início da temporada ($date).';
  }

  @override
  String leftOnAt(String date, String time) {
    return 'Saiu a $date às $time.';
  }

  @override
  String joinedOnAt(String date, String time) {
    return 'Entrou a $date às $time.';
  }

  @override
  String get statistics => 'Estatísticas';

  @override
  String get stars => 'Estrelas';

  @override
  String get numberOfStars => 'Número de estrelas';

  @override
  String get destructionRate => 'Taxa de destruição';

  @override
  String get events => 'Eventos';

  @override
  String get team => 'Equipas';

  @override
  String get myTeam => 'A minha equipa';

  @override
  String get enemiesTeam => 'Inimigos';

  @override
  String get defense => 'Defesa';

  @override
  String get defenses => 'Defesas';

  @override
  String get bestDefenses => 'Best defenses';

  @override
  String bestDefenseOutOf(int number) {
    return 'Best defense (out of $number)';
  }

  @override
  String get attack => 'Ataque';

  @override
  String get attacks => 'Ataques';

  @override
  String get bestAttacks => 'Best attacks';

  @override
  String get noAttackYet => 'No attack yet';

  @override
  String get noDefenseYet => 'No defense yet';

  @override
  String get bestPerformance => 'Best performance';

  @override
  String get victory => 'Vitória';

  @override
  String get defeat => 'Derrota';

  @override
  String get draw => 'Empate';

  @override
  String get perfectWar => 'Guerra perfeita';

  @override
  String get newest => 'Mais novo';

  @override
  String get oldest => 'Mais velho';

  @override
  String get warEnded => 'Guerra acabou';

  @override
  String get preparation => 'Preparação';

  @override
  String isNotInWar(String clan) {
    return '$clan não está em guerra.';
  }

  @override
  String warLogIsClosed(String clan) {
    return 'Os registos de guerra de $clan estão fechados.';
  }

  @override
  String get askForWar => 'Contacta o líder ou colíder para começar a guerra.';

  @override
  String get askForWarLogOpening => 'Contacta o líder ou colíder para abrir os registos de guerra.';

  @override
  String get warLogClosed => 'Registo de guerra fechado.';

  @override
  String get rounds => 'Rondas';

  @override
  String roundNumber(int number) {
    return 'Round $number';
  }

  @override
  String currentRound(int number) {
    return 'Current round (Round $number)';
  }

  @override
  String get noDataAvailableForThisWar => 'Não há dados disponíveis para esta guerra';

  @override
  String get stateOfTheWar => 'Estado da guerra';

  @override
  String starsNeededToTakeTheLead(String clan, int star, int star2, String percent, Object stars2) {
    return '$clan ainda precisa de $star estrela(s) ou $stars2 estrela(s) e $percent% para assumir a liderança.';
  }

  @override
  String starsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan ainda precisa de $percent% ou mais 1 estrela para assumir a liderança';
  }

  @override
  String get clanDraw => 'Os dois clãs estão empatados';

  @override
  String get fastCalculator => 'Calculadora rápida';

  @override
  String fastCalculatorAnswer(String percentNeedeed, String result, Object percentNeeded) {
    return 'Para conquistar uma taxa de destruição de $percentNeeded%, um resultado total de $result% é preciso.';
  }

  @override
  String get teamSize => 'Tamanho da equipa';

  @override
  String get neededOverall => '% Necessário, em geral';

  @override
  String get calculate => 'Calcular';

  @override
  String get warStats => 'Estatísticas de guerra';

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
  String get membersStats => 'Estatísticas de membros';

  @override
  String get clanWarLeague => 'Liga de Guerra de Clãs';

  @override
  String cwlRank(int rank) {
    return 'O seu clã está atualmente classificado $rank.';
  }

  @override
  String cwlStars(int stars) {
    return 'O seu clã têm um total de $stars estrelas.';
  }

  @override
  String cwlMissingStarsFromNext(int stars) {
    return 'Faltam $stars estrelas para o seu clã alcançar o próximo clã.';
  }

  @override
  String cwlMissingStarsFromFirst(int stars) {
    return 'Faltam $stars estrelas para o seu clã alcançar o primeiro clã.';
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
  String cwlCurrentRound(int round) {
    return 'Atualmente é a ronda $round.';
  }

  @override
  String get noAccountLinkedToYourProfileFound => 'Nenhuma conta vinculada ao seu perfil foi encontrada';

  @override
  String get management => 'Gestão';

  @override
  String get comingSoon => 'Em breve!';

  @override
  String get connectionError => 'Ocorreu um erro. Por favor, verifique a sua conexão de internet e tente novamente.';

  @override
  String get connectionErrorRelaunch => 'Ocorreu um erro. Por favor, verifique a sua conexão de internet e reinicie a aplicação.';

  @override
  String updatedAt(String time) {
    return 'Atualizado às $time';
  }

  @override
  String get tools => 'Ferramentas';

  @override
  String get community => 'Comunidade';

  @override
  String get raids => 'Raids';

  @override
  String get lastRaids => 'Últimos raides';

  @override
  String get ongoingRaids => 'Raides em curso';

  @override
  String get districtsDestroyed => 'Distritos destruídos';

  @override
  String get raidsCompleted => 'Raides finalizados';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get maintenanceDescription => 'Clash of Clans is currently under maintenance, so we can\'t access the API. Please check back later.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get downloadTooltip => 'Download CWL summary';

  @override
  String get downloadInProgress => 'Downloading file... It can take a few seconds...';

  @override
  String downloadSuccess(String path) {
    return 'File saved successfully in \$$path';
  }

  @override
  String get downloadError => 'Failed to download file';
}
