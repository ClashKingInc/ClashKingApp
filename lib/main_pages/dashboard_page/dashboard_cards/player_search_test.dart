import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:clashkingapp/api/player_name_info.dart';
import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/player_info_page.dart';
import 'dart:async';

class PlayerSearchCard extends StatefulWidget {
  const PlayerSearchCard({
    required this.discordUser,
    super.key,
  });

  final List<String> discordUser;

  @override
  PlayerSearchCardState createState() => PlayerSearchCardState();
}

class PlayerSearchCardState extends State<PlayerSearchCard> {
  late String _searchInput;
  bool _isLoading = false;

  Future<void> _handleSearch() async {
    try {
      setState(() {
        _isLoading = true;
      });
      if (_searchInput.isEmpty) {
        _showErrorDialog(
            AppLocalizations.of(context)?.noValueEntered ?? 'No value entered',
            _searchInput);
      } else if (RegExp(r'^#[PYLQGRJCUV0289]{3,9}$').hasMatch(_searchInput)) {
        PlayerAccountInfo playerStats =
            await PlayerService().fetchPlayerStats(_searchInput);
        _navigateToStatsScreen(playerStats);
      } else if (RegExp(r'^[PYLQGRJCUV0289]{3,9}$').hasMatch(_searchInput)) {
        PlayerAccountInfo playerStats =
            await PlayerService().fetchPlayerStats('#$_searchInput');
        _navigateToStatsScreen(playerStats);
      } else {
        List<PlayerNameInfo> playerNameInfo =
            await PlayerNameInfo.fetchPlayerNameInfo(_searchInput);
        if (mounted) {
          showSearchResults(context, playerNameInfo, _searchInput);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
            AppLocalizations.of(context)?.playerNotFound ?? 'Player not Found',
            _searchInput);
      }
    }
  }

  Future<void> _navigateToStatsScreen(PlayerAccountInfo playerStats) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatsScreen(
          playerStats: playerStats,
          discordUser: widget.discordUser,
        ),
      ),
    );

    setState(() {
      _isLoading = false;
    });
  }

  void _showErrorDialog(String message, String searchInput) {
    setState(() {
      _isLoading = false;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text(message)),
          content: SizedBox(
            width: 100,
            height: 90,
            child: Center(
              child: message == AppLocalizations.of(context)?.playerNotFound
                  ? Text(
                      '${AppLocalizations.of(context)?.player ?? 'Player'} ${AppLocalizations.of(context)?.notFoundOrNotLinkedToOurSystem(_searchInput) ?? 'not found or not linked to our system.'} ${AppLocalizations.of(context)?.tryAnotherNameOrTagOrLinkIt ?? 'Try another name/tag or link it.'}')
                  : null,
            ),
          ),
          actions: <Widget>[
            Center(
              child: Container(
                width: 100,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 2,
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextButton(
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)?.close ?? 'Close',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showSearchResults(BuildContext context,
      List<PlayerNameInfo> playerNameInfo, String searchInput) {
    setState(() {
      _isLoading = false;
    });
    playerNameInfo.sort((a, b) => b.th.compareTo(a.th));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        if (playerNameInfo.isEmpty) {
          return AlertDialog(
            content: SizedBox(
              width: 100,
              height: 90,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '${AppLocalizations.of(context)?.player ?? 'Player'} ${AppLocalizations.of(context)?.notFoundOrNotLinkedToOurSystem(_searchInput) ?? 'not found or not linked to our system.'} ${AppLocalizations.of(context)?.tryAnotherNameOrTagOrLinkIt ?? 'Try another name/tag or link it.'}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              Center(
                child: Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 2,
                    ),
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextButton(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)?.close ?? 'Close',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ],
          );
        } else {
          return AlertDialog(
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: playerNameInfo.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Center(
                      child: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <InlineSpan>[
                            TextSpan(text: playerNameInfo[index].name),
                            WidgetSpan(
                              child: Transform.translate(
                                offset: const Offset(0, -5),
                                child: Text(
                                  '${playerNameInfo[index].th}',
                                  style: TextStyle(
                                    fontSize: (DefaultTextStyle.of(context)
                                                .style
                                                .fontSize ??
                                            14) *
                                        0.7,
                                    height: 0.8,
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(
                                text: ' | ${playerNameInfo[index].clanName}'),
                          ],
                        ),
                      ),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return FutureBuilder<PlayerAccountInfo>(
                            future: PlayerService()
                                .fetchPlayerStats(playerNameInfo[index].tag),
                            builder: (BuildContext context,
                                AsyncSnapshot<PlayerAccountInfo> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Text(
                                    '${AppLocalizations.of(context)?.error ?? 'Error'}: ${snapshot.error}');
                              } else {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => StatsScreen(
                                        playerStats: snapshot.data!,
                                        discordUser: widget.discordUser,
                                      ),
                                    ),
                                  );
                                });
                                return Container();
                              }
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            actions: <Widget>[
              Center(
                child: Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 2,
                    ),
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextButton(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)?.close ?? 'Close',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(width: 16.0),
          Expanded(
            child: TextField(
              onChanged: (value) {
                _searchInput = value;
              },
              onSubmitted: (value) {
                _handleSearch();
              },
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)?.tagOrNamePlayer ??
                    'Player\'s tag or name',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                border: InputBorder.none,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: _isLoading
                ? SizedBox(
                    height: 24.0,
                    width: 24.0,
                    child: CircularProgressIndicator(),
                  )
                : Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            onPressed: _handleSearch,
          ),
          SizedBox(width: 16.0)
        ],
      ),
    );
  }
}
