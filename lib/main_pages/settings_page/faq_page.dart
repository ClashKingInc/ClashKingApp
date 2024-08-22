import 'package:clashkingapp/components/dialogs/open_clash_dialog.dart';
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
            title: Text(
              AppLocalizations.of(context)!.faqIsThisFromSupercell,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            children: <Widget>[
              ListTile(
                title: Text(AppLocalizations.of(context)!.faqFanContentPolicy),
              ),
            ],
          ),
          ExpansionTile(
            iconColor: Theme.of(context).colorScheme.secondary,
            collapsedIconColor: Theme.of(context).colorScheme.primary,
            title: Text(
              AppLocalizations.of(context)!.faqWhyNotAccurate,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            children: <Widget>[
              ListTile(
                title: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyLarge,
                    children: <TextSpan>[
                      TextSpan(
                        text: AppLocalizations.of(context)!.faqClanNotTracked,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: '\n'),
                      TextSpan(
                          text: AppLocalizations.of(context)!
                              .faqClanNotTrackedAnswer),
                      TextSpan(text: '\n\n'),
                      TextSpan(
                        text: AppLocalizations.of(context)!.faqTrackingDown,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: '\n'),
                      TextSpan(
                          text: AppLocalizations.of(context)!
                              .faqTrackingDownAnswer),
                      TextSpan(text: '\n\n'),
                      TextSpan(
                        text: AppLocalizations.of(context)!.faqApiLimitation,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: '\n'),
                      TextSpan(
                          text: AppLocalizations.of(context)!
                              .faqApiLimitationAnswer),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ExpansionTile(
            iconColor: Theme.of(context).colorScheme.secondary,
            collapsedIconColor: Theme.of(context).colorScheme.primary,
            title: Text(
              AppLocalizations.of(context)!.faqSupportWork,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            children: <Widget>[
              ListTile(
                title: Column(
                  children: [
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyLarge,
                        children: <TextSpan>[
                          TextSpan(
                              text: "${AppLocalizations.of(context)!
                                  .faqSupportWorkAnswer}\n"),
                          TextSpan(
                              text:
                                  "\u2022 ${AppLocalizations.of(context)!.faqUseCodeClashKing},\n"),
                          TextSpan(
                              text:
                                  "\u2022 ${AppLocalizations.of(context)!.faqSupportUsOnPatreon},\n"),
                          TextSpan(
                              text:
                                  "\u2022 ${AppLocalizations.of(context)!.faqShareTheApp},\n"),
                          TextSpan(
                              text:
                                  "\u2022 ${AppLocalizations.of(context)!.faqRateTheApp},\n"),
                          TextSpan(
                              text:
                                  "\u2022 ${AppLocalizations.of(context)!.faqHelpUsTranslate},\n"),
                          TextSpan(
                              text:
                                  "\u2022 ${AppLocalizations.of(context)!.faqJoinDiscord},\n"),
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
                            Text(
                                AppLocalizations.of(context)!
                                    .faqUseCodeClashKing,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white)),
                          ],
                        ),
                        onPressed: () async {
                          final languageCode = Localizations.localeOf(context)
                              .languageCode
                              .toLowerCase();
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return OpenClashDialog(
                                  url:
                                      'https://link.clashofclans.com/$languageCode?action=SupportCreator&id=Clashking');
                            },
                          );
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
                            Text(
                                AppLocalizations.of(context)!
                                    .faqSupportUsOnPatreon,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white)),
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
                            Text(AppLocalizations.of(context)!.faqJoinDiscord,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white)),
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
            title: Text(
              AppLocalizations.of(context)!.faqHowToInviteTheBot,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            children: <Widget>[
              ListTile(
                title: Column(
                  children: [
                    Text(AppLocalizations.of(context)!
                        .faqHowToInviteTheBotAnswer),
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
                            Text(
                              AppLocalizations.of(context)!.faqInviteTheBot,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.white),
                              overflow: TextOverflow.visible,
                            ),
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
              AppLocalizations.of(context)!.faqNeedHelp,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            children: <Widget>[
              ListTile(
                title: Column(
                  children: [
                    Text(AppLocalizations.of(context)!.faqNeedHelpAnswer),
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
                            Text(AppLocalizations.of(context)!.faqSendEmail,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white)),
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
                            throw 'Could not launch $url';
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
                            Text(AppLocalizations.of(context)!.faqJoinDiscord,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white),
                                overflow: TextOverflow.ellipsis),
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
