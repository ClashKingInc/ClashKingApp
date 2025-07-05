import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

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
                              text:
                                  "${AppLocalizations.of(context)!.faqSupportWorkAnswer}\n"),
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
                              final url = Uri.https(
                                  'link.clashofclans.com', '/$languageCode', {
                                'action': 'SupportCreator',
                                'id': 'Clashking',
                              });
                              return OpenClashDialog(url: url);
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
                            path: 'devs@clashk.ing',
                            query:
                                'subject=App%20Inquiry', // Add additional query parameters if needed
                          );

                          // Check if the device can launch the mailto scheme
                          try {
                            await launchUrl(params);
                          } catch (exception, stackTrace) {
                            // Provide feedback to the user if email client can't be opened
                            Sentry.captureException(exception,
                                stackTrace: stackTrace);

                            // Optionally, show an alert dialog or snackbar
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: Text(AppLocalizations.of(context)!
                                        .faqCannotOpenMailClient),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                            AppLocalizations.of(context)!.generalOk),
                                      ),
                                    ],
                                  );
                                },
                              );

                              // Copy the email to the clipboard or show a Snackbar message
                              Clipboard.setData(
                                  ClipboardData(text: 'devs@clashk.ing'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Email address copied to clipboard'),
                                ),
                              );
                            }
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
