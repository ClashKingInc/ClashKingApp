import 'dart:ui';

import 'package:clashkingapp/common/widgets/buttons/info_button.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';

/// Header of the to-do page: the landscape backdrop fills the whole header
/// and the aggregated stats float over it on a liquid glass panel, so the
/// image shows through the glass.
class PlayerToDoHeader extends StatelessWidget {
  final List<Player> players;
  final Map<String, WarMemberPresence> memberPresenceMap;

  const PlayerToDoHeader({
    super.key,
    required this.players,
    required this.memberPresenceMap,
  });

  static const double _panelHeight = 92;
  // How far the glass strip overlaps past the bottom edge of the image.
  static const double _panelOverlap = 40;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final total = players.length;
    final active = players
        .where((p) => DateTime.now().difference(p.lastOnline).inDays < 14)
        .length;
    final inactive = total - active;

    int totalClanGames = 0;
    final requiredClanGames = players.length * requiredClanGamesPoints;
    int totalSeasonPass = 0;
    final requiredSeasonPass = players.length * requiredSeasonPassPoints;
    int totalLegend = 0;
    int requiredLegend = 0;
    int totalCwl = 0;
    int requiredCwl = 0;
    int totalWar = 0;
    int requiredWar = 0;

    for (final player in players) {
      totalClanGames += player.currentClanGamesPoints;
      totalSeasonPass += player.currentSeasonPoints;

      if (player.league == "Legend League" &&
          player.currentLegendSeason?.currentDay != null) {
        requiredLegend += 8;
        totalLegend += player.currentLegendSeason?.currentDay?.totalAttacks ?? 0;
      }

      if (player.warData != null && player.warData!.state == 'inWar') {
        requiredWar += player.warData!.attacksPerMember ?? 0;
        totalWar +=
            player.warData!.getAttacksDoneByPlayer(player.tag, player.clanTag);
      }

      final warPresence = memberPresenceMap[player.tag];
      if (warPresence != null && warPresence.attacksAvailable > 0) {
        requiredCwl += warPresence.attacksAvailable;
        totalCwl += warPresence.attacksDone;
      }
    }

    final double progressRatio = players.isEmpty
        ? 0
        : players
                .map((p) => p.getTodoProgressRatio(
                    memberCwl:
                        memberPresenceMap[p.tag] ?? WarMemberPresence.empty()))
                .reduce((a, b) => a + b) /
            players.length;

    return Stack(
      children: [
        // Backdrop image: fills the header except the strip's overlap zone,
        // so the glass panel straddles the image/background boundary.
        Positioned.fill(
          bottom: _panelOverlap,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.32),
              BlendMode.darken,
            ),
            child: CachedNetworkImage(
              imageUrl:
                  "https://assets.clashk.ing/landscape/todo-landscape.png",
              fit: BoxFit.cover,
              errorWidget: (context, url, error) =>
                  ColoredBox(color: colorScheme.surface),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: statusBarHeight + 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  _HeaderIconButton(
                    icon: Icons.info_outline,
                    tooltip: loc.todoExplanationTitle,
                    onTap: () => _showExplanation(context, loc),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Hero typography directly on the image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.todoAccountsNumber(total),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${loc.todoAccountsNumberActive(active)} · '
                    '${loc.todoAccountsNumberInactive(inactive)}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Compact liquid glass strip straddling the image edge:
            // chips + overall progress, the image showing through the top.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: _panelHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NativeLiquidGlassBar(
                      height: _panelHeight,
                      cornerRadius: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: <Widget>[
                                if (requiredLegend > 0) ...[
                                  _SummaryChip(
                                    imageUrl:
                                        ImageAssets.legendBlazonNoPadding,
                                    label: '$totalLegend/$requiredLegend',
                                    done: totalLegend >= requiredLegend,
                                  ),
                                  const SizedBox(width: 7),
                                ],
                                if (requiredWar > 0) ...[
                                  _SummaryChip(
                                    imageUrl: ImageAssets.war,
                                    label: '$totalWar/$requiredWar',
                                    done: totalWar >= requiredWar,
                                  ),
                                  const SizedBox(width: 7),
                                ],
                                if (requiredCwl > 0) ...[
                                  _SummaryChip(
                                    imageUrl: ImageAssets.cwlSwordsNoBorder,
                                    label: '$totalCwl/$requiredCwl',
                                    done: totalCwl >= requiredCwl,
                                  ),
                                  const SizedBox(width: 7),
                                ],
                                if (totalClanGames > 0) ...[
                                  _SummaryChip(
                                    imageUrl: ImageAssets.clanGamesMedals,
                                    label:
                                        '$totalClanGames/$requiredClanGames',
                                    done: totalClanGames >= requiredClanGames,
                                  ),
                                  const SizedBox(width: 7),
                                ],
                                _SummaryChip(
                                  imageUrl: ImageAssets.iconGoldPass,
                                  label:
                                      '$totalSeasonPass/$requiredSeasonPass',
                                  done: totalSeasonPass >= requiredSeasonPass,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progressRatio,
                                    minHeight: 8,
                                    backgroundColor: colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.55),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Colors.green),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(progressRatio * 100).toInt()}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showExplanation(BuildContext context, AppLocalizations loc) {
    showInfoPopup(
      context,
      TextSpan(
        style: Theme.of(context)
            .textTheme
            .bodyMedium!
            .copyWith(color: Theme.of(context).colorScheme.onSurface),
        children: [
          TextSpan(text: "${loc.todoExplanationIntro}\n\n"),
          TextSpan(
              text: "${loc.todoExplanationLegendsTitle}\n",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: "${loc.todoExplanationLegends}\n\n"),
          TextSpan(
              text: "${loc.todoExplanationRaidsTitle}\n",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: "${loc.todoExplanationRaids}\n\n"),
          TextSpan(
              text: "${loc.todoExplanationClanWarsTitle}\n",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: "${loc.todoExplanationClanWars}\n\n"),
          TextSpan(
              text: "${loc.todoExplanationCwlTitle}\n",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: "${loc.todoExplanationCwl}\n\n"),
          TextSpan(
              text: "${loc.todoExplanationPassAndGamesTitle}\n",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: "${loc.todoExplanationPassAndGames}\n\n"),
          TextSpan(text: loc.todoExplanationConclusion),
        ],
      ),
      loc.todoExplanationTitle,
    );
  }
}

/// Frosted floating action over the backdrop, same look as the player
/// page header buttons.
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(19),
            child: InkWell(
              borderRadius: BorderRadius.circular(19),
              onTap: onTap,
              child: SizedBox(
                height: 42,
                width: 42,
                child: Icon(icon, size: 25),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Borderless pill chip — green when done, theme primary when pending.
class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.imageUrl,
    required this.label,
    required this.done,
  });

  final String imageUrl;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color =
        done ? Colors.green : Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 16,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                errorWidget: (context, url, error) =>
                    Icon(Icons.help_outline, size: 14, color: color),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
