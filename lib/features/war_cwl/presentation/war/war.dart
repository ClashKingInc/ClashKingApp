import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member.dart'
    show WarMember;
import 'package:clashkingapp/features/war_cwl/presentation/war/widgets/war_calculator_card.dart'
    show WarCalculatorCard;
import 'package:clashkingapp/features/war_cwl/presentation/war/war_events_tab.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/widgets/war_header.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war_statistics_tab.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war_team_tab.dart'
    show WarTeamTab;
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class WarScreen extends StatefulWidget {
  final WarInfo war;

  const WarScreen({super.key, required this.war});

  @override
  State<WarScreen> createState() => _WarScreenState();
}

class PlayerTab {
  String tag;
  String name;
  int townhallLevel;
  int mapPosition;

  PlayerTab(this.tag, this.name, this.townhallLevel, this.mapPosition);
}

class _WarScreenState extends State<WarScreen> with TickerProviderStateMixin {
  late TabController tabController;
  int _currentSegment = 1;
  String filterBy = "all";

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DebugUtils.debugInfo("war data ${widget.war.clan?.name} ${widget.war.opponent?.name}");
    final clanMembers = widget.war.clan?.members ?? [];
    final opponentMembers = widget.war.opponent?.members ?? [];

    List<WarMember> filterMembers(List<WarMember> members, String filter) {
      switch (filter) {
        case 'rattacks':
          return members.where((m) => (m.attacks?.isNotEmpty ?? false)).toList()
            ..sort((a, b) {
              final aBest = a.attacks!.reduce((curr, next) =>
                  next.stars > curr.stars ||
                          (next.stars == curr.stars &&
                              next.destructionPercentage >
                                  curr.destructionPercentage)
                      ? next
                      : curr);

              final bBest = b.attacks!.reduce((curr, next) =>
                  next.stars > curr.stars ||
                          (next.stars == curr.stars &&
                              next.destructionPercentage >
                                  curr.destructionPercentage)
                      ? next
                      : curr);

              if (aBest.stars != bBest.stars) {
                return bBest.stars.compareTo(aBest.stars);
              } else {
                return bBest.destructionPercentage
                    .compareTo(aBest.destructionPercentage);
              }
            });

        case 'rdefenses':
          return members
              .where(
                  (m) => m.opponentAttacks > 0 && m.bestOpponentAttack != null)
              .toList()
            ..sort((a, b) {
              final aDef = a.bestOpponentAttack!;
              final bDef = b.bestOpponentAttack!;

              if (aDef.stars != bDef.stars) {
                return aDef.stars.compareTo(bDef.stars);
              } else {
                return aDef.destructionPercentage
                    .compareTo(bDef.destructionPercentage);
              }
            });

        case 'noattacks':
          return members.where((m) => (m.attacks?.isEmpty ?? true)).toList()
            ..sort((a, b) {
              if (a.mapPosition != b.mapPosition) {
                return a.mapPosition.compareTo(b.mapPosition);
              } else {
                return a.name.compareTo(b.name);
              }
            });
        case 'nodefenses':
          return members.where((m) => m.opponentAttacks == 0).toList()
            ..sort((a, b) {
              if (a.mapPosition != b.mapPosition) {
                return a.mapPosition.compareTo(b.mapPosition);
              } else {
                return a.name.compareTo(b.name);
              }
            });
        case '3stars':
        case '2stars':
        case '1star':
        case '0star':
          int stars = int.parse(filter[0]);
          return members
              .where((m) => m.attacks?.any((a) => a.stars == stars) ?? false)
              .toList()
            ..sort((a, b) {
              if (a.mapPosition != b.mapPosition) {
                return a.mapPosition.compareTo(b.mapPosition);
              } else {
                return a.name.compareTo(b.name);
              }
            });
        case 'def_3stars':
        case 'def_2stars':
        case 'def_1star':
        case 'def_0star':
          int stars = int.parse(filter.split('_')[1][0]);
          return members
              .where((m) => m.bestOpponentAttack?.stars == stars)
              .toList()
            ..sort((a, b) {
              if (a.mapPosition != b.mapPosition) {
                return a.mapPosition.compareTo(b.mapPosition);
              } else {
                return a.name.compareTo(b.name);
              }
            });
        case 'bestAttacks':
          return members.where((m) => (m.attacks?.isNotEmpty ?? false)).toList()
            ..sort((a, b) {
              final aStars = a.attacks!.fold<int>(0, (sum, a) => sum + a.stars);
              final bStars = b.attacks!.fold<int>(0, (sum, a) => sum + a.stars);

              if (bStars != aStars) return bStars.compareTo(aStars);

              final aDestruction = a.attacks!
                  .fold<double>(0, (sum, a) => sum + a.destructionPercentage);
              final bDestruction = b.attacks!
                  .fold<double>(0, (sum, a) => sum + a.destructionPercentage);

              return bDestruction.compareTo(aDestruction);
            });
        case 'bestDefenses':
          return members.where((m) => (m.bestOpponentAttack != null)).toList()
            ..sort((b, a) {
              final aStars = a.bestOpponentAttack!.stars;
              final bStars = b.bestOpponentAttack!.stars;

              if (bStars != aStars) return bStars.compareTo(aStars);

              final aDestruction = a.bestOpponentAttack!.destructionPercentage;
              final bDestruction = b.bestOpponentAttack!.destructionPercentage;

              return bDestruction.compareTo(aDestruction);
            });
        case 'bestPerformance':
          return members
              .where((m) =>
                  (m.attacks != null && m.attacks!.isNotEmpty) ||
                  m.bestOpponentAttack != null)
              .toList()
            ..sort((a, b) {
              // Atk : stars + destruction
              final aAtkStars =
                  a.attacks?.fold<int>(0, (sum, a) => sum + a.stars) ?? 0;
              final bAtkStars =
                  b.attacks?.fold<int>(0, (sum, a) => sum + a.stars) ?? 0;

              final aAtkDestr = a.attacks?.fold<double>(
                      0, (sum, a) => sum + a.destructionPercentage) ??
                  0;
              final bAtkDestr = b.attacks?.fold<double>(
                      0, (sum, a) => sum + a.destructionPercentage) ??
                  0;

              // Def
              final aDefStars = a.bestOpponentAttack?.stars ?? 0;
              final bDefStars = b.bestOpponentAttack?.stars ?? 0;

              final aDefDestr =
                  a.bestOpponentAttack?.destructionPercentage ?? 0.0;
              final bDefDestr =
                  b.bestOpponentAttack?.destructionPercentage ?? 0.0;

              // Final score
              final aScore = aAtkStars * 100 + aAtkDestr - aDefStars * 100 - aDefDestr;
              final bScore = bAtkStars * 100 + bAtkDestr - bDefStars * 100 - bDefDestr;

              return bScore.compareTo(aScore);
            });

        default:
          return members
            ..sort((a, b) {
              if (a.mapPosition != b.mapPosition) {
                return a.mapPosition.compareTo(b.mapPosition);
              } else {
                return a.name.compareTo(b.name);
              }
            });
      }
    }

    final rawMembers = _currentSegment == 1 ? clanMembers : opponentMembers;
    final filteredMembers = filterMembers(rawMembers, filterBy);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            WarHeader(warInfo: widget.war),
            ScrollableTab(
              tabBarDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              labelColor: Theme.of(context).colorScheme.onSurface,
              labelPadding: EdgeInsets.zero,
              labelStyle: Theme.of(context).textTheme.bodyLarge,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
              onTap: (value) {},
              tabs: [
                Tab(text: AppLocalizations.of(context)!.navigationStatistics),
                Tab(text: AppLocalizations.of(context)!.warEventsTitle),
                Tab(text: AppLocalizations.of(context)!.navigationTeam),
              ],
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      WarStatisticsTab(warInfo: widget.war),
                      const SizedBox(height: 10),
                      WarCalculatorCard(warInfo: widget.war),
                    ],
                  ),
                ),
                WarEventsTab(warInfo: widget.war),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      FilterDropdown(
                          sortBy: filterBy,
                          updateSortBy: (value) {
                            setState(() {
                              filterBy = value;
                            });
                          },
                          sortByOptions: {
                            AppLocalizations.of(context)!.warPositionMap:
                                'all',
                            AppLocalizations.of(context)!.warAttacksTitle:
                                'rattacks',
                            AppLocalizations.of(context)!.warDefensesTitle:
                                'rdefenses',
                            AppLocalizations.of(context)!.warAttacksBest:
                                'bestAttacks',
                            AppLocalizations.of(context)!.warDefensesBest:
                                'bestDefenses',
                            AppLocalizations.of(context)!.warStarsBestPerformance:
                                'bestPerformance',
                            AppLocalizations.of(context)!.warAttacksNone:
                                'noattacks',
                            AppLocalizations.of(context)!.warDefensesNone:
                                'nodefenses',
                            generateStarsWithIconBefore(
                                3, 16, ImageAssets.sword): '3stars',
                            generateStarsWithIconBefore(
                                2, 16, ImageAssets.sword): '2stars',
                            generateStarsWithIconBefore(
                                1, 16, ImageAssets.sword): '1star',
                            generateStarsWithIconBefore(
                                0, 16, ImageAssets.sword): '0star',
                            generateStarsWithIconBefore(
                                    3, 16, ImageAssets.shieldWithArrow):
                                'def_3stars',
                            generateStarsWithIconBefore(
                                    2, 16, ImageAssets.shieldWithArrow):
                                'def_2stars',
                            generateStarsWithIconBefore(
                                    1, 16, ImageAssets.shieldWithArrow):
                                'def_1star',
                            generateStarsWithIconBefore(
                                    0, 16, ImageAssets.shieldWithArrow):
                                'def_0star',
                          }),
                      const SizedBox(height: 8),
                      CustomSlidingSegmentedControl<int>(
                        initialValue: _currentSegment,
                        children: {
                          1: Text(AppLocalizations.of(context)!.warMyTeam),
                          2: Text(
                              AppLocalizations.of(context)!.warEnemiesTeam),
                        },
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .tertiary
                              .withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        thumbDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        onValueChanged: (v) {
                          setState(() {
                            _currentSegment = v;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      WarTeamTab(
                        members: filteredMembers,
                        warInfo: widget.war,
                        attacksPerMember: widget.war.attacksPerMember ?? 1,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
