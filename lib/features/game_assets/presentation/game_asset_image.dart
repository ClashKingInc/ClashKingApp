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
        placeholderBuilder: (_) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (_, _, _) => const _GameAssetImageError(),
      );
    }

    return MobileWebImage(
      imageUrl: asset.url.toString(),
      fit: fit,
      placeholder: (_, _) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (_, _, _) => const _GameAssetImageError(),
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
