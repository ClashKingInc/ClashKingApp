import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/widgets/cwl_round_card.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class CwlRoundsTab extends StatefulWidget {
  final WarCwl warCwl;

  CwlRoundsTab({
    super.key,
    required this.warCwl,
  });

  @override
  CwlRoundsTabState createState() => CwlRoundsTabState();
}

class CwlRoundsTabState extends State<CwlRoundsTab> {
  @override
  Widget build(BuildContext context) {
    final rounds = widget.warCwl.leagueInfo?.rounds;
    final currentRound = widget.warCwl.leagueInfo?.getCurrentRounds();

    if (rounds == null || currentRound == null) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            AppLocalizations.of(context)!
                .cwlRoundNumber(currentRound.roundNumber),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ...currentRound.warTags.map((tag) {
          final war = widget.warCwl.getWarInfoFromTag(tag);
          return war != null
              ? RoundClanCard(warInfo: war)
              : const SizedBox.shrink();
        }),
        const SizedBox(height: 16),
        ...rounds
            .where((r) =>
                r.warTags.any((tag) => tag != "#0") &&
                r.roundNumber != currentRound.roundNumber)
            .map((round) => Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        AppLocalizations.of(context)!
                            .cwlRoundNumber(round.roundNumber),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    ...round.warTags.map((tag) {
                      final war = widget.warCwl.getWarInfoFromTag(tag);
                      return war != null
                          ? RoundClanCard(warInfo: war)
                          : const SizedBox.shrink();
                    }),
                  ],
                ))
            .toList()
            .reversed,
      ],
    );
  }
}
