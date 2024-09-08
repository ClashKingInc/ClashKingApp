import 'package:clashkingapp/main_pages/dashboard_page/dashboard_cards/player_search/player_search_results_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

class PlayerSearchCard extends StatefulWidget {
  final List<String> discordUser;

  PlayerSearchCard({required this.discordUser});
  @override
  PlayerSearchCardState createState() => PlayerSearchCardState();
}

class PlayerSearchCardState extends State<PlayerSearchCard> {
  TextEditingController _controller = TextEditingController();
  Future<List<dynamic>>? _searchResults;
  bool isSearching = false;
  bool isEmpty = true;
  Timer? _debounce;
  String lastSearch = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    try {
      if (_debounce?.isActive ?? false) _debounce?.cancel();

      isEmpty = _controller.text.isEmpty;

      _debounce = Timer(const Duration(seconds: 1), () {
        if (_controller.text != lastSearch) {
          if (!isEmpty) {
            setState(() {
              isSearching = true;
            });
          }
          _searchResults = _searchPlayerByTag(_controller.text);
          _searchResults!.whenComplete(() {
            setState(() {
              isSearching = false;
            });
          });
          lastSearch = _controller.text;
        }
      });
    } catch (exception, stackTrace) {
      Sentry.captureException(exception, stackTrace: stackTrace);
      Sentry.captureMessage('Error in search, search: ${_controller.text}, searchResults: $_searchResults');
    }
  }

  Future<List<dynamic>> _searchPlayerByTag(String query) async {
    dynamic response;
    if (RegExp(r'^#[PYLQGRJCUV0289]{3,9}$').hasMatch(query) ||
        RegExp(r'^[PYLQGRJCUV0289]{3,9}$').hasMatch(query)) {
      query = query.replaceFirst('#', '!');
      response = await http
          .get(Uri.parse('https://api.clashking.xyz/v1/players/$query'));
    } else {
      response = await http
          .get(Uri.parse('https://api.clashking.xyz/player/search/$query'));
    }

    if (query.isEmpty || query.length < 3) {
      isSearching = false;
      return [];
    }

    if (response.statusCode == 200) {
      var body = utf8.decode(response.bodyBytes);
      var data = jsonDecode(body);
      if (data.containsKey('items')) {
        return data['items'];
      } else {
        return [data];
      }
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: AppLocalizations.of(context)!.searchPlayer,
                hintText: AppLocalizations.of(context)!.nameOrTagPlayer,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                suffixIcon: IntrinsicWidth(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      isSearching
                          ? SizedBox(
                              width: 20.0,
                              height: 20.0,
                              child: CircularProgressIndicator(),
                            )
                          : !isEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() {
                                      isSearching = false;
                                    });
                                  },
                                )
                              : Icon(
                                  Icons.search,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                      SizedBox(width: 8.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          FutureBuilder<List<dynamic>>(
            future: _searchResults,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox.shrink();
              } else if (snapshot.hasError) {
                return Center(child: Text("No results found."));
              } else if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data != [] &&
                  snapshot.data!.isNotEmpty) {
                return SingleChildScrollView(
                    child: Column(
                  children: snapshot.data!.map<Widget>((player) {
                    return PlayerSearchResultTile(
                        player: player, user: widget.discordUser);
                  }).toList(),
                ));
              } else {
                if (_controller.text.length >= 2) {
                  return Column(
                    children: [
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!.noResult,
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  );
                } else {
                  return SizedBox.shrink();
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
