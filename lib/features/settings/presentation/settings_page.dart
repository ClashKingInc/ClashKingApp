import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/dialogs/logout_dialog.dart';
import 'package:clashkingapp/common/widgets/dialogs/snackbar.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/theme/theme_notifier.dart';
import 'package:clashkingapp/core/models/user.dart';
import 'package:clashkingapp/features/auth/presentation/login_page.dart';
import 'package:clashkingapp/core/constants/global_keys.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/core/app/my_app_state.dart';
import 'package:clashkingapp/l10n/locale.dart';
import 'package:clashkingapp/features/settings/presentation/faq_page.dart';
import 'package:clashkingapp/features/settings/presentation/translation_page.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/features/settings/presentation/features_vote.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class SettingsInfoScreen extends StatefulWidget {
  final User user;

  SettingsInfoScreen({required this.user});

  @override
  State<SettingsInfoScreen> createState() => _SettingsInfoScreenState();
}

class _SettingsInfoScreenState extends State<SettingsInfoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.generalSettings),
        actions: [],
      ),
      body: ListView(
        children: <Widget>[
          _buildListTile(
            context,
            title: AppLocalizations.of(context)!.settingsLanguage,
            subtitle: AppLocalizations.of(context)!.settingsSelectLanguage,
            leadingIcon: Icons.language,
            onTap: () async {
              await _showLanguageSelection(context);
            },
          ),
          Divider(),
          Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, child) {
              return _buildListTile(
                context,
                title: AppLocalizations.of(context)!.settingsToggleTheme,
                leadingIcon: LucideIcons.sunMoon,
                onTap: () {
                  themeNotifier.toggleTheme();
                },
              );
            },
          ),
          Divider(),
          _buildListTile(
            context,
            title: AppLocalizations.of(context)!.faqTitle,
            subtitle: AppLocalizations.of(context)!.faqSubtitle,
            leadingIcon: Icons.question_answer,
            onTap: () async {
              // Open FAQ page
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => FaqScreen()),
              );
            },
          ),
          Divider(),
          _buildListTile(
            context,
            title: AppLocalizations.of(context)!.translationHelpUsTranslate,
            leadingIcon: Icons.language,
            onTap: () async {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => TranslationScreen()),
              );
            },
          ),
          Divider(),
          _buildListTile(
            context,
            title: AppLocalizations.of(context)!.translationSuggestFeatures,
            leadingIcon: Icons.featured_play_list,
            onTap: () async {
              // Open Features vote
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => FeatureRequests()),
              );
            },
          ),
          Divider(),
          _buildListTile(
            context,
            title: AppLocalizations.of(context)!.faqJoinDiscord,
            leadingIcon: Icons.discord,
            onTap: () async {
              launchUrl(Uri.parse('https://discord.gg/clashking'));
            },
          ),
          Divider(),
          _buildListTile(
            context,
            title: AppLocalizations.of(context)!.settingsLicenses,
            subtitle: AppLocalizations.of(context)!.settingsLicensesSubtitle,
            leadingIcon: Icons.article_outlined,
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: AppLocalizations.of(context)!.appTitle,
                applicationVersion: '1.0.0+22',
                applicationIcon: SizedBox(
                  width: 48,
                  height: 48,
                  child: CachedNetworkImage(
                    imageUrl: Theme.of(context).brightness == Brightness.dark
                        ? "https://assets.clashk.ing/logos/crown-arrow-dark-bg/ClashKing-1.png"
                        : "https://assets.clashk.ing/logos/crown-arrow-white-bg/ClashKing-2.png",
                    errorWidget: (context, url, error) => Icon(Icons.apps),
                  ),
                ),
                applicationLegalese: '© ${DateTime.now().year} ClashKing',
              );
            },
          ),
          Divider(),
          _buildListTile(
            context,
            title: AppLocalizations.of(context)!.settingsPrivacyPolicy,
            subtitle:
                AppLocalizations.of(context)!.settingsPrivacyPolicySubtitle,
            leadingIcon: Icons.privacy_tip_outlined,
            onTap: () {
              launchUrl(
                Uri.parse('https://clashk.ing/'),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
          Divider(),
          _buildListTile(
            context,
            title: AppLocalizations.of(context)!.authLogout,
            leadingIcon: Icons.exit_to_app,
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ConfirmLogoutDialog(
                    onConfirm: _logOut,
                  );
                },
              );
            },
          ),
          Divider(),
          _buildVersionInfoTile(context),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData leadingIcon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface))
          : null,
      leading:
          Icon(leadingIcon, color: Theme.of(context).colorScheme.onSurface),
      onTap: onTap,
    );
  }

  Future<void> _showLanguageSelection(BuildContext context) async {
    final selectedLocale = await showModalBottomSheet<Locale>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: supportedLocales.map((LocaleInfo locale) {
                  return ListTile(
                    leading: CachedNetworkImage(
                      imageUrl: locale.flagUrl,
                      width: 32,
                      height: 32,
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
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
                }).toList(),
              ),
            ),
          ),
        );
      },
    );

    if (selectedLocale != null && context.mounted) {
      Provider.of<MyAppState>(context, listen: false)
          .changeLanguage(selectedLocale);
    }
  }

  Future<void> _logOut() async {
    DebugUtils.debugInfo(
        "SettingsInfoScreen: _logOut called, clearing all service data.");
    if (mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final cocAccountService =
          Provider.of<CocAccountService>(context, listen: false);

      // Clear all authentication and user data
      await authService.logoutAndClearAllData();

      // Clear all COC account service data
      cocAccountService.clearAccountData();

      // Navigate to login page
      globalNavigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
      DebugUtils.debugSuccess("SettingsInfoScreen: All service data cleared successfully.");
    } else {
      DebugUtils.debugWarning(
          "⚠️ SettingsInfoScreen: _logOut called but context is not mounted.");
    }
  }
}

Widget _buildVersionInfoTile(BuildContext context) {
  return FutureBuilder<String>(
    future: getAppAndDeviceInfo(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return ListTile(
          title: Text(AppLocalizations.of(context)!.versionDevice),
          subtitle: Text(AppLocalizations.of(context)!.generalLoading),
        );
      } else if (snapshot.hasError) {
        return ListTile(
          title: Text(AppLocalizations.of(context)!.versionDevice),
          subtitle: Text(AppLocalizations.of(context)!.errorLoadingVersion),
        );
      } else {
        return ListTile(
          title: Text(AppLocalizations.of(context)!.versionDevice),
          subtitle: Text(snapshot.data ?? ''),
          onTap: () {
            FlutterClipboard.copy(snapshot.data ?? '').then((_) {
              if (context.mounted) {
                showClipboardSnackbar(
                  context,
                  AppLocalizations.of(context)!.generalCopiedToClipboard,
                );
              }
            });
          },
        );
      }
    },
  );
}
