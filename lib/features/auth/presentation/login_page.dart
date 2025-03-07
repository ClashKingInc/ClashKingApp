import 'package:clashkingapp/features/home/presentation/my_home_page.dart';
import 'package:clashkingapp/services/api_service.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/services/token_service.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/login_page/guest_login_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool _isLoading = false; // Indicateur de chargement

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authService = Provider.of<AuthService>(context, listen: false);
    
    final logoUrl = ApiService.assetUrl +
        (isDarkMode
            ? "/logos/crown-arrow-dark-bg/ClashKing-1.png"
            : "/logos/crown-arrow-white-bg/ClashKing-2.png");
    final textLogoUrl = ApiService.assetUrl +
        (isDarkMode
            ? "/logos/crown-arrow-dark-bg/CK-text-dark-bg.png"
            : "/logos/crown-arrow-white-bg/CK-text-white-bg.png");

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(children: [
                  SizedBox(
                      height: 150,
                      width: 150,
                      child: CachedNetworkImage(imageUrl: logoUrl)),
                  SizedBox(height: 8),
                  SizedBox(
                      width: 250,
                      child: CachedNetworkImage(imageUrl: textLogoUrl)),
                ]),
                SizedBox(height: 48),
                
                // Bouton Connexion Discord
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          try {
                            await authService.signInWithDiscord();
                            final accessToken = await TokenService().getAccessToken();
                            
                            if (accessToken != null && context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => MyHomePage()),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context)!.loginError)),
                            );
                          }
                          setState(() => _isLoading = false);
                        },
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.discord, size: 24, color: Colors.white),
                          
                          SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.signInWithDiscord),
                        ]),
                ),

                SizedBox(height: 16),

                // Mode invité
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => GuestLoginPage()),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.group_add, size: 24, color: Colors.white),
                    SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.guestMode),
                  ]),
                ),
                
                SizedBox(height: 8),

                // Lien vers le Discord pour support
                TextButton(
                  onPressed: () async =>
                      launchUrl(Uri.parse('https://discord.gg/clashking')),
                  child: Text(
                    AppLocalizations.of(context)!.needHelpJoinDiscord,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        decoration: TextDecoration.underline),
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
