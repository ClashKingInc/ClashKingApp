import 'package:clashkingapp/common/widgets/dialogs/snackbar.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clipboard/clipboard.dart';

class ClanJoinLeaveHeader extends StatefulWidget {
  final Clan clanInfo;

  ClanJoinLeaveHeader({super.key, required this.clanInfo});

  @override
  ClanJoinLeaveHeaderState createState() => ClanJoinLeaveHeaderState();
}

class ClanJoinLeaveHeaderState extends State<ClanJoinLeaveHeader>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    String backgroundImageUrl =
        "https://assets.clashk.ing/landscape/join-leave-landscape.png";
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
                  Colors.black.withValues(alpha: 0.6),
                  BlendMode.darken,
                ),
                child: CachedNetworkImage(
                  errorWidget: (context, url, error) => Icon(Icons.error),
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
                errorWidget: (context, url, error) => Icon(Icons.error),
                imageUrl: widget.clanInfo.badgeUrls.large,
                width: 100,
              ),
              Center(
                child: Text(
                  widget.clanInfo.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white),
                ),
              ),
              InkWell(
                onTap: () {
                  FlutterClipboard.copy(widget.clanInfo.tag).then((_) {
                    if (context.mounted) {
                      showClipboardSnackbar(
                        context,
                        AppLocalizations.of(context)!.generalCopiedToClipboard,
                      );
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.only(top: 2.0, bottom: 4.0),
                  child: Text(
                    widget.clanInfo.tag,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ]),
          ),
          Positioned(
            top: 40,
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
