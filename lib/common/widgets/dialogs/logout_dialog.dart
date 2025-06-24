import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class ConfirmLogoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const ConfirmLogoutDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.generalWarning,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      content: Text(AppLocalizations.of(context)!.authConfirmLogout),
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
            onConfirm();
          },
        ),
      ],
    );
  }
}
