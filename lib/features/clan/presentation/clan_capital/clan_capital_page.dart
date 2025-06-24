import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_capital/clan_capital_header.dart';
import 'package:clashkingapp/features/clan/presentation/clan_capital/clan_capital_raid.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ClanCapitalScreen extends StatefulWidget {
  final Clan clanInfo;
  ClanCapitalScreen({super.key, required this.clanInfo});

  @override
  ClanCapitalScreenState createState() => ClanCapitalScreenState();
}

class ClanCapitalScreenState extends State<ClanCapitalScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  late DateTime selectedWeek;
  bool filterAccountActive = false;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    selectedWeek = _getStartOfWeek(DateTime.now());
  }

  DateTime _getStartOfWeek(DateTime date) {
    int dayOfWeek = date.weekday;
    DateTime startOfWeek = date.subtract(
        Duration(days: (dayOfWeek + 1) % 7)); // Adjust the day to Friday
    return startOfWeek;
  }

  void incrementWeek() {
    setState(() {
      selectedWeek = selectedWeek.add(Duration(days: 7));
    });
  }

  void decrementWeek() {
    setState(() {
      selectedWeek = selectedWeek.subtract(Duration(days: 7));
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final activeUserTags = cocService.getAccountTags();

    if (widget.clanInfo.clanCapitalRaid != null &&
        widget.clanInfo.clanCapitalRaid!.items.isNotEmpty) {
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              ClanCapitalHeader(
                user: activeUserTags,
                clanInfo: widget.clanInfo,
              ),
              ClanCapitalRaid(clanInfo: widget.clanInfo),
            ],
          ),
        ),
      );
    } else {
      return Column(
        children: [
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context)?.generalNoDataAvailable ??
                    'No data available',
              ),
            ),
          ),
          SizedBox(height: 32),
          CachedNetworkImage(
            errorWidget: (context, url, error) => Icon(Icons.error),
            imageUrl: ImageAssets.villager,
            height: 250,
            width: 200,
          ),
        ],
      );
    }
  }
}
