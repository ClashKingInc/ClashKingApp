import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/search_sort_bar.dart';
import 'package:clashkingapp/common/widgets/summary_chips.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/utils/capital_raid_analytics.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/clan_capital_history.dart';
import 'package:clashkingapp/features/clan/models/clan_member.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Member list for the currently selected raid week: search + sort bar,
/// filter pills and flat member rows (no nested Card), matching the
/// clan detail tabs' shared widgets instead of the page's old hand-rolled
/// elevated Card list.
class CapitalMembersTab extends StatefulWidget {
  final Clan clanInfo;
  final CapitalHistoryItem raid;
  final List<CapitalHistoryItem> allRaids;

  const CapitalMembersTab({
    super.key,
    required this.clanInfo,
    required this.raid,
    required this.allRaids,
  });

  @override
  State<CapitalMembersTab> createState() => _CapitalMembersTabState();
}

class _CapitalMembersTabState extends State<CapitalMembersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'loot';
  String _filter = 'all';
  bool _linkedOnly = false;
  bool _historyMode = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RaidMember> _sortedParticipants() {
    final participants = List<RaidMember>.from(widget.raid.members ?? []);
    participants.sort(
      (a, b) => _sortBy == 'attacks'
          ? b.attacks.compareTo(a.attacks)
          : b.capitalResourcesLooted.compareTo(a.capitalResourcesLooted),
    );
    return participants;
  }

  List<ClanMember> _nonParticipants() {
    final raidedTags = widget.allRaids
        .expand((item) => item.members ?? const [])
        .map((member) => member.tag)
        .toSet();
    return widget.clanInfo.memberList
        .where((member) => !raidedTags.contains(member.tag))
        .toList();
  }

  List<_CapitalMemberHistory> _historyParticipants() {
    final byTag = <String, _CapitalMemberHistoryAccumulator>{};
    for (final raid in widget.allRaids) {
      final members = raid.members ?? const <RaidMember>[];
      if (members.isEmpty) {
        for (final player in CapitalRaidAnalytics.playerAttackStats(
          raid.attackLog ?? const [],
        )) {
          final key = _tagKey(player.tag);
          final acc = byTag.putIfAbsent(
            key,
            () => _CapitalMemberHistoryAccumulator(player.name, player.tag),
          );
          acc.raids += 1;
          acc.attacks += player.attacks;
          acc.attackLogOnlyRaids += 1;
          acc.stars += player.stars;
          acc.destruction += player.destruction;
          acc.perfectHits += player.perfectHits;
        }
        continue;
      }

      for (final member in members) {
        final key = _tagKey(member.tag);
        final acc = byTag.putIfAbsent(
          key,
          () => _CapitalMemberHistoryAccumulator(member.name, member.tag),
        );
        acc.raids += 1;
        acc.attacks += member.attacks;
        acc.attackLimit += member.attackLimit + member.bonusAttackLimit;
        acc.loot += member.capitalResourcesLooted;
      }
    }

    final list = byTag.values
        .map(
          (acc) => _CapitalMemberHistory(
            name: acc.name,
            tag: acc.tag,
            raids: acc.raids,
            attacks: acc.attacks,
            attackLimit: acc.attackLimit,
            loot: acc.loot,
            attackLogOnlyRaids: acc.attackLogOnlyRaids,
            stars: acc.stars,
            destruction: acc.destruction,
            perfectHits: acc.perfectHits,
          ),
        )
        .toList();
    list.sort((a, b) {
      if (_sortBy == 'attacks') return b.attacks.compareTo(a.attacks);
      final lootCompare = b.loot.compareTo(a.loot);
      if (lootCompare != 0) return lootCompare;
      final starCompare = b.stars.compareTo(a.stars);
      if (starCompare != 0) return starCompare;
      return b.avgDestruction.compareTo(a.avgDestruction);
    });
    return list;
  }

  Map<String, ClanMember> _membersByTag() {
    return {
      for (final member in widget.clanInfo.memberList)
        _tagKey(member.tag): member,
    };
  }

  String _tagKey(String tag) => tag.replaceAll('#', '').toUpperCase();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cocService = context.watch<CocAccountService>();
    final activeUserTags = cocService.getAccountTags().map(_tagKey).toSet();
    final isOngoing = widget.raid.state == 'ongoing';
    final membersByTag = _membersByTag();
    final selectedRaidHasMembers = (widget.raid.members ?? const []).isNotEmpty;
    final selectedRaidAttackLogMembers = selectedRaidHasMembers
        ? const <PlayerAttackStat>[]
        : CapitalRaidAnalytics.playerAttackStats(widget.raid.attackLog ?? []);
    final canReconstructSelectedRaid =
        !selectedRaidHasMembers && selectedRaidAttackLogMembers.isNotEmpty;
    final effectiveHistoryMode = _historyMode;

    var participants = _sortedParticipants().where(
      (member) =>
          (_searchQuery.isEmpty ||
              member.name.toLowerCase().contains(_searchQuery)) &&
          (!_linkedOnly || activeUserTags.contains(_tagKey(member.tag))),
    );
    var nonParticipants = isOngoing
        ? _nonParticipants().where(
            (member) =>
                (_searchQuery.isEmpty ||
                    member.name.toLowerCase().contains(_searchQuery)) &&
                (!_linkedOnly || activeUserTags.contains(_tagKey(member.tag))),
          )
        : const Iterable<ClanMember>.empty();
    var historyParticipants = _historyParticipants().where(
      (member) =>
          (_searchQuery.isEmpty ||
              member.name.toLowerCase().contains(_searchQuery)) &&
          (!_linkedOnly || activeUserTags.contains(_tagKey(member.tag))),
    );

    final showParticipants = _filter != 'notAttacked';
    final showNonParticipants = isOngoing && _filter != 'attacked';
    final participantList = showParticipants
        ? participants.toList(growable: false)
        : const <RaidMember>[];
    final nonParticipantList = showNonParticipants
        ? nonParticipants.toList(growable: false)
        : const <ClanMember>[];
    final historyParticipantList = historyParticipants.toList(growable: false);
    final attackLogParticipantList = selectedRaidAttackLogMembers
        .where(
          (member) =>
              (_searchQuery.isEmpty ||
                  member.name.toLowerCase().contains(_searchQuery)) &&
              (!_linkedOnly || activeUserTags.contains(_tagKey(member.tag))),
        )
        .toList(growable: false);
    final isEmpty = effectiveHistoryMode
        ? historyParticipantList.isEmpty
        : selectedRaidHasMembers
        ? participantList.isEmpty && nonParticipantList.isEmpty
        : attackLogParticipantList.isEmpty;

    return Column(
      children: [
        ClanTabSearchSortBar(
          controller: _searchController,
          query: _searchQuery,
          hintText: loc.clanMembersSearchPlaceholder,
          sortBy: _sortBy,
          updateSortBy: (value) => setState(() => _sortBy = value),
          maxSortWidth: 110,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          sortByOptions: {
            loc.capitalRaidLoot: 'loot',
            loc.warAttacksTitle: 'attacks',
          },
        ),
        const SizedBox(height: 8),
        ClanFilterRail(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            ClanFilterChip(
              label: loc.clanCapitalSelectedRaid,
              icon: Icons.calendar_today_rounded,
              selected: !_historyMode,
              onTap: () => setState(() => _historyMode = false),
            ),
            ClanFilterChip(
              label: loc.generalHistory,
              icon: Icons.history_rounded,
              selected: _historyMode,
              onTap: () => setState(() => _historyMode = true),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClanFilterRail(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            if (!effectiveHistoryMode && selectedRaidHasMembers) ...[
              ClanFilterChip(
                label: loc.generalAll,
                icon: Icons.all_inclusive_rounded,
                selected: _filter == 'all',
                onTap: () => setState(() => _filter = 'all'),
              ),
              ClanFilterChip(
                label: loc.capitalRaidFilterAttacked,
                icon: Icons.check_rounded,
                selected: _filter == 'attacked',
                color: StatColors.win,
                onTap: () => setState(() => _filter = 'attacked'),
              ),
              if (isOngoing)
                ClanFilterChip(
                  label: loc.capitalRaidFilterNotAttacked,
                  icon: Icons.close_rounded,
                  selected: _filter == 'notAttacked',
                  color: StatColors.loss,
                  onTap: () => setState(() => _filter = 'notAttacked'),
                ),
            ],
            ClanFilterChip(
              label: loc.capitalRaidFilterLinked,
              icon: Icons.link_rounded,
              selected: _linkedOnly,
              onTap: () => setState(() => _linkedOnly = !_linkedOnly),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!_historyMode && !selectedRaidHasMembers)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _InfoPanel(
              title: canReconstructSelectedRaid
                  ? loc.capitalRaidMembersAttackLogFallback
                  : loc.capitalRaidMembersNoPlayerData,
            ),
          ),
        if (isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _EmptyPanel(
              title:
                  !_historyMode &&
                      !selectedRaidHasMembers &&
                      selectedRaidAttackLogMembers.isEmpty
                  ? loc.capitalRaidMembersNoIndividualData
                  : _searchQuery.isNotEmpty
                  ? (loc.generalNoFilteredResults)
                  : (loc.generalNoDataAvailable),
            ),
          )
        else if (!_historyMode && !selectedRaidHasMembers) ...[
          ...attackLogParticipantList.map(
            (member) => _CapitalAttackLogMemberRow(
              member: member,
              townHallLevel:
                  membersByTag[_tagKey(member.tag)]?.townHallLevel ?? 0,
              isLinked: activeUserTags.contains(_tagKey(member.tag)),
            ),
          ),
        ] else if (effectiveHistoryMode) ...[
          ...historyParticipantList.map(
            (member) => _CapitalMemberHistoryRow(
              member: member,
              townHallLevel:
                  membersByTag[_tagKey(member.tag)]?.townHallLevel ?? 0,
              isLinked: activeUserTags.contains(_tagKey(member.tag)),
            ),
          ),
        ] else ...[
          if (participantList.isNotEmpty)
            ...participantList.map(
              (member) => _CapitalMemberRow(
                name: member.name,
                tag: member.tag,
                townHallLevel:
                    membersByTag[_tagKey(member.tag)]?.townHallLevel ?? 0,
                attacks: member.attacks,
                attackLimit: member.attackLimit + member.bonusAttackLimit,
                loot: member.capitalResourcesLooted,
                isLinked: activeUserTags.contains(_tagKey(member.tag)),
                didNotAttack: false,
              ),
            ),
          if (nonParticipantList.isNotEmpty)
            ...nonParticipantList.map(
              (member) => _CapitalMemberRow(
                name: member.name,
                tag: member.tag,
                townHallLevel: member.townHallLevel,
                attacks: 0,
                attackLimit: 0,
                loot: 0,
                isLinked: activeUserTags.contains(_tagKey(member.tag)),
                didNotAttack: true,
              ),
            ),
        ],
      ],
    );
  }
}

class _CapitalMemberRow extends StatelessWidget {
  final String name;
  final String tag;
  final int townHallLevel;
  final int attacks;
  final int attackLimit;
  final int loot;
  final bool isLinked;
  final bool didNotAttack;

  const _CapitalMemberRow({
    required this.name,
    required this.tag,
    required this.townHallLevel,
    required this.attacks,
    required this.attackLimit,
    required this.loot,
    required this.isLinked,
    required this.didNotAttack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final borderColor = didNotAttack
        ? StatColors.loss.withValues(alpha: 0.65)
        : isLinked
        ? StatColors.win.withValues(alpha: 0.7)
        : colorScheme.outlineVariant.withValues(alpha: AppOpacity.borderStrong);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: MobileWebImage(
              imageUrl: townHallLevel > 0
                  ? ImageAssets.townHall(townHallLevel)
                  : didNotAttack
                  ? ImageAssets.capitalVacantHouse
                  : ImageAssets.capitalClanHouse,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 1),
                Text(
                  townHallLevel > 0 ? 'TH$townHallLevel · $tag' : tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (didNotAttack)
            Icon(Icons.close_rounded, color: StatColors.loss)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$attacks/$attackLimit',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  formatter.format(loot),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CapitalMemberHistoryRow extends StatelessWidget {
  final _CapitalMemberHistory member;
  final int townHallLevel;
  final bool isLinked;

  const _CapitalMemberHistoryRow({
    required this.member,
    required this.townHallLevel,
    required this.isLinked,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final hasLoot = member.hasRealMemberLoot;
    final subtitle = member.attackLimit > 0
        ? '${member.raids} raids · ${member.attacks}/${member.attackLimit} attacks'
        : '${member.raids} raids · ${member.attacks} hits · attack log';
    final borderColor = isLinked
        ? StatColors.win.withValues(alpha: 0.7)
        : colorScheme.outlineVariant.withValues(alpha: AppOpacity.borderStrong);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: MobileWebImage(
              imageUrl: townHallLevel > 0
                  ? ImageAssets.townHall(townHallLevel)
                  : ImageAssets.capitalClanHouse,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle + (townHallLevel > 0 ? ' · TH$townHallLevel' : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hasLoot ? formatter.format(member.loot) : '${member.stars}★',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                hasLoot
                    ? '${formatter.format(member.avgLootPerRaid.round())}/raid'
                    : '${member.avgDestruction.round()}% avg',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapitalAttackLogMemberRow extends StatelessWidget {
  final PlayerAttackStat member;
  final int townHallLevel;
  final bool isLinked;

  const _CapitalAttackLogMemberRow({
    required this.member,
    required this.townHallLevel,
    required this.isLinked,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = isLinked
        ? StatColors.win.withValues(alpha: 0.7)
        : colorScheme.outlineVariant.withValues(alpha: AppOpacity.borderStrong);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: MobileWebImage(
              imageUrl: townHallLevel > 0
                  ? ImageAssets.townHall(townHallLevel)
                  : ImageAssets.capitalClanHouse,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 1),
                Text(
                  '${member.attacks} hits · ${member.avgDestruction.round()}% avg'
                  '${townHallLevel > 0 ? ' · TH$townHallLevel' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${member.stars}★',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${member.perfectHits} perfect',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapitalMemberHistory {
  final String name;
  final String tag;
  final int raids;
  final int attacks;
  final int attackLimit;
  final int loot;
  final int attackLogOnlyRaids;
  final int stars;
  final int destruction;
  final int perfectHits;

  const _CapitalMemberHistory({
    required this.name,
    required this.tag,
    required this.raids,
    required this.attacks,
    required this.attackLimit,
    required this.loot,
    required this.attackLogOnlyRaids,
    required this.stars,
    required this.destruction,
    required this.perfectHits,
  });

  bool get hasRealMemberLoot => loot > 0;

  double get avgLootPerRaid => raids == 0 ? 0 : loot / raids;

  double get avgDestruction => attacks == 0 ? 0 : destruction / attacks;
}

class _CapitalMemberHistoryAccumulator {
  _CapitalMemberHistoryAccumulator(this.name, this.tag);

  final String name;
  final String tag;
  int raids = 0;
  int attacks = 0;
  int attackLimit = 0;
  int loot = 0;
  int attackLogOnlyRaids = 0;
  int stars = 0;
  int destruction = 0;
  int perfectHits = 0;
}

class _EmptyPanel extends StatelessWidget {
  final String title;

  const _EmptyPanel({required this.title});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: title,
      icon: Icons.history_toggle_off_rounded,
      padding: EdgeInsets.zero,
      stickerHeight: 140,
      stickerWidth: 112,
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String title;

  const _InfoPanel({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: AppOpacity.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
