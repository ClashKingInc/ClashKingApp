import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/components/dialogs/logout_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/theme_notifier.dart';
import 'package:clashkingapp/classes/account/user.dart';
import 'package:clashkingapp/front/main_pages/login_page/login_page.dart';
import 'package:clashkingapp/global_keys.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/core/my_app_state.dart';
import 'package:clashkingapp/l10n/locale.dart';
import 'package:clashkingapp/front/main_pages/settings_page/faq_page.dart';
import 'package:clashkingapp/front/main_pages/settings_page/translation_page.dart';
import 'package:clashkingapp/core/functions.dart';
import 'package:clashkingapp/front/main_pages/settings_page/features_vote.dart';
import 'package:url_launcher/url_launcher.dart';


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
        title: Text(AppLocalizations.of(context)!.settings),
        actions: [],
      ),
      body: ListView(
        children: <Widget>[
          _buildListTile(
            context,
            title: AppLocalizations.of(context)!.language,
            subtitle: AppLocalizations.of(context)!.selectLanguage,
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
                title: AppLocalizations.of(context)!.toggleTheme,
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
            title: AppLocalizations.of(context)!.faq,
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
            title: AppLocalizations.of(context)!.helpUsTranslate,
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
            title: AppLocalizations.of(context)!.suggestFeatures,
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
            title: AppLocalizations.of(context)!.logout,
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
    await clearPrefs();
    if (mounted) {
      globalNavigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
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
          subtitle: Text(AppLocalizations.of(context)!.loading),
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
            Clipboard.setData(ClipboardData(text: snapshot.data ?? ''));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.copiedToClipboard),
              ),
            );
          },
        );
      }
    },
  );
}