import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_clan.dart';
import 'package:clashkingapp/features/war_cwl/presentation/widgets/cwl_team_card.dart';
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

    final Map<String, String> sortByOptions = {
      AppLocalizations.of(context)!.stars: 'stars',
      AppLocalizations.of(context)!.destructionRate: 'percentage',
      AppLocalizations.of(context)!.townHallLevel: 'townHallLevel',
      AppLocalizations.of(context)!.missedAttacks: 'missedAttacks',
      AppLocalizations.of(context)!.averageStars: 'averageStars',
      AppLocalizations.of(context)!.zeroStar: '0stars',
      AppLocalizations.of(context)!.oneStar: '1stars',
      AppLocalizations.of(context)!.twoStars: '2stars',
      AppLocalizations.of(context)!.threeStars: '3stars',
      AppLocalizations.of(context)!.defenseStars: 'defStars',
      AppLocalizations.of(context)!.defenseDestruction: 'defDestruction',
      AppLocalizations.of(context)!.defenseAverageStars: 'defAverageStars',
      AppLocalizations.of(context)!.defZeroStar: 'def0stars',
      AppLocalizations.of(context)!.defOneStar: 'def1stars',
      AppLocalizations.of(context)!.defTwoStars: 'def2stars',
      AppLocalizations.of(context)!.defThreeStars: 'def3stars',
    };

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
        const SizedBox(height: 10),
        FilterDropdown(
          sortBy: sortBy,
          updateSortBy: (newValue) {
            setState(() {
              sortBy = newValue;
            });
          },
          sortByOptions: sortByOptions,
        ),
        const SizedBox(height: 10),
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
