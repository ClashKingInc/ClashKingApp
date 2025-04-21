import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:intl/intl.dart';

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
                      Colors.black.withValues(alpha: 0.3),
                      BlendMode.darken,
                    ),
                    child: MobileWebImage(
                      imageUrl: ImageAssets.clanCapitalPageBackground,
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
                                child: MobileWebImage(
                                  width: 170,
                                  fit: BoxFit.cover,
                                  imageUrl: ImageAssets.capitalHall(widget
                                          .clanInfo
                                          ?.clanCapital
                                          ?.capitalHallLevel ??
                                      1),
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
          SizedBox(height: 80),
          ImageChip(
            imageUrl: ImageAssets.capitalGold,
            label: NumberFormat('#,###').format(widget.clanInfo?.clanCapitalPoints),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
