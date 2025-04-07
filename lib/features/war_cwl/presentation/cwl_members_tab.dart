import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_member.dart';
import 'package:clashkingapp/features/war_cwl/presentation/widgets/cwl_member_card.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class CwlMembersTab extends StatefulWidget {
  final WarCwl warCwl;
  final String clanTag;

  const CwlMembersTab({
    super.key,
    required this.warCwl,
    required this.clanTag,
  });

  @override
  State<CwlMembersTab> createState() => _CwlMembersTabState();
}

class _CwlMembersTabState extends State<CwlMembersTab> {
  String sortBy = 'stars';

  bool showFullStats = false;

  void updateSortBy(String newSortBy) {
    setState(() {
      sortBy = newSortBy;
    });
  }

  void toggleShowStats() {
    setState(() {
      showFullStats = !showFullStats;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> sortByOptions = {
      AppLocalizations.of(context)!.stars: 'stars',
      AppLocalizations.of(context)!.destructionRate: 'percentage',
      AppLocalizations.of(context)!.averageStars: 'averageStars',
      AppLocalizations.of(context)!.averageDestruction: 'averagePercentage',
      AppLocalizations.of(context)!.attackCount: 'attackCount',
      AppLocalizations.of(context)!.missedAttacks: 'missedAttacks',
      AppLocalizations.of(context)!.defenseStars: 'defStars',
      AppLocalizations.of(context)!.defenseDestruction: 'defDestruction',
      AppLocalizations.of(context)!.defenseAverageStars: 'defAverageStars',
      AppLocalizations.of(context)!.defenseAverageDestruction:
          'defAverageDestruction',
    };

    final members =
        widget.warCwl.leagueInfo?.getClanDetails(widget.clanTag)?.members ?? [];
    sortCwlMembers(members, sortBy);

    return Column(
      children: [
        const SizedBox(height: 8),
        FilterDropdown(
          sortBy: sortBy,
          updateSortBy: updateSortBy,
          sortByOptions: sortByOptions,
        ),
        const SizedBox(height: 4),
        ...members.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          return MembersCard(
            sortBy: sortBy,
            showFullStats: showFullStats,
            onToggleFullStats: toggleShowStats,
            member: member,
            index: index,
          );
        }),
      ],
    );
  }
}

void sortCwlMembers(List<CwlMember> members, String sortBy) {
  switch (sortBy) {
    case 'stars':
      members.sort((a, b) =>
          (b.attackStats?.stars ?? 0).compareTo(a.attackStats?.stars ?? 0));
      break;
    case 'percentage':
      members.sort((a, b) => (b.attackStats?.totalDestruction ?? 0)
          .compareTo(a.attackStats?.totalDestruction ?? 0));
      break;
    case 'averageStars':
      members.sort((a, b) => (b.attackStats?.averageStars ?? 0)
          .compareTo(a.attackStats?.averageStars ?? 0));
      break;
    case 'averagePercentage':
      members.sort((a, b) => (b.attackStats?.averageDestruction ?? 0)
          .compareTo(a.attackStats?.averageDestruction ?? 0));
      break;
    case 'attackCount':
      members.sort((a, b) => (b.attackStats?.attackCount ?? 0)
          .compareTo(a.attackStats?.attackCount ?? 0));
      break;
    case 'missedAttacks':
      members.sort((a, b) => (b.attackStats?.missedAttacks ?? 0)
          .compareTo(a.attackStats?.missedAttacks ?? 0));
      break;
    case 'defStars':
      members.sort((a, b) =>
          (b.defenseStats?.stars ?? 0).compareTo(a.defenseStats?.stars ?? 0));
      break;
    case 'defDestruction':
      members.sort((a, b) => (b.defenseStats?.totalDestruction ?? 0)
          .compareTo(a.defenseStats?.totalDestruction ?? 0));
      break;
    case 'defAverageStars':
      members.sort((a, b) => (b.defenseStats?.averageStars ?? 0)
          .compareTo(a.defenseStats?.averageStars ?? 0));
      break;
    case 'defAverageDestruction':
      members.sort((a, b) => (b.defenseStats?.averageDestruction ?? 0)
          .compareTo(a.defenseStats?.averageDestruction ?? 0));
      break;
  }
}
