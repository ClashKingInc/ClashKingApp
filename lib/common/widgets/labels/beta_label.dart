import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class BetaLabel extends StatelessWidget {
  const BetaLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 24,
      child: GestureDetector(
        onTap: () => showBetaPopup(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(AppLocalizations.of(context)!.betaLabel,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}



void showBetaPopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.betaFeature),
        content: Text(AppLocalizations.of(context)!.betaDescription),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
