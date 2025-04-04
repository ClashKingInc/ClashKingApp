// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get creatorCode => 'Código de Creador: ClashKing';

  @override
  String get errorTitle => 'Oops! Our servers might have taken a fireball to the face! We\'re casting a healing spell... Try again in a moment.';

  @override
  String get errorSubtitle => 'If the issue persists, check our Discord Server to see if we\'re aware of it.';

  @override
  String get retry => 'Retry';

  @override
  String get signInWithDiscord => 'Iniciar sesión con Discord';

  @override
  String get guestMode => 'Modo Invitado';

  @override
  String get needHelpJoinDiscord => '¿Necesitas ayuda? Únete a nosotros en Discord.';

  @override
  String get loginError => 'An error occurred while logging in. Please try again later.';

  @override
  String get createGuestProfile => 'Crear perfil de invitado';

  @override
  String doesNotExist(String tag) {
    return '$tag no existe.';
  }

  @override
  String isAlreadyLinked(String tag) {
    return '$tag ya está vinculado a alguien.';
  }

  @override
  String get username => 'Usuario';

  @override
  String get pleaseEnterUsername => 'Por favor ingrese un usuario';

  @override
  String get playerTag => 'Player Tag (#ABC123)';

  @override
  String get playerTags => 'Etiquetas de Jugador';

  @override
  String get linkedAccounts => 'Linked Accounts';

  @override
  String followingTagsDoNotExist(String tags) {
    return 'Las siguientes etiquetas no existen: $tags.';
  }

  @override
  String followingTagsAreAlreadyLinked(String tags) {
    return 'Las siguientes etiquetas ya están vinculadas a alguien: $tags.';
  }

  @override
  String get welcome => '¡Bienvenido!';

  @override
  String get welcomeMessage => 'Por favor, añade una o más cuentas de Clash Of Clan a tu perfil. Puedes añadir o eliminar cuentas más tarde.';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get language => 'Idioma';

  @override
  String get settings => 'Ajustes';

  @override
  String get toggleTheme => 'Cambiar tema';

  @override
  String get selectLanguage => 'Selecciona un idioma';

  @override
  String get faq => 'FAQ';

  @override
  String get faqSubtitle => 'Preguntas frecuentes';

  @override
  String get faqIsThisFromSupercell => '¿Es esta app de Supercell?';

  @override
  String get faqFanContentPolicy => 'Este material no es oficial y no está avalado por Supercell. Para obtener más información, consulte la Política de Contenido del Fan de Supercell: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate => '¿Por qué los datos a veces son incorrectos o faltan?';

  @override
  String get faqClanNotTracked => 'El clan no está bajo seguimiento';

  @override
  String get faqClanNotTrackedAnswer => 'ClashKing solo puede obtener esta información si el clan es rastreado. Si tu clan no parece ser seguido, por favor invítalo a un servidor de Discord y usa el comando /addclan. Esperamos que esta función esté disponible en la aplicación pronto.';

  @override
  String get faqTrackingDown => 'Rastreando';

  @override
  String get faqTrackingDownAnswer => 'El seguimiento puede dejar de funcionar por un período de tiempo. Por eso a veces puedes tener agujeros en tus datos. Estamos trabajando en mejorar esto.';

  @override
  String get faqApiLimitation => 'Limitación de la API de Clash of Clans';

  @override
  String get faqApiLimitationAnswer => 'Algunos datos son proporcionados por Clash of Clans y su API tiene algunas limitaciones. Este es el caso del rastreo de leyendas en el que a veces apilan la ganancia y la pérdida de trofeos como si fuera un ataque. También es por eso que no tenemos información sobre sus niveles de edificios.';

  @override
  String get faqSupportWork => '¿Cómo puedo apoyar tu trabajo?';

  @override
  String get faqSupportWorkAnswer => 'Hay varias formas de apoyarnos:';

  @override
  String get faqUseCodeClashKing => 'Usa el código \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Apoyanos en Patreon';

  @override
  String get faqShareTheApp => 'Comparte la app con tus amigos';

  @override
  String get faqRateTheApp => 'Valora esta App en la tienda';

  @override
  String get faqHelpUsTranslate => 'Ayúdanos a traducir la app';

  @override
  String get faqHowToInviteTheBot => '¿Cómo puedo invitar a tu bot a mi servidor de Discord?';

  @override
  String get faqHowToInviteTheBotAnswer => 'Puedes invitar a nuestro bot en tu servidor haciendo clic en el botón de abajo. Necesitarás tener el permiso \"Administrar Servidor\" para añadir el bot.';

  @override
  String get faqInviteTheBot => 'Invitar al Bot \"ClashKing\"';

  @override
  String get faqNeedHelp => 'Necesito ayuda o me gustaría hacer una sugerencia. ¿Cómo puedo contactarte?';

  @override
  String get faqNeedHelpAnswer => 'Puedes unirte a nuestro servidor de Discord y pedir ayuda o hacer un comentario allí, o enviarnos un correo a devs@clashkingbot.com. Por favor, escribe solo en inglés o francés.';

  @override
  String get faqSendEmail => 'Enviar un correo';

  @override
  String get faqJoinDiscord => 'Unirse al Servidor de Discord';

  @override
  String get faqCannotOpenMailClient => 'For some reasons we can\'t open your mail client. We copied the email address for you. You can write an email and paste the address in the recipient field.';

  @override
  String get helpUsTranslate => 'Ayúdanos a traducir';

  @override
  String get suggestFeatures => 'Suggest features';

  @override
  String get thankYou => '¡Gracias!';

  @override
  String get thankYouContent => '¡Un enorme agradecimiento a todos nuestros increíbles traductores que nos ayudan a hacer que esta aplicación sea accesible para más personas en todo el mundo!';

  @override
  String get helpTranslateContent => 'You can help us translate the app on Crowdin. If your language is not available on Crowdin, feel free to request it in our Discord Server. Thank you so much for your help!';

  @override
  String get helpTranslateButton => 'Ayuda a traducir en Crowdin';

  @override
  String get versionDevice => 'Version & Device';

  @override
  String get loading => 'Cargando...';

  @override
  String get errorLoadingVersion => 'Error al cargar la versión';

  @override
  String get currentTranslators => 'Traductores Actuales';

  @override
  String get betaFeature => 'Función beta';

  @override
  String get beta => 'BETA';

  @override
  String get betaDescription => 'This feature is currently in beta, it may have some bugs or be incomplete. We are actively working on improvements and welcome your feedback. Please share your ideas and report any issues in our Discord Server to help us make it better.';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get all => 'Todo';

  @override
  String get hourIndicator => 'h';

  @override
  String get minIndicator => 'm';

  @override
  String get noDataAvailable => 'No hay datos disponibles.';

  @override
  String get close => 'Cerrar';

  @override
  String get closed => 'Cerrado';

  @override
  String get error => 'Error';

  @override
  String get player => 'Jugador';

  @override
  String notFoundOrNotLinkedToOurSystem(String player) {
    return '$player no encontrado o no enlazado a nuestro sistema.';
  }

  @override
  String get tryAnotherNameOrTagOrLinkIt => 'Intenta otro nombre/etiqueta o enlazalo.';

  @override
  String get playerNotFound => 'Jugador no encontrado';

  @override
  String get noValueEntered => 'No hay valor ingresado';

  @override
  String get manage => 'Gestionar';

  @override
  String get enterPlayerTag => 'Ingrese una etiqueta de jugador';

  @override
  String get add => 'Añadir';

  @override
  String get delete => 'Eliminar';

  @override
  String get addAccount => 'Añadir cuenta';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get playerTagNotExists => 'La etiqueta de jugador ingresada no existe.';

  @override
  String accountAlreadyLinked(Object tag) {
    return 'La etiqueta del jugador ya está vinculada a alguien.';
  }

  @override
  String get enterApiToken => 'Please enter the account API token to confirm it\'s yours. You can find it in Clash of Clans Settings > More Settings > API Token.';

  @override
  String get wrongApiToken => 'The API token entered is incorrect';

  @override
  String get accountAlreadyLinkedToYou => 'La etiqueta del jugador ya está vinculada a alguien.';

  @override
  String get apiToken => 'Account API Token';

  @override
  String get failedToAddTryAgain => 'Error al añadir el enlace. Inténtalo de nuevo más tarde.';

  @override
  String get fillAllFields => 'Please fill all fields.';

  @override
  String get failedToDeleteTryAgain => 'Error al eliminar el enlace. Inténtalo de nuevo más tarde.';

  @override
  String get enterPlayerTagWarning => 'You must enter a player tag and click on the \"+\" to continue.';

  @override
  String get failedToLoadAccountData => 'Failed to load accounts data.';

  @override
  String get loadAccountData => 'Load accounts data';

  @override
  String get search => 'Busca';

  @override
  String get warning => 'Advertencia';

  @override
  String get exitAppToOpenClash => 'You are about to leave the app to open Clash of Clans.';

  @override
  String get confirmLogout => 'Are you sure you want to log out?';

  @override
  String get tagOrNamePlayer => 'Etiqueta o nombre del jugador';

  @override
  String get searchPlayer => 'Buscar jugador';

  @override
  String get nameOrTagPlayer => 'Nombre o etiqueta del jugador';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Tu clan es \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(String ratio, String donations, String received) {
    return 'Tu proporción de donaciones es $ratio. Has donado $donations tropas y recibido $received tropas.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Tu preferencia de guerra es \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'Tienes $stars estrellas de guerra.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'Tienes $trophies trofeos. Actualmente estás en $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Your Town Hall level is $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Tu nivel del Ayuntamiento de Constructor es $level y tienes $trophies trofeos.';
  }

  @override
  String get dashboard => 'Panel';

  @override
  String get homeBase => 'Aldea';

  @override
  String get th => 'TH';

  @override
  String get builderBase => 'Base del constructor';

  @override
  String get bh => 'BH';

  @override
  String get clanCapital => 'Capital del Clan';

  @override
  String get leader => 'Líder';

  @override
  String get coLeader => 'Colíder';

  @override
  String get elder => 'Veterano';

  @override
  String get member => 'Miembro';

  @override
  String get ready => 'Optar por participar';

  @override
  String get unready => 'Optar por no participar';

  @override
  String level(int level, int maxLevel) {
    return 'Level: $level/$maxLevel';
  }

  @override
  String get heroes => 'Héroes';

  @override
  String get equipment => 'Equipos';

  @override
  String get troops => 'Tropas';

  @override
  String get superTroops => 'Supertropas';

  @override
  String get activeSuperTroops => 'Supertropas Activas';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get pets => 'Mascoras';

  @override
  String get siegeMachines => 'Máquinas de asedio';

  @override
  String get spells => 'Hechizos';

  @override
  String get achievements => 'Logros';

  @override
  String get byDay => 'Por día';

  @override
  String get bySeason => 'Por Temporada';

  @override
  String dayIndex(int index) {
    return 'Día $index';
  }

  @override
  String indexDays(int index) {
    return '$index días';
  }

  @override
  String get bestTrophies => 'Mejores Trofeos';

  @override
  String get mostAttacks => 'Most Attacks';

  @override
  String get lastSeason => 'Última Temporada';

  @override
  String get bestRank => 'Mejor Rango Global';

  @override
  String daysLeft(int days) {
    return '$days días restantes';
  }

  @override
  String get date => 'Fecha';

  @override
  String get stats => 'Estadísticas';

  @override
  String get details => 'Details';

  @override
  String get seasonStats => 'Estadísticas de la Temporada';

  @override
  String get charts => 'Gráficos';

  @override
  String get history => 'Curso';

  @override
  String get legendLeague => 'Liga de Leyendas';

  @override
  String get notInLegendLeague => 'No está en la Liga de Leyendas';

  @override
  String get noLegendData => 'No se han encontrado datos de leyenda hoy';

  @override
  String legendStartDescription(String trophies) {
    return 'Empezaste el día con $trophies trofeos.';
  }

  @override
  String legendNoRankLocalDescription(String country, int trophies) {
    return 'Actualmente no estás clasificado ($country) con $trophies trofeos.';
  }

  @override
  String legendRankLocalDescription(Object country, Object rank, Object trophies) {
    return 'Actualmente estás clasificado $rank ($country) con $trophies trofeos.';
  }

  @override
  String legendGainDescription(int trophies) {
    return 'Has ganado $trophies trofeos por ahora.';
  }

  @override
  String legendLossDescription(int trophies) {
    return 'Has perdido $trophies trofeos por ahora.';
  }

  @override
  String legendNoGlobalRankDescription(int trophies) {
    return 'Actualmente no estás clasificado a nivel global con $trophies trofeos.';
  }

  @override
  String legendGlobalRankDescription(int rank, Object trophies) {
    return 'Actualmente estás clasificado como $rank a nivel global.';
  }

  @override
  String get noRank => 'Sin ranking';

  @override
  String get started => 'Comenzado';

  @override
  String get ended => 'Terminado';

  @override
  String get average => 'Promedio';

  @override
  String get remaining => 'Restante';

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
    return 'Última actividad: $date';
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
  String get worst => 'Peor';

  @override
  String get best => 'Mejor';

  @override
  String get total => 'Total';

  @override
  String get heroesEquipments => 'Hero equipments';

  @override
  String daysAgo(int days) {
    return 'hace $days días';
  }

  @override
  String dayAgo(int day) {
    return 'Hace $day día';
  }

  @override
  String hourAgo(int hour) {
    return 'Hace $hour hora';
  }

  @override
  String hoursAgo(int hours, Object Hours) {
    return 'Hace $hours horas';
  }

  @override
  String minuteAgo(int minute) {
    return 'Hace $minute minuto';
  }

  @override
  String minutesAgo(int minutes) {
    return 'hace $minutes minutos';
  }

  @override
  String secondAgo(int seconds) {
    return 'Hace $seconds segundos';
  }

  @override
  String get justNow => 'Ahora mismo';

  @override
  String get trophiesByMonth => 'Trofeos por mes';

  @override
  String get trophiesBySeason => 'Trofeos por temporada';

  @override
  String get eosTrophies => 'Trofeos de fin de temporada';

  @override
  String get eosDetails => 'End Of Season Details';

  @override
  String get searchClan => 'Buscar clan';

  @override
  String get nameOrTagClan => 'Nombre o etiqueta del clan';

  @override
  String get noResult => 'Sin resultados.';

  @override
  String get filters => 'Filtros';

  @override
  String get whatever => 'Como sea';

  @override
  String get any => 'Cualquiera';

  @override
  String get notSet => 'No establecido';

  @override
  String get warFrequency => 'Frecuencia de guerra';

  @override
  String get minimumMembers => 'Miembros mínimos';

  @override
  String get maximumMembers => 'Miembros máximos';

  @override
  String get location => 'Localización';

  @override
  String get minimumClanPoints => 'Puntos mínimos del clan';

  @override
  String get minimumClanLevel => 'Nivel mínimo del clan';

  @override
  String get noClan => 'Sin clan';

  @override
  String get joinClanToUnlockNewFeatures => 'Únete a un clan para desbloquear nuevas funciones.';

  @override
  String get apply => 'Aplicar';

  @override
  String get opened => 'Abierto';

  @override
  String get inviteOnly => 'Solo invitación';

  @override
  String get cancel => 'Cancelar';

  @override
  String get clan => 'Clan';

  @override
  String get clans => 'Clanes';

  @override
  String get members => 'Miembros';

  @override
  String get role => 'Rol';

  @override
  String get expLevel => 'Nivel de Experiencia';

  @override
  String get townHallLevel => 'Nivel TH';

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
  String get ok => 'Ok';

  @override
  String get byDateRange => 'By date range';

  @override
  String get selectSeason => 'Select a season';

  @override
  String get year => 'Año';

  @override
  String get month => 'Mes';

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
  String get random => 'Aleatorio';

  @override
  String get selectMembersThLevel => 'Members TH Level';

  @override
  String get selectOpponentsThLevel => 'Opponents TH Level';

  @override
  String get equalThLevel => 'Equal TH';

  @override
  String get builderBaseTrophies => 'Trofeos BB';

  @override
  String get donations => 'Donaciones';

  @override
  String get donationsReceived => 'Donaciones recibidas';

  @override
  String get donationsRatio => 'Relación de donaciones';

  @override
  String get trophies => 'Trofeos';

  @override
  String get always => 'Siempre';

  @override
  String get never => 'Nunca';

  @override
  String get unknown => 'Desconocido';

  @override
  String get oncePerWeek => 'una vez por semana';

  @override
  String get twicePerWeek => 'dos veces a la semana';

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
  String get ongoingWar => 'Guerra en curso';

  @override
  String get ongoingCwl => 'LGC en curso';

  @override
  String get cantOpenLink => 'No podemos abrir este enlace.';

  @override
  String get notInWar => 'No está en guerra';

  @override
  String get warHistory => 'Curso de Guerra';

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
  String get warLog => 'Registro de guerra';

  @override
  String get publicWarLog => 'Registro de guerra pública';

  @override
  String get privateWarLog => 'Registro de guerra privada';

  @override
  String startsIn(String time) {
    return 'Comienza en $time';
  }

  @override
  String startsAt(String time) {
    return 'Comienza en $time';
  }

  @override
  String endsIn(String time) {
    return 'Termina en $time';
  }

  @override
  String endsAt(String time) {
    return 'Termina en $time';
  }

  @override
  String get joinLeaveLogs => 'Registros de Entrada/Salida';

  @override
  String get join => 'Unirse';

  @override
  String get leave => 'Abandonar';

  @override
  String get reset => 'Restablecer';

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
    return 'Tu clan tiene el mismo número de miembros que al principio de la temporada ($date).';
  }

  @override
  String leftOnAt(String date, String time) {
    return 'Se fue el $date a las $time.';
  }

  @override
  String joinedOnAt(String date, String time) {
    return 'Se unió el $date a las $time.';
  }

  @override
  String get statistics => 'Estadísticas';

  @override
  String get stars => 'Estrellas';

  @override
  String get numberOfStars => 'Número de estrellas';

  @override
  String get destructionRate => 'Tasa de destrucción';

  @override
  String get events => 'Eventos';

  @override
  String get team => 'Grupos';

  @override
  String get myTeam => 'Mi equipo';

  @override
  String get enemiesTeam => 'Enemigos';

  @override
  String get defense => 'Defensa';

  @override
  String get defenses => 'Defensas';

  @override
  String get attack => 'Ataque';

  @override
  String get attacks => 'Ataques';

  @override
  String get victory => '¡Victoria!';

  @override
  String get defeat => 'Derrota';

  @override
  String get draw => 'Empate';

  @override
  String get perfectWar => 'Guerra perfecta';

  @override
  String get newest => 'Más reciente';

  @override
  String get oldest => 'Más antiguos';

  @override
  String get warEnded => 'La guerra ha terminado';

  @override
  String get preparation => 'Preparación';

  @override
  String isNotInWar(String clan) {
    return '$clan no está en guerra.';
  }

  @override
  String warLogIsClosed(String clan) {
    return 'El registro de guerra de $clan está cerrado.';
  }

  @override
  String get askForWar => 'Contacta a un líder o un colíder para iniciar una guerra.';

  @override
  String get askForWarLogOpening => 'Contacta a un líder o un colíder para hacer público el registro de guerra.';

  @override
  String get warLogClosed => 'El registro de guerra cerrado.';

  @override
  String get rounds => 'Rondas';

  @override
  String get noDataAvailableForThisWar => 'No hay datos disponibles para esta guerra';

  @override
  String get stateOfTheWar => 'Estado de la guerra';

  @override
  String starsNeededToTakeTheLead(String clan, int star, int star2, String percent, Object stars2) {
    return '$clan todavía necesita $star estrella(s) más o $stars2 estrella(s) y $percent% para tomar la delantera.';
  }

  @override
  String starsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan todavía necesita $percent% o 1 estrella más para tomar la delantera';
  }

  @override
  String get clanDraw => 'Ambos clanes están empatados';

  @override
  String get fastCalculator => 'Calculadora rápida';

  @override
  String fastCalculatorAnswer(String percentNeedeed, String result, Object percentNeeded) {
    return 'Para lograr una tasa de destrucción de $percentNeeded%, se necesita un total de $result%.';
  }

  @override
  String get teamSize => 'Tamaño del equipo';

  @override
  String get neededOverall => '% Total necesario';

  @override
  String get calculate => 'Calcular';

  @override
  String get warStats => 'Estadísticas de Guerra';

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
  String get noAccountLinkedToYourProfileFound => 'No se encontró ninguna cuenta vinculada a su perfil';

  @override
  String get management => 'Administración';

  @override
  String get comingSoon => '¡Próximamente!';

  @override
  String get connectionError => 'Se ha producido un error. Por favor, comprueba tu conexión a internet e inténtalo de nuevo.';

  @override
  String get connectionErrorRelaunch => 'Se ha producido un error. Por favor, verifica tu conexión a internet y vuelve a iniciar la aplicación.';

  @override
  String updatedAt(String time) {
    return 'Updated at $time';
  }

  @override
  String get tools => 'Herramientas';

  @override
  String get community => 'Comunidad';

  @override
  String get lastRaids => 'Last raids';

  @override
  String get ongoingRaids => 'Ongoing raids';

  @override
  String get districtsDestroyed => 'Districts destroyed';

  @override
  String get raidsCompleted => 'Raids completed';
}

/// The translations for Spanish Castilian, as used in Spain (`es_ES`).
class AppLocalizationsEsEs extends AppLocalizationsEs {
  AppLocalizationsEsEs(): super('es_ES');

  @override
  String get creatorCode => 'Código de Creador: ClashKing';

  @override
  String get signInWithDiscord => 'Iniciar sesión con Discord';

  @override
  String get guestMode => 'Modo Invitado';

  @override
  String get needHelpJoinDiscord => '¿Necesitas ayuda? Únete a nosotros en Discord.';

  @override
  String get createGuestProfile => 'Crear perfil de invitado';

  @override
  String doesNotExist(String tag) {
    return '$tag no existe.';
  }

  @override
  String isAlreadyLinked(String tag) {
    return '$tag ya está vinculado a alguien.';
  }

  @override
  String get username => 'Usuario';

  @override
  String get pleaseEnterUsername => 'Por favor ingrese un usuario';

  @override
  String get playerTags => 'Etiquetas de Jugador';

  @override
  String followingTagsDoNotExist(String tags) {
    return 'Las siguientes etiquetas no existen: $tags.';
  }

  @override
  String followingTagsAreAlreadyLinked(String tags) {
    return 'Las siguientes etiquetas ya están vinculadas a alguien: $tags.';
  }

  @override
  String get welcome => '¡Bienvenido!';

  @override
  String get welcomeMessage => 'Por favor, añade una o más cuentas de Clash Of Clan a tu perfil. Puedes añadir o eliminar cuentas más tarde.';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get language => 'Idioma';

  @override
  String get settings => 'Ajustes';

  @override
  String get toggleTheme => 'Cambiar tema';

  @override
  String get selectLanguage => 'Selecciona un idioma';

  @override
  String get faq => 'FAQ';

  @override
  String get faqSubtitle => 'Preguntas frecuentes';

  @override
  String get faqIsThisFromSupercell => '¿Es esta app de Supercell?';

  @override
  String get faqFanContentPolicy => 'Este material no es oficial y no está avalado por Supercell. Para obtener más información, consulte la Política de Contenido del Fan de Supercell: www.supercell.com/fan-content-policy';

  @override
  String get faqWhyNotAccurate => '¿Por qué los datos a veces son incorrectos o faltan?';

  @override
  String get faqClanNotTracked => 'El clan no está bajo seguimiento';

  @override
  String get faqClanNotTrackedAnswer => 'ClashKing solo puede obtener esta información si el clan es rastreado. Si tu clan no parece ser seguido, por favor invítalo a un servidor de Discord y usa el comando /addclan. Esperamos que esta función esté disponible en la aplicación pronto.';

  @override
  String get faqTrackingDown => 'Rastreando';

  @override
  String get faqTrackingDownAnswer => 'El seguimiento puede dejar de funcionar por un período de tiempo. Por eso a veces puedes tener agujeros en tus datos. Estamos trabajando en mejorar esto.';

  @override
  String get faqApiLimitation => 'Limitación de la API de Clash of Clans';

  @override
  String get faqApiLimitationAnswer => 'Algunos datos son proporcionados por Clash of Clans y su API tiene algunas limitaciones. Este es el caso del rastreo de leyendas en el que a veces apilan la ganancia y la pérdida de trofeos como si fuera un ataque. También es por eso que no tenemos información sobre sus niveles de edificios.';

  @override
  String get faqSupportWork => '¿Cómo puedo apoyar tu trabajo?';

  @override
  String get faqSupportWorkAnswer => 'Hay varias formas de apoyarnos:';

  @override
  String get faqUseCodeClashKing => 'Usa el código \"ClashKing\"';

  @override
  String get faqSupportUsOnPatreon => 'Apoyanos en Patreon';

  @override
  String get faqShareTheApp => 'Comparte la app con tus amigos';

  @override
  String get faqRateTheApp => 'Valora esta App en la tienda';

  @override
  String get faqHelpUsTranslate => 'Ayúdanos a traducir la app';

  @override
  String get faqHowToInviteTheBot => '¿Cómo puedo invitar a tu bot a mi servidor de Discord?';

  @override
  String get faqHowToInviteTheBotAnswer => 'Puedes invitar a nuestro bot en tu servidor haciendo clic en el botón de abajo. Necesitarás tener el permiso \"Administrar Servidor\" para añadir el bot.';

  @override
  String get faqInviteTheBot => 'Invitar al Bot \"ClashKing\"';

  @override
  String get faqNeedHelp => 'Necesito ayuda o me gustaría hacer una sugerencia. ¿Cómo puedo contactarte?';

  @override
  String get faqNeedHelpAnswer => 'Puedes unirte a nuestro servidor de Discord y pedir ayuda o hacer un comentario allí, o enviarnos un correo a devs@clashkingbot.com. Por favor, escribe solo en inglés o francés.';

  @override
  String get faqSendEmail => 'Enviar un correo';

  @override
  String get faqJoinDiscord => 'Unirse al Servidor de Discord';

  @override
  String get helpUsTranslate => 'Ayúdanos a traducir';

  @override
  String get suggestFeatures => 'Suggest features';

  @override
  String get thankYou => '¡Gracias!';

  @override
  String get thankYouContent => '¡Un enorme agradecimiento a todos nuestros increíbles traductores que nos ayudan a hacer que esta aplicación sea accesible para más personas en todo el mundo!';

  @override
  String get helpTranslateContent => 'Puedes ayudarnos a traducir la aplicación en Crowdin. Si tu idioma no está disponible en Crowdin, no dudes en solicitarlo en nuestro servidor de Discord. ¡Muchas gracias por tu ayuda!';

  @override
  String get helpTranslateButton => 'Ayuda a traducir en Crowdin';

  @override
  String get currentTranslators => 'Traductores Actuales';

  @override
  String get betaFeature => 'Beta Feature';

  @override
  String get beta => 'BETA';

  @override
  String get betaDescription => 'This feature is in beta and may contain some bugs and be incomplete. It will be improved in the upcoming updates. Feel free to propose ideas and report bugs from our Discord server to help us improve it.';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get all => 'Todo';

  @override
  String get hourIndicator => 'h';

  @override
  String get minIndicator => 'm';

  @override
  String get noDataAvailable => 'No hay datos disponibles.';

  @override
  String get close => 'Cerrar';

  @override
  String get closed => 'Cerrado';

  @override
  String get error => 'Error';

  @override
  String get player => 'Jugador';

  @override
  String notFoundOrNotLinkedToOurSystem(String player) {
    return '$player no encontrado o no enlazado a nuestro sistema.';
  }

  @override
  String get tryAnotherNameOrTagOrLinkIt => 'Intenta otro nombre/etiqueta o enlazalo.';

  @override
  String get playerNotFound => 'Jugador no encontrado';

  @override
  String get noValueEntered => 'No hay valor ingresado';

  @override
  String get manage => 'Gestionar';

  @override
  String get enterPlayerTag => 'Ingrese una etiqueta de jugador';

  @override
  String get add => 'Añadir';

  @override
  String get delete => 'Eliminar';

  @override
  String get addAccount => 'Añadir cuenta';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get playerTagNotExists => 'La etiqueta de jugador ingresada no existe.';

  @override
  String accountAlreadyLinked(Object tag) {
    return 'La etiqueta del jugador ya está vinculada a alguien.';
  }

  @override
  String get failedToAddTryAgain => 'Error al añadir el enlace. Inténtalo de nuevo más tarde.';

  @override
  String get failedToDeleteTryAgain => 'Error al eliminar el enlace. Inténtalo de nuevo más tarde.';

  @override
  String get search => 'Busca';

  @override
  String get warning => 'Warning';

  @override
  String get exitAppToOpenClash => 'You are about to leave the app to open Clash of Clans.';

  @override
  String get tagOrNamePlayer => 'Etiqueta o nombre del jugador';

  @override
  String get searchPlayer => 'Buscar jugador';

  @override
  String get nameOrTagPlayer => 'Nombre o etiqueta del jugador';

  @override
  String playerClanDescription(String clan, String tag) {
    return 'Tu clan es \"$clan\" ($tag).';
  }

  @override
  String playerRatioDescription(String ratio, String donations, String received) {
    return 'Tu proporción de donaciones es $ratio. Has donado $donations tropas y recibido $received tropas.';
  }

  @override
  String playerWarPreferenceDescription(String preference) {
    return 'Tu preferencia de guerra es \"$preference\".';
  }

  @override
  String playerWarStarsDescription(int stars) {
    return 'Tienes $stars estrellas de guerra.';
  }

  @override
  String playerTrophiesDescription(int trophies, String league) {
    return 'Tienes $trophies trofeos. Actualmente estás en $league.';
  }

  @override
  String playerTownHallLevelDescription(int level) {
    return 'Tu nivel de ayuntamiento es $level.';
  }

  @override
  String playerBuilderBaseDescription(int level, int trophies) {
    return 'Tu nivel del Ayuntamiento de Constructor es $level y tienes $trophies trofeos.';
  }

  @override
  String get dashboard => 'Panel';

  @override
  String get homeBase => 'Aldea';

  @override
  String get th => 'TH';

  @override
  String get builderBase => 'Base del constructor';

  @override
  String get bh => 'BH';

  @override
  String get clanCapital => 'Capital del Clan';

  @override
  String get leader => 'Líder';

  @override
  String get coLeader => 'Colíder';

  @override
  String get elder => 'Veterano';

  @override
  String get member => 'Miembro';

  @override
  String get ready => 'Optar por participar';

  @override
  String get unready => 'Optar por no participar';

  @override
  String get heroes => 'Héroes';

  @override
  String get equipment => 'Equipos';

  @override
  String get troops => 'Tropas';

  @override
  String get superTroops => 'Supertropas';

  @override
  String get activeSuperTroops => 'Supertropas Activas';

  @override
  String get pets => 'Mascoras';

  @override
  String get siegeMachines => 'Máquinas de asedio';

  @override
  String get spells => 'Hechizos';

  @override
  String get achievements => 'Logros';

  @override
  String get byDay => 'Por día';

  @override
  String get bySeason => 'Por Temporada';

  @override
  String dayIndex(int index) {
    return 'Día $index';
  }

  @override
  String indexDays(int index) {
    return '$index días';
  }

  @override
  String get bestTrophies => 'Mejores Trofeos';

  @override
  String get mostAttacks => 'Most Attacks';

  @override
  String get lastSeason => 'Última Temporada';

  @override
  String get bestRank => 'Mejor Rango Global';

  @override
  String daysLeft(int days) {
    return '$days días restantes';
  }

  @override
  String get date => 'Fecha';

  @override
  String get stats => 'Estadísticas';

  @override
  String get details => 'Details';

  @override
  String get seasonStats => 'Estadísticas de la Temporada';

  @override
  String get charts => 'Gráficos';

  @override
  String get history => 'Curso';

  @override
  String get legendLeague => 'Liga de Leyendas';

  @override
  String get notInLegendLeague => 'No está en la Liga de Leyendas';

  @override
  String get noLegendData => 'No se han encontrado datos de leyenda hoy';

  @override
  String legendStartDescription(String trophies) {
    return 'Empezaste el día con $trophies trofeos.';
  }

  @override
  String legendNoRankLocalDescription(String country, int trophies) {
    return 'Actualmente no estás clasificado ($country) con $trophies trofeos.';
  }

  @override
  String legendRankLocalDescription(Object country, Object rank, Object trophies) {
    return 'Actualmente estás clasificado $rank ($country) con $trophies trofeos.';
  }

  @override
  String legendGainDescription(int trophies) {
    return 'Has ganado $trophies trofeos por ahora.';
  }

  @override
  String legendLossDescription(int trophies) {
    return 'Has perdido $trophies trofeos por ahora.';
  }

  @override
  String legendNoGlobalRankDescription(int trophies) {
    return 'Actualmente no estás clasificado a nivel global con $trophies trofeos.';
  }

  @override
  String legendGlobalRankDescription(int rank, Object trophies) {
    return 'Actualmente estás clasificado como $rank a nivel global.';
  }

  @override
  String get noRank => 'Sin ranking';

  @override
  String get started => 'Comenzado';

  @override
  String get ended => 'Terminado';

  @override
  String get average => 'Promedio';

  @override
  String get remaining => 'Restante';

  @override
  String get legendsTitle => 'Inacurate Data?';

  @override
  String get legendsExplanation_intro => 'Due to limitations in the Clash of Clans API, our data might not always be perfectly accurate. Here\'s why:\n';

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
  String get toDoList => 'Lista de tareas pendientes';

  @override
  String lastActive(String date) {
    return 'Última actividad: $date';
  }

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
  String get worst => 'Peor';

  @override
  String get best => 'Mejor';

  @override
  String get total => 'Total';

  @override
  String get heroesEquipments => 'Equipo heroico';

  @override
  String daysAgo(int days) {
    return 'hace $days días';
  }

  @override
  String dayAgo(int day) {
    return 'Hace $day día';
  }

  @override
  String hourAgo(int hour) {
    return 'Hace $hour hora';
  }

  @override
  String hoursAgo(int hours, Object Hours) {
    return 'Hace $hours horas';
  }

  @override
  String minuteAgo(int minute) {
    return 'Hace $minute minuto';
  }

  @override
  String minutesAgo(int minutes) {
    return 'hace $minutes minutos';
  }

  @override
  String secondAgo(int seconds) {
    return 'Hace $seconds segundos';
  }

  @override
  String get justNow => 'Ahora mismo';

  @override
  String get trophiesByMonth => 'Trofeos por mes';

  @override
  String get trophiesBySeason => 'Trofeos por temporada';

  @override
  String get eosTrophies => 'Trofeos de fin de temporada';

  @override
  String get searchClan => 'Buscar clan';

  @override
  String get nameOrTagClan => 'Nombre o etiqueta del clan';

  @override
  String get noResult => 'Sin resultados.';

  @override
  String get filters => 'Filtros';

  @override
  String get whatever => 'Como sea';

  @override
  String get any => 'Cualquiera';

  @override
  String get notSet => 'No establecido';

  @override
  String get warFrequency => 'Frecuencia de guerra';

  @override
  String get minimumMembers => 'Miembros mínimos';

  @override
  String get maximumMembers => 'Miembros máximos';

  @override
  String get location => 'Localización';

  @override
  String get minimumClanPoints => 'Puntos mínimos del clan';

  @override
  String get minimumClanLevel => 'Nivel mínimo del clan';

  @override
  String get noClan => 'Sin clan';

  @override
  String get joinClanToUnlockNewFeatures => 'Únete a un clan para desbloquear nuevas funciones.';

  @override
  String get apply => 'Aplicar';

  @override
  String get opened => 'Abierto';

  @override
  String get inviteOnly => 'Solo invitación';

  @override
  String get cancel => 'Cancelar';

  @override
  String get clan => 'Clan';

  @override
  String get clans => 'Clanes';

  @override
  String get members => 'Miembros';

  @override
  String get role => 'Rol';

  @override
  String get expLevel => 'Nivel de Experiencia';

  @override
  String get townHallLevel => 'Nivel TH';

  @override
  String thLevel(int level) {
    return 'TH$level';
  }

  @override
  String townHallLevelLevel(int level) {
    return 'TownHall $level';
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
  String get allTownHalls => 'All TownHalls';

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
  String get builderBaseTrophies => 'Trofeos BB';

  @override
  String get donations => 'Donaciones';

  @override
  String get donationsReceived => 'Donaciones recibidas';

  @override
  String get donationsRatio => 'Relación de donaciones';

  @override
  String get trophies => 'Trofeos';

  @override
  String get always => 'Siempre';

  @override
  String get never => 'Nunca';

  @override
  String get unknown => 'Desconocido';

  @override
  String get oncePerWeek => 'una vez por semana';

  @override
  String get twicePerWeek => 'dos veces a la semana';

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
  String get ongoingWar => 'Guerra en curso';

  @override
  String get ongoingCwl => 'LGC en curso';

  @override
  String get cantOpenLink => 'No podemos abrir este enlace.';

  @override
  String get notInWar => 'No está en guerra';

  @override
  String get warHistory => 'Curso de Guerra';

  @override
  String warHistoryWinsDescription(int wins, String percent) {
    return 'Hemos seguido los datos de $wins victorias en guerra de tu clan.';
  }

  @override
  String warHistoryLossesDescription(int losses, String percent) {
    return 'Hemos seguido los datos de $losses derrotas en guerra de tu clan.';
  }

  @override
  String warHistoryDrawsDescription(int draws, String percent) {
    return 'Hemos seguido los datos de $draws empates en guerra de tu clan.';
  }

  @override
  String warHistoryAverageMembersDescription(int members) {
    return 'Tu clan tiene un promedio de $members miembros participando por guerra que hemos seguido.';
  }

  @override
  String warHistoryAverageWarStarsDescription(double stars, String percent) {
    return 'Tu clan tiene un promedio de $stars estrellas por ataque al final de las guerras que hemos seguido.';
  }

  @override
  String warHistoryAverageHitRateDescription(String percent) {
    return 'Tu clan tiene un promedio de $percent de destrucción por ataque al final de las guerras que hemos seguido.';
  }

  @override
  String get warLog => 'Registro de guerra';

  @override
  String get publicWarLog => 'Registro de guerra pública';

  @override
  String get privateWarLog => 'Registro de guerra privada';

  @override
  String startsIn(String time) {
    return 'Comienza en $time';
  }

  @override
  String startsAt(String time) {
    return 'Comienza en $time';
  }

  @override
  String endsIn(String time) {
    return 'Termina en $time';
  }

  @override
  String endsAt(String time) {
    return 'Termina en $time';
  }

  @override
  String get joinLeaveLogs => 'Registros de Entrada/Salida';

  @override
  String get join => 'Unirse';

  @override
  String get leave => 'Abandonar';

  @override
  String get reset => 'Restablecer';

  @override
  String leaveNumberDescription(int number, String date) {
    return '$number jugadores abandonaron el clan durante la temporada actual ($date).';
  }

  @override
  String joinNumberDescription(int number, String date) {
    return '$number jugadores se unieron al clan durante la temporada actual ($date).';
  }

  @override
  String joinLeaveDifferenceUpDescription(int number, String date) {
    return 'Tu clan ha ganado $number nuevos miembros esta temporada ($date).';
  }

  @override
  String joinLeaveDifferenceDownDescription(int number, String date) {
    return 'Tu clan ha perdido $number miembros esta temporada ($date).';
  }

  @override
  String joinLeaveDifferenceEqualDescription(String date) {
    return 'Tu clan tiene el mismo número de miembros que al principio de la temporada ($date).';
  }

  @override
  String leftOnAt(String date, String time) {
    return 'Se fue el $date a las $time.';
  }

  @override
  String joinedOnAt(String date, String time) {
    return 'Se unió el $date a las $time.';
  }

  @override
  String get statistics => 'Estadísticas';

  @override
  String get stars => 'Estrellas';

  @override
  String get numberOfStars => 'Número de estrellas';

  @override
  String get destructionRate => 'Tasa de destrucción';

  @override
  String get events => 'Eventos';

  @override
  String get team => 'Grupos';

  @override
  String get myTeam => 'Mi equipo';

  @override
  String get enemiesTeam => 'Enemigos';

  @override
  String get defense => 'Defensa';

  @override
  String get defenses => 'Defensas';

  @override
  String get attack => 'Ataque';

  @override
  String get attacks => 'Ataques';

  @override
  String get victory => '¡Victoria!';

  @override
  String get defeat => 'Derrota';

  @override
  String get draw => 'Empate';

  @override
  String get perfectWar => 'Guerra perfecta';

  @override
  String get newest => 'Más reciente';

  @override
  String get oldest => 'Más antiguos';

  @override
  String get warEnded => 'La guerra ha terminado';

  @override
  String get preparation => 'Preparación';

  @override
  String isNotInWar(String clan) {
    return '$clan no está en guerra.';
  }

  @override
  String warLogIsClosed(String clan) {
    return 'El registro de guerra de $clan está cerrado.';
  }

  @override
  String get askForWar => 'Contacta a un líder o un colíder para iniciar una guerra.';

  @override
  String get askForWarLogOpening => 'Contacta a un líder o un colíder para hacer público el registro de guerra.';

  @override
  String get warLogClosed => 'El registro de guerra cerrado.';

  @override
  String get rounds => 'Rondas';

  @override
  String get noDataAvailableForThisWar => 'No hay datos disponibles para esta guerra';

  @override
  String get stateOfTheWar => 'Estado de la guerra';

  @override
  String starsNeededToTakeTheLead(String clan, int star, int star2, String percent, Object stars2) {
    return '$clan todavía necesita $star estrella(s) más o $stars2 estrella(s) y $percent% para tomar la delantera.';
  }

  @override
  String starsAndPercentNeededToTakeTheLead(String clan, String percent) {
    return '$clan todavía necesita $percent% o 1 estrella más para tomar la delantera';
  }

  @override
  String get clanDraw => 'Ambos clanes están empatados';

  @override
  String get fastCalculator => 'Calculadora rápida';

  @override
  String fastCalculatorAnswer(String percentNeedeed, String result, Object percentNeeded) {
    return 'Para lograr una tasa de destrucción de $percentNeeded%, se necesita un total de $result%.';
  }

  @override
  String get teamSize => 'Tamaño del equipo';

  @override
  String get neededOverall => '% Total necesario';

  @override
  String get calculate => 'Calcular';

  @override
  String get warStats => 'Estadísticas de Guerra';

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
  String cwlCurrentRound(int round) {
    return 'It\'s currently round $round.';
  }

  @override
  String get noAccountLinkedToYourProfileFound => 'No se encontró ninguna cuenta vinculada a su perfil';

  @override
  String get management => 'Administración';

  @override
  String get comingSoon => '¡Próximamente!';

  @override
  String get connectionError => 'Se ha producido un error. Por favor, comprueba tu conexión a internet e inténtalo de nuevo.';

  @override
  String get connectionErrorRelaunch => 'Se ha producido un error. Por favor, verifica tu conexión a internet y vuelve a iniciar la aplicación.';

  @override
  String updatedAt(String time) {
    return 'Updated at $time';
  }
}
