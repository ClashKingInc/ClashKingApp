import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/pages/widgets/player_search_result_tile.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

class PlayerSearchCard extends StatefulWidget {
  PlayerSearchCard({super.key});
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
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    try {
      if (_debounce?.isActive ?? false) _debounce?.cancel();

      isEmpty = _controller.text.isEmpty;

      _debounce = Timer(const Duration(seconds: 1), () {
        if (_controller.text != lastSearch) {
          if (!isEmpty && mounted) {
            setState(() {
              isSearching = true;
            });
          }
          _searchResults = _searchPlayerByTag(_controller.text);
          _searchResults!.whenComplete(() {
            if (mounted) {
              setState(() {
                isSearching = false;
              });
            }
          });
          lastSearch = _controller.text;
        }
      });
    } catch (exception, stackTrace) {
      Sentry.captureException(exception, stackTrace: stackTrace);
      Sentry.captureMessage(
          'Error in search, search: ${_controller.text}, searchResults: $_searchResults');
    }
  }

  Future<List<dynamic>> _searchPlayerByTag(String query) async {
    try {
      if (query.isEmpty || query.length < 3) {
        return [];
      }

      dynamic response;
      const timeout = Duration(seconds: 10);
      
      if (RegExp(r'^#[PYLQGRJCUV0289]{3,9}$').hasMatch(query) ||
          RegExp(r'^[PYLQGRJCUV0289]{3,9}$').hasMatch(query)) {
        query = query.replaceFirst('#', '!');
        response = await http
            .get(Uri.parse('${ApiService.proxyUrl}/players/$query'))
            .timeout(timeout);
      } else {
        response = await http
            .get(Uri.parse('${ApiService.apiUrlV1}/player/full-search/$query'))
            .timeout(timeout);
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
        Sentry.captureMessage('Search API returned status ${response.statusCode} for query: $query');
        return [];
      }
    } catch (exception, stackTrace) {
      Sentry.captureException(exception, stackTrace: stackTrace);
      Sentry.captureMessage('Error searching for player: $query');
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
                labelText: AppLocalizations.of(context)!.playerSearchTitle,
                hintText: AppLocalizations.of(context)!.playerSearchPlaceholder,
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
                                    if (mounted) {
                                      setState(() {
                                        isSearching = false;
                                      });
                                    }
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
                    return PlayerSearchResultTile(player: player);
                  }).toList(),
                ));
              } else {
                if (_controller.text.length >= 2) {
                  return Column(
                    children: [
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!.searchNoResult,
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
