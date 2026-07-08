import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MobileWebImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Widget Function(BuildContext context, String url)? placeholder;
  final Widget Function(BuildContext context, String url, Object error)?
  errorWidget;

  const MobileWebImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.color,
    this.colorBlendMode,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget fallback(Object error) {
      final customError = errorWidget?.call(context, imageUrl, error);
      if (customError != null) return customError;
      return Image.network(
        ImageAssets.defaultImage,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        color: color,
        colorBlendMode: colorBlendMode,
      );
    }

    if (kIsWeb) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        color: color,
        colorBlendMode: colorBlendMode,
        errorBuilder: (_, error, _) => fallback(error),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        color: color,
        colorBlendMode: colorBlendMode,
        placeholder: placeholder ?? (_, _) => const SizedBox.shrink(),
        errorWidget: (_, _, error) => fallback(error),
      );
    }
  }
}
