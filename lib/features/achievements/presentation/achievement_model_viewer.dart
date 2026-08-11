import 'package:clashkingapp/features/achievements/data/achievement_model_cache.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class AchievementModelViewer extends StatefulWidget {
  const AchievementModelViewer({
    super.key,
    required this.modelUrl,
    required this.semanticLabel,
    required this.locked,
    required this.interactive,
    required this.enableIdleRotation,
    this.cache,
  });

  final String modelUrl;
  final String semanticLabel;
  final bool locked;
  final bool interactive;
  final bool enableIdleRotation;
  final AchievementModelCache? cache;

  @override
  State<AchievementModelViewer> createState() => _AchievementModelViewerState();
}

class _AchievementModelViewerState extends State<AchievementModelViewer> {
  late AchievementModelCache _cache;
  late Future<String> _source;

  @override
  void initState() {
    super.initState();
    _cache = widget.cache ?? AchievementModelCache.shared;
    _source = _cache.resolve(widget.modelUrl);
  }

  @override
  void didUpdateWidget(covariant AchievementModelViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modelUrl != widget.modelUrl ||
        oldWidget.cache != widget.cache) {
      _cache = widget.cache ?? AchievementModelCache.shared;
      _source = _cache.resolve(widget.modelUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.interactive ? 'detail' : 'tile';
    final modelId = 'achievement-model-${widget.modelUrl.hashCode.abs()}-$mode';
    final lockStyle = widget.locked
        ? 'filter: grayscale(1) saturate(0) opacity(0.44);'
        : '';

    return FutureBuilder<String>(
      future: _source,
      initialData: _cache.peek(widget.modelUrl),
      builder: (context, snapshot) {
        final source = snapshot.data;
        if (source == null) return const SizedBox.expand();
        return Semantics(
          image: !widget.interactive,
          label: widget.semanticLabel,
          excludeSemantics: true,
          child: IgnorePointer(
            ignoring: !widget.interactive,
            child: ModelViewer(
              id: modelId,
              src: source,
              alt: widget.semanticLabel,
              backgroundColor: Colors.transparent,
              loading: widget.interactive ? Loading.eager : Loading.lazy,
              reveal: Reveal.auto,
              cameraControls: widget.interactive,
              disablePan: true,
              disableTap: true,
              disableZoom: true,
              touchAction: TouchAction.none,
              interactionPrompt: InteractionPrompt.none,
              cameraOrbit: '0deg 75deg 105%',
              minCameraOrbit: widget.interactive ? 'auto 75deg 105%' : null,
              maxCameraOrbit: widget.interactive ? 'auto 75deg 105%' : null,
              fieldOfView: '32deg',
              interpolationDecay: widget.interactive ? 200 : null,
              autoRotate: widget.interactive && widget.enableIdleRotation,
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
      },
    );
  }
}
