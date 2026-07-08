import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart'
    show generateStars;
import 'package:clashkingapp/features/war_cwl/models/war_attack.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/widgets/war_attack_details_sheet.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/widgets/war_search_field.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/shapes/left_pointing_triangle.dart';
import 'package:clashkingapp/common/widgets/shapes/right_pointing_triangle.dart';
import 'package:provider/provider.dart';

class WarEventsTab extends StatefulWidget {
  final WarInfo warInfo;

  const WarEventsTab({super.key, required this.warInfo});

  @override
  State<WarEventsTab> createState() => _WarEventsTabState();
}

class _WarEventsTabState extends State<WarEventsTab> {
  String filterOption = 'All';
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

    final searched = _searchQuery.isEmpty
        ? filtered
        : filtered.where((item) => _matchesEvent(item, _searchQuery)).toList();

    searched.sort((a, b) => b.attack.order.compareTo(a.attack.order));
    return searched;
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
          Row(
            children: [
              Expanded(
                child: WarSearchField(
                  controller: _searchController,
                  query: _searchQuery,
                  hintText: loc.playerSearchPlaceholder,
                ),
              ),
              const SizedBox(width: 8),
              FilterDropdown(
                sortBy: filterOption,
                updateSortBy: updateFilterOption,
                maxWidth: 132,
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
            ],
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
                    warInfo: widget.warInfo,
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
  final WarInfo warInfo;

  const _AttackEventRow({
    required this.item,
    required this.isFromClan,
    required this.warInfo,
  });

  @override
  Widget build(BuildContext context) {
    final activeUserTags = context.watch<CocAccountService>().getAccountTags();
    final isActiveUser =
        activeUserTags.contains(item.attacker.tag) ||
        activeUserTags.contains(item.attack.defenderTag);
    final leftMember = isFromClan ? item.attacker : item.defender;
    final rightMember = isFromClan ? item.defender : item.attacker;
    final leftFallback = isFromClan ? null : item.attack.defenderTag;
    final rightFallback = isFromClan ? item.attack.defenderTag : null;
    final arrowColor = isActiveUser
        ? Colors.green.shade500
        : Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3);

    return _WarEventItemCard(
      highlighted: isActiveUser,
      onTap: () => showWarAttackDetailsSheet(
        context,
        attack: item.attack,
        warInfo: warInfo,
      ),
      child: SizedBox(
        height: 58,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OrderColumn(order: item.attack.order),
            Expanded(
              flex: 4,
              child: _ArrowSegment(
                color: isFromClan ? arrowColor : Colors.transparent,
                child: _EventMember(
                  member: leftMember,
                  fallbackTag: leftFallback,
                  onArrow: isFromClan,
                  highlighted: isActiveUser,
                ),
              ),
            ),
            _ArrowJoin(
              color: arrowColor,
              pointsLeft: !isFromClan,
              isPoint: !isFromClan,
            ),
            Expanded(
              flex: 2,
              child: _AttackResult(
                attack: item.attack,
                color: arrowColor,
                highlighted: isActiveUser,
                isFromClan: isFromClan,
              ),
            ),
            _ArrowJoin(
              color: arrowColor,
              pointsLeft: false,
              isPoint: isFromClan,
            ),
            Expanded(
              flex: 4,
              child: _ArrowSegment(
                color: isFromClan ? Colors.transparent : arrowColor,
                child: _EventMember(
                  member: rightMember,
                  fallbackTag: rightFallback,
                  alignRight: true,
                  onArrow: !isFromClan,
                  highlighted: isActiveUser,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowJoin extends StatelessWidget {
  final Color color;
  final bool pointsLeft;
  final bool isPoint;

  const _ArrowJoin({
    required this.color,
    required this.pointsLeft,
    required this.isPoint,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      child: isPoint
          ? LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                return pointsLeft
                    ? LeftPointingTriangle(
                        width: 12,
                        height: height,
                        color: color,
                      )
                    : RightPointingTriangle(
                        width: 12,
                        height: height,
                        color: color,
                      );
              },
            )
          : ColoredBox(color: color),
    );
  }
}

class _ArrowSegment extends StatelessWidget {
  final Color color;
  final Widget child;

  const _ArrowSegment({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: child,
      ),
    );
  }
}

class _WarEventItemCard extends StatelessWidget {
  final Widget child;
  final bool highlighted;
  final VoidCallback? onTap;

  const _WarEventItemCard({
    required this.child,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = highlighted
        ? StatColors.warStarGold.withValues(alpha: 0.48)
        : colorScheme.outlineVariant.withValues(alpha: 0.34);

    return Material(
      color: highlighted
          ? StatColors.warStarGold.withValues(alpha: 0.07)
          : colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        child: child,
      ),
    );
  }
}

class _EventMember extends StatelessWidget {
  final WarMember? member;
  final String? fallbackTag;
  final bool alignRight;
  final bool onArrow;
  final bool highlighted;

  const _EventMember({
    required this.member,
    this.fallbackTag,
    this.alignRight = false,
    this.onArrow = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = member?.name ?? fallbackTag ?? '-';
    final mapPosition = member?.mapPosition;
    final townHall = member?.townhallLevel ?? 1;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryText = onArrow && highlighted
        ? Colors.white
        : colorScheme.onSurface;
    final secondaryText = onArrow && highlighted
        ? Colors.white.withValues(alpha: 0.88)
        : colorScheme.onSurfaceVariant;

    final info = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          mapPosition == null ? '-' : 'N°$mapPosition',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: secondaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignRight ? TextAlign.end : TextAlign.start,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    final townHallImage = MobileWebImage(
      imageUrl: ImageAssets.townHall(townHall),
      width: 36,
      height: 36,
    );

    return SizedBox.expand(
      child: Row(
        mainAxisAlignment: alignRight
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!alignRight) ...[townHallImage, const SizedBox(width: 8)],
          Expanded(child: info),
          if (alignRight) ...[const SizedBox(width: 8), townHallImage],
        ],
      ),
    );
  }
}

class _AttackResult extends StatelessWidget {
  final WarAttack attack;
  final Color color;
  final bool highlighted;
  final bool isFromClan;

  const _AttackResult({
    required this.attack,
    required this.color,
    required this.highlighted,
    required this.isFromClan,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = highlighted
        ? Colors.white
        : Theme.of(context).colorScheme.tertiary;
    final perfectTextColor = isFromClan ? StatColors.win : textColor;

    return ColoredBox(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${attack.destructionPercentage}%',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: attack.destructionPercentage == 100
                    ? perfectTextColor
                    : textColor,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: generateStars(attack.stars, 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderBadge extends StatelessWidget {
  final int order;

  const _OrderBadge({required this.order});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          '#$order',
          maxLines: 1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _OrderColumn extends StatelessWidget {
  final int order;

  const _OrderColumn({required this.order});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.56),
        ),
        child: Center(child: _OrderBadge(order: order)),
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  final String message;

  const _EmptyEvents({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.82,
              child: MobileWebImage(
                imageUrl: ImageAssets.villager,
                height: 132,
                width: 106,
              ),
            ),
            const SizedBox(height: 12),
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

bool _matchesEvent(_WarEventItem item, String query) {
  return _matchesMember(item.attacker, query) ||
      _matchesMember(item.defender, query) ||
      item.attack.defenderTag.toLowerCase().contains(query) ||
      item.attack.attackerTag.toLowerCase().contains(query) ||
      '#${item.attack.order}'.contains(query) ||
      item.attack.order.toString().contains(query) ||
      '${item.attack.stars}'.contains(query) ||
      '${item.attack.destructionPercentage}'.contains(query);
}

bool _matchesMember(WarMember? member, String query) {
  if (member == null) return false;

  return member.name.toLowerCase().contains(query) ||
      member.tag.toLowerCase().contains(query) ||
      '#${member.mapPosition}'.contains(query) ||
      member.mapPosition.toString().contains(query) ||
      'th${member.townhallLevel}'.contains(query) ||
      member.townhallLevel.toString().contains(query);
}
