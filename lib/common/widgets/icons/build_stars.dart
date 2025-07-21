import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/material.dart';

Widget buildStarsIcon(int filledStars) {
    List<Widget> stars = [];
    for (int i = 0; i < 3; i++) {
      stars.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: i < filledStars
              ? MobileWebImage(
                  imageUrl: ImageAssets.attackStar, width: 12, height: 12)
              : const Icon(Icons.star_border, size: 14),
        ),
      );
    }
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: stars,
        ));
  }