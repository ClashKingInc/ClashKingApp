import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/current_war_info_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/api/war_log.dart';

class WarLogHistoryCard extends StatefulWidget {
  final List<String> discordUser;
  final String clanTag;
  final List<WarLogDetails> warLogData;

  const WarLogHistoryCard({
    super.key,
    required this.discordUser,
    required this.clanTag,
    required this.warLogData,
  });

  @override
  WarLogHistoryCardState createState() => WarLogHistoryCardState();
}

class WarLogHistoryCardState extends State<WarLogHistoryCard> {
  String formatDate(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final format = locale == 'fr' ? 'dd/MM/yyyy' : 'MM/dd/yyyy';
    return DateFormat(format).format(date);
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        buildAllLog(context),
      ],
    );
  }

  Widget buildAllLog(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 2),
          Center(
            child: Column(
              children: List<Widget>.generate(widget.warLogData.length, (index) {
                final warLogDetail = widget.warLogData[index];
                if (warLogDetail.attacksPerMember != 2) {
                  return SizedBox.shrink();
                }
                
                return GestureDetector(
                  onTap: () {
                    CurrentWarService.fetchWarDataFromTime(widget.clanTag, warLogDetail.endTime).then((currentWarInfo) {
                      if (currentWarInfo == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Center(
                              child: Text(
                                AppLocalizations.of(context)?.noDataAvailableForThisWar ?? 'No data available for this war',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              ),
                            ),
                            duration: Duration(seconds: 1),
                            backgroundColor: Theme.of(context).colorScheme.surface,
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CurrentWarInfoScreen(
                              currentWarInfo: currentWarInfo,
                              discordUser: widget.discordUser,
                            ),
                          ),
                        );
                      }
                    }).catchError((error) {
                      return null;
                    });
                  },
                  child: Card(
                    margin: EdgeInsets.only(top: 4, bottom: 4, left: 4, right: 4),
                    child: Padding(
                    padding: const EdgeInsets.all(8.0),
                      child:Column(
                        children: <Widget>[
                          Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: <Widget>[
                                    SizedBox(
                                      width: 70,
                                      height: 70,
                                      child: CachedNetworkImage(imageUrl: warLogDetail.clan.badgeUrls.large, fit: BoxFit.cover),
                                    ),
                                    Text(
                                      warLogDetail.clan.name,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodySmall
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: <Widget>[
                                    Text(formatDate(warLogDetail.endTime, context),
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                    Text(
                                      warLogDetail.result == 'win' ? AppLocalizations.of(context)?.victory ?? 'Victory'
                                        : warLogDetail.result == 'lose' ? AppLocalizations.of(context)?.defeat ?? 'Defeat'
                                        : AppLocalizations.of(context)?.draw ?? 'Draw',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: warLogDetail.result == 'win' ? Colors.green 
                                          : warLogDetail.result == 'lose' ? Colors.red : Colors.blue),
                                    ),
                                    Text('${warLogDetail.clan.stars.toString().padRight(2, ' ')} - ${warLogDetail.opponent.stars.toString().padRight(2, ' ')} ',
                                      style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold)),
                                    Text('${warLogDetail.clan.destructionPercentage % 1 == 0 
                                      ? warLogDetail.clan.destructionPercentage.toInt().toString().padLeft(6, ' ') 
                                      : warLogDetail.clan.destructionPercentage.toStringAsFixed(2).padLeft(5, '0')}%    ${warLogDetail.opponent.destructionPercentage % 1 == 0 
                                        ? ('${warLogDetail.opponent.destructionPercentage.toInt()}%').padRight(7, ' ') 
                                        : ('${warLogDetail.opponent.destructionPercentage.toStringAsFixed(2)}%').padLeft(5, ' ')}'
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CachedNetworkImage(imageUrl: 'https://clashkingfiles.b-cdn.net/icons/Icon_HV_XP.png', width: 20, height: 20),
                                        Text(' +${warLogDetail.clan.expEarned}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: <Widget>[
                                    SizedBox(
                                      width: 70,
                                      height: 70,
                                      child: CachedNetworkImage(imageUrl: warLogDetail.opponent.badgeUrls.large,
                                        fit: BoxFit.cover),
                                    ),
                                    Text(warLogDetail.opponent.name,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodySmall
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}