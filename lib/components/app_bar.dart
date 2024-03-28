import 'package:flutter/material.dart';
import 'package:clashkingapp/global_keys.dart'; // Make sure to import global_keys.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clashkingapp/main_pages/login_page.dart';
import 'package:clashkingapp/api/user_data.dart';
import 'package:clashkingapp/main.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final DiscordUser user;

  CustomAppBar({required this.user});

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  String? selectedTag;

  @override
  void initState() {
    super.initState();
    _loadSelectedTag();
    if (widget.user.tags.isNotEmpty) {
      selectedTag = widget.user.tags.first;
    }
  }

  Future<void> _loadSelectedTag() async {
    final prefs = await SharedPreferences.getInstance();
    selectedTag = prefs.getString('selectedTag');
  }

  Future<void> _saveSelectedTag() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedTag', selectedTag!);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: DropdownButton<String>(
        value: selectedTag,
        icon: Icon(Icons.arrow_downward),
        iconSize: 24,
        elevation: 16,
        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        underline: Container(
          height: 2,
          color: Theme.of(context).colorScheme.secondary,
        ),
        onChanged: (String? newValue) async {
          setState(() {
            selectedTag = newValue;
            _saveSelectedTag();
          });
          // Call the functions that fetch the data
          var appState = Provider.of<MyAppState>(context, listen: false);
          await appState.fetchPlayerStats();
          await appState.fetchClanInfo();
          await appState.fetchCurrentWarInfo();
        },
        items: widget.user.tags.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
      actions: <Widget>[
        Row(
          children: <Widget>[
            SizedBox(width: 8), // Add some spacing
            Text(widget.user.globalName),
            Padding(padding: EdgeInsets.all(5)),
            GestureDetector(
              onTap: () async {
                await _logOut();
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

  Future<void> _logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('expiration_date');

    // Use the globalNavigatorKey to navigate
    globalNavigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}
