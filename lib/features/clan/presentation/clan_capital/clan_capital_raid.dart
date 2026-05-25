import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/clan_member.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/features/clan/models/clan_capital_history.dart';
import 'package:provider/provider.dart';

class ClanCapitalRaid extends StatefulWidget {
  final Clan clanInfo;

  const ClanCapitalRaid({super.key, required this.clanInfo});

  @override
  ClanCapitalRaidState createState() => ClanCapitalRaidState();
}

class ClanCapitalRaidState extends State<ClanCapitalRaid> {
  static const String _numberFormat = '#,###';

  String filterBy = "all";
  bool filterAccountActive = false;
  int week = 0;

  void incrementRaid() {
    setState(() {
      if (week > 0) {
        week--;
      }
    });
  }

  void decrementRaid() {
    setState(() {
      if (week < widget.clanInfo.clanCapitalRaid!.items.length - 1) {
        week++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final activeUserTags = cocService.getAccountTags();
    CapitalHistoryItem raid = widget.clanInfo.clanCapitalRaid!.items[week];

    final locale = Localizations.localeOf(context).toString();
    List<ClanMember> nonParticipants = getNonParticipatingMembers(raid);

    bool isOngoing = raid.state == 'ongoing';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  filterBy == "all"
                      ? LucideIcons.list
                      : filterBy == "done"
                      ? LucideIcons.check
                      : LucideIcons.x,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                onPressed: () {
                  setState(() {
                    switch (filterBy) {
                      case "all":
                        filterBy = "done";
                        break;
                      case "done":
                        filterBy = "notDone";
                        break;
                      default:
                        filterBy = "all";
                    }
                  });
                },
                tooltip: 'Filter Remaining Attacks',
              ),
              SizedBox(
                width: 30,
                height: 30,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 16,
                  ),
                  onPressed: decrementRaid,
                ),
              ),
              Text(
                DateFormat(
                  'dd MMMM yyyy',
                  Localizations.localeOf(context).languageCode,
                ).format(raid.startTime),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              SizedBox(
                width: 30,
                height: 30,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_forward,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 16,
                  ),
                  onPressed: incrementRaid,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.link,
                  color: filterAccountActive ? Colors.green : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    filterAccountActive = !filterAccountActive;
                  });
                },
                tooltip: 'Filter Active Users',
              ),
            ],
          ),
        ),
        buildLastRaids(raid, locale, isOngoing),
        if ((filterBy == "all" || filterBy == "done") && week == 0)
          buildLastRaidsMembers(raid, activeUserTags, filterAccountActive),
        if ((filterBy == "all" || filterBy == "notDone") && isOngoing)
          ...buildNonParticipantWidgets(
            nonParticipants,
            activeUserTags,
            filterAccountActive,
          )
        else
          const SizedBox.shrink(),
        const SizedBox(height: 10),
      ],
    );
  }

  List<ClanMember> getNonParticipatingMembers(CapitalHistoryItem firstRaid) {
    List<ClanMember> nonParticipants = [];
    Set<String> raidParticipantTags = widget.clanInfo.clanCapitalRaid!.items
        .expand((item) => item.members!.map((member) => member.tag))
        .toSet();

    for (var member in widget.clanInfo.memberList) {
      if (!raidParticipantTags.contains(member.tag)) {
        nonParticipants.add(member);
      }
    }
    return nonParticipants;
  }

  List<Widget> buildNonParticipantWidgets(
    List<ClanMember> nonParticipants,
    List<String> activeUserTags,
    bool filterAccountActive,
  ) {
    return nonParticipants
        .where(
          (member) =>
              !filterAccountActive || activeUserTags.contains(member.tag),
        )
        .map((member) {
          return Card(
            margin: const EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: 4,
              top: 4,
            ),
            elevation: 4,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(
                    height: 40,
                    width: 40,
                    child: MobileWebImage(
                      imageUrl: ImageAssets.capitalVacantHouse,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          member.tag,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.close, color: Colors.red),
                ],
              ),
            ),
          );
        })
        .toList();
  }

  Widget buildLastRaids(dynamic firstRaid, locale, isOngoing) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Card(
            margin: const EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: 4,
              top: 4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isOngoing
                            ? AppLocalizations.of(context)!.raidsOngoing
                            : AppLocalizations.of(context)!.raidsLast,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 4),
                      isOngoing
                          ? const MobileWebImage(
                              height: 24,
                              width: 24,
                              imageUrl: ImageAssets.swordGif,
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                  Text(
                    "(${DateFormat.yMMMd(locale).format(firstRaid.startTime)} - ${DateFormat.yMMMd(locale).format(firstRaid.endTime)})",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 32,
                                  width: 32,
                                  child: MobileWebImage(
                                    imageUrl: ImageAssets.capitalGold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOngoing
                                      ? AppLocalizations.of(
                                          context,
                                        )!.generalComingSoon
                                      : '${6 * firstRaid.offensiveReward + firstRaid.defensiveReward}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.center,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: MobileWebImage(
                                      imageUrl: ImageAssets.raidAttacks,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    "${NumberFormat(_numberFormat, Localizations.localeOf(context).toString()).format(firstRaid.raidsCompleted)} ${AppLocalizations.of(context)!.raidsCompleted}",
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    NumberFormat(
                                      _numberFormat,
                                      Localizations.localeOf(
                                        context,
                                      ).toString(),
                                    ).format(firstRaid.capitalTotalLoot),
                                  ),
                                  const SizedBox(width: 2),
                                  const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: MobileWebImage(
                                      imageUrl: ImageAssets.capitalGold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  ClipRect(
                                    child: Transform.scale(
                                      scale: 1.3,
                                      child: MobileWebImage(
                                        height: 24,
                                        width: 24,
                                        fit: BoxFit.cover,
                                        imageUrl: ImageAssets.capitalHall(5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    "${firstRaid.enemyDistrictsDestroyed} ${AppLocalizations.of(context)!.raidsDistrictsDestroyed}",
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text("${firstRaid.totalAttacks}"),
                                  const SizedBox(width: 2),
                                  ClipRect(
                                    child: Transform.scale(
                                      scale: 0.8,
                                      child: const MobileWebImage(
                                        height: 24,
                                        width: 24,
                                        fit: BoxFit.cover,
                                        imageUrl:
                                            ImageAssets.capitalThickSwords,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLastRaidsMembers(
    CapitalHistoryItem firstRaid,
    List<String> activeUserTags,
    bool filterAccountActive,
  ) {
    return Column(
      children: [
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Text(
                "${AppLocalizations.of(context)!.clanMembers} (${firstRaid.members?.length ?? 0}/50)",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              ...buildMemberWidgets(
                firstRaid.members ?? [],
                activeUserTags,
                filterAccountActive,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> buildMemberWidgets(
    List<RaidMember> raidMembers,
    List<String> activeUserTags,
    bool filterAccountActive,
  ) {
    raidMembers.sort(
      (a, b) => b.capitalResourcesLooted.compareTo(a.capitalResourcesLooted),
    );

    return raidMembers
        .where(
          (member) =>
              !filterAccountActive || activeUserTags.contains(member.tag),
        )
        .map((member) {
          bool isInDiscord = activeUserTags.contains(member.tag);

          return Card(
            margin: const EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: 4,
              top: 4,
            ),
            elevation: 4,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: isInDiscord ? Colors.green : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(
                    height: 40,
                    width: 40,
                    child: MobileWebImage(
                      imageUrl: ImageAssets.capitalClanHouse,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          member.tag,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${member.attacks}/${member.attackLimit + member.bonusAttackLimit}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        NumberFormat(
                          _numberFormat,
                          Localizations.localeOf(context).toString(),
                        ).format(member.capitalResourcesLooted),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: MobileWebImage(
                          imageUrl: ImageAssets.raidAttacks,
                        ),
                      ),
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: MobileWebImage(
                          imageUrl: ImageAssets.capitalGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        })
        .toList();
  }
}
