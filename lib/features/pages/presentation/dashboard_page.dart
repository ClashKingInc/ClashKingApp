import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/pages/widgets/utils_creator_code_card.dart';
import 'package:clashkingapp/features/pages/widgets/player_search_card.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/widgets/player_card.dart';
import 'package:clashkingapp/features/player/presentation/widgets/player_legend_card.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final playerService = context.watch<PlayerService>();
    final warCwlService = context.read<WarCwlService>();
    final clanService = context.watch<ClanService>();

    return Scaffold(
      body: RefreshIndicator(
        backgroundColor: Theme.of(context).colorScheme.surface,
        onRefresh: () async {
          await cocService.loadApiData(playerService, clanService, warCwlService);
        },
        child: Consumer<PlayerService>(
          builder: (context, playerService, child) {
            final selectedProfile = playerService.profiles.firstWhere(
              (profile) => profile.tag == cocService.selectedTag,
            );

            if (selectedProfile.tag.isEmpty) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)?.connectionErrorRelaunch ??
                      "Error, please restart",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }

            return ListView(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CreatorCodeCard(),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: PlayerSearchCard(),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: PlayerCard(),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: PlayerLegendCard(),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
