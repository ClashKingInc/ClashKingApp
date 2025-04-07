import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_page.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class CwlTeamCard extends StatelessWidget {
  final CwlClan clan;
  final WarCwl warCwl;

  const CwlTeamCard({super.key, required this.clan, required this.warCwl});

  @override
  Widget build(BuildContext context) {
    final sortedTownHalls = clan.townHallLevels.entries.toList();
    sortedTownHalls
        .sort((a, b) => int.parse(b.key).compareTo(int.parse(a.key)));

    return GestureDetector(
      onTap: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        final Clan clanInfo = await ClanService().loadClanData(clan.tag);
        if (context.mounted) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClanInfoScreen(
                clanInfo: clanInfo,
              ),
            ),
          );
        }
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  CachedNetworkImage(
                    imageUrl: clan.badgeUrls.medium,
                    width: 40,
                    height: 40,
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(clan.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(clan.tag,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text("${clan.stars}  "),
                          SizedBox(
                            child: MobileWebImage(
                              imageUrl: ImageAssets.attackStar,
                              width: 15,
                              height: 15,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                              "${NumberFormat('#,###', Localizations.localeOf(context).toString()).format(clan.destructionPercentageInflicted)}  "),
                          SizedBox(
                            child: MobileWebImage(
                              imageUrl: ImageAssets.hitrate,
                              width: 15,
                              height: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                children: sortedTownHalls.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MobileWebImage(
                          imageUrl: ImageAssets.townHall(int.parse(entry.key)),
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'x${entry.value}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            ],
          ),
        ),
      ),
    );
  }
}
