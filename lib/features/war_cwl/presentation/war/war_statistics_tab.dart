import 'package:clashkingapp/features/war_cwl/data/war_functions.dart' show countStars;
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WarStatisticsTab extends StatelessWidget {
  const WarStatisticsTab({
    super.key,
    required this.warInfo,
  });

  final WarInfo warInfo;

  @override
  Widget build(BuildContext context) {
    DebugUtils.debugInfo("war data ${warInfo.clan?.name} ${warInfo.opponent?.name}");
    final clan = warInfo.clan!;
    final opponent = warInfo.opponent!;

    Map<int, int> clanStarCounts = countStars(clan.members);
    Map<int, int> opponentStarCounts = countStars(opponent.members);

    final int attacksPerPlayer = warInfo.attacksPerMember ?? 2;
    final int teamSize = warInfo.teamSize ?? 15;
    final int numberOfAttacks = attacksPerPlayer * teamSize;

    String getWarStatus() {
      // Check if war hasn't started
      if (clan.stars == 0 && opponent.stars == 0 &&
          clan.destructionPercentage == 0.0 && opponent.destructionPercentage == 0.0) {
        return AppLocalizations.of(context)?.warNotStarted ?? 'War hasn\'t started yet';
      }

      // Check if war is finished
      if (warInfo.state == 'warEnded') {
        if (clan.stars > opponent.stars) {
          return AppLocalizations.of(context)?.warWonByStars(clan.name) ?? '${clan.name} won the war!';
        } else if (opponent.stars > clan.stars) {
          return AppLocalizations.of(context)?.warLostByStars(opponent.name) ?? '${opponent.name} won the war';
        } else if (clan.destructionPercentage > opponent.destructionPercentage) {
          return AppLocalizations.of(context)?.warWonByDestruction(clan.name) ?? '${clan.name} won by destruction!';
        } else if (opponent.destructionPercentage > clan.destructionPercentage) {
          return AppLocalizations.of(context)?.warLostByDestruction(opponent.name) ?? '${opponent.name} won by destruction';
        } else {
          return AppLocalizations.of(context)?.warPerfectDraw ?? 'Perfect draw!';
        }
      }

      // Calculate remaining attacks potential
      final clanRemainingAttacks = numberOfAttacks - clan.attacks;
      final opponentRemainingAttacks = numberOfAttacks - opponent.attacks;
      final clanMaxPossibleStars = clan.stars + (clanRemainingAttacks * 3);
      final opponentMaxPossibleStars = opponent.stars + (opponentRemainingAttacks * 3);

      if (clan.stars < opponent.stars) {
        final starsNeeded = opponent.stars - clan.stars + 1;
        final starsToTie = opponent.stars - clan.stars;

        if (starsNeeded > (clanMaxPossibleStars - clan.stars)) {
          // Can't win, check if can tie
          if (starsToTie <= (clanMaxPossibleStars - clan.stars)) {
            return AppLocalizations.of(context)?.warCanTieNeedsStars(clan.name, starsToTie) ?? '${clan.name} can tie but needs $starsToTie stars';
          } else {
            return AppLocalizations.of(context)?.warCannotCatchUp(clan.name) ?? '${clan.name} cannot catch up on stars';
          }
        }

        return AppLocalizations.of(context)?.warStarsNeededToTakeTheLead(
              clan.name,
              starsNeeded,
              starsToTie,
              (opponent.destructionPercentage - clan.destructionPercentage + 0.01).toStringAsFixed(2)
            ) ?? '';

      } else if (clan.stars > opponent.stars) {
        final starsNeeded = clan.stars - opponent.stars + 1;
        final starsToTie = clan.stars - opponent.stars;

        if (starsNeeded > (opponentMaxPossibleStars - opponent.stars)) {
          // Opponent can't win, check if can tie
          if (starsToTie <= (opponentMaxPossibleStars - opponent.stars)) {
            return AppLocalizations.of(context)?.warCanTieNeedsStars(opponent.name, starsToTie) ?? '${opponent.name} can tie but needs $starsToTie stars';
          } else {
            return AppLocalizations.of(context)?.warCannotCatchUp(opponent.name) ?? '${opponent.name} cannot catch up on stars';
          }
        }

        return AppLocalizations.of(context)?.warStarsNeededToTakeTheLead(
              opponent.name,
              starsNeeded,
              starsToTie,
              (clan.destructionPercentage - opponent.destructionPercentage + 0.01).toStringAsFixed(2)
            ) ?? '';

      } else if (clan.destructionPercentage > opponent.destructionPercentage) {
        return AppLocalizations.of(context)?.warStarsAndPercentNeededToTakeTheLead(
              clan.name,
              (clan.destructionPercentage - opponent.destructionPercentage + 0.01).toStringAsFixed(2),
            ) ?? '';
      } else if (clan.destructionPercentage < opponent.destructionPercentage) {
        return AppLocalizations.of(context)?.warStarsAndPercentNeededToTakeTheLead(
              opponent.name,
              (opponent.destructionPercentage - clan.destructionPercentage + 0.01).toStringAsFixed(2),
            ) ?? '';
      } else {
        return AppLocalizations.of(context)?.warClanDraw ?? 'The two clans are tied';
      }
    }

    final double clanStarsPercentage = clan.stars / (teamSize * 3);
    final double opponentStarsPercentage = opponent.stars / (teamSize * 3);
    final double clanAttacksPercentage = clan.attacks / numberOfAttacks;
    final double opponentAttacksPercentage = opponent.attacks / numberOfAttacks;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(AppLocalizations.of(context)?.warStarsTitle ?? 'Stars'),
            const SizedBox(height: 10),
            _buildDoubleProgressBar(
              context,
              value1: clanStarsPercentage,
              value2: opponentStarsPercentage,
              label1: '${clan.stars}/${teamSize * 3}',
              label2: '${opponent.stars}/${teamSize * 3}',
              imageUrl: "https://assets.clashk.ing/icons/Icon_BB_Star.png",
            ),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context)?.warAttacksTitle ?? 'Attacks'),
            const SizedBox(height: 10),
            _buildDoubleProgressBar(
              context,
              value1: clanAttacksPercentage,
              value2: opponentAttacksPercentage,
              label1: '${clan.attacks}/$numberOfAttacks',
              label2: '${opponent.attacks}/$numberOfAttacks',
              imageUrl: "https://assets.clashk.ing/icons/Icon_HV_Sword.png",
            ),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context)?.warDestructionRate ?? 'Destruction rate'),
            const SizedBox(height: 10),
            _buildDoubleProgressBar(
              context,
              value1: clan.destructionPercentage / 100,
              value2: opponent.destructionPercentage / 100,
              label1: '${clan.destructionPercentage.toStringAsFixed(2)}%',
              label2: '${opponent.destructionPercentage.toStringAsFixed(2)}%',
              icon: LucideIcons.percent,
            ),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context)?.warStarsNumber ?? "Number of stars"),
            const SizedBox(height: 10),
            _buildStarsBreakdown(clanStarCounts, opponentStarCounts),
            if (warInfo.state == 'inWar') ...[
              const SizedBox(height: 20),
              Text(AppLocalizations.of(context)?.warStateOfTheWar ?? 'State of the war'),
              const SizedBox(height: 10),
              Text(
                getWarStatus(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDoubleProgressBar(BuildContext context,
      {required double value1,
      required double value2,
      required String label1,
      required String label2,
      String? imageUrl,
      IconData? icon}) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LinearProgressIndicator(
                  value: value1,
                  backgroundColor: Colors.grey[300],
                  color: Colors.blue,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Center(
                  child: Text(label1,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 25,
          child: imageUrl != null
              ? CachedNetworkImage(imageUrl: imageUrl, errorWidget: (c, u, e) => Icon(Icons.error))
              : Icon(icon, size: 25),
        ),
        Expanded(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LinearProgressIndicator(
                  value: value2,
                  backgroundColor: Colors.grey[300],
                  color: Colors.red,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Center(
                  child: Text(label2,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStarsBreakdown(Map<int, int> clan, Map<int, int> opponent) {
    Widget row(int starCount) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('${clan[starCount] ?? 0}'),
            Row(
              children: List.generate(3, (i) {
                final image = i < starCount
                    ? "https://assets.clashk.ing/icons/Icon_BB_Star.png"
                    : "https://assets.clashk.ing/icons/Icon_BB_Empty_Star.png";
                return SizedBox(
                  width: 25,
                  child: CachedNetworkImage(imageUrl: image, errorWidget: (c, u, e) => Icon(Icons.error)),
                );
              }),
            ),
            Text('${opponent[starCount] ?? 0}'),
          ],
        );

    return Column(
      children: [
        row(0),
        const SizedBox(height: 10),
        row(1),
        const SizedBox(height: 10),
        row(2),
        const SizedBox(height: 10),
        row(3),
      ],
    );
  }
}