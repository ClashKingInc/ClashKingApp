import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenClashDialog extends StatelessWidget {
  final Uri url;

  const OpenClashDialog({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.generalWarning,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      ),
      content: Text(AppLocalizations.of(context)!.errorExitAppToOpenClash),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocalizations.of(context)!.generalCancel,
              style: Theme.of(context).textTheme.bodyMedium),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.generalOk,
              style: Theme.of(context).textTheme.bodyMedium),
          onPressed: () {
            Navigator.of(context).pop();
            launchUrl(url);
          },
        ),
      ],
    );
  }
}
