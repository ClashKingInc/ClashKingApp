import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClanSearchFilters extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      title: Text(AppLocalizations.of(context)!.filters,
          textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Text(AppLocalizations.of(context)!.comingSoon),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () {
            // Apply your filters here
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.apply),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
