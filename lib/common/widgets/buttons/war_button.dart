import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Widget buildWarButton(BuildContext context,
    {required VoidCallback onTap, required String label}) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      shadowColor: Theme.of(context).colorScheme.secondary,
    ),
    onPressed: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MobileWebImage(
            width: 20,
            imageUrl: ImageAssets.war,
          ),
          SizedBox(width: 8),
          Shimmer.fromColors(
            period: Duration(seconds: 3),
            baseColor: Colors.white,
            highlightColor: Colors.white.withValues(alpha: 0.4),
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    ),
  );
}
