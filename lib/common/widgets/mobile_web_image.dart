import 'dart:collection';

import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MobileWebImage extends StatelessWidget {
  static const _maxResolvedImages = 512;
  static const _maxFailedImages = 1024;
  static const _failureTtl = Duration(minutes: 5);
  static final LinkedHashMap<String, String> _resolvedImages = LinkedHashMap();
  static final LinkedHashMap<String, DateTime> _failedImages = LinkedHashMap();

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
  final List<String> fallbackImageUrls;
  final String? _resolutionKey;

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
    this.fallbackImageUrls = const [],
  }) : _resolutionKey = null;

  const MobileWebImage._fallback({
    required this.imageUrl,
    required String resolutionKey,
    required this.fallbackImageUrls,
    required this.fit,
    required this.width,
    required this.height,
    required this.alignment,
    required this.color,
    required this.colorBlendMode,
    required this.placeholder,
    required this.errorWidget,
  }) : _resolutionKey = resolutionKey,
       super(key: null);

  @override
  Widget build(BuildContext context) {
    final resolutionKey = _resolutionKey ?? imageUrl;
    final candidates = _imageCandidates(
      resolutionKey,
      imageUrl,
      fallbackImageUrls,
    );
    if (candidates.isEmpty) {
      return _terminalFallback(
        context,
        resolutionKey,
        StateError('No available image candidates'),
      );
    }
    final effectiveImageUrl = candidates.first;
    final remainingCandidates = candidates.skip(1).toList(growable: false);

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
          _rememberFailure(resolutionKey, effectiveImageUrl);
          if (remainingCandidates.isNotEmpty) {
            return MobileWebImage._fallback(
              imageUrl: remainingCandidates.first,
              resolutionKey: resolutionKey,
              fallbackImageUrls: remainingCandidates
                  .skip(1)
                  .toList(growable: false),
              fit: fit,
              width: width,
              height: height,
              alignment: alignment,
              color: color,
              colorBlendMode: colorBlendMode,
              placeholder: placeholder,
              errorWidget: errorWidget,
            );
          }
          final customError = errorWidget?.call(
            context,
            effectiveImageUrl,
            error,
          );
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
            effectiveImageUrl,
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            color: color,
            colorBlendMode: colorBlendMode,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame != null || wasSynchronouslyLoaded) {
                _rememberResolved(resolutionKey, effectiveImageUrl);
              }
              return child;
            },
            errorBuilder: (_, error, _) => fallback(error),
          );
        }

        return CachedNetworkImage(
          imageUrl: effectiveImageUrl,
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
          imageBuilder: (context, provider) {
            _rememberResolved(resolutionKey, effectiveImageUrl);
            return Image(
              image: provider,
              width: width,
              height: height,
              fit: fit,
              alignment: alignment,
              color: color,
              colorBlendMode: colorBlendMode,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
            );
          },
          placeholder: placeholder ?? (_, _) => const SizedBox.shrink(),
          errorWidget: (_, _, error) => fallback(error),
        );
      },
    );
  }

  Widget _terminalFallback(
    BuildContext context,
    String failedUrl,
    Object error,
  ) {
    final customError = errorWidget?.call(context, failedUrl, error);
    if (customError != null) return customError;
    return Image.network(
      ImageAssets.defaultImage,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
    );
  }

  static List<String> _imageCandidates(
    String resolutionKey,
    String requested,
    List<String> fallbacks,
  ) {
    final candidates = <String>[];
    final resolved = _resolvedImages[resolutionKey];
    final retryBefore = DateTime.now().subtract(_failureTtl);
    for (final candidate in [?resolved, requested, ...fallbacks]) {
      final failedAt = _failedImages[candidate];
      if (failedAt != null && failedAt.isBefore(retryBefore)) {
        _failedImages.remove(candidate);
      }
      if (candidate.isEmpty ||
          _failedImages.containsKey(candidate) ||
          candidates.contains(candidate)) {
        continue;
      }
      candidates.add(candidate);
    }
    return candidates;
  }

  static void _rememberResolved(String resolutionKey, String resolvedUrl) {
    if (_resolvedImages[resolutionKey] == resolvedUrl) return;
    _resolvedImages.remove(resolutionKey);
    _resolvedImages[resolutionKey] = resolvedUrl;
    while (_resolvedImages.length > _maxResolvedImages) {
      _resolvedImages.remove(_resolvedImages.keys.first);
    }
  }

  static void _rememberFailure(String resolutionKey, String failedUrl) {
    if (_resolvedImages[resolutionKey] == failedUrl) {
      _resolvedImages.remove(resolutionKey);
    }
    _failedImages.remove(failedUrl);
    _failedImages[failedUrl] = DateTime.now();
    while (_failedImages.length > _maxFailedImages) {
      _failedImages.remove(_failedImages.keys.first);
    }
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
