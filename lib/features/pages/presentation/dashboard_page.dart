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
import 'package:clashkingapp/common/widgets/responsive_layout_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/error/error_page.dart';
import 'dart:io';

class DashboardPage extends StatelessWidget {
  // Helper function to determine if an error is network-related
  bool _isNetworkError(dynamic error) {
    if (error is SocketException) {
      return true;
    }
    if (error is Exception) {
      String errorString = error.toString().toLowerCase();
      return errorString.contains('network') ||
             errorString.contains('connection') ||
             errorString.contains('hostname') ||
             errorString.contains('socket') ||
             errorString.contains('timeout') ||
             errorString.contains('no address');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final clanService = context.watch<ClanService>();
    final warCwlService = context.read<WarCwlService>();
    final cocService = context.watch<CocAccountService>();
    final player = playerService.getSelectedProfile(cocService);

    return Scaffold(
      body: ResponsiveLayoutWrapper(
        child: RefreshIndicator(
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
              if (_isNetworkError(e)) {
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
        child: Consumer<PlayerService>(
          builder: (context, playerService, child) {
            final selectedProfile = playerService.getSelectedProfile(cocService);

            if (selectedProfile == null || selectedProfile.tag.isEmpty) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)?.authErrorConnectionRelaunch ??
                      "Error, please restart",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }

            return ListView(
              children: <Widget>[
                LastRefreshIndicator(lastRefresh: cocService.lastRefresh),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CreatorCodeCard(),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      if (player?.legendsBySeason != null &&
                          player!.legendsBySeason!.allSeasons.isNotEmpty) {
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: PlayerCard(),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerLegendScreen(
                        player: player!,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: PlayerLegendCard(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: PlayerToDoCard(),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: PlayerWarStatsCard(),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    ),
    );
  }
}
