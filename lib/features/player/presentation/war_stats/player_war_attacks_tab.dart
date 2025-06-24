import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/player_war_attacks_card.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class PlayerWarAttacksTab extends StatefulWidget {
  final List<PlayerWarStatsData> wars;

  const PlayerWarAttacksTab({super.key, required this.wars});

  @override
  State<PlayerWarAttacksTab> createState() => _PlayerWarAttacksTabState();
}

class _PlayerWarAttacksTabState extends State<PlayerWarAttacksTab> {
  int _currentSegment = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        CustomSlidingSegmentedControl<int>(
          initialValue: _currentSegment,
          children: {
            1: Text(AppLocalizations.of(context)!.warAttacksTitle),
            2: Text(AppLocalizations.of(context)!.warDefensesTitle),
          },
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          thumbDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4.0,
                spreadRadius: 1.0,
                offset: Offset(0.0, 2.0),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInToLinear,
          onValueChanged: (v) {
            setState(() {
              _currentSegment = v;
            });
          },
        ),
        const SizedBox(height: 8),
        _currentSegment == 1
            ? PlayerWarAttacksCard(
                wars: widget.wars,
                type: "attacks",
              )
            : PlayerWarAttacksCard(
                wars: widget.wars,
                type: "defenses",
              ),
      ],
    );
  }
}
