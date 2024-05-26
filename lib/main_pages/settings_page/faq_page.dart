import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FaqScreen extends StatefulWidget {
  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FAQ'),
      ),
      body: ListView(
        children: <Widget>[
          ExpansionTile(
            iconColor: Theme.of(context).colorScheme.secondary,
            collapsedIconColor: Theme.of(context).colorScheme.primary,
            title: Text(AppLocalizations.of(context)!.faqIsThisFromSupercell),
            children: <Widget>[
              ListTile(
                title: Text(
                    "This material is unofficial and is not endorsed by Supercell. For more information see Supercell's Fan Content Policy: www.supercell.com/fan-content-policy"),
              ),
            ],
          ),
          ExpansionTile(
            iconColor: Theme.of(context).colorScheme.secondary,
            collapsedIconColor: Theme.of(context).colorScheme.primary,
            title: Text('Why isn\'t the data always accurate or missing?'),
            children: <Widget>[
              ListTile(
                title: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyLarge,
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Clan not tracked\n',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(
                          text:
                              'ClashKing can only get this info if the clan is tracked. If your clan seems not to be tracked, please invite him on a Discord server and use the command /addclan. We hope to make this feature available in the app soon.\n\n'),
                      TextSpan(
                        text: 'Tracking down\n',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(
                          text:
                              'The traking can stop working for a certain period of time. This is why sometimes you can have holes in your data. We are working on improving this.\n\n'),
                      TextSpan(
                        text: 'Clash of Clans API limitation\n',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(
                          text:
                              'Some data are provided by Clash of Clans and their API have some limitations. This is the case for legend tracking where it sometimes stack the trophy gain and loss as if it was one attack.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ExpansionTile(
            iconColor: Theme.of(context).colorScheme.secondary,
            collapsedIconColor: Theme.of(context).colorScheme.primary,
            title: Text('How can I support your work?'),
            children: <Widget>[
              ListTile(
                title: Column(
                  children: [
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyLarge,
                        children: <TextSpan>[
                          TextSpan(
                              text: 'There are several ways to support us:\n'),
                          TextSpan(text: '\u2022 Use code "ClashKing",\n'),
                          TextSpan(text: '\u2022 Support us on Patreon,\n'),
                          TextSpan(
                              text:
                                  '\u2022 Share the app with your friends,\n'),
                          TextSpan(text: '\u2022 Rate the app on the store,\n'),
                          TextSpan(text: '\u2022 Help us translate the app,\n'),
                          TextSpan(text: '\u2022 Join our Discord server.\n'),
                        ],
                      ),
                    ),
                    ButtonTheme(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.gamepad, size: 24),
                            SizedBox(width: 8),
                            Text("Use code 'ClashKing'"),
                          ],
                        ),
                        onPressed: () async {
                          launchUrl(Uri.parse(
                              'https://link.clashofclans.com/fr?action=SupportCreator&id=Clashking'));
                        },
                      ),
                    ),
                    ButtonTheme(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.coffee, size: 24),
                            SizedBox(width: 8),
                            Text("Support us on Patreon"),
                          ],
                        ),
                        onPressed: () async {
                          launchUrl(Uri.parse(
                              'https://www.patreon.com/clashking?utm_campaign=creatorshare_creator'));
                        },
                      ),
                    ),
                    ButtonTheme(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5865F2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.discord, size: 24),
                            SizedBox(width: 8),
                            Text("Join Discord Server"),
                          ],
                        ),
                        onPressed: () async {
                          launchUrl(Uri.parse('https://discord.gg/clashking'));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ExpansionTile(
            iconColor: Theme.of(context).colorScheme.secondary,
            collapsedIconColor: Theme.of(context).colorScheme.primary,
            title: Text('How can I invite your bot on my Discord server?'),
            children: <Widget>[
              ListTile(
                title: Column(
                  children: [
                    Text(
                        'You can invite our bot on your server by clicking on the button below. You will need to have the "Manage Server" permission to add the bot.'),
                    SizedBox(height: 8),
                  ],
                ),
                subtitle: Column(
                  children: [
                    SizedBox(width: 16),
                    ButtonTheme(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5865F2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.discord, size: 24),
                            SizedBox(width: 8),
                            Text("Invite ClashKing Bot"),
                          ],
                        ),
                        onPressed: () async {
                          launchUrl(Uri.parse(
                              'https://discord.com/api/oauth2/authorize?client_id=824653933347209227&permissions=8&scope=bot%20applications.commands'));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ExpansionTile(
            iconColor: Theme.of(context).colorScheme.secondary,
            collapsedIconColor: Theme.of(context).colorScheme.primary,
            title: Text(
                'I need help or make a suggestion. How can I contact you?'),
            children: <Widget>[
              ListTile(
                title: Column(
                  children: [
                    Text(
                        'You can join our Discord server and ask for help or make a feedback there or send us an email at devs@clashkingbot.com. \nPlease write in English or French only.'),
                    SizedBox(height: 8),
                  ],
                ),
                subtitle: Column(
                  children: [
                    ButtonTheme(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.email, size: 24),
                            SizedBox(width: 8),
                            Text("Send Email"),
                          ],
                        ),
                        onPressed: () async {
                          final Uri params = Uri(
                            scheme: 'mailto',
                            path: 'devs@clashkingbot.com',
                            query: 'subject=App%20Inquiry',
                          );

                          String url = params.toString();
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          } else {
                            print('Could not launch $url');
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    ButtonTheme(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5865F2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.discord, size: 24),
                            SizedBox(width: 8),
                            Text("Join Discord"),
                          ],
                        ),
                        onPressed: () async {
                          launchUrl(Uri.parse('https://discord.gg/clashking'));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
