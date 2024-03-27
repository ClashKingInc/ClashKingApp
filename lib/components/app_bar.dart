import "package:flutter/material.dart";
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
            CircleAvatar(
              backgroundImage: NetworkImage('https://cdn.discordapp.com/avatars/${user.id}/${user.avatar}.png'),
            ),
          ],
        ),
        SizedBox(width: 16), // Add some spacing on the right side
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}