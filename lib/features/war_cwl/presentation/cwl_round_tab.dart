import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/widgets/cwl_round_card.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_clan.dart';

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
  late String sortMembersBy = 'stars';
  late String sortTeamsBy = 'stars';
  late CwlClan clan;

  @override
  Widget build(BuildContext context) {
    final rounds = widget.warCwl.leagueInfo?.rounds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rounds!
          .where((round) => round.warTags.any((tag) => tag != "#0"))
          .map<Widget>((round) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Round ${round.roundNumber}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...round.warTags.map((tag) {
              final war = widget.warCwl.getWarInfoFromTag(tag);
              if (war != null) {
                return RoundClanCard(warInfo: war);
              } else {
                return const SizedBox.shrink();
              }
            }).toList(),
          ],
        );
      }).toList(),
    );
  }
}
