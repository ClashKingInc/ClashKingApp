import 'package:flutter/material.dart';
import 'package:clashkingapp/global_keys.dart'; // Make sure to import global_keys.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clashkingapp/main_pages/login_page.dart';
import 'package:clashkingapp/api/user_data.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DiscordUser user;

  CustomAppBar({required this.user});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actions: <Widget>[
        Row(
          children: <Widget>[
            Text(user.globalName),
            SizedBox(width: 8), // Add some spacing
            GestureDetector(
              onTap: () async {
                await _logOut();
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage('https://cdn.discordapp.com/avatars/${user.id}/${user.avatar}.png'),
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

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
