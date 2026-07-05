import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart'
    show timeLeft;
import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class WarHeader extends StatefulWidget {
  final WarInfo warInfo;
  final int? cwlRoundNumber;

  const WarHeader({super.key, required this.warInfo, this.cwlRoundNumber});

  @override
  State<WarHeader> createState() => _WarHeaderState();
}

class _WarHeaderState extends State<WarHeader> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageHeight = MediaQuery.of(context).padding.top + 500;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: imageHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.50),
                  BlendMode.darken,
                ),
                child: CachedNetworkImage(
                  imageUrl: ImageAssets.warPageBackground,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  errorWidget: (context, url, error) =>
                      ColoredBox(color: Theme.of(context).colorScheme.surface),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.36),
                      Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.64),
                      Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onTap: () => Navigator.of(context).pop(),
                    showBackground: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _WarIdentityPanel(
                warInfo: widget.warInfo,
                cwlRoundNumber: widget.cwlRoundNumber,
                onOpenClan: _openClan,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: _WarHeaderStats(warInfo: widget.warInfo),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openClan(BuildContext context, WarClan clan) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final Clan clanInfo = await ClanService().loadClanData(clan.tag);
    if (!context.mounted) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClanInfoScreen(clanInfo: clanInfo),
      ),
    );
  }
}

class _WarIdentityPanel extends StatelessWidget {
  final WarInfo warInfo;
  final int? cwlRoundNumber;
  final Future<void> Function(BuildContext context, WarClan clan) onOpenClan;

  const _WarIdentityPanel({
    required this.warInfo,
    required this.cwlRoundNumber,
    required this.onOpenClan,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final roundLabel = cwlRoundNumber == null
        ? null
        : '${loc.cwlTitle} - ${loc.cwlRoundNumber(cwlRoundNumber!)}';

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (roundLabel != null) ...[
                  _RoundPill(label: roundLabel),
                  const SizedBox(height: 8),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _WarScoreboardPanel(
                    warInfo: warInfo,
                    onOpenClan: onOpenClan,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WarHeaderStats extends StatelessWidget {
  final WarInfo warInfo;

  const _WarHeaderStats({required this.warInfo});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final teamSize = warInfo.teamSize;
    if (teamSize == null || teamSize == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _WarChipRows(
        children: [
          _WarQuickChip(
            value: '${teamSize}v$teamSize',
            icon: Icons.groups_rounded,
            tooltip: loc.warTeamSize,
          ),
        ],
      ),
    );
  }
}

class _WarScoreboardPanel extends StatelessWidget {
  final WarInfo warInfo;
  final Future<void> Function(BuildContext context, WarClan clan) onOpenClan;

  const _WarScoreboardPanel({required this.warInfo, required this.onOpenClan});

  @override
  Widget build(BuildContext context) {
    final clan = warInfo.clan;
    final opponent = warInfo.opponent;
    final score = '${clan?.stars ?? 0} - ${opponent?.stars ?? 0}';
    final status = _statusLabel(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusPill(label: status),
        const SizedBox(height: 8),
        Center(
          child: timeLeft(
            warInfo,
            context,
            Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _WarBattleSide(
                clan: clan,
                isLeading: _leadingSide == _WarSide.clan,
                onTap: clan == null ? null : () => onOpenClan(context, clan),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _WarScoreCore(score: score),
            ),
            Expanded(
              child: _WarBattleSide(
                clan: opponent,
                isLeading: _leadingSide == _WarSide.opponent,
                onTap: opponent == null
                    ? null
                    : () => onOpenClan(context, opponent),
              ),
            ),
          ],
        ),
      ],
    );
  }

  _WarSide? get _leadingSide {
    final clan = warInfo.clan;
    final opponent = warInfo.opponent;
    if (clan == null || opponent == null) return null;
    if (clan.stars != opponent.stars) {
      return clan.stars > opponent.stars ? _WarSide.clan : _WarSide.opponent;
    }
    if (clan.destructionPercentage == opponent.destructionPercentage) {
      return null;
    }
    return clan.destructionPercentage > opponent.destructionPercentage
        ? _WarSide.clan
        : _WarSide.opponent;
  }

  String _statusLabel(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return switch (warInfo.state) {
      'preparation' || 'preparationDay' => loc.warPreparation,
      'warEnded' => loc.warEnded,
      'inWar' || 'warInWar' => loc.warOngoing,
      _ => loc.warStateOfTheWar,
    };
  }
}

enum _WarSide { clan, opponent }

class _WarBattleSide extends StatelessWidget {
  final WarClan? clan;
  final bool isLeading;
  final VoidCallback? onTap;

  const _WarBattleSide({
    required this.clan,
    required this.isLeading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = isLeading ? StatColors.warStarGold : Colors.white;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: isLeading ? 76 : 70,
          height: isLeading ? 76 : 70,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLeading
                ? StatColors.warStarGold.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.14),
          ),
          child: MobileWebImage(imageUrl: clan?.badgeUrls.large ?? ''),
        ),
        const SizedBox(height: 5),
        Text(
          clan?.name ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: isLeading ? FontWeight.w900 : FontWeight.w700,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MobileWebImage(
              imageUrl: ImageAssets.attackStar,
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${clan?.stars ?? 0}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: content,
      ),
    );
  }
}

class _WarScoreCore extends StatelessWidget {
  final String score;

  const _WarScoreCore({required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MobileWebImage(imageUrl: ImageAssets.war, width: 32, height: 32),
        const SizedBox(height: 6),
        Text(
          score,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _RoundPill extends StatelessWidget {
  final String label;

  const _RoundPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MobileWebImage(
            imageUrl: ImageAssets.cwlSwordsNoBorder,
            width: 19,
            height: 19,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarChipRows extends StatelessWidget {
  final List<_WarQuickChip> children;

  const _WarChipRows({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 7.0;
        final widths = children
            .map((child) => child.estimatedWidth(context))
            .toList(growable: false);
        final rowPlans = _candidatePlans(children.length);

        for (final plan in rowPlans) {
          if (_planFits(plan, widths, spacing, constraints.maxWidth)) {
            return Column(children: _buildRows(plan, spacing));
          }
        }

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: spacing,
          children: children,
        );
      },
    );
  }

  List<List<int>> _candidatePlans(int count) {
    return switch (count) {
      4 => const [
        [4],
        [2, 2],
      ],
      3 => const [
        [3],
      ],
      2 => const [
        [2],
      ],
      _ => [
        [count],
      ],
    };
  }

  bool _planFits(
    List<int> plan,
    List<double> widths,
    double spacing,
    double maxWidth,
  ) {
    var start = 0;
    for (final rowLength in plan) {
      final rowWidth =
          widths.skip(start).take(rowLength).fold<double>(0, (a, b) => a + b) +
          spacing * (rowLength - 1);
      if (rowWidth > maxWidth) return false;
      start += rowLength;
    }
    return start == widths.length;
  }

  List<Widget> _buildRows(List<int> plan, double spacing) {
    final rows = <Widget>[];
    var start = 0;

    for (var i = 0; i < plan.length; i++) {
      final rowLength = plan[i];
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: children.skip(start).take(rowLength).expand((child) sync* {
            if (child != children[start]) {
              yield SizedBox(width: spacing);
            }
            yield child;
          }).toList(),
        ),
      );
      if (i != plan.length - 1) {
        rows.add(SizedBox(height: spacing));
      }
      start += rowLength;
    }

    return rows;
  }
}

class _WarQuickChip extends StatelessWidget {
  final String value;
  final IconData? icon;
  final String? tooltip;

  const _WarQuickChip({required this.value, this.icon, this.tooltip});

  double estimatedWidth(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, height: 1);
    final painter = TextPainter(
      text: TextSpan(text: value, style: textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    return 20 + 19 + 5 + painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = colorScheme.onSurface;

    final chipBody = Container(
      height: 40,
      padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.72),
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 24,
              child: Icon(
                icon ?? Icons.info_rounded,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return chipBody;
    return Tooltip(message: tooltip!, child: chipBody);
  }
}
