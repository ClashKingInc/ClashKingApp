import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MobileWebImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const MobileWebImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Image.network(
          ImageAssets.defaultImage,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => Image.network(
          ImageAssets.defaultImage,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    }
  }
}
