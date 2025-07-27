import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/icons/build_stars.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/war_cwl/models/war_attack.dart';
import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
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
                          "${targetPlayer?.mapPosition}. ${targetPlayer?.name ?? AppLocalizations.of(context)!.warAttacksDetailsUnknown}",
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
          SnackBar(content: Text(AppLocalizations.of(context)!.warAttacksFailedToLoadPlayer)),
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
                AppLocalizations.of(context)!.warAttacksDetailsTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // Attack info with user-friendly cards
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Attack Performance Card
                      _buildInfoCard(
                        context,
                        title: AppLocalizations.of(context)!.warAttacksDetailsTitle,
                        icon: Icons.military_tech,
                        children: [
                          _buildIconValueRow(context, Icons.star, AppLocalizations.of(context)!.warAttacksDetailsStars, attack.stars.toString()),
                          _buildIconValueRow(context, Icons.percent, AppLocalizations.of(context)!.warAttacksDetailsDestruction, '${attack.destructionPercentage}%'),
                          _buildIconValueRow(context, Icons.format_list_numbered, AppLocalizations.of(context)!.warAttacksDetailsAttackOrder, attack.order.toString()),
                          _buildIconValueRow(context, Icons.sports_esports, AppLocalizations.of(context)!.warAttacksDetailsWarType, war.warDetails.warType ?? AppLocalizations.of(context)!.warAttacksDetailsUnknown),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // War Information Card
                      _buildInfoCard(
                        context,
                        title: AppLocalizations.of(context)!.warInformationTitle,
                        icon: Icons.info,
                        children: [
                          _buildIconValueRow(context, _getWarStateIcon(war.warDetails.state), AppLocalizations.of(context)!.warDataState, _getWarStateDisplay(context, war.warDetails.state)),
                          _buildIconValueRow(context, Icons.group, AppLocalizations.of(context)!.warDataTeamSize, war.warDetails.teamSize?.toString() ?? AppLocalizations.of(context)!.warAttacksDetailsUnknown),
                          _buildIconValueRow(context, Icons.local_fire_department, AppLocalizations.of(context)!.warDataAttacksPerMember, war.warDetails.attacksPerMember?.toString() ?? AppLocalizations.of(context)!.warAttacksDetailsUnknown),
                          if (war.warDetails.startTime != null)
                            _buildIconValueRow(context, Icons.schedule, AppLocalizations.of(context)!.warDataStartTime, DateFormat.yMd(Localizations.localeOf(context).toString()).add_Hm().format(war.warDetails.startTime!)),
                          if (war.warDetails.endTime != null)
                            _buildIconValueRow(context, Icons.flag, AppLocalizations.of(context)!.warDataEndTime, DateFormat.yMd(Localizations.localeOf(context).toString()).add_Hm().format(war.warDetails.endTime!)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Clan vs Opponent Section
                      if (war.warDetails.clan != null && war.warDetails.opponent != null) ...[
                        _buildClanVsOpponentCard(context, war.warDetails.clan!, war.warDetails.opponent!),
                        const SizedBox(height: 16),
                      ],

                      // Players Card
                      _buildPlayersCard(context, attack),
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

  // Helper method to get appropriate icon for war state
  IconData _getWarStateIcon(String state) {
    switch (state.toLowerCase()) {
      case 'warended':
        return Icons.check_circle;
      case 'inwar':
        return Icons.local_fire_department;
      case 'preparation':
        return Icons.hourglass_top;
      default:
        return Icons.help_outline;
    }
  }

  String _getWarStateDisplay(BuildContext context, String state) {
    switch (state.toLowerCase()) {
      case 'warended':
        return AppLocalizations.of(context)!.warDataStateWarEnded;
      case 'inwar':
        return AppLocalizations.of(context)!.warDataStateInWar;
      case 'preparation':
        return AppLocalizations.of(context)!.warDataStatePreparation;
      default:
        return state;
    }
  }

  // New user-friendly card builder
  Widget _buildInfoCard(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Card content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // Icon-value row builder
  Widget _buildIconValueRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced clan vs opponent card
  Widget _buildClanVsOpponentCard(BuildContext context, WarClan clan, WarClan opponent) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.warResultsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Clan names
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        clan.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        opponent.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Stats comparison
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildClanStatItem(context, Icons.emoji_events, AppLocalizations.of(context)!.warDataClanLevel, clan.clanLevel.toString()),
                          _buildClanStatItem(context, Icons.star, AppLocalizations.of(context)!.warDataTotalStars, clan.stars.toString()),
                          _buildClanStatItem(context, Icons.local_fire_department, AppLocalizations.of(context)!.warDataAttacks, clan.attacks.toString()),
                          _buildClanStatItem(context, Icons.percent, AppLocalizations.of(context)!.warDataDestructionPercentage, '${clan.destructionPercentage.toStringAsFixed(1)}%'),
                        ],
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                            Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                            Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _buildClanStatItem(context, Icons.emoji_events, AppLocalizations.of(context)!.warDataClanLevel, opponent.clanLevel.toString()),
                          _buildClanStatItem(context, Icons.star, AppLocalizations.of(context)!.warDataTotalStars, opponent.stars.toString()),
                          _buildClanStatItem(context, Icons.local_fire_department, AppLocalizations.of(context)!.warDataAttacks, opponent.attacks.toString()),
                          _buildClanStatItem(context, Icons.percent, AppLocalizations.of(context)!.warDataDestructionPercentage, '${opponent.destructionPercentage.toStringAsFixed(1)}%'),
                        ],
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

  Widget _buildClanStatItem(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // Players card combining attacker and defender
  Widget _buildPlayersCard(BuildContext context, WarAttack attack) {
    return _buildInfoCard(
      context,
      title: AppLocalizations.of(context)!.warPlayersTitle,
      icon: Icons.people,
      children: [
        // Attacker section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 18,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.warAttacksDetailsAttacker,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildPlayerInfo(context, attack.attacker),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Defender section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shield,
                    size: 18,
                    color: Colors.red[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.warAttacksDetailsDefender,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildPlayerInfo(context, attack.defender),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerInfo(BuildContext context, dynamic player) {
    return Column(
      children: [
        _buildPlayerInfoRow(context, Icons.person, AppLocalizations.of(context)!.warAttacksDetailsName, player?.name ?? AppLocalizations.of(context)!.warAttacksDetailsUnknown),
        _buildPlayerInfoRow(context, Icons.home, AppLocalizations.of(context)!.warAttacksDetailsTHLevel, player?.townhallLevel?.toString() ?? AppLocalizations.of(context)!.warAttacksDetailsUnknown),
        _buildPlayerInfoRow(context, Icons.location_on, AppLocalizations.of(context)!.warAttacksDetailsMapPosition, player?.mapPosition?.toString() ?? AppLocalizations.of(context)!.warAttacksDetailsUnknown),
      ],
    );
  }

  Widget _buildPlayerInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
