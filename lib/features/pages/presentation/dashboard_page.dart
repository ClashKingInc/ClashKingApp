import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/pages/widgets/player_to_do_card.dart';
import 'package:clashkingapp/features/pages/widgets/player_war_stats_card.dart';
import 'package:clashkingapp/features/pages/widgets/utils_creator_code_card.dart';
import 'package:clashkingapp/features/pages/widgets/player_search_card.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/pages/widgets/player_card.dart';
import 'package:clashkingapp/features/pages/widgets/player_legend_card.dart';
import 'package:clashkingapp/features/player/presentation/legend/player_legend_page.dart'
    show PlayerLegendScreen;
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/common/widgets/indicators/last_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/error/error_page.dart';
import 'package:clashkingapp/core/utils/network_error_utils.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) { // NOSONAR
    final playerService = context.watch<PlayerService>();
    final clanService = context.read<ClanService>();
    final warCwlService = context.read<WarCwlService>();
    final cocService = context.watch<CocAccountService>();
    final player = playerService.getSelectedProfile(cocService);

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
              if (isNetworkError(e)) {
                // Navigate to error page for network errors
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ErrorPage(
                      isNetworkError: true,
                      onRetry: () async {
                        // Trigger refresh while staying on error page
                        await cocService.refreshPageData(
                            cocService.getAccountTags(),
                            playerService,
                            clanService,
                            warCwlService);
                        // Only pop if refresh succeeds
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                );
              } else {
                // Show SnackBar for other errors
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .generalRefreshFailed(e.toString()))),
                );
              }
            }
          }
        },
        child: player == null || player.tag.isEmpty
            ? Center(
                child: Text(
                  AppLocalizations.of(context)?.authErrorConnectionRelaunch ??
                      "Error, please restart",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : ListView(
                children: <Widget>[
                  LastRefreshIndicator(lastRefresh: cocService.lastRefresh),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CreatorCodeCard(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        if (player.legendsBySeason != null &&
                            player.legendsBySeason!.allSeasons.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PlayerLegendScreen(player: player),
                            ),
                          );
                        }
                      },
                      child: PlayerSearchCard(),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: PlayerCard(),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerLegendScreen(
                          player: player,
                        ),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: PlayerLegendCard(),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: PlayerToDoCard(),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: PlayerWarStatsCard(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
      ),
    );
  }
}
