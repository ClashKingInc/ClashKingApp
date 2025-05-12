import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/war_cwl/models/war_attack.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/core/functions/war_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlayerWarAttacksCard extends StatelessWidget {
  final List<PlayerWarStatsData> wars;
  final String type;

  const PlayerWarAttacksCard({super.key, required this.wars, required this.type});

  @override
  Widget build(BuildContext context) {
    if (wars.isEmpty) {
      return _buildEmpty(context);
    }

    List<Map<String, dynamic>> allAttacks = [];

    if (type == "attacks") {
      allAttacks = wars
          .expand((w) => w.memberData.attacks.map((d) => {"defense": d, "war": w}))
          .toList();
    } else {
      allAttacks = wars
          .expand((w) => w.memberData.defenses.map((d) => {"defense": d, "war": w}))
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
                .format(DateTime.parse(war.warDetails.startTime));

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: type == "attacks"
                ? Text(
                    "${defense.defender?.mapPosition}. ${defense.defender?.name}")
                : Text(
                    "${defense.attacker?.mapPosition}. ${defense.attacker?.name}"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${defense.destructionPercentage.toString()}%"),
                Row(children: [...generateStars(defense.stars, 16)])
              ],
            ),
            leading: CachedNetworkImage(
              imageUrl:
                  'https://assets.clashk.ing/home-base/town-hall-pics/town-hall-${defense.attacker?.townhallLevel}.png',
              width: 40,
            ),
            trailing: Text(formattedDate),
            onTap: () async {
              showDialog(
                context: context,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );
              Navigator.of(context).pop();
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(AppLocalizations.of(context)?.noDataAvailable ?? 'No data'),
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
