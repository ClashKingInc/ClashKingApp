import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/clan/war_league/current_league_info.dart';
import 'package:clashkingapp/main_pages/wars_league_page/league/current_league_info_page.dart';
import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class CwlCard extends StatefulWidget {
  final CurrentLeagueInfo currentLeagueInfo;
  final String clanTag;
  final Clan clanInfo;
  final List<String> discordUser;

  CwlCard({
    super.key,
    required this.currentLeagueInfo,
    required this.clanTag,
    required this.clanInfo,
    required this.discordUser,
  });

  @override
  CwlCardState createState() => CwlCardState();
}

class CwlCardState extends State<CwlCard> {
  ClanLeagueDetails? clan;
  @override
  void initState() {
    super.initState();
    clan = widget.currentLeagueInfo.getClanDetails(widget.clanTag);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CurrentLeagueInfoScreen(
              clanInfo: widget.clanInfo,
              discordUser: widget.discordUser,
              currentLeagueInfo: widget.currentLeagueInfo,
              clanTag: widget.clanTag,
            ),
          ),
        );
      },
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
        child: Card(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 70,
                  width: 70,
                  child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                    imageUrl: widget.clanInfo.warLeague!.imageUrl,
                  ),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 7.0,
                        runSpacing: -7.0,
                        children: [
                          ImageChip(
                            imageUrl:
                                "https://assets.clashk.ing/icons/Icon_HV_Podium.png",
                            labelPadding: 2,
                            label: widget.currentLeagueInfo
                                .getClanDetails(widget.clanTag)!
                                .rank
                                .toString(),
                            description: AppLocalizations.of(context)!
                                .cwlRank(clan!.rank),
                          ),
                          ImageChip(
                            imageUrl:
                                "https://assets.clashk.ing/icons/Icon_BB_Star.png",
                            labelPadding: 2,
                            label: clan!.stars.toString(),
                            description: AppLocalizations.of(context)!
                                .cwlStars(clan!.stars),
                          ),
                          IconChip(
                            icon: Icons.keyboard_double_arrow_up,
                            color: Colors.green,
                            size: 16,
                            labelPadding: 2,
                            label: clan!.starsDifferenceWithFirst.toString(),
                            description: AppLocalizations.of(context)!
                                .cwlMissingStarsFromFirst(
                                    clan!.starsDifferenceWithFirst),
                          ),
                          IconChip(
                            icon: Icons.keyboard_arrow_up,
                            color: Colors.blue,
                            size: 16,
                            labelPadding: 2,
                            label: clan!.starsDifferenceWithNext.toString(),
                            description: AppLocalizations.of(context)!
                                .cwlMissingStarsFromNext(
                                    clan!.starsDifferenceWithNext),
                          ),
                          ImageChip(
                            imageUrl:
                                "https://assets.clashk.ing/icons/Icon_DC_Hitrate.png",
                            labelPadding: 2,
                            label:
                                clan!.destructionPercentage.toInt().toString(),
                            description: AppLocalizations.of(context)!
                                .cwlDestructionPercentage(clan!
                                    .destructionPercentage
                                    .toStringAsFixed(0)),
                          ),
                          IconChip(
                            icon: Icons.date_range,
                            color: Colors.blue,
                            size: 16,
                            labelPadding: 2,
                            label: widget.currentLeagueInfo.currentRound
                                .toString(),
                            description: AppLocalizations.of(context)!
                                .cwlCurrentRound(
                                    widget.currentLeagueInfo.currentRound),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
