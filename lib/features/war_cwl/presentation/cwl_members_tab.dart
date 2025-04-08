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
  final Map<String, GlobalKey> _cardKeys = {};

  bool showFullStats = false;

  void updateSortBy(String newSortBy) {
    setState(() {
      sortBy = newSortBy;
    });
  }

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
    final Map<String, String> sortByOptions = {
      AppLocalizations.of(context)!.stars: 'stars',
      AppLocalizations.of(context)!.destructionRate: 'percentage',
      AppLocalizations.of(context)!.averageStars: 'averageStars',
      AppLocalizations.of(context)!.averageDestruction: 'averagePercentage',
      AppLocalizations.of(context)!.attackCount: 'attackCount',
      AppLocalizations.of(context)!.missedAttacks: 'missedAttacks',
      AppLocalizations.of(context)!.zeroStar: '0stars',
      AppLocalizations.of(context)!.oneStar: '1stars',
      AppLocalizations.of(context)!.twoStars: '2stars',
      AppLocalizations.of(context)!.threeStars: '3stars',
      AppLocalizations.of(context)!.lowerTownHallAttack: 'attackLowerTH',
      AppLocalizations.of(context)!.upperTownHallAttack: 'attackUpperTH',
      AppLocalizations.of(context)!.defenseStars: 'defStars',
      AppLocalizations.of(context)!.defenseDestruction: 'defDestruction',
      AppLocalizations.of(context)!.defenseAverageStars: 'defAverageStars',
      AppLocalizations.of(context)!.defenseAverageDestruction:
          'defAverageDestruction',
      AppLocalizations.of(context)!.defZeroStar: 'def0stars',
      AppLocalizations.of(context)!.defOneStar: 'def1stars',
      AppLocalizations.of(context)!.defTwoStars: 'def2stars',
      AppLocalizations.of(context)!.defThreeStars: 'def3stars',
      AppLocalizations.of(context)!.lowerTownHallDefense: 'defenseLowerTH',
      AppLocalizations.of(context)!.upperTownHallDefense: 'defenseUpperTH',
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
          final key = _cardKeys.putIfAbsent(member.tag, () => GlobalKey());
          return MembersCard(
            key: key,
            sortBy: sortBy,
            showFullStats: showFullStats,
            onToggleFullStats: () => toggleShowStats(key),
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
    case '0stars':
      members.sort((a, b) => (b.zeroStar).compareTo(a.zeroStar));
      break;
    case '1stars':
      members.sort((a, b) => (b.oneStar).compareTo(a.oneStar));
      break;
    case '2stars':
      members.sort((a, b) => (b.twoStars).compareTo(a.twoStars));
      break;
    case '3stars':
      members.sort((a, b) => (b.threeStars).compareTo(a.threeStars));
      break;
    case 'attackLowerTH':
      members.sort((a, b) =>
          (b.attackLowerTHLevel ?? 0).compareTo(a.attackLowerTHLevel ?? 0));
      break;
    case 'attackUpperTH':
      members.sort((a, b) =>
          (b.attackUpperTHLevel ?? 0).compareTo(a.attackUpperTHLevel ?? 0));
      break;
    case 'def0stars':
      members.sort((a, b) => (b.zeroStarDef).compareTo(a.zeroStarDef));
      break;
    case 'def1stars':
      members.sort((a, b) => (b.oneStarDef).compareTo(a.oneStarDef));
      break;
    case 'def2stars':
      members.sort((a, b) => (b.twoStarsDef).compareTo(a.twoStarsDef));
      break;
    case 'def3stars':
      members.sort((a, b) => (b.threeStarsDef).compareTo(a.threeStarsDef));
      break;
    case 'defenseLowerTH':
      members.sort((a, b) =>
          (b.defenseLowerTHLevel ?? 0).compareTo(a.defenseLowerTHLevel ?? 0));
      break;
    case 'defenseUpperTH':
      members.sort((a, b) =>
          (b.defenseUpperTHLevel ?? 0).compareTo(a.defenseUpperTHLevel ?? 0));
      break;

    default:
      members.sort((a, b) =>
          (b.attackStats?.stars ?? 0).compareTo(a.attackStats?.stars ?? 0));
      break;
  }
}
