import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_clan.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/widgets/cwl_team_card.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class CwlTeamsTab extends StatefulWidget {
  final WarCwl warCwl;

  const CwlTeamsTab({super.key, required this.warCwl});

  @override
  CwlTeamsTabState createState() => CwlTeamsTabState();
}

class CwlTeamsTabState extends State<CwlTeamsTab> {
  late String sortBy = 'stars';
  final Map<String, GlobalKey> _cardKeys = {};

  bool showFullStats = false;

  void toggleShowStats(key) {
    setState(() {
      showFullStats = !showFullStats;
      Future.delayed(Duration(milliseconds: 200), () {
        final context = key.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: Duration(milliseconds: 300),
            alignment: 0.1,
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<CwlClan> clans = List.from(widget.warCwl.leagueInfo?.clans ?? []);

    if (sortBy == 'stars') {
      clans.sort((a, b) => b.stars.compareTo(a.stars));
    } else if (sortBy == 'percentage') {
      clans.sort((a, b) => b.destructionPercentageInflicted
          .compareTo(a.destructionPercentageInflicted));
    } else if (sortBy == 'townHallLevel') {
      List<int> thPriorityOrder = List.generate(20, (i) => 20 - i);
      clans.sort((a, b) {
        for (final level in thPriorityOrder) {
          int countA = a.townHallLevels[level.toString()] ?? 0;
          int countB = b.townHallLevels[level.toString()] ?? 0;

          if (countA != countB) {
            return countB.compareTo(countA);
          }
        }
        return 0;
      });
    } else if (sortBy == 'missedAttacks') {
      clans.sort((a, b) => b.missedAttacks.compareTo(a.missedAttacks));
    } else if (sortBy == 'averageStars') {
      clans.sort((a, b) => b.averageStars.compareTo(a.averageStars));
    } else if (sortBy == '0stars') {
      clans.sort((a, b) => b.zeroStar.compareTo(a.zeroStar));
    } else if (sortBy == '1stars') {
      clans.sort((a, b) => b.oneStar.compareTo(a.oneStar));
    } else if (sortBy == '2stars') {
      clans.sort((a, b) => b.twoStars.compareTo(a.twoStars));
    } else if (sortBy == '3stars') {
      clans.sort((a, b) => b.threeStars.compareTo(a.threeStars));
    } else if (sortBy == 'defStars') {
      clans.sort((a, b) => b.defStars.compareTo(a.defStars));
    } else if (sortBy == 'defDestruction') {
      clans.sort(
          (a, b) => b.destructionPercentage.compareTo(a.destructionPercentage));
    } else if (sortBy == 'defAverageStars') {
      clans.sort((a, b) => b.defAverageStars.compareTo(a.defAverageStars));
    } else if (sortBy == 'defAverageDestruction') {
      clans.sort(
          (a, b) => b.defAverageDestruction.compareTo(a.defAverageDestruction));
    } else if (sortBy == 'def0stars') {
      clans.sort((a, b) => b.zeroStarDef.compareTo(a.zeroStarDef));
    } else if (sortBy == 'def1stars') {
      clans.sort((a, b) => b.oneStarDef.compareTo(a.oneStarDef));
    } else if (sortBy == 'def2stars') {
      clans.sort((a, b) => b.twoStarsDef.compareTo(a.twoStarsDef));
    } else if (sortBy == 'def3stars') {
      clans.sort((a, b) => b.threeStarsDef.compareTo(a.threeStarsDef));
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        FilterDropdown(
            sortBy: sortBy,
            updateSortBy: (newValue) {
              setState(() {
                sortBy = newValue;
              });
            },
            sortByOptions: {
              generateDoubleIcons(
                  16, ImageAssets.sword, ImageAssets.builderBaseStar): 'stars',
              generateDoubleIcons(16, ImageAssets.sword, ImageAssets.hitrate):
                  'percentage',
              generateDoubleImageIconsWithText(
                  16,
                  ImageAssets.sword,
                  ImageAssets.townHall(17),
                  AppLocalizations.of(context)!.townHallLevel): 'townHallLevel',
              generateImageIconWithText(16, ImageAssets.sword,
                  AppLocalizations.of(context)!.missedAttacks): 'missedAttacks',
              generateDoubleImageIconsWithText(
                  16,
                  ImageAssets.sword,
                  ImageAssets.builderBaseStar,
                  "(${AppLocalizations.of(context)!.avg})"): 'averageStars',
              generateStarsWithIconBefore(3, 16, ImageAssets.sword): '3stars',
              generateStarsWithIconBefore(2, 16, ImageAssets.sword): '2stars',
              generateStarsWithIconBefore(1, 16, ImageAssets.sword): '1stars',
              generateStarsWithIconBefore(0, 16, ImageAssets.sword): '0stars',
              generateDoubleIcons(16, ImageAssets.shieldWithArrow,
                  ImageAssets.builderBaseStar): 'defStars',
              generateDoubleIcons(
                      16, ImageAssets.shieldWithArrow, ImageAssets.hitrate):
                  'defDestruction',
              generateDoubleImageIconsWithText(
                  16,
                  ImageAssets.shieldWithArrow,
                  ImageAssets.builderBaseStar,
                  "(${AppLocalizations.of(context)!.avg})"): 'defAverageStars',
              generateDoubleImageIconsWithText(
                      16,
                      ImageAssets.shieldWithArrow,
                      ImageAssets.hitrate,
                      "(${AppLocalizations.of(context)!.avg})"):
                  'defAverageDestruction',
              generateStarsWithIconBefore(3, 16, ImageAssets.shieldWithArrow):
                  'def3stars',
              generateStarsWithIconBefore(2, 16, ImageAssets.shieldWithArrow):
                  'def2stars',
              generateStarsWithIconBefore(1, 16, ImageAssets.shieldWithArrow):
                  'def1stars',
              generateStarsWithIconBefore(0, 16, ImageAssets.shieldWithArrow):
                  'def0stars',
            }),
        const SizedBox(height: 12),
        ...clans.map((clan) {
          final key = _cardKeys.putIfAbsent(clan.tag, () => GlobalKey());
          return CwlTeamCard(
              clan: clan,
              warCwl: widget.warCwl,
              showFullStats: showFullStats,
              onToggleFullStats: () {
                toggleShowStats(key);
              });
        })
      ],
    );
  }
}
