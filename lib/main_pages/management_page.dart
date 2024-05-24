import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(AppLocalizations.of(context)!.comingSoon),
      );
  }
}
