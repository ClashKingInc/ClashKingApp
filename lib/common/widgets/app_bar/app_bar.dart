import 'package:clashkingapp/features/coc_accounts/presentation/coc_account_management_page.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/features/settings/presentation/settings_page.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final playerService = context.watch<PlayerService>();
    final authService = context.watch<AuthService>();

    // Fix selectedTag if it doesn't have corresponding player data
    if (cocService.selectedTag != null && 
        !playerService.profiles.any((p) => p.tag == cocService.selectedTag) &&
        playerService.profiles.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cocService.setSelectedTag(playerService.profiles.first.tag);
      });
    }

    return AppBar(
      automaticallyImplyLeading: false,
      title: DropdownButton<String>(
        value: cocService.selectedTag,
        elevation: 16,
        dropdownColor: Theme.of(context).colorScheme.surface,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        underline: Container(),
        onChanged: (String? newValue) {
          if (newValue != "manageAccounts") {
            cocService.setSelectedTag(newValue);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddCocAccountPage(),
              ),
            );
          }
        },
        items: [
          ...playerService.profiles.map<DropdownMenuItem<String>>((profile) {
            return DropdownMenuItem<String>(
              value: profile.tag,
              child: Row(
                children: <Widget>[
                  SizedBox(
                    height: 30,
                    width: 30,
                    child: CachedNetworkImage(
                      imageUrl: profile.townHallPic,
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    profile.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            );
          }),
          DropdownMenuItem<String>(
            value: "manageAccounts",
            child: Row(
              children: <Widget>[
                Icon(Icons.settings),
                SizedBox(width: 4),
                Text(AppLocalizations.of(context)?.generalManage ?? 'Manage'),
              ],
            ),
          ),
        ],
      ),
      actions: <Widget>[
        Row(
          children: <Widget>[
            Text(
              authService.currentUser?.username ?? "",
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(width: 5),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SettingsInfoScreen(user: authService.currentUser!)),
                );
              },
              child: ClipOval(
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: CachedNetworkImage(
                    imageUrl: authService.currentUser?.avatarUrl ?? "",
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: 16),
      ],
    );
  }
}
