import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/shapes/left_pointing_triangle.dart';
import 'package:clashkingapp/common/widgets/shapes/right_pointing_triangle.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart'
    show generateStars;
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

class WarEventsTab extends StatefulWidget {
  final WarInfo warInfo;

  const WarEventsTab({super.key, required this.warInfo});

  @override
  State<WarEventsTab> createState() => _WarEventsTabState();
}

class _WarEventsTabState extends State<WarEventsTab> {
  String filterOption = 'All';

  void updateFilterOption(String newOption) {
    setState(() {
      filterOption = newOption;
    });
  }

  List<Map<String, dynamic>> getAttacks() {
    List<Map<String, dynamic>> attacks = [];

    void add(List members, String clanTag, {int? starFilter}) {
      for (var member in members) {
        final filteredAttacks = (member.attacks ?? [])
            .where((a) => starFilter == null || a.stars == starFilter)
            .toList();

        for (var attack in filteredAttacks) {
          attacks.add({
            'attacker': member,
            'attack': attack,
            'clanTag': clanTag,
          });
        }
      }
    }

    if (filterOption == 'All') {
      add(widget.warInfo.clan!.members, widget.warInfo.clan!.tag);
      add(widget.warInfo.opponent!.members, widget.warInfo.opponent!.tag);
    } else if (filterOption == '5') {
      add(widget.warInfo.clan!.members, widget.warInfo.clan!.tag);
    } else if (filterOption == '4') {
      add(widget.warInfo.opponent!.members, widget.warInfo.opponent!.tag);
    } else {
      final starFilter = int.tryParse(filterOption);
      if (starFilter != null) {
        add(widget.warInfo.clan!.members, widget.warInfo.clan!.tag,
            starFilter: starFilter);
        add(widget.warInfo.opponent!.members, widget.warInfo.opponent!.tag,
            starFilter: starFilter);
      }
    }

    attacks.sort((a, b) => b['attack'].order.compareTo(a['attack'].order));
    return attacks;
  }

  Widget buildPlayerInfo(String tag, bool rightAlign) {
    final member = widget.warInfo.getMemberByTag(tag);
    return Row(
      mainAxisAlignment:
          rightAlign ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!rightAlign) const SizedBox(width: 4),
        if (!rightAlign)
          SizedBox(
            width: 40,
            height: 40,
            child: MobileWebImage(
              imageUrl: ImageAssets.townHall(member?.townhallLevel ?? 1),
            ),
          ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment:
                rightAlign ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text("N°${member!.mapPosition}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.tertiary)),
              Text(member.name,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (rightAlign)
          SizedBox(
            width: 40,
            height: 40,
            child: MobileWebImage(
              imageUrl: ImageAssets.townHall(member.townhallLevel),
            ),
          ),
        if (rightAlign) const SizedBox(width: 4),
      ],
    );
  }

  Widget buildEventRow(Map<String, dynamic> item) {
    final attacker = item['attacker'];
    final attack = item['attack'];
    final attackerClanTag = item['clanTag'];
    final cocService = context.watch<CocAccountService>();
    final activeUserTags = cocService.getAccountTags();

    final isAttackerFromClan = attackerClanTag == widget.warInfo.clan!.tag;
    final isActiveUser = activeUserTags.contains(attacker.tag) ||
        activeUserTags.contains(attack.defenderTag);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attacker
            Expanded(
              flex: 4,
              child: Container(
                color: isAttackerFromClan
                    ? isActiveUser
                        ? Colors.green.shade200
                        : Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withValues(alpha: 0.3)
                    : Colors.transparent,
                child: buildPlayerInfo(
                    isAttackerFromClan ? attacker.tag : attack.defenderTag,
                    false),
              ),
            ),
            SizedBox(
              width: 10,
              height: 40,
              child: !isAttackerFromClan
                  ? Center(
                      child: LeftPointingTriangle(
                        width: 10,
                        color: isActiveUser
                            ? Colors.green.shade200
                            : Theme.of(context)
                                .colorScheme
                                .tertiary
                                .withValues(alpha: 0.3),
                      ),
                    )
                  : Container(
                      width: 10,
                      color: isActiveUser
                          ? Colors.green.shade200
                          : Theme.of(context)
                              .colorScheme
                              .tertiary
                              .withValues(alpha: 0.3),
                    ),
            ),

            // Stats
            Expanded(
              flex: 2,
              child: Container(
                color: isActiveUser
                    ? Colors.green.shade200
                    : Theme.of(context)
                        .colorScheme
                        .tertiary
                        .withValues(alpha: 0.3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${attack.destructionPercentage}%',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: attack.destructionPercentage != 100
                                ? Theme.of(context).colorScheme.tertiary
                                : Theme.of(context).colorScheme.primary)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: generateStars(attack.stars, 13),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 10,
              child: isAttackerFromClan
                  ? // Triangle direction
                  SizedBox(
                      width: 14,
                      height: 40,
                      child: isAttackerFromClan
                          ? Center(
                              child: RightPointingTriangle(
                                width: 10,
                                color: isActiveUser
                                    ? Colors.green.shade200
                                    : Theme.of(context)
                                        .colorScheme
                                        .tertiary
                                        .withValues(alpha: 0.3),
                              ),
                            )
                          : const SizedBox(),
                    )
                  : Container(
                      width: 10,
                      color: isActiveUser
                          ? Colors.green.shade200
                          : Theme.of(context)
                              .colorScheme
                              .tertiary
                              .withValues(alpha: 0.3),
                    ),
            ),
            // Defender
            Expanded(
              flex: 4,
              child: Container(
                  color: !isAttackerFromClan
                      ? isActiveUser
                          ? Colors.green.shade200
                          : Theme.of(context)
                              .colorScheme
                              .tertiary
                              .withValues(alpha: 0.3)
                      : Colors.transparent,
                  child: buildPlayerInfo(
                      isAttackerFromClan ? attack.defenderTag : attacker.tag,
                      true)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attacks = getAttacks();

    return Column(
      children: [
        const SizedBox(height: 8),
        FilterDropdown(
          sortBy: filterOption,
          updateSortBy: updateFilterOption,
          sortByOptions: {
            AppLocalizations.of(context)!.all: 'All',
            widget.warInfo.clan!.name: '5',
            widget.warInfo.opponent!.name: '4',
            generateStars(3, 20): '3',
            generateStars(2, 20): '2',
            generateStars(1, 20): '1',
            generateStars(0, 20): '0',
          },
        ),
        const SizedBox(height: 8),
        attacks.isEmpty
            ? Column(
                children: [
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child:
                          Text(AppLocalizations.of(context)!.noDataAvailable),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CachedNetworkImage(
                    imageUrl:
                        'https://assets.clashk.ing/stickers/Villager_HV_Villager_7.png',
                    height: 250,
                    width: 200,
                    errorWidget: (c, u, e) => const Icon(Icons.error),
                  ),
                ],
              )
            : Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: attacks.map(buildEventRow).toList(),
                  ),
                ),
              ),
      ],
    );
  }
}
