import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/clan/logs/join_leave.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clipboard/clipboard.dart';

class ClanJoinLeaveHeader extends StatefulWidget {
  final List<String> user;
  final JoinLeaveClan joinLeaveClan;
  final Clan? clanInfo;

  ClanJoinLeaveHeader(
      {super.key,
      required this.user,
      required this.joinLeaveClan,
      required this.clanInfo});

  @override
  ClanJoinLeaveHeaderState createState() => ClanJoinLeaveHeaderState();
}

class ClanJoinLeaveHeaderState extends State<ClanJoinLeaveHeader>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    String backgroundImageUrl =
        "https://clashkingfiles.b-cdn.net/landscape/join-leave-landscape.png";
    return Column(children: [
      Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          SizedBox(
            height: 210,
            width: double.infinity,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6),
                  BlendMode.darken,
                ),
                child: CachedNetworkImage(
                  imageUrl: backgroundImageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            child: Column(children: [
              CachedNetworkImage(
                imageUrl: widget.clanInfo!.badgeUrls.large,
                width: 100,
              ),
              Center(
                child: Text(
                  widget.clanInfo!.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white),
                ),
              ),
              InkWell(
                onTap: () {
                  FlutterClipboard.copy(widget.clanInfo!.tag).then((value) {
                    final snackBar = SnackBar(
                      content: Center(
                        child: Text(
                          AppLocalizations.of(context)!.copiedToClipboard,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      duration: Duration(milliseconds: 1500),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  });
                },
                child: Container(
                  padding: EdgeInsets.only(top: 2.0, bottom: 4.0),
                  child: Text(
                    widget.clanInfo!.tag,
                    style: TextStyle(
                        color: Colors.white),
                  ),
                ),
              ),
            ]),
          ),
          Positioned(
            top: 30,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onPrimary, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    ]);
  }
}
