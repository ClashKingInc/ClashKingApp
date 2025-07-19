import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/icons/build_stars.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/war_cwl/models/war_attack.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlayerWarAttacksCard extends StatelessWidget {
  final List<PlayerWarStatsData> wars;
  final String type;

  const PlayerWarAttacksCard(
      {super.key, required this.wars, required this.type});

  @override
  Widget build(BuildContext context) {
    if (wars.isEmpty) {
      return _buildEmpty(context);
    }

    List<Map<String, dynamic>> allAttacks = [];

    if (type == "attacks") {
      allAttacks = wars
          .expand(
              (w) => w.memberData.attacks.map((d) => {"defense": d, "war": w}))
          .toList();
    } else {
      allAttacks = wars
          .expand(
              (w) => w.memberData.defenses.map((d) => {"defense": d, "war": w}))
          .toList();
    }

    if (allAttacks.isEmpty) {
      return _buildEmpty(context);
    }

    return Column(
      children: allAttacks.map((defenseData) {
        final defense = defenseData["defense"] as WarAttack;
        final war = defenseData["war"] as PlayerWarStatsData;
        final formattedDate =
            DateFormat.yMd(Localizations.localeOf(context).toString())
                .format(war.warDetails.startTime ?? DateTime.now());

        return _buildEnhancedAttackCard(context, defense, war, formattedDate);
      }).toList(),
    );
  }

  Widget _buildEnhancedAttackCard(BuildContext context, WarAttack attack,
      PlayerWarStatsData war, String formattedDate) {
    final isAttackCard = type == "attacks";
    final targetPlayer = isAttackCard ? attack.defender : attack.attacker;
    final targetPlayerTag = targetPlayer?.tag;

    // Get background colors based on stars only
    final starPerformance = type == "defenses" ? 3.0 - attack.stars : attack.stars;

    Color cardColor;
    Color borderColor;
    Color badgeColor;
    if (starPerformance == 3.0) {
      cardColor = Colors.green.withValues(alpha: 0.1);
      borderColor = Colors.green.withValues(alpha: 0.3);
      badgeColor = Colors.green[600]!;
    } else if (starPerformance == 2.0) {
      cardColor = Colors.orange.withValues(alpha: 0.1);
      borderColor = Colors.orange.withValues(alpha: 0.3);
      badgeColor = Colors.orange[600]!;
    } else if (starPerformance == 1.0) {
      cardColor = Colors.amber.withValues(alpha: 0.1);
      borderColor = Colors.amber.withValues(alpha: 0.3);
      badgeColor = Colors.amber[700]!;
    } else {
      cardColor = Colors.red.withValues(alpha: 0.1);
      borderColor = Colors.red.withValues(alpha: 0.3);
      badgeColor = Colors.red[600]!;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Dismissible(
        key: Key('${attack.order}-${war.warDetails.startTime}'),
        background: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 24,
          ),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(
            Icons.info,
            color: Colors.white,
            size: 24,
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Swipe right - view player profile
            await _viewPlayerProfile(context, targetPlayerTag);
          } else if (direction == DismissDirection.endToStart) {
            // Swipe left - show attack details
            _showAttackDetails(context, attack, war);
          }
          return false; // Don't actually dismiss
        },
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _viewPlayerProfile(context, targetPlayerTag),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Player avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: ImageAssets.townHall(
                          targetPlayer?.townhallLevel ?? 1),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[300],
                        child: const Icon(Icons.castle),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Main content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Player name and position
                        Text(
                          "${targetPlayer?.mapPosition}. ${targetPlayer?.name ?? 'Unknown'}",
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // War date
                        Text(
                          formattedDate,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),

                  // Performance indicator
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            buildStarsIcon(attack.stars.round()),
                            const SizedBox(width: 4),
                            Text(
                              "-"
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${attack.destructionPercentage}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.swipe,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _viewPlayerProfile(
      BuildContext context, String? playerTag) async {
    if (playerTag == null) return;

    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final player = await PlayerService().getPlayerAndClanData(playerTag);
      navigator.pop();
      navigator.push(
        MaterialPageRoute(
          builder: (_) => PlayerScreen(selectedPlayer: player),
        ),
      );
    } catch (e) {
      navigator.pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load player data')),
        );
      }
    }
  }

  void _showAttackDetails(
      BuildContext context, WarAttack attack, PlayerWarStatsData war) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Attack Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // Attack info
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                          'War Type', war.warDetails.warType ?? 'Unknown'),
                      _buildDetailRow('Attack Order', attack.order.toString()),
                      _buildDetailRow('Stars', attack.stars.toString()),
                      _buildDetailRow(
                          'Destruction', '${attack.destructionPercentage}%'),
                      const SizedBox(height: 16),

                      // Attacker info
                      Text(
                        'Attacker',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                          'Name', attack.attacker?.name ?? 'Unknown'),
                      _buildDetailRow(
                          'TH Level',
                          attack.attacker?.townhallLevel.toString() ??
                              'Unknown'),
                      _buildDetailRow('Map Position',
                          attack.attacker?.mapPosition.toString() ?? 'Unknown'),
                      const SizedBox(height: 16),

                      // Defender info
                      Text(
                        'Defender',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                          'Name', attack.defender?.name ?? 'Unknown'),
                      _buildDetailRow(
                          'TH Level',
                          attack.defender?.townhallLevel.toString() ??
                              'Unknown'),
                      _buildDetailRow('Map Position',
                          attack.defender?.mapPosition.toString() ?? 'Unknown'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(AppLocalizations.of(context)?.generalNoDataAvailable ??
              'No data'),
          const SizedBox(height: 16),
          CachedNetworkImage(
            imageUrl:
                'https://assets.clashk.ing/stickers/Villager_HV_Villager_7.png',
            height: 150,
            width: 120,
          )
        ],
      ),
    );
  }
}
