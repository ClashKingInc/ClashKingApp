import 'package:clashkingapp/core/constants/image_assets.dart';
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

    String getWarStatus() {
      final int warTeamSize = warInfo.teamSize ?? 15;
      final maxPossibleStars = warTeamSize * 3;
      
      // Check for perfect wars
      bool clanHasPerfectWar = clan.stars == maxPossibleStars && clan.destructionPercentage >= (warTeamSize * 100 - 1);
      bool opponentHasPerfectWar = opponent.stars == maxPossibleStars && opponent.destructionPercentage >= (warTeamSize * 100 - 1);
      
      if (opponentHasPerfectWar) {
        return AppLocalizations.of(context)?.warOpponentPerfectWar ?? 'Opponent has a perfect war - victory impossible.';
      }
      
      if (clanHasPerfectWar) {
        return AppLocalizations.of(context)?.warClanPerfectWar ?? 'Perfect war achieved - victory secured!';
      }
      
      if (clan.stars < opponent.stars) {
        final starsNeeded = opponent.stars - clan.stars + 1;
        final maxStarsWeCanGet = maxPossibleStars - clan.stars;
        
        if (starsNeeded > maxStarsWeCanGet) {
          return AppLocalizations.of(context)?.warCannotWinNotEnoughStars ?? 'Cannot win - not enough stars remaining.';
        }
        
        return AppLocalizations.of(context)?.warStarsNeededToTakeTheLead(
              clan.name,
              starsNeeded,
              opponent.stars - clan.stars,
              (opponent.destructionPercentage - clan.destructionPercentage + 0.01).toStringAsFixed(2)
            ) ?? '';
      } else if (clan.stars > opponent.stars) {
        final starsNeeded = clan.stars - opponent.stars + 1;
        final maxStarsOpponentCanGet = maxPossibleStars - opponent.stars;
        
        if (starsNeeded > maxStarsOpponentCanGet) {
          return AppLocalizations.of(context)?.warVictorySecured ?? 'Victory secured - opponent cannot catch up!';
        }
        
        return AppLocalizations.of(context)?.warStarsNeededToTakeTheLead(
              opponent.name,
              starsNeeded,
              clan.stars - opponent.stars,
              (clan.destructionPercentage - opponent.destructionPercentage + 0.01).toStringAsFixed(2)
            ) ?? '';
      } else if (clan.destructionPercentage > opponent.destructionPercentage) {
        return AppLocalizations.of(context)?.warStarsAndPercentNeededToTakeTheLead(
              clan.name,
              (clan.destructionPercentage - opponent.destructionPercentage + 0.01).toStringAsFixed(2),
            ) ?? '';
      } else if (clan.destructionPercentage < opponent.destructionPercentage) {
        final destructionNeeded = opponent.destructionPercentage - clan.destructionPercentage + 0.01;
        final maxDestructionWeCanGet = (warTeamSize * 100.0) - clan.destructionPercentage;
        
        if (destructionNeeded > maxDestructionWeCanGet) {
          return AppLocalizations.of(context)?.warCannotWinNotEnoughDestruction ?? 'Cannot win - not enough destruction possible.';
        }
        
        return AppLocalizations.of(context)?.warStarsAndPercentNeededToTakeTheLead(
              opponent.name,
              destructionNeeded.toStringAsFixed(2),
            ) ?? '';
      } else {
        // Perfect tie - check attack time tiebreaker
        final clanAvgTime = clan.getAverageAttackTime();
        final opponentAvgTime = opponent.getAverageAttackTime();
        
        if (clanAvgTime != null && opponentAvgTime != null) {
          if (clanAvgTime < opponentAvgTime) {
            return AppLocalizations.of(context)?.warTieAttackTimeWin ?? 'Perfect tie! Winning by faster attack time.';
          } else if (clanAvgTime > opponentAvgTime) {
            return AppLocalizations.of(context)?.warTieAttackTimeLoss ?? 'Perfect tie! Losing by slower attack time.';
          } else {
            return AppLocalizations.of(context)?.warPerfectTie ?? 'Perfect tie in all aspects!';
          }
        } else {
          return '${AppLocalizations.of(context)?.warClanDraw ?? 'The two clans are tied'}.';
        }
      }
    }

    // Determine attacks per player based on war type
    // CWL wars have 1 attack per player, regular wars have 2
    // CWL is detected when attacksPerMember is null OR warType contains 'cwl'
    final bool isCwlWar = warInfo.attacksPerMember == null || 
                         warInfo.warType?.toLowerCase().contains('cwl') == true;
    final int attacksPerPlayer = isCwlWar ? 1 : (warInfo.attacksPerMember ?? 2);
    
    DebugUtils.debugInfo("🔍 War type detection: attacksPerMember=${warInfo.attacksPerMember}, warType='${warInfo.warType}', isCwlWar=$isCwlWar, attacksPerPlayer=$attacksPerPlayer");
    final int teamSize = warInfo.teamSize ?? 15;
    final int numberOfAttacks = attacksPerPlayer * teamSize;

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
              imageUrl: ImageAssets.builderBaseStar
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
              imageUrl: ImageAssets.sword,
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
              const SizedBox(height: 20),
              _buildStrategicAnalysis(context),
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

  Widget _buildStrategicAnalysis(BuildContext context) {
    final clan = warInfo.clan!;
    final opponent = warInfo.opponent!;
    final int warTeamSize = warInfo.teamSize ?? 15;
    
    // Detect CWL properly for attack calculation
    final bool isCwlWar = warInfo.attacksPerMember == null || 
                         warInfo.warType?.toLowerCase().contains('cwl') == true;
    final int attacksPerMember = isCwlWar ? 1 : (warInfo.attacksPerMember ?? 2);
    final int totalPossibleAttacks = warTeamSize * attacksPerMember;
    
    final clanRemainingAttacks = totalPossibleAttacks - clan.attacks;
    final opponentRemainingAttacks = totalPossibleAttacks - opponent.attacks;
    
    final clanMaxPossibleStars = clan.stars + (clanRemainingAttacks * 3);
    final opponentMaxPossibleStars = opponent.stars + (opponentRemainingAttacks * 3);
    final clanMaxPossibleDestruction = clan.destructionPercentage + (clanRemainingAttacks * 100);
    final opponentMaxPossibleDestruction = opponent.destructionPercentage + (opponentRemainingAttacks * 100);
    
    // Calculate win probability
    double probability = 50.0;
    
    // Adjust for star difference
    if (clan.stars > opponent.stars) {
      double starAdvantage = (clan.stars - opponent.stars) / ((clan.stars + opponent.stars) / 2);
      probability += starAdvantage * 25;
    } else if (opponent.stars > clan.stars) {
      double starDisadvantage = (opponent.stars - clan.stars) / ((clan.stars + opponent.stars) / 2);
      probability -= starDisadvantage * 25;
    }

    // Adjust for destruction difference
    if (clan.destructionPercentage > opponent.destructionPercentage) {
      double destructionAdvantage = (clan.destructionPercentage - opponent.destructionPercentage) / 
                                   ((clan.destructionPercentage + opponent.destructionPercentage) / 2);
      probability += destructionAdvantage * 15;
    } else if (opponent.destructionPercentage > clan.destructionPercentage) {
      double destructionDisadvantage = (opponent.destructionPercentage - clan.destructionPercentage) / 
                                      ((clan.destructionPercentage + opponent.destructionPercentage) / 2);
      probability -= destructionDisadvantage * 15;
    }

    // Adjust for remaining potential
    double clanPotential = clanMaxPossibleStars + (clanMaxPossibleDestruction / 100);
    double opponentPotential = opponentMaxPossibleStars + (opponentMaxPossibleDestruction / 100);
    
    if (clanPotential > opponentPotential) {
      probability += 10;
    } else if (opponentPotential > clanPotential) {
      probability -= 10;
    }

    probability = probability.clamp(5.0, 95.0);
    
    // Generate strategic insights
    List<String> insights = _generateInsights(clan, opponent, clanRemainingAttacks, opponentRemainingAttacks, warTeamSize, isCwlWar);
    
    Color probabilityColor = probability >= 65 ? Colors.green : 
                            probability >= 35 ? Colors.orange : Colors.red;
    
    return Column(
      children: [
        // Win Probability Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: probabilityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: probabilityColor, width: 1),
          ),
          child: Column(
            children: [
              Text(
                "Win Probability",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: probabilityColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${probability.toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: probabilityColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: probability / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(probabilityColor),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "$clanRemainingAttacks attacks left",
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            Text(
                              "vs ${opponentRemainingAttacks}",
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Strategic Insights Section
        if (insights.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "💡 Strategic Insights",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("• ", style: TextStyle(color: Colors.blue)),
                      Expanded(
                        child: Text(
                          insight,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<String> _generateInsights(dynamic clan, dynamic opponent, int clanRemainingAttacks, int opponentRemainingAttacks, int teamSize, bool isCwlWar) {
    List<String> insights = [];
    
    // Attack timing insights
    if (opponentRemainingAttacks == 0 && clanRemainingAttacks > 0) {
      insights.add('⚡ Opponent has finished - time to capitalize!');
    } else if (clanRemainingAttacks == 0 && opponentRemainingAttacks > 0) {
      insights.add('⏰ You have finished - outcome depends on opponent');
    }

    // Close war insights
    if (clan.stars == opponent.stars && (clan.destructionPercentage - opponent.destructionPercentage).abs() < 5) {
      insights.add('🎯 Very close war - every percentage point matters!');
    }

    // Attack efficiency insights
    if (clanRemainingAttacks > 0) {
      double destructionNeededPerAttack = clanRemainingAttacks > 0 ? 
        (opponent.destructionPercentage - clan.destructionPercentage + 0.01) / clanRemainingAttacks : 0;
      if (destructionNeededPerAttack > 80) {
        insights.add('💪 Need ${destructionNeededPerAttack.toStringAsFixed(0)}% per attack - challenging but possible!');
      } else if (destructionNeededPerAttack > 50) {
        insights.add('🎯 Need ${destructionNeededPerAttack.toStringAsFixed(0)}% per attack - requires good performance');
      }
    }

    // Strategic positioning
    if (clanRemainingAttacks > opponentRemainingAttacks) {
      insights.add('✨ You have more attacks remaining - good position');
    } else if (clanRemainingAttacks < opponentRemainingAttacks && clan.stars >= opponent.stars) {
      insights.add('⚠️ Opponent has more attacks but you\'re ahead - maintain lead');
    }

    // War type specific insights
    if (isCwlWar) {
      insights.add('🏆 CWL War - 1 attack per member, make it count!');
    }

    return insights;
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
