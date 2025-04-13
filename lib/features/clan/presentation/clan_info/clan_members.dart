import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/clan_member.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ClanMembers extends StatefulWidget {
  final Clan clanInfo;

  const ClanMembers(
      {required this.clanInfo, super.key});

  @override
  ClanMembersState createState() => ClanMembersState();
}

class ClanMembersState extends State<ClanMembers> {
  String currentFilter = 'trophies';

  void updateFilter(String newFilter) {
    setState(() {
      currentFilter = newFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> filterOptions = {
      AppLocalizations.of(context)?.role ?? 'Role': 'role',
      AppLocalizations.of(context)?.townHallLevel ?? 'Town Hall Level':
          'townHallLevel',
      AppLocalizations.of(context)?.trophies ?? 'Trophies': 'trophies',
      AppLocalizations.of(context)?.expLevel ?? 'Experience Level': 'expLevel',
      AppLocalizations.of(context)?.builderBaseTrophies ??
          'Builder Base Trophies': 'builderBaseTrophies',
      AppLocalizations.of(context)?.donations ?? 'Donations': 'donations',
      AppLocalizations.of(context)?.donationsReceived ?? 'Donations received':
          'donationsReceived',
      AppLocalizations.of(context)?.donationsRatio ?? 'Donation Ratio':
          'donationsRatio',
    };
    
    final cocService = context.watch<CocAccountService>();
    final activeUserTags = cocService.getAccountTags();

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
          return b.donations.compareTo(a.donations);
        case 'donationsReceived':
          return b.donationsReceived.compareTo(a.donationsReceived);
        case 'donationsRatio':
          double ratioA = a.donations /
              (a.donationsReceived == 0 ? 1 : a.donationsReceived);
          double ratioB = b.donations /
              (b.donationsReceived == 0 ? 1 : b.donationsReceived);
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
                        ?.noAccountLinkedToYourProfileFound ??
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

                final Player selectedPlayer =
                    await PlayerService().getPlayerData(member.tag);

                navigator.pop();
                navigator.push(
                  MaterialPageRoute(
                      builder: (context) => PlayerScreen(
                          selectedPlayer: selectedPlayer)),
                );
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
                        child: _buildStatColumn(member),
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

  Widget _buildStatColumn(ClanMember member) {
    switch (currentFilter) {
      case 'expLevel':
        return _iconText(ImageAssets.xp, member.expLevel.toString());
      case 'builderBaseTrophies':
        return _iconText(
            ImageAssets.trophies, member.builderBaseTrophies.toString());
      case 'donations':
        return _iconTextWithIcon(
            LucideIcons.chevronUp, member.donations.toString(), Colors.green);
      case 'donationsReceived':
        return _iconTextWithIcon(LucideIcons.chevronDown,
            member.donationsReceived.toString(), Colors.red);
      case 'donationsRatio':
        double ratio = member.donations /
            (member.donationsReceived == 0 ? 1 : member.donationsReceived);
        String display = ratio > 100
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
        return loc.elder;
      case 'coLeader':
        return loc.coLeader;
      case 'leader':
        return loc.leader;
      default:
        return loc.member;
    }
  }
}
