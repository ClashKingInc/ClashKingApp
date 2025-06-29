import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/presentation/clan_capital/clan_capital_page.dart';
import 'package:clashkingapp/features/clan/presentation/join_leave/clan_join_leave.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';
import 'package:clashkingapp/features/pages/widgets/clan_capital_card.dart';
import 'package:clashkingapp/features/pages/widgets/clan_info_card.dart';
import 'package:clashkingapp/features/pages/widgets/clan_join_leave_card.dart';
import 'package:clashkingapp/features/pages/widgets/clan_no_clan_card.dart';
import 'package:clashkingapp/features/pages/widgets/clan_search_card.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/common/widgets/indicators/last_refresh_indicator.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';

class ClanPage extends StatelessWidget {
  const ClanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final clanService = context.watch<ClanService>();
    final playerService = context.watch<PlayerService>();
    final warCwlService = context.read<WarCwlService>();

    final clanInfo = clanService.getClanByTag(
        playerService.getSelectedProfile(cocService)?.clanTag ?? "");
    final hasClan = clanInfo != null && clanInfo.tag.isNotEmpty;

    return Scaffold(
      body: RefreshIndicator(
        backgroundColor: Theme.of(context).colorScheme.surface,
        onRefresh: () async {
          try {
            // Use bulk endpoint for consistent data structure
            final playerTags = cocService.getAccountTags();
            if (playerTags.isNotEmpty) {
              await cocService.refreshPageData(
                playerTags, playerService, clanService, warCwlService);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(AppLocalizations.of(context)!
                        .generalRefreshFailed(e.toString()))),
              );
            }
          }
        },
        child:
            Consumer<PlayerService>(builder: (context, playerService, child) {
          return ListView(children: <Widget>[
            LastRefreshIndicator(lastRefresh: cocService.lastRefresh),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ClanSearchCard(),
            ),
            if (hasClan)
              Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ClanInfoScreen(clanInfo: clanInfo),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ClanInfoCard(),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ClanJoinLeaveScreen(clanInfo: clanInfo),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ClanJoinLeaveCard(),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClanCapitalScreen(
                          clanInfo: clanInfo,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ClanCapitalCard(),
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Card(child: NoClanCard()),
              ),
            /*if (hasClan)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          /*ClanJoinLeaveScreen(
                      user: cocService.getAccountTags(),
                      clanInfo: clanInfo,
                    ),*/
                          SizedBox.shrink()),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Stack(
                    children: [
                      /*ClanJoinLeaveCard(
                        discordUser: cocService.getAccountTags(),
                        clanInfo: clanInfo,
                      ),*/
                      BetaLabel(),
                    ],
                  ),
                ),
              ),
            if (hasClan)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          /*ClanJoinLeaveScreen(
                      user: cocService.getAccountTags(),
                      clanInfo: clanInfo,
                    ),*/
                          SizedBox.shrink()),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Stack(
                    children: [
                      /*ClanCapitalCard(
                        user: cocService.getAccountTags(),
                        clanInfo: clanInfo,
                      ),*/
                      BetaLabel(),
                    ],
                  ),
                ),
              ),*/
            const SizedBox(height: 16),
          ]);
        }),
      ),
    );
  }
}
