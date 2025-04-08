import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart'
    show generateStars;
import 'package:clashkingapp/features/war_cwl/models/war_info.dart'
    show WarInfo;
import 'package:clashkingapp/features/war_cwl/models/war_member.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class WarTeamCard extends StatelessWidget {
  final WarInfo warInfo;
  final List<WarMember> members;
  final int attacksPerMember;

  const WarTeamCard({
    super.key,
    required this.members,
    required this.attacksPerMember,
    required this.warInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: members.map((member) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MobileWebImage(
                      imageUrl: ImageAssets.townHall(member.townhallLevel),
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 8),
                    Text('${member.mapPosition}. ${member.name}',
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Defense
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              AppLocalizations.of(context)!
                                  .bestDefenseOutOf(member.opponentAttacks),
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 4),
                          if (member.bestOpponentAttack != null)
                            _buildDefenseCard(context, member)
                          else
                            Text(AppLocalizations.of(context)!.noDefenseYet,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(
                                            alpha: 0.6,
                                          ),
                                    )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: warInfo.attacksPerMember == 1 ? 40 : 70,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "${AppLocalizations.of(context)!.attacks} (${member.attacks?.length ?? 0}/$attacksPerMember)",
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 4),
                          ...List.generate(attacksPerMember, (index) {
                            final attack = (member.attacks?.length ?? 0) > index
                                ? member.attacks![index]
                                : null;
                            return _buildAttackCard(context, attack);
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDefenseCard(BuildContext context, WarMember member) {
    final attack = member.bestOpponentAttack!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          MobileWebImage(
            imageUrl: ImageAssets.townHall(
                warInfo.getTownhallLevelByTag(attack.attackerTag) ?? 1),
            width: 30,
            height: 30,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${warInfo.getMapPositionByTag(attack.attackerTag)}. ${warInfo.getNameByTag(attack.attackerTag)}',
                    style: Theme.of(context).textTheme.bodySmall),
                Row(
                  children: [
                    ...generateStars(attack.stars, 16),
                    Text(' ${attack.destructionPercentage}%',
                        style: Theme.of(context).textTheme.labelLarge),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttackCard(BuildContext context, dynamic attack) {
    if (attack == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(AppLocalizations.of(context)!.noAttackYet,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.5,
                      ),
                )),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          MobileWebImage(
            imageUrl: ImageAssets.townHall(
                warInfo.getTownhallLevelByTag(attack.defenderTag) ?? 1),
            width: 30,
            height: 30,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${warInfo.getMapPositionByTag(attack.defenderTag)}. ${warInfo.getNameByTag(attack.defenderTag)}',
                    style: Theme.of(context).textTheme.bodySmall),
                Row(
                  children: [
                    ...generateStars(attack.stars, 16),
                    Text(' ${attack.destructionPercentage}%',
                        style: Theme.of(context).textTheme.labelLarge),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
