import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart'
    show generateStars;
import 'package:clashkingapp/features/war_cwl/models/war_attack.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

void showWarAttackDetailsSheet(
  BuildContext context, {
  required WarAttack attack,
  required WarInfo warInfo,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        _WarAttackDetailsSheet(attack: attack, warInfo: warInfo),
  );
}

class _WarAttackDetailsSheet extends StatelessWidget {
  final WarAttack attack;
  final WarInfo warInfo;

  const _WarAttackDetailsSheet({required this.attack, required this.warInfo});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final accentColor = _attackAccentColor(attack.stars);
    final attacker = _MemberSnapshot.fromWar(
      warInfo.getMemberByTag(attack.attackerTag),
      mini: attack.attacker,
      fallbackTag: attack.attackerTag,
    );
    final defender = _MemberSnapshot.fromWar(
      warInfo.getMemberByTag(attack.defenderTag),
      mini: attack.defender,
      fallbackTag: attack.defenderTag,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.42,
      maxChildSize: 0.90,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.34),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accentColor.withValues(alpha: 0.18),
                    colorScheme.surface,
                    colorScheme.surface,
                  ],
                  stops: const [0, 0.28, 1],
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  18,
                  10,
                  18,
                  MediaQuery.of(context).padding.bottom + 18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _SheetHandle(),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.warAttacksDetailsTitle,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.05,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _Pill(
                                    icon: Icons.format_list_numbered_rounded,
                                    label: '#${attack.order}',
                                    color: accentColor,
                                  ),
                                  _Pill(
                                    icon: Icons.local_fire_department_rounded,
                                    label:
                                        warInfo.warType ?? loc.generalUnknown,
                                    color: colorScheme.secondary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.surface.withValues(
                              alpha: 0.54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _ResultHero(attack: attack, accentColor: accentColor),
                    const SizedBox(height: 18),
                    _DividerSection(
                      title: loc.warAttacksDetailsAttacker,
                      child: _ParticipantLine(
                        snapshot: attacker,
                        leadingIcon: ImageAssets.sword,
                      ),
                    ),
                    _VersusConnector(color: accentColor),
                    _DividerSection(
                      title: loc.warAttacksDetailsDefender,
                      child: _ParticipantLine(
                        snapshot: defender,
                        leadingIcon: ImageAssets.shieldWithArrow,
                        alignRight: true,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _DividerSection(
                      title: loc.warInformationTitle,
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.star_rounded,
                            label: loc.warStarsTitle,
                            value: attack.stars.toString(),
                            valueColor: accentColor,
                          ),
                          _DetailRow(
                            icon: Icons.percent_rounded,
                            label: loc.warDestructionTitle,
                            value: '${attack.destructionPercentage}%',
                            valueColor: accentColor,
                          ),
                          _DetailRow(
                            icon: Icons.format_list_numbered_rounded,
                            label: loc.warAttacksDetailsAttackOrder,
                            value: '#${attack.order}',
                          ),
                          if (attack.duration != null)
                            _DetailRow(
                              icon: Icons.timer_outlined,
                              label: loc.warAttacksDetailsDuration,
                              value: _formatDuration(attack.duration!),
                            ),
                          _DetailRow(
                            icon: Icons.groups_rounded,
                            label: loc.warTeamSize,
                            value:
                                warInfo.teamSize?.toString() ??
                                loc.generalUnknown,
                          ),
                          _DetailRow(
                            icon: Icons.sports_martial_arts_rounded,
                            label: loc.warDataAttacksPerMember,
                            value: warInfo.effectiveAttacksPerMember.toString(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResultHero extends StatelessWidget {
  final WarAttack attack;
  final Color accentColor;

  const _ResultHero({required this.attack, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          '${attack.destructionPercentage}%',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: attack.destructionPercentage == 100
                ? StatColors.win
                : colorScheme.onSurface,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: generateStars(attack.stars, 28),
        ),
        const SizedBox(height: 10),
        Container(
          height: 4,
          width: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: accentColor.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}

class _DividerSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DividerSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.30),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ParticipantLine extends StatelessWidget {
  final _MemberSnapshot snapshot;
  final String leadingIcon;
  final bool alignRight;

  const _ParticipantLine({
    required this.snapshot,
    required this.leadingIcon,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColumn = Expanded(
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            snapshot.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignRight ? TextAlign.end : TextAlign.start,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            snapshot.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignRight ? TextAlign.end : TextAlign.start,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    final th = MobileWebImage(
      imageUrl: ImageAssets.townHall(snapshot.townHallLevel),
      width: 44,
      height: 44,
    );
    final role = MobileWebImage(imageUrl: leadingIcon, width: 20, height: 20);

    return Row(
      children: alignRight
          ? [
              role,
              const SizedBox(width: 10),
              textColumn,
              const SizedBox(width: 10),
              th,
            ]
          : [
              th,
              const SizedBox(width: 10),
              textColumn,
              const SizedBox(width: 10),
              role,
            ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 16, color: colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.42,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _VersusConnector extends StatelessWidget {
  final Color color;

  const _VersusConnector({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(height: 1, color: color.withValues(alpha: 0.32)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.keyboard_arrow_down_rounded, color: color),
          ),
          Expanded(
            child: Divider(height: 1, color: color.withValues(alpha: 0.32)),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _MemberSnapshot {
  final String tag;
  final String name;
  final int townHallLevel;
  final int? mapPosition;

  const _MemberSnapshot({
    required this.tag,
    required this.name,
    required this.townHallLevel,
    this.mapPosition,
  });

  String get subtitle {
    final map = mapPosition == null || mapPosition == 0
        ? null
        : 'N°$mapPosition';
    return [?map, tag].join(' · ');
  }

  factory _MemberSnapshot.fromWar(
    WarMember? member, {
    MiniMember? mini,
    required String fallbackTag,
  }) {
    return _MemberSnapshot(
      tag: member?.tag ?? mini?.tag ?? fallbackTag,
      name: member?.name ?? mini?.name ?? fallbackTag,
      townHallLevel: member?.townhallLevel ?? mini?.townhallLevel ?? 1,
      mapPosition: member?.mapPosition ?? mini?.mapPosition,
    );
  }
}

Color _attackAccentColor(int stars) {
  if (stars == 3) return StatColors.win;
  if (stars == 0) return StatColors.loss;
  return StatColors.warStarGold;
}

String _formatDuration(int seconds) {
  if (seconds <= 0) return '0s';
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  if (minutes <= 0) return '${remainingSeconds}s';
  return '${minutes}m ${remainingSeconds.toString().padLeft(2, '0')}s';
}
