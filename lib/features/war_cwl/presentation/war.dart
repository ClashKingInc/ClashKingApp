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

class _WarScreenState extends State<WarScreen>
    with TickerProviderStateMixin {
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
                return aDef.stars
                    .compareTo(bDef.stars);
              } else {
                return aDef.destructionPercentage
                    .compareTo(bDef.destructionPercentage);
              }
            });

        case 'noattacks':
          return members.where((m) => (m.attacks?.isEmpty ?? true)).toList();
        case 'nodefenses':
          return members.where((m) => m.opponentAttacks == 0).toList();
        case '3stars':
        case '2stars':
        case '1star':
        case '0star':
          int stars = int.parse(filter[0]);
          return members
              .where((m) => m.attacks?.any((a) => a.stars == stars) ?? false)
              .toList();
        case 'def_3stars':
        case 'def_2stars':
        case 'def_1star':
        case 'def_0star':
          int stars = int.parse(filter.split('_')[1][0]);
          return members
              .where((m) => m.bestOpponentAttack?.stars == stars)
              .toList();
        case 'highDestruction':
          return members
              .where((m) =>
                  m.attacks?.any((a) => a.destructionPercentage >= 80) ?? false)
              .toList();
        case 'lowDestruction':
          return members
              .where((m) =>
                  m.attacks?.any((a) => a.destructionPercentage <= 50) ?? false)
              .toList();
        default:
          return members;
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
                Tab(text: AppLocalizations.of(context)!.statistics),
                Tab(text: AppLocalizations.of(context)!.events),
                Tab(text: AppLocalizations.of(context)!.team),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          FilterDropdown(
                              sortBy: filterBy,
                              updateSortBy: (value) {
                                setState(() {
                                  filterBy = value;
                                });
                              },
                              sortByOptions: {
                                AppLocalizations.of(context)!.mapPosition:
                                    'all',
                                AppLocalizations.of(context)!.attacks:
                                    'rattacks',
                                AppLocalizations.of(context)!.defense:
                                    'rdefenses',
                                AppLocalizations.of(context)!.noAttackYet:
                                    'noattacks',
                                AppLocalizations.of(context)!.noDefenseYet:
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
                          CustomSlidingSegmentedControl<int>(
                            initialValue: _currentSegment,
                            children: {
                              1: Text(AppLocalizations.of(context)!.myTeam),
                              2: Text(
                                  AppLocalizations.of(context)!.enemiesTeam),
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
                        ],
                      ),
                      const SizedBox(height: 4),
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
