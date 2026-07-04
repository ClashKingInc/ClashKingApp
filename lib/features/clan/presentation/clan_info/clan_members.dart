import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
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
  String currentFilter = 'league';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  void updateFilter(String newFilter) {
    setState(() {
      currentFilter = newFilter;
    });
  }

  BookmarkedPlayer _toBookmarkedPlayer(ClanMember member) {
    return BookmarkedPlayer(
      tag: member.tag,
      name: member.name,
      townHallLevel: member.townHallLevel,
      townHallPic: ImageAssets.townHall(member.townHallLevel),
      clanTag: widget.clanInfo.tag,
      clanName: widget.clanInfo.name,
      trophies: member.trophies,
      league: member.league.name,
      leagueUrl: ImageAssets.getLeagueImage(_leagueName(member)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    Map<String, String> filterOptions = {
      loc?.generalRole ?? 'Role': 'role',
      loc?.gameTownHallLevel ?? 'Town Hall Level': 'townHallLevel',
      loc?.gameLeague ?? 'League': 'league',
      loc?.gameTrophies ?? 'Trophies': 'trophies',
      loc?.gameExpLevel ?? 'Experience Level': 'expLevel',
      loc?.gameBuilderBaseTrophies ?? 'Builder Base Trophies':
          'builderBaseTrophies',
      loc?.gameDonations ?? 'Donations': 'donations',
      loc?.gameDonationsReceived ?? 'Donations received': 'donationsReceived',
      loc?.gameDonationsRatio ?? 'Donation Ratio': 'donationsRatio',
    };

    final cocService = context.watch<CocAccountService>();
    final activeUserTags = cocService.getAccountTags();
    final bookmarkService = context.watch<BookmarkService>();

    Map<String, int> roleWeights = {
      'leader': 4,
      'coLeader': 3,
      'admin': 2,
      'member': 1,
    };

    List<ClanMember> members = widget.clanInfo.memberList
        .where(
          (member) =>
              _searchQuery.isEmpty ||
              member.name.toLowerCase().contains(_searchQuery),
        )
        .toList();

    members.sort((a, b) {
      switch (currentFilter) {
        case 'role':
          return (roleWeights[b.role] ?? 0).compareTo(roleWeights[a.role] ?? 0);
        case 'townHallLevel':
          return b.townHallLevel.compareTo(a.townHallLevel);
        case 'league':
          final leagueCompare = b.league.id.compareTo(a.league.id);
          return leagueCompare != 0
              ? leagueCompare
              : b.trophies.compareTo(a.trophies);
        case 'trophies':
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

    // The persistent trophy row already shows trophies+league, so the
    // dynamic stat column would just repeat it for these sorts.
    final dynamicStatDuplicatesTrophyRow =
        currentFilter == 'trophies' ||
        currentFilter == 'townHallLevel' ||
        currentFilter == 'league';

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NativeLiquidGlassBar(
                        height: 44,
                        cornerRadius: 22,
                        borderOpacity:
                            Theme.of(context).brightness == Brightness.dark
                            ? 0.22
                            : 0.30,
                        shadowOpacity:
                            Theme.of(context).brightness == Brightness.dark
                            ? 0.22
                            : 0.08,
                      ),
                      TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              loc?.clanMembersSearchPlaceholder ??
                              'Search members',
                          hintStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                          isDense: true,
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 44,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilterDropdown(
                sortBy: currentFilter,
                updateSortBy: updateFilter,
                maxWidth: 130,
                sortByOptions: filterOptions,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (members.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _searchQuery.isNotEmpty
                    ? (loc?.generalNoFilteredResults ??
                          'No results match your filters')
                    : (loc?.accountsNoneFound ??
                          'No account linked to your profile found'),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...members.asMap().entries.map((entry) {
            int index = entry.key + 1;
            ClanMember member = entry.value;
            final isLinked = activeUserTags.contains(member.tag);
            final isBookmarked = bookmarkService.isPlayerBookmarked(member.tag);

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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).cardTheme.color ??
                      Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLinked
                        ? Colors.green.withValues(alpha: 0.55)
                        : colorScheme.outlineVariant.withValues(alpha: 0.32),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text(
                        index.toString(),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CachedNetworkImage(
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.error),
                                imageUrl: ImageAssets.townHall(
                                  member.townHallLevel,
                                ),
                                width: 40,
                              ),
                              if (isLinked)
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).cardTheme.color ??
                                          colorScheme.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colorScheme.outlineVariant
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(
                                        Icons.link_rounded,
                                        size: 11,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _localizedRole(context, member.role),
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _trophyRow(member),
                          if (!dynamicStatDuplicatesTrophyRow) ...[
                            const SizedBox(height: 2),
                            _buildStatColumn(member),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 20,
                        color: isBookmarked
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      tooltip: isBookmarked
                          ? (loc?.generalRemoveBookmark ?? 'Remove bookmark')
                          : (loc?.generalBookmark ?? 'Bookmark'),
                      onPressed: () {
                        if (isBookmarked) {
                          bookmarkService.removePlayer(member.tag);
                        } else {
                          bookmarkService.addPlayer(
                            _toBookmarkedPlayer(member),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _trophyRow(ClanMember member) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CachedNetworkImage(
          errorWidget: (context, url, error) => Icon(Icons.error),
          imageUrl: ImageAssets.getLeagueImage(_leagueName(member)),
          width: 24,
          height: 24,
        ),
        const SizedBox(width: 5),
        Text(
          member.trophies.toString(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildStatColumn(ClanMember member) {
    switch (currentFilter) {
      case 'expLevel':
        return _iconText(ImageAssets.xp, member.expLevel.toString());
      case 'builderBaseTrophies':
        return _iconText(
          ImageAssets.trophies,
          member.builderBaseTrophies.toString(),
        );
      case 'donations':
        return _iconTextWithIcon(
          LucideIcons.chevronUp,
          member.donations.toString(),
          Colors.green,
        );
      case 'donationsReceived':
        return _iconTextWithIcon(
          LucideIcons.chevronDown,
          member.donationsReceived.toString(),
          Colors.red,
        );
      case 'donationsRatio':
        double ratio =
            member.donations /
            (member.donationsReceived == 0 ? 1 : member.donationsReceived);
        String display = ratio > 100
            ? ratio.toInt().toString()
            : ratio > 10
            ? ratio.toStringAsFixed(1)
            : ratio.toStringAsFixed(2);
        return _iconTextWithIcon(
          LucideIcons.chevronsUpDown,
          display,
          Colors.blue,
        );
      case 'role':
        return _iconTextWithIcon(
          member.role == 'leader'
              ? Icons.star
              : member.role == 'coLeader'
              ? Icons.star_half
              : Icons.person,
          _localizedRole(context, member.role),
          member.role == 'leader'
              ? Colors.yellow
              : member.role == 'coLeader'
              ? Colors.orange
              : Colors.grey,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _iconText(String imageUrl, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CachedNetworkImage(
          errorWidget: (context, url, error) => Icon(Icons.error),
          imageUrl: imageUrl,
          width: 16,
        ),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _iconTextWithIcon(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // The clan member list's own league.iconUrls come straight from the CoC
  // API and don't distinguish Legend League tiers the way the game
  // currently does. ImageAssets.getLeagueImage resolves badges by league
  // name against GameDataService instead, same as the player page — so
  // member badges here need to go through it too rather than the raw URL.
  String _leagueName(ClanMember member) =>
      member.league.name.isEmpty ? 'Unranked' : member.league.name;

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
