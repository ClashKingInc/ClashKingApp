import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/theme_notifier.dart';
import 'package:clashkingapp/api/user_info.dart';
import 'package:clashkingapp/main_pages/login_page/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clashkingapp/global_keys.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/core/my_app_state.dart';
import 'package:clashkingapp/l10n/locale.dart';
import 'package:clashkingapp/main_pages/settings_page/faq_page.dart';
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
              launchUrl(Uri.parse(
                  'https://crowdin.com/project/clashkingapp/invite?h=87a407268713f1cb79724a2e0c00a5d52098842'));
            },
          ),
          Divider(),
          _buildListTile(
            context,
            title: AppLocalizations.of(context)!.logout,
            leadingIcon: Icons.exit_to_app,
            onTap: _logOut,
          ),
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
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style:
                  TextStyle(color: Theme.of(context).colorScheme.onBackground))
          : null,
      leading:
          Icon(leadingIcon, color: Theme.of(context).colorScheme.onBackground),
      onTap: onTap,
    );
  }

  Future<void> _showLanguageSelection(context) async {
    final selectedLanguage = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            color: Theme.of(context).colorScheme.surface, // Replace with your desired color
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
                    onTap: () => Navigator.pop(context, locale.languageCode),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );

    // Check if the widget is still mounted before trying to use `context`
    if (selectedLanguage != null && mounted) {
      Provider.of<MyAppState>(context, listen: false)
          .changeLanguage(selectedLanguage);
    }
  }

  Future<void> _logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      globalNavigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }
}
