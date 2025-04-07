import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_clan.dart';
import 'package:clashkingapp/features/war_cwl/presentation/widgets/cwl_team_card.dart';
import 'package:flutter/material.dart';

class CwlTeamsTab extends StatefulWidget {
  final WarCwl warCwl;

  const CwlTeamsTab({super.key, required this.warCwl});

  @override
  CwlTeamsTabState createState() => CwlTeamsTabState();
}

class CwlTeamsTabState extends State<CwlTeamsTab> {
  late String sortBy = 'stars';
  final Map<String, String> sortByOptions = {
    'Stars': 'stars',
    'Destruction Percentage': 'percentage',
    'TownHall Level': 'townHallLevel',
  };

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
        ...clans.map((clan) => CwlTeamCard(clan: clan, warCwl: widget.warCwl)),
      ],
    );
  }
}
