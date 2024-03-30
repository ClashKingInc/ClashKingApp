import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/my_app.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:clashkingapp/main_pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clashkingapp/global_keys.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsInfoScreen extends StatelessWidget {
  final DiscordUser user;

  SettingsInfoScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              // Show some information about settings or the app
            },
          ),
        ],
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
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      leading: Icon(leadingIcon),
      onTap: onTap,
    );
  }

  Future<void> _showLanguageSelection(BuildContext context) async {
    final selectedLanguage = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <String>['en', 'fr'].map((String language) {
              return ListTile(
                leading: Icon(Icons.language),
                title: Text(language == 'en' ? 'English' : 'Français'),
                onTap: () => Navigator.pop(context, language),
              );
            }).toList(),
          ),
        );
      },
    );

    if (selectedLanguage != null) {
      Provider.of<MyAppState>(context, listen: false)
          .changeLanguage(selectedLanguage);
    }
  }

  Future<void> _logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('expiration_date');

    globalNavigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}
