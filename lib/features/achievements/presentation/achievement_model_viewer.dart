import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class AchievementModelViewer extends StatelessWidget {
  const AchievementModelViewer({
    super.key,
    required this.modelUrl,
    required this.semanticLabel,
    required this.locked,
    required this.interactive,
    required this.enableIdleRotation,
  });

  final String modelUrl;
  final String semanticLabel;
  final bool locked;
  final bool interactive;
  final bool enableIdleRotation;

  @override
  Widget build(BuildContext context) {
    final mode = interactive ? 'detail' : 'tile';
    final modelId = 'achievement-model-${modelUrl.hashCode.abs()}-$mode';
    final lockStyle = locked
        ? 'filter: grayscale(1) saturate(0) opacity(0.44);'
        : '';

    return Semantics(
      image: !interactive,
      label: semanticLabel,
      excludeSemantics: true,
      child: IgnorePointer(
        ignoring: !interactive,
        child: ModelViewer(
          id: modelId,
          src: modelUrl,
          alt: semanticLabel,
          backgroundColor: Colors.transparent,
          loading: interactive ? Loading.eager : Loading.lazy,
          reveal: Reveal.auto,
          cameraControls: interactive,
          disablePan: true,
          disableTap: true,
          disableZoom: true,
          touchAction: TouchAction.panY,
          interactionPrompt: InteractionPrompt.none,
          cameraOrbit: '0deg 75deg 105%',
          minCameraOrbit: interactive ? 'auto 75deg 105%' : null,
          maxCameraOrbit: interactive ? 'auto 75deg 105%' : null,
          fieldOfView: '32deg',
          interpolationDecay: interactive ? 200 : null,
          autoRotate: interactive && enableIdleRotation,
          autoRotateDelay: 3000,
          rotationPerSecond: '18deg',
          environmentImage: 'neutral',
          shadowIntensity: 0.7,
          shadowSoftness: 0.9,
          debugLogging: false,
          relatedCss:
              '''
          #$modelId {
            width: 100%;
            height: 100%;
            --poster-color: transparent;
            $lockStyle
          }
        ''',
        ),
      ),
    );
  }
}
