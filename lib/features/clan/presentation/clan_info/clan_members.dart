import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/clan_member.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

List<String> _recentSeasons({int count = 12}) {
  final now = DateTime.now().toUtc();
  return List.generate(count, (i) {
    final dt = DateTime(now.year, now.month - i, 1);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
  });
}

class ClanMembers extends StatefulWidget {
  final Clan clanInfo;

  const ClanMembers(
      {required this.clanInfo, super.key});

  @override
  ClanMembersState createState() => ClanMembersState();
}

const _donationFilters = {'donations', 'donationsReceived', 'donationsRatio'};

class ClanMembersState extends State<ClanMembers> {
  String currentFilter = 'trophies';
  String? _selectedSeason;

  void updateFilter(String newFilter) {
    setState(() {
      currentFilter = newFilter;
      if (!_donationFilters.contains(newFilter)) _selectedSeason = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> filterOptions = {
      AppLocalizations.of(context)?.generalRole ?? 'Role': 'role',
      AppLocalizations.of(context)?.gameTownHallLevel ?? 'Town Hall Level':
          'townHallLevel',
      AppLocalizations.of(context)?.gameTrophies ?? 'Trophies': 'trophies',
      AppLocalizations.of(context)?.gameExpLevel ?? 'Experience Level': 'expLevel',
      AppLocalizations.of(context)?.gameBuilderBaseTrophies ??
          'Builder Base Trophies': 'builderBaseTrophies',
      AppLocalizations.of(context)?.gameDonations ?? 'Donations': 'donations',
      AppLocalizations.of(context)?.gameDonationsReceived ?? 'Donations received':
          'donationsReceived',
      AppLocalizations.of(context)?.gameDonationsRatio ?? 'Donation Ratio':
          'donationsRatio',
    };
    
    final cocService = context.watch<CocAccountService>();
    final activeUserTags = cocService.getAccountTags();
    final clanService = context.watch<ClanService>();
    final seasonalData = _selectedSeason != null
        ? clanService.getSeasonalDonations(widget.clanInfo.tag, _selectedSeason!)
        : null;

    // Build a lookup map from tag → {donated, received} for seasonal data
    final Map<String, ({int donated, int received})> seasonLookup = {};
    if (seasonalData != null) {
      for (final item in seasonalData) {
        final tag = item['tag'] as String? ?? '';
        seasonLookup[tag] = (
          donated: (item['donated'] as num? ?? 0).toInt(),
          received: (item['received'] as num? ?? 0).toInt(),
        );
      }
    }

    int getDonated(ClanMember m) =>
        seasonLookup[m.tag]?.donated ?? m.donations;
    int getReceived(ClanMember m) =>
        seasonLookup[m.tag]?.received ?? m.donationsReceived;

    Map<String, int> roleWeights = {
      'leader': 4,
      'coLeader': 3,
      'admin': 2,
      'member': 1,
    };

    List<ClanMember> members = widget.clanInfo.memberList.toList();

    members.sort((a, b) {
      switch (currentFilter) {
        case 'role':
          return (roleWeights[b.role] ?? 0).compareTo(roleWeights[a.role] ?? 0);
        case 'townHallLevel':
          return b.townHallLevel.compareTo(a.townHallLevel);
        case 'trophies':
          return b.trophies.compareTo(a.trophies);
        case 'expLevel':
          return b.expLevel.compareTo(a.expLevel);
        case 'builderBaseTrophies':
          return b.builderBaseTrophies.compareTo(a.builderBaseTrophies);
        case 'donations':
          return getDonated(b).compareTo(getDonated(a));
        case 'donationsReceived':
          return getReceived(b).compareTo(getReceived(a));
        case 'donationsRatio':
          final dA = getDonated(a);
          final rA = getReceived(a);
          final dB = getDonated(b);
          final rB = getReceived(b);
          double ratioA = dA / (rA == 0 ? 1 : rA);
          double ratioB = dB / (rB == 0 ? 1 : rB);
          return ratioB.compareTo(ratioA);
        default:
          return 0;
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Center(
          child: Column(
            children: [
              FilterDropdown(
                sortBy: currentFilter,
                updateSortBy: updateFilter,
                sortByOptions: filterOptions,
              ),
              if (_donationFilters.contains(currentFilter)) ...[
                const SizedBox(height: 4),
                _SeasonSelector(
                  clanTag: widget.clanInfo.tag,
                  selectedSeason: _selectedSeason,
                  onSeasonChanged: (season) {
                    setState(() => _selectedSeason = season);
                    if (season != null) {
                      context
                          .read<ClanService>()
                          .fetchDonationsBySeason(widget.clanInfo.tag, season);
                    }
                  },
                ),
              ],
              const SizedBox(height: 6),
            ],
          ),
        ),
        if (members.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context)
                        ?.accountsNoneFound ??
                    'No account linked to your profile found',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
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
                  final Player selectedPlayer =
                      await PlayerService().getPlayerAndClanData(member.tag);

                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute(
                        builder: (context) => PlayerScreen(
                            selectedPlayer: selectedPlayer)),
                  );
                } catch (e) {
                  // Dismiss loading dialog
                  navigator.pop();
                  
                  // Show error message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!
                            .generalRefreshFailed(e.toString())),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: BorderSide(
                    color: activeUserTags.contains(member.tag)
                        ? Colors.green
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(index.toString(),
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      Expanded(
                        flex: 6,
                        child: Row(
                          children: [
                            CachedNetworkImage(
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                              imageUrl:
                                  ImageAssets.townHall(member.townHallLevel),
                              width: 40,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(member.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                    _localizedRole(context, member.role),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: _buildStatColumn(member, getDonated, getReceived),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStatColumn(
    ClanMember member,
    int Function(ClanMember) getDonated,
    int Function(ClanMember) getReceived,
  ) {
    switch (currentFilter) {
      case 'expLevel':
        return _iconText(ImageAssets.xp, member.expLevel.toString());
      case 'builderBaseTrophies':
        return _iconText(
            ImageAssets.trophies, member.builderBaseTrophies.toString());
      case 'donations':
        return _iconTextWithIcon(
            LucideIcons.chevronUp, getDonated(member).toString(), Colors.green);
      case 'donationsReceived':
        return _iconTextWithIcon(LucideIcons.chevronDown,
            getReceived(member).toString(), Colors.red);
      case 'donationsRatio':
        final donated = getDonated(member);
        final received = getReceived(member);
        double ratio = donated / (received == 0 ? 1 : received);
        final display = ratio > 100
            ? ratio.toInt().toString()
            : ratio > 10
                ? ratio.toStringAsFixed(1)
                : ratio.toStringAsFixed(2);
        return _iconTextWithIcon(
            LucideIcons.chevronsUpDown, display, Colors.blue);
      case 'trophies':
        return _iconText(ImageAssets.trophies, member.trophies.toString());
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
      case 'townHallLevel':
        return _iconText(
            member.league.tinyIconUrl ?? "", member.trophies.toString());
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _iconText(String imageUrl, String text) {
    return Row(
      children: [
        const SizedBox(width: 20),
        CachedNetworkImage(
            errorWidget: (context, url, error) => Icon(Icons.error),
            imageUrl: imageUrl,
            width: 24),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _iconTextWithIcon(IconData icon, String text, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(width: 20),
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
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

class _SeasonSelector extends StatelessWidget {
  final String clanTag;
  final String? selectedSeason;
  final void Function(String?) onSeasonChanged;

  const _SeasonSelector({
    required this.clanTag,
    required this.selectedSeason,
    required this.onSeasonChanged,
  });

  @override
  Widget build(BuildContext context) {
    final seasons = _recentSeasons();
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: seasons.length + 1,
        separatorBuilder: (context, i) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          if (i == 0) {
            final isCurrent = selectedSeason == null;
            return ChoiceChip(
              label: const Text('Current'),
              selected: isCurrent,
              onSelected: (_) => onSeasonChanged(null),
              labelStyle: TextStyle(
                fontSize: 11,
                color: isCurrent
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            );
          }
          final season = seasons[i - 1];
          final parts = season.split('-');
          final label = parts.length == 2
              ? DateFormat('MMM yy').format(DateTime(int.parse(parts[0]), int.parse(parts[1])))
              : season;
          final isSelected = selectedSeason == season;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onSeasonChanged(isSelected ? null : season),
            labelStyle: TextStyle(
              fontSize: 11,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          );
        },
      ),
    );
  }
}
