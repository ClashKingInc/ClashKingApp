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
    return LayoutBuilder(
      builder: (context, constraints) {
        final logicalWidth =
            width ??
            (constraints.hasBoundedWidth ? constraints.maxWidth : null);
        final logicalHeight =
            height ??
            (constraints.hasBoundedHeight ? constraints.maxHeight : null);
        final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        final requestedCacheWidth = _physicalCacheDimension(
          logicalWidth,
          devicePixelRatio,
        );
        final requestedCacheHeight = _physicalCacheDimension(
          logicalHeight,
          devicePixelRatio,
        );
        final (cacheWidth, cacheHeight) = _cacheDimensions(
          fit: fit,
          width: requestedCacheWidth,
          height: requestedCacheHeight,
        );

        Widget fallback(Object error) {
          final customError = errorWidget?.call(context, imageUrl, error);
          if (customError != null) return customError;
          return Image.network(
            ImageAssets.defaultImage,
            width: width,
            height: height,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            fit: fit,
            alignment: alignment,
            color: color,
            colorBlendMode: colorBlendMode,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
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
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
            errorBuilder: (_, error, _) => fallback(error),
          );
        }

        return CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          memCacheWidth: cacheWidth,
          memCacheHeight: cacheHeight,
          fit: fit,
          alignment: alignment,
          color: color,
          colorBlendMode: colorBlendMode,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          useOldImageOnUrlChange: true,
          filterQuality: FilterQuality.low,
          placeholder: placeholder ?? (_, _) => const SizedBox.shrink(),
          errorWidget: (_, _, error) => fallback(error),
        );
      },
    );
  }

  static int? _physicalCacheDimension(double? logicalSize, double scale) {
    if (logicalSize == null || !logicalSize.isFinite || logicalSize <= 0) {
      return null;
    }
    return (logicalSize * scale).ceil().clamp(1, 4096);
  }

  static (int?, int?) _cacheDimensions({
    required BoxFit fit,
    required int? width,
    required int? height,
  }) {
    // Supplying both target dimensions makes Flutter decode the source into
    // that exact rectangle before BoxFit is applied. Keep one dimension so
    // contain/cover preserve the source aspect ratio during decoding.
    if (fit == BoxFit.fill) return (width, height);
    if (width != null) return (width, null);
    return (null, height);
  }
}
