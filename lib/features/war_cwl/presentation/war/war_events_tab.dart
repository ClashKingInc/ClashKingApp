import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart'
    show generateStars;
import 'package:clashkingapp/features/war_cwl/models/war_attack.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
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

  List<_WarEventItem> getAttacks() {
    final clan = widget.warInfo.clan;
    final opponent = widget.warInfo.opponent;
    if (clan == null || opponent == null) return const [];

    final attacks = <_WarEventItem>[];

    void add(List<WarMember> members, String clanTag) {
      for (final member in members) {
        for (final attack in member.attacks ?? const <WarAttack>[]) {
          attacks.add(
            _WarEventItem(
              attacker: member,
              defender: widget.warInfo.getMemberByTag(attack.defenderTag),
              attack: attack,
              clanTag: clanTag,
            ),
          );
        }
      }
    }

    add(clan.members, clan.tag);
    add(opponent.members, opponent.tag);

    final filtered = attacks.where((item) {
      if (filterOption == '5') return item.clanTag == clan.tag;
      if (filterOption == '4') return item.clanTag == opponent.tag;
      if (filterOption == 'All') return true;
      final starFilter = int.tryParse(filterOption);
      return starFilter == null || item.attack.stars == starFilter;
    }).toList();

    filtered.sort((a, b) => b.attack.order.compareTo(a.attack.order));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final clan = widget.warInfo.clan;
    final opponent = widget.warInfo.opponent;

    if (clan == null || opponent == null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: _EmptyEvents(message: loc.generalNoDataAvailable),
      );
    }

    final attacks = getAttacks();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          FilterDropdown(
            sortBy: filterOption,
            updateSortBy: updateFilterOption,
            sortByOptions: {
              loc.generalAll: 'All',
              clan.name: '5',
              opponent.name: '4',
              generateStars(3, 20): '3',
              generateStars(2, 20): '2',
              generateStars(1, 20): '1',
              generateStars(0, 20): '0',
            },
          ),
          const SizedBox(height: 10),
          if (attacks.isEmpty)
            _EmptyEvents(message: loc.generalNoDataAvailable)
          else
            Column(
              children: [
                for (var index = 0; index < attacks.length; index++) ...[
                  _AttackEventRow(
                    item: attacks[index],
                    isFromClan: attacks[index].clanTag == clan.tag,
                  ),
                  if (index < attacks.length - 1) const SizedBox(height: 6),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _AttackEventRow extends StatelessWidget {
  final _WarEventItem item;
  final bool isFromClan;

  const _AttackEventRow({required this.item, required this.isFromClan});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final activeUserTags = context.watch<CocAccountService>().getAccountTags();
    final isActiveUser =
        activeUserTags.contains(item.attacker.tag) ||
        activeUserTags.contains(item.attack.defenderTag);

    return _WarEventItemCard(
      child: Column(
        children: [
          Row(
            children: [
              _SourcePill(
                label: isFromClan ? loc.warMyTeam : loc.warEnemiesTeam,
                imageUrl: isFromClan ? ImageAssets.sword : ImageAssets.shield,
                selected: isActiveUser,
              ),
              if (isActiveUser) ...[
                const SizedBox(width: 6),
                _SourcePill(
                  label: loc.authAccountConnectedStatus,
                  imageUrl: ImageAssets.iconTick,
                  selected: true,
                  color: StatColors.win,
                ),
              ],
              const Spacer(),
              _OrderBadge(order: item.attack.order),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _EventMember(member: item.attacker)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _AttackResult(attack: item.attack),
              ),
              Expanded(
                child: _EventMember(
                  member: item.defender,
                  fallbackTag: item.attack.defenderTag,
                  alignRight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WarEventItemCard extends StatelessWidget {
  final Widget child;

  const _WarEventItemCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.34),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: child,
      ),
    );
  }
}

class _EventMember extends StatelessWidget {
  final WarMember? member;
  final String? fallbackTag;
  final bool alignRight;

  const _EventMember({
    required this.member,
    this.fallbackTag,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = member?.name ?? fallbackTag ?? '-';
    final mapPosition = member?.mapPosition;
    final townHall = member?.townhallLevel ?? 1;

    final info = Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          mapPosition == null ? '-' : 'N°$mapPosition',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignRight ? TextAlign.end : TextAlign.start,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );

    final townHallImage = MobileWebImage(
      imageUrl: ImageAssets.townHall(townHall),
      width: 36,
      height: 36,
    );

    return Row(
      mainAxisAlignment: alignRight
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!alignRight) ...[townHallImage, const SizedBox(width: 8)],
        Expanded(child: info),
        if (alignRight) ...[const SizedBox(width: 8), townHallImage],
      ],
    );
  }
}

class _AttackResult extends StatelessWidget {
  final WarAttack attack;

  const _AttackResult({required this.attack});

  @override
  Widget build(BuildContext context) {
    final color = _attackColor(attack.stars);
    return Column(
      children: [
        MobileWebImage(imageUrl: ImageAssets.sword, width: 24, height: 24),
        const SizedBox(height: 3),
        Text(
          '${attack.destructionPercentage}%',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: generateStars(attack.stars, 13),
        ),
      ],
    );
  }
}

class _SourcePill extends StatelessWidget {
  final String label;
  final String imageUrl;
  final bool selected;
  final Color? color;

  const _SourcePill({
    required this.label,
    required this.imageUrl,
    required this.selected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = color ?? (selected ? StatColors.warStarGold : null);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 22,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: MobileWebImage(imageUrl: imageUrl),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: accent ?? colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _OrderBadge extends StatelessWidget {
  final int order;

  const _OrderBadge({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MobileWebImage(imageUrl: ImageAssets.war, width: 18, height: 18),
        const SizedBox(width: 4),
        Text(
          '#$order',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  final String message;

  const _EmptyEvents({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          children: [
            MobileWebImage(
              imageUrl: ImageAssets.villager,
              height: 148,
              width: 118,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarEventItem {
  final WarMember attacker;
  final WarMember? defender;
  final WarAttack attack;
  final String clanTag;

  const _WarEventItem({
    required this.attacker,
    required this.defender,
    required this.attack,
    required this.clanTag,
  });
}

Color _attackColor(int stars) {
  if (stars == 3) return StatColors.win;
  if (stars == 0) return StatColors.loss;
  return StatColors.warStarGold;
}
