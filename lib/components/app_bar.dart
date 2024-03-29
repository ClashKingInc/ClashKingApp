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
    widget.user.selectedTagDetails
        .sort((a, b) => b['townHallLevel'].compareTo(a['townHallLevel']));
    return AppBar(
      title: ValueListenableBuilder<String?>(
        valueListenable: appState.selectedTag,
        builder: (context, selectedTag, child) {
          return DropdownButton<String>(
            value: selectedTag,
            elevation: 16,
            dropdownColor: Theme.of(context).colorScheme.surface,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            underline: Container(
            ),
            onChanged: (String? newValue) async {
              await _saveSelectedTag(newValue!);
              appState.selectedTag.value = newValue;
            },
            items: widget.user.selectedTagDetails
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
                      child: Image.network(imageUrl),
                    ),
                    SizedBox(width: 4),
                    Text(name,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface)),
                  ],
                ),
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
