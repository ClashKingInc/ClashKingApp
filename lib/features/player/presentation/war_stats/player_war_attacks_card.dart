import 'dart:async';

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

class PlayerWarAttacksCard extends StatefulWidget {
  final List<PlayerWarStatsData> wars;
  final String type;

  const PlayerWarAttacksCard({
    super.key,
    required this.wars,
    required this.type,
  });

  @override
  State<PlayerWarAttacksCard> createState() => _PlayerWarAttacksCardState();
}

class _PlayerWarAttacksCardState extends State<PlayerWarAttacksCard> {
  static const int _initialVisibleEntries = 25;
  static const int _entriesPerFrame = 12;
  static const Duration _progressiveRenderDelay = Duration(milliseconds: 80);

  final List<_WarAttackEntry> _entries = [];
  Timer? _progressiveRenderTimer;
  int _visibleEntryCount = 0;
  int _dataSignature = 0;

  @override
  void initState() {
    super.initState();
    _refreshEntries();
  }

  @override
  void didUpdateWidget(covariant PlayerWarAttacksCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSignature = _buildDataSignature();
    if (nextSignature != _dataSignature) {
      _refreshEntries(signature: nextSignature);
    }
  }

  @override
  void dispose() {
    _progressiveRenderTimer?.cancel();
    super.dispose();
  }

  void _refreshEntries({int? signature}) {
    _progressiveRenderTimer?.cancel();
    _dataSignature = signature ?? _buildDataSignature();
    _entries
      ..clear()
      ..addAll(_buildEntries());
    _visibleEntryCount = _entries.length < _initialVisibleEntries
        ? _entries.length
        : _initialVisibleEntries;
    _startProgressiveRender();
  }

  List<_WarAttackEntry> _buildEntries() {
    final entries = <_WarAttackEntry>[];
    for (final war in widget.wars) {
      final attacks = widget.type == "attacks"
          ? war.memberData.attacks
          : war.memberData.defenses;
      for (final attack in attacks) {
        entries.add(_WarAttackEntry(war: war, attack: attack));
      }
    }
    return entries;
  }

  int _buildDataSignature() {
    return Object.hash(
      widget.type,
      Object.hashAll(
        widget.wars.map((war) {
          final entries = widget.type == "attacks"
              ? war.memberData.attacks
              : war.memberData.defenses;
          return Object.hash(
            war.warDetails.startTime?.millisecondsSinceEpoch,
            war.warDetails.warType,
            war.warDetails.state,
            entries.length,
          );
        }),
      ),
    );
  }

  void _startProgressiveRender() {
    if (_visibleEntryCount >= _entries.length) return;

    _progressiveRenderTimer = Timer.periodic(_progressiveRenderDelay, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_visibleEntryCount >= _entries.length) {
        timer.cancel();
        return;
      }

      setState(() {
        final nextCount = _visibleEntryCount + _entriesPerFrame;
        _visibleEntryCount = nextCount > _entries.length
            ? _entries.length
            : nextCount;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.wars.isEmpty) {
      return _buildEmpty(context);
    }

    if (_entries.isEmpty) {
      return _buildEmpty(context);
    }

    return Column(
      children: _entries
          .take(_visibleEntryCount)
          .map(
            (entry) =>
                _buildEnhancedAttackCard(context, entry.attack, entry.war),
          )
          .toList(),
    );
  }

  Widget _buildEnhancedAttackCard(
    BuildContext context,
    WarAttack attack,
    PlayerWarStatsData war,
  ) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isAttackCard = widget.type == "attacks";
    final targetPlayer = isAttackCard ? attack.defender : attack.attacker;
    final targetPlayerTag =
        targetPlayer?.tag ??
        (isAttackCard ? attack.defenderTag : attack.attackerTag);
    final targetName = targetPlayer?.name ?? loc.generalUnknown;
    final targetPosition = targetPlayer?.mapPosition;
    final targetTownHall = targetPlayer?.townhallLevel;
    final formattedDate = DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).format(war.warDetails.startTime ?? DateTime.now());
    final starPerformance = widget.type == "defenses"
        ? 3.0 - attack.stars
        : attack.stars.toDouble();
    final accentColor = _performanceColor(starPerformance);
    final targetLabel = targetPosition != null && targetPosition > 0
        ? '$targetPosition. $targetName'
        : targetName;
    final detailParts = [
      if (targetTownHall != null && targetTownHall > 0) 'TH$targetTownHall',
      formattedDate,
      if (attack.order > 0) '#${attack.order}',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
      ),
      child: Dismissible(
        key: Key(
          '${widget.type}-${attack.order}-${attack.attacker?.tag}-${attack.defender?.tag}-${war.warDetails.startTime}',
        ),
        background: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(Icons.person, color: Colors.white, size: 24),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.info, color: Colors.white, size: 24),
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
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _viewPlayerProfile(context, targetPlayerTag),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: ImageAssets.townHall(
                      targetTownHall != null && targetTownHall > 0
                          ? targetTownHall
                          : 1,
                    ),
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      width: 34,
                      height: 34,
                      color: colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Text(
                        targetTownHall != null && targetTownHall > 0
                            ? 'TH$targetTownHall'
                            : '?',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        targetLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detailParts.join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                buildStarsIcon(attack.stars),
                const SizedBox(width: 8),
                Text(
                  '${attack.destructionPercentage}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                SizedBox.square(
                  dimension: 40,
                  child: IconButton(
                    tooltip: loc.warAttacksDetailsTitle,
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    color: colorScheme.onSurfaceVariant,
                    onPressed: () => _showAttackDetails(context, attack, war),
                    icon: const Icon(Icons.info_outline_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _performanceColor(double starPerformance) {
    if (starPerformance >= 3.0) return Colors.green[600]!;
    if (starPerformance >= 2.0) return Colors.orange[600]!;
    if (starPerformance >= 1.0) return Colors.amber[700]!;
    return Colors.red[600]!;
  }

  Future<void> _viewPlayerProfile(
    BuildContext context,
    String? playerTag,
  ) async {
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
        MaterialPageRoute(builder: (_) => PlayerScreen(selectedPlayer: player)),
      );
    } catch (e) {
      navigator.pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.warAttacksFailedToLoadPlayer,
            ),
          ),
        );
      }
    }
  }

  void _showAttackDetails(
    BuildContext context,
    WarAttack attack,
    PlayerWarStatsData war,
  ) {
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
                        title: AppLocalizations.of(
                          context,
                        )!.warAttacksDetailsTitle,
                        icon: Icons.military_tech,
                        children: [
                          _buildIconValueRow(
                            context,
                            Icons.star,
                            AppLocalizations.of(context)!.warStarsTitle,
                            attack.stars.toString(),
                          ),
                          _buildIconValueRow(
                            context,
                            Icons.percent,
                            AppLocalizations.of(context)!.warDestructionTitle,
                            '${attack.destructionPercentage}%',
                          ),
                          _buildIconValueRow(
                            context,
                            Icons.format_list_numbered,
                            AppLocalizations.of(
                              context,
                            )!.warAttacksDetailsAttackOrder,
                            attack.order.toString(),
                          ),
                          _buildIconValueRow(
                            context,
                            Icons.sports_esports,
                            AppLocalizations.of(context)!.filtersWarType,
                            war.warDetails.warType ??
                                AppLocalizations.of(context)!.generalUnknown,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // War Information Card
                      _buildInfoCard(
                        context,
                        title: AppLocalizations.of(
                          context,
                        )!.warInformationTitle,
                        icon: Icons.info,
                        children: [
                          _buildIconValueRow(
                            context,
                            _getWarStateIcon(war.warDetails.state),
                            AppLocalizations.of(context)!.warDataState,
                            _getWarStateDisplay(context, war.warDetails.state),
                          ),
                          _buildIconValueRow(
                            context,
                            Icons.group,
                            AppLocalizations.of(context)!.warTeamSize,
                            war.warDetails.teamSize?.toString() ??
                                AppLocalizations.of(context)!.generalUnknown,
                          ),
                          _buildIconValueRow(
                            context,
                            Icons.local_fire_department,
                            AppLocalizations.of(
                              context,
                            )!.warDataAttacksPerMember,
                            war.warDetails.attacksPerMember?.toString() ??
                                AppLocalizations.of(context)!.generalUnknown,
                          ),
                          if (war.warDetails.startTime != null)
                            _buildIconValueRow(
                              context,
                              Icons.schedule,
                              AppLocalizations.of(context)!.warDataStartTime,
                              DateFormat.yMd(
                                Localizations.localeOf(context).toString(),
                              ).add_Hm().format(war.warDetails.startTime!),
                            ),
                          if (war.warDetails.endTime != null)
                            _buildIconValueRow(
                              context,
                              Icons.flag,
                              AppLocalizations.of(context)!.warDataEndTime,
                              DateFormat.yMd(
                                Localizations.localeOf(context).toString(),
                              ).add_Hm().format(war.warDetails.endTime!),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Clan vs Opponent Section
                      if (war.warDetails.clan != null &&
                          war.warDetails.opponent != null) ...[
                        _buildClanVsOpponentCard(
                          context,
                          war.warDetails.clan!,
                          war.warDetails.opponent!,
                        ),
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
          Text(
            AppLocalizations.of(context)?.generalNoDataAvailable ?? 'No data',
          ),
          const SizedBox(height: 16),
          CachedNetworkImage(
            imageUrl:
                'https://assets.clashk.ing/stickers/Villager_HV_Villager_7.png',
            height: 150,
            width: 120,
          ),
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
        return AppLocalizations.of(context)!.warEnded;
      case 'inwar':
        return AppLocalizations.of(context)!.warInWar;
      case 'preparation':
        return AppLocalizations.of(context)!.warPreparation;
      default:
        return state;
    }
  }

  // New user-friendly card builder
  Widget _buildInfoCard(
    BuildContext context, {
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
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
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
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // Icon-value row builder
  Widget _buildIconValueRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
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
  Widget _buildClanVsOpponentCard(
    BuildContext context,
    WarClan clan,
    WarClan opponent,
  ) {
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
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
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
                          _buildClanStatItem(
                            context,
                            Icons.emoji_events,
                            AppLocalizations.of(context)!.warDataClanLevel,
                            clan.clanLevel.toString(),
                          ),
                          _buildClanStatItem(
                            context,
                            Icons.star,
                            AppLocalizations.of(context)!.warDataTotalStars,
                            clan.stars.toString(),
                          ),
                          _buildClanStatItem(
                            context,
                            Icons.local_fire_department,
                            AppLocalizations.of(context)!.warAttacksTitle,
                            clan.attacks.toString(),
                          ),
                          _buildClanStatItem(
                            context,
                            Icons.percent,
                            AppLocalizations.of(
                              context,
                            )!.warDataDestructionPercentage,
                            '${clan.destructionPercentage.toStringAsFixed(1)}%',
                          ),
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
                            Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.1),
                            Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.3),
                            Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _buildClanStatItem(
                            context,
                            Icons.emoji_events,
                            AppLocalizations.of(context)!.warDataClanLevel,
                            opponent.clanLevel.toString(),
                          ),
                          _buildClanStatItem(
                            context,
                            Icons.star,
                            AppLocalizations.of(context)!.warDataTotalStars,
                            opponent.stars.toString(),
                          ),
                          _buildClanStatItem(
                            context,
                            Icons.local_fire_department,
                            AppLocalizations.of(context)!.warAttacksTitle,
                            opponent.attacks.toString(),
                          ),
                          _buildClanStatItem(
                            context,
                            Icons.percent,
                            AppLocalizations.of(
                              context,
                            )!.warDataDestructionPercentage,
                            '${opponent.destructionPercentage.toStringAsFixed(1)}%',
                          ),
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

  Widget _buildClanStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
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
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, size: 18, color: Colors.blue[700]),
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
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield, size: 18, color: Colors.red[700]),
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
        _buildPlayerInfoRow(
          context,
          Icons.person,
          AppLocalizations.of(context)!.warAttacksDetailsName,
          player?.name ?? AppLocalizations.of(context)!.generalUnknown,
        ),
        _buildPlayerInfoRow(
          context,
          Icons.home,
          AppLocalizations.of(context)!.gameTownHallLevel,
          player?.townhallLevel?.toString() ??
              AppLocalizations.of(context)!.generalUnknown,
        ),
        _buildPlayerInfoRow(
          context,
          Icons.location_on,
          AppLocalizations.of(context)!.warPositionMap,
          player?.mapPosition?.toString() ??
              AppLocalizations.of(context)!.generalUnknown,
        ),
      ],
    );
  }

  Widget _buildPlayerInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _WarAttackEntry {
  final PlayerWarStatsData war;
  final WarAttack attack;

  const _WarAttackEntry({required this.war, required this.attack});
}
