import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/features/game_assets/models/game_asset_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

typedef GameAssetImageBuilder =
    Widget Function(BuildContext context, GameAsset asset, BoxFit fit);

class GameAssetImage extends StatelessWidget {
  const GameAssetImage({
    super.key,
    required this.asset,
    this.fit = BoxFit.contain,
  });

  final GameAsset asset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (asset.extension == 'svg') {
      return SvgPicture.network(
        asset.url.toString(),
        fit: fit,
        placeholderBuilder: (_) => const _GameAssetImageSkeleton(),
        errorBuilder: (_, _, _) => const _GameAssetImageError(),
      );
    }

    return MobileWebImage(
      imageUrl: asset.url.toString(),
      fit: fit,
      placeholder: (_, _) => const _GameAssetImageSkeleton(),
      errorWidget: (_, _, _) => const _GameAssetImageError(),
    );
  }
}

class _GameAssetImageSkeleton extends StatelessWidget {
  const _GameAssetImageSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedSides = [
          if (constraints.hasBoundedWidth) constraints.maxWidth,
          if (constraints.hasBoundedHeight) constraints.maxHeight,
        ];
        final maxSide = boundedSides.isEmpty
            ? 72.0
            : boundedSides.reduce((a, b) => a < b ? a : b);
        final side = (maxSide * 0.56).clamp(36.0, 96.0).toDouble();
        return Center(
          child: SkeletonLoader(
            width: side,
            height: side,
            borderRadius: BorderRadius.circular(side * 0.24),
          ),
        );
      },
    );
  }
}

class _GameAssetImageError extends StatelessWidget {
  const _GameAssetImageError();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.broken_image_outlined,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
