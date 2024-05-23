import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:clashkingapp/main_pages/clan_page/clan_info_page/clan_info_page.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/main_pages/clan_page/component/clan_info_card.dart';

class ClanSearch extends StatefulWidget {
  @override
  _ClanSearchState createState() => _ClanSearchState();
}

class _ClanSearchState extends State<ClanSearch> {
  TextEditingController _controller = TextEditingController();
  Future<List<dynamic>>? _searchResults;
  bool isLoading = false;
  Timer? _debounce;

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
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      setState(() {
        isLoading = true;
      });
      _searchResults = _searchClans(_controller.text);
      _searchResults!.whenComplete(() {
        setState(() {
          isLoading = false;
        });
      });
    });
  }

  Future<List<dynamic>> _searchClans(String query) async {
    print('Searching for $query');
    if (query.isEmpty || query.length < 2) {
      return [];
    }

    var response = await http.get(Uri.parse(
        'https://api.clashking.xyz/clan/search?minMembers=$query&limit=20&memberList=false'));

    print('Response: ${response.body}');

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['items'];
    } else {
      throw Exception('Failed to load clans');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Search Clan",
                suffixIcon: isLoading
                    ? Container(
                        width: 20.0,
                        height: 20.0,
                        padding: EdgeInsets.all(10.0),
                        child: CircularProgressIndicator(),
                      )
                    : Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
              ),
            ),
          ),
          FutureBuilder<List<dynamic>>(
            future: _searchResults,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                isLoading = true;
                return SizedBox.shrink();
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (snapshot.hasData) {
                return SingleChildScrollView(
                  child: Column(
                    children: snapshot.data!.map<Widget>((clan) {
                      ClanInfo clanInfo = ClanInfo.fromJson(clan);
                      print('Clan Info: $clanInfo');
                      return Column(children: [
                        Container(
                          height: 100, // Adjust this value as needed
                          child: GestureDetector(
                            onTap: () {
                              /*Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ClanInfoScreen(
                                      clanInfo: clanInfo, discordUser: [])),
                              );*/
                            },
                            child: Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 8.0),
                                child: ClanInfoCard(clanInfo: clanInfo)),
                          ),
                        )
                      ]);
                    }).toList(),
                  ),
                );
              } else {
                if (_controller.text.length >= 2) {
                  return Center(child: Text("No clans found"));
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
