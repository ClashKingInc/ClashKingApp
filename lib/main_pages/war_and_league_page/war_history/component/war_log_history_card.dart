import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/api/war_log.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';

class WarLogHistoryCard extends StatefulWidget {
  final List<dynamic> warHistoryData;
  final List<String> discordUser;
  final String clanTag;
  final List<WarLogDetails> warLogData;

  const WarLogHistoryCard({
    super.key,
    required this.warHistoryData,
    required this.discordUser,
    required this.clanTag,
    required this.warLogData,
  });

  @override
  WarLogHistoryCardState createState() => WarLogHistoryCardState();
}

class WarLogHistoryCardState extends State<WarLogHistoryCard> {
  int selectedSegment = 0;

  String formatDate(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final format = locale == 'fr' ? 'dd/MM/yyyy' : 'MM/dd/yyyy';
    return DateFormat(format).format(date);
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        CustomSlidingSegmentedControl(
          children: {
            0: Text(AppLocalizations.of(context)?.warLog ?? 'War Log'),
            1: Text('War with details'),
          },
          onValueChanged: (value) {
            setState(() {
              selectedSegment = value;
            });
          },
          initialValue: selectedSegment,
                    decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          thumbDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.3),
                blurRadius: 4.0,
                spreadRadius: 1.0,
                offset: Offset(
                  0.0,
                  2.0,
                ),
              ),
            ],
          ),
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInToLinear,
        ),
        if (selectedSegment == 0) buildAllLog(context),
        if (selectedSegment == 1) buildWarLogWithDetails(context),
      ],
    );
  }

  Widget buildWarLogWithDetails(BuildContext context) {

    String determineWarResult(war, clanTag) {
      bool isClan = war['clan']['tag'] == clanTag;
      int clanStars = war['clan']['stars'];
      int opponentStars = war['opponent']['stars'];
      double clanDestruction = war['clan']['destructionPercentage'];
      double opponentDestruction = war['opponent']['destructionPercentage'];

      if (clanStars > opponentStars) {
        return isClan ? 'victory' : 'defeat';
      } else if (clanStars < opponentStars) {
        return isClan ? 'defeat' : 'victory';
      } else {
        if (clanDestruction > opponentDestruction) {
          return isClan ? 'victory' : 'defeat';
        } else if (clanDestruction < opponentDestruction) {
          return isClan ? 'defeat' : 'victory';
        } else {
          return 'draw';
        }
      }
    }

    List<Widget> warHistoryWidgets = [];

    for (var war in widget.warHistoryData) {
      String warResult = determineWarResult(war, widget.clanTag);
      Color color;
      String warResultString;
      if (warResult == 'victory') {
        color = Colors.green;
        warResultString = AppLocalizations.of(context)?.victory ?? 'Victory';
      } else if (warResult == 'defeat') {
        color = Colors.red;
        warResultString = AppLocalizations.of(context)?.defeat ?? 'Defeat';
      } else {
        color = Colors.blue;
        warResultString = AppLocalizations.of(context)?.draw ?? 'Draw';
      }
      warHistoryWidgets.add(
        Container(
          margin: EdgeInsets.only(top: 6, left: 4, right: 4),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: CachedNetworkImage(imageUrl: war['clan']['badgeUrls']['large'],
                              fit: BoxFit.cover),
                        ),
                        Text(war['clan']['name'],
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: <Widget>[
                        Text(
                          AppLocalizations.of(context)?.warEnded ?? 'War ended',
                          style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)
                        ),
                        Text(
                          warResultString,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold, color: color),
                        ),
                        Center(
                          child: Text(
                              '${war['clan']['stars'].toString().padRight(2, ' ')} - ${war['opponent']['stars'].toString().padRight(2, ' ')} ',
                              style: Theme.of(context)
                            .textTheme
                            .titleMedium
                          ),
                        ),
                        Center(
                            child: Text(
                                '${war['clan']['destructionPercentage'].toStringAsFixed(2).padLeft(5, '0')}%    ${war['opponent']['destructionPercentage'].toStringAsFixed(2).padLeft(5, ' ')}%')),
                        Center(child: Text(' ')),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          width: 70,
                          height:70,
                          child: CachedNetworkImage(imageUrl: war['opponent']['badgeUrls']['large'],
                              fit: BoxFit.cover),
                        ),
                        Text(war['opponent']['name'],
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall),
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
    return Column(children: warHistoryWidgets);
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

                    return  Card(
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
                                      Text('${warLogDetail.clan.destructionPercentage % 1 == 0 ? warLogDetail.clan.destructionPercentage.toInt() : warLogDetail.clan.destructionPercentage.toStringAsFixed(2).padLeft(5, '0')}%    ${warLogDetail.opponent.destructionPercentage % 1 == 0 ? warLogDetail.opponent.destructionPercentage.toInt() : warLogDetail.opponent.destructionPercentage.toStringAsFixed(2).padLeft(5, ' ')}%'),
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
                    );
                  }
                ),
              ),
            ),
          ],
        ),
    );
  }
}