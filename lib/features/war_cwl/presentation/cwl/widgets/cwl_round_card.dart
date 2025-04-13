import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/functions.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class RoundClanCard extends StatelessWidget {
  final WarInfo warInfo;

  const RoundClanCard({
    super.key,
    required this.warInfo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WarScreen(war: warInfo),
            ),
          );
        },
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 50,
                              width: 50,
                              child: CachedNetworkImage(
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                  imageUrl: warInfo.clan!.badgeUrls.small),
                            ),
                            Column(
                              children: [
                                Row(children: [
                                  SizedBox(
                                    child: CachedNetworkImage(
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.error),
                                      imageUrl: ImageAssets.sword,
                                      width: 12,
                                      height: 12,
                                    ),
                                  ),
                                  Text(
                                      "${warInfo.clan!.attacks}/${warInfo.teamSize.toString()}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium),
                                ]),
                                Row(children: [
                                  SizedBox(
                                    child: CachedNetworkImage(
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.error),
                                      imageUrl: ImageAssets.hitrate,
                                      width: 12,
                                      height: 12,
                                    ),
                                  ),
                                  Text(
                                      " ${warInfo.clan!.destructionPercentage.toStringAsFixed(2)}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium),
                                ]),
                              ],
                            ),
                          ]),
                      Text(
                        warInfo.clan!.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        warInfo.state == "preparation"
                            ? "Starts at ${DateFormat('HH:mm').format(warInfo.startTime!.toLocal())}"
                            : warInfo.state == "inWar"
                                ? "Ends at ${DateFormat('HH:mm').format(warInfo.endTime!.toLocal())}"
                                : getEndedAgoText(warInfo.endTime, context),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${warInfo.clan!.stars}",
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: warInfo.clan!.stars >
                                                  warInfo.opponent!.stars ||
                                              (warInfo.clan!.stars ==
                                                      warInfo.opponent!.stars &&
                                                  warInfo.clan!
                                                          .destructionPercentage >
                                                      warInfo.opponent!
                                                          .destructionPercentage)
                                          ? Colors.green
                                          : null,
                                    ),
                          ),
                          Text(" - "),
                          Text(
                            "${warInfo.opponent!.stars}",
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: warInfo.opponent!.stars >
                                                  warInfo.clan!.stars ||
                                              (warInfo.opponent!.stars ==
                                                      warInfo.clan!.stars &&
                                                  warInfo.opponent!
                                                          .destructionPercentage >
                                                      warInfo.clan!
                                                          .destructionPercentage)
                                          ? Colors.green
                                          : null,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        "${warInfo.opponent!.attacks}/${warInfo.teamSize.toString()}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium),
                                    SizedBox(
                                      child: CachedNetworkImage(
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                        imageUrl:
                                            "https://assets.clashk.ing/icons/Icon_HV_Sword.png",
                                        width: 12,
                                        height: 12,
                                      ),
                                    ),
                                  ]),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        "${warInfo.opponent!.destructionPercentage.toStringAsFixed(2)} ",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium),
                                    SizedBox(
                                      child: CachedNetworkImage(
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                        imageUrl:
                                            "https://assets.clashk.ing/icons/Icon_DC_Hitrate.png",
                                        width: 12,
                                        height: 12,
                                      ),
                                    ),
                                  ])
                            ],
                          ),
                          SizedBox(
                            height: 50,
                            width: 50,
                            child: CachedNetworkImage(
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.error),
                                imageUrl: warInfo.opponent!.badgeUrls.small),
                          ),
                        ],
                      ),
                      Text(
                        warInfo.opponent!.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
