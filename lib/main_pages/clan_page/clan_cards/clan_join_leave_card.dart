import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/components/chip.dart';
import 'package:clashkingapp/classes/functions.dart';
import 'package:intl/intl.dart';

class ClanJoinLeaveCard extends StatelessWidget {
  const ClanJoinLeaveCard(
      {super.key, required this.discordUser, required this.clanInfo});

  final List<String> discordUser;
  final Clan? clanInfo;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    DateTime lastMonday = findLastMondayOfMonth(now.year, now.month - 1);
    String formattedDate = DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(lastMonday);
    
    var joinsAfterLastMonday = clanInfo!.joinLeaveClan.items.where((item) => item.type == "join" && item.time.isAfter(lastMonday)).toList();
    var leavesAfterLastMonday = clanInfo!.joinLeaveClan.items.where((item) => item.type == "leave" && item.time.isAfter(lastMonday)).toList();
    int joinDifference = joinsAfterLastMonday.length - leavesAfterLastMonday.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      CachedNetworkImage(
                        height: 70,
                        width: 70,
                        imageUrl: "https://assets.clashk.ing/stickers/Troop_HV_Goblin.png"),
                    ],
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: Column(
                    children: <Widget>[
                      Text(
                        AppLocalizations.of(context)!.joinLeaveLogs,
                        style: Theme.of(context).textTheme.labelLarge,
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                      SizedBox(height: 2.0),
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 7.0,
                        runSpacing: -7.0,
                        children: <Widget>[
                          IconChip(
                            icon: LucideIcons.logOut,
                            color: Colors.red,
                            size: 16,
                            labelPadding: 2,
                            label: joinsAfterLastMonday.length.toString(),
                            description: AppLocalizations.of(context)!
                            .leaveNumberDescription(joinsAfterLastMonday.length,formattedDate),
                          ),
                          IconChip(
                            icon: LucideIcons.logIn,
                            color: Colors.green,
                            size: 16,
                            labelPadding: 2,
                            label: leavesAfterLastMonday.length.toString(),
                            description: AppLocalizations.of(context)!
                              .joinNumberDescription(leavesAfterLastMonday.length,formattedDate),
                          ),
                          IconChip(
                            icon: LucideIcons.arrowUpDown,
                            color: Colors.blue,
                            size: 16,
                            labelPadding: 2,
                            label: joinDifference.toString(),
                            description: joinDifference > 0
                              ? AppLocalizations.of(context)!.joinLeaveDifferenceUpDescription(joinDifference, formattedDate)
                              : joinDifference < 0
                                ? AppLocalizations.of(context)!.joinLeaveDifferenceDownDescription(-joinDifference, formattedDate)
                                : AppLocalizations.of(context)!.joinLeaveDifferenceEqualDescription(formattedDate)
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
