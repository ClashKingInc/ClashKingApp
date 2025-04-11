import 'dart:convert';
import 'package:clashkingapp/features/pages/widgets/clan_search_filters_dialog.dart';
import 'package:clashkingapp/features/pages/widgets/clan_search_result_tiles.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:clashkingapp/l10n/app_localizations.dart';

class ClanSearchCard extends StatefulWidget {
  const ClanSearchCard({super.key});

  @override
  ClanSearchCardState createState() => ClanSearchCardState();
}

class ClanSearchCardState extends State<ClanSearchCard> {
  final TextEditingController _controller = TextEditingController();
  Future<List<dynamic>>? _searchResults;
  bool isSearching = false;
  bool isEmpty = true;
  Timer? _debounce;
  String lastSearch = '';
  String searchFilters = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    isEmpty = _controller.text.isEmpty;

    _debounce = Timer(const Duration(seconds: 1), () {
      if (_controller.text != lastSearch) {
        if (!isEmpty) {
          setState(() {
            isSearching = true;
          });
        }
        String query = '';
        if (_controller.text != '' && _controller.text.startsWith('#')) {
          query = "name=${_controller.text.replaceFirst("#", "%23")}";
        } else if (_controller.text != '') {
          query = "name=${_controller.text}";
        }
        _searchResults = _searchClans("$query$searchFilters");
        _searchResults!.whenComplete(() {
          setState(() {
            isSearching = false;
          });
        });
        lastSearch = _controller.text;
      }
    });
  }

  Future<List<dynamic>> _searchClans(String query) async {
    if (query.isEmpty || query.length < 8) {
      isSearching = false;
      return [];
    }
    final response = await http.get(Uri.parse(
        'https://proxy.clashk.ing/v1/clans?$query&limit=20&memberList=false'));

    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      final data = jsonDecode(body);
      return data['items'];
    } else {
      throw Exception('Failed to load clans with status code: ${response.statusCode}');
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
                labelText: AppLocalizations.of(context)!.searchClan,
                hintText: AppLocalizations.of(context)!.clanName,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                suffixIcon: IntrinsicWidth(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: () {
                            showDialog<String>(
                              context: context,
                              builder: (BuildContext context) {
                                return ClanSearchFilters();
                              },
                            ).then((String? filters) {
                              if (filters != null) {
                                setState(() {
                                  String query = '';
                                  if (_controller.text != '') {
                                    if (_controller.text.startsWith('#')) {
                                      query =
                                          "name=${_controller.text.replaceFirst("#", "%23")}$filters";
                                    } else {
                                      query = "name=${_controller.text}$filters";
                                    }
                                  } else {
                                    query = filters.replaceFirst('&', '');
                                  }
                                  searchFilters = filters;
                                  _searchResults = _searchClans(query);
                                });
                              }
                            });
                          },
                          color: Theme.of(context).colorScheme.onSurface),
                      isSearching
                          ? const SizedBox(
                              width: 20.0,
                              height: 20.0,
                              child: CircularProgressIndicator(),
                            )
                          : !isEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                                  onPressed: () {
                                    searchFilters = '';
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
                      const SizedBox(width: 8.0),
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
                return const SizedBox.shrink();
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.isNotEmpty) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final clan = snapshot.data![index];
                    return ClanSearchResultTile(clan: clan);
                  },
                );
              } else {
                if (_controller.text.length >= 2) {
                  return Column(children: [
                    Center(child: Text(AppLocalizations.of(context)!.noResult)),
                    const SizedBox(height: 8)
                  ]);
                } else {
                  return const SizedBox.shrink();
                }
              }
            },
          ),
        ],
      ),
    );
  }
}