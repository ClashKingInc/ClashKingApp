import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/dialogs/logout_dialog.dart';
import 'package:clashkingapp/common/widgets/dialogs/snackbar.dart';
import 'package:clashkingapp/core/constants/global_keys.dart';
import 'package:clashkingapp/core/app/my_app_state.dart';
import 'package:clashkingapp/core/config/app_feature_flags.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/core/models/user.dart';
import 'package:clashkingapp/core/services/app_icon_service.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/core/services/live_activity_debug_service.dart';
import 'package:clashkingapp/core/services/player_card_preferences_service.dart';
import 'package:clashkingapp/core/theme/theme_notifier.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/auth/presentation/login_page.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/pages/presentation/dashboard_page.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/settings/presentation/faq_page.dart';
import 'package:clashkingapp/features/settings/presentation/features_vote.dart';
import 'package:clashkingapp/features/settings/presentation/notification_settings_page.dart';
import 'package:clashkingapp/features/settings/presentation/privacy_controls_page.dart';
import 'package:clashkingapp/features/settings/presentation/translation_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/l10n/locale.dart';
import 'package:clashkingapp/widgets/war_widget.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsInfoScreen extends StatefulWidget {
  const SettingsInfoScreen({super.key, required this.user});

  final User user;

  @override
  State<SettingsInfoScreen> createState() => _SettingsInfoScreenState();
}

class _SettingsInfoScreenState extends State<SettingsInfoScreen> {
  final AppIconService _appIconService = AppIconService();

  bool _supportsAlternateIcons = false;
  bool _isChangingAppIcon = false;
  String? _selectedAppIconName;
  String? _cachedWarWidgetClanSignature;

  @override
  void initState() {
    super.initState();
    _loadAppIconState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final appState = context.watch<MyAppState>();
    final notificationsEnabled = appState.isFeatureEnabled(
      AppFeatureFlags.notifications,
    );
    final warWidgetsEnabled = appState.isFeatureEnabled(
      AppFeatureFlags.warWidgets,
    );
    final hasDiscord =
        widget.user.hasDiscordAuth || widget.user.avatarUrl.isNotEmpty;
    final hasEmail = widget.user.hasEmailAuth;
    final widgetClans = warWidgetsEnabled
        ? WarWidgetService.clanOptionsFromProfiles(
            context.watch<PlayerService>().profiles,
            bookmarkedClans: context.watch<BookmarkService>().clans,
          )
        : const <WarWidgetClanOption>[];
    if (warWidgetsEnabled) {
      _scheduleWarWidgetClanCache(widgetClans);
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.generalSettings),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
      ),
      body: _SettingsResponsiveList(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
          children: [
            _ProfileHeader(user: widget.user),
            const SizedBox(height: 14),
            _SettingsSection(
              title: l10n.settingsPreferences,
              children: [
                _SettingsTile(
                  icon: Icons.language,
                  title: l10n.settingsLanguage,
                  subtitle: l10n.settingsSelectLanguage,
                  onTap: () => _showLanguageSelection(context),
                ),
                Consumer<ThemeNotifier>(
                  builder: (context, themeNotifier, child) {
                    return _SettingsTile(
                      icon: LucideIcons.sunMoon,
                      title: l10n.settingsToggleTheme,
                      trailingText: _themeModeLabel(
                        context,
                        themeNotifier.themeMode,
                      ),
                      onTap: () =>
                          _showThemeModeSelection(context, themeNotifier),
                    );
                  },
                ),
                if (_supportsAlternateIcons)
                  _SettingsTile(
                    icon: LucideIcons.image,
                    title: l10n.settingsAppIcon,
                    trailingText: _isChangingAppIcon
                        ? l10n.settingsChanging
                        : _appIconService
                              .optionForName(_selectedAppIconName)
                              .labelFor(context),
                    onTap: _isChangingAppIcon ? null : _showAppIconSelection,
                  ),
                if (notificationsEnabled)
                  _SettingsTile(
                    icon: LucideIcons.bellRing,
                    title: l10n.settingsNotificationsTitle,
                    subtitle: l10n.settingsNotificationsSubtitle,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationSettingsPage(),
                        ),
                      );
                    },
                  ),
                if (warWidgetsEnabled)
                  _SettingsTile(
                    icon: LucideIcons.panelTop,
                    title: l10n.settingsAddWarWidget,
                    subtitle: widgetClans.isEmpty
                        ? l10n.settingsWarWidgetLinkClanFirst
                        : l10n.settingsWarWidgetClanCount(widgetClans.length),
                    onTap: () => _showWarWidgetSheet(widgetClans),
                  ),
              ],
            ),
            if (kDebugMode && LiveActivityDebugService.isSupportedPlatform)
              _SettingsSection(
                title: l10n.settingsLiveActivityTest,
                children: [
                  _SettingsTile(
                    icon: LucideIcons.radio,
                    title: l10n.settingsLiveActivityStart,
                    subtitle: l10n.settingsLiveActivityStartSubtitle,
                    onTap: () => _runLiveActivityAction('start'),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.refreshCw,
                    title: l10n.settingsLiveActivityUpdate,
                    subtitle: l10n.settingsLiveActivityUpdateSubtitle,
                    onTap: () => _runLiveActivityAction('update'),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.circleStop,
                    title: l10n.settingsLiveActivityEnd,
                    subtitle: l10n.settingsLiveActivityEndSubtitle,
                    onTap: () => _runLiveActivityAction('end'),
                  ),
                ],
              ),
            _SettingsSection(
              title: l10n.settingsSupport,
              children: [
                _SettingsTile(
                  icon: Icons.question_answer_outlined,
                  title: l10n.faqTitle,
                  subtitle: l10n.faqSubtitle,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => FaqScreen()),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.translate,
                  title: l10n.translationHelpUsTranslate,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TranslationScreen(),
                      ),
                    );
                  },
                ),
                if (appState.isFeatureEnabled(AppFeatureFlags.featureRequests))
                  _SettingsTile(
                    icon: Icons.featured_play_list_outlined,
                    title: l10n.translationSuggestFeatures,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FeatureRequests(),
                        ),
                      );
                    },
                  ),
                _SettingsTile(
                  icon: Icons.discord,
                  title: l10n.faqJoinDiscord,
                  onTap: () {
                    launchUrl(Uri.parse('https://discord.gg/clashking'));
                  },
                ),
              ],
            ),
            _SettingsSection(
              title: l10n.settingsAbout,
              children: [
                _SettingsTile(
                  icon: Icons.article_outlined,
                  title: l10n.settingsLicenses,
                  subtitle: l10n.settingsLicensesSubtitle,
                  onTap: _showLicenses,
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.settingsPrivacyPolicy,
                  subtitle: l10n.settingsPrivacyPolicySubtitle,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PrivacyControlsPage(),
                      ),
                    );
                  },
                ),
                _VersionSettingsTile(),
              ],
            ),
            _SettingsSection(
              title: l10n.settingsAccount,
              children: [
                if (appState.isFeatureEnabled(
                  AppFeatureFlags.accountConnections,
                )) ...[
                  _SettingsTile(
                    icon: Icons.discord,
                    title: l10n.generalDiscord,
                    subtitle: hasDiscord
                        ? l10n.settingsDiscordConnectedSubtitle
                        : l10n.settingsDiscordSyncSubtitle,
                    trailingText: hasDiscord ? l10n.settingsConnected : null,
                    onTap: hasDiscord
                        ? () => _showConnectionPlaceholder('Disconnect Discord')
                        : () => _showConnectionPlaceholder('Connect Discord'),
                  ),
                  _SettingsTile(
                    icon: Icons.alternate_email,
                    title: l10n.settingsClashKingAccount,
                    subtitle: hasEmail
                        ? l10n.settingsEmailConnectedSubtitle
                        : l10n.settingsEmailRecoverySubtitle,
                    trailingText: hasEmail ? l10n.settingsConnected : null,
                    onTap: hasEmail
                        ? () => _showConnectionPlaceholder(
                            'Disconnect ClashKing account',
                          )
                        : () => _showConnectionPlaceholder(
                            'Connect ClashKing account',
                          ),
                  ),
                ],
                _SettingsTile(
                  icon: Icons.alternate_email,
                  title: widget.user.email ?? widget.user.username,
                  subtitle: widget.user.email == null
                      ? l10n.settingsSignedIn
                      : l10n.authEmail,
                  showChevron: false,
                ),
                _SettingsTile(
                  icon: Icons.logout,
                  title: l10n.authLogout,
                  destructive: true,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          ConfirmLogoutDialog(onConfirm: _logOut),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _themeModeLabel(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context)!;
    return switch (mode) {
      ThemeMode.light => l10n.settingsThemeLight,
      ThemeMode.dark => l10n.settingsThemeDark,
      ThemeMode.system => l10n.settingsThemeSystem,
    };
  }

  Future<void> _loadAppIconState() async {
    if (!AppIconService.isSupportedPlatform) return;

    final supported = await _appIconService.supportsAlternateIcons();
    final iconName = supported
        ? await _appIconService.getAlternateIconName()
        : null;

    if (!mounted) return;
    setState(() {
      _supportsAlternateIcons = supported;
      _selectedAppIconName = iconName;
    });
  }

  Future<void> _showLanguageSelection(BuildContext context) async {
    final selectedLocale = await showModalBottomSheet<Locale>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            itemBuilder: (context, index) {
              final locale = supportedLocales[index];
              return ListTile(
                leading: MobileWebImage(
                  imageUrl: locale.flagUrl,
                  width: 32,
                  height: 32,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error_outline),
                ),
                title: Text(locale.languageName),
                onTap: () {
                  Navigator.pop(
                    context,
                    Locale.fromSubtags(
                      languageCode: locale.languageCode,
                      countryCode: locale.countryCode,
                      scriptCode: locale.scriptCode,
                    ),
                  );
                },
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: supportedLocales.length,
          ),
        );
      },
    );

    if (selectedLocale != null && context.mounted) {
      await Provider.of<MyAppState>(
        context,
        listen: false,
      ).changeLanguage(selectedLocale);
    }
  }

  Future<void> _showThemeModeSelection(
    BuildContext context,
    ThemeNotifier themeNotifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final current = themeNotifier.themeMode;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: _SettingsSection(
              title: l10n.settingsAppearance,
              children: [
                _ThemeModeTile(
                  title: l10n.settingsThemeSystem,
                  subtitle: l10n.settingsThemeMatchDevice,
                  icon: Icons.brightness_auto_outlined,
                  selected: current == ThemeMode.system,
                  value: ThemeMode.system,
                ),
                _ThemeModeTile(
                  title: l10n.settingsThemeLight,
                  icon: Icons.light_mode_outlined,
                  selected: current == ThemeMode.light,
                  value: ThemeMode.light,
                ),
                _ThemeModeTile(
                  title: l10n.settingsThemeDark,
                  icon: Icons.dark_mode_outlined,
                  selected: current == ThemeMode.dark,
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await themeNotifier.setThemeMode(selected);
    }
  }

  Future<void> _showAppIconSelection() async {
    final selected = await showModalBottomSheet<AppIconOption>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final current = _selectedAppIconName;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: _SettingsSection(
              title: AppLocalizations.of(context)!.settingsAppIcon,
              children: [
                for (final option in AppIconService.options)
                  _AppIconOptionTile(
                    option: option,
                    selected: option.iconName == current,
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || selected.iconName == _selectedAppIconName) return;

    setState(() => _isChangingAppIcon = true);
    try {
      await _appIconService.setAlternateIconName(selected.iconName);
      if (!mounted) return;
      setState(() => _selectedAppIconName = selected.iconName);
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
    } finally {
      if (mounted) {
        setState(() => _isChangingAppIcon = false);
      }
    }
  }

  void _scheduleWarWidgetClanCache(List<WarWidgetClanOption> clans) {
    final signature = clans.map((clan) => '${clan.tag}:${clan.name}').join('|');
    if (signature.isEmpty || signature == _cachedWarWidgetClanSignature) {
      return;
    }
    _cachedWarWidgetClanSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await WarWidgetService.cacheClanOptions(clans);
      } catch (error) {
        DebugUtils.debugWarning("Could not cache war widget clans: $error");
      }
    });
  }

  Future<void> _showWarWidgetSheet(List<WarWidgetClanOption> clans) async {
    await WarWidgetService.cacheClanOptions(clans);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        String? pendingClanTag;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colorScheme = Theme.of(context).colorScheme;
            final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
            final isAndroid = defaultTargetPlatform == TargetPlatform.android;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add War Widget',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isIOS
                          ? 'Choose a clan to cache it. After adding the widget, long press it, tap Edit Widget, then choose Clan.'
                          : 'Choose a clan to cache it, then add the widget from Android.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (clans.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No linked accounts are currently in a clan.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final clan = clans[index];
                            final isPending = pendingClanTag == clan.tag;
                            return _WarWidgetClanTile(
                              clan: clan,
                              isPending: isPending,
                              onTap: isPending
                                  ? null
                                  : () async {
                                      setSheetState(
                                        () => pendingClanTag = clan.tag,
                                      );
                                      try {
                                        await WarWidgetService.prepareClanWidgets(
                                          clans,
                                          selectedClanTag: clan.tag,
                                        );
                                        if (isAndroid) {
                                          await WarWidgetService.requestPinnedWarWidget();
                                        }
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isIOS
                                                  ? '${clan.name} is ready. Edit the widget and choose it under Clan.'
                                                  : '${clan.name} widget data is ready.',
                                            ),
                                          ),
                                        );
                                        Navigator.pop(sheetContext);
                                      } catch (error) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Could not prepare widget: $error',
                                            ),
                                          ),
                                        );
                                      } finally {
                                        if (context.mounted) {
                                          setSheetState(
                                            () => pendingClanTag = null,
                                          );
                                        }
                                      }
                                    },
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemCount: clans.length,
                        ),
                      ),
                    if (isIOS) ...[
                      const SizedBox(height: 12),
                      Text(
                        'You can add more than one War Widget and set a different Clan on each one.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: AppLocalizations.of(context)!.appTitle,
      applicationVersion: '1.0.0+22',
      applicationIcon: SizedBox(
        width: 48,
        height: 48,
        child: MobileWebImage(
          imageUrl: Theme.of(context).brightness == Brightness.dark
              ? 'https://assets.clashk.ing/logos/crown-arrow-dark-bg/ClashKing-1.png'
              : 'https://assets.clashk.ing/logos/crown-arrow-white-bg/ClashKing-2.png',
          errorWidget: (context, url, error) => const Icon(Icons.apps),
        ),
      ),
      applicationLegalese: '© ${DateTime.now().year} ClashKing',
    );
  }

  Future<void> _runLiveActivityAction(String action) async {
    final service = LiveActivityDebugService();

    try {
      final status = switch (action) {
        'start' => await service.start(),
        'update' => await service.update(),
        'end' => await service.end(),
        _ => await service.status(),
      };

      if (!mounted) return;
      final running = status['running'] == true;
      final message = running
          ? 'Live Activity running: ${status['score'] ?? ''} ${status['timeState'] ?? ''}'
          : 'Live Activity ended.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
    }
  }

  void _showConnectionPlaceholder(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$action will be wired once the account connection API is available.',
        ),
      ),
    );
  }

  Future<void> _logOut() async {
    DebugUtils.debugInfo(
      'SettingsInfoScreen: _logOut called, clearing all service data.',
    );
    if (!mounted) {
      DebugUtils.debugWarning(
        'SettingsInfoScreen: _logOut called but context is not mounted.',
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final cocAccountService = Provider.of<CocAccountService>(
      context,
      listen: false,
    );
    final playerService = Provider.of<PlayerService>(context, listen: false);
    final cardPreferences = Provider.of<PlayerCardPreferencesService>(
      context,
      listen: false,
    );

    await authService.logoutAndClearAllData();
    cocAccountService.clearAccountData();
    clearAccountScopedHomeCaches(
      playerService,
      cardPreferences: cardPreferences,
    );

    globalNavigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
    DebugUtils.debugSuccess(
      'SettingsInfoScreen: All service data cleared successfully.',
    );
  }
}

class _SettingsResponsiveList extends StatelessWidget {
  const _SettingsResponsiveList({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopWeb = kIsWeb && constraints.maxWidth >= 900;
        if (!isDesktopWeb) return child;

        final contentWidth = (constraints.maxWidth - 48)
            .clamp(0.0, 760.0)
            .toDouble();
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentWidth,
            height: constraints.maxHeight,
            child: child,
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox.square(
          dimension: 68,
          child: ClipOval(
            child: MobileWebImage(
              imageUrl: user.avatarUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person,
                  color: colorScheme.onSurfaceVariant,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.username,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 5),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.28),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Column(
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    children[index],
                    if (index != children.length - 1)
                      Divider(
                        height: 1,
                        indent: 55,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.42,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.onTap,
    this.destructive = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback? onTap;
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = destructive ? colorScheme.error : colorScheme.onSurface;
    final secondary = colorScheme.onSurfaceVariant;

    final rowHeight = subtitle == null ? 50.0 : 62.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: rowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Icon(icon, color: foreground, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w500,
                          fontSize: 17,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: secondary, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingText != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    trailingText!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: secondary,
                      fontSize: 16,
                    ),
                  ),
                ],
                if (showChevron && onTap != null) ...[
                  const SizedBox(width: 5),
                  Icon(Icons.chevron_right, color: secondary, size: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.value,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final ThemeMode value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      showChevron: false,
      trailingText: selected ? l10n.settingsThemeSelected : null,
      onTap: () => Navigator.pop(context, value),
    );
  }
}

class _AppIconOptionTile extends StatelessWidget {
  const _AppIconOptionTile({required this.option, required this.selected});

  final AppIconOption option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final secondary = colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context, option),
        child: SizedBox(
          height: 62,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.asset(
                    option.previewAsset,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.labelFor(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: 17,
                    ),
                  ),
                ),
                if (selected)
                  Text(
                    AppLocalizations.of(context)!.settingsThemeSelected,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: secondary,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WarWidgetClanTile extends StatelessWidget {
  const _WarWidgetClanTile({
    required this.clan,
    required this.isPending,
    required this.onTap,
  });

  final WarWidgetClanOption clan;
  final bool isPending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
      leading: SizedBox(
        width: 42,
        height: 42,
        child: clan.badgeUrl == null || clan.badgeUrl!.isEmpty
            ? CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  clan.name.characters.firstOrNull ?? '?',
                  style: TextStyle(color: colorScheme.onPrimaryContainer),
                ),
              )
            : MobileWebImage(
                imageUrl: clan.badgeUrl!,
                fit: BoxFit.contain,
                errorWidget: (context, url, error) => CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    clan.name.characters.firstOrNull ?? '?',
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                ),
              ),
      ),
      title: Text(clan.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(clan.tag),
      trailing: isPending
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_rounded),
      onTap: onTap,
    );
  }
}

class _VersionSettingsTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getAppAndDeviceInfo(),
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        final subtitle = switch (snapshot.connectionState) {
          ConnectionState.waiting => l10n.generalLoading,
          _ when snapshot.hasError => l10n.errorLoadingVersion,
          _ => snapshot.data ?? '',
        };

        return _SettingsTile(
          icon: Icons.info_outline,
          title: l10n.versionDevice,
          subtitle: subtitle,
          showChevron: false,
          onTap: snapshot.hasData
              ? () {
                  FlutterClipboard.copy(snapshot.data ?? '').then((_) {
                    if (context.mounted) {
                      showClipboardSnackbar(
                        context,
                        l10n.generalCopiedToClipboard,
                      );
                    }
                  });
                }
              : null,
        );
      },
    );
  }
}

extension AppIconOptionL10n on AppIconOption {
  String labelFor(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return switch (labelKey) {
      'default' => loc.appIconDefault,
      'christmas' => loc.appIconChristmas,
      'black_white' => loc.appIconBlackWhite,
      'dark_mode' => loc.appIconDarkMode,
      _ => labelKey,
    };
  }
}
