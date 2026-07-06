import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart'
    show generateStars;
import 'package:clashkingapp/features/war_cwl/models/war_attack.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart'
    show WarInfo;
import 'package:clashkingapp/features/war_cwl/models/war_member.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class WarTeamTab extends StatelessWidget {
  final WarInfo warInfo;
  final List<WarMember> members;
  final int attacksPerMember;

  const WarTeamTab({
    super.key,
    required this.members,
    required this.attacksPerMember,
    required this.warInfo,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return _TeamEmptyState(
        message: AppLocalizations.of(context)!.generalNoDataAvailable,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < members.length; index++) ...[
          _TeamMemberRow(
            member: members[index],
            attacksPerMember: attacksPerMember,
            warInfo: warInfo,
          ),
          if (index < members.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _TeamMemberRow extends StatelessWidget {
  final WarMember member;
  final int attacksPerMember;
  final WarInfo warInfo;

  const _TeamMemberRow({
    required this.member,
    required this.attacksPerMember,
    required this.warInfo,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final attacks = member.attacks ?? const <WarAttack>[];

    return _WarTeamItemCard(
      child: Column(
        children: [
          Row(
            children: [
              MobileWebImage(
                imageUrl: ImageAssets.townHall(member.townhallLevel),
                width: 44,
                height: 44,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'N°${member.mapPosition}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _CocPill(
                value: '${attacks.length}/$attacksPerMember',
                imageUrl: ImageAssets.sword,
                color: _attackCountColor(attacks.length, attacksPerMember),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InlineWarColumn(
                  title: loc.warAttacksTitle,
                  imageUrl: ImageAssets.sword,
                  children: List.generate(attacksPerMember, (index) {
                    final attack = attacks.length > index
                        ? attacks[index]
                        : null;
                    return _AttackSummaryRow(attack: attack, warInfo: warInfo);
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InlineWarColumn(
                  title: loc.warDefensesTitle,
                  imageUrl: ImageAssets.shieldWithArrow,
                  subtitle: loc.warDefensesBestOutOf(member.opponentAttacks),
                  children: [
                    _DefenseSummaryRow(member: member, warInfo: warInfo),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WarTeamItemCard extends StatelessWidget {
  final Widget child;

  const _WarTeamItemCard({required this.child});

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

class _InlineWarColumn extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String imageUrl;
  final List<Widget> children;

  const _InlineWarColumn({
    required this.title,
    this.subtitle,
    required this.imageUrl,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MobileWebImage(imageUrl: imageUrl, width: 18, height: 18),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                subtitle ?? title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ...children,
      ],
    );
  }
}

class _AttackSummaryRow extends StatelessWidget {
  final WarAttack? attack;
  final WarInfo warInfo;

  const _AttackSummaryRow({required this.attack, required this.warInfo});

  @override
  Widget build(BuildContext context) {
    final attack = this.attack;
    if (attack == null) {
      return _EmptyActionRow(
        label: AppLocalizations.of(context)!.warAttacksNone,
        imageUrl: ImageAssets.brokenSword,
      );
    }

    return _ActionRow(
      townHallLevel: warInfo.getTownhallLevelByTag(attack.defenderTag) ?? 1,
      title:
          '${warInfo.getMapPositionByTag(attack.defenderTag) ?? '-'}'
          '. ${warInfo.getNameByTag(attack.defenderTag) ?? attack.defenderTag}',
      stars: attack.stars,
      destructionPercentage: attack.destructionPercentage,
    );
  }
}

class _DefenseSummaryRow extends StatelessWidget {
  final WarMember member;
  final WarInfo warInfo;

  const _DefenseSummaryRow({required this.member, required this.warInfo});

  @override
  Widget build(BuildContext context) {
    final attack = member.bestOpponentAttack;
    if (attack == null) {
      return _EmptyActionRow(
        label: AppLocalizations.of(context)!.warDefensesNone,
        imageUrl: ImageAssets.shield,
      );
    }

    return _ActionRow(
      townHallLevel: warInfo.getTownhallLevelByTag(attack.attackerTag) ?? 1,
      title:
          '${warInfo.getMapPositionByTag(attack.attackerTag) ?? '-'}'
          '. ${warInfo.getNameByTag(attack.attackerTag) ?? attack.attackerTag}',
      stars: attack.stars,
      destructionPercentage: attack.destructionPercentage,
    );
  }
}

class _ActionRow extends StatelessWidget {
  final int townHallLevel;
  final String title;
  final int stars;
  final int destructionPercentage;

  const _ActionRow({
    required this.townHallLevel,
    required this.title,
    required this.stars,
    required this.destructionPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final color = _attackColor(stars);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          MobileWebImage(
            imageUrl: ImageAssets.townHall(townHallLevel),
            width: 28,
            height: 28,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    ...generateStars(stars, 13),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$destructionPercentage%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyActionRow extends StatelessWidget {
  final String semanticLabel;
  final String imageUrl;

  const _EmptyActionRow({required String label, required this.imageUrl})
    : semanticLabel = label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurfaceVariant.withValues(alpha: 0.56);

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Semantics(
        label: semanticLabel,
        child: Row(
          children: [
            Opacity(
              opacity: 0.42,
              child: MobileWebImage(imageUrl: imageUrl, width: 28, height: 28),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Opacity(
                        opacity: 0.45,
                        child: Row(children: generateStars(0, 13)),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '-%',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: muted,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                        ),
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
  }
}

class _CocPill extends StatelessWidget {
  final String value;
  final String imageUrl;
  final Color color;

  const _CocPill({
    required this.value,
    required this.imageUrl,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MobileWebImage(imageUrl: imageUrl, width: 14, height: 14),
        const SizedBox(width: 5),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _TeamEmptyState extends StatelessWidget {
  final String message;

  const _TeamEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text(message)),
      ),
    );
  }
}

Color _attackColor(int stars) {
  if (stars == 3) return StatColors.win;
  if (stars == 0) return StatColors.loss;
  return StatColors.warStarGold;
}

Color _attackCountColor(int attacks, int attacksPerMember) {
  if (attacks >= attacksPerMember) return StatColors.win;
  if (attacks == 0) return StatColors.loss;
  return StatColors.warStarGold;
}
