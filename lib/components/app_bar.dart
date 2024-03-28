import 'package:flutter/material.dart';
import 'package:clashkingapp/global_keys.dart'; // Make sure to import global_keys.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clashkingapp/main_pages/login_page.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/my_app.dart';

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
    _loadSelectedTag().then((_) {
      print('Selected tag: $selectedTag');
      if (selectedTag == null && widget.user.tags.isNotEmpty) {
        setState(() {
          selectedTag = widget.user.tags.first;
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
    print('Saving selected tag: $tag');
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedTag', tag);
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context, listen: false);
    return AppBar(
      title: ValueListenableBuilder<String?>(
        valueListenable: appState.selectedTag,
        builder: (context, selectedTag, child) {
          return DropdownButton<String>(
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
              await _saveSelectedTag(newValue!);
              appState.selectedTag.value = newValue;
            },
            items:
                widget.user.tags.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          );
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
