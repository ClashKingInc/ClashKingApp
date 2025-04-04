import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl_round_tab.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_league.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_clan.dart';
import 'dart:ui';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';

class CwlScreen extends StatefulWidget {
  final WarCwl warCwl;
  final String clanTag;
  final CwlClan clanInfo;

  CwlScreen({
    super.key,
    required this.warCwl,
    required this.clanTag,
    required this.clanInfo,
  });

  @override
  CwlScreenState createState() => CwlScreenState();
}

class CwlScreenState extends State<CwlScreen> {
  late String sortMembersBy = 'stars';
  late String sortTeamsBy = 'stars';

  void updateSortMembersBy(String newValue) {
    setState(() {
      sortMembersBy = newValue;
    });
  }

  void updateSortTeamsBy(String newValue) {
    setState(() {
      sortTeamsBy = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    CwlClan clan = widget.warCwl.leagueInfo!.getClanDetails(widget.clanTag)!;
    CwlLeague league = widget.warCwl.leagueInfo!;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox(
                  height: 220,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                          Colors.black.withAlpha(128), BlendMode.darken),
                      child: CachedNetworkImage(
                        imageUrl:
                            "https://assets.clashk.ing/landscape/cwl-landscape.png",
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(height: 36),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 70,
                            child: CachedNetworkImage(
                                imageUrl: widget.clanInfo.badgeUrls.medium),
                          ),
                          Column(
                            children: [
                              Text(
                                widget.clanInfo.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                              Text(
                                widget.clanInfo.tag,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 7.0,
                        runSpacing: -7.0,
                        children: <Widget>[
                          ImageChip(
                            textColor: Colors.white,
                            imageUrl: ImageAssets.podium,
                            labelPadding: 2,
                            label: clan.rank.toString(),
                            description: AppLocalizations.of(context)!
                                .cwlRank(clan.rank),
                          ),
                          ImageChip(
                            textColor: Colors.white,
                            imageUrl: ImageAssets.builderBaseStar,
                            labelPadding: 2,
                            label: clan.stars.toString(),
                            description: AppLocalizations.of(context)!
                                .cwlStars(clan.stars),
                          ),
                          IconChip(
                            textColor: Colors.white,
                            icon: Icons.keyboard_double_arrow_up,
                            color: Colors.blue,
                            size: 16,
                            labelPadding: 2,
                            label: league
                                    .getStarsGapFromRank(clan.tag, 1)
                                    ?.toString() ??
                                '-',
                            description: AppLocalizations.of(context)!
                                .cwlMissingStarsFromFirst(
                                    league.getStarsGapFromRank(clan.tag, 1) ??
                                        0),
                          ),
                          IconChip(
                            textColor: Colors.white,
                            icon: Icons.arrow_upward,
                            color: Colors.blue,
                            size: 16,
                            labelPadding: 2,
                            label: league
                                    .getStarsGapFromRank(
                                        clan.tag, clan.rank - 1)
                                    ?.toString() ??
                                '-',
                            description: AppLocalizations.of(context)!
                                .cwlMissingStarsFromNext(
                                    league.getStarsGapFromRank(
                                            clan.tag, clan.rank - 1) ??
                                        0),
                          ),
                          ImageChip(
                            textColor: Colors.white,
                            imageUrl: ImageAssets.hitrate,
                            labelPadding: 2,
                            label:
                                clan.destructionPercentage.toInt().toString(),
                            description: AppLocalizations.of(context)!
                                .cwlDestructionPercentage(clan
                                    .destructionPercentage
                                    .toStringAsFixed(0)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ScrollableTab(
              labelColor: Theme.of(context).colorScheme.onSurface,
              labelPadding: EdgeInsets.zero,
              labelStyle: Theme.of(context).textTheme.bodyLarge,
              tabBarDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
              onTap: (value) {},
              tabs: [
                Tab(text: AppLocalizations.of(context)?.rounds ?? 'Rounds'),
                Tab(text: AppLocalizations.of(context)?.team ?? 'Teams'),
                Tab(text: AppLocalizations.of(context)?.members ?? "Members")
              ],
              children: [
                CwlRoundsTab(warCwl: widget.warCwl),
                //CwlTeamsTab(context, widget.currentLeagueInfo, widget.clanTag, sortTeamsBy, updateSortTeamsBy),
                //CwlMembersTab(context, widget.currentLeagueInfo, widget.clanTag, sortMembersBy, updateSortMembersBy),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
