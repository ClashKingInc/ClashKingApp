import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/pages/widgets/war_card.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ClanWarLog extends StatefulWidget {
  final Clan clan;
  final List<String> selectedTypes;

  const ClanWarLog({
    super.key,
    required this.clan,
    required this.selectedTypes,
  });

  @override
  ClanWarLogState createState() => ClanWarLogState();
}

class ClanWarLogState extends State<ClanWarLog> {
  String? selectedFilter;
  String formatDate(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final format = locale == 'jp' ? 'yyyy/MM/dd' : 'dd/MM/yyyy';
    return DateFormat(format).format(date);
  }

  List<WarInfo> getFilteredWarLogData() {
    List<WarInfo> filteredData = widget.clan.clanWarStats?.wars
            .where((war) =>
                war.warDetails.warType != null &&
                widget.selectedTypes
                    .contains(war.warDetails.warType!.toLowerCase()))
            .map((war) => war.warDetails)
            .toList() ??
        [];

    if (selectedFilter == null) {
      return filteredData;
    }

    switch (selectedFilter) {
      case 'victory':
        return filteredData
            .where((war) => war.getWarResult(widget.clan.tag) == 'won')
            .toList();
      case 'defeat':
        return filteredData
            .where((war) => war.getWarResult(widget.clan.tag) == 'lost')
            .toList();
      case 'draw':
        return filteredData
            .where((war) => war.getWarResult(widget.clan.tag) == 'tie')
            .toList();
      case 'perfectWar':
        return filteredData
            .where((war) => war.getWarResult(widget.clan.tag) == 'perfectWar')
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
        return filteredData.where((war) => war.teamSize == teamSize).toList();
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
                  MobileWebImage(
                    imageUrl: ImageAssets.villager,
                    height: 250,
                    width: 200,
                  ),
                ],
              )
            : buildAllLog(context, filteredWarLogData, widget.clan.tag),
      ],
    );
  }

  Widget buildAllLog(
      BuildContext context, List<WarInfo> warLogData, String clanTag) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 2),
          Center(
            child: Column(
              children: List<Widget>.generate(warLogData.length, (index) {
                final war = warLogData[index];
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
                    WarCwlService.fetchWarDataFromTime(
                            widget.clan.tag, war.endTime ?? DateTime.now())
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
                            builder: (context) =>
                                WarScreen(war: currentWarInfo),
                          ),
                        );
                      }
                    }).catchError((error, stackTrace) {
                      Sentry.captureException(error, stackTrace: stackTrace);
                      return null;
                    });
                  },
                  child: WarCard(
                    clanTag: clanTag,
                    currentWarInfo: war,
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
