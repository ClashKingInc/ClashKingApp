import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ClanJoinLeaveCard extends StatelessWidget {
  ClanJoinLeaveCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final cocService = context.watch<CocAccountService>();
    final player = playerService.getSelectedProfile(cocService);
    final clan = player?.clan;
    final formattedDate = DateFormat.yMMMd().format(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Column(
                  children: <Widget>[
                    SizedBox(width: 100),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: MobileWebImage(imageUrl: ImageAssets.goblin),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                        AppLocalizations.of(context)!.joinLeaveTitle,
                        style: Theme.of(context).textTheme.labelLarge,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                      Wrap(
                        spacing: 7.0,
                        runSpacing: -7.0,
                        children: <Widget>[
                          IconChip(
                            icon: LucideIcons.logIn,
                            color: Colors.green,
                            size: 16,
                            labelPadding: 2,
                            label: clan!.joinLeave!.stats.totalJoins.toString(),
                            description: AppLocalizations.of(context)!
                                .joinLeaveJoinNumberDescription(
                                    clan.joinLeave!.stats.totalJoins,
                                    formattedDate),
                          ),
                          IconChip(
                            icon: LucideIcons.logOut,
                            color: Colors.red,
                            size: 16,
                            labelPadding: 2,
                            label: clan.joinLeave!.stats.totalLeaves.toString(),
                            description: AppLocalizations.of(context)!
                                .joinLeaveNumberDescription(
                                    clan.joinLeave!.stats.totalLeaves,
                                    formattedDate),
                          ),
                          IconChip(
                              icon: LucideIcons.arrowUpDown,
                              color: Colors.blue,
                              size: 16,
                              labelPadding: 2,
                              label: clan.joinLeave!.stats.movingPlayers
                                  .toString(),
                              description: AppLocalizations.of(context)!
                                  .joinLeaveMovingNumberDescription(
                                      clan.joinLeave!.stats.movingPlayers,
                                      formattedDate)),
                          IconChip(
                            icon: LucideIcons.user,
                            size: 16,
                            labelPadding: 2,
                            label:
                                clan.joinLeave!.stats.uniquePlayers.toString(),
                            description: AppLocalizations.of(context)!
                                .joinLeaveUniqueNumberDescription(
                                    clan.joinLeave!.stats.uniquePlayers,
                                    formattedDate),
                          ),
                          IconChip(
                            icon: LucideIcons.plus,
                            color: Colors.green,
                            size: 16,
                            labelPadding: 2,
                            label: clan.joinLeave!.stats.playerStillInClan
                                .toString(),
                            description: AppLocalizations.of(context)!
                                .joinLeaveStillInClanNumberDescription(
                                    clan.joinLeave!.stats.playerStillInClan),
                          ),
                          IconChip(
                            icon: LucideIcons.minus,
                            color: Colors.red,
                            size: 16,
                            labelPadding: 2,
                            label:
                                clan.joinLeave!.stats.playerLeftClan.toString(),
                            description: AppLocalizations.of(context)!
                                .joinLeaveLeftClanNumberDescription(
                                    clan.joinLeave!.stats.playerLeftClan),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
