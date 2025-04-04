import 'package:flutter/material.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:clashkingapp/common/widgets/cards/add_player_card.dart';
import 'package:clashkingapp/common/widgets/cards/delete_player_card.dart';
import 'package:clashkingapp/features/settings/presentation/settings_page.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final playerService = context.watch<PlayerService>();
    final authService = context.watch<AuthService>();

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
            _showManageAccountsDialog(context, cocService);
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
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
                Text(AppLocalizations.of(context)?.manage ?? 'Manage'),
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

  void _showManageAccountsDialog(BuildContext context, CocAccountService cocService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int currentSegment = 0;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(AppLocalizations.of(context)?.manage ?? 'Manage'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomSlidingSegmentedControl<int>(
                      children: {
                        0: Text(AppLocalizations.of(context)?.add ?? 'Add'),
                        1: Text(AppLocalizations.of(context)?.delete ?? 'Delete'),
                      },
                      initialValue: currentSegment,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary.withValues(alpha : 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      thumbDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha : .3),
                            blurRadius: 4.0,
                            spreadRadius: 1.0,
                            offset: Offset(0.0, 2.0),
                          ),
                        ],
                      ),
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInToLinear,
                      onValueChanged: (newValue) {
                        setState(() {
                          currentSegment = newValue;
                        });
                      },
                    ),
                    SizedBox(height: 4),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
