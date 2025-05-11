import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan_join_leave.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ClanJoinLeaveEvents extends StatefulWidget {
  final ClanJoinLeave? joinLeaveClan;

  const ClanJoinLeaveEvents({
    super.key,
    required this.joinLeaveClan,
  });

  @override
  ClanJoinLeaveEventsState createState() => ClanJoinLeaveEventsState();
}

class ClanJoinLeaveEventsState extends State<ClanJoinLeaveEvents>
    with SingleTickerProviderStateMixin {
  String currentFilter = "all";
  bool filterActiveUsers = false;
  DateTime? selectedDate;

  void toggleFilterActiveUsers() {
    setState(() {
      filterActiveUsers = !filterActiveUsers;
    });
  }

  void updateFilter(String newFilter) {
    setState(() {
      currentFilter = newFilter;
    });
  }

  void resetDateFilter() {
    setState(() {
      selectedDate = null;
      currentFilter = "all";
      filterActiveUsers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cocService = context.watch<CocAccountService>();
    final activeUserTags = cocService.getAccountTags();

    Map<String, String> filterOptions = {
      loc.all: "all",
      loc.join: "join",
      loc.leave: "leave",
    };

    var filteredItems = widget.joinLeaveClan?.joinLeaveList
            .where((item) =>
                (currentFilter == "all" || item.type == currentFilter) &&
                (!filterActiveUsers || activeUserTags.contains(item.tag)) &&
                (selectedDate == null ||
                    DateTime(selectedDate!.year, selectedDate!.month,
                            selectedDate!.day)
                        .isAtSameMomentAs(DateTime(
                            item.time.year, item.time.month, item.time.day))))
            .take(100)
            .toList() ??
        [];

    return Column(
      children: [
        // Filters
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.calendar_today, size: 24),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2018, 8),
                      lastDate: DateTime(2200),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                IconButton(
                  icon: Icon(LucideIcons.listRestart),
                  onPressed: resetDateFilter,
                  tooltip: loc.reset,
                ),
              ],
            ),
            FilterDropdown(
              sortBy: currentFilter,
              updateSortBy: updateFilter,
              sortByOptions: filterOptions,
            ),
            Row(
              children: [
                SizedBox(
                  width: 48,
                ),
                IconButton(
                  icon: Icon(Icons.link,
                      color: filterActiveUsers ? Colors.green : null, size: 24),
                  onPressed: toggleFilterActiveUsers,
                  tooltip: 'Filter Active Users',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // No results
        if (filteredItems.isEmpty)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(loc.noDataAvailable,
                    style: Theme.of(context).textTheme.labelLarge),
              ),
            ),
          )
        else
          for (var item in filteredItems)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(
                  color: activeUserTags.contains(item.tag)
                      ? Colors.green
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                leading: MobileWebImage(
                  imageUrl: ImageAssets.townHall(item.th),
                  width: 48,
                  height: 48,
                ),
                title: Text(item.name,
                    style: Theme.of(context).textTheme.bodyLarge),
                subtitle: Text(
                  item.type == "join"
                      ? loc.joinedOnAt(
                          DateFormat.yMMMd(
                                  Localizations.localeOf(context).languageCode)
                              .format(item.time),
                          DateFormat.Hm().format(item.time),
                        )
                      : loc.leftOnAt(
                          DateFormat.yMMMd(
                                  Localizations.localeOf(context).languageCode)
                              .format(item.time),
                          DateFormat.Hm().format(item.time),
                        ),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                trailing: Icon(
                  item.type == "join" ? LucideIcons.logIn : LucideIcons.logOut,
                  color: item.type == "join" ? Colors.green : Colors.red,
                ),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                  Player player =
                      await PlayerService().getPlayerAndClanData(item.tag);
                  navigator.pop();
                  navigator.push(MaterialPageRoute(
                      builder: (_) => PlayerScreen(selectedPlayer: player)));
                },
              ),
            ),
      ],
    );
  }
}
