import 'package:clashkingapp/features/pages/widgets/clan_no_clan_card.dart';
import 'package:clashkingapp/features/pages/widgets/cwl_card.dart';
import 'package:clashkingapp/features/pages/widgets/cwl_war_card.dart';
import 'package:clashkingapp/features/pages/widgets/war_access_denied_card.dart';
import 'package:clashkingapp/features/pages/widgets/war_card.dart';
import 'package:clashkingapp/features/pages/widgets/war_history_card.dart';
import 'package:clashkingapp/features/pages/widgets/war_not_in_war_card.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';

class WarCwlPage extends StatelessWidget {
  const WarCwlPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final clanService = context.watch<ClanService>();
    final playerService = context.watch<PlayerService>();
    final warCwlService = context.watch<WarCwlService>();
    final player = playerService.getSelectedProfile(cocService);

    final clan = clanService.getClanByTag(
        playerService.getSelectedProfile(cocService)?.clanTag ?? "");
    final warCwl = warCwlService.getWarCwlByTag(clan?.tag ?? "");
    final hasClan = clan != null && clan.tag.isNotEmpty;
    final isPlayerInWarElsewhere = player?.warData != null;
    final cwlClan = warCwl?.leagueInfo?.clans
        .firstWhere((element) => element.tag == clan!.tag);

    return Scaffold(
      body: RefreshIndicator(
        backgroundColor: Theme.of(context).colorScheme.surface,
        onRefresh: () async {
          await cocService.loadApiData(
              playerService, clanService, warCwlService);
        },
        child: ListView(
          children: [
            const SizedBox(height: 4),
            if (!hasClan)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Card(child: NoClanCard()),
              )
            else if (warCwl != null && warCwl.isInWar == true)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WarScreen(war: warCwl.warInfo),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: WarCard(
                      currentWarInfo: warCwl.warInfo, clanTag: clan.tag),
                ),
              )
            else if (warCwl != null && warCwl.isInCwl == true)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Card(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        Text(AppLocalizations.of(context)!.clanWarLeague),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CwlScreen(
                                clanTag: clan.tag,
                                warCwl: warCwl,
                                clanInfo: cwlClan!,
                              ),
                            ),
                          ),
                          child: CwlCard(),
                        ),
                        if (warCwl.getActiveWarByTag(clan.tag) != null)
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CwlScreen(
                                  clanTag: clan.tag,
                                  warCwl: warCwl,
                                  clanInfo: cwlClan!,
                                ),
                              ),
                            ),
                            child: CurrentWarInfoCard(),
                          )
                      ],
                    ),
                  ),
                ),
              )
            else if (warCwl != null && warCwl.warInfo.state == "accessDenied")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: WarAccessDeniedCard(
                  clanName: clan.name,
                  clanBadgeUrl: clan.badgeUrls.large,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: NotInWarCard(
                  clanName: clan.name,
                  clanBadgeUrl: clan.badgeUrls.large,
                ),
              ),
            if (isPlayerInWarElsewhere)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: WarCard(
                  currentWarInfo: player!.warData!,
                  clanTag: player.clanTag,
                ),
              ),
            if (hasClan &&
                warCwl != null &&
                !warCwl.isInCwl &&
                warCwl.warInfo.state == "accessDenied" &&
                clan.isWarLogPublic == true)
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: WarAccessDeniedCard(
                    clanName: clan.name,
                    clanBadgeUrl: clan.badgeUrls.large,
                  )),
            if (hasClan &&
                clan.isWarLogPublic == true &&
                clan.clanWarStats != null)
              WarHistoryCard(clan: clan),
          ],
        ),
      ),
    );
  }
}
