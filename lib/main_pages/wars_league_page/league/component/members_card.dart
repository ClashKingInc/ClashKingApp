import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class MembersCard extends StatelessWidget {
  const MembersCard({
    super.key,
    required this.memberEntry,
    required this.index,
    required this.discordUser,
  });

  final MapEntry<String, Map<String, dynamic>> memberEntry;
  final int index;
  final List<String> discordUser;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          shape: RoundedRectangleBorder(
          side: discordUser.contains(memberEntry.key)
            ? BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
          borderRadius: BorderRadius.circular(12.0),
        ),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                            height: 70,
                            width: 70,
                            child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),imageUrl: 
                              'https://assets.clashk.ing/home-base/town-hall-pics/town-hall-${memberEntry.value['townHallLevel']}.png')),
                        ],
                      ),
                      Text(" ${memberEntry.value['name']}"),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Text(AppLocalizations.of(context)!.total),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${memberEntry.value['stars']}'),
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),imageUrl: 
                              'https://assets.clashk.ing/icons/Icon_BB_Star.png')),
                        ],
                      ),
                      Text('${(memberEntry.value['percentage'] as double).toInt()}%'),
                      Text('${memberEntry.value['attacksDone']}/${memberEntry.value['warParticipated']}'),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.average),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("${(memberEntry.value['averageStars']).toStringAsFixed(1)}"),
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),imageUrl: 
                              'https://assets.clashk.ing/icons/Icon_BB_Star.png')),
                        ],
                      ),
                      Text('${(memberEntry.value['averagePercentage']).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 20,
          child: Text("${index + 1}.",
          style: Theme.of(context).textTheme.titleMedium)
        ),
      ],
    );
  }
}
