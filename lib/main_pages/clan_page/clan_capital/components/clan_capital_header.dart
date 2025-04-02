import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';

class ClanCapitalHeader extends StatefulWidget {
  final List<String> user;
  final Clan? clanInfo;

  ClanCapitalHeader({
    super.key,
    required this.user,
    required this.clanInfo,
  });

  @override
  ClanCapitalHeaderState createState() => ClanCapitalHeaderState();
}

class ClanCapitalHeaderState extends State<ClanCapitalHeader>
    with SingleTickerProviderStateMixin {
  String backgroundImageUrl =
      "https://assets.clashk.ing/landscape/clan-capital-landscape.png";

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              SizedBox(
                height: 190,
                width: double.infinity,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha : 0.3),
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
                top: 30,
                left: 10,
                child: IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onPrimary, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                bottom: -62,
                child: Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        SizedBox(height: 10),
                        SizedBox(
                          width: 48,
                          height: 32,
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          width: 32,
                          height: 32,
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          width: 32,
                          height: 32,
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                    SizedBox(width: 16),
                    Column(
                      children: [
                        ClipRect(
                          child: Transform.translate(
                            offset: Offset(0, -6),
                            child: Transform.scale(
                              scale: (widget.clanInfo?.clanCapital
                                          ?.capitalHallLevel ==
                                      8)
                                  ? 0.91
                                  : 1.3,
                              child: InteractiveViewer(
                                child: CachedNetworkImage(
                                width: 170,
                                fit: BoxFit.cover,
                                imageUrl:
                                  'https://assets.clashk.ing/capital-base/capital-hall-pics/Building_CC_Capital_Hall_level_${widget.clanInfo?.clanCapital?.capitalHallLevel}.png',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 16),
                    Column(
                      children: [
                        SizedBox(height: 10),
                        SizedBox(
                          width: 32,
                          height: 32,
                        ),
                        SizedBox(height: 8),
                        IconButton(
                          icon: Icon(Icons.sports_esports_rounded,
                              color: Colors.white, size: 32),
                          onPressed: () async {
                            final languageCode = Localizations.localeOf(context)
                                .languageCode
                                .toLowerCase();
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  final url = Uri.https('link.clashofclans.com',
                                      '/$languageCode', {
                                    'action': 'OpenClanProfile',
                                    'tag': widget.clanInfo?.tag,
                                  });

                                  return OpenClashDialog(url: url);
                                });
                          },
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          width: 32,
                          height: 32,
                        ),
                        SizedBox(height: 8),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 60),
        ],
      ),
    );
  }
}
