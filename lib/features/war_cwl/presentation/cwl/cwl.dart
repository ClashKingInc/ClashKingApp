import 'package:clashkingapp/common/widgets/icons/excel_download_icon.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl_members_tab.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl_rounds_tab.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl_teams_tab.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_clan.dart';
import 'dart:ui';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:intl/intl.dart';
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
  @override
  Widget build(BuildContext context) {
    CwlClan clan = widget.warCwl.leagueInfo!.getClanDetails(widget.clanTag)!;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox(
                  height: 240,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                          Colors.black.withAlpha(128), BlendMode.darken),
                      child: MobileWebImage(
                        imageUrl: ImageAssets.cwlPageBackground,
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
                  top: 40,
                  right: 10,
                  child: DownloadCwlExcelButton(
                      url:
                          "${ApiService.apiUrlV2}/war/cwl-summary/export?tag=${widget.clanTag.replaceAll('#', '!')}",
                      fileName:
                          "cwl_summary_${widget.clanInfo.tag.replaceAll('#', '')}.xlsx"),
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
                            child: MobileWebImage(
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
                        alignment: WrapAlignment.center,
                        spacing: 7.0,
                        runSpacing: -7.0,
                        children: <Widget>[
                          ImageChip(
                            context: context,
                            textColor: Colors.white,
                            edgeColor: Colors.white,
                            imageUrl: ImageAssets.podium,
                            labelPadding: 6,
                            label: clan.rank.toString(),
                            description: AppLocalizations.of(context)!
                                .cwlRank(clan.rank),
                          ),
                          ImageChip(
                            context: context,
                            textColor: Colors.white,
                            edgeColor: Colors.white,
                            imageUrl: ImageAssets.builderBaseStar,
                            labelPadding: 2,
                            label: clan.stars.toString(),
                            description: AppLocalizations.of(context)!
                                .cwlStars(clan.stars),
                          ),
                          ImageChip(
                            context: context,
                            textColor: Colors.white,
                            edgeColor: Colors.white,
                            imageUrl: ImageAssets.hitrate,
                            labelPadding: 6,
                            label: NumberFormat('#,###',
                                    Localizations.localeOf(context).toString())
                                .format(clan.destructionPercentageInflicted),
                            description: AppLocalizations.of(context)!
                                .cwlDestructionPercentage(clan
                                    .destructionPercentageInflicted
                                    .toStringAsFixed(0)),
                          ),
                          ImageChip(
                            context: context,
                            textColor: Colors.white,
                            edgeColor: Colors.white,
                            imageUrl: ImageAssets.war,
                            labelPadding: 6,
                            label: clan.warsPlayed.toString(),
                            description: AppLocalizations.of(context)!
                                .cwlCurrentRound(clan.warsPlayed),
                          ),
                          ImageChip(
                            context: context,
                            textColor: Colors.white,
                            edgeColor: Colors.white,
                            imageUrl: ImageAssets.sword,
                            labelPadding: 2,
                            label:
                                "${clan.attackCount}/${widget.warCwl.teamSize * clan.warsPlayed}",
                            description: AppLocalizations.of(context)!
                                .cwlTotalAttacks(clan.attackCount,
                                    widget.warCwl.teamSize * clan.warsPlayed),
                          ),
                          ImageChip(
                            context: context,
                            textColor: Colors.white,
                            edgeColor: Colors.white,
                            imageUrl: ImageAssets.brokenSword,
                            labelPadding: 6,
                            label: clan.missedAttacks.toString(),
                            description:
                                AppLocalizations.of(context)!.warAttacksMissed,
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
                Tab(text: AppLocalizations.of(context)?.cwlRounds ?? 'Rounds'),
                Tab(text: AppLocalizations.of(context)?.navigationTeam ?? 'Teams'),
                Tab(text: AppLocalizations.of(context)?.clanMembers ?? "Members")
              ],
              children: [
                CwlRoundsTab(warCwl: widget.warCwl),
                CwlTeamsTab(warCwl: widget.warCwl),
                CwlMembersTab(warCwl: widget.warCwl, clanTag: widget.clanTag),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
