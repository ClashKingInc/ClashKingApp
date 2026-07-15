import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class NoClanCard extends StatelessWidget {
  const NoClanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: AppLocalizations.of(context)?.clanNone ?? 'No Clan',
      body: AppLocalizations.of(context)!.clanJoinToUnlock,
      icon: Icons.groups_2_outlined,
      padding: EdgeInsets.zero,
    );
  }
}
