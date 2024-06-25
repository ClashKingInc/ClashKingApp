import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/account/user.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/my_app_state.dart';
import 'package:clashkingapp/main_pages/settings_page/settings_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:clashkingapp/components/app_bar/add_player_card.dart';
import 'package:clashkingapp/components/app_bar/delete_player_card.dart';
import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final User user;
  final Accounts accounts;

  CustomAppBar({required this.user, required this.accounts});

  @override
  CustomAppBarState createState() => CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class CustomAppBarState extends State<CustomAppBar> {
  late ValueNotifier<bool> _initializedNotifier;

  @override
  void initState() {
    super.initState();
    _initializedNotifier = ValueNotifier(false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      var appState = Provider.of<MyAppState>(context, listen: false);
      if (appState.selectedTagNotifier.value == null &&
          widget.accounts.accounts.isNotEmpty) {
        appState.selectedTagNotifier.value =
            widget.accounts.accounts.first.profileInfo.tag;
        appState.account = widget.accounts.accounts.first;
      }
      _checkInitialization(widget.accounts);
    });
  }

  Future<void> _saveSelectedTag(String? newValue) async {
    if (newValue != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      print('Saving selectedTag: $newValue');
      await prefs.setString('selectedTag', newValue);
    }
  }

  void _checkInitialization(Accounts accounts) {
    bool allInitialized =
        accounts.accounts.every((account) => account.profileInfo.initialized);

    if (!allInitialized) {
      Future.delayed(Duration(milliseconds: 100), () {
        _checkInitialization(accounts);
      });
    } else {
      _initializedNotifier.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context);

    return AppBar(
      automaticallyImplyLeading: false,
      title: ValueListenableBuilder<String?>(
        valueListenable: appState.selectedTagNotifier,
        builder: (context, selectedTag, child) {
          return ValueListenableBuilder<bool>(
            valueListenable: _initializedNotifier,
            builder: (context, initialized, child) {
              return DropdownButton<String>(
                value: selectedTag,
                elevation: 16,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                underline: Container(),
                onChanged: (String? newValue) async {
                  if (newValue != "manageAccounts") {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        appState.selectedTagNotifier.value = newValue;
                        appState.account =
                            appState.accounts!.accounts.firstWhere(
                          (element) => element.profileInfo.tag == newValue,
                        );
                      });
                      _checkInitialization(appState.accounts!);
                      _saveSelectedTag(newValue);
                    });
                  } else {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        int currentSegment = 0;
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return AlertDialog(
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                              title: Text(
                                  AppLocalizations.of(context)?.manage ??
                                      'Manage'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomSlidingSegmentedControl<int>(
                                      children: {
                                        0: Text(
                                            AppLocalizations.of(context)?.add ??
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
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      thumbDecoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(.3),
                                            blurRadius: 4.0,
                                            spreadRadius: 1.0,
                                            offset: Offset(0.0, 2.0),
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
                                            user: widget.user,
                                            accounts: widget.accounts)
                                        : AddPlayerCard(user: widget.user),
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
                  ...widget.accounts.accounts
                      .map<DropdownMenuItem<String>>((Account account) {
                    String tag = account.profileInfo.tag;
                    String imageUrl = account.profileInfo.townHallPic;
                    String name = account.profileInfo.name;
                    return DropdownMenuItem<String>(
                      value: tag,
                      child: Row(
                        children: <Widget>[
                          if (account.profileInfo.initialized)
                            SizedBox(
                              height: 30,
                              width: 30,
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                placeholder: (context, url) => 
                                    CircularProgressIndicator(),
                                errorWidget: (context, url, error) => 
                                    Icon(Icons.error),
                              ),
                            )
                          else
                            SizedBox(height: 30, width: 30),
                          SizedBox(width: 4),
                          Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
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
                        Text(AppLocalizations.of(context)?.manage ?? 'Manage'),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      actions: <Widget>[
        Row(
          children: <Widget>[
            Text(
              widget.user.globalName,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
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
                backgroundImage: NetworkImage(widget.user.avatar),
                backgroundColor: Colors.transparent,
              ),
            ),
          ],
        ),
        SizedBox(width: 16),
      ],
    );
  }
}
