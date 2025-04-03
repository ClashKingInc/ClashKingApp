import 'package:clashkingapp/classes/clan/war_league/current_war_info.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/current_war_info_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/clan/war_league/war_log.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class WarLogHistoryTab extends StatefulWidget {
  final List<String> discordUser;
  final String clanTag;
  final List<WarLogDetails> warLogData;

  const WarLogHistoryTab({
    super.key,
    required this.discordUser,
    required this.clanTag,
    required this.warLogData,
  });

  @override
  WarLogHistoryTabState createState() => WarLogHistoryTabState();
}

class WarLogHistoryTabState extends State<WarLogHistoryTab> {
  String? selectedFilter;
  String formatDate(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final format = locale == 'jp' ? 'yyyy/MM/dd' : 'dd/MM/yyyy';
    return DateFormat(format).format(date);
  }

  List<WarLogDetails> getFilteredWarLogData() {
    List<WarLogDetails> filteredData = widget.warLogData
        .where((warLogDetail) => warLogDetail.attacksPerMember == 2)
        .toList();
    if (selectedFilter == null) {
      return filteredData;
    }

    switch (selectedFilter) {
      case 'victory':
        return filteredData
            .where((warLogDetail) => warLogDetail.result == 'win')
            .toList();
      case 'defeat':
        return filteredData
            .where((warLogDetail) => warLogDetail.result == 'lose')
            .toList();
      case 'draw':
        return filteredData
            .where((warLogDetail) => warLogDetail.result == 'tie')
            .toList();
      case 'perfectWar':
        return filteredData
            .where((warLogDetail) =>
                (warLogDetail.clan.destructionPercentage == 100 ||
                    warLogDetail.opponent.destructionPercentage == 100))
            .toList();
      case 'newest':
        return filteredData;
      case 'oldest':
        return filteredData.reversed.toList();
      case '5':
      case '10':
      case '15':
      case '20':
      case '25':
      case '30':
      case '40':
      case '50':
        final teamSize = int.parse(selectedFilter!);
        return filteredData
            .where((warLogDetail) => warLogDetail.teamSize == teamSize)
            .toList();
      default:
        return filteredData;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredWarLogData = getFilteredWarLogData();

    return Column(
      children: [
        FilterDropdown(
          sortBy: selectedFilter ?? 'newest',
          updateSortBy: (String newValue) {
            setState(() {
              selectedFilter = newValue;
            });
          },
          sortByOptions: {
            AppLocalizations.of(context)?.newest ?? 'Newest': 'newest',
            AppLocalizations.of(context)?.oldest ?? 'Oldest': 'oldest',
            AppLocalizations.of(context)?.victory ?? 'Victory': 'victory',
            AppLocalizations.of(context)?.defeat ?? 'Defeat': 'defeat',
            AppLocalizations.of(context)?.draw ?? 'Draw': 'draw',
            AppLocalizations.of(context)?.perfectWar ?? 'Perfect War':
                'perfectWar',
            '5v5': '5',
            '10v10': '10',
            '15v15': '15',
            '20v20': '20',
            '25v25': '25',
            '30v30': '30',
            '40v40': '40',
            '50v50': '50',
          },
        ),
        SizedBox(height: 2),
        filteredWarLogData.isEmpty
            ? Column(
                children: [
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                          AppLocalizations.of(context)?.noDataAvailable ??
                              'No data available'),
                    ),
                  ),
                  SizedBox(height: 32),
                  CachedNetworkImage(
                    imageUrl:
                        'https://assets.clashk.ing/stickers/Villager_HV_Villager_7.png',
                    height: 250,
                    width: 200,
                  ),
                ],
              )
            : buildAllLog(context, filteredWarLogData),
      ],
    );
  }

  Widget buildAllLog(BuildContext context, List<WarLogDetails> warLogData) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 2),
          Center(
            child: Column(
              children: List<Widget>.generate(warLogData.length, (index) {
                final warLogDetail = warLogData[index];
                final navigator = Navigator.of(context);

                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    );
                    CurrentWarService.fetchWarDataFromTime(
                            widget.clanTag, warLogDetail.endTime)
                        .then((currentWarInfo) {
                      navigator.pop();
                      if (currentWarInfo == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Center(
                                child: Text(
                                  AppLocalizations.of(context)
                                          ?.noDataAvailableForThisWar ??
                                      'No data available for this war',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                                ),
                              ),
                              duration: Duration(seconds: 1),
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                            ),
                          );
                        }
                      } else {
                        navigator.push(
                          MaterialPageRoute(
                            builder: (context) => CurrentWarInfoScreen(
                              currentWarInfo: currentWarInfo,
                              discordUser: widget.discordUser,
                            ),
                          ),
                        );
                      }
                    }).catchError((error, stackTrace) {
                      Sentry.captureException(error, stackTrace: stackTrace);
                      return null;
                    });
                  },
                  child: Card(
                    margin:
                        EdgeInsets.only(top: 4, bottom: 4, left: 4, right: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
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
                                      child: CachedNetworkImage(
                                          imageUrl:
                                              warLogDetail.clan.badgeUrls.large,
                                          fit: BoxFit.cover),
                                    ),
                                    Text(warLogDetail.clan.name,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                        formatDate(
                                            warLogDetail.endTime, context),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold)),
                                    Text(
                                      warLogDetail.result == 'win'
                                          ? AppLocalizations.of(context)
                                                  ?.victory ??
                                              'Victory'
                                          : warLogDetail.result == 'lose'
                                              ? AppLocalizations.of(context)
                                                      ?.defeat ??
                                                  'Defeat'
                                              : AppLocalizations.of(context)
                                                      ?.draw ??
                                                  'Draw',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  warLogDetail.result == 'win'
                                                      ? Colors.green
                                                      : warLogDetail.result ==
                                                              'lose'
                                                          ? Colors.red
                                                          : Colors.blue),
                                    ),
                                    Text(
                                        '${warLogDetail.clan.stars.toString().padRight(2, ' ')} - ${warLogDetail.opponent.stars.toString().padRight(2, ' ')} ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold)),
                                    Text(
                                        '${warLogDetail.clan.destructionPercentage % 1 == 0 ? warLogDetail.clan.destructionPercentage.toInt().toString().padLeft(6, ' ') : warLogDetail.clan.destructionPercentage.toStringAsFixed(2).padLeft(5, '0')}%    ${warLogDetail.opponent.destructionPercentage % 1 == 0 ? ('${warLogDetail.opponent.destructionPercentage.toInt()}%').padRight(7, ' ') : ('${warLogDetail.opponent.destructionPercentage.toStringAsFixed(2)}%').padLeft(5, ' ')}'),
                                    SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CachedNetworkImage(
                                            imageUrl:
                                                'https://assets.clashk.ing/icons/Icon_HV_XP.png',
                                            width: 20,
                                            height: 20),
                                        Text(
                                            ' +${warLogDetail.clan.expEarned}'),
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
                                      child: CachedNetworkImage(
                                          imageUrl: warLogDetail
                                              .opponent.badgeUrls.large,
                                          fit: BoxFit.cover),
                                    ),
                                    Text(warLogDetail.opponent.name,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
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
