import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/my_app.dart';
import 'package:clashkingapp/main_pages/settings_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:clashkingapp/components/app_bar/add_player_card.dart';
import 'package:clashkingapp/components/app_bar/delete_player_card.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final DiscordUser user;

  CustomAppBar({required this.user});

  @override
  CustomAppBarState createState() => CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class CustomAppBarState extends State<CustomAppBar> {
  String? selectedTag;

  @override
  void initState() {
    super.initState();
    _loadSelectedTag().then((_) {
      if (selectedTag == null ||
          !widget.user.selectedTagDetails
              .any((details) => details['tag'] == selectedTag)) {
        setState(() {
          selectedTag = widget.user.selectedTagDetails.isNotEmpty
              ? widget.user.selectedTagDetails.first['tag']
              : null;
          _saveSelectedTag(selectedTag!);
        });
      }
    });
  }

  Future<void> _loadSelectedTag() async {
    final prefs = await SharedPreferences.getInstance();
    selectedTag = prefs.getString('selectedTag');
  }

  Future<void> _saveSelectedTag(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedTag', tag);
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context);
    widget.user.selectedTagDetails
        .sort((a, b) => b['townHallLevel'].compareTo(a['townHallLevel']));
    print(widget.user.selectedTagDetails);
    return AppBar(
      automaticallyImplyLeading: false,
      title: appState.isLoading
          ? Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<String?>(
              valueListenable: appState.selectedTag,
              builder: (context, selectedTag, child) {
                return DropdownButton<String>(
                    value: selectedTag,
                    elevation: 16,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                    underline: Container(),
                    onChanged: (String? newValue) async {
                      if (newValue != "manageAccounts") {
                        await _saveSelectedTag(newValue!);
                        appState.selectedTag.value = newValue;
                      } else {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            // Declare stateful values inside the builder
                            int currentSegment = 0;
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: Text(AppLocalizations.of(context)
                                          ?.manageAccounts ??
                                      'Manage Accounts'),
                                  content: SingleChildScrollView(
                                    // Add this
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CustomSlidingSegmentedControl<int>(
                                          children: {
                                            0: Text(AppLocalizations.of(context)
                                                    ?.add ??
                                                'Add'),
                                            1: Text(AppLocalizations.of(context)
                                                    ?.delete ??
                                                'Delete'),
                                          },
                                          initialValue: currentSegment,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          thumbDecoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(.3),
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
                                          onValueChanged: (newValue) {
                                            setState(() {
                                              currentSegment = newValue;
                                            });
                                          },
                                        ),
                                        SizedBox(height: 4),
                                        currentSegment == 1
                                            ? DeletePlayerCard(
                                                user: widget.user)
                                            : AddPlayerCard(
                                                userId: widget.user.id),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      }
                    },
                    items: [
                      ...widget.user.selectedTagDetails
                          .map<DropdownMenuItem<String>>((details) {
                        String tag = details['tag'];
                        String imageUrl = details['imageUrl'];
                        String name = details['name'];
                        return DropdownMenuItem<String>(
                          value: tag,
                          child: Row(
                            children: <Widget>[
                              SizedBox(
                                height: 30,
                                width: 30,
                                child: CachedNetworkImage(imageUrl: imageUrl),
                              ),
                              SizedBox(width: 4),
                              Text(name,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface)),
                            ],
                          ),
                        );
                      }).toList(),
                      DropdownMenuItem<String>(
                        value: "manageAccounts",
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.settings),
                            SizedBox(width: 4),
                            Text(
                                AppLocalizations.of(context)?.manageAccounts ??
                                    'Manage Accounts',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface)),
                          ],
                        ),
                      ),
                    ]);
              },
            ),
      actions: <Widget>[
        Row(
          children: <Widget>[
            SizedBox(width: 8), // Add some spacing
            Text(widget.user.globalName),
            Padding(padding: EdgeInsets.all(5)),
            GestureDetector(
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SettingsInfoScreen(user: widget.user)),
                );
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                    'https://cdn.discordapp.com/avatars/${widget.user.id}/${widget.user.avatar}.png'),
              ),
            ),
          ],
        ),
        SizedBox(width: 16), // Add some spacing on the right side
      ],
    );
  }
}
