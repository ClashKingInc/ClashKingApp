import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class AchievementModelViewer extends StatelessWidget {
  const AchievementModelViewer({
    super.key,
    required this.modelUrl,
    required this.semanticLabel,
    required this.locked,
    required this.interactive,
    required this.playUnlockAnimation,
  });

  final String modelUrl;
  final String semanticLabel;
  final bool locked;
  final bool interactive;
  final bool playUnlockAnimation;

  @override
  Widget build(BuildContext context) {
    final surface = interactive
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Colors.transparent;
    final unlockDuration = CKMotion.slow * 2;
    final mode = interactive ? 'detail' : 'tile';
    final modelId = 'achievement-model-${modelUrl.hashCode.abs()}-$mode';
    final lockStyle = locked
        ? 'filter: grayscale(1) saturate(0) opacity(0.44);'
        : '';
    final unlockStyle = playUnlockAnimation
        ? '''
          @keyframes ck-achievement-unlock {
            0% { transform: scale(0.86); filter: brightness(1.7) saturate(0.65); }
            58% { transform: scale(1.04); filter: brightness(1.18) saturate(1.1); }
            100% { transform: scale(1); filter: brightness(1) saturate(1); }
          }
          #$modelId { animation: ck-achievement-unlock ${CKMotion.slow.inMilliseconds}ms ease-out both; }
        '''
        : '';
    final stopAfterOneSpin = playUnlockAnimation
        ? '''
          (() => {
            const model = document.getElementById('$modelId');
            model.addEventListener('load', () => {
              model.autoRotate = true;
              window.setTimeout(() => {
                model.autoRotate = false;
                model.cameraOrbit = '0deg 75deg 105%';
              }, ${unlockDuration.inMilliseconds});
            }, { once: true });
          })();
        '''
        : null;

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
          backgroundColor: surface,
          loading: interactive ? Loading.eager : Loading.lazy,
          reveal: Reveal.auto,
          cameraControls: interactive,
          disablePan: true,
          disableTap: true,
          disableZoom: true,
          touchAction: TouchAction.panY,
          interactionPrompt: InteractionPrompt.none,
          cameraOrbit: '0deg 75deg 105%',
          fieldOfView: '32deg',
          autoRotate: false,
          autoRotateDelay: 0,
          rotationPerSecond: '500deg',
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
          $unlockStyle
        ''',
          relatedJs: stopAfterOneSpin,
        ),
      ),
    );
  }
}
