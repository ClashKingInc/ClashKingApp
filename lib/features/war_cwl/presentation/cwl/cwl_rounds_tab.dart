import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_league_round.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/widgets/cwl_round_card.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class CwlRoundsTab extends StatefulWidget {
  final WarCwl warCwl;

  CwlRoundsTab({super.key, required this.warCwl});

  @override
  CwlRoundsTabState createState() => CwlRoundsTabState();
}

class CwlRoundsTabState extends State<CwlRoundsTab> {
  final Set<int> _expandedRounds = {};
  int? _defaultExpandedRound;

  @override
  Widget build(BuildContext context) {
    final rounds = widget.warCwl.leagueInfo?.rounds;
    final currentRound = widget.warCwl.leagueInfo?.getCurrentRounds();

    if (rounds == null || currentRound == null) {
      return SizedBox.shrink();
    }

    _syncDefaultExpandedRound(currentRound);
    final visibleRounds = _orderedRounds(rounds, currentRound);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: visibleRounds
          .map(
            (round) => _RoundSection(
              round: round,
              clanTag: widget.warCwl.tag,
              wars: _warsForRound(round),
              isCurrentRound: round.roundNumber == currentRound.roundNumber,
              isExpanded: _expandedRounds.contains(round.roundNumber),
              onToggle: () => _toggleRound(round.roundNumber),
            ),
          )
          .toList(),
    );
  }

  void _syncDefaultExpandedRound(CwlLeagueRound currentRound) {
    if (_defaultExpandedRound == currentRound.roundNumber) {
      return;
    }

    _expandedRounds
      ..clear()
      ..add(currentRound.roundNumber);
    _defaultExpandedRound = currentRound.roundNumber;
  }

  void _toggleRound(int roundNumber) {
    setState(() {
      if (_expandedRounds.contains(roundNumber)) {
        _expandedRounds.remove(roundNumber);
      } else {
        _expandedRounds.add(roundNumber);
      }
    });
  }

  List<WarInfo> _warsForRound(CwlLeagueRound round) {
    return round.warTags
        .where((tag) => tag != "#0")
        .map(widget.warCwl.getWarInfoFromTag)
        .whereType<WarInfo>()
        .where((war) => war.clan != null && war.opponent != null)
        .toList();
  }

  List<CwlLeagueRound> _orderedRounds(
    List<CwlLeagueRound> rounds,
    CwlLeagueRound currentRound,
  ) {
    final playableRounds = rounds
        .where((round) => round.warTags.any((tag) => tag != "#0"))
        .toList();
    final preparationRound = _preparationRound(playableRounds, currentRound);
    final orderedRounds = <CwlLeagueRound>[];

    void addIfMissing(CwlLeagueRound? round) {
      if (round == null) return;
      if (orderedRounds.any((r) => r.roundNumber == round.roundNumber)) return;
      orderedRounds.add(round);
    }

    addIfMissing(preparationRound);
    addIfMissing(currentRound);

    for (final round in playableRounds.reversed) {
      addIfMissing(round);
    }

    return orderedRounds;
  }

  CwlLeagueRound? _preparationRound(
    List<CwlLeagueRound> rounds,
    CwlLeagueRound currentRound,
  ) {
    for (final round in rounds.reversed) {
      if (round.roundNumber == currentRound.roundNumber) continue;
      if (_warsForRound(round).any(_isPreparationWar)) {
        return round;
      }
    }
    return null;
  }

  bool _isPreparationWar(WarInfo war) {
    return war.state == 'preparation' || war.state == 'preparationDay';
  }
}

class _RoundSection extends StatelessWidget {
  final CwlLeagueRound round;
  final String clanTag;
  final List<WarInfo> wars;
  final bool isCurrentRound;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _RoundSection({
    required this.round,
    required this.clanTag,
    required this.wars,
    required this.isCurrentRound,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roundSurface = isDark
        ? Colors.black.withValues(alpha: 0.28)
        : Colors.black.withValues(alpha: 0.06);
    final roundBorder = Colors.black.withValues(
      alpha: isCurrentRound
          ? isDark
                ? 0.44
                : 0.18
          : isDark
          ? 0.28
          : 0.10,
    );
    final selectedWar = _selectedClanWar;
    final fallbackWar = wars.isNotEmpty ? wars.first : null;
    final status = _RoundStatus.fromWar(selectedWar ?? fallbackWar);
    final result = status == _RoundStatus.ended && selectedWar != null
        ? _RoundResult.fromWar(selectedWar, clanTag)
        : null;
    final badgeLabel = result?.label(loc) ?? status.label(loc);
    final badgeColor = result?.color ?? status.color;
    final badgeImageUrl = result?.imageUrl ?? status.imageUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: Ink(
              decoration: BoxDecoration(
                color: roundSurface,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(color: roundBorder),
              ),
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.cwlRoundNumber(round.roundNumber),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoundBadge(
                        label: badgeLabel,
                        color: badgeColor,
                        imageUrl: badgeImageUrl,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                children: wars
                    .map(
                      (war) => RoundClanCard(
                        warInfo: war,
                        roundNumber: round.roundNumber,
                      ),
                    )
                    .toList(),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  WarInfo? get _selectedClanWar {
    final normalizedClanTag = _normalizeTag(clanTag);
    for (final war in wars) {
      if (_normalizeTag(war.clan?.tag) == normalizedClanTag ||
          _normalizeTag(war.opponent?.tag) == normalizedClanTag) {
        return war;
      }
    }
    return null;
  }
}

class _RoundBadge extends StatelessWidget {
  final String label;
  final Color color;
  final String imageUrl;

  const _RoundBadge({
    required this.label,
    required this.color,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MobileWebImage(
              imageUrl: imageUrl,
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

enum _RoundStatus {
  incoming,
  ongoing,
  ended;

  factory _RoundStatus.fromWar(WarInfo? war) {
    return switch (war?.state) {
      'warEnded' => _RoundStatus.ended,
      'inWar' || 'warInWar' => _RoundStatus.ongoing,
      _ => _RoundStatus.incoming,
    };
  }

  String label(AppLocalizations loc) {
    return switch (this) {
      _RoundStatus.incoming => loc.warPreparation,
      _RoundStatus.ongoing => loc.warOngoing,
      _RoundStatus.ended => loc.warEnded,
    };
  }

  Color get color {
    return switch (this) {
      _RoundStatus.incoming => StatColors.warStarGold,
      _RoundStatus.ongoing => StatColors.tie,
      _RoundStatus.ended => StatColors.win,
    };
  }

  String get imageUrl {
    return switch (this) {
      _RoundStatus.incoming => ImageAssets.iconClock,
      _RoundStatus.ongoing => ImageAssets.sword,
      _RoundStatus.ended => ImageAssets.iconTick,
    };
  }
}

enum _RoundResult {
  won,
  lost,
  draw,
  perfect;

  factory _RoundResult.fromWar(WarInfo war, String clanTag) {
    return switch (war.getWarResult(clanTag)) {
      'won' => _RoundResult.won,
      'lost' => _RoundResult.lost,
      'tie' => _RoundResult.draw,
      'perfectWar' => _RoundResult.perfect,
      _ => _RoundResult.draw,
    };
  }

  String label(AppLocalizations loc) {
    return switch (this) {
      _RoundResult.won => loc.warVictory,
      _RoundResult.lost => loc.warDefeat,
      _RoundResult.draw => loc.warDraw,
      _RoundResult.perfect => loc.warPerfectWar,
    };
  }

  Color get color {
    return switch (this) {
      _RoundResult.won || _RoundResult.perfect => StatColors.win,
      _RoundResult.lost => StatColors.loss,
      _RoundResult.draw => StatColors.tie,
    };
  }

  String get imageUrl {
    return switch (this) {
      _RoundResult.won || _RoundResult.perfect => ImageAssets.attackStar,
      _RoundResult.lost => ImageAssets.brokenSword,
      _RoundResult.draw => ImageAssets.shield,
    };
  }
}

String? _normalizeTag(String? tag) {
  if (tag == null || tag.isEmpty) {
    return null;
  }
  return tag.startsWith('#') ? tag : '#$tag';
}
