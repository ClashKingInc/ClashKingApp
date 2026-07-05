import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/clan_league.dart';
import 'package:clashkingapp/features/clan/models/clan_member.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ClanMembers extends StatefulWidget {
  final Clan clanInfo;

  const ClanMembers({required this.clanInfo, super.key});

  @override
  ClanMembersState createState() => ClanMembersState();
}

class ClanMembersState extends State<ClanMembers> {
  String currentFilter = 'trophies';
  bool isMemberListExpanded = true;

  void updateFilter(String newFilter) {
    setState(() {
      currentFilter = newFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filterOptions = _filterOptions(context);

    final cocService = context.watch<CocAccountService>();
    final activeUserTags = cocService.getAccountTags();

    Map<String, int> roleWeights = {
      'leader': 4,
      'coLeader': 3,
      'admin': 2,
      'member': 1,
    };

    List<ClanMember> members = widget.clanInfo.memberList.toList();
    final townHallCounts = <int, int>{};
    for (final member in members) {
      townHallCounts.update(
        member.townHallLevel,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final townHallBreakdown = townHallCounts.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final leagueCounts = <int, int>{};
    final leaguesById = <int, ClanLeague>{};
    for (final member in members) {
      leagueCounts.update(
        member.league.id,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      leaguesById[member.league.id] = member.league;
    }
    final leagueBreakdown =
        leagueCounts.entries
            .map((entry) => MapEntry(leaguesById[entry.key]!, entry.value))
            .toList()
          ..sort((a, b) => b.key.id.compareTo(a.key.id));

    members.sort((a, b) {
      switch (currentFilter) {
        case 'role':
          return (roleWeights[b.role] ?? 0).compareTo(roleWeights[a.role] ?? 0);
        case 'townHallLevel':
          return b.townHallLevel.compareTo(a.townHallLevel);
        case 'trophies':
          final leagueComparison = b.league.id.compareTo(a.league.id);
          if (leagueComparison != 0) return leagueComparison;
          return b.trophies.compareTo(a.trophies);
        case 'expLevel':
          return b.expLevel.compareTo(a.expLevel);
        case 'builderBaseTrophies':
          return b.builderBaseTrophies.compareTo(a.builderBaseTrophies);
        case 'donations':
          return b.donations.compareTo(a.donations);
        case 'donationsReceived':
          return b.donationsReceived.compareTo(a.donationsReceived);
        case 'donationsRatio':
          double ratioA =
              a.donations /
              (a.donationsReceived == 0 ? 1 : a.donationsReceived);
          double ratioB =
              b.donations /
              (b.donationsReceived == 0 ? 1 : b.donationsReceived);
          return ratioB.compareTo(ratioA);
        default:
          return 0;
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  onTap: () => setState(
                    () => isMemberListExpanded = !isMemberListExpanded,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isMemberListExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        if (!isMemberListExpanded)
                          Flexible(
                            child: Text(
                              'Clan Totals',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isMemberListExpanded) ...[
                const SizedBox(width: 10),
                FilterDropdown(
                  sortBy: currentFilter,
                  updateSortBy: updateFilter,
                  sortByOptions: filterOptions,
                  maxWidth: 176,
                ),
              ],
            ],
          ),
        ),
        if (members.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context)?.accountsNoneFound ??
                    'No account linked to your profile found',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          if (isMemberListExpanded)
            ...members.asMap().entries.map((entry) {
              int index = entry.key + 1;
              ClanMember member = entry.value;

              return GestureDetector(
                onTap: () async {
                  final navigator = Navigator.of(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final Player selectedPlayer = await PlayerService()
                        .getPlayerAndClanData(member.tag);

                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute(
                        builder: (context) =>
                            PlayerScreen(selectedPlayer: selectedPlayer),
                      ),
                    );
                  } catch (e) {
                    // Dismiss loading dialog
                    navigator.pop();

                    // Show error message
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(
                              context,
                            )!.generalRefreshFailed(e.toString()),
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 3,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).cardTheme.color ??
                        Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: activeUserTags.contains(member.tag)
                          ? Colors.green.withValues(alpha: 0.7)
                          : Theme.of(context).colorScheme.outlineVariant
                                .withValues(alpha: 0.32),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 19,
                        child: Text(
                          index.toString(),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      CachedNetworkImage(
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                        imageUrl: ImageAssets.townHall(member.townHallLevel),
                        width: 38,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        member.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        _localizedRole(context, member.role),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _SortValueChip(
                                  member: member,
                                  sortBy: currentFilter,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          if (!isMemberListExpanded)
            _MemberBreakdown(
              townHalls: townHallBreakdown,
              leagues: leagueBreakdown,
            ),
        ],
      ],
    );
  }

  Map<String, String> _filterOptions(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return {
      loc?.gameTrophies ?? 'Trophies': 'trophies',
      loc?.gameTownHallLevel ?? 'Town Hall': 'townHallLevel',
      loc?.generalRole ?? 'Role': 'role',
      loc?.gameDonations ?? 'Donations': 'donations',
      loc?.gameDonationsReceived ?? 'Received': 'donationsReceived',
      loc?.gameDonationsRatio ?? 'Donation Ratio': 'donationsRatio',
      loc?.gameBuilderBaseTrophies ?? 'Builder': 'builderBaseTrophies',
      loc?.gameExpLevel ?? 'XP': 'expLevel',
    };
  }

  String _localizedRole(BuildContext context, String role) {
    final loc = AppLocalizations.of(context)!;
    switch (role) {
      case 'admin':
        return loc.clanRoleElder;
      case 'coLeader':
        return loc.clanRoleCoLeader;
      case 'leader':
        return loc.clanRoleLeader;
      default:
        return loc.clanRoleMember;
    }
  }
}

class _MemberBreakdown extends StatelessWidget {
  final List<MapEntry<int, int>> townHalls;
  final List<MapEntry<ClanLeague, int>> leagues;

  const _MemberBreakdown({required this.townHalls, required this.leagues});

  @override
  Widget build(BuildContext context) {
    if (townHalls.isEmpty && leagues.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                for (final entry in leagues)
                  _BreakdownCount(
                    imageUrl: ImageAssets.getLeagueImage(entry.key.name),
                    count: entry.value,
                  ),
              ],
            ),
            if (townHalls.isNotEmpty && leagues.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.28),
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                for (final entry in townHalls)
                  _BreakdownCount(
                    imageUrl: ImageAssets.townHall(entry.key),
                    count: entry.value,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCount extends StatelessWidget {
  final String imageUrl;
  final int count;

  const _BreakdownCount({required this.imageUrl, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CachedNetworkImage(
          errorWidget: (context, url, error) => const Icon(Icons.error),
          imageUrl: imageUrl,
          width: 24,
          height: 24,
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _SortValueChip extends StatelessWidget {
  final ClanMember member;
  final String sortBy;

  const _SortValueChip({required this.member, required this.sortBy});

  @override
  Widget build(BuildContext context) {
    switch (sortBy) {
      case 'townHallLevel':
        return _MemberMiniStat(
          imageUrl: ImageAssets.getLeagueImage(member.league.name),
          value: member.trophies.toString(),
        );
      case 'role':
        return _MemberMiniStat(
          imageUrl: ImageAssets.getLeagueImage(member.league.name),
          value: member.trophies.toString(),
        );
      case 'expLevel':
        return _MemberMiniStat(
          imageUrl: ImageAssets.xp,
          value: member.expLevel.toString(),
        );
      case 'builderBaseTrophies':
        return _MemberMiniStat(
          imageUrl: ImageAssets.builderBaseTrophy,
          value: member.builderBaseTrophies.toString(),
        );
      case 'donations':
        return _MemberMiniStat(
          icon: LucideIcons.chevronUp,
          value: member.donations.toString(),
          color: Colors.green,
        );
      case 'donationsReceived':
        return _MemberMiniStat(
          icon: LucideIcons.chevronDown,
          value: member.donationsReceived.toString(),
          color: Colors.red,
        );
      case 'donationsRatio':
        final ratio =
            member.donations /
            (member.donationsReceived == 0 ? 1 : member.donationsReceived);
        final display = ratio > 100
            ? ratio.toInt().toString()
            : ratio > 10
            ? ratio.toStringAsFixed(1)
            : ratio.toStringAsFixed(2);
        return _MemberMiniStat(
          icon: LucideIcons.chevronsUpDown,
          value: display,
          color: Colors.blue,
        );
      default:
        return _MemberMiniStat(
          imageUrl: ImageAssets.getLeagueImage(member.league.name),
          value: member.trophies.toString(),
        );
    }
  }
}

class _MemberMiniStat extends StatelessWidget {
  final String? imageUrl;
  final IconData? icon;
  final String value;
  final Color? color;

  const _MemberMiniStat({
    this.imageUrl,
    this.icon,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null)
            CachedNetworkImage(
              errorWidget: (context, url, error) =>
                  Icon(Icons.error, size: 14, color: colorScheme.onSurface),
              imageUrl: imageUrl!,
              width: 18,
              height: 18,
            )
          else
            Icon(icon, size: 18, color: color),
          const SizedBox(width: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
