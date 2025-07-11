import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_member.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/widgets/cwl_member_card.dart';
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

  void toggleShowStats(GlobalKey<State<StatefulWidget>> key) {
    setState(() {
      showFullStats = !showFullStats;
      Future.delayed(Duration(milliseconds: 200), () {
        final context = key.currentContext;
        if (context != null && context.mounted) {
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
    final members =
        widget.warCwl.leagueInfo?.getClanDetails(widget.clanTag)?.members ?? [];
    sortCwlMembers(members, sortBy);
    
    final clanDetails = widget.warCwl.leagueInfo?.getClanDetails(widget.clanTag);
    final warsPlayed = clanDetails?.warsPlayed ?? 0;
    final attacksPerWar = 1; // Standard CWL attacks per war

    return Column(
      children: [
        const SizedBox(height: 12),
        FilterDropdown(
            sortBy: sortBy,
            updateSortBy: updateSortBy,
            sortByOptions: {
              generateDoubleIcons(
                  16, ImageAssets.sword, ImageAssets.builderBaseStar): 'stars',
              generateDoubleIcons(16, ImageAssets.sword, ImageAssets.hitrate):
                  'percentage',
              generateDoubleImageIconsWithText(
                  16,
                  ImageAssets.sword,
                  ImageAssets.builderBaseStar,
                  "(${AppLocalizations.of(context)!.warAbbreviationAvg})"): 'averageStars',
              generateDoubleImageIconsWithText(
                      16,
                      ImageAssets.sword,
                      ImageAssets.hitrate,
                      "(${AppLocalizations.of(context)!.warAbbreviationAvg})"):
                  'averagePercentage',
              generateImageIconWithText(16, ImageAssets.sword,
                  AppLocalizations.of(context)!.warAttacksCount): 'attackCount',
              generateImageIconWithText(16, ImageAssets.sword,
                  AppLocalizations.of(context)!.warAttacksMissed): 'missedAttacks',
              generateStarsWithIconBefore(3, 16, ImageAssets.sword): '3stars',
              generateStarsWithIconBefore(2, 16, ImageAssets.sword): '2stars',
              generateStarsWithIconBefore(1, 16, ImageAssets.sword): '1stars',
              generateStarsWithIconBefore(0, 16, ImageAssets.sword): '0stars',
              generateDoubleIconsWithText(
                      16,
                      ImageAssets.sword,
                      Icons.keyboard_double_arrow_down,
                      AppLocalizations.of(context)!.warOpponentLowerTownhall):
                  'attackLowerTH',
              generateDoubleIconsWithText(
                      16,
                      ImageAssets.sword,
                      Icons.keyboard_double_arrow_up,
                      AppLocalizations.of(context)!.warOpponentUpperTownhall):
                  'attackUpperTH',
              generateDoubleIcons(16, ImageAssets.shieldWithArrow,
                  ImageAssets.builderBaseStar): 'defStars',
              generateDoubleIcons(
                      16, ImageAssets.shieldWithArrow, ImageAssets.hitrate):
                  'defDestruction',
              generateDoubleImageIconsWithText(
                  16,
                  ImageAssets.shieldWithArrow,
                  ImageAssets.builderBaseStar,
                  "(${AppLocalizations.of(context)!.warAbbreviationAvg})"): 'defAverageStars',
              generateDoubleImageIconsWithText(
                      16,
                      ImageAssets.shieldWithArrow,
                      ImageAssets.hitrate,
                      "(${AppLocalizations.of(context)!.warAbbreviationAvg})"):
                  'defAverageDestruction',
              generateStarsWithIconBefore(3, 16, ImageAssets.shieldWithArrow):
                  'def3stars',
              generateStarsWithIconBefore(2, 16, ImageAssets.shieldWithArrow):
                  'def2stars',
              generateStarsWithIconBefore(1, 16, ImageAssets.shieldWithArrow):
                  'def1stars',
              generateStarsWithIconBefore(0, 16, ImageAssets.shieldWithArrow):
                  'def0stars',
              generateDoubleIconsWithText(
                      16,
                      ImageAssets.shieldWithArrow,
                      Icons.keyboard_double_arrow_down,
                      AppLocalizations.of(context)!.warOpponentLowerTownhall):
                  'defenseLowerTH',
              generateDoubleIconsWithText(
                      16,
                      ImageAssets.shieldWithArrow,
                      Icons.keyboard_double_arrow_up,
                      AppLocalizations.of(context)!.warOpponentUpperTownhall):
                  'defenseUpperTH',
            }),
        const SizedBox(height: 12),
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
            warsPlayed: warsPlayed,
            attacksPerWar: attacksPerWar,
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
