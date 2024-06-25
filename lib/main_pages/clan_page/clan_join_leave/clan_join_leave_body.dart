import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/components/filter_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/clan/logs/join_leave.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/player_info_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';

class ClanJoinLeaveBody extends StatefulWidget {
  final List<String> user;
  final JoinLeaveClan joinLeaveClan;

  ClanJoinLeaveBody(
      {super.key, required this.user, required this.joinLeaveClan});

  @override
  ClanJoinLeaveBodyState createState() => ClanJoinLeaveBodyState();
}

class ClanJoinLeaveBodyState extends State<ClanJoinLeaveBody>
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
    if (newFilter == "reset") {
      resetDateFilter(); 
    } else {
      setState(() {
        currentFilter = newFilter;
      });
    }
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
    Map<String, String> filterOptions = {
      AppLocalizations.of(context)?.all ?? "All": "all",
      AppLocalizations.of(context)?.join ?? "Join": "join",
      AppLocalizations.of(context)?.leave ?? "Leave": "leave",
      AppLocalizations.of(context)?.reset ?? "Reset": "reset",
    };

    var filteredItems = widget.joinLeaveClan.items.where((item) => 
      (currentFilter == "all" || item.type == currentFilter) &&
      (!filterActiveUsers || widget.user.contains(item.tag)) &&
      (selectedDate == null || DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day).isAtSameMomentAs(DateTime(item.time.year, item.time.month, item.time.day)))
    ).take(100).toList();

    return Column(
      children: [
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.onSurface, size: 16),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2018, 8),
                      lastDate: DateTime(2200),
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                Spacer(),              
                FilterDropdown(
                  sortBy: currentFilter,
                  updateSortBy: updateFilter,
                  sortByOptions: filterOptions,
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.link, color: filterActiveUsers ? Colors.green : null),
                  onPressed: toggleFilterActiveUsers,
                  color: filterActiveUsers ? Colors.green : Colors.grey,
                  tooltip: 'Filter Active Users',
                ),
                SizedBox(width: 16),
              ],
            ),
            SizedBox(height: 2),
          if (filteredItems.isEmpty)
            Card(
              margin: EdgeInsets.only(top: 4, left: 16, right: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.noDataAvailable ?? "Aucun résultat trouvé.",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            )
          else
            for (var item in filteredItems)
              GestureDetector(
                onTap: () async {
                  final navigator = Navigator.of(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  );
                  ProfileInfo playerStats = await ProfileInfoService().fetchProfileInfo(item.tag);
                  while (playerStats.initialized != true) {
                  await Future.delayed(Duration(milliseconds: 100));
                }
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => StatsScreen(
                        playerStats: playerStats, discordUser: widget.user),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(
                      color: widget.user.contains(item.tag) ? Colors.green : Colors.transparent, // Vert si présent, sinon transparent
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CachedNetworkImage(
                                imageUrl: item.townHallPic,
                                width: 60, height: 60,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: Theme.of(context).textTheme.bodyLarge,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Transform.translate(
                                offset: Offset(0, -2),
                                child: Text(
                                  item.tag,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.tertiary),
                                ),
                              ),
                              Text(
                                item.type == "join"
                                  ? AppLocalizations.of(context)?.joinedOnAt(
                                    DateFormat('dd/MM/yyyy').format(item.time.toLocal()),
                                    DateFormat('HH:mm').format(item.time.toLocal())) ??
                                      "Joined on ${DateFormat('dd/MM/yyyy').format(item.time.toLocal())} at ${DateFormat('HH:mm').format(item.time.toLocal())}."
                                  : AppLocalizations.of(context)?.leftOnAt(
                                    DateFormat('dd/MM/yyyy').format(item.time.toLocal()),
                                    DateFormat('HH:mm').format(item.time.toLocal())) ??
                                      "Left on ${DateFormat('dd/MM/yyyy').format(item.time.toLocal())} at ${DateFormat('HH:mm').format(item.time.toLocal())}.",
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: item.type == "join"
                                  ? Icon(LucideIcons.logIn, size: 24, color: Colors.green)
                                  : Icon(LucideIcons.logOut, size: 24, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
